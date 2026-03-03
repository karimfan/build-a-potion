local Workspace = game:GetService("Workspace")

local RNG_SEED = 28042026
local DECOR_FOLDER_NAME = "MysticalDecor"
local SAFE_NODE_RADIUS = 10

local rng = Random.new(RNG_SEED)

local function findWildGrove()
    local zones = Workspace:FindFirstChild("Zones")
    if not zones then
        return nil
    end
    return zones:FindFirstChild("WildGrove")
end

local function collectForageNodes(grove)
    local points = {}
    for _, inst in ipairs(grove:GetDescendants()) do
        if inst:IsA("BasePart") and inst.Name:match("ForageNode") then
            table.insert(points, inst.Position)
        end
    end
    return points
end

local function getFloorY(grove)
    local floor = grove:FindFirstChild("Floor")
    if floor and floor:IsA("BasePart") then
        return floor.Position.Y + floor.Size.Y * 0.5
    end
    return grove:GetPivot().Position.Y
end

local function isNearAnyNode(pos, nodePoints, radius)
    for _, p in ipairs(nodePoints) do
        if (p - pos).Magnitude < radius then
            return true
        end
    end
    return false
end

local function randomPoint(center, innerRadius, outerRadius, y)
    local a = rng:NextNumber(0, math.pi * 2)
    local r = rng:NextNumber(innerRadius, outerRadius)
    return Vector3.new(center.X + math.cos(a) * r, y, center.Z + math.sin(a) * r)
end

local function makePart(parent, props)
    local p = Instance.new("Part")
    p.Anchored = true
    p.CanCollide = false
    p.TopSurface = Enum.SurfaceType.Smooth
    p.BottomSurface = Enum.SurfaceType.Smooth
    p.CastShadow = false
    for k, v in pairs(props) do
        p[k] = v
    end
    p.Parent = parent
    return p
end

local function createAmbientMotes(parent, center, y)
    local anchor = makePart(parent, {
        Name = "AmbientMotesAnchor",
        Size = Vector3.new(2, 2, 2),
        Position = Vector3.new(center.X, y + 12, center.Z),
        Transparency = 1,
    })
    local emitter = Instance.new("ParticleEmitter")
    emitter.Name = "AmbientMotes"
    emitter.Rate = 85
    emitter.Lifetime = NumberRange.new(6, 11)
    emitter.Speed = NumberRange.new(0.35, 1.4)
    emitter.SpreadAngle = Vector2.new(180, 180)
    emitter.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.08),
        NumberSequenceKeypoint.new(0.6, 0.14),
        NumberSequenceKeypoint.new(1, 0),
    })
    emitter.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.2),
        NumberSequenceKeypoint.new(0.7, 0.35),
        NumberSequenceKeypoint.new(1, 1),
    })
    emitter.Color = ColorSequence.new(Color3.fromRGB(90, 160, 255), Color3.fromRGB(176, 118, 255))
    emitter.LightEmission = 1
    emitter.Parent = anchor
end

local function createMoonlightBeacon(parent, center, y)
    local moon = makePart(parent, {
        Name = "MoonlightOrb",
        Shape = Enum.PartType.Ball,
        Size = Vector3.new(6, 6, 6),
        Position = Vector3.new(center.X + 6, y + 42, center.Z - 26),
        Color = Color3.fromRGB(180, 200, 255),
        Material = Enum.Material.Neon,
        Transparency = 0.35,
    })
    local glow = Instance.new("PointLight")
    glow.Color = Color3.fromRGB(145, 170, 255)
    glow.Brightness = 2
    glow.Range = 85
    glow.Parent = moon
end

local function createAncientTree(parent, pos, baseY)
    local model = Instance.new("Model")
    model.Name = "AncientTree"
    model.Parent = parent

    local trunk = makePart(model, {
        Shape = Enum.PartType.Cylinder,
        Size = Vector3.new(12, 6.4, 6.4),
        CFrame = CFrame.new(pos.X, baseY + 6, pos.Z) * CFrame.Angles(0, 0, math.rad(90)),
        Color = Color3.fromRGB(58, 37, 82),
        Material = Enum.Material.Wood,
    })

    for i = 1, 7 do
        local orbPos = pos + Vector3.new(
            rng:NextNumber(-5, 5),
            rng:NextNumber(8, 15),
            rng:NextNumber(-5, 5)
        )
        makePart(model, {
            Shape = Enum.PartType.Ball,
            Size = Vector3.new(rng:NextNumber(5.5, 8), rng:NextNumber(5.5, 8), rng:NextNumber(5.5, 8)),
            Position = orbPos,
            Color = Color3.fromRGB(26, 56, 58),
            Material = Enum.Material.LeafyGrass,
            Transparency = 0.12,
        })
    end

    for i = 1, 18 do
        local pod = makePart(model, {
            Shape = Enum.PartType.Ball,
            Size = Vector3.new(0.7, 0.7, 0.7),
            Position = pos + Vector3.new(
                rng:NextNumber(-4.5, 4.5),
                rng:NextNumber(7.5, 15),
                rng:NextNumber(-4.5, 4.5)
            ),
            Color = Color3.fromRGB(100, 156, 255),
            Material = Enum.Material.Neon,
        })
        local light = Instance.new("PointLight")
        light.Color = Color3.fromRGB(88, 130, 255)
        light.Range = 10
        light.Brightness = 1.35
        light.Parent = pod
    end

    for i = 1, 8 do
        local rune = makePart(model, {
            Name = "TreeRune",
            Shape = Enum.PartType.Ball,
            Size = Vector3.new(0.4, 0.4, 0.4),
            Position = pos + Vector3.new(
                rng:NextNumber(-2.8, 2.8),
                rng:NextNumber(2.6, 8.5),
                rng:NextNumber(-2.8, 2.8)
            ),
            Color = Color3.fromRGB(165, 115, 255),
            Material = Enum.Material.Neon,
        })
        local pl = Instance.new("PointLight")
        pl.Color = Color3.fromRGB(165, 115, 255)
        pl.Range = 6
        pl.Brightness = 0.7
        pl.Parent = rune
    end

    model.PrimaryPart = trunk
end

local function createTree(parent, pos, baseY)
    local trunkHeight = rng:NextNumber(4, 7)
    local trunk = makePart(parent, {
        Shape = Enum.PartType.Cylinder,
        Size = Vector3.new(trunkHeight, 1.8, 1.8),
        CFrame = CFrame.new(pos.X, baseY + trunkHeight * 0.5, pos.Z) * CFrame.Angles(0, 0, math.rad(90)),
        Color = Color3.fromRGB(64, 44, 86),
        Material = Enum.Material.Wood,
    })
    local canopySize = rng:NextNumber(4.5, 6.5)
    makePart(parent, {
        Shape = Enum.PartType.Ball,
        Size = Vector3.new(canopySize, canopySize, canopySize),
        Position = pos + Vector3.new(0, trunkHeight + rng:NextNumber(1.6, 2.5), 0),
        Color = Color3.fromRGB(22, 62, 72),
        Material = Enum.Material.LeafyGrass,
        Transparency = 0.15,
    })
    if rng:NextNumber() < 0.45 then
        local fruit = makePart(parent, {
            Shape = Enum.PartType.Ball,
            Size = Vector3.new(0.5, 0.5, 0.5),
            Position = pos + Vector3.new(rng:NextNumber(-1.4, 1.4), trunkHeight + rng:NextNumber(1.2, 3.2), rng:NextNumber(-1.4, 1.4)),
            Color = Color3.fromRGB(90, 190, 255),
            Material = Enum.Material.Neon,
        })
        local pl = Instance.new("PointLight")
        pl.Color = Color3.fromRGB(90, 190, 255)
        pl.Range = 4
        pl.Brightness = 0.6
        pl.Parent = fruit
    end
    return trunk
end

local function createShrub(parent, pos, baseY)
    for i = 1, rng:NextInteger(2, 4) do
        makePart(parent, {
            Shape = Enum.PartType.Ball,
            Size = Vector3.new(
                rng:NextNumber(1.8, 3.1),
                rng:NextNumber(1.3, 2.3),
                rng:NextNumber(1.8, 3.1)
            ),
            Position = pos + Vector3.new(rng:NextNumber(-1, 1), rng:NextNumber(0.8, 1.4), rng:NextNumber(-1, 1)),
            Color = Color3.fromRGB(28, 90, 74),
            Material = Enum.Material.Grass,
            Transparency = 0.16,
        })
    end
end

local function createCrystalCluster(parent, pos, baseY)
    local anchor = makePart(parent, {
        Shape = Enum.PartType.Ball,
        Size = Vector3.new(1.1, 1.1, 1.1),
        Position = Vector3.new(pos.X, baseY + 0.6, pos.Z),
        Color = Color3.fromRGB(90, 138, 255),
        Material = Enum.Material.Neon,
    })
    local light = Instance.new("PointLight")
    light.Color = Color3.fromRGB(118, 145, 255)
    light.Brightness = 1.4
    light.Range = 12
    light.Parent = anchor

    for i = 1, rng:NextInteger(2, 4) do
        makePart(parent, {
            Size = Vector3.new(rng:NextNumber(0.6, 1.1), rng:NextNumber(2.1, 3.8), rng:NextNumber(0.6, 1.1)),
            Position = pos + Vector3.new(rng:NextNumber(-1, 1), rng:NextNumber(1, 1.8), rng:NextNumber(-1, 1)),
            Color = Color3.fromRGB(160, 170, 255),
            Material = Enum.Material.Glass,
            Transparency = 0.2,
        })
    end
end

local function createRuneStone(parent, pos, baseY)
    local stone = makePart(parent, {
        Size = Vector3.new(rng:NextNumber(1.2, 1.8), rng:NextNumber(2.2, 3.5), rng:NextNumber(0.8, 1.2)),
        CFrame = CFrame.new(pos.X, baseY + rng:NextNumber(1.2, 1.8), pos.Z)
            * CFrame.Angles(0, math.rad(rng:NextInteger(0, 359)), math.rad(rng:NextInteger(-10, 10))),
        Color = Color3.fromRGB(68, 74, 92),
        Material = Enum.Material.Slate,
    })
    local rune = Instance.new("SurfaceLight")
    rune.Face = Enum.NormalId.Front
    rune.Brightness = 0.7
    rune.Range = 4
    rune.Color = Color3.fromRGB(125, 210, 255)
    rune.Parent = stone
end

local function createArcaneRuins(parent, center, baseY, nodePoints)
    for i = 1, 8 do
        local placed = false
        for _ = 1, 24 do
            local p = randomPoint(center, 16, 72, baseY)
            if not isNearAnyNode(p, nodePoints, SAFE_NODE_RADIUS + 3) then
                placed = true
                local pillarH = rng:NextNumber(8, 14)
                makePart(parent, {
                    Name = "RuinPillar",
                    Size = Vector3.new(rng:NextNumber(1.4, 2.2), pillarH, rng:NextNumber(1.4, 2.2)),
                    Position = Vector3.new(p.X, baseY + pillarH * 0.5, p.Z),
                    Color = Color3.fromRGB(56, 60, 84),
                    Material = Enum.Material.Slate,
                })
                if rng:NextNumber() < 0.5 then
                    local cap = makePart(parent, {
                        Name = "RuinCap",
                        Size = Vector3.new(2.8, 0.8, 2.8),
                        Position = Vector3.new(p.X, baseY + pillarH + 0.2, p.Z),
                        Color = Color3.fromRGB(68, 72, 98),
                        Material = Enum.Material.Rock,
                    })
                    cap.Orientation = Vector3.new(rng:NextNumber(-6, 6), rng:NextNumber(0, 360), rng:NextNumber(-6, 6))
                end
                break
            end
        end
        if not placed then
            break
        end
    end

    for i = 1, 4 do
        local p = randomPoint(center, 20, 64, baseY)
        if not isNearAnyNode(p, nodePoints, SAFE_NODE_RADIUS + 4) then
            local archA = makePart(parent, {
                Name = "RuinArchA",
                Size = Vector3.new(2, 8, 2),
                Position = Vector3.new(p.X - 3.2, baseY + 4, p.Z),
                Color = Color3.fromRGB(58, 62, 88),
                Material = Enum.Material.Slate,
            })
            local archB = makePart(parent, {
                Name = "RuinArchB",
                Size = Vector3.new(2, 8, 2),
                Position = Vector3.new(p.X + 3.2, baseY + 4, p.Z),
                Color = Color3.fromRGB(58, 62, 88),
                Material = Enum.Material.Slate,
            })
            local top = makePart(parent, {
                Name = "RuinArchTop",
                Size = Vector3.new(8, 1.5, 2),
                Position = Vector3.new(p.X, baseY + 8.1, p.Z),
                Color = Color3.fromRGB(66, 70, 96),
                Material = Enum.Material.Rock,
            })
            local rot = rng:NextNumber(0, 360)
            archA.Orientation = Vector3.new(0, rot, rng:NextNumber(-3, 3))
            archB.Orientation = Vector3.new(0, rot, rng:NextNumber(-3, 3))
            top.Orientation = Vector3.new(rng:NextNumber(-6, 6), rot, rng:NextNumber(-6, 6))
        end
    end
end

local function createFloatingArcaneStones(parent, center, baseY, nodePoints)
    for i = 1, 18 do
        local p = randomPoint(center, 14, 70, baseY)
        if not isNearAnyNode(p, nodePoints, SAFE_NODE_RADIUS + 4) then
            local stone = makePart(parent, {
                Name = "FloatingArcaneStone",
                Size = Vector3.new(rng:NextNumber(1.2, 2.8), rng:NextNumber(0.8, 1.7), rng:NextNumber(1.2, 2.8)),
                Position = Vector3.new(p.X, baseY + rng:NextNumber(3.5, 8), p.Z),
                Color = Color3.fromRGB(64, 69, 99),
                Material = Enum.Material.Rock,
            })
            stone.Orientation = Vector3.new(rng:NextNumber(0, 360), rng:NextNumber(0, 360), rng:NextNumber(0, 360))
            if rng:NextNumber() < 0.4 then
                local rune = makePart(parent, {
                    Name = "ArcaneShard",
                    Shape = Enum.PartType.Ball,
                    Size = Vector3.new(0.35, 0.35, 0.35),
                    Position = stone.Position + Vector3.new(0, rng:NextNumber(0.8, 1.4), 0),
                    Color = Color3.fromRGB(150, 120, 255),
                    Material = Enum.Material.Neon,
                })
                local pl = Instance.new("PointLight")
                pl.Color = Color3.fromRGB(150, 120, 255)
                pl.Range = 4
                pl.Brightness = 0.55
                pl.Parent = rune
            end
        end
    end
end

local function tuneCauldron()
    local zones = Workspace:FindFirstChild("Zones")
    if not zones then
        return
    end
    local yourShop = zones:FindFirstChild("YourShop")
    if not yourShop then
        return
    end
    local cauldron = yourShop:FindFirstChild("Cauldron")
    if not cauldron then
        return
    end

    local bronze = Color3.fromRGB(157, 105, 61)

    if cauldron:IsA("BasePart") then
        local oldY = cauldron.Size.Y
        cauldron.Size = Vector3.new(cauldron.Size.X * 0.82, cauldron.Size.Y * 0.82, cauldron.Size.Z * 0.82)
        cauldron.Position = cauldron.Position - Vector3.new(0, (oldY - cauldron.Size.Y) * 0.5, 0)
        cauldron.Material = Enum.Material.Metal
        cauldron.Color = bronze
    elseif cauldron:IsA("Model") then
        pcall(function()
            cauldron:ScaleTo(0.82)
        end)
        for _, d in ipairs(cauldron:GetDescendants()) do
            if d:IsA("BasePart") then
                d.Material = Enum.Material.Metal
                d.Color = bronze
            end
        end
    end
end

local function buildMysticalGrove()
    local grove = findWildGrove()
    if not grove then
        warn("[WildGroveDecorationService] WildGrove not found")
        return
    end

    local existing = grove:FindFirstChild(DECOR_FOLDER_NAME)
    if existing then
        existing:Destroy()
    end

    local decor = Instance.new("Folder")
    decor.Name = DECOR_FOLDER_NAME
    decor.Parent = grove

    local floorY = getFloorY(grove)
    local nodePoints = collectForageNodes(grove)
    local center = grove:GetPivot().Position
    center = Vector3.new(center.X, floorY, center.Z)

    createAncientTree(decor, center + Vector3.new(0, 0, -12), floorY)
    createAmbientMotes(decor, center, floorY)
    createMoonlightBeacon(decor, center, floorY)

    local function placeMany(count, minR, maxR, radiusCheck, placeFn, maxAttempts)
        local placed = 0
        local attempts = 0
        local attemptLimit = maxAttempts or (count * 15)
        while placed < count and attempts < attemptLimit do
            attempts = attempts + 1
            local p = randomPoint(center, minR, maxR, floorY)
            if not isNearAnyNode(p, nodePoints, radiusCheck) then
                placeFn(decor, p, floorY)
                placed = placed + 1
            end
        end
    end

    placeMany(26, 22, 82, SAFE_NODE_RADIUS + 2, createTree)
    placeMany(58, 8, 84, SAFE_NODE_RADIUS, createShrub)
    placeMany(22, 14, 80, SAFE_NODE_RADIUS + 3, createCrystalCluster)
    placeMany(34, 10, 82, SAFE_NODE_RADIUS + 2, createRuneStone)
    createArcaneRuins(decor, center, floorY, nodePoints)
    createFloatingArcaneStones(decor, center, floorY, nodePoints)

    for _, inst in ipairs(grove:GetDescendants()) do
        if inst:IsA("BasePart") and inst.Name:match("ForageNode") then
            if not inst:FindFirstChild("MysticNodeLight") then
                local light = Instance.new("PointLight")
                light.Name = "MysticNodeLight"
                light.Color = Color3.fromRGB(125, 150, 255)
                light.Brightness = 1.8
                light.Range = 12
                light.Parent = inst
            end
        end
    end

    tuneCauldron()
    print("[WildGroveDecorationService] Mystical decor generated")
end

task.defer(buildMysticalGrove)
