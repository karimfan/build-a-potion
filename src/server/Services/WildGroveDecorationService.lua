local Workspace = game:GetService("Workspace")

local RNG_SEED = 28042026
local DECOR_FOLDER_NAME = "MysticalDecor"
local SHOP_DECOR_FOLDER_NAME = "WizardDecor"
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

local function findYourShop()
    local zones = Workspace:FindFirstChild("Zones")
    if not zones then
        return nil
    end
    return zones:FindFirstChild("YourShop")
end

local function localToWorld(floorPart, x, y, z)
    return floorPart.CFrame:PointToWorldSpace(Vector3.new(x, y, z))
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
    local cauldronScale = 0.48

    if cauldron:IsA("BasePart") then
        local oldY = cauldron.Size.Y
        cauldron.Size = Vector3.new(cauldron.Size.X * cauldronScale, cauldron.Size.Y * cauldronScale, cauldron.Size.Z * cauldronScale)
        cauldron.Position = cauldron.Position - Vector3.new(0, (oldY - cauldron.Size.Y) * 0.5, 0)
        cauldron.Material = Enum.Material.Metal
        cauldron.Color = bronze
    elseif cauldron:IsA("Model") then
        pcall(function()
            cauldron:ScaleTo(cauldronScale)
        end)
        for _, d in ipairs(cauldron:GetDescendants()) do
            if d:IsA("BasePart") then
                d.Material = Enum.Material.Metal
                d.Color = bronze
            end
        end
    end
end

local function tuneYourShopFloor()
    -- Floor tiles live in workspace.Zones.LegoGround, not inside YourShop
    local zones = Workspace:FindFirstChild("Zones")
    if not zones then return end
    local legoGround = zones:FindFirstChild("LegoGround")
    if not legoGround then return end

    local brown = Color3.fromRGB(105, 72, 48)
    for _, d in ipairs(legoGround:GetChildren()) do
        if d:IsA("BasePart") and d.Name == "Tile" then
            if d.Position.X >= -50 and d.Position.X <= 50 and d.Position.Z >= -50 and d.Position.Z <= 50 then
                d.Material = Enum.Material.Brick
                d.Color = brown
            end
        end
    end
end

local function createWizardShopDecor()
    local yourShop = findYourShop()
    if not yourShop then return end

    -- Ensure Floor reference part exists
    local floor = yourShop:FindFirstChild("Floor")
    if not floor or not floor:IsA("BasePart") then
        floor = Instance.new("Part")
        floor.Name = "Floor"
        floor.Size = Vector3.new(100, 1, 100)
        floor.Position = Vector3.new(0, -0.5, 0)
        floor.Anchored = true
        floor.CanCollide = false
        floor.Transparency = 1
        floor.Parent = yourShop
    end

    local existing = yourShop:FindFirstChild(SHOP_DECOR_FOLDER_NAME)
    if existing then existing:Destroy() end

    local decor = Instance.new("Folder")
    decor.Name = SHOP_DECOR_FOLDER_NAME
    decor.Parent = yourShop

    local potionColors = {
        Color3.fromRGB(30,120,255), Color3.fromRGB(50,220,100), Color3.fromRGB(160,60,255),
        Color3.fromRGB(255,200,50), Color3.fromRGB(255,60,60), Color3.fromRGB(255,120,200),
        Color3.fromRGB(255,140,40), Color3.fromRGB(80,255,200), Color3.fromRGB(200,50,180),
        Color3.fromRGB(100,255,80), Color3.fromRGB(60,180,255), Color3.fromRGB(220,180,60),
    }
    local woodColor = Color3.fromRGB(65, 45, 30)

    -- Restyle boundary walls to dark cobblestone
    local boundaries = yourShop:FindFirstChild("Boundaries")
    if boundaries then
        for _, w in ipairs(boundaries:GetChildren()) do
            if w:IsA("BasePart") then
                w.Material = Enum.Material.Cobblestone
                w.Color = Color3.fromRGB(55, 45, 40)
            end
        end
    end

    -- Restyle floor tiles
    local zones = Workspace:FindFirstChild("Zones")
    local legoGround = zones and zones:FindFirstChild("LegoGround")
    if legoGround then
        for _, d in ipairs(legoGround:GetChildren()) do
            if d:IsA("BasePart") and d.Name == "Tile" then
                if d.Position.X >= -50 and d.Position.X <= 50 and d.Position.Z >= -50 and d.Position.Z <= 50 then
                    d.Material = Enum.Material.Cobblestone
                    d.Color = Color3.fromRGB(75, 60, 48)
                end
            end
        end
    end

    -- Raised cauldron platform (3 concentric rings)
    local pc = Color3.fromRGB(60, 50, 42)
    makePart(decor, { Name="Platform_Outer", Shape=Enum.PartType.Cylinder, Size=Vector3.new(1.2, 16, 16),
        CFrame=CFrame.new(0, 0.6, -8)*CFrame.Angles(0,0,math.rad(90)), Material=Enum.Material.Cobblestone, Color=pc })
    makePart(decor, { Name="Platform_Mid", Shape=Enum.PartType.Cylinder, Size=Vector3.new(1.8, 12, 12),
        CFrame=CFrame.new(0, 0.9, -8)*CFrame.Angles(0,0,math.rad(90)), Material=Enum.Material.Cobblestone, Color=Color3.fromRGB(65,55,45) })
    makePart(decor, { Name="Platform_Inner", Shape=Enum.PartType.Cylinder, Size=Vector3.new(2.4, 8, 8),
        CFrame=CFrame.new(0, 1.2, -8)*CFrame.Angles(0,0,math.rad(90)), Material=Enum.Material.Cobblestone, Color=Color3.fromRGB(70,58,48) })

    -- Gothic arch portal behind cauldron
    local ac = Color3.fromRGB(60, 50, 68)
    makePart(decor, { Name="ArchPillar_L", Size=Vector3.new(2.5, 14, 2), Position=Vector3.new(-5.5, 7, -48), Material=Enum.Material.Cobblestone, Color=ac })
    makePart(decor, { Name="ArchPillar_R", Size=Vector3.new(2.5, 14, 2), Position=Vector3.new(5.5, 7, -48), Material=Enum.Material.Cobblestone, Color=ac })
    for i = 0, 8 do
        local t = i / 8
        local ang = math.pi * t
        makePart(decor, { Name="ArchCurve_"..i, Size=Vector3.new(1.8, 1.8, 2),
            Position=Vector3.new(math.cos(ang)*5.5, 14+math.sin(ang)*4, -48),
            Material=Enum.Material.Cobblestone, Color=ac,
            Orientation=Vector3.new(0, 0, -math.deg(ang)+90) })
    end
    makePart(decor, { Name="ArchBack", Size=Vector3.new(9, 14, 0.5), Position=Vector3.new(0, 7, -49),
        Material=Enum.Material.Slate, Color=Color3.fromRGB(30, 25, 35), Transparency=0.1 })
    local sparkAnchor = makePart(decor, { Name="ArchSparkleAnchor", Size=Vector3.new(6, 10, 1),
        Position=Vector3.new(0, 9, -48.5), Transparency=1 })
    local sparkles = Instance.new("ParticleEmitter")
    sparkles.Rate = 60; sparkles.Lifetime = NumberRange.new(1.5, 4)
    sparkles.Speed = NumberRange.new(0.5, 2); sparkles.SpreadAngle = Vector2.new(40, 60)
    sparkles.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(0.5, 0.25), NumberSequenceKeypoint.new(1, 0)})
    sparkles.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(1, 1)})
    sparkles.Color = ColorSequence.new(Color3.fromRGB(150,80,255), Color3.fromRGB(200,150,255))
    sparkles.LightEmission = 1; sparkles.Parent = sparkAnchor
    local archGlow = makePart(decor, { Name="ArchGlow", Shape=Enum.PartType.Ball, Size=Vector3.new(2.5,2.5,2.5),
        Position=Vector3.new(0, 12, -48.5), Material=Enum.Material.Neon, Color=Color3.fromRGB(180,140,255), Transparency=0.3 })
    local agl = Instance.new("PointLight"); agl.Color=Color3.fromRGB(160,100,255); agl.Brightness=3; agl.Range=30; agl.Parent=archGlow

    -- Purple beam above cauldron
    makePart(decor, { Name="PurpleBeam", Shape=Enum.PartType.Cylinder, Size=Vector3.new(20, 1.5, 1.5),
        CFrame=CFrame.new(0, 15, -8)*CFrame.Angles(0,0,math.rad(90)),
        Material=Enum.Material.Neon, Color=Color3.fromRGB(130,70,220), Transparency=0.5 })

    -- Dense wall shelving (4 tiers, all walls) with potion bottles
    local shelfTiers = {1.8, 3.8, 5.8, 7.8}
    local function shelfRow(cx, cz, shelfY, width, wallAxis)
        local sx, sz = width, 2
        if wallAxis == "Z" then sx, sz = 2, width end
        makePart(decor, { Name="Shelf", Size=Vector3.new(sx, 0.3, sz),
            Position=Vector3.new(cx, shelfY, cz), Material=Enum.Material.WoodPlanks, Color=woodColor })
        makePart(decor, { Name="Bracket", Size=Vector3.new(sx*0.15, 0.6, sz*0.15),
            Position=Vector3.new(cx, shelfY-0.45, cz), Material=Enum.Material.Wood, Color=Color3.fromRGB(55,38,25) })
        local count = math.floor(width / 1.2)
        for b = 1, count do
            local offset = -width/2 + (b-0.5)*(width/count) + rng:NextNumber(-0.2, 0.2)
            local bx, bz = cx, cz
            if wallAxis == "X" then bz = cz + offset else bx = cx + offset end
            local h = rng:NextNumber(0.6, 1.4)
            local w = rng:NextNumber(0.3, 0.6)
            local color = potionColors[rng:NextInteger(1, #potionColors)]
            makePart(decor, { Name="Bottle", Shape=Enum.PartType.Cylinder, Size=Vector3.new(h, w, w),
                CFrame=CFrame.new(bx, shelfY+h/2+0.15, bz)*CFrame.Angles(0,0,math.rad(90)),
                Material=Enum.Material.Glass, Color=color, Transparency=0.2 })
            makePart(decor, { Name="Cork", Shape=Enum.PartType.Cylinder, Size=Vector3.new(0.15, w*0.6, w*0.6),
                CFrame=CFrame.new(bx, shelfY+h+0.22, bz)*CFrame.Angles(0,0,math.rad(90)),
                Material=Enum.Material.Wood, Color=Color3.fromRGB(140,100,60) })
        end
    end
    for _, tier in ipairs(shelfTiers) do
        shelfRow(-30, -47, tier, 18, "X"); shelfRow(30, -47, tier, 18, "X")
        shelfRow(-25, 47, tier, 20, "X"); shelfRow(25, 47, tier, 20, "X")
        shelfRow(47, -20, tier, 18, "Z"); shelfRow(47, 20, tier, 18, "Z")
        shelfRow(-47, -20, tier, 18, "Z"); shelfRow(-47, 20, tier, 18, "Z")
    end

    -- Work tables (4 around cauldron)
    local tablePos = {Vector3.new(-12,0,-4), Vector3.new(12,0,-4), Vector3.new(-10,0,-16), Vector3.new(10,0,-16)}
    for i, pos in ipairs(tablePos) do
        makePart(decor, { Name="Table_"..i, Size=Vector3.new(7, 0.4, 4),
            Position=pos+Vector3.new(0, 2.2, 0), Material=Enum.Material.WoodPlanks, Color=Color3.fromRGB(75,52,35) })
        for _, lx in ipairs({-2.8, 2.8}) do
            for _, lz in ipairs({-1.5, 1.5}) do
                makePart(decor, { Name="Leg", Size=Vector3.new(0.4, 2, 0.4),
                    Position=pos+Vector3.new(lx, 1, lz), Material=Enum.Material.Wood, Color=Color3.fromRGB(60,42,28) })
            end
        end
        makePart(decor, { Name="Book_"..i, Size=Vector3.new(1.8, 0.12, 1.3),
            Position=pos+Vector3.new(rng:NextNumber(-1.5,1.5), 2.46, rng:NextNumber(-0.5,0.5)),
            Material=Enum.Material.SmoothPlastic, Color=Color3.fromRGB(200,185,150),
            Orientation=Vector3.new(0, rng:NextNumber(-20,20), 0) })
        for b = 1, 4 do
            local color = potionColors[rng:NextInteger(1, #potionColors)]
            local h = rng:NextNumber(0.5, 1.0)
            makePart(decor, { Name="TableBottle", Shape=Enum.PartType.Cylinder, Size=Vector3.new(h, 0.35, 0.35),
                CFrame=CFrame.new(pos.X+rng:NextNumber(-2.5,2.5), 2.4+h/2+0.05, pos.Z+rng:NextNumber(-1.2,1.2))*CFrame.Angles(0,0,math.rad(90)),
                Material=Enum.Material.Glass, Color=color, Transparency=0.2 })
        end
    end

    -- Floor bottles around cauldron (25)
    for i = 1, 25 do
        local a = rng:NextNumber(0, math.pi*2)
        local d = rng:NextNumber(5, 12)
        local color = potionColors[rng:NextInteger(1, #potionColors)]
        local h = rng:NextNumber(0.5, 1.2)
        local bottle = makePart(decor, { Name="FloorBottle_"..i, Shape=Enum.PartType.Cylinder, Size=Vector3.new(h, 0.4, 0.4),
            CFrame=CFrame.new(math.cos(a)*d, h/2+0.1, -8+math.sin(a)*d)*CFrame.Angles(0,0,math.rad(90)),
            Material=Enum.Material.Glass, Color=color, Transparency=0.15 })
        if rng:NextNumber() < 0.4 then
            local gl = Instance.new("PointLight"); gl.Color=color; gl.Brightness=0.6; gl.Range=5; gl.Parent=bottle
        end
    end

    -- Candles everywhere (50)
    local candleSpots = {}
    for i = 1, 20 do
        local side = rng:NextInteger(1, 4)
        local x, z
        if side==1 then x=rng:NextNumber(-42,42); z=rng:NextNumber(-46,-40)
        elseif side==2 then x=rng:NextNumber(-42,42); z=rng:NextNumber(40,46)
        elseif side==3 then x=rng:NextNumber(-46,-40); z=rng:NextNumber(-42,42)
        else x=rng:NextNumber(40,46); z=rng:NextNumber(-42,42) end
        table.insert(candleSpots, Vector3.new(x, 0, z))
    end
    for i = 1, 18 do
        local a = rng:NextNumber(0, math.pi*2)
        local r = rng:NextNumber(6, 20)
        table.insert(candleSpots, Vector3.new(math.cos(a)*r, 0, -8+math.sin(a)*r))
    end
    for _, tp in ipairs(tablePos) do
        for c = 1, 3 do
            table.insert(candleSpots, tp+Vector3.new(rng:NextNumber(-2.5,2.5), 2.4, rng:NextNumber(-1.2,1.2)))
        end
    end
    for i, spot in ipairs(candleSpots) do
        local baseY = spot.Y < 1 and 0.1 or spot.Y
        local h = rng:NextNumber(0.5, 1.4)
        makePart(decor, { Name="Candle_"..i, Shape=Enum.PartType.Cylinder, Size=Vector3.new(h, 0.25, 0.25),
            CFrame=CFrame.new(spot.X, baseY+h/2, spot.Z)*CFrame.Angles(0,0,math.rad(90)),
            Material=Enum.Material.SmoothPlastic, Color=Color3.fromRGB(225,210,175) })
        local flame = makePart(decor, { Name="Flame_"..i, Shape=Enum.PartType.Ball, Size=Vector3.new(0.18, 0.28, 0.18),
            Position=Vector3.new(spot.X, baseY+h+0.14, spot.Z),
            Material=Enum.Material.Neon, Color=Color3.fromRGB(255,185,80) })
        local fl = Instance.new("PointLight"); fl.Color=Color3.fromRGB(255,180,70); fl.Brightness=0.8; fl.Range=10; fl.Parent=flame
    end

    -- Skulls at cauldron base (4)
    for i = 1, 4 do
        local a = (i/4)*math.pi*2+0.5
        makePart(decor, { Name="Skull_"..i, Shape=Enum.PartType.Ball, Size=Vector3.new(1.2, 1, 1.1),
            Position=Vector3.new(math.cos(a)*5, 1.2, -8+math.sin(a)*5),
            Material=Enum.Material.SmoothPlastic, Color=Color3.fromRGB(200,195,175) })
    end

    -- Glowing crystals (8 freestanding)
    local crystalColors = {Color3.fromRGB(150,80,255), Color3.fromRGB(80,150,255), Color3.fromRGB(180,60,220)}
    for i = 1, 8 do
        local a = (i/8)*math.pi*2
        local r = rng:NextNumber(16, 35)
        local h = rng:NextNumber(2, 4)
        local color = crystalColors[rng:NextInteger(1, #crystalColors)]
        local crystal = makePart(decor, { Name="Crystal_"..i, Size=Vector3.new(rng:NextNumber(0.6,1.2), h, rng:NextNumber(0.6,1.2)),
            Position=Vector3.new(math.cos(a)*r, h/2+0.1, -8+math.sin(a)*r),
            Material=Enum.Material.Neon, Color=color,
            Orientation=Vector3.new(rng:NextNumber(-15,15), rng:NextNumber(0,360), rng:NextNumber(-15,15)) })
        local cl = Instance.new("PointLight"); cl.Color=color; cl.Brightness=1.5; cl.Range=12; cl.Parent=crystal
    end

    -- Chandeliers (9 large)
    local chandelierData = {
        {pos=Vector3.new(-22, 14, -22), size=12}, {pos=Vector3.new(22, 14, -22), size=12},
        {pos=Vector3.new(-22, 14, 22), size=12}, {pos=Vector3.new(22, 14, 22), size=12},
        {pos=Vector3.new(0, 16, -8), size=18},
        {pos=Vector3.new(-35, 13, 0), size=10}, {pos=Vector3.new(35, 13, 0), size=10},
        {pos=Vector3.new(0, 13.5, -38), size=11}, {pos=Vector3.new(0, 13.5, 32), size=11},
    }
    for ci, cd in ipairs(chandelierData) do
        local pos = cd.pos
        local rs = cd.size
        local ch = Instance.new("Model"); ch.Name="Chandelier_"..ci; ch.Parent=decor
        makePart(ch, { Name="Chain", Size=Vector3.new(0.3, 4, 0.3), Position=pos+Vector3.new(0, 2, 0),
            Material=Enum.Material.Metal, Color=Color3.fromRGB(62,58,78) })
        local ring = makePart(ch, { Name="Ring", Shape=Enum.PartType.Cylinder, Size=Vector3.new(0.6, rs, rs),
            CFrame=CFrame.new(pos)*CFrame.Angles(0,0,math.rad(90)), Material=Enum.Material.Metal, Color=Color3.fromRGB(105,85,55) })
        makePart(ch, { Name="LowerRing", Shape=Enum.PartType.Cylinder, Size=Vector3.new(0.45, rs*0.7, rs*0.7),
            CFrame=CFrame.new(pos-Vector3.new(0,1.2,0))*CFrame.Angles(0,0,math.rad(90)), Material=Enum.Material.Metal, Color=Color3.fromRGB(88,72,50) })
        local outerN = (ci==5) and 12 or 8
        for c = 1, outerN do
            local a = (c/outerN)*math.pi*2
            local cr = rs*0.48
            local cx = pos.X+math.cos(a)*cr
            local cz = pos.Z+math.sin(a)*cr
            makePart(ch, { Name="Candle_"..c, Shape=Enum.PartType.Cylinder, Size=Vector3.new(1.2, 0.35, 0.35),
                CFrame=CFrame.new(cx, pos.Y+0.6, cz)*CFrame.Angles(0,0,math.rad(90)),
                Material=Enum.Material.SmoothPlastic, Color=Color3.fromRGB(230,215,180) })
            local fl = makePart(ch, { Name="Flame_"..c, Shape=Enum.PartType.Ball, Size=Vector3.new(0.35, 0.5, 0.35),
                Position=Vector3.new(cx, pos.Y+1.35, cz), Material=Enum.Material.Neon, Color=Color3.fromRGB(255,190,70) })
            local li = Instance.new("PointLight"); li.Color=Color3.fromRGB(255,180,80); li.Brightness=1.2; li.Range=18; li.Parent=fl
        end
        local gc = (ci==5) and Color3.fromRGB(150,110,255) or ((ci%2==0) and Color3.fromRGB(100,180,255) or Color3.fromRGB(170,130,255))
        local gs = (ci==5) and 1.8 or 1.1
        local gem = makePart(ch, { Name="CenterGem", Shape=Enum.PartType.Ball, Size=Vector3.new(gs, gs*1.4, gs),
            Position=pos-Vector3.new(0, 2, 0), Material=Enum.Material.Neon, Color=gc, Transparency=0.08 })
        local gl = Instance.new("PointLight"); gl.Color=gc; gl.Brightness=(ci==5) and 3 or 1.6; gl.Range=(ci==5) and 35 or 20; gl.Parent=gem
        ch.PrimaryPart = ring
    end

    -- Ambient purple mist
    local mistAnchor = makePart(decor, { Name="FloorMist", Size=Vector3.new(2,2,2), Position=Vector3.new(0, 1, -8), Transparency=1 })
    local mist = Instance.new("ParticleEmitter")
    mist.Rate=55; mist.Lifetime=NumberRange.new(5,9); mist.Speed=NumberRange.new(0.1,0.6); mist.SpreadAngle=Vector2.new(180,180)
    mist.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,0.3), NumberSequenceKeypoint.new(0.6,1.5), NumberSequenceKeypoint.new(1,0)})
    mist.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0.5), NumberSequenceKeypoint.new(0.7,0.7), NumberSequenceKeypoint.new(1,1)})
    mist.Color=ColorSequence.new(Color3.fromRGB(90,60,150), Color3.fromRGB(60,40,120))
    mist.LightEmission=0.4; mist.Parent=mistAnchor

    print("[WildGroveDecorationService] Wizard shop decor generated")
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

    tuneYourShopFloor()
    createWizardShopDecor()
    tuneCauldron()
    print("[WildGroveDecorationService] Mystical decor generated")
end

task.defer(buildMysticalGrove)
