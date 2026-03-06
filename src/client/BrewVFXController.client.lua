-- BrewVFXController: MAXIMUM DRAMA brewing VFX
-- Event-driven via BindableEvent, not polling
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Remotes = RS.Remotes
local Potions = require(RS.Shared.Config.Potions)

local player = game.Players.LocalPlayer

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

local bubbleSound, rumbleSound, thunderSound, completionSound, swooshSound, chimeSound
local fireBurstSounds = {}
local lastFireBurstTime = 0
local lastThunderTime = 0

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
local steamE, steamPlumeE, steamGeyserE, sparkE, sparkShowerE, fireE, firePillarE
local fireworkE, bigFireE, magicSwirl, magicRingE, arcaneDustE, voidFlareE
local emberE, smokeTrailE, lightningE, runeGlowE

local function setupEmitters()
    if not cauldron then return end
    for _, e in ipairs(stageEmitters) do if e and e.Parent then e:Destroy() end end
    stageEmitters = {}

    -- 1. BASE STEAM — thick rolling clouds
    steamE = makeEmitter("Steam", cauldron, {
        Color = ColorSequence.new(Color3.fromRGB(220, 230, 255), Color3.fromRGB(180, 200, 240)),
        Size = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 1),
            NumberSequenceKeypoint.new(0.5, 5),
            NumberSequenceKeypoint.new(1, 10)
        }),
        Lifetime = NumberRange.new(3, 6),
        Speed = NumberRange.new(2, 8),
        SpreadAngle = Vector2.new(30, 30),
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.1),
            NumberSequenceKeypoint.new(0.5, 0.35),
            NumberSequenceKeypoint.new(1, 1)
        }),
        LightEmission = 0.3,
        RotSpeed = NumberRange.new(-40, 40),
        Rotation = NumberRange.new(0, 360),
    })

    -- 2. STEAM PLUMES — big billowing clouds that rise high
    steamPlumeE = makeEmitter("SteamPlume", cauldron, {
        Color = ColorSequence.new(Color3.fromRGB(240, 245, 255), Color3.fromRGB(200, 215, 240)),
        Size = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 3),
            NumberSequenceKeypoint.new(0.3, 10),
            NumberSequenceKeypoint.new(0.7, 16),
            NumberSequenceKeypoint.new(1, 20)
        }),
        Lifetime = NumberRange.new(4, 8),
        Speed = NumberRange.new(3, 8),
        SpreadAngle = Vector2.new(12, 12),
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.05),
            NumberSequenceKeypoint.new(0.2, 0.2),
            NumberSequenceKeypoint.new(0.7, 0.5),
            NumberSequenceKeypoint.new(1, 1)
        }),
        LightEmission = 0.2,
        RotSpeed = NumberRange.new(-25, 25),
        Rotation = NumberRange.new(0, 360),
    })

    -- 3. STEAM GEYSER — narrow high-velocity column shooting to the sky
    steamGeyserE = makeEmitter("SteamGeyser", cauldron, {
        Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(210, 220, 255)),
        Size = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 1.5),
            NumberSequenceKeypoint.new(0.2, 4),
            NumberSequenceKeypoint.new(0.6, 8),
            NumberSequenceKeypoint.new(1, 14)
        }),
        Lifetime = NumberRange.new(2, 5),
        Speed = NumberRange.new(20, 50),
        SpreadAngle = Vector2.new(5, 5),
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0),
            NumberSequenceKeypoint.new(0.3, 0.15),
            NumberSequenceKeypoint.new(0.7, 0.5),
            NumberSequenceKeypoint.new(1, 1)
        }),
        LightEmission = 0.4,
        RotSpeed = NumberRange.new(-15, 15),
        Rotation = NumberRange.new(0, 360),
    })

    -- 4. HOT SPARKS — snappy bright motes
    sparkE = makeEmitter("Sparks", cauldron, {
        Color = ColorSequence.new(Color3.fromRGB(255, 240, 80), Color3.fromRGB(255, 100, 0)),
        Size = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.08),
            NumberSequenceKeypoint.new(0.15, 0.25),
            NumberSequenceKeypoint.new(1, 0)
        }),
        Lifetime = NumberRange.new(0.4, 1.5),
        Speed = NumberRange.new(8, 25),
        SpreadAngle = Vector2.new(60, 60),
        Transparency = NumberSequence.new(0, 1),
        LightEmission = 1,
        Drag = 2,
    })

    -- 5. SPARK SHOWER — dense cascade of tiny sparks raining outward
    sparkShowerE = makeEmitter("SparkShower", cauldron, {
        Color = ColorSequence.new(Color3.fromRGB(255, 200, 50), Color3.fromRGB(255, 60, 0)),
        Size = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.04),
            NumberSequenceKeypoint.new(0.1, 0.12),
            NumberSequenceKeypoint.new(1, 0)
        }),
        Lifetime = NumberRange.new(0.5, 2),
        Speed = NumberRange.new(12, 35),
        SpreadAngle = Vector2.new(80, 80),
        Transparency = NumberSequence.new(0, 1),
        LightEmission = 1,
        Drag = 4,
    })

    -- 6. FIRE BURSTS — licking flames from the rim
    fireE = makeEmitter("Fire", cauldron, {
        Color = ColorSequence.new(Color3.fromRGB(255, 200, 30), Color3.fromRGB(255, 40, 0)),
        Size = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.8),
            NumberSequenceKeypoint.new(0.3, 3),
            NumberSequenceKeypoint.new(1, 0)
        }),
        Lifetime = NumberRange.new(0.2, 1),
        Speed = NumberRange.new(5, 18),
        SpreadAngle = Vector2.new(40, 40),
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0),
            NumberSequenceKeypoint.new(0.3, 0.1),
            NumberSequenceKeypoint.new(1, 1)
        }),
        LightEmission = 1,
    })

    -- 7. FIRE PILLAR — tall roaring column of flame
    firePillarE = makeEmitter("FirePillar", cauldron, {
        Color = ColorSequence.new(Color3.fromRGB(255, 220, 60), Color3.fromRGB(255, 50, 0)),
        Size = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 1.5),
            NumberSequenceKeypoint.new(0.3, 4),
            NumberSequenceKeypoint.new(0.7, 6),
            NumberSequenceKeypoint.new(1, 0)
        }),
        Lifetime = NumberRange.new(0.5, 1.5),
        Speed = NumberRange.new(15, 40),
        SpreadAngle = Vector2.new(8, 8),
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0),
            NumberSequenceKeypoint.new(0.2, 0.05),
            NumberSequenceKeypoint.new(1, 1)
        }),
        LightEmission = 1,
    })

    -- 8. EMBERS — slow floating hot embers drifting upward
    emberE = makeEmitter("Embers", cauldron, {
        Color = ColorSequence.new(Color3.fromRGB(255, 160, 30), Color3.fromRGB(255, 60, 0)),
        Size = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.1),
            NumberSequenceKeypoint.new(0.5, 0.2),
            NumberSequenceKeypoint.new(1, 0)
        }),
        Lifetime = NumberRange.new(2, 5),
        Speed = NumberRange.new(1, 4),
        SpreadAngle = Vector2.new(45, 45),
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0),
            NumberSequenceKeypoint.new(0.7, 0.3),
            NumberSequenceKeypoint.new(1, 1)
        }),
        LightEmission = 1,
        RotSpeed = NumberRange.new(-60, 60),
    })

    -- 9. SMOKE TRAIL — dark dramatic smoke rising after fire
    smokeTrailE = makeEmitter("SmokeTrail", cauldron, {
        Color = ColorSequence.new(Color3.fromRGB(60, 50, 50), Color3.fromRGB(30, 25, 30)),
        Size = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 1),
            NumberSequenceKeypoint.new(0.4, 5),
            NumberSequenceKeypoint.new(1, 12)
        }),
        Lifetime = NumberRange.new(3, 7),
        Speed = NumberRange.new(2, 6),
        SpreadAngle = Vector2.new(20, 20),
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.4),
            NumberSequenceKeypoint.new(0.5, 0.65),
            NumberSequenceKeypoint.new(1, 1)
        }),
        LightEmission = 0,
        RotSpeed = NumberRange.new(-20, 20),
        Rotation = NumberRange.new(0, 360),
    })

    -- 10. BIG FIRE COLUMN — finale eruption
    bigFireE = makeEmitter("BigFire", cauldron, {
        Color = ColorSequence.new(Color3.fromRGB(255, 220, 60), Color3.fromRGB(255, 40, 0)),
        Size = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 2),
            NumberSequenceKeypoint.new(0.4, 6),
            NumberSequenceKeypoint.new(1, 0)
        }),
        Lifetime = NumberRange.new(0.5, 2),
        Speed = NumberRange.new(20, 50),
        SpreadAngle = Vector2.new(12, 12),
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0),
            NumberSequenceKeypoint.new(0.2, 0.05),
            NumberSequenceKeypoint.new(1, 1)
        }),
        LightEmission = 1,
    })

    -- 11. FIREWORKS — explosive finale
    fireworkE = makeEmitter("Fireworks", cauldron, {
        Color = ColorSequence.new(Color3.fromRGB(100, 200, 255), Color3.fromRGB(255, 100, 255)),
        Size = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.4),
            NumberSequenceKeypoint.new(0.3, 0.8),
            NumberSequenceKeypoint.new(1, 0)
        }),
        Lifetime = NumberRange.new(1, 3),
        Speed = NumberRange.new(25, 55),
        SpreadAngle = Vector2.new(85, 85),
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0),
            NumberSequenceKeypoint.new(0.5, 0),
            NumberSequenceKeypoint.new(1, 1)
        }),
        LightEmission = 1,
        Drag = 2,
    })

    -- 12. MAGIC SWIRL — orbiting mystical particles
    magicSwirl = makeEmitter("MagicSwirl", cauldron, {
        Color = ColorSequence.new(Color3.fromRGB(150, 80, 255), Color3.fromRGB(80, 200, 255)),
        Size = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0),
            NumberSequenceKeypoint.new(0.5, 0.5),
            NumberSequenceKeypoint.new(1, 0)
        }),
        Lifetime = NumberRange.new(1, 3),
        Speed = NumberRange.new(3, 8),
        SpreadAngle = Vector2.new(180, 180),
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.4),
            NumberSequenceKeypoint.new(0.5, 0),
            NumberSequenceKeypoint.new(1, 1)
        }),
        LightEmission = 1,
        RotSpeed = NumberRange.new(-120, 120),
    })

    -- 13. MAGIC RING — horizontal ring of arcane energy
    magicRingE = makeEmitter("MagicRing", cauldron, {
        Color = ColorSequence.new(Color3.fromRGB(100, 60, 255), Color3.fromRGB(200, 150, 255)),
        Size = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.1),
            NumberSequenceKeypoint.new(0.3, 0.4),
            NumberSequenceKeypoint.new(1, 0)
        }),
        Lifetime = NumberRange.new(1.5, 3),
        Speed = NumberRange.new(4, 10),
        SpreadAngle = Vector2.new(180, 10),
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.2),
            NumberSequenceKeypoint.new(0.5, 0),
            NumberSequenceKeypoint.new(1, 1)
        }),
        LightEmission = 1,
        RotSpeed = NumberRange.new(-150, 150),
    })

    -- 14. ARCANE DUST — shimmering mystical motes
    arcaneDustE = makeEmitter("ArcaneDust", cauldron, {
        Color = ColorSequence.new(Color3.fromRGB(150, 200, 255), Color3.fromRGB(190, 120, 255)),
        Size = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.06),
            NumberSequenceKeypoint.new(0.4, 0.2),
            NumberSequenceKeypoint.new(1, 0),
        }),
        Lifetime = NumberRange.new(1.5, 3.5),
        Speed = NumberRange.new(1, 3),
        SpreadAngle = Vector2.new(180, 180),
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.1),
            NumberSequenceKeypoint.new(1, 1),
        }),
        LightEmission = 1,
        RotSpeed = NumberRange.new(-100, 100),
    })

    -- 15. LIGHTNING CRACKLE — quick bright flashes for mythic/divine
    lightningE = makeEmitter("Lightning", cauldron, {
        Color = ColorSequence.new(Color3.fromRGB(200, 220, 255), Color3.fromRGB(150, 180, 255)),
        Size = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.1),
            NumberSequenceKeypoint.new(0.05, 0.6),
            NumberSequenceKeypoint.new(0.15, 0.1),
            NumberSequenceKeypoint.new(1, 0)
        }),
        Lifetime = NumberRange.new(0.1, 0.4),
        Speed = NumberRange.new(20, 50),
        SpreadAngle = Vector2.new(90, 90),
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0),
            NumberSequenceKeypoint.new(0.5, 0.3),
            NumberSequenceKeypoint.new(1, 1)
        }),
        LightEmission = 1,
    })

    -- 16. RUNE GLOW — slow rising mystical symbols/orbs
    runeGlowE = makeEmitter("RuneGlow", cauldron, {
        Color = ColorSequence.new(Color3.fromRGB(80, 255, 150), Color3.fromRGB(50, 180, 255)),
        Size = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.3),
            NumberSequenceKeypoint.new(0.5, 0.8),
            NumberSequenceKeypoint.new(1, 0)
        }),
        Lifetime = NumberRange.new(2, 4),
        Speed = NumberRange.new(1, 3),
        SpreadAngle = Vector2.new(40, 40),
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.3),
            NumberSequenceKeypoint.new(0.4, 0),
            NumberSequenceKeypoint.new(1, 1)
        }),
        LightEmission = 1,
        RotSpeed = NumberRange.new(-40, 40),
    })

    -- 17. VOID FLARE — mythic/divine intensity bursts
    voidFlareE = makeEmitter("VoidFlare", cauldron, {
        Color = ColorSequence.new(Color3.fromRGB(110, 80, 255), Color3.fromRGB(240, 210, 255)),
        Size = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.3),
            NumberSequenceKeypoint.new(0.4, 1.2),
            NumberSequenceKeypoint.new(1, 0),
        }),
        Lifetime = NumberRange.new(0.4, 1.2),
        Speed = NumberRange.new(8, 22),
        SpreadAngle = Vector2.new(35, 35),
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0),
            NumberSequenceKeypoint.new(1, 1),
        }),
        LightEmission = 1,
    })
end

-- === SOUND EFFECTS (all IDs verified working in Studio) ===
local function setupSounds()
    if not cauldron then return end
    cleanupSounds()

    -- Bubbling cauldron loop (swim ambience pitched up)
    bubbleSound = Instance.new("Sound")
    bubbleSound.Name = "BrewBubble"
    bubbleSound.SoundId = "rbxasset://sounds/action_swim.mp3"
    bubbleSound.Looped = true
    bubbleSound.Volume = 0
    bubbleSound.PlaybackSpeed = 1.4
    bubbleSound.RollOffMaxDistance = 60
    bubbleSound.RollOffMinDistance = 5
    bubbleSound.Parent = cauldron

    -- Deep rumble/roar loop (falling wind pitched way down)
    rumbleSound = Instance.new("Sound")
    rumbleSound.Name = "BrewRumble"
    rumbleSound.SoundId = "rbxasset://sounds/action_falling.mp3"
    rumbleSound.Looped = true
    rumbleSound.Volume = 0
    rumbleSound.PlaybackSpeed = 0.4
    rumbleSound.RollOffMaxDistance = 80
    rumbleSound.RollOffMinDistance = 5
    rumbleSound.Parent = cauldron

    -- Thunder crack for lightning at high progress
    thunderSound = Instance.new("Sound")
    thunderSound.Name = "BrewThunder"
    thunderSound.SoundId = "rbxassetid://142070127"
    thunderSound.Looped = false
    thunderSound.Volume = 0.6
    thunderSound.RollOffMaxDistance = 80
    thunderSound.RollOffMinDistance = 5
    thunderSound.Parent = cauldron

    -- Fire burst one-shots (random during fire phase)
    for i = 1, 3 do
        local fb = Instance.new("Sound")
        fb.Name = "BrewFireBurst_" .. i
        fb.SoundId = "rbxassetid://130113370"
        fb.Looped = false
        fb.Volume = 0.4
        fb.PlaybackSpeed = 0.8 + math.random() * 0.4
        fb.RollOffMaxDistance = 50
        fb.RollOffMinDistance = 5
        fb.Parent = cauldron
        table.insert(fireBurstSounds, fb)
    end

    -- Completion swoosh
    swooshSound = Instance.new("Sound")
    swooshSound.Name = "BrewSwoosh"
    swooshSound.SoundId = "rbxassetid://2865227271"
    swooshSound.Looped = false
    swooshSound.Volume = 0.8
    swooshSound.PlaybackSpeed = 1.2
    swooshSound.RollOffMaxDistance = 100
    swooshSound.RollOffMinDistance = 5
    swooshSound.Parent = cauldron

    -- Completion magical burst
    completionSound = Instance.new("Sound")
    completionSound.Name = "BrewComplete"
    completionSound.SoundId = "rbxassetid://9125402735"
    completionSound.Looped = false
    completionSound.Volume = 1
    completionSound.RollOffMaxDistance = 100
    completionSound.RollOffMinDistance = 5
    completionSound.Parent = cauldron

    -- Completion chime
    chimeSound = Instance.new("Sound")
    chimeSound.Name = "BrewChime"
    chimeSound.SoundId = "rbxassetid://169380525"
    chimeSound.Looped = false
    chimeSound.Volume = 0.7
    chimeSound.PlaybackSpeed = 0.8
    chimeSound.RollOffMaxDistance = 80
    chimeSound.RollOffMinDistance = 5
    chimeSound.Parent = cauldron
end

function cleanupSounds()
    if bubbleSound and bubbleSound.Parent then bubbleSound:Destroy() end
    if rumbleSound and rumbleSound.Parent then rumbleSound:Destroy() end
    if thunderSound and thunderSound.Parent then thunderSound:Destroy() end
    if completionSound and completionSound.Parent then completionSound:Destroy() end
    if swooshSound and swooshSound.Parent then swooshSound:Destroy() end
    if chimeSound and chimeSound.Parent then chimeSound:Destroy() end
    for _, fb in ipairs(fireBurstSounds) do
        if fb and fb.Parent then fb:Destroy() end
    end
    bubbleSound, rumbleSound, thunderSound = nil, nil, nil
    completionSound, swooshSound, chimeSound = nil, nil, nil
    fireBurstSounds = {}
    lastFireBurstTime = 0
    lastThunderTime = 0
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
        -- Speed up spoon as brew progresses (gets frantic)
        speed = 2.0 + angle * 0.001
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

-- Update VFX by brew percentage — CRANKED TO MAX
local function updateBrewVFX(pct, mult)
    mult = mult or 1
    local ambientBubbles = cauldron and cauldron:FindFirstChild("CauldronBubbles")
    if ambientBubbles then ambientBubbles.Rate = 20 + pct * 80 * mult end

    if cauldronGlow then
        cauldronGlow.Range = 25 + pct * 40 * mult
        cauldronGlow.Brightness = 3 + pct * 8 * mult
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

    -- STEAM: always on, massive scaling
    if steamE then steamE.Rate = 20 + pct * 80 * mult end
    -- STEAM PLUMES: from 10%+, big billowing clouds
    if steamPlumeE then steamPlumeE.Rate = pct >= 0.1 and (8 + (pct - 0.1) * 50 * math.min(mult, 4)) or 0 end
    -- STEAM GEYSER: from 30%+, shoots to the sky
    if steamGeyserE then steamGeyserE.Rate = pct >= 0.3 and (5 + (pct - 0.3) * 40 * math.min(mult, 3)) or 0 end
    -- MAGIC SWIRL: from 5%+
    if magicSwirl then magicSwirl.Rate = pct >= 0.05 and (10 + pct * 30 * mult) or 0 end
    -- MAGIC RING: from 15%+
    if magicRingE then magicRingE.Rate = pct >= 0.15 and (6 + pct * 20 * mult) or 0 end
    -- RUNE GLOW: from 10%+
    if runeGlowE then runeGlowE.Rate = pct >= 0.1 and (4 + pct * 16 * mult) or 0 end
    -- SPARKS: from 20%+
    if sparkE then sparkE.Rate = pct >= 0.2 and (25 + (pct - 0.2) * 80 * mult) or 0 end
    -- SPARK SHOWER: from 35%+
    if sparkShowerE then sparkShowerE.Rate = pct >= 0.35 and (20 + (pct - 0.35) * 100 * mult) or 0 end
    -- EMBERS: from 25%+, gentle floaters
    if emberE then emberE.Rate = pct >= 0.25 and (10 + (pct - 0.25) * 40 * mult) or 0 end
    -- FIRE: from 40%+
    if fireE then fireE.Rate = pct >= 0.4 and (15 + (pct - 0.4) * 60 * mult) or 0 end
    -- FIRE PILLAR: from 60%+, roaring column
    if firePillarE then firePillarE.Rate = pct >= 0.6 and (8 + (pct - 0.6) * 50 * mult) or 0 end
    -- SMOKE TRAIL: from 50%+, dramatic dark smoke
    if smokeTrailE then smokeTrailE.Rate = pct >= 0.5 and (4 + (pct - 0.5) * 20 * math.min(mult, 2)) or 0 end
    -- ARCANE DUST: from 30%+
    if arcaneDustE then arcaneDustE.Rate = pct >= 0.3 and (15 + (pct - 0.3) * 60 * mult) or 0 end
    -- LIGHTNING: from 70%+ on rare+, electric crackle
    if lightningE then lightningE.Rate = (mult >= 2 and pct >= 0.7) and (8 + (pct - 0.7) * 80 * (mult / 2)) or 0 end
    -- VOID FLARE: from 75%+ on mythic/divine
    if voidFlareE then voidFlareE.Rate = (mult >= 3 and pct >= 0.75) and (25 + (pct - 0.75) * 400 * (mult / 3)) or 0 end

    -- SOUNDS: bubbling loop scales with progress
    if bubbleSound then
        bubbleSound.Volume = 0.1 + pct * 0.6 * math.min(mult, 2)
        bubbleSound.PlaybackSpeed = 1.4 + pct * 0.6
        if not bubbleSound.IsPlaying then bubbleSound:Play() end
    end
    -- Rumble loop from 30%+
    if rumbleSound then
        if pct >= 0.3 then
            rumbleSound.Volume = (pct - 0.3) * 0.5 * math.min(mult, 2)
            rumbleSound.PlaybackSpeed = 0.3 + pct * 0.2
            if not rumbleSound.IsPlaying then rumbleSound:Play() end
        else
            rumbleSound.Volume = 0
        end
    end
    -- Random fire burst one-shots during fire phase
    if pct >= 0.4 and #fireBurstSounds > 0 then
        local now = tick()
        local interval = math.max(0.5, 3 - pct * 2.5)
        if now - lastFireBurstTime > interval then
            local fb = fireBurstSounds[math.random(1, #fireBurstSounds)]
            if fb and not fb.IsPlaying then
                fb.Volume = 0.3 + pct * 0.4
                fb.PlaybackSpeed = 0.7 + math.random() * 0.6
                fb:Play()
            end
            lastFireBurstTime = now
        end
    end
    -- Thunder crack at 70%+ for rare+
    if mult >= 2 and pct >= 0.7 and thunderSound then
        local now = tick()
        local interval = math.max(1.5, 5 - pct * 4)
        if now - lastThunderTime > interval then
            thunderSound.Volume = 0.3 + (pct - 0.7) * 1.5 * math.min(mult, 3)
            thunderSound.PlaybackSpeed = 0.8 + math.random() * 0.4
            thunderSound:Play()
            lastThunderTime = now
        end
    end

    -- CAULDRON SHAKE — aggressive physical rumble
    if originalCauldronCFrame and cauldron then
        local shakeIntensity = 0.03 + pct * 0.2 * math.min(mult, 5)
        local ox = (math.random() - 0.5) * shakeIntensity
        local oz = (math.random() - 0.5) * shakeIntensity
        local oy = (math.random() - 0.5) * shakeIntensity * 0.4
        -- Add rotational shake at high progress
        local rotShake = pct * 0.02 * math.min(mult, 3)
        local rx = (math.random() - 0.5) * rotShake
        local rz = (math.random() - 0.5) * rotShake
        cauldron.CFrame = originalCauldronCFrame * CFrame.new(ox, oy, oz) * CFrame.Angles(rx, 0, rz)
    end

    -- CAMERA SHAKE — feel the power
    local camIntensity = 0.015 + pct * 0.12 * math.min(mult, 3)
    applyCameraShake(camIntensity)

    -- Liquid pulse
    if cauldronLiquid then
        local pulse = 1 + math.sin(tick() * 6 + pct * 15) * 0.03 * (1 + pct * 3)
        local baseSize = cauldronLiquid:GetAttribute("OriginalSize")
        if baseSize then
            cauldronLiquid.Size = baseSize * pulse
        end
    end
end

local function playShockwave(mult, rarity)
    if not cauldron then return end
    -- Double shockwave — inner fast + outer slow
    for i, data in ipairs({
        { delay = 0, speed = 0.5, maxSize = 40, color = nil },
        { delay = 0.15, speed = 0.8, maxSize = 60, color = nil },
    }) do
        task.delay(data.delay, function()
            local ring = Instance.new("Part")
            ring.Name = "BrewShockwave"
            ring.Anchored = true
            ring.CanCollide = false
            ring.CastShadow = false
            ring.Shape = Enum.PartType.Cylinder
            ring.Material = Enum.Material.Neon
            ring.Color = (rarity == "Divine") and Color3.fromRGB(255, 240, 180) or ((rarity == "Mythic") and Color3.fromRGB(190, 120, 255) or Color3.fromRGB(130, 190, 255))
            ring.Size = Vector3.new(0.2, 2, 2)
            ring.CFrame = CFrame.new(cauldron.Position + Vector3.new(0, 0.4, 0)) * CFrame.Angles(0, 0, math.rad(90))
            ring.Transparency = 0.1
            ring.Parent = cauldron.Parent
            TweenService:Create(ring, TweenInfo.new(data.speed, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Size = Vector3.new(0.2, data.maxSize * mult, data.maxSize * mult),
                Transparency = 1,
            }):Play()
            task.delay(data.speed + 0.1, function()
                if ring and ring.Parent then ring:Destroy() end
            end)
        end)
    end
end

-- Completion burst — MAXIMUM DRAMA
local function playCompletionBurst(mult, rarity)
    mult = mult or 1
    -- Everything at max
    if bigFireE then bigFireE.Rate = 200 * mult end
    if fireworkE then fireworkE.Rate = 200 * mult end
    if sparkE then sparkE.Rate = 200 * mult end
    if sparkShowerE then sparkShowerE.Rate = 250 * mult end
    if arcaneDustE then arcaneDustE.Rate = 120 * mult end
    if steamGeyserE then steamGeyserE.Rate = 60 * mult end
    if steamPlumeE then steamPlumeE.Rate = 50 * mult end
    if firePillarE then firePillarE.Rate = 80 * mult end
    if emberE then emberE.Rate = 80 * mult end
    if lightningE then lightningE.Rate = 60 * mult end
    if runeGlowE then runeGlowE.Rate = 40 * mult end
    if magicRingE then magicRingE.Rate = 30 * mult end
    if smokeTrailE then smokeTrailE.Rate = 25 * mult end
    if voidFlareE and (rarity == "Mythic" or rarity == "Divine") then
        voidFlareE.Rate = 200 * mult
    end
    -- Flash glow HUGE
    if cauldronGlow then
        cauldronGlow.Range = 150 + mult * 20
        cauldronGlow.Brightness = 25 + mult * 5
        cauldronGlow.Color = rarity == "Divine" and Color3.fromRGB(255, 235, 180) or Color3.new(1, 1, 0.85)
    end

    playShockwave(math.clamp(mult, 1, 3), rarity)

    -- Completion audio: swoosh + burst + chime layered
    if swooshSound then swooshSound:Play() end
    if completionSound then completionSound:Play() end
    task.delay(0.3, function()
        if chimeSound then chimeSound:Play() end
    end)
    if thunderSound and (rarity == "Mythic" or rarity == "Divine") then
        thunderSound.Volume = 0.8
        thunderSound:Play()
    end

    -- INTENSE camera shake burst (decays over 0.8s)
    task.spawn(function()
        local burstStart = tick()
        local burstDuration = 0.8
        while tick() - burstStart < burstDuration do
            local t = (tick() - burstStart) / burstDuration
            local intensity = 0.6 * math.min(mult, 4) * (1 - t)
            applyCameraShake(intensity)
            RunService.Heartbeat:Wait()
        end
        resetCameraShake()
    end)

    -- Cauldron JUMP — big pop up then bouncy settle
    if originalCauldronCFrame and cauldron then
        local jumpHeight = 1.0 * math.min(mult, 3)
        local jumpCF = originalCauldronCFrame + Vector3.new(0, jumpHeight, 0)
        TweenService:Create(cauldron, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            CFrame = jumpCF,
        }):Play()
        task.delay(0.12, function()
            if cauldron and originalCauldronCFrame then
                TweenService:Create(cauldron, TweenInfo.new(0.4, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out), {
                    CFrame = originalCauldronCFrame,
                }):Play()
            end
        end)
    end

    -- Staged wind-down
    task.delay(1.0, function()
        if bigFireE then bigFireE.Rate = 0 end
        if firePillarE then firePillarE.Rate = 0 end
        if fireworkE then fireworkE.Rate = 60 * mult end
        if sparkShowerE then sparkShowerE.Rate = 40 * mult end
    end)
    task.delay(2.0, function()
        if fireworkE then fireworkE.Rate = 0 end
        if sparkE then sparkE.Rate = 0 end
        if sparkShowerE then sparkShowerE.Rate = 0 end
        if arcaneDustE then arcaneDustE.Rate = 0 end
        if voidFlareE then voidFlareE.Rate = 0 end
        if steamGeyserE then steamGeyserE.Rate = 0 end
        if steamPlumeE then steamPlumeE.Rate = 0 end
        if lightningE then lightningE.Rate = 0 end
        if runeGlowE then runeGlowE.Rate = 0 end
        if magicRingE then magicRingE.Rate = 0 end
        if smokeTrailE then smokeTrailE.Rate = 0 end
        if emberE then emberE.Rate = 0 end
        if bubbleSound then TweenService:Create(bubbleSound, TweenInfo.new(1), { Volume = 0 }):Play() end
        if rumbleSound then TweenService:Create(rumbleSound, TweenInfo.new(0.5), { Volume = 0 }):Play() end
    end)
    task.delay(3.0, function()
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
    if originalCauldronCFrame and cauldron then
        cauldron.CFrame = originalCauldronCFrame
    end
    originalCauldronCFrame = nil
    resetCameraShake()
    if bubbleSound and bubbleSound.IsPlaying then bubbleSound:Stop() end
    if rumbleSound and rumbleSound.IsPlaying then rumbleSound:Stop() end
    cleanupSounds()
end

-- === MAIN BREW ANIMATION LOOP ===
local function runBrewAnimation(duration, endUnix, rarity)
    if not getShopRefs() then return end
    setupEmitters()
    setupSounds()
    isAnimating = true

    if cauldron then
        originalCauldronCFrame = cauldron.CFrame
    end

    if cauldronLiquid and not cauldronLiquid:GetAttribute("OriginalSize") then
        cauldronLiquid:SetAttribute("OriginalSize", cauldronLiquid.Size)
    end

    startSpoonOrbit()

    local multMap = { Common = 1, Uncommon = 1.8, Rare = 3.2, Mythic = 5.6, Divine = 8.5 }
    local mult = multMap[rarity] or 1

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

print("[BrewVFXController] Initialized (MAXIMUM DRAMA VFX)")
