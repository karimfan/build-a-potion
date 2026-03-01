local Recipes = {}

-- Key is sorted ingredient pair "id1|id2" (alphabetical order)
-- This ensures A+B == B+A
Recipes.Data = {
    ["mushroom|river_water"] = "healing_salve",
    ["fern_leaf|river_water"] = "growth_potion",
    ["fern_leaf|mushroom"] = "forest_remedy",
    ["dewdrop|river_water"] = "purification_elixir",
    ["ember_root|fire_salt"] = "flame_draught",
    ["moss_clump|wind_blossom"] = "breeze_tonic",
    ["dewdrop|mushroom"] = "dew_brew",
    ["fire_salt|wind_blossom"] = "spark_elixir",
    ["crystal_dust|mushroom"] = "glow_potion",
    ["dewdrop|moonpetal"] = "night_vision_tonic",
    ["fire_salt|moonpetal"] = "shadow_flame_brew",
    ["crystal_dust|moonpetal"] = "starlight_serum",
    ["crystal_dust|ember_root"] = "fire_shield_elixir",
    ["dragon_scale|moonpetal"] = "dragonheart_potion",
    ["moonpetal|phoenix_feather"] = "rebirth_potion",
}

-- Look up a recipe by two ingredient IDs (order doesn't matter)
function Recipes.lookup(ingredientId1, ingredientId2)
    local sorted = {ingredientId1, ingredientId2}
    table.sort(sorted)
    local key = sorted[1] .. "|" .. sorted[2]
    return Recipes.Data[key] -- returns potionId or nil (nil = sludge)
end

-- Get all recipe keys for recipe book display
function Recipes.getAllRecipeIds()
    local ids = {}
    for key, potionId in pairs(Recipes.Data) do
        ids[key] = potionId
    end
    return ids
end

return Recipes
