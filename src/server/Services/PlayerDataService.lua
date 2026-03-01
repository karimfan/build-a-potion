local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local RS = game:GetService("ReplicatedStorage")
local Types = require(RS.Shared.Types)
local IngredientsConfig = require(RS.Shared.Config.Ingredients)
local Remotes = RS.Remotes

local DATASTORE_NAME = Types.DATASTORE_NAME
local AUTOSAVE_INTERVAL = Types.AUTOSAVE_INTERVAL

local PlayerData = {}
local DataStore = DataStoreService:GetDataStore(DATASTORE_NAME)

-- ============================================================
-- V3 DEFAULT PROFILE
-- ============================================================
local function getDefaultBrewStats()
    return {
        TotalBrewed = 0,
        TotalValueBrewed = 0,
        CurrentStreak = 0,
        BestStreak = 0,
        PotionCounts = {},
    }
end

local function getDefaultActiveBrew()
    return {
        Status = Types.BrewStatus.Idle,
        StartUnix = 0, EndUnix = 0,
        IngredientA = "", IngredientB = "",
        ResultPotionId = "", IsNewDiscovery = false,
    }
end

local function getDefaultProfile()
    return {
        Version = Types.DATASTORE_VERSION,
        Coins = Types.STARTING_COINS,
        Ingredients = {},  -- V3: { [id] = { stacks = { {amount, acquiredUnix, expiresUnix, source}, ... } } }
        Potions = {},
        DiscoveredRecipes = {},
        LastLoginUnix = os.time(),
        BrewStats = getDefaultBrewStats(),
        ActiveBrew = getDefaultActiveBrew(),
        Score = {
            TimePlayedMinutes = 0,
            TotalCoinsFromSelling = 0,
            BrewScoreCache = 0,
            MutationScoreCache = 0,
            CompositeScore = 0,
            LastLeaderboardWriteUnix = 0,
        },
        Upgrades = {
            CauldronTier = 1,
            BrewStations = 1,
            StorageSlots = 20,
        },
        DailyDemandState = {
            LastSoldDateKey = "",
            SoldPotionIds = {},
        },
    }
end

-- ============================================================
-- MIGRATION V1/V2 → V3
-- ============================================================
local function migrateProfile(data)
    -- V1 → V2: Add BrewStats + ActiveBrew
    if not data.Version or data.Version < 2 then
        if not data.BrewStats then data.BrewStats = getDefaultBrewStats() end
        if not data.ActiveBrew then data.ActiveBrew = getDefaultActiveBrew() end
        data.Version = 2
        print("[PlayerDataService] Migrated V1 → V2")
    end

    -- V2 → V3: Convert numeric Ingredients to stack-based
    if data.Version < 3 then
        local oldIngredients = data.Ingredients or {}
        local newIngredients = {}
        local now = os.time()

        for ingredientId, value in pairs(oldIngredients) do
            if type(value) == "number" and value > 0 then
                -- Old format: just a count. Convert to stack.
                local config = IngredientsConfig.Data[ingredientId]
                local shelfHours = config and config.freshness and config.freshness.shelfLifeHours or 24
                newIngredients[ingredientId] = {
                    stacks = {
                        {
                            amount = value,
                            acquiredUnix = now,
                            expiresUnix = now + (shelfHours * 3600),
                            source = "legacy",
                        }
                    }
                }
            elseif type(value) == "table" and value.stacks then
                -- Already V3 format (idempotent)
                newIngredients[ingredientId] = value
            end
        end

        data.Ingredients = newIngredients
        data.Version = 3
        print("[PlayerDataService] Migrated V2 → V3 (stack inventory)")
    end

    -- V3 → V4: Add Score, Upgrades, DailyDemandState
    if data.Version < 4 then
        if not data.Score then
            data.Score = {
                TimePlayedMinutes = 0, TotalCoinsFromSelling = 0,
                BrewScoreCache = 0, MutationScoreCache = 0,
                CompositeScore = 0, LastLeaderboardWriteUnix = 0,
            }
        end
        if not data.Upgrades then
            data.Upgrades = { CauldronTier = 1, BrewStations = 1, StorageSlots = 20 }
        end
        if not data.DailyDemandState then
            data.DailyDemandState = { LastSoldDateKey = "", SoldPotionIds = {} }
        end
        data.Version = 4
        print("[PlayerDataService] Migrated V3 → V4 (score + upgrades)")
    end

    -- Defensive: ensure all V3 fields exist
    if not data.BrewStats then data.BrewStats = getDefaultBrewStats() end
    if not data.ActiveBrew then data.ActiveBrew = getDefaultActiveBrew() end
    if not data.BrewStats.PotionCounts then data.BrewStats.PotionCounts = {} end
    if not data.BrewStats.CurrentStreak then data.BrewStats.CurrentStreak = 0 end
    if not data.BrewStats.BestStreak then data.BrewStats.BestStreak = 0 end
    if not data.Score then data.Score = { TimePlayedMinutes = 0, TotalCoinsFromSelling = 0, BrewScoreCache = 0, MutationScoreCache = 0, CompositeScore = 0, LastLeaderboardWriteUnix = 0 } end
    if not data.Upgrades then data.Upgrades = { CauldronTier = 1, BrewStations = 1, StorageSlots = 20 } end
    if not data.DailyDemandState then data.DailyDemandState = { LastSoldDateKey = "", SoldPotionIds = {} } end

    return data
end

-- ============================================================
-- FRESHNESS UTILITIES
-- ============================================================
local function computeFreshness(stack, now)
    now = now or os.time()
    if not stack.expiresUnix or not stack.acquiredUnix then return 1.0 end
    local totalLife = stack.expiresUnix - stack.acquiredUnix
    if totalLife <= 0 then return 0 end
    local remaining = stack.expiresUnix - now
    return math.clamp(remaining / totalLife, 0, 1)
end

local function getFreshnessState(freshness)
    if freshness > 0.7 then return Types.FreshnessState.Fresh
    elseif freshness > 0.5 then return Types.FreshnessState.Stable
    elseif freshness > 0.2 then return Types.FreshnessState.Stale
    else return Types.FreshnessState.Expired end
end

-- Get total quantity of an ingredient (sum all stacks)
local function getIngredientCount(data, ingredientId)
    local entry = data.Ingredients[ingredientId]
    if not entry or not entry.stacks then return 0 end
    local total = 0
    for _, stack in ipairs(entry.stacks) do
        total = total + (stack.amount or 0)
    end
    return total
end

-- Add a new stack (from buying/foraging)
local function addIngredientStack(data, ingredientId, amount, source)
    local config = IngredientsConfig.Data[ingredientId]
    local shelfHours = config and config.freshness and config.freshness.shelfLifeHours or 24
    local now = os.time()

    if not data.Ingredients[ingredientId] then
        data.Ingredients[ingredientId] = { stacks = {} }
    end

    table.insert(data.Ingredients[ingredientId].stacks, {
        amount = amount,
        acquiredUnix = now,
        expiresUnix = now + (shelfHours * 3600),
        source = source or "market",
    })
end

-- Consume from oldest stacks first (FIFO), returns average freshness of consumed
local function consumeIngredientFIFO(data, ingredientId, amount)
    local entry = data.Ingredients[ingredientId]
    if not entry or not entry.stacks then return 0, 0 end

    local remaining = amount
    local totalFreshness = 0
    local totalConsumed = 0
    local now = os.time()

    -- Sort stacks by acquiredUnix (oldest first)
    table.sort(entry.stacks, function(a, b) return a.acquiredUnix < b.acquiredUnix end)

    local newStacks = {}
    for _, stack in ipairs(entry.stacks) do
        if remaining <= 0 then
            table.insert(newStacks, stack)
        elseif stack.amount <= remaining then
            -- Consume entire stack
            local f = computeFreshness(stack, now)
            totalFreshness = totalFreshness + f * stack.amount
            totalConsumed = totalConsumed + stack.amount
            remaining = remaining - stack.amount
        else
            -- Partially consume stack
            local f = computeFreshness(stack, now)
            totalFreshness = totalFreshness + f * remaining
            totalConsumed = totalConsumed + remaining
            stack.amount = stack.amount - remaining
            remaining = 0
            table.insert(newStacks, stack)
        end
    end

    entry.stacks = newStacks

    -- Clean up empty entries
    if #entry.stacks == 0 then
        data.Ingredients[ingredientId] = nil
    end

    local avgFreshness = totalConsumed > 0 and (totalFreshness / totalConsumed) or 0
    return totalConsumed, avgFreshness
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

-- ============================================================
-- LOAD / SAVE
-- ============================================================
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
        print("[PlayerDataService] Loaded data for " .. player.Name .. " (V" .. data.Version .. ")")
    else
        PlayerData[player.UserId] = getDefaultProfile()
        if not success then
            warn("[PlayerDataService] Failed to load for " .. player.Name .. ", using defaults")
        else
            print("[PlayerDataService] New player: " .. player.Name)
        end
    end

    Remotes.PlayerDataUpdate:FireClient(player, PlayerData[player.UserId])
end

local function savePlayerData(player)
    local data = PlayerData[player.UserId]
    if not data then return end
    local userId = tostring(player.UserId)
    local success, err

    for attempt = 1, 3 do
        success, err = pcall(function()
            DataStore:SetAsync("Player_" .. userId, data)
        end)
        if success then break end
        warn("[PlayerDataService] Save attempt " .. attempt .. " failed: " .. tostring(err))
        task.wait(attempt * 2)
    end
end

local function forceSave(player)
    task.spawn(function() savePlayerData(player) end)
end

-- ============================================================
-- PUBLIC API
-- ============================================================
local module = {}

function module.getData(player) return PlayerData[player.UserId] end
function module.notifyClient(player)
    local data = PlayerData[player.UserId]
    if data then Remotes.PlayerDataUpdate:FireClient(player, data) end
end
function module.forceSave(player) forceSave(player) end

-- Stack utilities exposed for other services
module.getIngredientCount = getIngredientCount
module.addIngredientStack = addIngredientStack
module.consumeIngredientFIFO = consumeIngredientFIFO
module.computeFreshness = computeFreshness
module.getFreshnessState = getFreshnessState

_G.PlayerDataService = module

-- ============================================================
-- CONNECTIONS
-- ============================================================
Players.PlayerAdded:Connect(function(player) loadPlayerData(player) end)
Players.PlayerRemoving:Connect(function(player) savePlayerData(player); PlayerData[player.UserId] = nil end)

task.spawn(function()
    while true do
        task.wait(AUTOSAVE_INTERVAL)
        for _, player in ipairs(Players:GetPlayers()) do
            task.spawn(function() savePlayerData(player) end)
        end
    end
end)

game:BindToClose(function()
    for _, player in ipairs(Players:GetPlayers()) do
        task.spawn(function() savePlayerData(player) end)
    end
    task.wait(3)
end)

Remotes.GetPlayerData.OnServerInvoke = function(player) return PlayerData[player.UserId] end

print("[PlayerDataService] Initialized (V3 - Stack Inventory)")
