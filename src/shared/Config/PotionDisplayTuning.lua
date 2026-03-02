local PDT = {}

PDT.MaxDisplays = 30
PDT.PotionsPerShelf = 6

-- Visual config per tier — vibrant, Instagram-worthy trophy display
PDT.TierVisuals = {
    Common = {
        shape = "Cylinder", -- simple vial
        size = Vector3.new(0.9, 0.5, 0.5),
        material = "Glass",
        transparency = 0.25,
        particleRate = 0,
        lightBrightness = 0.3,
        lightRange = 4,
    },
    Uncommon = {
        shape = "Cylinder",
        size = Vector3.new(1.0, 0.55, 0.55),
        material = "Glass",
        transparency = 0.15,
        particleRate = 2,
        lightBrightness = 0.8,
        lightRange = 6,
    },
    Rare = {
        shape = "Cylinder",
        size = Vector3.new(1.1, 0.6, 0.6),
        material = "Glass",
        transparency = 0.05,
        particleRate = 8,
        lightBrightness = 1.5,
        lightRange = 10,
    },
    Mythic = {
        shape = "Ball",
        size = Vector3.new(0.8, 0.8, 0.8),
        material = "Neon",
        transparency = 0,
        particleRate = 12,
        lightBrightness = 2.0,
        lightRange = 14,
    },
    Divine = {
        shape = "Ball",
        size = Vector3.new(0.9, 0.9, 0.9),
        material = "Neon",
        transparency = 0,
        particleRate = 18,
        lightBrightness = 3.0,
        lightRange = 18,
        floats = true,
    },
}

-- Element colors for potion tint
PDT.ElementColors = {
    Fire = Color3.fromRGB(255, 80, 20),
    Water = Color3.fromRGB(40, 140, 255),
    Earth = Color3.fromRGB(100, 200, 50),
    Air = Color3.fromRGB(170, 220, 255),
    Shadow = Color3.fromRGB(120, 30, 180),
    Light = Color3.fromRGB(255, 240, 80),
}

-- Mutation visual modifiers — vibrant and dramatic
PDT.MutationModifiers = {
    Glowing = { material = "Neon", extraLight = 2, particleRate = 6 },
    Bubbling = { particleRate = 10, particleSpeed = 3 },
    Crystallized = { material = "Glass", transparency = 0, extraLight = 1.5 },
    Shadow = { material = "ForceField", color = Color3.fromRGB(60, 20, 100), extraLight = 1 },
    Rainbow = { material = "Neon", colorShift = true, particleRate = 15, extraLight = 2 },
    Golden = { material = "Neon", color = Color3.fromRGB(255, 215, 0), particleRate = 20, extraLight = 3 },
}

return PDT
