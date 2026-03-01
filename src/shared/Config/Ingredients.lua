local Ingredients = {}

Ingredients.Data = {
    mushroom = {
        id = "mushroom", name = "Mushroom", tier = "Common",
        cost = 10, element = "Earth",
        description = "A common forest mushroom with mild magical properties.",
    },
    fern_leaf = {
        id = "fern_leaf", name = "Fern Leaf", tier = "Common",
        cost = 8, element = "Earth",
        description = "A curled fern frond that thrums with natural energy.",
    },
    river_water = {
        id = "river_water", name = "River Water", tier = "Common",
        cost = 5, element = "Water",
        description = "Crystal clear water from an enchanted stream.",
    },
    ember_root = {
        id = "ember_root", name = "Ember Root", tier = "Common",
        cost = 15, element = "Fire",
        description = "A smoldering root that radiates warmth.",
    },
    fire_salt = {
        id = "fire_salt", name = "Fire Salt", tier = "Common",
        cost = 12, element = "Fire",
        description = "Volcanic mineral crystals that crackle with heat.",
    },
    dewdrop = {
        id = "dewdrop", name = "Dewdrop", tier = "Common",
        cost = 7, element = "Water",
        description = "A perfectly spherical drop of morning dew.",
    },
    moss_clump = {
        id = "moss_clump", name = "Moss Clump", tier = "Common",
        cost = 6, element = "Earth",
        description = "Soft, glowing moss from a fairy ring.",
    },
    wind_blossom = {
        id = "wind_blossom", name = "Wind Blossom", tier = "Common",
        cost = 9, element = "Air",
        description = "A flower petal that floats on invisible currents.",
    },
    crystal_dust = {
        id = "crystal_dust", name = "Crystal Dust", tier = "Uncommon",
        cost = 50, element = "Light",
        description = "Shimmering dust ground from enchanted crystals.",
    },
    moonpetal = {
        id = "moonpetal", name = "Moonpetal", tier = "Uncommon",
        cost = 60, element = "Shadow",
        description = "A petal that only blooms under moonlight.",
    },
    dragon_scale = {
        id = "dragon_scale", name = "Dragon Scale", tier = "Rare",
        cost = 300, element = "Fire",
        description = "A scale shed by an ancient fire dragon.",
    },
    phoenix_feather = {
        id = "phoenix_feather", name = "Phoenix Feather", tier = "Rare",
        cost = 500, element = "Fire",
        description = "A radiant feather from a reborn phoenix.",
    },
}

-- Helper: get all ingredients by tier
function Ingredients.getByTier(tier)
    local result = {}
    for id, data in pairs(Ingredients.Data) do
        if data.tier == tier then
            table.insert(result, data)
        end
    end
    return result
end

return Ingredients

