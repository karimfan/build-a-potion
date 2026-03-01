local Potions = {}

-- Helper to parse compound mutation keys (potionId__mutation)
function Potions.parsePotionKey(key)
    local sep = key:find("__")
    if sep then
        return key:sub(1, sep - 1), key:sub(sep + 2)
    end
    return key, nil
end

-- Get base sell value (handles compound keys)
function Potions.getSellValue(key)
    local baseId, mutation = Potions.parsePotionKey(key)
    local potion = Potions.Data[baseId]
    if not potion then return 0 end
    local base = potion.sellValue or 0
    if mutation then
        local MutationTuning = require(script.Parent.MutationTuning)
        local mutData = MutationTuning.Types[mutation]
        if mutData then
            return math.floor(base * mutData.sellMultiplier)
        end
    end
    return base
end

Potions.Data = {
    -- ===== SLUDGE =====
    sludge = { id = "sludge", name = "Sludge", tier = "Common", sellValue = 2, description = "A failed brew. Smells terrible." },

    -- ===== COMMON POTIONS (30) =====
    healing_salve = { id = "healing_salve", name = "Healing Salve", tier = "Common", sellValue = 25, description = "Soothes minor wounds." },
    growth_potion = { id = "growth_potion", name = "Growth Potion", tier = "Common", sellValue = 30, description = "Makes plants sprout instantly." },
    forest_remedy = { id = "forest_remedy", name = "Forest Remedy", tier = "Common", sellValue = 20, description = "A natural cure from the forest floor." },
    purification_elixir = { id = "purification_elixir", name = "Purification Elixir", tier = "Common", sellValue = 18, description = "Cleanses impurities from body and soul." },
    smoke_bomb_tonic = { id = "smoke_bomb_tonic", name = "Smoke Bomb Tonic", tier = "Common", sellValue = 22, description = "Creates a cloud of concealing smoke." },
    breeze_tonic = { id = "breeze_tonic", name = "Breeze Tonic", tier = "Common", sellValue = 28, description = "Grants a feeling of lightness and speed." },
    cloud_essence = { id = "cloud_essence", name = "Cloud Essence", tier = "Common", sellValue = 15, description = "Fluffy, weightless liquid." },
    stoneskin_salve = { id = "stoneskin_salve", name = "Stoneskin Salve", tier = "Common", sellValue = 20, description = "Hardens skin temporarily." },
    mudslide_brew = { id = "mudslide_brew", name = "Mudslide Brew", tier = "Common", sellValue = 12, description = "Slippery but oddly useful." },
    sweet_salve = { id = "sweet_salve", name = "Sweet Salve", tier = "Common", sellValue = 35, description = "Tasty healing mixture." },
    refreshment_draught = { id = "refreshment_draught", name = "Refreshment Draught", tier = "Common", sellValue = 30, description = "Instantly refreshing." },
    grit_potion = { id = "grit_potion", name = "Grit Potion", tier = "Common", sellValue = 15, description = "Makes you tougher." },
    cool_spring_tonic = { id = "cool_spring_tonic", name = "Cool Spring Tonic", tier = "Common", sellValue = 22, description = "Refreshing and crisp." },
    lantern_brew = { id = "lantern_brew", name = "Lantern Brew", tier = "Common", sellValue = 40, description = "Glows brightly for hours." },
    float_light = { id = "float_light", name = "Float Light", tier = "Common", sellValue = 32, description = "A tiny floating lamp." },
    sticky_remedy = { id = "sticky_remedy", name = "Sticky Remedy", tier = "Common", sellValue = 18, description = "Binds wounds together." },
    golem_paste = { id = "golem_paste", name = "Golem Paste", tier = "Common", sellValue = 25, description = "Animates small objects briefly." },
    willow_tea = { id = "willow_tea", name = "Willow Tea", tier = "Common", sellValue = 22, description = "Calming natural brew." },
    bark_shield_potion = { id = "bark_shield_potion", name = "Bark Shield Potion", tier = "Common", sellValue = 28, description = "Tough woody defense." },
    dewfall_tonic = { id = "dewfall_tonic", name = "Dewfall Tonic", tier = "Common", sellValue = 20, description = "The purest refreshment." },
    rain_brew = { id = "rain_brew", name = "Rain Brew", tier = "Common", sellValue = 16, description = "Summons a light drizzle." },
    seed_bomb = { id = "seed_bomb", name = "Seed Bomb", tier = "Common", sellValue = 25, description = "Explodes into plants." },
    sprout_serum = { id = "sprout_serum", name = "Sprout Serum", tier = "Common", sellValue = 22, description = "Accelerates plant growth." },
    shadow_thread_tonic = { id = "shadow_thread_tonic", name = "Shadow Thread Tonic", tier = "Common", sellValue = 30, description = "Creates shadow bindings." },
    smoke_web_potion = { id = "smoke_web_potion", name = "Smoke Web Potion", tier = "Common", sellValue = 28, description = "A trapping smoke net." },
    ember_syrup = { id = "ember_syrup", name = "Ember Syrup", tier = "Common", sellValue = 35, description = "Sweet and fiery." },
    glow_trap_brew = { id = "glow_trap_brew", name = "Glow Trap Brew", tier = "Common", sellValue = 38, description = "A luminous web trap." },
    earthen_wall_tonic = { id = "earthen_wall_tonic", name = "Earthen Wall Tonic", tier = "Common", sellValue = 24, description = "Raises an earth barrier." },
    grinding_paste = { id = "grinding_paste", name = "Grinding Paste", tier = "Common", sellValue = 18, description = "Polishes anything to a shine." },
    windshower_potion = { id = "windshower_potion", name = "Windshower Potion", tier = "Common", sellValue = 20, description = "Calls wind and gentle rain." },
    -- ===== UNCOMMON POTIONS (20) =====
    moonlight_nectar = { id = "moonlight_nectar", name = "Moonlight Nectar", tier = "Uncommon", sellValue = 120, description = "Glows silver, calms emotions." },
    night_weaver_elixir = { id = "night_weaver_elixir", name = "Night Weaver Elixir", tier = "Uncommon", sellValue = 140, description = "See in complete darkness." },
    flame_draught = { id = "flame_draught", name = "Flame Draught", tier = "Uncommon", sellValue = 100, description = "Burns with inner fire." },
    smolder_salve = { id = "smolder_salve", name = "Smolder Salve", tier = "Uncommon", sellValue = 90, description = "Slow-burning healing." },
    diamond_dust_potion = { id = "diamond_dust_potion", name = "Diamond Dust Potion", tier = "Uncommon", sellValue = 110, description = "Crystalline clarity." },
    prismatic_elixir = { id = "prismatic_elixir", name = "Prismatic Elixir", tier = "Uncommon", sellValue = 130, description = "Refracts all light into rainbows." },
    permafrost_tonic = { id = "permafrost_tonic", name = "Permafrost Tonic", tier = "Uncommon", sellValue = 100, description = "Freezes anything it touches." },
    arctic_breath_brew = { id = "arctic_breath_brew", name = "Arctic Breath Brew", tier = "Uncommon", sellValue = 95, description = "Breathe ice crystals." },
    storm_bottle = { id = "storm_bottle", name = "Storm Bottle", tier = "Uncommon", sellValue = 110, description = "A bottled thunderstorm." },
    lightning_rod_elixir = { id = "lightning_rod_elixir", name = "Lightning Rod Elixir", tier = "Uncommon", sellValue = 90, description = "Attracts and channels electricity." },
    shadow_cloak_potion = { id = "shadow_cloak_potion", name = "Shadow Cloak Potion", tier = "Uncommon", sellValue = 130, description = "Become one with the shadows." },
    dark_growth_serum = { id = "dark_growth_serum", name = "Dark Growth Serum", tier = "Uncommon", sellValue = 100, description = "Grows twisted shadow plants." },
    solar_flare_tonic = { id = "solar_flare_tonic", name = "Solar Flare Tonic", tier = "Uncommon", sellValue = 150, description = "Blindingly bright burst." },
    magma_brew = { id = "magma_brew", name = "Magma Brew", tier = "Uncommon", sellValue = 120, description = "Molten heat in a bottle." },
    pearl_essence = { id = "pearl_essence", name = "Pearl Essence", tier = "Uncommon", sellValue = 100, description = "Lustrous beauty potion." },
    ironclad_tonic = { id = "ironclad_tonic", name = "Ironclad Tonic", tier = "Uncommon", sellValue = 90, description = "Metallic defense coating." },
    fairy_flight_potion = { id = "fairy_flight_potion", name = "Fairy Flight Potion", tier = "Uncommon", sellValue = 160, description = "Temporary levitation." },
    bioluminescence_brew = { id = "bioluminescence_brew", name = "Bioluminescence Brew", tier = "Uncommon", sellValue = 120, description = "Skin glows for hours." },
    tidal_potion = { id = "tidal_potion", name = "Tidal Potion", tier = "Uncommon", sellValue = 170, description = "Control water currents." },
    sweet_nightmare_elixir = { id = "sweet_nightmare_elixir", name = "Sweet Nightmare Elixir", tier = "Uncommon", sellValue = 115, description = "Induces vivid dreams." },

    -- ===== RARE POTIONS (15) =====
    dragonheart_potion = { id = "dragonheart_potion", name = "Dragonheart Potion", tier = "Rare", sellValue = 1200, description = "Grants the courage and power of a dragon." },
    rebirth_potion = { id = "rebirth_potion", name = "Rebirth Potion", tier = "Rare", sellValue = 1500, description = "A legendary elixir of renewal." },
    solar_phoenix_elixir = { id = "solar_phoenix_elixir", name = "Solar Phoenix Elixir", tier = "Rare", sellValue = 1800, description = "Rebirth through sunfire." },
    abyssal_cloak_potion = { id = "abyssal_cloak_potion", name = "Abyssal Cloak Potion", tier = "Rare", sellValue = 2000, description = "Complete shadow immersion." },
    nightmare_fuel = { id = "nightmare_fuel", name = "Nightmare Fuel", tier = "Rare", sellValue = 1600, description = "Weaponized darkness." },
    purification_supreme = { id = "purification_supreme", name = "Purification Supreme", tier = "Rare", sellValue = 1800, description = "Cures absolutely any ailment." },
    frozen_miracle = { id = "frozen_miracle", name = "Frozen Miracle", tier = "Rare", sellValue = 2200, description = "Time-stopping ice." },
    thunder_gods_draught = { id = "thunder_gods_draught", name = "Thunder God's Draught", tier = "Rare", sellValue = 1500, description = "Command lightning itself." },
    deep_sea_elixir = { id = "deep_sea_elixir", name = "Deep Sea Elixir", tier = "Rare", sellValue = 1800, description = "Breathe underwater forever." },
    volcanic_frost = { id = "volcanic_frost", name = "Volcanic Frost", tier = "Rare", sellValue = 2500, description = "Fire and ice collide spectacularly." },
    phantom_elixir = { id = "phantom_elixir", name = "Phantom Elixir", tier = "Rare", sellValue = 2000, description = "Phase through solid walls." },
    titan_strength_brew = { id = "titan_strength_brew", name = "Titan Strength Brew", tier = "Rare", sellValue = 1600, description = "Colossal power surges through you." },
    petrification_potion = { id = "petrification_potion", name = "Petrification Potion", tier = "Rare", sellValue = 2000, description = "Turns things to solid stone." },
    enchantment_elixir = { id = "enchantment_elixir", name = "Enchantment Elixir", tier = "Rare", sellValue = 1800, description = "Irresistible magical charm." },
    twilight_serum = { id = "twilight_serum", name = "Twilight Serum", tier = "Rare", sellValue = 2200, description = "Harness the power of the eclipse." },

    -- ===== MYTHIC POTIONS (8) =====
    cosmic_elixir = { id = "cosmic_elixir", name = "Cosmic Elixir", tier = "Mythic", sellValue = 8000, description = "Grants cosmic awareness beyond mortal senses." },
    abyss_lords_draught = { id = "abyss_lords_draught", name = "Abyss Lord's Draught", tier = "Mythic", sellValue = 10000, description = "Command the deep seas and their creatures." },
    chrono_draught = { id = "chrono_draught", name = "Chrono Draught", tier = "Mythic", sellValue = 8500, description = "Slows time for everyone but you." },
    natures_wrath = { id = "natures_wrath", name = "Nature's Wrath", tier = "Mythic", sellValue = 9000, description = "An earthquake in a bottle." },
    infernal_rage_potion = { id = "infernal_rage_potion", name = "Infernal Rage Potion", tier = "Mythic", sellValue = 12000, description = "Unstoppable demonic fury." },
    void_walker_elixir = { id = "void_walker_elixir", name = "Void Walker Elixir", tier = "Mythic", sellValue = 15000, description = "Step between dimensions." },
    divine_grace = { id = "divine_grace", name = "Divine Grace", tier = "Mythic", sellValue = 12000, description = "Pure heavenly blessing." },
    eternal_flame_elixir = { id = "eternal_flame_elixir", name = "Eternal Flame Elixir", tier = "Mythic", sellValue = 13000, description = "Fire that will never die." },

    -- ===== DIVINE POTIONS (2) =====
    transmutation_elixir = { id = "transmutation_elixir", name = "Transmutation Elixir", tier = "Divine", sellValue = 50000, description = "Transform any material into gold." },
    wish_potion = { id = "wish_potion", name = "Wish Potion", tier = "Divine", sellValue = 75000, description = "Grants one wish. Use wisely." },
    -- ===== ADDITIONAL COVERAGE POTIONS =====
    brimstone_salve = { id = "brimstone_salve", name = "Brimstone Salve", tier = "Uncommon", sellValue = 85, description = "Burns and heals simultaneously." },
    slime_lantern_brew = { id = "slime_lantern_brew", name = "Slime Lantern Brew", tier = "Uncommon", sellValue = 105, description = "A slimy glowing orb." },
    zephyr_elixir = { id = "zephyr_elixir", name = "Zephyr Elixir", tier = "Uncommon", sellValue = 155, description = "Ride the wind currents." },
    ocean_sovereign_tonic = { id = "ocean_sovereign_tonic", name = "Ocean Sovereign Tonic", tier = "Uncommon", sellValue = 175, description = "Command tides and waves." },
    whisper_poison = { id = "whisper_poison", name = "Whisper Poison", tier = "Uncommon", sellValue = 110, description = "Silences the target completely." },
    meteor_scale_potion = { id = "meteor_scale_potion", name = "Meteor Scale Potion", tier = "Rare", sellValue = 1800, description = "Skin becomes meteor-hard." },
    spectral_venom = { id = "spectral_venom", name = "Spectral Venom", tier = "Rare", sellValue = 1700, description = "Poison that affects ghosts." },
    frozen_echo_elixir = { id = "frozen_echo_elixir", name = "Frozen Echo Elixir", tier = "Rare", sellValue = 1500, description = "Hear sounds from the past." },
    colossus_draught = { id = "colossus_draught", name = "Colossus Draught", tier = "Rare", sellValue = 2000, description = "Grow to enormous size." },
    total_eclipse_potion = { id = "total_eclipse_potion", name = "Total Eclipse Potion", tier = "Rare", sellValue = 1900, description = "Blots out all light." },
    time_lords_elixir = { id = "time_lords_elixir", name = "Time Lord's Elixir", tier = "Mythic", sellValue = 12000, description = "Master time itself." },
    dream_void_potion = { id = "dream_void_potion", name = "Dream Void Potion", tier = "Mythic", sellValue = 11000, description = "Enter the void between dreams." },
    hellfire_supreme = { id = "hellfire_supreme", name = "Hellfire Supreme", tier = "Mythic", sellValue = 14000, description = "The hottest flame in existence." },
    ocean_gods_draught = { id = "ocean_gods_draught", name = "Ocean God's Draught", tier = "Mythic", sellValue = 11000, description = "Rule the seas absolutely." },
    celestial_storm_brew = { id = "celestial_storm_brew", name = "Celestial Storm Brew", tier = "Mythic", sellValue = 10000, description = "A storm of falling stars." },
    eternity_elixir = { id = "eternity_elixir", name = "Eternity Elixir", tier = "Divine", sellValue = 60000, description = "Live forever... maybe." },
    apocalypse_potion = { id = "apocalypse_potion", name = "Apocalypse Potion", tier = "Divine", sellValue = 80000, description = "The end and beginning of everything." },
}

return Potions
