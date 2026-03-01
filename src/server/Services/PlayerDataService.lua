local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local RS = game:GetService("ReplicatedStorage")
local Types = require(RS.Shared.Types)
local Remotes = RS.Remotes

local DATASTORE_NAME = Types.DATASTORE_NAME
local AUTOSAVE_INTERVAL = Types.AUTOSAVE_INTERVAL

-- Session cache: PlayerData[userId] = data table
local PlayerData = {}
local DataStore = DataStoreService:GetDataStore(DATASTORE_NAME)

-- Default BrewStats for new/migrated players
local function getDefaultBrewStats()
    return {
        TotalBrewed = 0,
        TotalValueBrewed = 0,
        CurrentStreak = 0,
        BestStreak = 0,
        PotionCounts = {},
    }
end

-- Default ActiveBrew state
local function getDefaultActiveBrew()
    return {
        Status = Types.BrewStatus.Idle,
        StartUnix = 0,
        EndUnix = 0,
        IngredientA = "",
        IngredientB = "",
        ResultPotionId = "",
        IsNewDiscovery = false,
    }
end

-- Default profile for new players (V2)
local function getDefaultProfile()
    return {
        Version = Types.DATASTORE_VERSION,
        Coins = Types.STARTING_COINS,
        Ingredients = {},
        Potions = {},
        DiscoveredRecipes = {},
        LastLoginUnix = os.time(),
        BrewStats = getDefaultBrewStats(),
        ActiveBrew = getDefaultActiveBrew(),
    }
end

-- Migrate V1 profile to V2 (idempotent)
local function migrateProfile(data)
    if not data.Version or data.Version < 2 then
        -- Add BrewStats if missing
        if not data.BrewStats then
            data.BrewStats = getDefaultBrewStats()
        end
        -- Add ActiveBrew if missing
        if not data.ActiveBrew then
            data.ActiveBrew = getDefaultActiveBrew()
        end
        data.Version = 2
        print("[PlayerDataService] Migrated profile from V1 to V2")
    end
    
    -- Ensure all fields exist (defensive)
    if not data.BrewStats then data.BrewStats = getDefaultBrewStats() end
    if not data.ActiveBrew then data.ActiveBrew = getDefaultActiveBrew() end
    if not data.BrewStats.PotionCounts then data.BrewStats.PotionCounts = {} end
    if not data.BrewStats.CurrentStreak then data.BrewStats.CurrentStreak = 0 end
    if not data.BrewStats.BestStreak then data.BrewStats.BestStreak = 0 end
    
    return data
end

-- Reconcile stale active brews on login
local function reconcileActiveBrew(data)
    local brew = data.ActiveBrew
    if brew and brew.Status == Types.BrewStatus.Brewing then
        if os.time() >= (brew.EndUnix or 0) then
            brew.Status = Types.BrewStatus.CompletedUnclaimed
            print("[PlayerDataService] Reconciled stale brew -> completed_unclaimed")
        end
    end
end

-- Load player data from DataStore with retry
local function loadPlayerData(player)
    local userId = tostring(player.UserId)
    local success, data = false, nil
    
    for attempt = 1, 3 do
        success, data = pcall(function()
            return DataStore:GetAsync("Player_" .. userId)
        end)
        if success then break end
        warn("[PlayerDataService] Load attempt " .. attempt .. " failed for " .. player.Name)
        task.wait(attempt * 2)
    end
    
    if success and data then
        data = migrateProfile(data)
        reconcileActiveBrew(data)
        data.LastLoginUnix = os.time()
        PlayerData[player.UserId] = data
        print("[PlayerDataService] Loaded data for " .. player.Name)
    else
        PlayerData[player.UserId] = getDefaultProfile()
        if not success then
            warn("[PlayerDataService] Failed to load data for " .. player.Name .. ", using defaults")
        else
            print("[PlayerDataService] New player: " .. player.Name)
        end
    end
    
    Remotes.PlayerDataUpdate:FireClient(player, PlayerData[player.UserId])
end

-- Save player data to DataStore with retry
local function savePlayerData(player)
    local data = PlayerData[player.UserId]
    if not data then return end
    
    local userId = tostring(player.UserId)
    local success, err = false, nil
    
    for attempt = 1, 3 do
        success, err = pcall(function()
            DataStore:SetAsync("Player_" .. userId, data)
        end)
        if success then break end
        warn("[PlayerDataService] Save attempt " .. attempt .. " failed for " .. player.Name .. ": " .. tostring(err))
        task.wait(attempt * 2)
    end
    
    if success then
        -- silent success (reduce log spam)
    else
        warn("[PlayerDataService] FAILED to save data for " .. player.Name .. " after 3 attempts")
    end
end

-- Force save (for critical transitions like brew start/claim)
local function forceSave(player)
    task.spawn(function()
        savePlayerData(player)
    end)
end

-- Public API
local module = {}

function module.getData(player)
    return PlayerData[player.UserId]
end

function module.notifyClient(player)
    local data = PlayerData[player.UserId]
    if data then
        Remotes.PlayerDataUpdate:FireClient(player, data)
    end
end

function module.forceSave(player)
    forceSave(player)
end

_G.PlayerDataService = module

-- Player join
Players.PlayerAdded:Connect(function(player)
    loadPlayerData(player)
end)

-- Player leave: save immediately
Players.PlayerRemoving:Connect(function(player)
    savePlayerData(player)
    PlayerData[player.UserId] = nil
end)

-- Autosave loop
task.spawn(function()
    while true do
        task.wait(AUTOSAVE_INTERVAL)
        for _, player in ipairs(Players:GetPlayers()) do
            task.spawn(function()
                savePlayerData(player)
            end)
        end
    end
end)

-- BindToClose: save all on server shutdown
game:BindToClose(function()
    for _, player in ipairs(Players:GetPlayers()) do
        task.spawn(function()
            savePlayerData(player)
        end)
    end
    task.wait(3)
end)

-- GetPlayerData RemoteFunction
Remotes.GetPlayerData.OnServerInvoke = function(player)
    return PlayerData[player.UserId]
end

print("[PlayerDataService] Initialized")

