local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Types = require(RS.Shared.Types)
local Ingredients = require(RS.Shared.Config.Ingredients)
local MarketTuning = require(RS.Shared.Config.MarketTuning)
local Remotes = RS.Remotes

-- Current market state (global, shared by all players on this server)
local MarketState = {
    RefreshTime = 0,
    Offers = {},  -- { {ingredientId, price, stock}, ... }
}

-- Generate new market offers based on rarity weights
local function generateOffers()
    local offers = {}
    
    for tierName, rules in pairs(MarketTuning.TierRules) do
        -- Roll chance for this tier
        if math.random() <= rules.chance then
            -- Get all ingredients of this tier
            local tierIngredients = Ingredients.getByTier(tierName)
            if #tierIngredients > 0 then
                -- Shuffle
                for i = #tierIngredients, 2, -1 do
                    local j = math.random(1, i)
                    tierIngredients[i], tierIngredients[j] = tierIngredients[j], tierIngredients[i]
                end
                
                -- Pick random number of offers within range
                local numOffers = math.random(rules.minOffers, rules.maxOffers)
                numOffers = math.min(numOffers, #tierIngredients)
                
                for i = 1, numOffers do
                    local ingredient = tierIngredients[i]
                    local stock = math.random(rules.minStock, rules.maxStock)
                    table.insert(offers, {
                        ingredientId = ingredient.id,
                        name = ingredient.name,
                        tier = ingredient.tier,
                        element = ingredient.element,
                        price = ingredient.cost,
                        stock = stock,
                    })
                end
            end
        end
    end
    
    return offers
end

-- Refresh market
local function refreshMarket()
    MarketState.Offers = generateOffers()
    MarketState.RefreshTime = os.time() + MarketTuning.REFRESH_SECONDS
    
    -- Broadcast to all connected clients
    for _, player in ipairs(Players:GetPlayers()) do
        Remotes.MarketRefresh:FireClient(player, MarketState)
    end
    
    print("[MarketService] Market refreshed with " .. #MarketState.Offers .. " offers. Next refresh in " .. MarketTuning.REFRESH_SECONDS .. "s")
end

-- Store globally for EconomyService to access
_G.MarketService = {
    getState = function()
        return MarketState
    end,
    deductStock = function(ingredientId, amount)
        for _, offer in ipairs(MarketState.Offers) do
            if offer.ingredientId == ingredientId then
                if offer.stock >= amount then
                    offer.stock = offer.stock - amount
                    return true
                end
                return false
            end
        end
        return false
    end,
}

-- GetMarketOffers RemoteFunction
Remotes.GetMarketOffers.OnServerInvoke = function(player)
    return MarketState
end

-- Initial market generation
refreshMarket()

-- Market refresh loop
task.spawn(function()
    while true do
        task.wait(MarketTuning.REFRESH_SECONDS)
        refreshMarket()
    end
end)

print("[MarketService] Initialized")

