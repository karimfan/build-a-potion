-- BrewVFXController: Dramatic world VFX during brewing
-- Event-driven via BindableEvent, not polling
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Remotes = RS.Remotes
local Potions = require(RS.Shared.Config.Potions)

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
local originalCauldronCFrame = nil

-- Sound references (created/destroyed per brew)
local sizzleSound, fireRoarSound, completionSound

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
local steamE, steamPlumeE, sparkE, fireE, fireworkE, bigFireE, magicSwirl, arcaneDustE, voidFlareE

local function setupEmitters()
    if not cauldron then return end
    for _, e in ipairs(stageEmitters) do if e and e.Parent then e:Destroy() end end
    stageEmitters = {}

    -- Thick steam (base layer)
    steamE = makeEmitter("Steam", cauldron, {
        Color = ColorSequence.new(Color3.fromRGB(220, 230, 255), Color3.fromRGB(180, 200, 240)),
        Size = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.5),
            NumberSequenceKeypoint.new(0.5, 3),
            NumberSequenceKeypoint.new(1, 6)
        }),
        Lifetime = NumberRange.new(2, 5),
        Speed = NumberRange.new(1, 5),
        SpreadAngle = Vector2.new(25, 25),
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.2),
            NumberSequenceKeypoint.new(0.5, 0.45),
            NumberSequenceKeypoint.new(1, 1)
        }),
        LightEmission = 0.2,
        RotSpeed = NumberRange.new(-30, 30),
        Rotation = NumberRange.new(0, 360),
    })

    -- Big billowing steam plumes (new — dramatic clouds)
    steamPlumeE = makeEmitter("SteamPlume", cauldron, {
        Color = ColorSequence.new(Color3.fromRGB(235, 240, 255), Color3.fromRGB(200, 210, 230)),
        Size = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 2),
            NumberSequenceKeypoint.new(0.4, 6),
            NumberSequenceKeypoint.new(1, 10)
        }),
        Lifetime = NumberRange.new(3, 7),
        Speed = NumberRange.new(0.8, 2.5),
        SpreadAngle = Vector2.new(15, 15),
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.15),
            NumberSequenceKeypoint.new(0.3, 0.35),
            NumberSequenceKeypoint.new(1, 1)
        }),
        LightEmission = 0.15,
        RotSpeed = NumberRange.new(-20, 20),
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

    -- Arcane dust for high-tier magical identity
    arcaneDustE = makeEmitter("ArcaneDust", cauldron, {
        Color = ColorSequence.new(Color3.fromRGB(150, 200, 255), Color3.fromRGB(190, 120, 255)),
        Size = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.05),
            NumberSequenceKeypoint.new(0.4, 0.14),
            NumberSequenceKeypoint.new(1, 0),
        }),
        Lifetime = NumberRange.new(1.2, 2.8),
        Speed = NumberRange.new(0.5, 1.7),
        SpreadAngle = Vector2.new(180, 180),
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.2),
            NumberSequenceKeypoint.new(1, 1),
        }),
        LightEmission = 1,
        RotSpeed = NumberRange.new(-80, 80),
    })

    -- Void flare for mythic/divine
    voidFlareE = makeEmitter("VoidFlare", cauldron, {
        Color = ColorSequence.new(Color3.fromRGB(110, 80, 255), Color3.fromRGB(240, 210, 255)),
        Size = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.2),
            NumberSequenceKeypoint.new(0.4, 0.8),
            NumberSequenceKeypoint.new(1, 0),
        }),
        Lifetime = NumberRange.new(0.4, 1.2),
        Speed = NumberRange.new(5, 14),
        SpreadAngle = Vector2.new(30, 30),
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.08),
            NumberSequenceKeypoint.new(1, 1),
        }),
        LightEmission = 1,
    })
end

-- === SOUND EFFECTS ===
local function setupSounds()
    if not cauldron then return end
    -- Clean up any existing brew sounds
    cleanupSounds()

    -- Sizzle/bubble loop
    sizzleSound = Instance.new("Sound")
    sizzleSound.Name = "BrewSizzle"
    sizzleSound.SoundId = "rbxassetid://9113869830" -- water/sizzle loop
    sizzleSound.Looped = true
    sizzleSound.Volume = 0
    sizzleSound.RollOffMaxDistance = 60
    sizzleSound.RollOffMinDistance = 5
    sizzleSound.Parent = cauldron

    -- Fire roar loop
    fireRoarSound = Instance.new("Sound")
    fireRoarSound.Name = "BrewFireRoar"
    fireRoarSound.SoundId = "rbxassetid://9114488653" -- fire crackling
    fireRoarSound.Looped = true
    fireRoarSound.Volume = 0
    fireRoarSound.RollOffMaxDistance = 50
    fireRoarSound.RollOffMinDistance = 5
    fireRoarSound.Parent = cauldron

    -- Completion boom (one-shot)
    completionSound = Instance.new("Sound")
    completionSound.Name = "BrewComplete"
    completionSound.SoundId = "rbxassetid://9125402735" -- magical burst
    completionSound.Looped = false
    completionSound.Volume = 0.8
    completionSound.RollOffMaxDistance = 80
    completionSound.RollOffMinDistance = 5
    completionSound.Parent = cauldron
end

function cleanupSounds()
    if sizzleSound and sizzleSound.Parent then sizzleSound:Destroy() end
    if fireRoarSound and fireRoarSound.Parent then fireRoarSound:Destroy() end
    if completionSound and completionSound.Parent then completionSound:Destroy() end
    sizzleSound, fireRoarSound, completionSound = nil, nil, nil
end

-- === CAMERA SHAKE ===
local function getCameraShakeTarget()
    local char = player.Character
    return char and char:FindFirstChildOfClass("Humanoid")
end

local function applyCameraShake(intensity)
    local hum = getCameraShakeTarget()
    if not hum then return end
    local x = (math.random() - 0.5) * 2 * intensity
    local y = (math.random() - 0.5) * 2 * intensity
    hum.CameraOffset = Vector3.new(x, y, 0)
end

local function resetCameraShake()
    local hum = getCameraShakeTarget()
    if hum then hum.CameraOffset = Vector3.new(0, 0, 0) end
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
    if ambientBubbles then ambientBubbles.Rate = 12 + pct * 40 * mult end

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
    if steamE then steamE.Rate = 12 + pct * 45 * mult end
    -- Steam plumes from 20%+
    if steamPlumeE then steamPlumeE.Rate = pct >= 0.2 and (4 + (pct - 0.2) * 25 * math.min(mult, 3)) or 0 end
    -- Magic swirl starts at 10%
    if magicSwirl then magicSwirl.Rate = pct >= 0.1 and (6 + pct * 16 * mult) or 0 end
    -- Stage 2: Sparks at 25%+
    if sparkE then sparkE.Rate = pct >= 0.25 and (15 + (pct - 0.25) * 40 * mult) or 0 end
    -- Stage 3: Fire at 50%+
    if fireE then fireE.Rate = pct >= 0.5 and (10 + (pct - 0.5) * 35 * mult) or 0 end
    -- Stage 4: Arcane dust at 35%+ for all, stronger with rarity
    if arcaneDustE then arcaneDustE.Rate = pct >= 0.35 and (8 + (pct - 0.35) * 38 * mult) or 0 end
    -- Stage 5: Void flare near completion on high multipliers
    if voidFlareE then voidFlareE.Rate = (mult >= 3 and pct >= 0.78) and (20 + (pct - 0.78) * 300 * (mult / 3)) or 0 end

    -- Sound: sizzle volume scales with progress
    if sizzleSound then
        sizzleSound.Volume = 0.1 + pct * 0.5 * math.min(mult, 2)
        if not sizzleSound.IsPlaying then sizzleSound:Play() end
    end
    -- Sound: fire roar at 50%+
    if fireRoarSound then
        if pct >= 0.5 then
            fireRoarSound.Volume = (pct - 0.5) * 0.8 * math.min(mult, 2)
            if not fireRoarSound.IsPlaying then fireRoarSound:Play() end
        else
            fireRoarSound.Volume = 0
        end
    end

    -- Cauldron shake (physical rumble)
    if originalCauldronCFrame and cauldron then
        local shakeIntensity = 0.02 + pct * 0.13 * math.min(mult, 4)
        local ox = (math.random() - 0.5) * shakeIntensity
        local oz = (math.random() - 0.5) * shakeIntensity
        local oy = (math.random() - 0.5) * shakeIntensity * 0.3
        cauldron.CFrame = originalCauldronCFrame * CFrame.new(ox, oy, oz)
    end

    -- Camera shake (subtle tremor, scales with progress)
    local camIntensity = 0.01 + pct * 0.08 * math.min(mult, 3)
    applyCameraShake(camIntensity)

    -- Liquid bubbling pulse (subtle size oscillation)
    if cauldronLiquid then
        local pulse = 1 + math.sin(tick() * 4 + pct * 10) * 0.02 * (1 + pct * 2)
        local baseSize = cauldronLiquid:GetAttribute("OriginalSize")
        if baseSize then
            cauldronLiquid.Size = baseSize * pulse
        end
    end
end

local function playShockwave(mult, rarity)
    if not cauldron then return end
    local ring = Instance.new("Part")
    ring.Name = "BrewShockwave"
    ring.Anchored = true
    ring.CanCollide = false
    ring.CastShadow = false
    ring.Shape = Enum.PartType.Cylinder
    ring.Material = Enum.Material.Neon
    ring.Color = (rarity == "Divine") and Color3.fromRGB(255, 240, 180) or ((rarity == "Mythic") and Color3.fromRGB(190, 120, 255) or Color3.fromRGB(130, 190, 255))
    ring.Size = Vector3.new(0.15, 2, 2)
    ring.CFrame = CFrame.new(cauldron.Position + Vector3.new(0, 0.4, 0)) * CFrame.Angles(0, 0, math.rad(90))
    ring.Transparency = 0.15
    ring.Parent = cauldron.Parent
    TweenService:Create(ring, TweenInfo.new(0.65, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size = Vector3.new(0.15, 36 * mult, 36 * mult),
        Transparency = 1,
    }):Play()
    task.delay(0.7, function()
        if ring and ring.Parent then ring:Destroy() end
    end)
end

-- Completion burst
local function playCompletionBurst(mult, rarity)
    mult = mult or 1
    -- Big fire column
    if bigFireE then bigFireE.Rate = 140 * mult end
    -- Fireworks
    if fireworkE then fireworkE.Rate = 140 * mult end
    -- Max sparks
    if sparkE then sparkE.Rate = 120 * mult end
    if arcaneDustE then arcaneDustE.Rate = 90 * mult end
    if voidFlareE and (rarity == "Mythic" or rarity == "Divine") then
        voidFlareE.Rate = 140 * mult
    end
    -- Max steam plumes
    if steamPlumeE then steamPlumeE.Rate = 30 * mult end
    -- Flash glow
    if cauldronGlow then
        cauldronGlow.Range = 110 + mult * 10
        cauldronGlow.Brightness = 16 + mult * 2
        cauldronGlow.Color = rarity == "Divine" and Color3.fromRGB(255, 235, 180) or Color3.new(1, 1, 0.85)
    end

    playShockwave(math.clamp(mult, 1, 3), rarity)

    -- Completion sound
    if completionSound then completionSound:Play() end

    -- Intense camera shake burst (decays over 0.5s)
    task.spawn(function()
        local burstStart = tick()
        local burstDuration = 0.5
        while tick() - burstStart < burstDuration do
            local t = (tick() - burstStart) / burstDuration
            local intensity = 0.4 * math.min(mult, 3) * (1 - t)
            applyCameraShake(intensity)
            RunService.Heartbeat:Wait()
        end
        resetCameraShake()
    end)

    -- Cauldron jump — pop up then settle
    if originalCauldronCFrame and cauldron then
        local jumpHeight = 0.5 * math.min(mult, 3)
        local jumpCF = originalCauldronCFrame + Vector3.new(0, jumpHeight, 0)
        TweenService:Create(cauldron, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            CFrame = jumpCF,
        }):Play()
        task.delay(0.15, function()
            if cauldron and originalCauldronCFrame then
                TweenService:Create(cauldron, TweenInfo.new(0.3, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out), {
                    CFrame = originalCauldronCFrame,
                }):Play()
            end
        end)
    end

    task.delay(0.8, function()
        if bigFireE then bigFireE.Rate = 0 end
        if fireworkE then fireworkE.Rate = 40 * mult end
    end)
    task.delay(1.5, function()
        if fireworkE then fireworkE.Rate = 0 end
        if sparkE then sparkE.Rate = 0 end
        if arcaneDustE then arcaneDustE.Rate = 0 end
        if voidFlareE then voidFlareE.Rate = 0 end
        if steamPlumeE then steamPlumeE.Rate = 0 end
        -- Fade out sounds
        if sizzleSound then TweenService:Create(sizzleSound, TweenInfo.new(1), { Volume = 0 }):Play() end
        if fireRoarSound then TweenService:Create(fireRoarSound, TweenInfo.new(0.5), { Volume = 0 }):Play() end
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
    -- Restore cauldron position
    if originalCauldronCFrame and cauldron then
        cauldron.CFrame = originalCauldronCFrame
    end
    originalCauldronCFrame = nil
    resetCameraShake()
    -- Stop sounds
    if sizzleSound and sizzleSound.IsPlaying then sizzleSound:Stop() end
    if fireRoarSound and fireRoarSound.IsPlaying then fireRoarSound:Stop() end
    cleanupSounds()
end

-- === MAIN BREW ANIMATION LOOP ===
local function runBrewAnimation(duration, endUnix, rarity)
    if not getShopRefs() then return end
    setupEmitters()
    setupSounds()
    isAnimating = true

    -- Save original CFrame for shake
    if cauldron then
        originalCauldronCFrame = cauldron.CFrame
    end

    -- Save original liquid size for pulse
    if cauldronLiquid and not cauldronLiquid:GetAttribute("OriginalSize") then
        cauldronLiquid:SetAttribute("OriginalSize", cauldronLiquid.Size)
    end

    startSpoonOrbit()

    local multMap = { Common = 1, Uncommon = 1.8, Rare = 3.2, Mythic = 5.6, Divine = 8.5 }
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
            playCompletionBurst(mult, rarity)
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
            local baseId = state.resultPotionId or "sludge"
            local sep = baseId:find("__")
            if sep then baseId = baseId:sub(1, sep - 1) end
            local potion = Potions.Data[baseId]
            local rarity = potion and potion.tier or "Common"
            runBrewAnimation(duration, state.endUnix, rarity)
        end
    end
end)

print("[BrewVFXController] Initialized (event-driven + sizzle VFX)")
