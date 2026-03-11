local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Potions = require(RS.Shared.Config.Potions)
local MutationTuning = require(RS.Shared.Config.MutationTuning)
local ArenaTuning = require(RS:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("ArenaTuning"))
local Remotes = RS:WaitForChild("Remotes")

-- Create arena remotes
local function ensureRemote(name, className)
    if not Remotes:FindFirstChild(name) then
        local r = Instance.new(className)
        r.Name = name
        r.Parent = Remotes
    end
    return Remotes[name]
end

local ChallengePlayer = ensureRemote("ChallengePlayer", "RemoteEvent")
local ChallengeResponse = ensureRemote("ChallengeResponse", "RemoteEvent")
local WagerPotion = ensureRemote("WagerPotion", "RemoteEvent")
local ConfirmLoadout = ensureRemote("ConfirmLoadout", "RemoteEvent")
local BoostClick = ensureRemote("BoostClick", "RemoteEvent")
local ClaimDuelReward = ensureRemote("ClaimDuelReward", "RemoteEvent")
local DuelStateUpdate = ensureRemote("DuelStateUpdate", "RemoteEvent")
local GetDuelState = ensureRemote("GetDuelState", "RemoteFunction")

local DuelState = ArenaTuning.DuelState

-- Active duels: activeDuels[sessionId] = duel
local activeDuels = {}
-- Player to duel mapping: playerDuel[userId] = sessionId
local playerDuel = {}
-- Pending challenges: pendingChallenges[targetUserId] = {challengerUserId, timestamp}
local pendingChallenges = {}
-- Cooldowns: lastDuelTime[userId] = os.time()
local lastDuelTime = {}
-- Boost click timestamps: lastBoostClick[userId] = tick()
local lastBoostClick = {}

local nextSessionId = 1

local function getPlayerStars(player)
    local pds = _G.PlayerDataService
    if not pds then return 0 end
    local data = pds.getData(player)
    if not data or not data.BrewStats then return 0 end
    return data.BrewStats.StarCount or data.BrewStats.TotalBrewed or 0
end

local function getPlayerPotionCount(player)
    local pds = _G.PlayerDataService
    if not pds then return 0 end
    local data = pds.getData(player)
    if not data then return 0 end
    local count = 0
    for _, qty in pairs(data.Potions or {}) do
        count = count + (qty or 0)
    end
    return count
end

local function canEnterArena(player)
    local stars = getPlayerStars(player)
    local potions = getPlayerPotionCount(player)
    if stars < ArenaTuning.MinStarsToEnter then return false, "Need " .. ArenaTuning.MinStarsToEnter .. " stars to enter the Arena." end
    if potions < ArenaTuning.MinPotionsToEnter then return false, "Need " .. ArenaTuning.MinPotionsToEnter .. " potions to enter the Arena." end
    if playerDuel[player.UserId] then return false, "Already in a duel." end
    local cooldown = lastDuelTime[player.UserId]
    if cooldown and os.time() - cooldown < ArenaTuning.DuelCooldownSeconds then
        return false, "Duel cooldown: " .. (ArenaTuning.DuelCooldownSeconds - (os.time() - cooldown)) .. "s remaining."
    end
    return true, nil
end

local function broadcastDuelState(duel)
    for _, pData in ipairs({duel.player1, duel.player2}) do
        local player = Players:GetPlayerByUserId(pData.userId)
        if player then
            pcall(function()
                DuelStateUpdate:FireClient(player, {
                    sessionId = duel.id,
                    state = duel.state,
                    player1 = { userId = duel.player1.userId, name = duel.player1.name, wagerCount = #duel.player1.wagers, confirmed = duel.player1.confirmed, power = duel.player1.power, boostClicks = duel.player1.boostClicks },
                    player2 = { userId = duel.player2.userId, name = duel.player2.name, wagerCount = #duel.player2.wagers, confirmed = duel.player2.confirmed, power = duel.player2.power, boostClicks = duel.player2.boostClicks },
                    winnerId = duel.winnerId,
                    phaseEndUnix = duel.phaseEndUnix,
                })
            end)
        end
    end
end

local function announceGlobal(msg)
    if Remotes:FindFirstChild("GlobalAnnouncement") then
        for _, p in ipairs(Players:GetPlayers()) do
            pcall(function() Remotes.GlobalAnnouncement:FireClient(p, msg) end)
        end
    end
end

local function getDuelForPlayer(player)
    local sessionId = playerDuel[player.UserId]
    if not sessionId then return nil, nil end
    return activeDuels[sessionId], sessionId
end

local function getParticipant(duel, userId)
    if duel.player1.userId == userId then return duel.player1 end
    if duel.player2.userId == userId then return duel.player2 end
    return nil
end

local function getOpponent(duel, userId)
    if duel.player1.userId == userId then return duel.player2 end
    if duel.player2.userId == userId then return duel.player1 end
    return nil
end

local function resolveFight(duel)
    -- Compute power for both players
    for _, pData in ipairs({duel.player1, duel.player2}) do
        local player = Players:GetPlayerByUserId(pData.userId)
        local stars = player and getPlayerStars(player) or 0
        pData.power = ArenaTuning.computePower(pData.wagers, stars, pData.boostClicks, Potions.Data, MutationTuning)
    end

    -- Apply luck factor
    local luck1 = ArenaTuning.LuckMin + math.random() * (ArenaTuning.LuckMax - ArenaTuning.LuckMin)
    local luck2 = ArenaTuning.LuckMin + math.random() * (ArenaTuning.LuckMax - ArenaTuning.LuckMin)
    local final1 = duel.player1.power * luck1
    local final2 = duel.player2.power * luck2

    duel.player1.finalPower = math.floor(final1)
    duel.player2.finalPower = math.floor(final2)

    if final1 >= final2 then
        duel.winnerId = duel.player1.userId
    else
        duel.winnerId = duel.player2.userId
    end

    duel.state = DuelState.Result
    duel.phaseEndUnix = os.time() + ArenaTuning.ResultSeconds

    print("[ArenaService] Fight resolved: " .. duel.player1.name .. "(" .. duel.player1.finalPower .. ") vs " .. duel.player2.name .. "(" .. duel.player2.finalPower .. ") -> Winner: " .. (duel.winnerId == duel.player1.userId and duel.player1.name or duel.player2.name))

    broadcastDuelState(duel)

    -- Auto-resolve if winner doesn't claim in time
    task.delay(ArenaTuning.ResultSeconds + 2, function()
        if duel.state == DuelState.Result then
            -- Auto-claim: winner gets a random potion from loser
            local winner = getParticipant(duel, duel.winnerId)
            local loser = getOpponent(duel, duel.winnerId)
            if loser and #loser.wagers > 0 then
                local potionId = loser.wagers[1]
                transferReward(duel, duel.winnerId, potionId)
            else
                cleanupDuel(duel)
            end
        end
    end)
end

function transferReward(duel, winnerUserId, claimedPotionId)
    local pds = _G.PlayerDataService
    if not pds then cleanupDuel(duel) return end

    local winner = getParticipant(duel, winnerUserId)
    local loser = getOpponent(duel, winnerUserId)
    if not winner or not loser then cleanupDuel(duel) return end

    local winnerPlayer = Players:GetPlayerByUserId(winner.userId)
    local loserPlayer = Players:GetPlayerByUserId(loser.userId)

    -- Validate claimed potion is in loser's wagers
    local validClaim = false
    for _, pid in ipairs(loser.wagers) do
        if pid == claimedPotionId then validClaim = true break end
    end
    if not validClaim and #loser.wagers > 0 then
        claimedPotionId = loser.wagers[1] -- fallback
    end

    -- Transfer potion: add to winner, (already removed from loser's inventory during wager)
    if winnerPlayer then
        local winnerData = pds.getData(winnerPlayer)
        if winnerData then
            winnerData.Potions[claimedPotionId] = (winnerData.Potions[claimedPotionId] or 0) + 1
        end
    end

    -- Return UN-claimed wagers to both players
    for _, pData in ipairs({winner, loser}) do
        local player = Players:GetPlayerByUserId(pData.userId)
        if player then
            local data = pds.getData(player)
            if data then
                for _, pid in ipairs(pData.wagers) do
                    if pData == loser and pid == claimedPotionId then
                        -- This one goes to winner, don't return
                        claimedPotionId = nil -- only skip first match
                    else
                        data.Potions[pid] = (data.Potions[pid] or 0) + 1
                    end
                end
            end
        end
    end

    -- Award stars to winner
    if winnerPlayer then
        local winnerData = pds.getData(winnerPlayer)
        if winnerData and winnerData.BrewStats then
            local bonusStars = ArenaTuning.WinnerStars
            -- Underdog bonus
            local winnerStars = winnerData.BrewStats.StarCount or 0
            local loserStars = 0
            if loserPlayer then
                local loserData = pds.getData(loserPlayer)
                if loserData and loserData.BrewStats then
                    loserStars = loserData.BrewStats.StarCount or 0
                end
            end
            if winnerStars < loserStars then
                bonusStars = bonusStars + ArenaTuning.UnderdogBonusStars
            end
            winnerData.BrewStats.StarCount = (winnerData.BrewStats.StarCount or 0) + bonusStars
            print("[ArenaService] " .. winner.name .. " earned +" .. bonusStars .. " stars from duel")
        end
    end

    -- Notify both clients
    for _, pData in ipairs({winner, loser}) do
        local player = Players:GetPlayerByUserId(pData.userId)
        if player then
            pds.notifyClient(player)
            pds.forceSave(player)
        end
    end

    -- Global announcement for high-stakes duels
    local baseId = (claimedPotionId or ""):find("__") and (claimedPotionId or ""):sub(1, ((claimedPotionId or ""):find("__") or 0) - 1) or (claimedPotionId or "")
    local potion = Potions.Data[baseId]
    if potion and (potion.tier == "Rare" or potion.tier == "Mythic" or potion.tier == "Divine") then
        announceGlobal(winner.name .. " won a " .. potion.name .. " from " .. loser.name .. " in the Arena!")
    end

    cleanupDuel(duel)
end

function cleanupDuel(duel)
    duel.state = DuelState.Done
    broadcastDuelState(duel)
    playerDuel[duel.player1.userId] = nil
    playerDuel[duel.player2.userId] = nil
    lastDuelTime[duel.player1.userId] = os.time()
    lastDuelTime[duel.player2.userId] = os.time()
    activeDuels[duel.id] = nil
end

-- ============================================================
-- REMOTE HANDLERS
-- ============================================================

-- Challenge a player
ChallengePlayer.OnServerEvent:Connect(function(player, targetUserId)
    if type(targetUserId) ~= "number" then return end
    local canEnter, err = canEnterArena(player)
    if not canEnter then
        pcall(function() Remotes.GlobalAnnouncement:FireClient(player, err) end)
        return
    end
    local target = Players:GetPlayerByUserId(targetUserId)
    if not target then return end
    if target == player then return end
    local targetCan, targetErr = canEnterArena(target)
    if not targetCan then
        pcall(function() Remotes.GlobalAnnouncement:FireClient(player, target.Name .. " can't duel: " .. targetErr) end)
        return
    end

    pendingChallenges[targetUserId] = { challengerUserId = player.UserId, timestamp = os.time() }
    pcall(function()
        ChallengeResponse:FireClient(target, "incoming", player.UserId, player.Name, getPlayerStars(player))
    end)
    pcall(function()
        Remotes.GlobalAnnouncement:FireClient(player, "Challenge sent to " .. target.Name .. "!")
    end)
    print("[ArenaService] " .. player.Name .. " challenged " .. target.Name)

    -- Expire after 20 seconds
    task.delay(20, function()
        if pendingChallenges[targetUserId] and pendingChallenges[targetUserId].challengerUserId == player.UserId then
            pendingChallenges[targetUserId] = nil
            pcall(function() Remotes.GlobalAnnouncement:FireClient(player, target.Name .. " didn't respond to your challenge.") end)
        end
    end)
end)

-- Accept or decline challenge
ChallengeResponse.OnServerEvent:Connect(function(player, action, challengerUserId)
    if action == "decline" then
        pendingChallenges[player.UserId] = nil
        local challenger = Players:GetPlayerByUserId(challengerUserId)
        if challenger then
            pcall(function() Remotes.GlobalAnnouncement:FireClient(challenger, player.Name .. " declined your challenge.") end)
        end
        return
    end

    if action ~= "accept" then return end
    local pending = pendingChallenges[player.UserId]
    if not pending or pending.challengerUserId ~= challengerUserId then return end
    pendingChallenges[player.UserId] = nil

    local challenger = Players:GetPlayerByUserId(challengerUserId)
    if not challenger then return end

    -- Re-validate both can enter
    local can1, err1 = canEnterArena(challenger)
    local can2, err2 = canEnterArena(player)
    if not can1 or not can2 then return end

    -- Create duel session
    local sessionId = nextSessionId
    nextSessionId = nextSessionId + 1

    local duel = {
        id = sessionId,
        state = DuelState.Loadout,
        phaseEndUnix = os.time() + ArenaTuning.LoadoutSeconds,
        player1 = { userId = challenger.UserId, name = challenger.Name, wagers = {}, boostClicks = 0, power = 0, finalPower = 0, confirmed = false },
        player2 = { userId = player.UserId, name = player.Name, wagers = {}, boostClicks = 0, power = 0, finalPower = 0, confirmed = false },
        winnerId = nil,
    }

    activeDuels[sessionId] = duel
    playerDuel[challenger.UserId] = sessionId
    playerDuel[player.UserId] = sessionId

    print("[ArenaService] Duel #" .. sessionId .. " started: " .. challenger.Name .. " vs " .. player.Name)
    broadcastDuelState(duel)

    -- Auto-advance to fighting when loadout timer expires
    task.delay(ArenaTuning.LoadoutSeconds + 1, function()
        if duel.state == DuelState.Loadout then
            -- If neither wagered anything, cancel
            if #duel.player1.wagers == 0 and #duel.player2.wagers == 0 then
                announceGlobal("Duel cancelled — neither player wagered potions!")
                -- Return nothing, just cleanup
                cleanupDuel(duel)
                return
            end
            duel.state = DuelState.Fighting
            duel.phaseEndUnix = os.time() + ArenaTuning.FightSeconds
            broadcastDuelState(duel)
            print("[ArenaService] Duel #" .. duel.id .. " entering fight phase")

            -- Resolve after fight timer
            task.delay(ArenaTuning.FightSeconds, function()
                if duel.state == DuelState.Fighting then
                    resolveFight(duel)
                end
            end)
        end
    end)
end)

-- Wager a potion during loadout
WagerPotion.OnServerEvent:Connect(function(player, potionId)
    if type(potionId) ~= "string" then return end
    local duel = getDuelForPlayer(player)
    if not duel or duel.state ~= DuelState.Loadout then return end

    local participant = getParticipant(duel, player.UserId)
    if not participant then return end
    if #participant.wagers >= ArenaTuning.MaxWagers then return end
    if participant.confirmed then return end

    -- Validate player owns the potion
    local pds = _G.PlayerDataService
    if not pds then return end
    local data = pds.getData(player)
    if not data then return end

    local owned = data.Potions[potionId] or 0
    -- Count how many of this potion are already wagered
    local alreadyWagered = 0
    for _, wid in ipairs(participant.wagers) do
        if wid == potionId then alreadyWagered = alreadyWagered + 1 end
    end
    if owned - alreadyWagered < 1 then return end

    -- Remove from inventory (escrow)
    data.Potions[potionId] = data.Potions[potionId] - 1
    if data.Potions[potionId] <= 0 then data.Potions[potionId] = nil end

    table.insert(participant.wagers, potionId)
    pds.notifyClient(player)
    broadcastDuelState(duel)

    local power = ArenaTuning.getPotionPower(potionId, Potions.Data, MutationTuning)
    print("[ArenaService] " .. player.Name .. " wagered " .. potionId .. " (power: " .. power .. ")")
end)

-- Confirm loadout (ready to fight)
ConfirmLoadout.OnServerEvent:Connect(function(player)
    local duel = getDuelForPlayer(player)
    if not duel or duel.state ~= DuelState.Loadout then return end
    local participant = getParticipant(duel, player.UserId)
    if not participant then return end
    if #participant.wagers == 0 then return end -- must wager at least 1

    participant.confirmed = true
    broadcastDuelState(duel)

    -- If both confirmed, start fight immediately
    if duel.player1.confirmed and duel.player2.confirmed then
        duel.state = DuelState.Fighting
        duel.phaseEndUnix = os.time() + ArenaTuning.FightSeconds
        broadcastDuelState(duel)
        print("[ArenaService] Both confirmed, fighting!")

        task.delay(ArenaTuning.FightSeconds, function()
            if duel.state == DuelState.Fighting then
                resolveFight(duel)
            end
        end)
    end
end)

-- Boost click during fight
BoostClick.OnServerEvent:Connect(function(player)
    local duel = getDuelForPlayer(player)
    if not duel or duel.state ~= DuelState.Fighting then return end
    local participant = getParticipant(duel, player.UserId)
    if not participant then return end
    if participant.boostClicks >= ArenaTuning.MaxBoostClicks then return end

    -- Rate limit
    local now = tick()
    local last = lastBoostClick[player.UserId] or 0
    if now - last < ArenaTuning.BoostClickCooldown then return end
    lastBoostClick[player.UserId] = now

    participant.boostClicks = participant.boostClicks + 1
end)

-- Claim reward (winner picks potion from loser)
ClaimDuelReward.OnServerEvent:Connect(function(player, potionId)
    if type(potionId) ~= "string" then return end
    local duel = getDuelForPlayer(player)
    if not duel or duel.state ~= DuelState.Result then return end
    if duel.winnerId ~= player.UserId then return end

    transferReward(duel, player.UserId, potionId)
end)

-- Get current duel state
GetDuelState.OnServerInvoke = function(player)
    local duel = getDuelForPlayer(player)
    if not duel then return nil end
    local participant = getParticipant(duel, player.UserId)
    local opponent = getOpponent(duel, player.UserId)
    return {
        sessionId = duel.id,
        state = duel.state,
        player1 = { userId = duel.player1.userId, name = duel.player1.name, wagerCount = #duel.player1.wagers, confirmed = duel.player1.confirmed },
        player2 = { userId = duel.player2.userId, name = duel.player2.name, wagerCount = #duel.player2.wagers, confirmed = duel.player2.confirmed },
        winnerId = duel.winnerId,
        phaseEndUnix = duel.phaseEndUnix,
        myWagers = participant and participant.wagers or {},
        opponentWagers = (duel.state == DuelState.Result and opponent) and opponent.wagers or {},
    }
end

-- Cleanup on player leave
Players.PlayerRemoving:Connect(function(player)
    local duel = getDuelForPlayer(player)
    if duel and (duel.state == DuelState.Loadout or duel.state == DuelState.Fighting) then
        -- Forfeit: opponent wins
        local opponent = getOpponent(duel, player.UserId)
        local participant = getParticipant(duel, player.UserId)
        if opponent and participant then
            duel.winnerId = opponent.userId
            -- Return leaver's wagers to them (graceful)
            local pds = _G.PlayerDataService
            if pds then
                local data = pds.getData(player)
                if data then
                    for _, pid in ipairs(participant.wagers) do
                        data.Potions[pid] = (data.Potions[pid] or 0) + 1
                    end
                    pds.forceSave(player)
                end
            end
            participant.wagers = {}
            -- Return opponent's wagers (no potions to claim)
            local oppPlayer = Players:GetPlayerByUserId(opponent.userId)
            if oppPlayer and pds then
                local oppData = pds.getData(oppPlayer)
                if oppData then
                    for _, pid in ipairs(opponent.wagers) do
                        oppData.Potions[pid] = (oppData.Potions[pid] or 0) + 1
                    end
                    pds.notifyClient(oppPlayer)
                end
            end
            announceGlobal(player.Name .. " disconnected — " .. opponent.name .. " wins the duel!")
            cleanupDuel(duel)
        end
    end
    pendingChallenges[player.UserId] = nil
    playerDuel[player.UserId] = nil
    lastDuelTime[player.UserId] = nil
    lastBoostClick[player.UserId] = nil
end)

_G.ArenaService = {}
print("[ArenaService] Initialized (Sprint 012 - Potion Arena)")
