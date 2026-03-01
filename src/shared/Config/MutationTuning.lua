local MutationTuning = {}

-- Base mutation chance (before bonuses)
MutationTuning.BaseChance = 0.05  -- 5%

-- Maximum total mutation chance (cap)
MutationTuning.MaxChance = 0.20  -- 20%

-- Tier bonus to mutation chance (per ingredient used)
MutationTuning.TierBonus = {
    Common = 0.00,
    Uncommon = 0.01,
    Rare = 0.02,
    Mythic = 0.03,
    Divine = 0.04,
}

-- Freshness bonus
-- avgFreshness >= 0.85 → +1%, >= 0.65 → +0.5%, else +0%
MutationTuning.FreshnessBonus = {
    { threshold = 0.85, bonus = 0.01 },
    { threshold = 0.65, bonus = 0.005 },
}

-- Mutation types with weights and sell multipliers
-- Weights are relative (will be normalized)
MutationTuning.Types = {
    Glowing = {
        name = "Glowing",
        sellMultiplier = 2.0,
        weight = 40,
        color = {200, 255, 150},  -- soft green glow
    },
    Bubbling = {
        name = "Bubbling",
        sellMultiplier = 2.5,
        weight = 25,
        color = {100, 200, 255},  -- blue bubbles
    },
    Crystallized = {
        name = "Crystallized",
        sellMultiplier = 3.0,
        weight = 15,
        color = {200, 220, 255},  -- crystal white-blue
    },
    Shadow = {
        name = "Shadow",
        sellMultiplier = 4.0,
        weight = 10,
        color = {80, 40, 120},    -- dark purple
    },
    Rainbow = {
        name = "Rainbow",
        sellMultiplier = 6.0,
        weight = 7,
        color = {255, 200, 100},  -- golden rainbow
    },
    Golden = {
        name = "Golden",
        sellMultiplier = 10.0,
        weight = 3,
        color = {255, 215, 0},    -- pure gold
    },
}

-- Order for display
MutationTuning.TypeOrder = {"Glowing", "Bubbling", "Crystallized", "Shadow", "Rainbow", "Golden"}

-- Total weight for normalization
local totalWeight = 0
for _, data in pairs(MutationTuning.Types) do
    totalWeight = totalWeight + data.weight
end
MutationTuning.TotalWeight = totalWeight

-- Calculate total mutation chance from ingredients and freshness
function MutationTuning.calculateChance(ingredientTiers, avgFreshness)
    local chance = MutationTuning.BaseChance

    -- Add tier bonuses
    for _, tier in ipairs(ingredientTiers) do
        chance = chance + (MutationTuning.TierBonus[tier] or 0)
    end

    -- Add freshness bonus
    for _, fb in ipairs(MutationTuning.FreshnessBonus) do
        if avgFreshness >= fb.threshold then
            chance = chance + fb.bonus
            break
        end
    end

    return math.min(chance, MutationTuning.MaxChance)
end

-- Roll for mutation type (weighted random)
function MutationTuning.rollMutationType()
    local roll = math.random() * MutationTuning.TotalWeight
    local cumulative = 0
    for _, typeName in ipairs(MutationTuning.TypeOrder) do
        cumulative = cumulative + MutationTuning.Types[typeName].weight
        if roll <= cumulative then
            return typeName
        end
    end
    return "Glowing" -- fallback
end

-- Mutations that trigger global announcements
MutationTuning.AnnounceMutations = {
    Rainbow = true,
    Golden = true,
}

return MutationTuning
