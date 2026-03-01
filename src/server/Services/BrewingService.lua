local RS = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Recipes = require(RS.Shared.Config.Recipes)
local Potions = require(RS.Shared.Config.Potions)
local BrewTuning = require(RS.Shared.Config.BrewTuning)
local Types = require(RS.Shared.Types)
local Remotes = RS.Remotes

local BrewStatus = Types.BrewStatus

-- Rate limiting
local lastActionTime = {}
local ACTION_COOLDOWN = 1.0

local function rateLimited(player)
    local now = tick()
    local last = lastActionTime[player.UserId] or 0
    if now - last < ACTION_COOLDOWN then
        return true
    end
    lastActionTime[player.UserId] = now
    return false
end

-- ============================================================
-- BrewPotion: Start a timed brew
-- ============================================================
Remotes.BrewPotion.OnServerInvoke = function(player, ingredientId1, ingredientId2)
    if rateLimited(player) then
        return { success = false, error = "Too fast! Wait a moment." }
    end
    
    -- Validate inputs
    if type(ingredientId1) ~= "string" or type(ingredientId2) ~= "string" then
        return { success = false, error = "Invalid ingredients." }
    end
    
    local pds = _G.PlayerDataService
    if not pds then
        return { success = false, error = "Server not ready." }
    end
    
    local data = pds.getData(player)
    if not data then
        return { success = false, error = "Player data not loaded." }
    end
    
    -- Check no active brew
    if data.ActiveBrew and data.ActiveBrew.Status ~= BrewStatus.Idle then
        return { success = false, error = "Already brewing! Wait for current brew to finish." }
    end
    
    -- Validate player owns both ingredients
    -- V3: Get ingredient counts from stacks
    local pdsUtil = _G.PlayerDataService
    local owned1 = pdsUtil and pdsUtil.getIngredientCount(data, ingredientId1) or 0
    local owned2 = pdsUtil and pdsUtil.getIngredientCount(data, ingredientId2) or 0
    
    if ingredientId1 == ingredientId2 then
        if owned1 < 2 then
            return { success = false, error = "Not enough " .. ingredientId1 .. "." }
        end
    else
        if owned1 < 1 then
            return { success = false, error = "You don't have " .. ingredientId1 .. "." }
        end
        if owned2 < 1 then
            return { success = false, error = "You don't have " .. ingredientId2 .. "." }
        end
    end
    
    -- Consume ingredients atomically
    -- V3: Consume from stacks (FIFO - oldest first)
    local freshness1, freshness2 = 1.0, 1.0
    if ingredientId1 == ingredientId2 then
        local consumed, avgFresh = pdsUtil.consumeIngredientFIFO(data, ingredientId1, 2)
        freshness1 = avgFresh
        freshness2 = avgFresh
    else
        local c1, f1 = pdsUtil.consumeIngredientFIFO(data, ingredientId1, 1)
        local c2, f2 = pdsUtil.consumeIngredientFIFO(data, ingredientId2, 1)
        freshness1 = f1
        freshness2 = f2
    end
    local avgFreshness = (freshness1 + freshness2) / 2
    
    -- Resolve recipe
    local potionId = Recipes.lookup(ingredientId1, ingredientId2)
    if not potionId then
        potionId = "sludge"
    end
    
    -- Check for new discovery
    local isNewDiscovery = false
    if potionId ~= "sludge" then
        local sorted = {ingredientId1, ingredientId2}
        table.sort(sorted)
        local recipeKey = sorted[1] .. "|" .. sorted[2]
        if not data.DiscoveredRecipes[recipeKey] then
            data.DiscoveredRecipes[recipeKey] = true
            isNewDiscovery = true
        end
    end
    
    -- Determine brew duration from potion rarity
    local potion = Potions.Data[potionId]
    local rarity = potion and potion.tier or "Common"
    local duration = BrewTuning.getDuration(rarity)
    if potionId == "sludge" then
        duration = BrewTuning.SludgeTimer
    end
    
    -- Set ActiveBrew state
    local now = os.time()
    data.ActiveBrew = {
        Status = BrewStatus.Brewing,
        StartUnix = now,
        EndUnix = now + duration,
        IngredientA = ingredientId1,
        IngredientB = ingredientId2,
        ResultPotionId = potionId,
        IsNewDiscovery = isNewDiscovery,
    }
    
    -- Force save (critical transition)
    pds.forceSave(player)
    pds.notifyClient(player)
    
    local potionName = potion and potion.name or "Unknown"
    print("[BrewingService] " .. player.Name .. " started brewing " .. potionName .. " (" .. duration .. "s)")
    
    return {
        success = true,
        potionId = potionId,
        potionName = potionName,
        rarity = rarity,
        brewDuration = duration,
        endUnix = now + duration,
        isNewDiscovery = isNewDiscovery,
        sellValue = potion and potion.sellValue or 0,
    }
end

-- ============================================================
-- ClaimBrewResult: Claim completed brew
-- ============================================================
Remotes.ClaimBrewResult.OnServerInvoke = function(player)
    if rateLimited(player) then
        return { success = false, error = "Too fast!" }
    end
    
    local pds = _G.PlayerDataService
    if not pds then
        return { success = false, error = "Server not ready." }
    end
    
    local data = pds.getData(player)
    if not data or not data.ActiveBrew then
        return { success = false, error = "No active brew." }
    end
    
    local brew = data.ActiveBrew
    
    -- Check if brew is done
    if brew.Status == BrewStatus.Brewing then
        if os.time() < brew.EndUnix then
            local remaining = brew.EndUnix - os.time()
            return { success = false, error = "Brew not ready! " .. remaining .. "s remaining." }
        end
        -- Timer expired, transition to completed
        brew.Status = BrewStatus.CompletedUnclaimed
    end
    
    if brew.Status ~= BrewStatus.CompletedUnclaimed then
        return { success = false, error = "No completed brew to claim." }
    end
    
    -- Grant potion to inventory
    local potionId = brew.ResultPotionId
    data.Potions[potionId] = (data.Potions[potionId] or 0) + 1
    
    local potion = Potions.Data[potionId]
    local potionName = potion and potion.name or "Unknown"
    local sellValue = potion and potion.sellValue or 0
    local isNewDiscovery = brew.IsNewDiscovery
    
    -- Update BrewStats
    local stats = data.BrewStats
    stats.TotalBrewed = (stats.TotalBrewed or 0) + 1
    stats.TotalValueBrewed = (stats.TotalValueBrewed or 0) + sellValue
    stats.PotionCounts[potionId] = (stats.PotionCounts[potionId] or 0) + 1
    
    -- Streak logic
    if potionId == "sludge" then
        stats.CurrentStreak = 0
    else
        stats.CurrentStreak = (stats.CurrentStreak or 0) + 1
        if stats.CurrentStreak > (stats.BestStreak or 0) then
            stats.BestStreak = stats.CurrentStreak
        end
    end
    
    -- Check evolution tier change
    local oldTier = BrewTuning.getEvolutionTier((stats.TotalBrewed or 1) - 1)
    local newTier = BrewTuning.getEvolutionTier(stats.TotalBrewed)
    local tierChanged = oldTier.tier ~= newTier.tier
    
    -- Clear ActiveBrew
    data.ActiveBrew = {
        Status = BrewStatus.Idle,
        StartUnix = 0,
        EndUnix = 0,
        IngredientA = "",
        IngredientB = "",
        ResultPotionId = "",
        IsNewDiscovery = false,
    }
    
    -- Force save (critical transition)
    pds.forceSave(player)
    pds.notifyClient(player)
    
    print("[BrewingService] " .. player.Name .. " claimed " .. potionName .. 
        (isNewDiscovery and " (NEW DISCOVERY!)" or "") ..
        (tierChanged and (" [TIER UP: " .. newTier.name .. "]") or ""))
    
    return {
        success = true,
        potionId = potionId,
        potionName = potionName,
        sellValue = sellValue,
        isNewDiscovery = isNewDiscovery,
        rarity = potion and potion.tier or "Common",
        stats = {
            TotalBrewed = stats.TotalBrewed,
            TotalValueBrewed = stats.TotalValueBrewed,
            CurrentStreak = stats.CurrentStreak,
            BestStreak = stats.BestStreak,
        },
        tierChanged = tierChanged,
        newTier = tierChanged and newTier or nil,
    }
end

-- ============================================================
-- GetActiveBrewState: Sync brew state to client
-- ============================================================
Remotes.GetActiveBrewState.OnServerInvoke = function(player)
    local pds = _G.PlayerDataService
    if not pds then return nil end
    
    local data = pds.getData(player)
    if not data or not data.ActiveBrew then return nil end
    
    local brew = data.ActiveBrew
    
    -- Auto-transition if timer expired
    if brew.Status == BrewStatus.Brewing and os.time() >= brew.EndUnix then
        brew.Status = BrewStatus.CompletedUnclaimed
    end
    
    return {
        status = brew.Status,
        startUnix = brew.StartUnix,
        endUnix = brew.EndUnix,
        resultPotionId = brew.ResultPotionId,
        isNewDiscovery = brew.IsNewDiscovery,
    }
end

print("[BrewingService] Initialized (Sprint 003 - Timed Brewing)")
