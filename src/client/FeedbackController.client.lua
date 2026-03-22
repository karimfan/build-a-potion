-- FeedbackController: Visual feedback for all game actions
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local Remotes = RS:WaitForChild("Remotes")
local Ingredients = require(RS.Shared.Config.Ingredients)
local Potions = require(RS.Shared.Config.Potions)

local feedbackGui = playerGui:WaitForChild("FeedbackGui")
local popupContainer = feedbackGui:WaitForChild("PopupContainer")
local discoveryBanner = feedbackGui:WaitForChild("DiscoveryBanner")
local zoneNotif = feedbackGui:WaitForChild("ZoneNotification")

-- ========== FLOATING TEXT POPUP ==========
local function showPopup(text, color, yOffset)
    yOffset = yOffset or 0
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0, 300, 0, 40)
    label.Position = UDim2.new(0.5, -150, 0.45 + yOffset, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = color or Color3.new(1, 1, 1)
    label.TextStrokeTransparency = 0.3
    label.TextStrokeColor3 = Color3.new(0, 0, 0)
    label.TextScaled = true
    label.Font = Enum.Font.GothamBold
    label.ZIndex = 15
    label.Parent = popupContainer
    
    -- Animate: float up and fade out
    local tweenInfo = TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local tween = TweenService:Create(label, tweenInfo, {
        Position = UDim2.new(0.5, -150, 0.3 + yOffset, 0),
        TextTransparency = 1,
        TextStrokeTransparency = 1,
    })
    tween:Play()
    tween.Completed:Connect(function()
        label:Destroy()
    end)
end

-- ========== DISCOVERY BANNER ==========
local function showDiscoveryBanner(potionName, sellValue)
    discoveryBanner.Detail.Text = potionName .. " — Worth " .. sellValue .. " coins!"
    discoveryBanner.Visible = true
    discoveryBanner.BackgroundTransparency = 0.1
    
    -- Flash effect
    local flash = TweenService:Create(discoveryBanner, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
        BackgroundTransparency = 0,
    })
    flash:Play()
    flash.Completed:Connect(function()
        TweenService:Create(discoveryBanner, TweenInfo.new(0.3), {BackgroundTransparency = 0.1}):Play()
    end)
    
    -- Hide after 3 seconds
    task.delay(3, function()
        local fadeOut = TweenService:Create(discoveryBanner, TweenInfo.new(0.5), {
            BackgroundTransparency = 1,
        })
        fadeOut:Play()
        fadeOut.Completed:Connect(function()
            discoveryBanner.Visible = false
        end)
    end)
end

-- ========== ZONE NOTIFICATION ==========
local function showZoneArrival(zoneName)
    local displayNames = {
        YourShop = "My Shop",
        IngredientMarket = "Ingredient Market",
        TradingPost = "Trading Post",
        WildGrove = "Wild Grove",
    }
    local name = displayNames[zoneName] or zoneName
    zoneNotif.Text = "— " .. name .. " —"
    zoneNotif.TextTransparency = 0
    zoneNotif.Visible = true
    
    task.delay(2, function()
        local fade = TweenService:Create(zoneNotif, TweenInfo.new(1), {
            TextTransparency = 1,
        })
        fade:Play()
        fade.Completed:Connect(function()
            zoneNotif.Visible = false
        end)
    end)
end

-- ========== LISTEN FOR DATA CHANGES ==========
local prevData = nil
local Recipes = require(RS.Shared.Config.Recipes)

local function getIngredientTotal(entry)
    if type(entry) == "number" then
        return entry
    end
    if type(entry) ~= "table" or not entry.stacks then
        return 0
    end
    local total = 0
    for _, stack in ipairs(entry.stacks) do
        total = total + (stack.amount or 0)
    end
    return total
end

Remotes.PlayerDataUpdate.OnClientEvent:Connect(function(newData)
    if prevData then
        -- Detect what changed
        local coinDiff = newData.Coins - prevData.Coins
        
        if coinDiff > 0 then
            showPopup("+" .. coinDiff .. " coins", Color3.fromRGB(255, 215, 0))
        elseif coinDiff < 0 then
            showPopup(coinDiff .. " coins", Color3.fromRGB(255, 150, 150), 0.02)
        end
        
        -- Detect new ingredients
        for id, entry in pairs(newData.Ingredients or {}) do
            local qty = getIngredientTotal(entry)
            local oldQty = (prevData.Ingredients and prevData.Ingredients[id]) or 0
            if qty > oldQty then
                local ing = Ingredients.Data[id]
                local name = ing and ing.name or id
                showPopup("+" .. (qty - oldQty) .. " " .. name, Color3.fromRGB(100, 255, 150), 0.05)
            end
        end
        
        -- Detect new potions
        for id, qty in pairs(newData.Potions or {}) do
            local oldQty = (prevData.Potions and prevData.Potions[id]) or 0
            if qty > oldQty then
                local baseId = id
                local sep = id:find("__")
                if sep then
                    baseId = id:sub(1, sep - 1)
                end
                local potion = Potions.Data[baseId]
                local name = potion and potion.name or id
                local color = Color3.fromRGB(150, 200, 255)
                if id == "sludge" then
                    color = Color3.fromRGB(150, 150, 100)
                end
                -- Potion brew feedback removed (was showing over player)
            end
        end
        
        -- Detect new recipe discoveries
        for key, _ in pairs(newData.DiscoveredRecipes or {}) do
            if not prevData.DiscoveredRecipes[key] then
                -- Find the potion name for this recipe
                local potionId = Recipes.Data[key]
                if potionId then
                    local potion = Potions.Data[potionId]
                    if potion then
                        showDiscoveryBanner(potion.name, potion.sellValue)
                    end
                end
            end
        end
    end
    
    prevData = {}
    -- Deep copy
    prevData.Coins = newData.Coins
    prevData.Ingredients = {}
    for k, v in pairs(newData.Ingredients or {}) do
        prevData.Ingredients[k] = getIngredientTotal(v)
    end
    prevData.Potions = {}
    for k, v in pairs(newData.Potions or {}) do prevData.Potions[k] = v end
    prevData.DiscoveredRecipes = {}
    for k, v in pairs(newData.DiscoveredRecipes or {}) do prevData.DiscoveredRecipes[k] = v end
end)

-- ========== ZONE TELEPORT HOOK ==========
-- Listen for character position changes to detect zone arrivals
local lastZone = nil
local function checkZone()
    local char = player.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    local pos = hrp.Position
    local zones = workspace:FindFirstChild("Zones")
    if not zones then return end
    
    local closestZone = nil
    local closestDist = math.huge
    
    for _, zone in ipairs(zones:GetChildren()) do
        if zone:IsA("Model") then
            local floor = zone:FindFirstChild("Floor")
            if floor then
                local dist = (Vector3.new(pos.X, 0, pos.Z) - Vector3.new(floor.Position.X, 0, floor.Position.Z)).Magnitude
                if dist < closestDist then
                    closestDist = dist
                    closestZone = zone.Name
                end
            end
        end
    end
    
    if closestZone and closestZone ~= lastZone then
        lastZone = closestZone
        showZoneArrival(closestZone)
    end
end

task.spawn(function()
    while true do
        checkZone()
        task.wait(0.5)
    end
end)

-- Initialize prevData
task.spawn(function()
    prevData = Remotes.GetPlayerData:InvokeServer()
    if not prevData then
        prevData = {Coins = 0, Ingredients = {}, Potions = {}, DiscoveredRecipes = {}}
    else
        local normalizedIngredients = {}
        for k, v in pairs(prevData.Ingredients or {}) do
            normalizedIngredients[k] = getIngredientTotal(v)
        end
        prevData.Ingredients = normalizedIngredients
    end
end)

-- ========== GLOBAL ANNOUNCEMENTS ==========
local announcementQueue = {}
local isShowingAnnouncement = false

local function showNextAnnouncement()
    if isShowingAnnouncement or #announcementQueue == 0 then return end
    isShowingAnnouncement = true
    local msg = table.remove(announcementQueue, 1)
    
    -- Create announcement banner at top of screen
    local playerGui = game.Players.LocalPlayer:WaitForChild("PlayerGui")
    local banner = Instance.new("ScreenGui")
    banner.Name = "AnnouncementBanner"
    banner.DisplayOrder = 100
    banner.Parent = playerGui
    
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0.6, 0, 0, 40)
    frame.Position = UDim2.new(0.2, 0, 0, -50)
    frame.BackgroundColor3 = Color3.fromRGB(50, 30, 80)
    frame.BackgroundTransparency = 0.1
    frame.Parent = banner
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 12)
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(255, 215, 0)
    stroke.Thickness = 2
    stroke.Parent = frame
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -20, 1, 0)
    label.Position = UDim2.new(0, 10, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = msg
    label.TextColor3 = Color3.fromRGB(255, 215, 100)
    label.TextScaled = true
    label.Font = Enum.Font.GothamBold
    label.Parent = frame
    
    -- Animate slide in
    local TweenService = game:GetService("TweenService")
    TweenService:Create(frame, TweenInfo.new(0.3, Enum.EasingStyle.Back), { Position = UDim2.new(0.2, 0, 0, 10) }):Play()
    
    -- Wait and fade out
    task.delay(4, function()
        TweenService:Create(frame, TweenInfo.new(0.5), { Position = UDim2.new(0.2, 0, 0, -50) }):Play()
        task.delay(0.6, function()
            banner:Destroy()
            isShowingAnnouncement = false
            showNextAnnouncement()
        end)
    end)
end

Remotes.GlobalAnnouncement.OnClientEvent:Connect(function(msg)
    table.insert(announcementQueue, msg)
    if #announcementQueue > 3 then
        table.remove(announcementQueue, 1) -- drop oldest if queue full
    end
    showNextAnnouncement()
end)

print("[FeedbackController] Initialized")
