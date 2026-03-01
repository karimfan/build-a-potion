-- BrewVFXController: Orchestrates world VFX during brewing
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Remotes = RS.Remotes

local player = game.Players.LocalPlayer

-- References (resolved at runtime)
local cauldron = nil
local cauldronLiquid = nil
local spoon = nil
local cauldronGlow = nil

local isAnimating = false
local vfxConnection = nil
local spoonTween = nil

-- Stage-specific particle emitters (created dynamically)
local stageEmitters = {}

local function getShopRefs()
    local shop = workspace:FindFirstChild("Zones") and workspace.Zones:FindFirstChild("YourShop")
    if not shop then return false end
    cauldron = shop:FindFirstChild("Cauldron")
    cauldronLiquid = shop:FindFirstChild("CauldronLiquid")
    spoon = shop:FindFirstChild("BrewingSpoon")
    if cauldron then
        cauldronGlow = cauldron:FindFirstChild("CauldronGlow")
    end
    return cauldron ~= nil
end

-- Show/hide spoon
local function setSpoonVisible(visible)
    if not spoon then return end
    for _, d in ipairs(spoon:GetDescendants()) do
        if d:IsA("BasePart") then
            d.Transparency = visible and 0 or 1
        end
    end
end

-- Animate spoon orbiting above cauldron
local function startSpoonOrbit()
    if not spoon or not cauldron then return end
    setSpoonVisible(true)
    local center = cauldron.Position + Vector3.new(0, 3.5, 0)
    local radius = 1.5
    local speed = 1.5 -- radians per second
    
    local angle = 0
    if vfxConnection then vfxConnection:Disconnect() end
    vfxConnection = RunService.Heartbeat:Connect(function(dt)
        if not isAnimating then return end
        angle = angle + speed * dt
        local x = center.X + math.cos(angle) * radius
        local z = center.Z + math.sin(angle) * radius
        local y = center.Y + math.sin(angle * 2) * 0.3 -- gentle bob
        spoon:PivotTo(CFrame.new(x, y, z) * CFrame.Angles(0, -angle, math.rad(30)))
    end)
end

local function stopSpoonOrbit()
    if vfxConnection then
        vfxConnection:Disconnect()
        vfxConnection = nil
    end
    setSpoonVisible(false)
end

-- Create stage particle emitters
local function createStageEmitter(name, parent, config)
    local emitter = Instance.new("ParticleEmitter")
    emitter.Name = "BrewVFX_" .. name
    emitter.Color = config.color or ColorSequence.new(Color3.new(1,1,1))
    emitter.Size = config.size or NumberSequence.new(0.5)
    emitter.Lifetime = config.lifetime or NumberRange.new(1, 2)
    emitter.Rate = 0 -- start disabled
    emitter.Speed = config.speed or NumberRange.new(1, 3)
    emitter.SpreadAngle = config.spread or Vector2.new(15, 15)
    emitter.Transparency = config.transparency or NumberSequence.new(0, 1)
    emitter.LightEmission = config.lightEmission or 0.5
    emitter.Parent = parent
    table.insert(stageEmitters, emitter)
    return emitter
end

-- Setup all stage emitters on cauldron
local steamEmitter, sparkEmitter, fireEmitter, fireworkEmitter

local function setupEmitters()
    if not cauldron then return end
    -- Clean old ones
    for _, e in ipairs(stageEmitters) do
        if e and e.Parent then e:Destroy() end
    end
    stageEmitters = {}
    
    -- Steam (stage 1: 0-25%)
    steamEmitter = createStageEmitter("Steam", cauldron, {
        color = ColorSequence.new(Color3.fromRGB(200, 220, 255)),
        size = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.3),
            NumberSequenceKeypoint.new(1, 2)
        }),
        lifetime = NumberRange.new(2, 4),
        speed = NumberRange.new(1, 3),
        spread = Vector2.new(20, 20),
        transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.4),
            NumberSequenceKeypoint.new(1, 1)
        }),
        lightEmission = 0.3,
    })
    
    -- Sparks (stage 2: 25-50%)
    sparkEmitter = createStageEmitter("Sparks", cauldron, {
        color = ColorSequence.new(Color3.fromRGB(255, 200, 50), Color3.fromRGB(255, 100, 0)),
        size = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.1),
            NumberSequenceKeypoint.new(0.5, 0.2),
            NumberSequenceKeypoint.new(1, 0)
        }),
        lifetime = NumberRange.new(0.5, 1.5),
        speed = NumberRange.new(3, 8),
        spread = Vector2.new(40, 40),
        transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0),
            NumberSequenceKeypoint.new(1, 1)
        }),
        lightEmission = 1,
    })
    
    -- Fire bursts (stage 3: 50-75%)
    fireEmitter = createStageEmitter("Fire", cauldron, {
        color = ColorSequence.new(Color3.fromRGB(255, 150, 0), Color3.fromRGB(255, 50, 0)),
        size = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.3),
            NumberSequenceKeypoint.new(0.5, 0.8),
            NumberSequenceKeypoint.new(1, 0)
        }),
        lifetime = NumberRange.new(0.3, 1),
        speed = NumberRange.new(2, 6),
        spread = Vector2.new(30, 30),
        transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0),
            NumberSequenceKeypoint.new(0.5, 0.3),
            NumberSequenceKeypoint.new(1, 1)
        }),
        lightEmission = 1,
    })
    
    -- Fireworks (completion: 100%)
    fireworkEmitter = createStageEmitter("Fireworks", cauldron, {
        color = ColorSequence.new(Color3.fromRGB(100, 200, 255), Color3.fromRGB(255, 215, 0)),
        size = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.2),
            NumberSequenceKeypoint.new(0.3, 0.5),
            NumberSequenceKeypoint.new(1, 0)
        }),
        lifetime = NumberRange.new(1, 3),
        speed = NumberRange.new(10, 20),
        spread = Vector2.new(60, 60),
        transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0),
            NumberSequenceKeypoint.new(0.5, 0),
            NumberSequenceKeypoint.new(1, 1)
        }),
        lightEmission = 1,
    })
end

-- Update VFX based on brew progress percentage
local function updateBrewVFX(pct, rarity)
    local mult = 1
    local mults = { Common = 1, Uncommon = 1.3, Rare = 1.8, Mythic = 2.5 }
    mult = mults[rarity] or 1
    
    -- Existing ambient bubbles - intensify
    local ambientBubbles = cauldron and cauldron:FindFirstChild("CauldronBubbles")
    if ambientBubbles then
        ambientBubbles.Rate = 8 + pct * 20 * mult
    end
    
    -- Glow expansion
    if cauldronGlow then
        cauldronGlow.Range = 20 + pct * 20 * mult
        cauldronGlow.Brightness = 2 + pct * 3 * mult
    end
    
    -- Stage 1: Steam (0-100%, intensifies)
    if steamEmitter then
        steamEmitter.Rate = 3 + pct * 10 * mult
    end
    
    -- Stage 2: Sparks (25%+)
    if sparkEmitter then
        sparkEmitter.Rate = pct >= 0.25 and (5 + (pct - 0.25) * 20 * mult) or 0
    end
    
    -- Stage 3: Fire (50%+)
    if fireEmitter then
        fireEmitter.Rate = pct >= 0.5 and (3 + (pct - 0.5) * 15 * mult) or 0
    end
end

-- Completion burst
local function playCompletionBurst(rarity)
    local mult = ({ Common = 1, Uncommon = 1.5, Rare = 2, Mythic = 3 })[rarity] or 1
    
    -- Fireworks burst
    if fireworkEmitter then
        fireworkEmitter.Rate = 50 * mult
        task.delay(0.5, function()
            if fireworkEmitter then fireworkEmitter.Rate = 0 end
        end)
    end
    
    -- Flash the glow
    if cauldronGlow then
        cauldronGlow.Range = 60
        cauldronGlow.Brightness = 8
        task.delay(0.3, function()
            if cauldronGlow then
                cauldronGlow.Range = 20
                cauldronGlow.Brightness = 2
            end
        end)
    end
    
    -- All sparks burst
    if sparkEmitter then
        sparkEmitter.Rate = 40 * mult
        task.delay(0.3, function()
            if sparkEmitter then sparkEmitter.Rate = 0 end
        end)
    end
end

-- Reset all VFX to ambient state
local function resetVFX()
    for _, e in ipairs(stageEmitters) do
        if e and e.Parent then e.Rate = 0 end
    end
    local ambientBubbles = cauldron and cauldron:FindFirstChild("CauldronBubbles")
    if ambientBubbles then ambientBubbles.Rate = 8 end
    if cauldronGlow then
        cauldronGlow.Range = 20
        cauldronGlow.Brightness = 2
    end
end

-- ===== PUBLIC BREW VFX ORCHESTRATION =====
-- Listen for brew state changes via a BindableEvent or polling

local function pollBrewState()
    while true do
        task.wait(0.5)
        if not getShopRefs() then continue end
        
        local state = Remotes.GetActiveBrewState:InvokeServer()
        if state and state.status == "brewing" then
            if not isAnimating then
                -- Brew just started (or we reconnected)
                isAnimating = true
                setupEmitters()
                startSpoonOrbit()
            end
            
            local now = os.time()
            local duration = state.endUnix - state.startUnix
            local elapsed = now - state.startUnix
            local pct = math.clamp(elapsed / duration, 0, 1)
            
            updateBrewVFX(pct, nil) -- rarity not available from state, use default
            
            if pct >= 1 then
                playCompletionBurst("Common")
                task.wait(1)
                isAnimating = false
                stopSpoonOrbit()
                resetVFX()
            end
        elseif isAnimating then
            -- Brew ended
            playCompletionBurst("Common")
            task.wait(1)
            isAnimating = false
            stopSpoonOrbit()
            resetVFX()
        end
    end
end

-- Start polling
task.spawn(function()
    task.wait(3) -- let everything load
    getShopRefs()
    setupEmitters()
    pollBrewState()
end)

print("[BrewVFXController] Initialized")

