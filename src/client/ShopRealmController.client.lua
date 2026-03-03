local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local Remotes = RS:WaitForChild("Remotes")
local Potions = require(RS.Shared.Config.Potions)

local MAX_VISIBLE_STARS = 160
local SHOWCASE_COUNT = 12

local tierColors = {
    Common = Color3.fromRGB(130, 180, 120),
    Uncommon = Color3.fromRGB(80, 170, 220),
    Rare = Color3.fromRGB(255, 200, 90),
    Mythic = Color3.fromRGB(195, 110, 255),
    Divine = Color3.fromRGB(255, 250, 210),
}

local tierScale = {
    Common = 0.22,
    Uncommon = 0.28,
    Rare = 0.36,
    Mythic = 0.48,
    Divine = 0.62,
}

local lastTotalBrewed = 0
local prevPotionCounts = {}
local entryRevealPlayed = false

local realmFolder
local coreFolder
local constellationFolder
local showcaseFolder
local shopCenter = Vector3.new()
local shopFloorY = 0
local corePulsePart

local function getShop()
    local zones = workspace:FindFirstChild("Zones")
    if not zones then
        return nil
    end
    return zones:FindFirstChild("YourShop")
end

local function ensureRealm()
    local shop = getShop()
    if not shop then
        return nil
    end

    local floor = shop:FindFirstChild("Floor")
    if floor and floor:IsA("BasePart") then
        shopFloorY = floor.Position.Y + floor.Size.Y * 0.5
    else
        shopFloorY = shop:GetPivot().Position.Y
    end
    shopCenter = Vector3.new(shop:GetPivot().Position.X, shopFloorY, shop:GetPivot().Position.Z)

    if realmFolder and realmFolder.Parent then
        return shop
    end

    realmFolder = Instance.new("Folder")
    realmFolder.Name = "ClientMagicRealm_" .. tostring(player.UserId)
    realmFolder.Parent = shop

    coreFolder = Instance.new("Folder")
    coreFolder.Name = "SkybreakCore"
    coreFolder.Parent = realmFolder

    constellationFolder = Instance.new("Folder")
    constellationFolder.Name = "PotionConstellation"
    constellationFolder.Parent = realmFolder

    showcaseFolder = Instance.new("Folder")
    showcaseFolder.Name = "HallOfEchoes"
    showcaseFolder.Parent = realmFolder

    return shop
end

local function makePart(parent, props)
    local p = Instance.new("Part")
    p.Anchored = true
    p.CanCollide = false
    p.CastShadow = false
    p.TopSurface = Enum.SurfaceType.Smooth
    p.BottomSurface = Enum.SurfaceType.Smooth
    for k, v in pairs(props) do
        p[k] = v
    end
    p.Parent = parent
    return p
end

local function clearFolder(folder)
    if not folder then
        return
    end
    for _, child in ipairs(folder:GetChildren()) do
        child:Destroy()
    end
end

local function parsePotionKey(potionKey)
    local baseId = potionKey
    local sep = potionKey:find("__")
    if sep then
        baseId = potionKey:sub(1, sep - 1)
    end
    return baseId
end

local function getPotionTier(potionKey)
    local baseId = parsePotionKey(potionKey)
    local potion = Potions.Data[baseId]
    return potion and potion.tier or "Common"
end

local function getCauldronCenter(shop)
    if not shop then
        return shopCenter + Vector3.new(0, 2, -6)
    end
    local cauldron = shop:FindFirstChild("Cauldron")
    if not cauldron then
        return shopCenter + Vector3.new(0, 2, -6)
    end
    if cauldron:IsA("BasePart") then
        return cauldron.Position + Vector3.new(0, cauldron.Size.Y * 0.5, 0)
    end
    if cauldron:IsA("Model") then
        return cauldron:GetPivot().Position + Vector3.new(0, 2, 0)
    end
    return shopCenter + Vector3.new(0, 2, -6)
end

local function buildSkybreakCore()
    local shop = ensureRealm()
    if not shop then
        return
    end

    clearFolder(coreFolder)

    local c = getCauldronCenter(shop)

    for i = 1, 3 do
        local r = 4 + (i * 1.7)
        local ring = makePart(coreFolder, {
            Name = "CoreRing_" .. i,
            Shape = Enum.PartType.Cylinder,
            Size = Vector3.new(0.2, r * 2, r * 2),
            CFrame = CFrame.new(c + Vector3.new(0, 0.25 + i * 0.4, 0)) * CFrame.Angles(0, 0, math.rad(90)),
            Material = Enum.Material.Neon,
            Color = i == 3 and Color3.fromRGB(145, 120, 255) or Color3.fromRGB(90, 140, 255),
            Transparency = 0.45 + (i * 0.12),
        })
        local light = Instance.new("PointLight")
        light.Color = ring.Color
        light.Brightness = 0.6
        light.Range = 10 + i * 3
        light.Parent = ring
    end

    corePulsePart = makePart(coreFolder, {
        Name = "CorePulse",
        Shape = Enum.PartType.Ball,
        Size = Vector3.new(1.4, 1.4, 1.4),
        Position = c + Vector3.new(0, 2.6, 0),
        Material = Enum.Material.Neon,
        Color = Color3.fromRGB(120, 175, 255),
        Transparency = 0.15,
    })
    local coreLight = Instance.new("PointLight")
    coreLight.Color = Color3.fromRGB(120, 175, 255)
    coreLight.Brightness = 2.3
    coreLight.Range = 16
    coreLight.Parent = corePulsePart

    local riftBeam = makePart(coreFolder, {
        Name = "SkyRiftBeam",
        Shape = Enum.PartType.Cylinder,
        Size = Vector3.new(0.6, 26, 26),
        CFrame = CFrame.new(c + Vector3.new(0, 14, 0)) * CFrame.Angles(0, 0, math.rad(90)),
        Material = Enum.Material.Neon,
        Color = Color3.fromRGB(110, 145, 255),
        Transparency = 0.82,
    })
    local riftLight = Instance.new("PointLight")
    riftLight.Color = Color3.fromRGB(110, 145, 255)
    riftLight.Brightness = 1.1
    riftLight.Range = 26
    riftLight.Parent = riftBeam

    local apex = makePart(coreFolder, {
        Name = "SkyRiftApex",
        Shape = Enum.PartType.Ball,
        Size = Vector3.new(3.6, 3.6, 3.6),
        Position = c + Vector3.new(0, 27.5, 0),
        Material = Enum.Material.Neon,
        Color = Color3.fromRGB(165, 132, 255),
        Transparency = 0.45,
    })
    local apexLight = Instance.new("PointLight")
    apexLight.Color = Color3.fromRGB(165, 132, 255)
    apexLight.Brightness = 1.8
    apexLight.Range = 35
    apexLight.Parent = apex

    for i = 1, 14 do
        local a = (i / 14) * math.pi * 2
        local shard = makePart(coreFolder, {
            Name = "FloatingShard_" .. i,
            Size = Vector3.new(0.35, 1.4, 0.35),
            CFrame = CFrame.new(c + Vector3.new(math.cos(a) * 5.8, 3.5 + (i % 3) * 0.7, math.sin(a) * 5.8))
                * CFrame.Angles(math.rad(20), a, math.rad(10)),
            Material = Enum.Material.Glass,
            Color = Color3.fromRGB(165, 185, 255),
            Transparency = 0.28,
        })
        local sl = Instance.new("PointLight")
        sl.Color = Color3.fromRGB(120, 165, 255)
        sl.Brightness = 0.45
        sl.Range = 5
        sl.Parent = shard
    end

    local mistAnchor = makePart(coreFolder, {
        Name = "CoreMistAnchor",
        Size = Vector3.new(2, 2, 2),
        Position = c + Vector3.new(0, 2.2, 0),
        Transparency = 1,
    })
    local mist = Instance.new("ParticleEmitter")
    mist.Name = "CoreMist"
    mist.Rate = 45
    mist.Lifetime = NumberRange.new(2.4, 4.2)
    mist.Speed = NumberRange.new(0.4, 1.3)
    mist.SpreadAngle = Vector2.new(180, 180)
    mist.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.15),
        NumberSequenceKeypoint.new(0.6, 0.6),
        NumberSequenceKeypoint.new(1, 0),
    })
    mist.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.45),
        NumberSequenceKeypoint.new(0.7, 0.6),
        NumberSequenceKeypoint.new(1, 1),
    })
    mist.Color = ColorSequence.new(Color3.fromRGB(110, 165, 255), Color3.fromRGB(170, 120, 255))
    mist.LightEmission = 1
    mist.Parent = mistAnchor
end

local function starPosition(index, center)
    local golden = math.pi * (3 - math.sqrt(5))
    local angle = index * golden
    local radius = math.min(22, 1.2 + math.sqrt(index) * 0.95)
    local x = center.X + math.cos(angle) * radius
    local z = center.Z + math.sin(angle) * radius
    local y = center.Y + 20 + ((index % 9) * 0.32)
    return Vector3.new(x, y, z)
end

local function createConstellationStar(index, tier, animateFrom)
    if not constellationFolder then
        return
    end
    local c = shopCenter + Vector3.new(0, 0, -6)
    local pos = starPosition(index, c)
    local size = tierScale[tier] or tierScale.Common
    local color = tierColors[tier] or tierColors.Common

    local startPos = animateFrom or pos
    local star = makePart(constellationFolder, {
        Name = "Star_" .. index,
        Shape = Enum.PartType.Ball,
        Size = Vector3.new(size, size, size),
        Position = startPos,
        Material = Enum.Material.Neon,
        Color = color,
        Transparency = animateFrom and 0.55 or 0.2,
    })

    local light = Instance.new("PointLight")
    light.Color = color
    light.Brightness = tier == "Divine" and 1.6 or 0.9
    light.Range = tier == "Divine" and 11 or 6
    light.Parent = star

    if tier == "Mythic" or tier == "Divine" then
        local sparkle = Instance.new("ParticleEmitter")
        sparkle.Rate = tier == "Divine" and 8 or 4
        sparkle.Lifetime = NumberRange.new(0.4, 1.1)
        sparkle.Speed = NumberRange.new(0.2, 0.9)
        sparkle.Size = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.05),
            NumberSequenceKeypoint.new(1, 0),
        })
        sparkle.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.2),
            NumberSequenceKeypoint.new(1, 1),
        })
        sparkle.Color = ColorSequence.new(color)
        sparkle.LightEmission = 1
        sparkle.Parent = star
    end

    if animateFrom then
        local t = TweenService:Create(star, TweenInfo.new(0.8, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
            Position = pos,
            Transparency = 0.2,
        })
        t:Play()
    end
end

local function rebuildConstellationBaseline(data)
    if not ensureRealm() then
        return
    end
    clearFolder(constellationFolder)

    local total = data and data.BrewStats and data.BrewStats.TotalBrewed or 0
    local potionCounts = data and data.BrewStats and data.BrewStats.PotionCounts or {}

    local weighted = {}
    for potionKey, count in pairs(potionCounts) do
        local tier = getPotionTier(potionKey)
        for _ = 1, math.clamp(count, 1, 20) do
            table.insert(weighted, tier)
        end
    end
    if #weighted == 0 then
        for _ = 1, 8 do
            table.insert(weighted, "Common")
        end
    end

    local starCount = math.clamp(total, 12, MAX_VISIBLE_STARS)
    for i = 1, starCount do
        local tier = weighted[((i - 1) % #weighted) + 1]
        createConstellationStar(i, tier, nil)
    end
end

local function rebuildHallOfEchoes(data)
    if not ensureRealm() then
        return
    end
    clearFolder(showcaseFolder)

    local counts = data and data.BrewStats and data.BrewStats.PotionCounts or {}
    local ranked = {}
    for potionKey, count in pairs(counts) do
        table.insert(ranked, { key = potionKey, count = count })
    end
    table.sort(ranked, function(a, b) return a.count > b.count end)

    local displayCount = math.min(SHOWCASE_COUNT, #ranked)
    if displayCount <= 0 then
        return
    end

    local center = shopCenter + Vector3.new(0, 0, -6)
    local radius = 12
    local startAngle = math.rad(206)
    local endAngle = math.rad(334)

    for i = 1, displayCount do
        local alpha = displayCount == 1 and 0.5 or ((i - 1) / (displayCount - 1))
        local a = startAngle + (endAngle - startAngle) * alpha
        local x = center.X + math.cos(a) * radius
        local z = center.Z + math.sin(a) * radius
        local y = shopFloorY + 1.4

        local entry = ranked[i]
        local baseId = parsePotionKey(entry.key)
        local tier = getPotionTier(entry.key)
        local color = tierColors[tier] or tierColors.Common
        local potionName = (Potions.Data[baseId] and Potions.Data[baseId].name) or baseId

        local pedestal = makePart(showcaseFolder, {
            Name = "EchoPedestal_" .. i,
            Shape = Enum.PartType.Cylinder,
            Size = Vector3.new(2.4, 3, 3),
            CFrame = CFrame.new(x, y, z) * CFrame.Angles(0, 0, math.rad(90)),
            Color = Color3.fromRGB(50, 46, 72),
            Material = Enum.Material.Slate,
        })
        local rim = makePart(showcaseFolder, {
            Name = "EchoRim_" .. i,
            Shape = Enum.PartType.Cylinder,
            Size = Vector3.new(0.4, 3.4, 3.4),
            CFrame = CFrame.new(x, y + 1.4, z) * CFrame.Angles(0, 0, math.rad(90)),
            Color = Color3.fromRGB(130, 125, 170),
            Material = Enum.Material.Metal,
        })
        local core = makePart(showcaseFolder, {
            Name = "EchoPotion_" .. i,
            Shape = Enum.PartType.Ball,
            Size = Vector3.new(0.95, 0.95, 0.95),
            Position = Vector3.new(x, y + 2.35, z),
            Color = color,
            Material = Enum.Material.Neon,
            Transparency = 0.08,
        })
        local glow = Instance.new("PointLight")
        glow.Color = color
        glow.Brightness = 1.3
        glow.Range = 10
        glow.Parent = core

        local bb = Instance.new("BillboardGui")
        bb.Size = UDim2.new(0, 180, 0, 44)
        bb.StudsOffset = Vector3.new(0, 1.6, 0)
        bb.AlwaysOnTop = true
        bb.Parent = core
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, 0, 1, 0)
        label.BackgroundTransparency = 1
        label.Text = potionName .. " x" .. tostring(entry.count)
        label.TextColor3 = Color3.fromRGB(230, 230, 255)
        label.TextStrokeTransparency = 0.5
        label.TextScaled = true
        label.Font = Enum.Font.GothamBold
        label.Parent = bb

        local halo = Instance.new("ParticleEmitter")
        halo.Rate = tier == "Divine" and 9 or (tier == "Mythic" and 6 or 3)
        halo.Lifetime = NumberRange.new(0.7, 1.8)
        halo.Speed = NumberRange.new(0.15, 0.75)
        halo.Size = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.06),
            NumberSequenceKeypoint.new(1, 0),
        })
        halo.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.25),
            NumberSequenceKeypoint.new(1, 1),
        })
        halo.Color = ColorSequence.new(color)
        halo.LightEmission = 1
        halo.Parent = core

        rim.Orientation = Vector3.new(0, math.deg(a) + 90, 0)
        pedestal.Orientation = Vector3.new(0, math.deg(a) + 90, 0)
    end
end

local function pulseCore(strength)
    if not corePulsePart or not corePulsePart.Parent then
        return
    end
    local s = math.clamp(strength, 0.8, 3.2)
    local baseSize = Vector3.new(1.4, 1.4, 1.4)
    corePulsePart.Size = baseSize
    corePulsePart.Transparency = 0.12
    TweenService:Create(corePulsePart, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size = baseSize * (1 + s * 0.9),
        Transparency = 0.7,
    }):Play()
    task.delay(0.4, function()
        if corePulsePart and corePulsePart.Parent then
            corePulsePart.Size = baseSize
            corePulsePart.Transparency = 0.12
        end
    end)
end

local function playEntryReveal()
    if entryRevealPlayed or not realmFolder then
        return
    end
    entryRevealPlayed = true

    local revealParts = {}
    for _, d in ipairs(realmFolder:GetDescendants()) do
        if d:IsA("BasePart") then
            table.insert(revealParts, d)
        end
    end

    for _, p in ipairs(revealParts) do
        local final = p.Transparency
        p.Transparency = 1
        TweenService:Create(p, TweenInfo.new(0.75, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Transparency = final,
        }):Play()
    end
end

local function updateFromData(data)
    if not data or not data.BrewStats then
        return
    end
    if not ensureRealm() then
        return
    end

    local total = data.BrewStats.TotalBrewed or 0
    local potionCounts = data.BrewStats.PotionCounts or {}

    if lastTotalBrewed == 0 then
        buildSkybreakCore()
        rebuildConstellationBaseline(data)
        rebuildHallOfEchoes(data)
        lastTotalBrewed = total
        prevPotionCounts = {}
        for k, v in pairs(potionCounts) do
            prevPotionCounts[k] = v
        end
        return
    end

    local grew = total > lastTotalBrewed
    if grew then
        local added = total - lastTotalBrewed
        local nextIndex = math.min(lastTotalBrewed, MAX_VISIBLE_STARS)
        local shop = getShop()
        local cauldronPos = getCauldronCenter(shop)
        local spawned = 0

        for potionKey, newCount in pairs(potionCounts) do
            local oldCount = prevPotionCounts[potionKey] or 0
            local delta = newCount - oldCount
            if delta > 0 then
                local tier = getPotionTier(potionKey)
                for _ = 1, delta do
                    if nextIndex >= MAX_VISIBLE_STARS then
                        break
                    end
                    nextIndex = nextIndex + 1
                    createConstellationStar(nextIndex, tier, cauldronPos + Vector3.new(0, 2.5, 0))
                    spawned = spawned + 1
                end
            end
        end

        if spawned < added then
            for _ = spawned + 1, added do
                if nextIndex >= MAX_VISIBLE_STARS then
                    break
                end
                nextIndex = nextIndex + 1
                createConstellationStar(nextIndex, "Common", cauldronPos + Vector3.new(0, 2.5, 0))
            end
        end

        pulseCore(1 + (added * 0.3))
        rebuildHallOfEchoes(data)
    end

    lastTotalBrewed = total
    prevPotionCounts = {}
    for k, v in pairs(potionCounts) do
        prevPotionCounts[k] = v
    end
end

local function isInYourShop()
    local char = player.Character
    if not char then
        return false
    end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then
        return false
    end
    local shop = getShop()
    if not shop then
        return false
    end
    local floor = shop:FindFirstChild("Floor")
    if floor and floor:IsA("BasePart") then
        local d = (Vector3.new(hrp.Position.X, 0, hrp.Position.Z) - Vector3.new(floor.Position.X, 0, floor.Position.Z)).Magnitude
        return d < math.max(floor.Size.X, floor.Size.Z) * 0.65
    end
    return (hrp.Position - shop:GetPivot().Position).Magnitude < 80
end

Remotes.PlayerDataUpdate.OnClientEvent:Connect(function(data)
    updateFromData(data)
end)

task.spawn(function()
    task.wait(4)
    local ok, data = pcall(function()
        return Remotes.GetPlayerData:InvokeServer()
    end)
    if ok and data then
        updateFromData(data)
    end
end)

task.spawn(function()
    while true do
        if coreFolder and coreFolder.Parent then
            local t = tick()
            for _, p in ipairs(coreFolder:GetChildren()) do
                if p:IsA("BasePart") and p.Name:match("^FloatingShard_") then
                    local n = tonumber(p.Name:match("_(%d+)")) or 1
                    local angle = (t * 0.35) + n
                    local base = getCauldronCenter(getShop())
                    p.Position = base + Vector3.new(math.cos(angle) * 5.8, 3.2 + math.sin((t * 1.2) + n) * 0.4 + (n % 3) * 0.5, math.sin(angle) * 5.8)
                    p.Orientation = Vector3.new(20 + math.sin(t + n) * 12, math.deg(angle), 10 + math.cos(t + n) * 10)
                end
            end
        end
        task.wait(0.03)
    end
end)

task.spawn(function()
    while true do
        if isInYourShop() then
            playEntryReveal()
        else
            entryRevealPlayed = false
        end
        task.wait(0.75)
    end
end)

print("[ShopRealmController] Initialized")
