local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Types = require(RS.Shared.Types)
local Ingredients = require(RS.Shared.Config.Ingredients)
local ForageTuning = require(RS.Shared.Config.ForageTuning)
local Remotes = RS.Remotes

-- Forage cooldowns: forageCooldowns[userId][nodeId] = expiry time
local forageCooldowns = {}

-- ========== STAR-SCALED REGULAR FORAGE ==========

-- Resolve a forage drop using star-scaled probability tables
local function resolveForageDrop(player, nodeId)
    local pds = _G.PlayerDataService
    if not pds then return nil end
    local data = pds.getData(player)
    if not data then return nil end

    -- Get star count
    local stars = data.BrewStats and data.BrewStats.TotalBrewed or 0

    -- Roll forage tier based on stars
    local rolledTier = ForageTuning.rollForageTier(stars)

    -- Get node pools
    local pools = ForageTuning.NodePools[nodeId]
    if not pools then return "mushroom" end

    -- Try to pick from the rolled tier's pool
    if rolledTier == "Rare" then
        local pool = pools.rare
        if pool and #pool > 0 then
            return pool[math.random(1, #pool)]
        end
        -- Fallback: try global rare pool
        if #ForageTuning.RareForagePool > 0 then
            return ForageTuning.RareForagePool[math.random(1, #ForageTuning.RareForagePool)]
        end
        -- Final fallback to uncommon
        rolledTier = "Uncommon"
    end

    if rolledTier == "Uncommon" then
        local pool = pools.uncommon
        if pool and #pool > 0 then
            return pool[math.random(1, #pool)]
        end
        -- Fallback: try global uncommon pool
        if #ForageTuning.UncommonForagePool > 0 then
            return ForageTuning.UncommonForagePool[math.random(1, #ForageTuning.UncommonForagePool)]
        end
        -- Final fallback to common
        rolledTier = "Common"
    end

    -- Common (default)
    local pool = pools.common
    if pool and #pool > 0 then
        return pool[math.random(1, #pool)]
    end
    return "mushroom"
end

-- ForageNode handler
Remotes.ForageNode.OnServerEvent:Connect(function(player, nodeId)
    if type(nodeId) ~= "string" then return end

    -- Strict node ID validation
    if not ForageTuning.NodeWhitelist[nodeId] then
        warn("[ZoneService] Rejected invalid nodeId: " .. tostring(nodeId) .. " from " .. player.Name)
        return
    end

    local pds = _G.PlayerDataService
    if not pds then return end

    local data = pds.getData(player)
    if not data then return end

    -- Get star count for gating
    local stars = data.BrewStats and data.BrewStats.TotalBrewed or 0

    -- Sub-zone node gating: check star threshold
    if not ForageTuning.isNodeUnlocked(nodeId, stars) then
        local threshold, zoneName = ForageTuning.getNodeThreshold(nodeId)
        if threshold then
            pcall(function()
                Remotes.GlobalAnnouncement:FireClient(player, "Reach " .. threshold .. " stars to unlock " .. (zoneName or "this area") .. "!")
            end)
        end
        return
    end

    -- Check cooldown
    local userId = player.UserId
    if not forageCooldowns[userId] then
        forageCooldowns[userId] = {}
    end

    local now = os.time()
    local expiry = forageCooldowns[userId][nodeId] or 0
    if now < expiry then
        return  -- still on cooldown
    end

    -- Set cooldown
    forageCooldowns[userId][nodeId] = now + Types.FORAGE_COOLDOWN_SECONDS

    -- Resolve drop using star-scaled tables
    local ingredientId = resolveForageDrop(player, nodeId)
    if not ingredientId then return end

    -- Add ingredient to inventory
    if pds.addIngredientStack then
        pds.addIngredientStack(data, ingredientId, 1, "forage")
    end

    local ingredient = Ingredients.Data[ingredientId]
    local tierInfo, tierIdx = ForageTuning.getTierForStars(stars)
    print("[ZoneService] " .. player.Name .. " foraged " .. (ingredient and ingredient.name or ingredientId)
        .. " from " .. nodeId .. " (stars=" .. stars .. " tier=" .. tierInfo.tierName .. ")")

    -- Notify client
    pds.notifyClient(player)

    -- Soft storage warning
    if pds.isIngredientStorageFull and pds.isIngredientStorageFull(data) then
        local used = pds.getTotalIngredientUnits(data)
        local cap = pds.getIngredientCapacity(data)
        pcall(function()
            Remotes.GlobalAnnouncement:FireClient(player, "Inventory full! (" .. used .. "/" .. cap .. ") Brew or sell to make room.")
        end)
    end
end)

-- Cleanup on leave
Players.PlayerRemoving:Connect(function(player)
    forageCooldowns[player.UserId] = nil
end)

-- ========== RARE FORAGE NODES (Star-Enhanced) ==========
local RARE_UNCOMMON = {"moonpetal","ember_root","crystal_dust","frost_bloom","thundermoss","shadow_vine","sunstone_chip","dewdrop_pearl","pixie_wing","glowshroom_cap","mermaid_scale","nightshade_berry"}
local RARE_RARE = {"dragon_scale","phoenix_feather","void_essence","unicorn_tear","stormglass_shard","kraken_ink","frozen_amber","ghost_orchid"}

local rareNodeActive = false
local rareNodePart = nil

local function spawnRareNode()
    if rareNodeActive then return end
    rareNodeActive = true
    local grove = workspace.Zones and workspace.Zones:FindFirstChild("WildGrove")
    if not grove then rareNodeActive = false return end
    local x = math.random(-180, -80)
    local z = math.random(-50, 50)

    -- Rare-vs-uncommon split is now determined per-player at trigger time
    -- Pre-pick one from each pool; the trigger handler will re-roll based on player stars
    local uncommonIngredient = RARE_UNCOMMON[math.random(1, #RARE_UNCOMMON)]
    local rareIngredient = RARE_RARE[math.random(1, #RARE_RARE)]

    rareNodePart = Instance.new("Part")
    rareNodePart.Name = "RareForageNode"
    rareNodePart.Shape = Enum.PartType.Ball
    rareNodePart.Size = Vector3.new(5, 5, 5)
    rareNodePart.Position = Vector3.new(x, 4, z)
    rareNodePart.Anchored = true
    rareNodePart.CanCollide = false
    rareNodePart.Material = Enum.Material.Neon
    rareNodePart.Color = Color3.fromRGB(180, 200, 255)
    rareNodePart.Parent = grove

    local light = Instance.new("PointLight")
    light.Color = rareNodePart.Color
    light.Brightness = 3
    light.Range = 25
    light.Parent = rareNodePart

    local particles = Instance.new("ParticleEmitter")
    particles.Color = ColorSequence.new(rareNodePart.Color)
    particles.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.5, 0.3), NumberSequenceKeypoint.new(1, 0)})
    particles.Lifetime = NumberRange.new(1, 3)
    particles.Rate = 12
    particles.Speed = NumberRange.new(1, 3)
    particles.SpreadAngle = Vector2.new(180, 180)
    particles.LightEmission = 1
    particles.Parent = rareNodePart

    local bb = Instance.new("BillboardGui")
    bb.Size = UDim2.new(0, 160, 0, 50)
    bb.StudsOffset = Vector3.new(0, 4, 0)
    bb.AlwaysOnTop = true
    bb.Parent = rareNodePart
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 0.5, 0)
    label.Position = UDim2.new(0, 0, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = "Rare Forage Node"
    label.TextColor3 = Color3.fromRGB(255, 215, 100)
    label.TextScaled = true
    label.Font = Enum.Font.GothamBlack
    label.TextStrokeColor3 = Color3.new(0, 0, 0)
    label.TextStrokeTransparency = 0
    label.Parent = bb
    local tierLabel = Instance.new("TextLabel")
    tierLabel.Size = UDim2.new(1, 0, 0.4, 0)
    tierLabel.Position = UDim2.new(0, 0, 0.55, 0)
    tierLabel.BackgroundTransparency = 1
    tierLabel.Text = "Tap to discover!"
    tierLabel.TextColor3 = Color3.fromRGB(200, 200, 220)
    tierLabel.TextScaled = true
    tierLabel.Font = Enum.Font.GothamBold
    tierLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    tierLabel.TextStrokeTransparency = 0
    tierLabel.Parent = bb

    local prompt = Instance.new("ProximityPrompt")
    prompt.ActionText = "Forage"
    prompt.ObjectText = "Rare Forage Node"
    prompt.MaxActivationDistance = 15
    prompt.RequiresLineOfSight = false
    prompt.Parent = rareNodePart

    prompt.Triggered:Connect(function(triggerPlayer)
        if not rareNodeActive then return end
        local pds = _G.PlayerDataService
        if not pds then return end
        local data = pds.getData(triggerPlayer)
        if not data then return end

        -- Per-player star-scaled rare chance
        local playerStars = data.BrewStats and data.BrewStats.TotalBrewed or 0
        local _, tierIdx = ForageTuning.getTierForStars(playerStars)
        local rareChance = ForageTuning.getRareNodeChance(tierIdx)
        local isRare = math.random() < rareChance
        local ingredientId = isRare and rareIngredient or uncommonIngredient
        local ingData = Ingredients.Data[ingredientId]
        local tierName = isRare and "RARE" or "Uncommon"

        pds.addIngredientStack(data, ingredientId, 1, "forage")
        pds.notifyClient(triggerPlayer)
        print("[ZoneService] " .. triggerPlayer.Name .. " found " .. tierName .. ": " .. (ingData and ingData.name or ingredientId) .. " (stars=" .. playerStars .. " rareChance=" .. string.format("%.0f%%", rareChance * 100) .. ")")
        rareNodeActive = false
        if rareNodePart then rareNodePart:Destroy() rareNodePart = nil end

        -- Soft storage warning
        if pds.isIngredientStorageFull and pds.isIngredientStorageFull(data) then
            local used = pds.getTotalIngredientUnits(data)
            local cap = pds.getIngredientCapacity(data)
            pcall(function()
                Remotes.GlobalAnnouncement:FireClient(triggerPlayer, "Inventory full! (" .. used .. "/" .. cap .. ") Brew or sell to make room.")
            end)
        end
    end)

    if Remotes:FindFirstChild("GlobalAnnouncement") then
        for _, p in ipairs(game.Players:GetPlayers()) do
            pcall(function() Remotes.GlobalAnnouncement:FireClient(p, "A rare ingredient appeared in the Wild Grove!") end)
        end
    end

    print("[ZoneService] Rare forage node spawned at (" .. x .. ", " .. z .. ")")

    task.delay(60, function()
        if rareNodeActive and rareNodePart then
            rareNodePart:Destroy()
            rareNodePart = nil
            rareNodeActive = false
        end
    end)
end

task.spawn(function()
    task.wait(30)
    while true do
        spawnRareNode()
        task.wait(math.random(120, 240))
    end
end)


print("[ZoneService] Initialized (Sprint 011 - Starbound Foraging)")
