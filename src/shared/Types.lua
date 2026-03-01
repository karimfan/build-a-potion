local Types = {}

Types.Tiers = {
    Common = "Common",
    Uncommon = "Uncommon",
    Rare = "Rare",
    Mythic = "Mythic",
    Divine = "Divine",
}

Types.Elements = {
    Fire = "Fire",
    Water = "Water",
    Earth = "Earth",
    Air = "Air",
    Shadow = "Shadow",
    Light = "Light",
}

-- Brew states
Types.BrewStatus = {
    Idle = "idle",
    Brewing = "brewing",
    CompletedUnclaimed = "completed_unclaimed",
}

-- Freshness states
Types.FreshnessState = {
    Fresh = "Fresh",       -- > 0.7
    Stable = "Stable",     -- 0.5 - 0.7
    Stale = "Stale",       -- 0.2 - 0.5
    Expired = "Expired",   -- < 0.2
}

-- Acquisition sources
Types.AcquisitionSource = {
    Market = "market",
    Forage = "forage",
    Robux = "robux",
    Legacy = "legacy",
}

Types.STARTING_COINS = 100
Types.MARKET_REFRESH_SECONDS = 300
Types.FORAGE_COOLDOWN_SECONDS = 60
Types.AUTOSAVE_INTERVAL = 60
Types.DATASTORE_NAME = "BrewAPotionPlayerData"
Types.DATASTORE_VERSION = 4

return Types