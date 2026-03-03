-- PotionDisplayController: Renders brewed potions as visual vials on shop shelves
local RS = game:GetService("ReplicatedStorage")
local Remotes = RS.Remotes
local Potions = require(RS.Shared.Config.Potions)
local PDT = require(RS.Shared.Config.PotionDisplayTuning)
local Ingredients = require(RS.Shared.Config.Ingredients)

local player = game.Players.LocalPlayer
local displayedParts = {}

-- Display positions: 6 glass dome pedestals in semicircle around cauldron
-- Each pedestal holds up to 5 potions stacked vertically (30 total)
-- Pedestals are at radius 15 from cauldron center (0, -8)
local shelfPositions = {}
local centerX, centerZ = 0, -8
local radius = 15
local startAngle, endAngle = 200, 340
for i = 1, 6 do
    local angle = math.rad(startAngle + (i - 1) * ((endAngle - startAngle) / 5))
    local x = centerX + math.cos(angle) * radius
    local z = centerZ + math.sin(angle) * radius
    table.insert(shelfPositions, {
        origin = Vector3.new(x, 2.0, z), dir = Vector3.new(0, 0.5, 0), count = 5
    })
end

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
        local shelfIdx = math.ceil(idx / 6)
        if shelfIdx > #shelfPositions then break end
        local shelf = shelfPositions[shelfIdx]
        local slotIdx = ((idx - 1) % 6)
        local spacing = 3.2
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

        -- Add particles — steam/sparkle effect, scaled by tier
        local effectRate = visual.particleRate or 0
        if mutation and PDT.MutationModifiers[mutation] and PDT.MutationModifiers[mutation].particleRate then
            effectRate = math.max(effectRate, PDT.MutationModifiers[mutation].particleRate)
        end
        if effectRate > 0 then
            -- Steam/mist rising from bottle
            local steam = Instance.new("ParticleEmitter")
            steam.Color = ColorSequence.new(color)
            steam.Size = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0.05),
                NumberSequenceKeypoint.new(0.3, 0.15),
                NumberSequenceKeypoint.new(1, 0)
            })
            steam.Lifetime = NumberRange.new(0.8, 2)
            steam.Rate = effectRate
            steam.Speed = NumberRange.new(0.3, 1.2)
            steam.SpreadAngle = Vector2.new(30, 30)
            steam.LightEmission = 1
            steam.Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0.3),
                NumberSequenceKeypoint.new(0.5, 0.6),
                NumberSequenceKeypoint.new(1, 1)
            })
            steam.Parent = vial

            -- Sparkle burst for Mythic+ and special mutations
            if tier == "Mythic" or tier == "Divine" or (mutation and (mutation == "Rainbow" or mutation == "Golden")) then
                local sparkle = Instance.new("ParticleEmitter")
                sparkle.Color = ColorSequence.new(Color3.fromRGB(255, 255, 220))
                sparkle.Size = NumberSequence.new({
                    NumberSequenceKeypoint.new(0, 0.08),
                    NumberSequenceKeypoint.new(0.5, 0.02),
                    NumberSequenceKeypoint.new(1, 0)
                })
                sparkle.Lifetime = NumberRange.new(0.3, 0.8)
                sparkle.Rate = effectRate * 0.5
                sparkle.Speed = NumberRange.new(1, 3)
                sparkle.SpreadAngle = Vector2.new(180, 180)
                sparkle.LightEmission = 1
                sparkle.Transparency = NumberSequence.new({
                    NumberSequenceKeypoint.new(0, 0),
                    NumberSequenceKeypoint.new(1, 1)
                })
                sparkle.Parent = vial
            end
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
