-- PotionDisplayController: Renders brewed potions as visual vials on shop shelves
local RS = game:GetService("ReplicatedStorage")
local Remotes = RS.Remotes
local Potions = require(RS.Shared.Config.Potions)
local PDT = require(RS.Shared.Config.PotionDisplayTuning)
local Ingredients = require(RS.Shared.Config.Ingredients)

local player = game.Players.LocalPlayer
local displayedParts = {}

-- Shelf positions: {position, direction (along shelf)}
local shelfPositions = {
    -- Left wall lower
    {origin = Vector3.new(-35, 3.5, -24), dir = Vector3.new(0, 0, 1), count = 5},
    -- Left wall upper
    {origin = Vector3.new(-35, 6, -24), dir = Vector3.new(0, 0, 1), count = 5},
    -- Right wall lower
    {origin = Vector3.new(35, 3.5, -24), dir = Vector3.new(0, 0, 1), count = 5},
    -- Right wall upper
    {origin = Vector3.new(35, 6, -24), dir = Vector3.new(0, 0, 1), count = 5},
    -- Back wall lower
    {origin = Vector3.new(-12, 3.5, -38), dir = Vector3.new(1, 0, 0), count = 5},
    -- Back wall upper
    {origin = Vector3.new(-12, 6, -38), dir = Vector3.new(1, 0, 0), count = 5},
}

local function clearDisplays()
    for _, part in ipairs(displayedParts) do
        if part and part.Parent then part:Destroy() end
    end
    displayedParts = {}
end

local function getElementColor(potionId)
    local baseId = potionId
    local sep = potionId:find("__")
    if sep then baseId = potionId:sub(1, sep - 1) end
    local potion = Potions.Data[baseId]
    if not potion then return Color3.fromRGB(150, 150, 150) end
    -- Try to determine color from potion tier
    local tierColors = {
        Common = Color3.fromRGB(120, 180, 100),
        Uncommon = Color3.fromRGB(80, 160, 220),
        Rare = Color3.fromRGB(255, 180, 50),
        Mythic = Color3.fromRGB(200, 80, 255),
        Divine = Color3.fromRGB(255, 255, 200),
    }
    return tierColors[potion.tier] or Color3.fromRGB(150, 150, 150)
end

local function renderDisplays(potionDisplays)
    clearDisplays()
    if not potionDisplays then return end

    local shop = workspace:FindFirstChild("Zones") and workspace.Zones:FindFirstChild("YourShop")
    if not shop then return end

    for idx, display in ipairs(potionDisplays) do
        if idx > PDT.MaxDisplays then break end

        -- Determine shelf position
        local shelfIdx = math.ceil(idx / 5)
        if shelfIdx > #shelfPositions then break end
        local shelf = shelfPositions[shelfIdx]
        local slotIdx = ((idx - 1) % 5)
        local spacing = 5
        local pos = shelf.origin + shelf.dir * (slotIdx * spacing)

        -- Get potion info
        local baseId = display.potionId
        local mutation = display.mutation
        local sep = baseId:find("__")
        if sep then
            mutation = baseId:sub(sep + 2)
            baseId = baseId:sub(1, sep - 1)
        end
        local potion = Potions.Data[baseId]
        local tier = potion and potion.tier or "Common"
        local visual = PDT.TierVisuals[tier] or PDT.TierVisuals.Common

        -- Create vial
        local vial = Instance.new("Part")
        vial.Name = "PotionDisplay_" .. idx
        vial.Shape = visual.shape == "Ball" and Enum.PartType.Ball or Enum.PartType.Cylinder
        vial.Size = visual.size
        if visual.shape == "Cylinder" then
            vial.CFrame = CFrame.new(pos) * CFrame.Angles(0, 0, math.rad(90))
        else
            vial.Position = pos + (visual.floats and Vector3.new(0, 0.5, 0) or Vector3.new(0, 0, 0))
        end
        vial.Anchored = true
        vial.CanCollide = false
        vial.Material = Enum.Material[visual.material] or Enum.Material.Glass
        vial.Transparency = visual.transparency or 0

        -- Color
        local color = getElementColor(display.potionId)
        if mutation and PDT.MutationModifiers[mutation] then
            local mod = PDT.MutationModifiers[mutation]
            if mod.color then color = mod.color end
            if mod.material then vial.Material = Enum.Material[mod.material] or vial.Material end
        end
        vial.Color = color
        vial.Parent = shop
        table.insert(displayedParts, vial)

        -- Add light for Uncommon+
        if visual.lightBrightness and visual.lightBrightness > 0 then
            local light = Instance.new("PointLight")
            light.Color = color
            light.Brightness = visual.lightBrightness
            light.Range = visual.lightRange or 4
            light.Parent = vial
        end

        -- Add particles for Rare+
        if visual.particleRate and visual.particleRate > 0 then
            local pe = Instance.new("ParticleEmitter")
            pe.Color = ColorSequence.new(color)
            pe.Size = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0),
                NumberSequenceKeypoint.new(0.5, 0.1),
                NumberSequenceKeypoint.new(1, 0)
            })
            pe.Lifetime = NumberRange.new(0.5, 1.5)
            pe.Rate = visual.particleRate
            pe.Speed = NumberRange.new(0.3, 1)
            pe.SpreadAngle = Vector2.new(180, 180)
            pe.LightEmission = 1
            pe.Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0.5),
                NumberSequenceKeypoint.new(1, 1)
            })
            pe.Parent = vial
        end

        -- Floating animation for Divine
        if visual.floats then
            task.spawn(function()
                local baseY = pos.Y + 0.5
                while vial and vial.Parent do
                    vial.Position = Vector3.new(pos.X, baseY + math.sin(tick() * 2) * 0.3, pos.Z)
                    task.wait()
                end
            end)
        end

        -- Add name label
        local bb = Instance.new("BillboardGui")
        bb.Size = UDim2.new(0, 80, 0, 20)
        bb.StudsOffset = Vector3.new(0, 1, 0)
        bb.AlwaysOnTop = false
        bb.Parent = vial
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, 0, 1, 0)
        label.BackgroundTransparency = 1
        label.Text = potion and potion.name or baseId
        label.TextColor3 = color
        label.TextScaled = true
        label.Font = Enum.Font.Gotham
        label.TextStrokeTransparency = 0.5
        label.Parent = bb
    end
end

-- Listen for data updates
Remotes.PlayerDataUpdate.OnClientEvent:Connect(function(data)
    if data and data.PotionDisplays then
        renderDisplays(data.PotionDisplays)
    end
end)

-- Initial load
task.spawn(function()
    task.wait(5)
    local data = Remotes.GetPlayerData:InvokeServer()
    if data and data.PotionDisplays then
        renderDisplays(data.PotionDisplays)
    end
end)

print("[PotionDisplayController] Initialized")
