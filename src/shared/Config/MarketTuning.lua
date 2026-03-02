local MarketTuning = {}

MarketTuning.REFRESH_SECONDS = 300  -- 5 minutes

-- Tier caps: max offers per tier per refresh
MarketTuning.TierCaps = {
    Common = 8,
    Uncommon = 5,
    Rare = 3,
    Mythic = 2,
    Divine = 1,
}

-- Guaranteed minimums per refresh (deterministic backfill)
MarketTuning.MinCommon = 4
MarketTuning.MinUncommon = 2
MarketTuning.MinRarePlus = 1  -- at least 1 Rare/Mythic/Divine (flash sale)

-- Stock quantity ranges per tier
MarketTuning.TierRules = {
    Common = {
        minStock = 10,
        maxStock = 20,
    },
    Uncommon = {
        minStock = 3,
        maxStock = 8,
    },
    Rare = {
        minStock = 1,
        maxStock = 2,
    },
    Mythic = {
        minStock = 1,
        maxStock = 1,
    },
    Divine = {
        minStock = 1,
        maxStock = 1,
    },
}

return MarketTuning
