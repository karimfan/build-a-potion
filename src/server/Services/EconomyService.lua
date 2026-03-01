local RS = game:GetService("ReplicatedStorage")
local Types = require(RS.Shared.Types)
local Ingredients = require(RS.Shared.Config.Ingredients)
local Potions = require(RS.Shared.Config.Potions)
local Remotes = RS.Remotes

-- Rate limiting: track last action time per player
local lastActionTime = {}
local COOLDOWN = 0.5  -- seconds between actions

local function canAct(player)
    local now = tick()
    local last = lastActionTime[player.UserId] or 0
    if now - last < COOLDOWN then
        return false
    end
    lastActionTime[player.UserId] = now
    return true
end

-- BuyIngredient handler
Remotes.BuyIngredient.OnServerEvent:Connect(function(player, ingredientId, quantity)
    if not canAct(player) then return end
    quantity = quantity or 1
    if type(ingredientId) ~= "string" or type(quantity) ~= "number" then return end
    if quantity < 1 or quantity > 99 then return end
    quantity = math.floor(quantity)
    
    local pds = _G.PlayerDataService
    local ms = _G.MarketService
    if not pds or not ms then return end
    
    local data = pds.getData(player)
    if not data then return end
    
    -- Validate ingredient exists
    local ingredient = Ingredients.Data[ingredientId]
    if not ingredient then
        warn("[EconomyService] Invalid ingredient: " .. tostring(ingredientId))
        return
    end
    
    -- Check market has stock
    local totalCost = ingredient.cost * quantity
    
    -- Validate coins
    if data.Coins < totalCost then
        warn("[EconomyService] " .. player.Name .. " insufficient coins for " .. ingredientId)
        return
    end
    
    -- Deduct market stock
    if not ms.deductStock(ingredientId, quantity) then
        warn("[EconomyService] " .. player.Name .. " insufficient market stock for " .. ingredientId)
        return
    end
    
    -- Execute transaction
    data.Coins = data.Coins - totalCost
    -- V3: Add as fresh stack
    local pdsModule = _G.PlayerDataService
    if pdsModule and pdsModule.addIngredientStack then
        pdsModule.addIngredientStack(data, ingredientId, quantity, "market")
    else
        -- Fallback for compatibility
        if not data.Ingredients[ingredientId] then
            data.Ingredients[ingredientId] = { stacks = {} }
        end
        local config = Ingredients.Data[ingredientId]
        local shelfHours = config and config.freshness and config.freshness.shelfLifeHours or 24
        local now = os.time()
        table.insert(data.Ingredients[ingredientId].stacks, {
            amount = quantity,
            acquiredUnix = now,
            expiresUnix = now + (shelfHours * 3600),
            source = "market",
        })
    end
    
    print("[EconomyService] " .. player.Name .. " bought " .. quantity .. "x " .. ingredient.name .. " for " .. totalCost .. " coins")
    
    -- Notify client of updated data
    pds.notifyClient(player)
end)

-- SellPotion handler
Remotes.SellPotion.OnServerEvent:Connect(function(player, potionId, quantity)
    if not canAct(player) then return end
    quantity = quantity or 1
    if type(potionId) ~= "string" or type(quantity) ~= "number" then return end
    if quantity < 1 or quantity > 99 then return end
    quantity = math.floor(quantity)
    
    local pds = _G.PlayerDataService
    if not pds then return end
    
    local data = pds.getData(player)
    if not data then return end
    
    -- Validate potion exists
    local baseId = potionId:find('__') and potionId:sub(1, potionId:find('__') - 1) or potionId
    local potion = Potions.Data[baseId]
    if not potion then
        warn("[EconomyService] Invalid potion: " .. tostring(potionId))
        return
    end
    
    -- Validate player has the potion
    local owned = data.Potions[potionId] or 0
    if owned < quantity then
        warn("[EconomyService] " .. player.Name .. " doesn't have enough " .. potionId)
        return
    end
    
    -- Execute transaction
    -- Mutation-aware sell value
    local baseSellValue = potion.sellValue
    local sep = potionId:find("__")
    if sep then
        local mutName = potionId:sub(sep + 2)
        local ok, MutTuning = pcall(require, RS.Shared.Config.MutationTuning)
        if ok and MutTuning.Types[mutName] then
            baseSellValue = math.floor(baseSellValue * MutTuning.Types[mutName].sellMultiplier)
        end
    end
    local totalValue = baseSellValue * quantity
    data.Potions[potionId] = owned - quantity
    if data.Potions[potionId] <= 0 then
        data.Potions[potionId] = nil
    end
    data.Coins = data.Coins + totalValue
    
    print("[EconomyService] " .. player.Name .. " sold " .. quantity .. "x " .. potion.name .. " for " .. totalValue .. " coins")
    
    -- Notify client
    pds.notifyClient(player)
end)

print("[EconomyService] Initialized")
