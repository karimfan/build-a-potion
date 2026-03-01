-- BrewVFXController: Dramatic world VFX during brewing
-- Event-driven via BindableEvent, not polling
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Remotes = RS.Remotes

local player = game.Players.LocalPlayer

-- Find the pre-created BindableEvent for brew state communication
local brewEvent = RS:WaitForChild("BrewStateEvent", 10)
if not brewEvent then
    brewEvent = Instance.new("BindableEvent")
    brewEvent.Name = "BrewStateEvent"
    brewEvent.Parent = RS
end

local cauldron, cauldronLiquid, spoon, cauldronGlow
local isAnimating = false
local vfxConnection = nil
local stageEmitters = {}

local function getShopRefs()
    local shop = workspace:FindFirstChild("Zones") and workspace.Zones:FindFirstChild("YourShop")
    if not shop then return false end
    cauldron = shop:FindFirstChild("Cauldron")
    cauldronLiquid = shop:FindFirstChild("CauldronLiquid")
    spoon = shop:FindFirstChild("BrewingSpoon")
    if cauldron then cauldronGlow = cauldron:FindFirstChild("CauldronGlow") end
    return cauldron ~= nil
end

local function setSpoonVisible(visible)
    if not spoon then return end
    local targetTransp = visible and 0 or 1
    for _, d in ipairs(spoon:GetDescendants()) do
        if d:IsA("BasePart") then
            if visible then
                TweenService:Create(d, TweenInfo.new(0.5), { Transparency = 0 }):Play()
            else
                TweenService:Create(d, TweenInfo.new(0.3), { Transparency = 1 }):Play()
            end
        end
    end
end

-- Create a particle emitter helper
local function makeEmitter(name, parent, props)
    local e = Instance.new("ParticleEmitter")
    e.Name = "BrewVFX_" .. name
    for k, v in pairs(props) do e[k] = v end
    e.Rate = 0
    e.Parent = parent
    table.insert(stageEmitters, e)
    return e
end

-- All stage emitters
local steamE, sparkE, fireE, fireworkE, bigFireE, magicSwirl

local function setupEmitters()
    if not cauldron then return end
    for _, e in ipairs(stageEmitters) do if e and e.Parent then e:Destroy() end end
    stageEmitters = {}

    -- Thick steam
    steamE = makeEmitter("Steam", cauldron, {
        Color = ColorSequence.new(Color3.fromRGB(220, 230, 255), Color3.fromRGB(180, 200, 240)),
        Size = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.5),
            NumberSequenceKeypoint.new(0.5, 2.5),
            NumberSequenceKeypoint.new(1, 4)
        }),
        Lifetime = NumberRange.new(2, 5),
        Speed = NumberRange.new(1, 4),
        SpreadAngle = Vector2.new(25, 25),
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.3),
            NumberSequenceKeypoint.new(0.5, 0.5),
            NumberSequenceKeypoint.new(1, 1)
        }),
        LightEmission = 0.2,
        RotSpeed = NumberRange.new(-30, 30),
        Rotation = NumberRange.new(0, 360),
    })

    -- Hot sparks
    sparkE = makeEmitter("Sparks", cauldron, {
        Color = ColorSequence.new(Color3.fromRGB(255, 220, 50), Color3.fromRGB(255, 80, 0)),
        Size = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.05),
            NumberSequenceKeypoint.new(0.2, 0.15),
            NumberSequenceKeypoint.new(1, 0)
        }),
        Lifetime = NumberRange.new(0.3, 1.2),
        Speed = NumberRange.new(5, 15),
        SpreadAngle = Vector2.new(50, 50),
        Transparency = NumberSequence.new(0, 1),
        LightEmission = 1,
        Drag = 3,
    })

    -- Fire bursts from rim
    fireE = makeEmitter("Fire", cauldron, {
        Color = ColorSequence.new(Color3.fromRGB(255, 180, 0), Color3.fromRGB(255, 30, 0)),
        Size = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.5),
            NumberSequenceKeypoint.new(0.3, 1.5),
            NumberSequenceKeypoint.new(1, 0)
        }),
        Lifetime = NumberRange.new(0.2, 0.8),
        Speed = NumberRange.new(3, 10),
        SpreadAngle = Vector2.new(35, 35),
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0),
            NumberSequenceKeypoint.new(0.4, 0.2),
            NumberSequenceKeypoint.new(1, 1)
        }),
        LightEmission = 1,
    })

    -- Big fire column for finale
    bigFireE = makeEmitter("BigFire", cauldron, {
        Color = ColorSequence.new(Color3.fromRGB(255, 200, 50), Color3.fromRGB(255, 50, 0)),
        Size = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 1),
            NumberSequenceKeypoint.new(0.5, 3),
            NumberSequenceKeypoint.new(1, 0)
        }),
        Lifetime = NumberRange.new(0.5, 1.5),
        Speed = NumberRange.new(10, 25),
        SpreadAngle = Vector2.new(15, 15),
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0),
            NumberSequenceKeypoint.new(0.3, 0.1),
            NumberSequenceKeypoint.new(1, 1)
        }),
        LightEmission = 1,
    })

    -- Fireworks
    fireworkE = makeEmitter("Fireworks", cauldron, {
        Color = ColorSequence.new(Color3.fromRGB(100, 200, 255), Color3.fromRGB(255, 100, 255)),
        Size = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.3),
            NumberSequenceKeypoint.new(0.3, 0.6),
            NumberSequenceKeypoint.new(1, 0)
        }),
        Lifetime = NumberRange.new(1, 3),
        Speed = NumberRange.new(15, 30),
        SpreadAngle = Vector2.new(70, 70),
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0),
            NumberSequenceKeypoint.new(0.5, 0),
            NumberSequenceKeypoint.new(1, 1)
        }),
        LightEmission = 1,
        Drag = 2,
    })

    -- Magic swirl around cauldron
    magicSwirl = makeEmitter("MagicSwirl", cauldron, {
        Color = ColorSequence.new(Color3.fromRGB(150, 80, 255), Color3.fromRGB(80, 200, 255)),
        Size = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0),
            NumberSequenceKeypoint.new(0.5, 0.3),
            NumberSequenceKeypoint.new(1, 0)
        }),
        Lifetime = NumberRange.new(1, 3),
        Speed = NumberRange.new(2, 5),
        SpreadAngle = Vector2.new(180, 180),
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.5),
            NumberSequenceKeypoint.new(0.5, 0),
            NumberSequenceKeypoint.new(1, 1)
        }),
        LightEmission = 1,
        RotSpeed = NumberRange.new(-90, 90),
    })
end

-- Spoon orbit animation
local function startSpoonOrbit()
    if not spoon or not cauldron then return end
    setSpoonVisible(true)
    local center = cauldron.Position + Vector3.new(0, 3.5, 0)
    local radius = 1.8
    local speed = 2.0
    local angle = 0

    if vfxConnection then vfxConnection:Disconnect() end
    vfxConnection = RunService.Heartbeat:Connect(function(dt)
        if not isAnimating then return end
        angle = angle + speed * dt
        local x = center.X + math.cos(angle) * radius
        local z = center.Z + math.sin(angle) * radius
        local y = center.Y + math.sin(angle * 2.5) * 0.4
        local tiltAngle = math.sin(angle * 1.5) * math.rad(15)
        spoon:PivotTo(CFrame.new(x, y, z) * CFrame.Angles(tiltAngle, -angle, math.rad(25)))
    end)
end

local function stopSpoonOrbit()
    if vfxConnection then vfxConnection:Disconnect() vfxConnection = nil end
    setSpoonVisible(false)
end

-- Update VFX by brew percentage
local function updateBrewVFX(pct, mult)
    mult = mult or 1
    local ambientBubbles = cauldron and cauldron:FindFirstChild("CauldronBubbles")
    if ambientBubbles then ambientBubbles.Rate = 8 + pct * 30 * mult end

    if cauldronGlow then
        cauldronGlow.Range = 20 + pct * 25 * mult
        cauldronGlow.Brightness = 2 + pct * 4 * mult
        -- Shift glow color from green toward potion-orange
        local r = 0.3 + pct * 0.7
        local g = 1 - pct * 0.3
        local b = 0.5 - pct * 0.4
        cauldronGlow.Color = Color3.new(r, g, b)
    end

    if cauldronLiquid then
        local r = 0.2 + pct * 0.6
        local g = 0.8 - pct * 0.4
        local b = 0.4 + pct * 0.2
        cauldronLiquid.Color = Color3.new(r, g, b)
    end

    -- Stage 1: Steam always on during brew, intensifies
    if steamE then steamE.Rate = 5 + pct * 15 * mult end
    -- Magic swirl starts at 10%
    if magicSwirl then magicSwirl.Rate = pct >= 0.1 and (3 + pct * 8 * mult) or 0 end
    -- Stage 2: Sparks at 25%+
    if sparkE then sparkE.Rate = pct >= 0.25 and (8 + (pct - 0.25) * 25 * mult) or 0 end
    -- Stage 3: Fire at 50%+
    if fireE then fireE.Rate = pct >= 0.5 and (5 + (pct - 0.5) * 20 * mult) or 0 end
end

-- Completion burst
local function playCompletionBurst(mult)
    mult = mult or 1
    -- Big fire column
    if bigFireE then bigFireE.Rate = 60 * mult end
    -- Fireworks
    if fireworkE then fireworkE.Rate = 80 * mult end
    -- Max sparks
    if sparkE then sparkE.Rate = 50 * mult end
    -- Flash glow
    if cauldronGlow then
        cauldronGlow.Range = 80
        cauldronGlow.Brightness = 10
        cauldronGlow.Color = Color3.new(1, 1, 0.8)
    end

    task.delay(0.8, function()
        if bigFireE then bigFireE.Rate = 0 end
        if fireworkE then fireworkE.Rate = 40 * mult end
    end)
    task.delay(1.5, function()
        if fireworkE then fireworkE.Rate = 0 end
        if sparkE then sparkE.Rate = 0 end
    end)
    task.delay(2, function()
        resetVFX()
    end)
end

function resetVFX()
    for _, e in ipairs(stageEmitters) do if e and e.Parent then e.Rate = 0 end end
    local ambientBubbles = cauldron and cauldron:FindFirstChild("CauldronBubbles")
    if ambientBubbles then ambientBubbles.Rate = 8 end
    if cauldronGlow then
        cauldronGlow.Range = 20
        cauldronGlow.Brightness = 2
        cauldronGlow.Color = Color3.new(0.3, 1, 0.5)
    end
    if cauldronLiquid then
        cauldronLiquid.Color = Color3.fromRGB(50, 200, 100)
    end
end

-- === MAIN BREW ANIMATION LOOP ===
local function runBrewAnimation(duration, endUnix, rarity)
    if not getShopRefs() then return end
    setupEmitters()
    isAnimating = true
    startSpoonOrbit()

    local multMap = { Common = 1, Uncommon = 1.3, Rare = 1.8, Mythic = 2.5 }
    local mult = multMap[rarity] or 1

    -- Update loop
    local conn
    conn = RunService.Heartbeat:Connect(function()
        if not isAnimating then
            conn:Disconnect()
            return
        end
        local now = os.time()
        local elapsed = duration - math.max(0, endUnix - now)
        local pct = math.clamp(elapsed / duration, 0, 1)
        updateBrewVFX(pct, mult)

        if pct >= 1 then
            conn:Disconnect()
            playCompletionBurst(mult)
            isAnimating = false
            stopSpoonOrbit()
        end
    end)
end

-- Listen for brew events from InteractionController
brewEvent.Event:Connect(function(action, data)
    if action == "start" then
        runBrewAnimation(data.duration, data.endUnix, data.rarity)
    elseif action == "stop" then
        isAnimating = false
        stopSpoonOrbit()
        resetVFX()
    end
end)

-- Also check on load for active brew (reconnect scenario)
task.spawn(function()
    task.wait(4)
    if not getShopRefs() then return end
    setupEmitters()
    local state = Remotes.GetActiveBrewState:InvokeServer()
    if state and state.status == "brewing" then
        local now = os.time()
        local remaining = math.max(0, state.endUnix - now)
        if remaining > 0 then
            local duration = state.endUnix - state.startUnix
            runBrewAnimation(duration, state.endUnix, "Common")
        end
    end
end)

print("[BrewVFXController] Initialized (event-driven)")
