local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Types = require(RS.Shared.Types)
local Ingredients = require(RS.Shared.Config.Ingredients)
local Remotes = RS.Remotes

local REFRESH_SECONDS = Types.MARKET_REFRESH_SECONDS

-- Current market state (global per server)
local MarketState = {
    RefreshTime = 0,
    Offers = {},
}

-- Tier stock ranges
local TierStock = {
    Common =   { min = 10, max = 20 },
    Uncommon = { min = 3,  max = 8  },
    Rare =     { min = 1,  max = 2  },
    Mythic =   { min = 1,  max = 1  },
    Divine =   { min = 1,  max = 1  },
}

-- Tier caps per refresh
local TierCaps = {
    Common = 8,
    Uncommon = 5,
    Rare = 3,
    Mythic = 2,
    Divine = 1,
}

-- Minimum Common floor
local COMMON_FLOOR = 3

-- Generate offers by rolling each ingredient individually
local function generateOffers()
    local offers = {}
    local tierCounts = { Common = 0, Uncommon = 0, Rare = 0, Mythic = 0, Divine = 0 }
    local now = os.time()

    -- Collect all market-eligible ingredients
    local eligible = Ingredients.getMarketEligible()

    -- Shuffle for fairness
    for i = #eligible, 2, -1 do
        local j = math.random(1, i)
        eligible[i], eligible[j] = eligible[j], eligible[i]
    end

    -- Roll each ingredient
    for _, ing in ipairs(eligible) do
        local tier = ing.tier
        local cap = TierCaps[tier] or 5

        -- Check tier cap
        if tierCounts[tier] and tierCounts[tier] >= cap then
            continue
        end

        -- Roll per-ingredient chance
        if math.random() <= (ing.marketChance or 0) then
            local stockRange = TierStock[tier] or TierStock.Common
            local stock = math.random(stockRange.min, stockRange.max)

            table.insert(offers, {
                ingredientId = ing.id,
                name = ing.name,
                tier = ing.tier,
                element = ing.element,
                price = ing.cost,
                stock = stock,
                generatedAtUnix = now,
            })

            tierCounts[tier] = (tierCounts[tier] or 0) + 1
        end
    end

    -- Enforce Common floor: if fewer than COMMON_FLOOR commons, add some
    if tierCounts.Common < COMMON_FLOOR then
        local commons = Ingredients.getByTier("Common")
        for i = #commons, 2, -1 do
            local j = math.random(1, i)
            commons[i], commons[j] = commons[j], commons[i]
        end

        local needed = COMMON_FLOOR - tierCounts.Common
        local added = 0
        for _, ing in ipairs(commons) do
            if added >= needed then break end
            -- Check not already in offers
            local found = false
            for _, offer in ipairs(offers) do
                if offer.ingredientId == ing.id then found = true break end
            end
            if not found then
                local stockRange = TierStock.Common
                table.insert(offers, {
                    ingredientId = ing.id,
                    name = ing.name,
                    tier = ing.tier,
                    element = ing.element,
                    price = ing.cost,
                    stock = math.random(stockRange.min, stockRange.max),
                    generatedAtUnix = now,
                })
                added = added + 1
            end
        end
    end

    return offers, tierCounts
end

-- Refresh market
local function refreshMarket()
    local offers, tierCounts = generateOffers()
    MarketState.Offers = offers
    MarketState.RefreshTime = os.time() + REFRESH_SECONDS

    -- Log
    local summary = {}
    for tier, count in pairs(tierCounts) do
        if count > 0 then table.insert(summary, tier .. "=" .. count) end
    end
    print("[MarketService] Refreshed with " .. #offers .. " offers (" .. table.concat(summary, ", ") .. ")")

    -- Fire global announcement for Mythic/Divine
    for _, offer in ipairs(offers) do
        if offer.tier == "Mythic" or offer.tier == "Divine" then
            local msg = offer.tier == "Divine"
                and ("A " .. offer.name .. " has appeared in the market! (DIVINE)")
                or ("A " .. offer.name .. " has appeared in the market!")
            -- Announce to all players
            for _, player in ipairs(Players:GetPlayers()) do
                pcall(function()
                    Remotes.PlayerDataUpdate:FireClient(player, nil) -- trigger refresh
                end)
            end
            print("[MarketService] ANNOUNCEMENT: " .. msg)
        end
    end

    -- Broadcast to all connected clients
    for _, player in ipairs(Players:GetPlayers()) do
        pcall(function()
            Remotes.MarketRefresh:FireClient(player, MarketState)
        end)
    end
end

-- Initial refresh
refreshMarket()
print("[MarketService] Market refreshed with " .. #MarketState.Offers .. " offers. Next refresh in " .. REFRESH_SECONDS .. "s")

-- Refresh loop
task.spawn(function()
    while true do
        task.wait(REFRESH_SECONDS)
        refreshMarket()
    end
end)

-- GetMarketOffers RemoteFunction
Remotes.GetMarketOffers.OnServerInvoke = function(player)
    return MarketState
end

print("[MarketService] Initialized (per-ingredient odds)")
