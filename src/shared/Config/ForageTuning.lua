local ForageTuning = {}

-- Star tiers aligned with BrewTuning.EvolutionTiers
-- Each tier: {threshold, commonWeight, uncommonWeight, rareWeight, tierName}
ForageTuning.StarTiers = {
    { threshold = 0,   commonWeight = 1.00, uncommonWeight = 0.00, rareWeight = 0.00, tierName = "Apprentice" },
    { threshold = 10,  commonWeight = 0.85, uncommonWeight = 0.15, rareWeight = 0.00, tierName = "Adept" },
    { threshold = 25,  commonWeight = 0.70, uncommonWeight = 0.28, rareWeight = 0.02, tierName = "Alchemist" },
    { threshold = 50,  commonWeight = 0.55, uncommonWeight = 0.38, rareWeight = 0.07, tierName = "Master" },
    { threshold = 100, commonWeight = 0.45, uncommonWeight = 0.45, rareWeight = 0.10, tierName = "Archmage" },
}

-- Uncommon ingredients available via star-boosted foraging
ForageTuning.UncommonForagePool = {
    "moonpetal", "ember_root", "crystal_dust", "frost_bloom",
    "thundermoss", "shadow_vine", "sunstone_chip", "dewdrop_pearl",
    "iron_filings", "pixie_wing", "glowshroom_cap", "sulfur_nugget",
    "mermaid_scale", "nightshade_berry", "wind_whistle_reed",
}

-- Rare ingredients available via star-boosted foraging
ForageTuning.RareForagePool = {
    "dragon_scale", "phoenix_feather", "void_essence", "unicorn_tear",
    "stormglass_shard", "kraken_ink", "frozen_amber", "ghost_orchid",
    "basilisk_fang", "siren_song_echo", "eclipse_petal", "celestial_dew",
}

-- Sub-zone definitions
ForageTuning.SubZones = {
    {
        name = "Starlight Glade",
        threshold = 10,
        nodeIds = { "ForageNode_13", "ForageNode_14" },
    },
    {
        name = "Moonwell Spring",
        threshold = 25,
        nodeIds = { "ForageNode_15", "ForageNode_16" },
    },
    {
        name = "Shadow Hollow",
        threshold = 50,
        nodeIds = { "ForageNode_17", "ForageNode_18" },
    },
}

-- Rare forage node rare-vs-uncommon chance by tier (per triggering player)
ForageTuning.RareNodeChanceByTier = {
    [0] = 0.30,
    [1] = 0.35,
    [2] = 0.40,
    [3] = 0.50,
    [4] = 0.60,
}

-- Valid node IDs (whitelist)
ForageTuning.NodeWhitelist = {}
for i = 1, 18 do
    ForageTuning.NodeWhitelist["ForageNode_" .. i] = true
end

-- Base node rarity-bucketed pools (reclassified from original ZoneService pools)
-- Nodes 1-12: existing pools split by rarity
ForageTuning.NodePools = {
    ForageNode_1  = { common = {"mushroom", "willow_bark", "snail_slime"} },
    ForageNode_2  = { common = {"river_water", "rainwater", "snail_slime"} },
    ForageNode_3  = { common = {"fern_leaf", "mint_sprig", "dandelion_puff"} },
    ForageNode_4  = { common = {"cobweb_strand", "charcoal_chunk", "pebble_dust"} },
    ForageNode_5  = { common = {"acorn_cap", "pebble_dust", "willow_bark"} },
    ForageNode_6  = { common = {"clay_mud", "honey_drop", "firefly_glow"} },
    ForageNode_7  = { common = {"mushroom", "willow_bark"}, uncommon = {"glowshroom_cap"} },
    ForageNode_8  = { common = {"river_water", "rainwater"}, uncommon = {"dewdrop_pearl"} },
    ForageNode_9  = { common = {"fern_leaf", "mint_sprig", "dandelion_puff"} },
    ForageNode_10 = { common = {"cobweb_strand", "charcoal_chunk"}, uncommon = {"nightshade_berry"} },
    ForageNode_11 = { common = {"acorn_cap", "willow_bark", "honey_drop"} },
    ForageNode_12 = { common = {"clay_mud", "firefly_glow", "mint_sprig"} },
    -- Sub-zone nodes (richer pools)
    ForageNode_13 = { common = {"mushroom", "fern_leaf"}, uncommon = {"moonpetal", "glowshroom_cap", "sunstone_chip"} },
    ForageNode_14 = { common = {"river_water", "rainwater"}, uncommon = {"crystal_dust", "dewdrop_pearl", "frost_bloom"} },
    ForageNode_15 = { common = {"dandelion_puff", "mint_sprig"}, uncommon = {"pixie_wing", "mermaid_scale", "wind_whistle_reed"} },
    ForageNode_16 = { common = {"cobweb_strand", "willow_bark"}, uncommon = {"thundermoss", "shadow_vine", "nightshade_berry"} },
    ForageNode_17 = { common = {"charcoal_chunk"}, uncommon = {"ember_root", "sulfur_nugget"}, rare = {"dragon_scale", "phoenix_feather"} },
    ForageNode_18 = { common = {"snail_slime"}, uncommon = {"iron_filings", "nightshade_berry"}, rare = {"void_essence", "ghost_orchid", "frozen_amber"} },
}

-- Get the star tier data for a given star count
function ForageTuning.getTierForStars(starCount)
    local current = ForageTuning.StarTiers[1]
    local tierIndex = 0
    for i, tier in ipairs(ForageTuning.StarTiers) do
        if starCount >= tier.threshold then
            current = tier
            tierIndex = i - 1
        end
    end
    return current, tierIndex
end

-- Roll a forage rarity tier based on star count
-- Returns "Common", "Uncommon", or "Rare"
function ForageTuning.rollForageTier(starCount)
    local tier = ForageTuning.getTierForStars(starCount)
    local roll = math.random()
    if roll <= tier.rareWeight then
        return "Rare"
    elseif roll <= tier.rareWeight + tier.uncommonWeight then
        return "Uncommon"
    else
        return "Common"
    end
end

-- Check if a node is unlocked for a given star count
function ForageTuning.isNodeUnlocked(nodeId, starCount)
    -- Base nodes (1-12) always unlocked
    local num = tonumber(nodeId:match("ForageNode_(%d+)"))
    if not num then return false end
    if num <= 12 then return true end
    -- Sub-zone nodes: check threshold
    for _, zone in ipairs(ForageTuning.SubZones) do
        for _, nid in ipairs(zone.nodeIds) do
            if nid == nodeId then
                return starCount >= zone.threshold
            end
        end
    end
    return false
end

-- Get the sub-zone threshold for a node (nil if base node)
function ForageTuning.getNodeThreshold(nodeId)
    for _, zone in ipairs(ForageTuning.SubZones) do
        for _, nid in ipairs(zone.nodeIds) do
            if nid == nodeId then
                return zone.threshold, zone.name
            end
        end
    end
    return nil, nil
end

-- Get the rare node rare-chance for a given tier index
function ForageTuning.getRareNodeChance(tierIndex)
    return ForageTuning.RareNodeChanceByTier[tierIndex] or 0.30
end

-- Get a display string for the forage bonus
function ForageTuning.getBonusDisplay(starCount)
    local tier = ForageTuning.getTierForStars(starCount)
    local uncommonPct = math.floor(tier.uncommonWeight * 100 + 0.5)
    local rarePct = math.floor(tier.rareWeight * 100 + 0.5)
    if rarePct > 0 then
        return tier.tierName .. " Forager", "+" .. uncommonPct .. "% Uncommon, +" .. rarePct .. "% Rare"
    elseif uncommonPct > 0 then
        return tier.tierName .. " Forager", "+" .. uncommonPct .. "% Uncommon"
    else
        return tier.tierName .. " Forager", "Common drops"
    end
end

return ForageTuning
