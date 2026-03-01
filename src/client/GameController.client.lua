-- GameController: Master client-side controller
-- Handles: zone nav, proximity prompts, GUI toggling, data updates

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local Remotes = RS:WaitForChild("Remotes")
local Ingredients = require(RS:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("Ingredients"))

local IngredientVisualFactory = require(script.Parent:WaitForChild('IngredientVisualFactory'))
local Potions = require(RS.Shared.Config:WaitForChild("Potions"))
local Recipes = require(RS.Shared.Config:WaitForChild("Recipes"))

-- Wait for GUIs
local hudGui = playerGui:WaitForChild("HudGui")
local topNav = playerGui:WaitForChild("TopBarNavGui")
local marketGui = playerGui:WaitForChild("MarketGui")
local cauldronGui = playerGui:WaitForChild("CauldronGui")
local sellGui = playerGui:WaitForChild("SellGui")
local recipeBookGui = playerGui:WaitForChild("RecipeBookGui")

-- Player data cache
local myData = nil

-- ========== UTILITY ==========
local function closeAllGuis()
    marketGui.Enabled = false
    cauldronGui.Enabled = false
    sellGui.Enabled = false
    recipeBookGui.Enabled = false
end

local function showCoinNotification(amount)
    local notif = hudGui.CoinNotification
    local sign = amount > 0 and "+" or ""
    notif.Text = sign .. tostring(amount) .. " coins"
    notif.TextColor3 = amount > 0 and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(255, 100, 100)
    notif.Visible = true
    task.delay(1.5, function()
        notif.Visible = false
    end)
end

-- ========== DATA UPDATES ==========
local function updateHud()
    if myData then
        hudGui.CoinFrame.CoinLabel.Text = tostring(myData.Coins)
    end
end

Remotes.PlayerDataUpdate.OnClientEvent:Connect(function(data)
    local oldCoins = myData and myData.Coins or data.Coins
    myData = data
    updateHud()
    
    -- Show coin change notification
    local diff = data.Coins - oldCoins
    if diff ~= 0 then
        showCoinNotification(diff)
    end
end)

-- Request initial data
task.spawn(function()
    myData = Remotes.GetPlayerData:InvokeServer()
    updateHud()
end)

-- ========== ZONE NAVIGATION ==========
local function teleportToZone(zoneName)
    local zones = workspace:FindFirstChild("Zones")
    if not zones then return end
    local zone = zones:FindFirstChild(zoneName)
    if not zone then return end
    local spawnPt = zone:FindFirstChild("SpawnPoint")
    if not spawnPt then return end
    
    local character = player.Character
    if character then
        local hrp = character:FindFirstChild("HumanoidRootPart")
        if hrp then
            closeAllGuis()
            hrp.CFrame = spawnPt.CFrame
        end
    end
end

-- Wire up nav buttons
local navContainer = topNav.NavContainer
for _, btn in ipairs(navContainer:GetChildren()) do
    if btn:IsA("TextButton") then
        local zoneName = btn.Name:gsub("Nav_", "")
        btn.MouseButton1Click:Connect(function()
            teleportToZone(zoneName)
        end)
    end
end

-- ========== MARKET GUI ==========
local marketState = nil

local function refreshMarketUI()
    if not marketState then return end
    local list = marketGui.MainFrame.IngredientList
    
    -- Clear existing items
    for _, child in ipairs(list:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end
    
    -- Element background tints
    local elementTints = {
        Fire =   Color3.fromRGB(60, 30, 25),
        Water =  Color3.fromRGB(25, 35, 60),
        Earth =  Color3.fromRGB(45, 35, 25),
        Air =    Color3.fromRGB(35, 45, 55),
        Shadow = Color3.fromRGB(35, 25, 50),
        Light =  Color3.fromRGB(55, 50, 30),
    }
    
    -- Rarity border colors
    local rarityBorderColors = {
        Common =   Color3.fromRGB(100, 100, 100),
        Uncommon = Color3.fromRGB(60, 140, 220),
        Rare =     Color3.fromRGB(255, 200, 50),
        Mythic =   Color3.fromRGB(200, 80, 255),
        Divine =   Color3.fromRGB(255, 255, 220),
    }
    
    for i, offer in ipairs(marketState.Offers) do
        local ingData = Ingredients.Data[offer.ingredientId]
        local element = offer.element or "Earth"
        local tier = offer.tier or "Common"
        
        -- Card frame with element-colored background
        local card = Instance.new("Frame")
        card.Name = "Offer_" .. offer.ingredientId
        card.Size = UDim2.new(1, 0, 0, 80)
        card.BackgroundColor3 = elementTints[element] or Color3.fromRGB(40, 35, 45)
        card.LayoutOrder = i
        card.Parent = list
        Instance.new("UICorner", card).CornerRadius = UDim.new(0, 10)
        
        -- Rarity border
        local borderColor = rarityBorderColors[tier] or rarityBorderColors.Common
        local stroke = Instance.new("UIStroke")
        stroke.Color = borderColor
        stroke.Thickness = tier == "Common" and 1 or (tier == "Uncommon" and 2 or 3)
        stroke.Parent = card
        
        -- ViewportFrame for 3D ingredient preview
        local viewport = Instance.new("ViewportFrame")
        viewport.Size = UDim2.new(0, 60, 0, 60)
        viewport.Position = UDim2.new(0, 10, 0, 10)
        viewport.BackgroundTransparency = 1
        viewport.Parent = card
        Instance.new("UICorner", viewport).CornerRadius = UDim.new(0, 8)
        
        -- Render ingredient model in viewport
        if ingData and IngredientVisualFactory then
            pcall(function()
                IngredientVisualFactory.renderInViewport(ingData, viewport)
            end)
        end
        
        -- Name label
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(0.5, -80, 0, 22)
        nameLabel.Position = UDim2.new(0, 80, 0, 5)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = offer.name
        nameLabel.TextColor3 = Color3.new(1, 1, 1)
        nameLabel.TextScaled = true
        nameLabel.Font = Enum.Font.GothamBold
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.Parent = card
        
        -- Tier + Element label
        local tierLabel = Instance.new("TextLabel")
        tierLabel.Size = UDim2.new(0.4, -80, 0, 18)
        tierLabel.Position = UDim2.new(0, 80, 0, 28)
        tierLabel.BackgroundTransparency = 1
        tierLabel.Text = tier .. " | " .. element
        tierLabel.TextColor3 = borderColor
        tierLabel.TextScaled = true
        tierLabel.Font = Enum.Font.Gotham
        tierLabel.TextXAlignment = Enum.TextXAlignment.Left
        tierLabel.Parent = card
        
        -- Price + stock
        local priceLabel = Instance.new("TextLabel")
        priceLabel.Size = UDim2.new(0, 100, 0, 20)
        priceLabel.Position = UDim2.new(0, 80, 0, 50)
        priceLabel.BackgroundTransparency = 1
        priceLabel.Text = tostring(offer.price) .. " coins  |  Stock: " .. tostring(offer.stock)
        priceLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
        priceLabel.TextScaled = true
        priceLabel.Font = Enum.Font.Gotham
        priceLabel.TextXAlignment = Enum.TextXAlignment.Left
        priceLabel.Parent = card
        
        -- Buy button
        local buyBtn = Instance.new("TextButton")
        buyBtn.Name = "BuyBtn"
        buyBtn.Size = UDim2.new(0, 65, 0, 50)
        buyBtn.Position = UDim2.new(1, -75, 0, 15)
        buyBtn.BackgroundColor3 = Color3.fromRGB(50, 130, 50)
        buyBtn.Text = "Buy"
        buyBtn.TextColor3 = Color3.new(1, 1, 1)
        buyBtn.TextScaled = true
        buyBtn.Font = Enum.Font.GothamBold
        buyBtn.Parent = card
        Instance.new("UICorner", buyBtn).CornerRadius = UDim.new(0, 8)
        
        buyBtn.MouseButton1Click:Connect(function()
            Remotes.BuyIngredient:FireServer(offer.ingredientId, 1)
            offer.stock = math.max(0, offer.stock - 1)
            priceLabel.Text = tostring(offer.price) .. " coins  |  Stock: " .. tostring(offer.stock)
            if offer.stock <= 0 then
                buyBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
                buyBtn.Text = "Out"
            end
        end)
        
        if offer.stock <= 0 then
            buyBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
            buyBtn.Text = "Out"
        end
        
        -- Rarity badge for Rare+
        if tier == "Rare" or tier == "Mythic" or tier == "Divine" then
            local badge = Instance.new("TextLabel")
            badge.Size = UDim2.new(0, 60, 0, 18)
            badge.Position = UDim2.new(1, -140, 0, 3)
            badge.BackgroundColor3 = borderColor
            badge.Text = tier == "Divine" and "DIVINE!" or (tier == "Mythic" and "MYTHIC!" or "RARE!")
            badge.TextColor3 = tier == "Divine" and Color3.fromRGB(50, 50, 50) or Color3.new(1, 1, 1)
            badge.TextScaled = true
            badge.Font = Enum.Font.GothamBlack
            badge.Parent = card
            Instance.new("UICorner", badge).CornerRadius = UDim.new(0, 6)
        end
    end
end

-- Market refresh timer
local function updateMarketTimer()
    if not marketState then return end
    local remaining = marketState.RefreshTime - os.time()
    if remaining < 0 then remaining = 0 end
    local mins = math.floor(remaining / 60)
    local secs = remaining % 60
    marketGui.MainFrame.RefreshTimer.Text = string.format("Next refresh: %d:%02d", mins, secs)
end

-- Listen for market refresh
Remotes.MarketRefresh.OnClientEvent:Connect(function(state)
    marketState = state
    refreshMarketUI()
end)

-- Fetch initial market state
task.spawn(function()
    marketState = Remotes.GetMarketOffers:InvokeServer()
    refreshMarketUI()
end)

-- Timer update loop
task.spawn(function()
    while true do
        updateMarketTimer()
        task.wait(1)
    end
end)

-- Close button
marketGui.MainFrame.TitleBar.CloseBtn.MouseButton1Click:Connect(function()
    marketGui.Enabled = false
end)


-- ========== BREW TIMER HUD WIDGET ==========
local brewTimerWidget = hudGui:WaitForChild("BrewTimerWidget")
local brewTimerConnection = nil

local function updateBrewTimerHUD()
    local state = Remotes.GetActiveBrewState:InvokeServer()
    if state and (state.status == "brewing" or state.status == "completed_unclaimed") then
        brewTimerWidget.Visible = true
        local now = os.time()
        local duration = state.endUnix - state.startUnix
        local remaining = math.max(0, state.endUnix - now)
        local pct = math.clamp(1 - remaining / duration, 0, 1)
        
        local fill = brewTimerWidget.ProgressBg.Fill
        fill.Size = UDim2.new(pct, 0, 1, 0)
        fill.BackgroundColor3 = Color3.new(0.3 + pct * 0.7, 0.8 - pct * 0.3, 0.5 - pct * 0.3)
        
        local mins = math.floor(remaining / 60)
        local secs = remaining % 60
        brewTimerWidget.Countdown.Text = string.format("%d:%02d", mins, secs)
        
        if state.status == "completed_unclaimed" then
            brewTimerWidget.PotionName.Text = "Brew Ready! Tap to claim"
            brewTimerWidget.Countdown.Text = "DONE!"
            fill.Size = UDim2.new(1, 0, 1, 0)
            fill.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
        end
    else
        brewTimerWidget.Visible = false
    end
end

-- Click brew timer widget to open cauldron GUI
brewTimerWidget.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        -- Trigger cauldron interaction
        local cauldronGui = playerGui:FindFirstChild("CauldronGui")
        if cauldronGui then
            cauldronGui.Enabled = true
        end
    end
end)

-- Poll brew state every 2 seconds for HUD
task.spawn(function()
    while true do
        task.wait(2)
        pcall(updateBrewTimerHUD)
    end
end)

-- ========== SCORE HUD ==========
local scoreFrame = hudGui:FindFirstChild("ScoreFrame")

Remotes.PlayerDataUpdate.OnClientEvent:Connect(function(data)
    if data and scoreFrame then
        local score = data.Score and data.Score.CompositeScore or 0
        scoreFrame.ScoreLabel.Text = tostring(score)
    end
end)

print("[GameController] Market wired")
