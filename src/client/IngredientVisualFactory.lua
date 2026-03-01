local IngredientVisualFactory = {}

-- Cache built models to avoid recreation
local modelCache = {}

-- Element colors for backgrounds
IngredientVisualFactory.ElementColors = {
    Fire =   Color3.fromRGB(200, 60, 30),
    Water =  Color3.fromRGB(40, 100, 200),
    Earth =  Color3.fromRGB(120, 90, 50),
    Air =    Color3.fromRGB(150, 200, 220),
    Shadow = Color3.fromRGB(80, 40, 120),
    Light =  Color3.fromRGB(220, 200, 100),
}

-- Rarity border colors
IngredientVisualFactory.RarityColors = {
    Common =   Color3.fromRGB(150, 150, 150),
    Uncommon = Color3.fromRGB(60, 140, 220),
    Rare =     Color3.fromRGB(255, 200, 50),
    Mythic =   Color3.fromRGB(200, 80, 255),
    Divine =   Color3.fromRGB(255, 255, 255),
}

-- Helper: create a Part with defaults
local function makePart(props)
    local p = Instance.new("Part")
    p.Anchored = true
    p.CanCollide = false
    for k, v in pairs(props) do p[k] = v end
    return p
end

-- Helper: Color3 from {r,g,b} table
local function c3(t)
    if not t then return Color3.new(1,1,1) end
    return Color3.fromRGB(t[1] or 255, t[2] or 255, t[3] or 255)
end

-- Helper: resolve material
local function mat(name)
    local m = Enum.Material[name]
    return m or Enum.Material.SmoothPlastic
end

-- ============================================================
-- SHAPE BUILDERS: Each returns a Model with parts
-- ============================================================
local ShapeBuilders = {}

ShapeBuilders.mushroom = function(vis)
    local m = Instance.new("Model"); m.Name = "IngModel"
    local cap = makePart({ Shape = Enum.PartType.Ball, Size = Vector3.new(1.2, 0.8, 1.2), Position = Vector3.new(0, 0.8, 0), Color = c3(vis.primaryColor), Material = mat(vis.material) })
    local stem = makePart({ Size = Vector3.new(0.3, 0.8, 0.3), Position = Vector3.new(0, 0.2, 0), Color = c3(vis.secondaryColor), Material = Enum.Material.SmoothPlastic })
    cap.Parent = m; stem.Parent = m; m.PrimaryPart = cap
    return m
end

ShapeBuilders.leaf = function(vis)
    local m = Instance.new("Model"); m.Name = "IngModel"
    local leaf = makePart({ Size = Vector3.new(0.8, 0.1, 1.4), Position = Vector3.new(0, 0.5, 0), Color = c3(vis.primaryColor), Material = mat(vis.material) })
    leaf.CFrame = leaf.CFrame * CFrame.Angles(0, 0, math.rad(15))
    local vein = makePart({ Size = Vector3.new(0.05, 0.05, 1.2), Position = Vector3.new(0, 0.55, 0), Color = c3(vis.secondaryColor), Material = Enum.Material.SmoothPlastic })
    leaf.Parent = m; vein.Parent = m; m.PrimaryPart = leaf
    return m
end

ShapeBuilders.crystal = function(vis)
    local m = Instance.new("Model"); m.Name = "IngModel"
    local main = makePart({ Size = Vector3.new(0.4, 1.4, 0.4), Position = Vector3.new(0, 0.7, 0), Color = c3(vis.primaryColor), Material = mat(vis.material) })
    main.CFrame = main.CFrame * CFrame.Angles(0, 0, math.rad(8))
    local side1 = makePart({ Size = Vector3.new(0.25, 0.9, 0.25), Position = Vector3.new(0.3, 0.5, 0.1), Color = c3(vis.secondaryColor), Material = mat(vis.material) })
    side1.CFrame = side1.CFrame * CFrame.Angles(0, math.rad(20), math.rad(-15))
    local side2 = makePart({ Size = Vector3.new(0.2, 0.6, 0.2), Position = Vector3.new(-0.25, 0.4, -0.15), Color = c3(vis.primaryColor), Material = mat(vis.material) })
    side2.CFrame = side2.CFrame * CFrame.Angles(0, math.rad(-30), math.rad(12))
    main.Parent = m; side1.Parent = m; side2.Parent = m; m.PrimaryPart = main
    return m
end

ShapeBuilders.feather = function(vis)
    local m = Instance.new("Model"); m.Name = "IngModel"
    local shaft = makePart({ Size = Vector3.new(0.06, 1.6, 0.06), Position = Vector3.new(0, 0.8, 0), Color = c3(vis.secondaryColor), Material = Enum.Material.SmoothPlastic })
    shaft.CFrame = shaft.CFrame * CFrame.Angles(0, 0, math.rad(10))
    local vane = makePart({ Size = Vector3.new(0.6, 1.2, 0.05), Position = Vector3.new(0.15, 0.9, 0), Color = c3(vis.primaryColor), Material = vis.emissive and Enum.Material.Neon or mat(vis.material) })
    vane.CFrame = vane.CFrame * CFrame.Angles(0, 0, math.rad(10))
    shaft.Parent = m; vane.Parent = m; m.PrimaryPart = shaft
    return m
end

ShapeBuilders.scale = function(vis)
    local m = Instance.new("Model"); m.Name = "IngModel"
    local main = makePart({ Size = Vector3.new(1.0, 0.1, 1.2), Position = Vector3.new(0, 0.5, 0), Color = c3(vis.primaryColor), Material = mat(vis.material) })
    main.CFrame = main.CFrame * CFrame.Angles(math.rad(20), math.rad(15), 0)
    local edge = makePart({ Size = Vector3.new(0.8, 0.08, 0.1), Position = Vector3.new(0, 0.55, 0.5), Color = c3(vis.secondaryColor), Material = vis.emissive and Enum.Material.Neon or mat(vis.material) })
    main.Parent = m; edge.Parent = m; m.PrimaryPart = main
    return m
end

ShapeBuilders.vial = function(vis)
    local m = Instance.new("Model"); m.Name = "IngModel"
    local body = makePart({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(1.0, 0.4, 0.4), Position = Vector3.new(0, 0.5, 0), Color = c3(vis.primaryColor), Material = mat(vis.material) })
    body.CFrame = body.CFrame * CFrame.Angles(0, 0, math.rad(90))
    local neck = makePart({ Size = Vector3.new(0.15, 0.3, 0.15), Position = Vector3.new(0, 1.1, 0), Color = c3(vis.secondaryColor), Material = Enum.Material.Glass })
    local cork = makePart({ Shape = Enum.PartType.Ball, Size = Vector3.new(0.2, 0.2, 0.2), Position = Vector3.new(0, 1.3, 0), Color = Color3.fromRGB(160, 120, 60), Material = Enum.Material.Wood })
    body.Parent = m; neck.Parent = m; cork.Parent = m; m.PrimaryPart = body
    return m
end

ShapeBuilders.flower = function(vis)
    local m = Instance.new("Model"); m.Name = "IngModel"
    local center = makePart({ Shape = Enum.PartType.Ball, Size = Vector3.new(0.3, 0.3, 0.3), Position = Vector3.new(0, 0.7, 0), Color = c3(vis.secondaryColor), Material = vis.emissive and Enum.Material.Neon or Enum.Material.SmoothPlastic })
    center.Parent = m; m.PrimaryPart = center
    for i = 1, 5 do
        local angle = (i - 1) * (2 * math.pi / 5)
        local petal = makePart({ Size = Vector3.new(0.5, 0.08, 0.3), Color = c3(vis.primaryColor), Material = vis.emissive and Enum.Material.Neon or mat(vis.material) })
        petal.CFrame = CFrame.new(math.cos(angle) * 0.4, 0.7, math.sin(angle) * 0.4) * CFrame.Angles(0, -angle, math.rad(30))
        petal.Parent = m
    end
    local stem = makePart({ Size = Vector3.new(0.06, 0.5, 0.06), Position = Vector3.new(0, 0.3, 0), Color = Color3.fromRGB(50, 120, 50), Material = Enum.Material.SmoothPlastic })
    stem.Parent = m
    return m
end

ShapeBuilders.dust = function(vis)
    local m = Instance.new("Model"); m.Name = "IngModel"
    for i = 1, 6 do
        local p = makePart({ Shape = Enum.PartType.Ball, Size = Vector3.new(0.15, 0.15, 0.15), Color = c3(i % 2 == 0 and vis.primaryColor or vis.secondaryColor), Material = vis.emissive and Enum.Material.Neon or mat(vis.material) })
        p.Position = Vector3.new(math.random(-30, 30)/100, math.random(20, 80)/100, math.random(-30, 30)/100)
        p.Parent = m
        if i == 1 then m.PrimaryPart = p end
    end
    return m
end

ShapeBuilders.shard = function(vis)
    local m = Instance.new("Model"); m.Name = "IngModel"
    local main = makePart({ Size = Vector3.new(0.5, 1.4, 0.3), Position = Vector3.new(0, 0.7, 0), Color = c3(vis.primaryColor), Material = vis.emissive and Enum.Material.Neon or mat(vis.material) })
    main.CFrame = main.CFrame * CFrame.Angles(math.rad(5), math.rad(12), math.rad(-8))
    local chip = makePart({ Size = Vector3.new(0.3, 0.6, 0.2), Position = Vector3.new(0.3, 0.4, 0.1), Color = c3(vis.secondaryColor), Material = vis.emissive and Enum.Material.Neon or mat(vis.material) })
    chip.CFrame = chip.CFrame * CFrame.Angles(0, math.rad(25), math.rad(15))
    main.Parent = m; chip.Parent = m; m.PrimaryPart = main
    return m
end

ShapeBuilders.bone = function(vis)
    local m = Instance.new("Model"); m.Name = "IngModel"
    local shaft = makePart({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(1.2, 0.2, 0.2), Position = Vector3.new(0, 0.5, 0), Color = c3(vis.primaryColor), Material = mat(vis.material) })
    shaft.CFrame = shaft.CFrame * CFrame.Angles(0, 0, math.rad(90))
    local end1 = makePart({ Shape = Enum.PartType.Ball, Size = Vector3.new(0.35, 0.35, 0.35), Position = Vector3.new(0, 1.1, 0), Color = c3(vis.primaryColor), Material = mat(vis.material) })
    local end2 = makePart({ Shape = Enum.PartType.Ball, Size = Vector3.new(0.3, 0.3, 0.3), Position = Vector3.new(0, 0.0, 0), Color = c3(vis.secondaryColor), Material = mat(vis.material) })
    shaft.Parent = m; end1.Parent = m; end2.Parent = m; m.PrimaryPart = shaft
    return m
end

ShapeBuilders.orb = function(vis)
    local m = Instance.new("Model"); m.Name = "IngModel"
    local outer = makePart({ Shape = Enum.PartType.Ball, Size = Vector3.new(0.9, 0.9, 0.9), Position = Vector3.new(0, 0.6, 0), Color = c3(vis.primaryColor), Material = vis.emissive and Enum.Material.Neon or mat(vis.material), Transparency = vis.emissive and 0 or 0.1 })
    local inner = makePart({ Shape = Enum.PartType.Ball, Size = Vector3.new(0.5, 0.5, 0.5), Position = Vector3.new(0, 0.6, 0), Color = c3(vis.secondaryColor), Material = Enum.Material.Neon, Transparency = 0.3 })
    outer.Parent = m; inner.Parent = m; m.PrimaryPart = outer
    return m
end

ShapeBuilders.ember = function(vis)
    local m = Instance.new("Model"); m.Name = "IngModel"
    local core = makePart({ Shape = Enum.PartType.Ball, Size = Vector3.new(0.7, 0.7, 0.7), Position = Vector3.new(0, 0.5, 0), Color = c3(vis.primaryColor), Material = vis.emissive and Enum.Material.Neon or Enum.Material.Slate })
    local glow = makePart({ Shape = Enum.PartType.Ball, Size = Vector3.new(0.4, 0.4, 0.4), Position = Vector3.new(0, 0.5, 0), Color = c3(vis.secondaryColor), Material = Enum.Material.Neon, Transparency = 0.3 })
    core.Parent = m; glow.Parent = m; m.PrimaryPart = core
    return m
end

ShapeBuilders.fang = function(vis)
    local m = Instance.new("Model"); m.Name = "IngModel"
    local tooth = makePart({ Size = Vector3.new(0.25, 1.3, 0.25), Position = Vector3.new(0, 0.65, 0), Color = c3(vis.primaryColor), Material = mat(vis.material) })
    tooth.CFrame = tooth.CFrame * CFrame.Angles(0, 0, math.rad(5))
    -- Green venom tip
    local tip = makePart({ Shape = Enum.PartType.Ball, Size = Vector3.new(0.15, 0.15, 0.15), Position = Vector3.new(0.05, 0.05, 0), Color = c3(vis.secondaryColor), Material = Enum.Material.Neon })
    tooth.Parent = m; tip.Parent = m; m.PrimaryPart = tooth
    return m
end

ShapeBuilders.tear = function(vis)
    local m = Instance.new("Model"); m.Name = "IngModel"
    local drop = makePart({ Shape = Enum.PartType.Ball, Size = Vector3.new(0.6, 0.8, 0.6), Position = Vector3.new(0, 0.5, 0), Color = c3(vis.primaryColor), Material = mat(vis.material), Transparency = 0.2 })
    local point = makePart({ Size = Vector3.new(0.15, 0.3, 0.15), Position = Vector3.new(0, 0.95, 0), Color = c3(vis.secondaryColor), Material = mat(vis.material), Transparency = 0.2 })
    drop.Parent = m; point.Parent = m; m.PrimaryPart = drop
    return m
end

ShapeBuilders.silk = function(vis)
    local m = Instance.new("Model"); m.Name = "IngModel"
    local ribbon = makePart({ Size = Vector3.new(1.0, 0.04, 0.4), Position = Vector3.new(0, 0.6, 0), Color = c3(vis.primaryColor), Material = vis.emissive and Enum.Material.Neon or mat(vis.material), Transparency = 0.3 })
    ribbon.CFrame = ribbon.CFrame * CFrame.Angles(math.rad(10), math.rad(20), math.rad(5))
    local fold = makePart({ Size = Vector3.new(0.8, 0.04, 0.3), Position = Vector3.new(-0.1, 0.5, 0.15), Color = c3(vis.secondaryColor), Material = vis.emissive and Enum.Material.Neon or mat(vis.material), Transparency = 0.3 })
    fold.CFrame = fold.CFrame * CFrame.Angles(math.rad(-8), math.rad(-10), math.rad(-5))
    ribbon.Parent = m; fold.Parent = m; m.PrimaryPart = ribbon
    return m
end

-- ============================================================
-- PUBLIC API
-- ============================================================

-- Build a 3D model for an ingredient
function IngredientVisualFactory.createModel(ingredientData)
    if not ingredientData or not ingredientData.visual then
        -- Fallback orb
        return ShapeBuilders.orb({ primaryColor = {150,150,150}, secondaryColor = {100,100,100}, material = "SmoothPlastic", emissive = false })
    end

    local vis = ingredientData.visual
    local builder = ShapeBuilders[vis.archetype]
    if not builder then
        builder = ShapeBuilders.orb
    end

    local model = builder(vis)

    -- Add rarity particles if applicable
    if vis.particleRate and vis.particleRate > 0 and model.PrimaryPart then
        local pe = Instance.new("ParticleEmitter")
        pe.Name = "RarityParticles"
        pe.Color = ColorSequence.new(c3(vis.particleColor or vis.primaryColor))
        pe.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.5, 0.1), NumberSequenceKeypoint.new(1, 0) })
        pe.Lifetime = NumberRange.new(0.5, 1.5)
        pe.Rate = vis.particleRate
        pe.Speed = NumberRange.new(0.3, 1)
        pe.SpreadAngle = Vector2.new(180, 180)
        pe.LightEmission = 1
        pe.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 1)})
        pe.Parent = model.PrimaryPart
    end

    -- Add glow light for emissive ingredients
    if vis.emissive and model.PrimaryPart then
        local light = Instance.new("PointLight")
        light.Color = c3(vis.primaryColor)
        light.Brightness = 0.8
        light.Range = 3
        light.Parent = model.PrimaryPart
    end

    return model
end

-- Render ingredient in a ViewportFrame
function IngredientVisualFactory.renderInViewport(ingredientData, viewportFrame)
    -- Clear existing
    for _, child in ipairs(viewportFrame:GetChildren()) do
        if child:IsA("Model") or child:IsA("Camera") or child:IsA("WorldModel") then child:Destroy() end
    end

    -- Set viewport lighting
    viewportFrame.Ambient = Color3.fromRGB(180, 170, 200)
    viewportFrame.LightColor = Color3.fromRGB(255, 250, 240)
    viewportFrame.LightDirection = Vector3.new(-1, -1, -1)
    viewportFrame.BackgroundColor3 = Color3.fromRGB(30, 25, 40)
    viewportFrame.BackgroundTransparency = 0.5

    -- Use WorldModel for proper rendering
    local worldModel = Instance.new("WorldModel")
    worldModel.Parent = viewportFrame

    local model = IngredientVisualFactory.createModel(ingredientData)
    model.Parent = worldModel

    -- Create and position camera looking at origin
    local cam = Instance.new("Camera")
    cam.CFrame = CFrame.new(Vector3.new(1.8, 1.2, 1.8), Vector3.new(0, 0.5, 0))
    cam.FieldOfView = 50
    cam.Parent = viewportFrame
    viewportFrame.CurrentCamera = cam

    return model
end
return IngredientVisualFactory