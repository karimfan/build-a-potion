local Recipes = {}

-- Key format: sorted ingredient IDs joined by "|"
-- Supports 2 and 3 ingredient recipes
Recipes.Data = {
    -- ============ COMMON TIER (30) ============
    ["mushroom|river_water"] = "healing_salve",
    ["fern_leaf|river_water"] = "growth_potion",
    ["fern_leaf|mushroom"] = "forest_remedy",
    ["charcoal_chunk|river_water"] = "purification_elixir",
    ["charcoal_chunk|fern_leaf"] = "smoke_bomb_tonic",
    ["dandelion_puff|mint_sprig"] = "breeze_tonic",
    ["dandelion_puff|river_water"] = "cloud_essence",
    ["clay_mud|pebble_dust"] = "stoneskin_salve",
    ["clay_mud|river_water"] = "mudslide_brew",
    ["honey_drop|mushroom"] = "sweet_salve",
    ["honey_drop|mint_sprig"] = "refreshment_draught",
    ["pebble_dust|river_water"] = "grit_potion",
    ["mint_sprig|river_water"] = "cool_spring_tonic",
    ["firefly_glow|honey_drop"] = "lantern_brew",
    ["dandelion_puff|firefly_glow"] = "float_light",
    ["mushroom|snail_slime"] = "sticky_remedy",
    ["clay_mud|snail_slime"] = "golem_paste",
    ["river_water|willow_bark"] = "willow_tea",
    ["fern_leaf|willow_bark"] = "bark_shield_potion",
    ["mint_sprig|rainwater"] = "dewfall_tonic",
    ["mushroom|rainwater"] = "rain_brew",
    ["acorn_cap|pebble_dust"] = "seed_bomb",
    ["acorn_cap|fern_leaf"] = "sprout_serum",
    ["cobweb_strand|snail_slime"] = "shadow_thread_tonic",
    ["charcoal_chunk|cobweb_strand"] = "smoke_web_potion",
    ["charcoal_chunk|honey_drop"] = "ember_syrup",
    ["cobweb_strand|firefly_glow"] = "glow_trap_brew",
    ["clay_mud|willow_bark"] = "earthen_wall_tonic",
    ["pebble_dust|snail_slime"] = "grinding_paste",
    ["dandelion_puff|rainwater"] = "windshower_potion",

    -- ============ UNCOMMON TIER (20) ============
    ["honey_drop|moonpetal"] = "moonlight_nectar",
    ["cobweb_strand|moonpetal"] = "night_weaver_elixir",
    ["charcoal_chunk|ember_root"] = "flame_draught",
    ["ember_root|willow_bark"] = "smolder_salve",
    ["crystal_dust|pebble_dust"] = "diamond_dust_potion",
    ["crystal_dust|rainwater"] = "prismatic_elixir",
    ["frost_bloom|river_water"] = "permafrost_tonic",
    ["frost_bloom|mint_sprig"] = "arctic_breath_brew",
    ["dandelion_puff|thundermoss"] = "storm_bottle",
    ["pebble_dust|thundermoss"] = "lightning_rod_elixir",
    ["cobweb_strand|shadow_vine"] = "shadow_cloak_potion",
    ["mushroom|shadow_vine"] = "dark_growth_serum",
    ["firefly_glow|sunstone_chip"] = "solar_flare_tonic",
    ["charcoal_chunk|sunstone_chip"] = "magma_brew",
    ["dewdrop_pearl|snail_slime"] = "pearl_essence",
    ["clay_mud|iron_filings"] = "ironclad_tonic",
    ["dandelion_puff|pixie_wing"] = "fairy_flight_potion",
    ["glowshroom_cap|mushroom"] = "bioluminescence_brew",
    ["mermaid_scale|rainwater"] = "tidal_potion",
    ["honey_drop|nightshade_berry"] = "sweet_nightmare_elixir",

    -- ============ RARE TIER (15) ============
    ["dragon_scale|ember_root"] = "dragonheart_potion",
    ["moonpetal|phoenix_feather"] = "rebirth_potion",
    ["phoenix_feather|sunstone_chip"] = "solar_phoenix_elixir",
    ["shadow_vine|void_essence"] = "abyssal_cloak_potion",
    ["nightshade_berry|void_essence"] = "nightmare_fuel",
    ["crystal_dust|unicorn_tear"] = "purification_supreme",
    ["frost_bloom|unicorn_tear"] = "frozen_miracle",
    ["stormglass_shard|thundermoss"] = "thunder_gods_draught",
    ["kraken_ink|mermaid_scale"] = "deep_sea_elixir",
    ["frozen_amber|lava_pearl"] = "volcanic_frost",
    ["cobweb_strand|ghost_orchid|moonpetal"] = "phantom_elixir",
    ["iron_filings|titan_bone_dust"] = "titan_strength_brew",
    ["basilisk_fang|snail_slime"] = "petrification_potion",
    ["dewdrop_pearl|siren_song_echo"] = "enchantment_elixir",
    ["celestial_dew|eclipse_petal"] = "twilight_serum",

    -- ============ MYTHIC TIER (8) ============
    ["celestial_dew|starfall_shard"] = "cosmic_elixir",
    ["kraken_ink|leviathan_tear"] = "abyss_lords_draught",
    ["stormglass_shard|time_sand"] = "chrono_draught",
    ["titan_bone_dust|world_tree_bark"] = "natures_wrath",
    ["demon_heart_ember|lava_pearl"] = "infernal_rage_potion",
    ["abyssal_core|void_essence"] = "void_walker_elixir",
    ["angel_feather|celestial_dew|unicorn_tear"] = "divine_grace",
    ["phoenix_feather|primordial_flame"] = "eternal_flame_elixir",

    -- ============ DIVINE TIER (2) ============
    ["philosophers_stone|primordial_flame|world_tree_bark"] = "transmutation_elixir",
    ["angel_feather|cosmic_ember|starfall_shard"] = "wish_potion",
    -- ===== ADDITIONAL COVERAGE RECIPES (17) =====
    ["sulfur_nugget|willow_bark"] = "brimstone_salve",
    ["glowshroom_cap|snail_slime"] = "slime_lantern_brew",
    ["pixie_wing|wind_whistle_reed"] = "zephyr_elixir",
    ["mermaid_scale|tidal_moonstone"] = "ocean_sovereign_tonic",
    ["nightshade_berry|wind_whistle_reed"] = "whisper_poison",
    ["comet_tail_ash|dragon_scale"] = "meteor_scale_potion",
    ["basilisk_fang|ghost_orchid"] = "spectral_venom",
    ["frozen_amber|siren_song_echo"] = "frozen_echo_elixir",
    ["behemoth_heartstone|titan_bone_dust"] = "colossus_draught",
    ["eclipse_petal|void_essence"] = "total_eclipse_potion",
    ["chrono_crystal|time_sand"] = "time_lords_elixir",
    ["abyssal_core|dreamweaver_silk"] = "dream_void_potion",
    ["demon_heart_ember|primordial_flame"] = "hellfire_supreme",
    ["leviathan_tear|tidal_moonstone"] = "ocean_gods_draught",
    ["comet_tail_ash|starfall_shard"] = "celestial_storm_brew",
    ["behemoth_heartstone|chrono_crystal|philosophers_stone"] = "eternity_elixir",
    ["angel_feather|cosmic_ember|demon_heart_ember"] = "apocalypse_potion",
}

-- Look up a recipe by ingredient IDs (supports 2 or 3)
function Recipes.lookup(...)
    local ids = {...}
    -- Flatten if passed as table
    if type(ids[1]) == "table" then ids = ids[1] end
    table.sort(ids)
    local key = table.concat(ids, "|")
    return Recipes.Data[key]
end

-- Get all recipe keys for recipe book display
function Recipes.getAllRecipeIds()
    local ids = {}
    for key, potionId in pairs(Recipes.Data) do
        ids[key] = potionId
    end
    return ids
end

-- Count recipes by tier (requires Potions config)
function Recipes.getRecipeCountByTier(PotionsConfig)
    local counts = { Common = 0, Uncommon = 0, Rare = 0, Mythic = 0, Divine = 0 }
    for _, potionId in pairs(Recipes.Data) do
        local potion = PotionsConfig.Data[potionId]
        if potion then
            counts[potion.tier] = (counts[potion.tier] or 0) + 1
        end
    end
    return counts
end

-- Count total recipes
function Recipes.count()
    local n = 0
    for _ in pairs(Recipes.Data) do n = n + 1 end
    return n
end

return Recipes
