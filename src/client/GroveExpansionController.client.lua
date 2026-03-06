-- GroveExpansionController: Sub-zone unlock visuals + Forage Power HUD badge
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local Remotes = RS:WaitForChild("Remotes")
local ForageTuning = require(RS.Shared.Config.ForageTuning)

local currentStars = 0
local previousUnlocks = {} -- track which zones were already unlocked
local forageBadge = nil
local isInGrove = false

-- ========== FORAGE POWER HUD BADGE ==========
local function createForageBadge()
    local sg = Instance.new("ScreenGui")
    sg.Name = "ForagePowerGui"
    sg.DisplayOrder = 8
    sg.ResetOnSpawn = false
    sg.Parent = playerGui

    local frame = Instance.new("Frame")
    frame.Name = "ForageBadge"
    frame.Size = UDim2.new(0, 200, 0, 50)
    frame.Position = UDim2.new(0, 10, 1, -60)
    frame.BackgroundColor3 = Color3.fromRGB(25, 40, 30)
    frame.BackgroundTransparency = 0.15
    frame.Visible = false
    frame.Parent = sg
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(80, 200, 120)
    stroke.Thickness = 2
    stroke.Parent = frame

    local starIcon = Instance.new("TextLabel")
    starIcon.Name = "StarIcon"
    starIcon.Size = UDim2.new(0, 30, 0, 30)
    starIcon.Position = UDim2.new(0, 8, 0, 10)
    starIcon.BackgroundTransparency = 1
    starIcon.Text = "*"
    starIcon.TextColor3 = Color3.fromRGB(255, 215, 100)
    starIcon.TextScaled = true
    starIcon.Font = Enum.Font.GothamBlack
    starIcon.Parent = frame

    local tierLabel = Instance.new("TextLabel")
    tierLabel.Name = "TierLabel"
    tierLabel.Size = UDim2.new(1, -45, 0, 22)
    tierLabel.Position = UDim2.new(0, 42, 0, 3)
    tierLabel.BackgroundTransparency = 1
    tierLabel.Text = "Apprentice Forager"
    tierLabel.TextColor3 = Color3.fromRGB(100, 255, 150)
    tierLabel.TextScaled = true
    tierLabel.Font = Enum.Font.GothamBold
    tierLabel.TextXAlignment = Enum.TextXAlignment.Left
    tierLabel.Parent = frame

    local bonusLabel = Instance.new("TextLabel")
    bonusLabel.Name = "BonusLabel"
    bonusLabel.Size = UDim2.new(1, -45, 0, 18)
    bonusLabel.Position = UDim2.new(0, 42, 0, 26)
    bonusLabel.BackgroundTransparency = 1
    bonusLabel.Text = "Common drops"
    bonusLabel.TextColor3 = Color3.fromRGB(180, 200, 180)
    bonusLabel.TextScaled = true
    bonusLabel.Font = Enum.Font.Gotham
    bonusLabel.TextXAlignment = Enum.TextXAlignment.Left
    bonusLabel.Parent = frame

    forageBadge = frame
    return frame
end

local function updateForageBadge(stars)
    if not forageBadge then return end
    local tierName, bonusText = ForageTuning.getBonusDisplay(stars)
    forageBadge.TierLabel.Text = tierName
    forageBadge.BonusLabel.Text = bonusText
end

local function showForageBadge()
    if not forageBadge then return end
    if forageBadge.Visible then return end
    forageBadge.Visible = true
    forageBadge.BackgroundTransparency = 1
    TweenService:Create(forageBadge, TweenInfo.new(0.5, Enum.EasingStyle.Quad), {
        BackgroundTransparency = 0.15,
    }):Play()
end

local function hideForageBadge()
    if not forageBadge then return end
    if not forageBadge.Visible then return end
    local tween = TweenService:Create(forageBadge, TweenInfo.new(0.5, Enum.EasingStyle.Quad), {
        BackgroundTransparency = 1,
    })
    tween:Play()
    tween.Completed:Connect(function()
        if forageBadge then forageBadge.Visible = false end
    end)
end

-- ========== SUB-ZONE BARRIER MANAGEMENT ==========

local function findBarrier(zoneName)
    local grove = workspace:FindFirstChild("Zones") and workspace.Zones:FindFirstChild("WildGrove")
    if not grove then return nil end
    return grove:FindFirstChild(zoneName .. "_Barrier")
end

local function findSubZoneNodes(nodeIds)
    local grove = workspace:FindFirstChild("Zones") and workspace.Zones:FindFirstChild("WildGrove")
    if not grove then return {} end
    local nodes = {}
    for _, nid in ipairs(nodeIds) do
        local node = grove:FindFirstChild(nid)
        if node then table.insert(nodes, node) end
    end
    return nodes
end

local function setBarrierLocked(zoneName, threshold)
    local barrier = findBarrier(zoneName)
    if not barrier then return end
    barrier.Transparency = 0.5
    barrier.CanCollide = true
    -- Update or create lock label
    local bb = barrier:FindFirstChild("LockGui")
    if bb then
        local label = bb:FindFirstChild("LockLabel")
        if label then label.Text = threshold .. " Stars Required" end
    end
end

local function dissolveBarrier(zoneName, animated)
    local barrier = findBarrier(zoneName)
    if not barrier then return end
    if animated then
        -- Play unlock particle burst
        local burst = Instance.new("ParticleEmitter")
        burst.Color = ColorSequence.new(Color3.fromRGB(100, 255, 180))
        burst.Size = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.3),
            NumberSequenceKeypoint.new(0.5, 0.8),
            NumberSequenceKeypoint.new(1, 0),
        })
        burst.Lifetime = NumberRange.new(0.5, 1.5)
        burst.Speed = NumberRange.new(3, 8)
        burst.SpreadAngle = Vector2.new(180, 180)
        burst.LightEmission = 1
        burst.Rate = 0
        burst.Parent = barrier
        burst:Emit(40)

        -- Dissolve barrier
        TweenService:Create(barrier, TweenInfo.new(1.5, Enum.EasingStyle.Quad), {
            Transparency = 1,
        }):Play()
        barrier.CanCollide = false

        -- Clean up after animation
        task.delay(2, function()
            if burst and burst.Parent then burst:Destroy() end
        end)
    else
        barrier.Transparency = 1
        barrier.CanCollide = false
    end
end

local function setNodePromptEnabled(node, enabled)
    local prompt = node:FindFirstChildWhichIsA("ProximityPrompt")
    if prompt then
        prompt.Enabled = enabled
    end
end

local function updateSubZones(stars, animated)
    for _, zone in ipairs(ForageTuning.SubZones) do
        local wasUnlocked = previousUnlocks[zone.name] or false
        local isUnlocked = stars >= zone.threshold

        if isUnlocked and not wasUnlocked then
            -- Just unlocked!
            dissolveBarrier(zone.name, animated)
            local nodes = findSubZoneNodes(zone.nodeIds)
            for _, node in ipairs(nodes) do
                setNodePromptEnabled(node, true)
            end
            if animated then
                pcall(function()
                    Remotes.GlobalAnnouncement:FireClient(player,
                        "The " .. zone.name .. " has opened in the Wild Grove!")
                end)
            end
        elseif isUnlocked then
            -- Already unlocked, ensure state is correct
            dissolveBarrier(zone.name, false)
            local nodes = findSubZoneNodes(zone.nodeIds)
            for _, node in ipairs(nodes) do
                setNodePromptEnabled(node, true)
            end
        else
            -- Still locked
            setBarrierLocked(zone.name, zone.threshold)
            local nodes = findSubZoneNodes(zone.nodeIds)
            for _, node in ipairs(nodes) do
                setNodePromptEnabled(node, false)
            end
        end

        previousUnlocks[zone.name] = isUnlocked
    end
end

-- ========== ZONE DETECTION ==========

local function checkIfInGrove()
    local char = player.Character
    if not char then return false end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    local grove = workspace:FindFirstChild("Zones") and workspace.Zones:FindFirstChild("WildGrove")
    if not grove then return false end
    local floor = grove:FindFirstChild("Floor")
    if floor and floor:IsA("BasePart") then
        local d = (Vector3.new(hrp.Position.X, 0, hrp.Position.Z) - Vector3.new(floor.Position.X, 0, floor.Position.Z)).Magnitude
        return d < math.max(floor.Size.X, floor.Size.Z) * 0.65
    end
    return false
end

-- ========== DATA UPDATE LISTENER ==========

Remotes.PlayerDataUpdate.OnClientEvent:Connect(function(data)
    if not data or not data.BrewStats then return end
    local newStars = data.BrewStats.TotalBrewed or 0
    local animated = currentStars > 0 and newStars > currentStars
    currentStars = newStars
    updateForageBadge(newStars)
    updateSubZones(newStars, animated)
end)

-- ========== INIT ==========

createForageBadge()

-- Initial data load
task.spawn(function()
    task.wait(4)
    local ok, data = pcall(function()
        return Remotes.GetPlayerData:InvokeServer()
    end)
    if ok and data and data.BrewStats then
        currentStars = data.BrewStats.TotalBrewed or 0
        updateForageBadge(currentStars)
        updateSubZones(currentStars, false) -- no animation on load
    end
end)

-- Zone presence polling for badge visibility
task.spawn(function()
    while true do
        local inGrove = checkIfInGrove()
        if inGrove and not isInGrove then
            isInGrove = true
            showForageBadge()
        elseif not inGrove and isInGrove then
            isInGrove = false
            hideForageBadge()
        end
        task.wait(0.75)
    end
end)

print("[GroveExpansionController] Initialized (Sprint 011 - Starbound Foraging)")
