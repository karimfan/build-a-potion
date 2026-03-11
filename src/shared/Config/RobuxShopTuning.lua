local RobuxShopTuning = {}

-- Developer Product IDs (MUST match IDs configured in Roblox Creator Dashboard)
-- These are placeholder IDs — replace with real ones after creating products in dashboard
RobuxShopTuning.Products = {
    -- Ingredient Packs
    {
        productId = 0, -- REPLACE with real Developer Product ID
        name = "Common Ingredient Pack",
        description = "5 random Common ingredients",
        robux = 25,
        category = "Ingredients",
        grantType = "random_ingredients",
        grantTier = "Common",
        grantCount = 5,
    },
    {
        productId = 0, -- REPLACE
        name = "Uncommon Ingredient Pack",
        description = "3 random Uncommon ingredients",
        robux = 75,
        category = "Ingredients",
        grantType = "random_ingredients",
        grantTier = "Uncommon",
        grantCount = 3,
    },
    {
        productId = 0, -- REPLACE
        name = "Rare Ingredient",
        description = "1 random Rare ingredient",
        robux = 199,
        category = "Ingredients",
        grantType = "random_ingredients",
        grantTier = "Rare",
        grantCount = 1,
    },
    {
        productId = 0, -- REPLACE
        name = "Mythic Ingredient",
        description = "1 random Mythic ingredient",
        robux = 399,
        category = "Ingredients",
        grantType = "random_ingredients",
        grantTier = "Mythic",
        grantCount = 1,
    },

    -- Potion Packs
    {
        productId = 0, -- REPLACE
        name = "Common Potion Pack",
        description = "3 random Common potions",
        robux = 49,
        category = "Potions",
        grantType = "random_potions",
        grantTier = "Common",
        grantCount = 3,
    },
    {
        productId = 0, -- REPLACE
        name = "Uncommon Potion Pack",
        description = "2 random Uncommon potions",
        robux = 99,
        category = "Potions",
        grantType = "random_potions",
        grantTier = "Uncommon",
        grantCount = 2,
    },
    {
        productId = 0, -- REPLACE
        name = "Rare Potion",
        description = "1 random Rare potion",
        robux = 249,
        category = "Potions",
        grantType = "random_potions",
        grantTier = "Rare",
        grantCount = 1,
    },
    {
        productId = 0, -- REPLACE
        name = "Mythic Potion",
        description = "1 random Mythic potion",
        robux = 499,
        category = "Potions",
        grantType = "random_potions",
        grantTier = "Mythic",
        grantCount = 1,
    },

    -- Convenience
    {
        productId = 0, -- REPLACE
        name = "Instant Brew",
        description = "Skip your current brew timer instantly",
        robux = 19,
        category = "Convenience",
        grantType = "instant_brew",
        grantCount = 1,
    },
    {
        productId = 0, -- REPLACE
        name = "Mutation Charm",
        description = "Guarantee a mutation on your next brew",
        robux = 49,
        category = "Convenience",
        grantType = "mutation_charm",
        grantCount = 1,
    },
}

-- Lookup product by ID
function RobuxShopTuning.getProductById(productId)
    for _, product in ipairs(RobuxShopTuning.Products) do
        if product.productId == productId then
            return product
        end
    end
    return nil
end

-- Get products by category
function RobuxShopTuning.getByCategory(category)
    local result = {}
    for _, product in ipairs(RobuxShopTuning.Products) do
        if product.category == category then
            table.insert(result, product)
        end
    end
    return result
end

-- Category display order
RobuxShopTuning.Categories = {"Ingredients", "Potions", "Convenience"}

-- Tier colors for shop UI
RobuxShopTuning.TierColors = {
    Common = Color3.fromRGB(130, 180, 120),
    Uncommon = Color3.fromRGB(80, 170, 220),
    Rare = Color3.fromRGB(255, 200, 90),
    Mythic = Color3.fromRGB(195, 110, 255),
    Divine = Color3.fromRGB(255, 250, 210),
}

return RobuxShopTuning
