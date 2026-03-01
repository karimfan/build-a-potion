local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local RS = game:GetService("ReplicatedStorage")
local Remotes = RS.Remotes

local LEADERBOARD_KEY = "GlobalScoreV1"
local WRITE_COOLDOWN = 30  -- seconds between writes per player
local READ_CADENCE = 60    -- seconds between top-N refreshes
local TOP_N = 50

local orderedDS = nil
pcall(function()
    orderedDS = DataStoreService:GetOrderedDataStore(LEADERBOARD_KEY)
end)

local lastWriteTime = {}  -- [userId] = os.time()
local cachedTopList = {}   -- { {userId, name, score}, ... }

-- Write score to OrderedDataStore (throttled)
local function writeScore(player, score)
    if not orderedDS then return end
    local userId = player.UserId
    local now = os.time()
    if lastWriteTime[userId] and (now - lastWriteTime[userId]) < WRITE_COOLDOWN then
        return -- throttled
    end
    lastWriteTime[userId] = now
    
    task.spawn(function()
        local ok, err = pcall(function()
            orderedDS:SetAsync("u_" .. tostring(userId), score)
        end)
        if not ok then
            warn("[LeaderboardService] Write failed for " .. player.Name .. ": " .. tostring(err))
        end
    end)
end

-- Read top N from OrderedDataStore
local function refreshTopList()
    if not orderedDS then return end
    
    local ok, pages = pcall(function()
        return orderedDS:GetSortedAsync(false, TOP_N)
    end)
    
    if ok and pages then
        local newList = {}
        local page = pages:GetCurrentPage()
        for rank, entry in ipairs(page) do
            local userId = tonumber(entry.key:gsub("u_", ""))
            local playerName = "Player" .. tostring(userId)
            -- Try to get display name
            pcall(function()
                playerName = Players:GetNameFromUserIdAsync(userId)
            end)
            table.insert(newList, {
                rank = rank,
                userId = userId,
                name = playerName,
                score = entry.value,
            })
        end
        cachedTopList = newList
    end
end

-- Public API
local module = {}

function module.updateScore(player, score)
    writeScore(player, score)
end

function module.getTopList()
    return cachedTopList
end

function module.getPlayerRank(userId)
    for _, entry in ipairs(cachedTopList) do
        if entry.userId == userId then
            return entry.rank
        end
    end
    return nil
end

_G.LeaderboardService = module

-- Create GetLeaderboard remote if it doesn't exist
if not Remotes:FindFirstChild("GetLeaderboard") then
    local r = Instance.new("RemoteFunction")
    r.Name = "GetLeaderboard"
    r.Parent = Remotes
end

Remotes.GetLeaderboard.OnServerInvoke = function(player)
    return {
        topList = cachedTopList,
        playerRank = module.getPlayerRank(player.UserId),
    }
end

-- Refresh loop
task.spawn(function()
    while true do
        pcall(refreshTopList)
        task.wait(READ_CADENCE)
    end
end)

-- Write scores when they change (hook from ScoreService)
Players.PlayerRemoving:Connect(function(player)
    lastWriteTime[player.UserId] = nil
end)

-- Periodic score write for all connected players
task.spawn(function()
    while true do
        task.wait(WRITE_COOLDOWN)
        local pds = _G.PlayerDataService
        if pds then
            for _, player in ipairs(Players:GetPlayers()) do
                local data = pds.getData(player)
                if data and data.Score then
                    module.updateScore(player, data.Score.CompositeScore or 0)
                end
            end
        end
    end
end)

print("[LeaderboardService] Initialized (Global OrderedDataStore)")
