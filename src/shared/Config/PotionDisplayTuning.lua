local PDT = {}

PDT.MaxDisplays = 30
PDT.ShelvesPerWall = 2 -- lower + upper
PDT.PotionsPerShelf = 5

-- Visual config per tier
PDT.TierVisuals = {
    Common = {
        shape = "Cylinder", -- vial
        size = Vector3.new(0.8, 0.4, 0.4),
        material = "Glass",
        transparency = 0.3,
        particleRate = 0,
        lightBrightness = 0,
    },
    Uncommon = {
        shape = "Cylinder",
        size = Vector3.new(0.9, 0.45, 0.45),
        material = "Glass",
        transparency = 0.2,
        particleRate = 0,
        lightBrightness = 0.5,
        lightRange = 4,
    },
    Rare = {
        shape = "Cylinder",
        size = Vector3.new(1.0, 0.5, 0.5),
        material = "Glass",
        transparency = 0.1,
        particleRate = 3,
        lightBrightness = 1.0,
        lightRange = 6,
    },
    Mythic = {
        shape = "Ball",
        size = Vector3.new(0.7, 0.7, 0.7),
        material = "Neon",
        transparency = 0,
        particleRate = 6,
        lightBrightness = 1.5,
        lightRange = 8,
    },
    Divine = {
        shape = "Ball",
        size = Vector3.new(0.8, 0.8, 0.8),
        material = "Neon",
        transparency = 0,
        particleRate = 10,
        lightBrightness = 2.5,
        lightRange = 12,
        floats = true,
    },
}

-- Element colors for potion tint
PDT.ElementColors = {
    Fire = Color3.fromRGB(255, 100, 30),
    Water = Color3.fromRGB(50, 150, 255),
    Earth = Color3.fromRGB(120, 180, 60),
    Air = Color3.fromRGB(180, 220, 255),
    Shadow = Color3.fromRGB(100, 40, 150),
    Light = Color3.fromRGB(255, 230, 100),
}

-- Mutation visual modifiers
PDT.MutationModifiers = {
    Glowing = { material = "Neon", extraLight = 1 },
    Bubbling = { particleRate = 5, particleSpeed = 2 },
    Crystallized = { material = "Glass", transparency = 0 },
    Shadow = { material = "ForceField", color = Color3.fromRGB(30, 10, 40) },
    Rainbow = { material = "Neon", colorShift = true },
    Golden = { material = "Metal", color = Color3.fromRGB(255, 215, 0) },
}

return PDT
