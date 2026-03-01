local Ingredients = {}

--[[
    Full ingredient catalog: 58 ingredients across 5 tiers
    Each ingredient has: id, name, tier, element, cost, description,
    marketChance, affinity, freshness, visual, acquisition
]]

Ingredients.Data = {
    -- ============================================================
    -- COMMON TIER (15) - Always in stock, forageable, earthy basics
    -- ============================================================
    mushroom = {
        id = "mushroom", name = "Mushroom", tier = "Common",
        element = "Earth", cost = 5, description = "A common forest mushroom with mild magical properties.",
        marketChance = 1.0, affinity = "Stable",
        freshness = { shelfLifeHours = 24 },
        visual = { archetype = "mushroom", primaryColor = {139, 90, 43}, secondaryColor = {200, 180, 150}, material = "SmoothPlastic", emissive = false, particleRate = 0 },
        acquisition = { market = true, forage = true, robuxProductId = nil },
    },
    fern_leaf = {
        id = "fern_leaf", name = "Fern Leaf", tier = "Common",
        element = "Earth", cost = 8, description = "A curled fern frond that thrums with natural energy.",
        marketChance = 1.0, affinity = "Harmonious",
        freshness = { shelfLifeHours = 24 },
        visual = { archetype = "leaf", primaryColor = {50, 140, 50}, secondaryColor = {30, 100, 30}, material = "LeafyGrass", emissive = false, particleRate = 0 },
        acquisition = { market = true, forage = true, robuxProductId = nil },
    },
    river_water = {
        id = "river_water", name = "River Water", tier = "Common",
        element = "Water", cost = 5, description = "Crystal clear water from an enchanted stream.",
        marketChance = 1.0, affinity = "Stable",
        freshness = { shelfLifeHours = 24 },
        visual = { archetype = "vial", primaryColor = {80, 160, 255}, secondaryColor = {40, 100, 200}, material = "Glass", emissive = false, particleRate = 0 },
        acquisition = { market = true, forage = true, robuxProductId = nil },
    },
    charcoal_chunk = {
        id = "charcoal_chunk", name = "Charcoal Chunk", tier = "Common",
        element = "Fire", cost = 10, description = "Burnt wood fragments that still hold warmth.",
        marketChance = 1.0, affinity = "Volatile",
        freshness = { shelfLifeHours = 24 },
        visual = { archetype = "ember", primaryColor = {40, 30, 30}, secondaryColor = {200, 80, 0}, material = "Slate", emissive = false, particleRate = 1 },
        acquisition = { market = true, forage = true, robuxProductId = nil },
    },
    dandelion_puff = {
        id = "dandelion_puff", name = "Dandelion Puff", tier = "Common",
        element = "Air", cost = 7, description = "Floats away if not caught quickly.",
        marketChance = 1.0, affinity = "Chaotic",
        freshness = { shelfLifeHours = 24 },
        visual = { archetype = "flower", primaryColor = {255, 255, 240}, secondaryColor = {200, 200, 180}, material = "SmoothPlastic", emissive = false, particleRate = 2 },
        acquisition = { market = true, forage = true, robuxProductId = nil },
    },
    clay_mud = {
        id = "clay_mud", name = "Clay Mud", tier = "Common",
        element = "Earth", cost = 6, description = "Scooped from enchanted riverbanks.",
        marketChance = 1.0, affinity = "Stable",
        freshness = { shelfLifeHours = 24 },
        visual = { archetype = "orb", primaryColor = {140, 100, 60}, secondaryColor = {100, 70, 40}, material = "Slate", emissive = false, particleRate = 0 },
        acquisition = { market = true, forage = true, robuxProductId = nil },
    },
    honey_drop = {
        id = "honey_drop", name = "Honey Drop", tier = "Common",
        element = "Light", cost = 12, description = "Sweet base for many beginner potions.",
        marketChance = 1.0, affinity = "Harmonious",
        freshness = { shelfLifeHours = 24 },
        visual = { archetype = "tear", primaryColor = {255, 200, 50}, secondaryColor = {200, 150, 0}, material = "Glass", emissive = false, particleRate = 0 },
        acquisition = { market = true, forage = false, robuxProductId = nil },
    },
    pebble_dust = {
        id = "pebble_dust", name = "Pebble Dust", tier = "Common",
        element = "Earth", cost = 5, description = "Ground-up river stones with binding power.",
        marketChance = 1.0, affinity = "Stable",
        freshness = { shelfLifeHours = 24 },
        visual = { archetype = "dust", primaryColor = {150, 140, 130}, secondaryColor = {100, 95, 90}, material = "Granite", emissive = false, particleRate = 1 },
        acquisition = { market = true, forage = true, robuxProductId = nil },
    },
    mint_sprig = {
        id = "mint_sprig", name = "Mint Sprig", tier = "Common",
        element = "Air", cost = 9, description = "Refreshing herb that grows everywhere.",
        marketChance = 1.0, affinity = "Harmonious",
        freshness = { shelfLifeHours = 24 },
        visual = { archetype = "leaf", primaryColor = {60, 180, 80}, secondaryColor = {40, 140, 60}, material = "LeafyGrass", emissive = false, particleRate = 0 },
        acquisition = { market = true, forage = true, robuxProductId = nil },
    },
    firefly_glow = {
        id = "firefly_glow", name = "Firefly Glow", tier = "Common",
        element = "Light", cost = 15, description = "Captured at dusk in Wild Grove.",
        marketChance = 1.0, affinity = "Chaotic",
        freshness = { shelfLifeHours = 24 },
        visual = { archetype = "orb", primaryColor = {200, 255, 100}, secondaryColor = {150, 200, 50}, material = "Neon", emissive = true, particleRate = 3 },
        acquisition = { market = true, forage = false, robuxProductId = nil },
    },
    snail_slime = {
        id = "snail_slime", name = "Snail Slime", tier = "Common",
        element = "Water", cost = 8, description = "Oddly useful binding agent.",
        marketChance = 1.0, affinity = "Stable",
        freshness = { shelfLifeHours = 24 },
        visual = { archetype = "vial", primaryColor = {130, 200, 130}, secondaryColor = {80, 150, 80}, material = "Glass", emissive = false, particleRate = 0 },
        acquisition = { market = true, forage = true, robuxProductId = nil },
    },
    willow_bark = {
        id = "willow_bark", name = "Willow Bark", tier = "Common",
        element = "Earth", cost = 10, description = "Stripped from enchanted grove trees.",
        marketChance = 1.0, affinity = "Harmonious",
        freshness = { shelfLifeHours = 24 },
        visual = { archetype = "shard", primaryColor = {120, 80, 40}, secondaryColor = {90, 60, 30}, material = "WoodPlanks", emissive = false, particleRate = 0 },
        acquisition = { market = true, forage = true, robuxProductId = nil },
    },
    rainwater = {
        id = "rainwater", name = "Rainwater", tier = "Common",
        element = "Water", cost = 5, description = "Collected during magical rain events.",
        marketChance = 1.0, affinity = "Stable",
        freshness = { shelfLifeHours = 24 },
        visual = { archetype = "tear", primaryColor = {100, 180, 255}, secondaryColor = {60, 130, 220}, material = "Glass", emissive = false, particleRate = 1 },
        acquisition = { market = true, forage = true, robuxProductId = nil },
    },
    acorn_cap = {
        id = "acorn_cap", name = "Acorn Cap", tier = "Common",
        element = "Earth", cost = 7, description = "Tiny but potent natural container.",
        marketChance = 1.0, affinity = "Stable",
        freshness = { shelfLifeHours = 24 },
        visual = { archetype = "mushroom", primaryColor = {160, 120, 60}, secondaryColor = {100, 80, 40}, material = "Wood", emissive = false, particleRate = 0 },
        acquisition = { market = true, forage = true, robuxProductId = nil },
    },
    cobweb_strand = {
        id = "cobweb_strand", name = "Cobweb Strand", tier = "Common",
        element = "Shadow", cost = 12, description = "Found in dark corners of the grove.",
        marketChance = 1.0, affinity = "Chaotic",
        freshness = { shelfLifeHours = 24 },
        visual = { archetype = "silk", primaryColor = {200, 200, 210}, secondaryColor = {150, 140, 160}, material = "SmoothPlastic", emissive = false, particleRate = 0 },
        acquisition = { market = true, forage = true, robuxProductId = nil },
    },
    -- ============================================================
    -- UNCOMMON TIER (14) - 50-60% chance, mystical reagents
    -- ============================================================
    moonpetal = {
        id = "moonpetal", name = "Moonpetal", tier = "Uncommon",
        element = "Light", cost = 50, description = "Blooms only under moonlight cycles.",
        marketChance = 0.60, affinity = "Harmonious",
        freshness = { shelfLifeHours = 18 },
        visual = { archetype = "flower", primaryColor = {220, 220, 255}, secondaryColor = {180, 180, 240}, material = "SmoothPlastic", emissive = true, particleRate = 2 },
        acquisition = { market = true, forage = false, robuxProductId = nil },
    },
    ember_root = {
        id = "ember_root", name = "Ember Root", tier = "Uncommon",
        element = "Fire", cost = 75, description = "Warm to the touch, glows faintly.",
        marketChance = 0.60, affinity = "Volatile",
        freshness = { shelfLifeHours = 18 },
        visual = { archetype = "shard", primaryColor = {200, 80, 20}, secondaryColor = {255, 140, 40}, material = "Slate", emissive = true, particleRate = 2 },
        acquisition = { market = true, forage = false, robuxProductId = nil },
    },
    crystal_dust = {
        id = "crystal_dust", name = "Crystal Dust", tier = "Uncommon",
        element = "Earth", cost = 100, description = "Shimmering powder from cave crystals.",
        marketChance = 0.60, affinity = "Stable",
        freshness = { shelfLifeHours = 18 },
        visual = { archetype = "dust", primaryColor = {200, 220, 255}, secondaryColor = {150, 180, 220}, material = "Glass", emissive = true, particleRate = 3 },
        acquisition = { market = true, forage = false, robuxProductId = nil },
    },
    frost_bloom = {
        id = "frost_bloom", name = "Frost Bloom", tier = "Uncommon",
        element = "Water", cost = 80, description = "Ice flower that never melts.",
        marketChance = 0.60, affinity = "Harmonious",
        freshness = { shelfLifeHours = 18 },
        visual = { archetype = "flower", primaryColor = {180, 220, 255}, secondaryColor = {120, 180, 240}, material = "Ice", emissive = true, particleRate = 2 },
        acquisition = { market = true, forage = false, robuxProductId = nil },
    },
    thundermoss = {
        id = "thundermoss", name = "Thundermoss", tier = "Uncommon",
        element = "Air", cost = 65, description = "Crackles with static electricity.",
        marketChance = 0.60, affinity = "Volatile",
        freshness = { shelfLifeHours = 18 },
        visual = { archetype = "mushroom", primaryColor = {100, 120, 80}, secondaryColor = {200, 230, 50}, material = "Grass", emissive = false, particleRate = 3 },
        acquisition = { market = true, forage = false, robuxProductId = nil },
    },
    shadow_vine = {
        id = "shadow_vine", name = "Shadow Vine", tier = "Uncommon",
        element = "Shadow", cost = 90, description = "Writhing plant from dark places.",
        marketChance = 0.60, affinity = "Chaotic",
        freshness = { shelfLifeHours = 18 },
        visual = { archetype = "leaf", primaryColor = {60, 30, 80}, secondaryColor = {100, 50, 130}, material = "SmoothPlastic", emissive = false, particleRate = 2 },
        acquisition = { market = true, forage = false, robuxProductId = nil },
    },
    sunstone_chip = {
        id = "sunstone_chip", name = "Sunstone Chip", tier = "Uncommon",
        element = "Fire", cost = 110, description = "Fragment of a sun-warmed boulder.",
        marketChance = 0.60, affinity = "Stable",
        freshness = { shelfLifeHours = 18 },
        visual = { archetype = "crystal", primaryColor = {255, 200, 50}, secondaryColor = {255, 160, 0}, material = "Glass", emissive = true, particleRate = 2 },
        acquisition = { market = true, forage = false, robuxProductId = nil },
    },
    dewdrop_pearl = {
        id = "dewdrop_pearl", name = "Dewdrop Pearl", tier = "Uncommon",
        element = "Water", cost = 70, description = "Morning dew crystallized into a bead.",
        marketChance = 0.60, affinity = "Harmonious",
        freshness = { shelfLifeHours = 18 },
        visual = { archetype = "tear", primaryColor = {200, 230, 255}, secondaryColor = {160, 200, 240}, material = "Glass", emissive = true, particleRate = 1 },
        acquisition = { market = true, forage = false, robuxProductId = nil },
    },
    iron_filings = {
        id = "iron_filings", name = "Iron Filings", tier = "Uncommon",
        element = "Earth", cost = 55, description = "Magnetic shavings with binding power.",
        marketChance = 0.60, affinity = "Stable",
        freshness = { shelfLifeHours = 18 },
        visual = { archetype = "dust", primaryColor = {100, 100, 110}, secondaryColor = {60, 60, 70}, material = "Metal", emissive = false, particleRate = 1 },
        acquisition = { market = true, forage = false, robuxProductId = nil },
    },
    pixie_wing = {
        id = "pixie_wing", name = "Pixie Wing", tier = "Uncommon",
        element = "Air", cost = 120, description = "Iridescent and feather-light.",
        marketChance = 0.55, affinity = "Chaotic",
        freshness = { shelfLifeHours = 18 },
        visual = { archetype = "feather", primaryColor = {220, 180, 255}, secondaryColor = {180, 140, 220}, material = "Glass", emissive = true, particleRate = 3 },
        acquisition = { market = true, forage = false, robuxProductId = nil },
    },
    glowshroom_cap = {
        id = "glowshroom_cap", name = "Glowshroom Cap", tier = "Uncommon",
        element = "Light", cost = 95, description = "Bioluminescent mushroom variant.",
        marketChance = 0.60, affinity = "Harmonious",
        freshness = { shelfLifeHours = 18 },
        visual = { archetype = "mushroom", primaryColor = {100, 255, 150}, secondaryColor = {50, 200, 100}, material = "Neon", emissive = true, particleRate = 2 },
        acquisition = { market = true, forage = false, robuxProductId = nil },
    },
    sulfur_nugget = {
        id = "sulfur_nugget", name = "Sulfur Nugget", tier = "Uncommon",
        element = "Fire", cost = 60, description = "Pungent but powerful catalyst.",
        marketChance = 0.60, affinity = "Volatile",
        freshness = { shelfLifeHours = 18 },
        visual = { archetype = "crystal", primaryColor = {220, 200, 50}, secondaryColor = {180, 160, 30}, material = "Slate", emissive = false, particleRate = 1 },
        acquisition = { market = true, forage = false, robuxProductId = nil },
    },
    mermaid_scale = {
        id = "mermaid_scale", name = "Mermaid Scale", tier = "Uncommon",
        element = "Water", cost = 130, description = "Shed scale, shimmers in water.",
        marketChance = 0.50, affinity = "Harmonious",
        freshness = { shelfLifeHours = 18 },
        visual = { archetype = "scale", primaryColor = {80, 200, 200}, secondaryColor = {50, 150, 180}, material = "Glass", emissive = true, particleRate = 2 },
        acquisition = { market = true, forage = false, robuxProductId = nil },
    },
    nightshade_berry = {
        id = "nightshade_berry", name = "Nightshade Berry", tier = "Uncommon",
        element = "Shadow", cost = 85, description = "Dark purple, handle with care.",
        marketChance = 0.60, affinity = "Volatile",
        freshness = { shelfLifeHours = 18 },
        visual = { archetype = "orb", primaryColor = {80, 20, 100}, secondaryColor = {120, 40, 150}, material = "SmoothPlastic", emissive = false, particleRate = 1 },
        acquisition = { market = true, forage = false, robuxProductId = nil },
    },
    wind_whistle_reed = {
        id = "wind_whistle_reed", name = "Wind Whistle Reed", tier = "Uncommon",
        element = "Air", cost = 70, description = "Hums when exposed to any breeze.",
        marketChance = 0.60, affinity = "Stable",
        freshness = { shelfLifeHours = 18 },
        visual = { archetype = "leaf", primaryColor = {180, 200, 150}, secondaryColor = {140, 170, 110}, material = "Grass", emissive = false, particleRate = 1 },
        acquisition = { market = true, forage = false, robuxProductId = nil },
    },
    -- ============================================================
    -- RARE TIER (15) - 10-15% chance, legendary reagents with dramatic visuals
    -- ============================================================
    dragon_scale = {
        id = "dragon_scale", name = "Dragon Scale", tier = "Rare",
        element = "Fire", cost = 500, description = "Shed by young drakes, extremely durable.",
        marketChance = 0.15, affinity = "Volatile",
        freshness = { shelfLifeHours = 12 },
        visual = { archetype = "scale", primaryColor = {200, 30, 30}, secondaryColor = {255, 100, 0}, material = "Metal", emissive = true, particleRate = 4 },
        acquisition = { market = true, forage = false, robuxProductId = nil },
    },
    phoenix_feather = {
        id = "phoenix_feather", name = "Phoenix Feather", tier = "Rare",
        element = "Fire", cost = 650, description = "Warm, regenerates slowly over time.",
        marketChance = 0.12, affinity = "Harmonious",
        freshness = { shelfLifeHours = 12 },
        visual = { archetype = "feather", primaryColor = {255, 180, 30}, secondaryColor = {255, 80, 0}, material = "Neon", emissive = true, particleRate = 5 },
        acquisition = { market = true, forage = false, robuxProductId = nil },
    },
    void_essence = {
        id = "void_essence", name = "Void Essence", tier = "Rare",
        element = "Shadow", cost = 800, description = "Bottled fragment of pure darkness.",
        marketChance = 0.10, affinity = "Chaotic",
        freshness = { shelfLifeHours = 12 },
        visual = { archetype = "orb", primaryColor = {20, 10, 30}, secondaryColor = {100, 30, 150}, material = "ForceField", emissive = true, particleRate = 4 },
        acquisition = { market = true, forage = false, robuxProductId = nil },
    },
    unicorn_tear = {
        id = "unicorn_tear", name = "Unicorn Tear", tier = "Rare",
        element = "Light", cost = 700, description = "Purifying liquid, extremely precious.",
        marketChance = 0.12, affinity = "Harmonious",
        freshness = { shelfLifeHours = 12 },
        visual = { archetype = "tear", primaryColor = {255, 255, 255}, secondaryColor = {200, 220, 255}, material = "Glass", emissive = true, particleRate = 4 },
        acquisition = { market = true, forage = false, robuxProductId = nil },
    },
    stormglass_shard = {
        id = "stormglass_shard", name = "Stormglass Shard", tier = "Rare",
        element = "Air", cost = 550, description = "Lightning-struck glass, holds a charge.",
        marketChance = 0.15, affinity = "Volatile",
        freshness = { shelfLifeHours = 12 },
        visual = { archetype = "shard", primaryColor = {180, 200, 255}, secondaryColor = {100, 150, 255}, material = "Glass", emissive = true, particleRate = 4 },
        acquisition = { market = true, forage = false, robuxProductId = nil },
    },
    kraken_ink = {
        id = "kraken_ink", name = "Kraken Ink", tier = "Rare",
        element = "Water", cost = 600, description = "Deep-sea ink with transformative power.",
        marketChance = 0.13, affinity = "Chaotic",
        freshness = { shelfLifeHours = 12 },
        visual = { archetype = "vial", primaryColor = {20, 20, 60}, secondaryColor = {50, 30, 100}, material = "Glass", emissive = false, particleRate = 3 },
        acquisition = { market = true, forage = false, robuxProductId = nil },
    },
    lava_pearl = {
        id = "lava_pearl", name = "Lava Pearl", tier = "Rare",
        element = "Fire", cost = 750, description = "Formed inside volcanic vents.",
        marketChance = 0.10, affinity = "Volatile",
        freshness = { shelfLifeHours = 12 },
        visual = { archetype = "orb", primaryColor = {255, 100, 0}, secondaryColor = {200, 50, 0}, material = "Neon", emissive = true, particleRate = 5 },
        acquisition = { market = true, forage = false, robuxProductId = nil },
    },
    frozen_amber = {
        id = "frozen_amber", name = "Frozen Amber", tier = "Rare",
        element = "Water", cost = 450, description = "Ancient resin preserved in permafrost.",
        marketChance = 0.15, affinity = "Stable",
        freshness = { shelfLifeHours = 12 },
        visual = { archetype = "crystal", primaryColor = {200, 160, 50}, secondaryColor = {160, 120, 30}, material = "Glass", emissive = true, particleRate = 3 },
        acquisition = { market = true, forage = false, robuxProductId = nil },
    },
    ghost_orchid = {
        id = "ghost_orchid", name = "Ghost Orchid", tier = "Rare",
        element = "Shadow", cost = 500, description = "Transparent flower, phases in and out.",
        marketChance = 0.14, affinity = "Chaotic",
        freshness = { shelfLifeHours = 12 },
        visual = { archetype = "flower", primaryColor = {200, 220, 200}, secondaryColor = {150, 180, 150}, material = "Glass", emissive = true, particleRate = 3 },
        acquisition = { market = true, forage = false, robuxProductId = nil },
    },
    titan_bone_dust = {
        id = "titan_bone_dust", name = "Titan Bone Dust", tier = "Rare",
        element = "Earth", cost = 700, description = "Ground remains of ancient giants.",
        marketChance = 0.11, affinity = "Stable",
        freshness = { shelfLifeHours = 12 },
        visual = { archetype = "bone", primaryColor = {230, 220, 200}, secondaryColor = {200, 190, 170}, material = "Marble", emissive = false, particleRate = 2 },
        acquisition = { market = true, forage = false, robuxProductId = nil },
    },
    comet_tail_ash = {
        id = "comet_tail_ash", name = "Comet Tail Ash", tier = "Rare",
        element = "Air", cost = 650, description = "Swept up after meteor showers.",
        marketChance = 0.12, affinity = "Volatile",
        freshness = { shelfLifeHours = 12 },
        visual = { archetype = "dust", primaryColor = {200, 200, 220}, secondaryColor = {150, 160, 200}, material = "SmoothPlastic", emissive = true, particleRate = 5 },
        acquisition = { market = true, forage = false, robuxProductId = nil },
    },
    basilisk_fang = {
        id = "basilisk_fang", name = "Basilisk Fang", tier = "Rare",
        element = "Earth", cost = 800, description = "Petrifying venom still active.",
        marketChance = 0.10, affinity = "Volatile",
        freshness = { shelfLifeHours = 12 },
        visual = { archetype = "fang", primaryColor = {230, 225, 210}, secondaryColor = {80, 180, 50}, material = "Marble", emissive = false, particleRate = 2 },
        acquisition = { market = true, forage = false, robuxProductId = nil },
    },
    siren_song_echo = {
        id = "siren_song_echo", name = "Siren Song Echo", tier = "Rare",
        element = "Water", cost = 550, description = "Captured sound wave in a crystal vial.",
        marketChance = 0.14, affinity = "Harmonious",
        freshness = { shelfLifeHours = 12 },
        visual = { archetype = "vial", primaryColor = {150, 200, 255}, secondaryColor = {100, 150, 220}, material = "Glass", emissive = true, particleRate = 3 },
        acquisition = { market = true, forage = false, robuxProductId = nil },
    },
    eclipse_petal = {
        id = "eclipse_petal", name = "Eclipse Petal", tier = "Rare",
        element = "Shadow", cost = 600, description = "Only appears during solar events.",
        marketChance = 0.13, affinity = "Chaotic",
        freshness = { shelfLifeHours = 12 },
        visual = { archetype = "flower", primaryColor = {40, 20, 60}, secondaryColor = {200, 100, 0}, material = "SmoothPlastic", emissive = true, particleRate = 4 },
        acquisition = { market = true, forage = false, robuxProductId = nil },
    },
    celestial_dew = {
        id = "celestial_dew", name = "Celestial Dew", tier = "Rare",
        element = "Light", cost = 700, description = "Condensation from star-touched clouds.",
        marketChance = 0.11, affinity = "Harmonious",
        freshness = { shelfLifeHours = 12 },
        visual = { archetype = "tear", primaryColor = {220, 240, 255}, secondaryColor = {180, 200, 240}, material = "Glass", emissive = true, particleRate = 4 },
        acquisition = { market = true, forage = false, robuxProductId = nil },
    },
    -- ============================================================
    -- MYTHIC TIER (12) - 1.5-3% chance, world-shaping reagents
    -- ============================================================
    starfall_shard = {
        id = "starfall_shard", name = "Starfall Shard", tier = "Mythic",
        element = "Light", cost = 3000, description = "Fragment of a fallen star.",
        marketChance = 0.03, affinity = "Chaotic",
        freshness = { shelfLifeHours = 8 },
        visual = { archetype = "shard", primaryColor = {255, 255, 200}, secondaryColor = {200, 180, 255}, material = "Neon", emissive = true, particleRate = 8 },
        acquisition = { market = true, forage = false, robuxProductId = nil },
    },
    leviathan_tear = {
        id = "leviathan_tear", name = "Leviathan Tear", tier = "Mythic",
        element = "Water", cost = 4000, description = "Wept by ancient sea creatures.",
        marketChance = 0.02, affinity = "Harmonious",
        freshness = { shelfLifeHours = 8 },
        visual = { archetype = "tear", primaryColor = {30, 80, 200}, secondaryColor = {20, 50, 150}, material = "Glass", emissive = true, particleRate = 6 },
        acquisition = { market = true, forage = false, robuxProductId = nil },
    },
    time_sand = {
        id = "time_sand", name = "Time Sand", tier = "Mythic",
        element = "Air", cost = 5000, description = "Flows upward, defies gravity.",
        marketChance = 0.02, affinity = "Chaotic",
        freshness = { shelfLifeHours = 8 },
        visual = { archetype = "dust", primaryColor = {255, 215, 80}, secondaryColor = {200, 180, 50}, material = "Neon", emissive = true, particleRate = 8 },
        acquisition = { market = true, forage = false, robuxProductId = nil },
    },
    world_tree_bark = {
        id = "world_tree_bark", name = "World Tree Bark", tier = "Mythic",
        element = "Earth", cost = 3500, description = "From the roots of the cosmic tree.",
        marketChance = 0.03, affinity = "Harmonious",
        freshness = { shelfLifeHours = 8 },
        visual = { archetype = "shard", primaryColor = {80, 140, 60}, secondaryColor = {50, 100, 40}, material = "WoodPlanks", emissive = true, particleRate = 5 },
        acquisition = { market = true, forage = false, robuxProductId = nil },
    },
    demon_heart_ember = {
        id = "demon_heart_ember", name = "Demon Heart Ember", tier = "Mythic",
        element = "Fire", cost = 4500, description = "Still beats with infernal heat.",
        marketChance = 0.02, affinity = "Volatile",
        freshness = { shelfLifeHours = 8 },
        visual = { archetype = "ember", primaryColor = {200, 20, 0}, secondaryColor = {255, 80, 0}, material = "Neon", emissive = true, particleRate = 8 },
        acquisition = { market = true, forage = false, robuxProductId = nil },
    },
    abyssal_core = {
        id = "abyssal_core", name = "Abyssal Core", tier = "Mythic",
        element = "Shadow", cost = 5000, description = "Condensed void energy, warps nearby light.",
        marketChance = 0.015, affinity = "Chaotic",
        freshness = { shelfLifeHours = 8 },
        visual = { archetype = "orb", primaryColor = {10, 0, 20}, secondaryColor = {80, 0, 120}, material = "ForceField", emissive = true, particleRate = 8 },
        acquisition = { market = true, forage = false, robuxProductId = nil },
    },
    angel_feather = {
        id = "angel_feather", name = "Angel Feather", tier = "Mythic",
        element = "Light", cost = 4000, description = "Weightless, emits a soft hum.",
        marketChance = 0.025, affinity = "Harmonious",
        freshness = { shelfLifeHours = 8 },
        visual = { archetype = "feather", primaryColor = {255, 255, 255}, secondaryColor = {240, 240, 255}, material = "Neon", emissive = true, particleRate = 6 },
        acquisition = { market = true, forage = false, robuxProductId = nil },
    },
    chrono_crystal = {
        id = "chrono_crystal", name = "Chrono Crystal", tier = "Mythic",
        element = "Air", cost = 4500, description = "Shows glimpses of other timelines.",
        marketChance = 0.02, affinity = "Chaotic",
        freshness = { shelfLifeHours = 8 },
        visual = { archetype = "crystal", primaryColor = {180, 200, 255}, secondaryColor = {140, 160, 220}, material = "Glass", emissive = true, particleRate = 7 },
        acquisition = { market = true, forage = false, robuxProductId = nil },
    },
    behemoth_heartstone = {
        id = "behemoth_heartstone", name = "Behemoth Heartstone", tier = "Mythic",
        element = "Earth", cost = 3500, description = "Crystallized core of an ancient beast.",
        marketChance = 0.03, affinity = "Stable",
        freshness = { shelfLifeHours = 8 },
        visual = { archetype = "crystal", primaryColor = {180, 120, 60}, secondaryColor = {140, 80, 30}, material = "Metal", emissive = true, particleRate = 5 },
        acquisition = { market = true, forage = false, robuxProductId = nil },
    },
    primordial_flame = {
        id = "primordial_flame", name = "Primordial Flame", tier = "Mythic",
        element = "Fire", cost = 5000, description = "Fire that has burned since creation.",
        marketChance = 0.015, affinity = "Volatile",
        freshness = { shelfLifeHours = 8 },
        visual = { archetype = "ember", primaryColor = {255, 200, 50}, secondaryColor = {255, 100, 0}, material = "Neon", emissive = true, particleRate = 10 },
        acquisition = { market = true, forage = false, robuxProductId = nil },
    },
    dreamweaver_silk = {
        id = "dreamweaver_silk", name = "Dreamweaver Silk", tier = "Mythic",
        element = "Shadow", cost = 3000, description = "Spun from the fabric of dreams.",
        marketChance = 0.03, affinity = "Harmonious",
        freshness = { shelfLifeHours = 8 },
        visual = { archetype = "silk", primaryColor = {150, 100, 200}, secondaryColor = {100, 60, 160}, material = "SmoothPlastic", emissive = true, particleRate = 5 },
        acquisition = { market = true, forage = false, robuxProductId = nil },
    },
    tidal_moonstone = {
        id = "tidal_moonstone", name = "Tidal Moonstone", tier = "Mythic",
        element = "Water", cost = 4000, description = "Controls nearby water, glows at night.",
        marketChance = 0.02, affinity = "Harmonious",
        freshness = { shelfLifeHours = 8 },
        visual = { archetype = "orb", primaryColor = {150, 200, 240}, secondaryColor = {100, 150, 200}, material = "Glass", emissive = true, particleRate = 6 },
        acquisition = { market = true, forage = false, robuxProductId = nil },
    },

    -- ============================================================
    -- DIVINE TIER (2) - 0.1% market chance + Robux purchasable
    -- ============================================================
    philosophers_stone = {
        id = "philosophers_stone", name = "Philosopher's Stone Fragment", tier = "Divine",
        element = "Earth", cost = 10000, description = "The legendary transmutation catalyst.",
        marketChance = 0.001, affinity = "Chaotic",
        freshness = { shelfLifeHours = 48 },
        visual = { archetype = "crystal", primaryColor = {200, 30, 30}, secondaryColor = {255, 200, 50}, material = "Neon", emissive = true, particleRate = 12 },
        acquisition = { market = true, forage = false, robuxProductId = 1001 },
    },
    cosmic_ember = {
        id = "cosmic_ember", name = "Cosmic Ember", tier = "Divine",
        element = "Fire", cost = 10000, description = "A spark from the birth of a universe.",
        marketChance = 0.001, affinity = "Volatile",
        freshness = { shelfLifeHours = 48 },
        visual = { archetype = "ember", primaryColor = {255, 255, 255}, secondaryColor = {200, 220, 255}, material = "Neon", emissive = true, particleRate = 12 },
        acquisition = { market = true, forage = false, robuxProductId = 1002 },
    },
}

-- ============================================================
-- HELPER FUNCTIONS
-- ============================================================

function Ingredients.getByTier(tier)
    local result = {}
    for id, data in pairs(Ingredients.Data) do
        if data.tier == tier then
            table.insert(result, data)
        end
    end
    return result
end

function Ingredients.getMarketEligible()
    local result = {}
    for id, data in pairs(Ingredients.Data) do
        if data.acquisition and data.acquisition.market then
            table.insert(result, data)
        end
    end
    return result
end

function Ingredients.getForageable()
    local result = {}
    for id, data in pairs(Ingredients.Data) do
        if data.acquisition and data.acquisition.forage then
            table.insert(result, data)
        end
    end
    return result
end

function Ingredients.count()
    local n = 0
    for _ in pairs(Ingredients.Data) do n = n + 1 end
    return n
end

return Ingredients
