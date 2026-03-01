local MarketTuning = {}

MarketTuning.REFRESH_SECONDS = 300  -- 5 minutes

-- How many offers per tier to generate each refresh
-- chance = probability this tier appears, min/max = stock quantity range
MarketTuning.TierRules = {
    Common = {
        chance = 1.0,       -- always appears
        minOffers = 4,      -- at least 4 common ingredients offered
        maxOffers = 6,
        minStock = 10,
        maxStock = 20,
    },
    Uncommon = {
        chance = 0.6,       -- 60% chance per refresh
        minOffers = 1,
        maxOffers = 2,
        minStock = 3,
        maxStock = 8,
    },
    Rare = {
        chance = 0.15,      -- 15% chance per refresh
        minOffers = 1,
        maxOffers = 1,
        minStock = 1,
        maxStock = 2,
    },
}

return MarketTuning
