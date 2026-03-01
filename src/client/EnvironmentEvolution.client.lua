-- EnvironmentEvolution: Shows/hides cauldron environment tiers based on BrewStats
local RS = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Remotes = RS.Remotes

local player = game.Players.LocalPlayer
local currentTier = -1

-- Tier thresholds
local TIERS = {
    { threshold = 0,   tier = 0 },
    { threshold = 10,  tier = 1 },
    { threshold = 25,  tier = 2 },
    { threshold = 50,  tier = 3 },
    { threshold = 100, tier = 4 },
}

local function getTierForCount(totalBrewed)
    local t = 0
    for _, info in ipairs(TIERS) do
        if totalBrewed >= info.threshold then
            t = info.tier
        end
    end
    return t
end

local function getEvolutionFolder()
    local shop = workspace:FindFirstChild("Zones") and workspace.Zones:FindFirstChild("YourShop")
    if not shop then return nil end
    return shop:FindFirstChild("EvolutionTiers")
end

-- Fade in parts in a folder
local function fadeInFolder(folder, duration)
    if not folder then return end
    for _, d in ipairs(folder:GetDescendants()) do
        if d:IsA("BasePart") and d.Transparency == 1 then
            TweenService:Create(d, TweenInfo.new(duration, Enum.EasingStyle.Quad), { Transparency = 0.1 }):Play()
        end
        if d:IsA("PointLight") and d.Brightness == 0 then
            TweenService:Create(d, TweenInfo.new(duration, Enum.EasingStyle.Quad), { Brightness = 1.5 }):Play()
        end
        if d:IsA("ParticleEmitter") and d.Rate == 0 then
            -- Can't tween Rate, set directly after delay
            task.delay(duration * 0.5, function()
                if d.Name == "ArcaneMotes" then d.Rate = 8
                elseif d.Name == "FloatingRunes" then d.Rate = 4
                else d.Rate = 5 end
            end)
        end
        if d:IsA("Sound") and d.Volume == 0 then
            d.Playing = true
            TweenService:Create(d, TweenInfo.new(duration, Enum.EasingStyle.Quad), { Volume = 0.15 }):Play()
        end
    end
end

-- Hide parts in a folder
local function hideFolder(folder)
    if not folder then return end
    for _, d in ipairs(folder:GetDescendants()) do
        if d:IsA("BasePart") then d.Transparency = 1 end
        if d:IsA("PointLight") then d.Brightness = 0 end
        if d:IsA("ParticleEmitter") then d.Rate = 0 end
        if d:IsA("Sound") then d.Volume = 0; d.Playing = false end
    end
end

-- Apply tier visuals
local function applyTier(tier, animated)
    local folder = getEvolutionFolder()
    if not folder then return end
    
    local duration = animated and 2 or 0
    
    -- Tier 1: Rune Circle
    local t1 = folder:FindFirstChild("Tier1_RuneCircle")
    if tier >= 1 then
        fadeInFolder(t1, duration)
    else
        hideFolder(t1)
    end
    
    -- Tier 2: Floating Jars
    local t2 = folder:FindFirstChild("Tier2_FloatingJars")
    if tier >= 2 then
        fadeInFolder(t2, duration)
        -- Start orbit animation for jars
        task.spawn(function()
            local jars = {}
            for _, j in ipairs(t2:GetChildren()) do
                if j:IsA("BasePart") then table.insert(jars, j) end
            end
            local cauldron = workspace.Zones.YourShop:FindFirstChild("Cauldron")
            if not cauldron then return end
            local center = cauldron.Position + Vector3.new(0, 5, 0)
            local radius = 3
            while tier >= 2 do
                for i, jar in ipairs(jars) do
                    if jar.Transparency < 1 then
                        local angle = (tick() * 0.5) + (i - 1) * (2 * math.pi / #jars)
                        local x = center.X + math.cos(angle) * radius
                        local z = center.Z + math.sin(angle) * radius
                        local y = center.Y + math.sin(tick() + i) * 0.5
                        jar.Position = Vector3.new(x, y, z)
                    end
                end
                task.wait()
            end
        end)
    else
        hideFolder(t2)
    end
    
    -- Tier 3: Crystals
    local t3 = folder:FindFirstChild("Tier3_Crystals")
    if tier >= 3 then
        fadeInFolder(t3, duration)
    else
        hideFolder(t3)
    end
    
    -- Tier 4: Enchanted Aura
    local t4 = folder:FindFirstChild("Tier4_EnchantedAura")
    if tier >= 4 then
        fadeInFolder(t4, duration)
    else
        hideFolder(t4)
    end
end

-- Listen for data updates to check tier changes
Remotes.PlayerDataUpdate.OnClientEvent:Connect(function(data)
    if data and data.BrewStats then
        local newTier = getTierForCount(data.BrewStats.TotalBrewed or 0)
        if newTier ~= currentTier then
            local animated = currentTier >= 0 -- animate if not first load
            currentTier = newTier
            applyTier(newTier, animated)
        end
    end
end)

-- Initial load
task.spawn(function()
    task.wait(3) -- let data load
    local data = Remotes.GetPlayerData:InvokeServer()
    if data and data.BrewStats then
        currentTier = getTierForCount(data.BrewStats.TotalBrewed or 0)
        applyTier(currentTier, false)
    end
end)

print("[EnvironmentEvolution] Initialized")

