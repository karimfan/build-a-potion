local BrewTuning = {}

-- Brew timer by potion rarity (seconds)
BrewTuning.TimerByRarity = {
    Common = 60,
    Uncommon = 90,
    Rare = 120,
    Mythic = 180,
    Divine = 300,
}

-- Sludge (failed brew) always uses Common timer
BrewTuning.SludgeTimer = 60

-- VFX intensity multiplier by rarity
BrewTuning.VFXMultiplier = {
    Common = 1.0,
    Uncommon = 1.3,
    Rare = 1.8,
    Mythic = 2.5,
    Divine = 3.0,
}

-- Streak rules
BrewTuning.StreakResetOnSludge = true

-- Evolution tier thresholds (TotalBrewed)
BrewTuning.EvolutionTiers = {
    { threshold = 0,   tier = 0, name = "Apprentice" },
    { threshold = 10,  tier = 1, name = "Adept" },
    { threshold = 25,  tier = 2, name = "Alchemist" },
    { threshold = 50,  tier = 3, name = "Master" },
    { threshold = 100, tier = 4, name = "Archmage" },
}

-- Get evolution tier for a given brew count
function BrewTuning.getEvolutionTier(totalBrewed)
    local currentTier = BrewTuning.EvolutionTiers[1]
    for _, tierInfo in ipairs(BrewTuning.EvolutionTiers) do
        if totalBrewed >= tierInfo.threshold then
            currentTier = tierInfo
        end
    end
    return currentTier
end

-- Get brew duration for a potion rarity
function BrewTuning.getDuration(rarity)
    return BrewTuning.TimerByRarity[rarity] or BrewTuning.SludgeTimer
end

return BrewTuning

