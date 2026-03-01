-- GameController: Master client-side controller
-- Handles: zone nav, proximity prompts, GUI toggling, data updates

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local Remotes = RS:WaitForChild("Remotes")
local Ingredients = require(RS:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("Ingredients"))
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
    
    for i, offer in ipairs(marketState.Offers) do
        local item = Instance.new("Frame")
        item.Name = "Offer_" .. offer.ingredientId
        item.Size = UDim2.new(1, 0, 0, 55)
        item.BackgroundColor3 = Color3.fromRGB(50, 40, 55)
        item.LayoutOrder = i
        item.Parent = list
        Instance.new("UICorner", item).CornerRadius = UDim.new(0, 8)
        
        -- Name + tier
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(0.5, -5, 0, 25)
        nameLabel.Position = UDim2.new(0, 10, 0, 5)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = offer.name
        nameLabel.TextColor3 = Color3.new(1, 1, 1)
        nameLabel.TextScaled = true
        nameLabel.Font = Enum.Font.GothamBold
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.Parent = item
        
        local tierLabel = Instance.new("TextLabel")
        tierLabel.Size = UDim2.new(0.5, -5, 0, 20)
        tierLabel.Position = UDim2.new(0, 10, 0, 30)
        tierLabel.BackgroundTransparency = 1
        tierLabel.Text = offer.tier .. " | " .. offer.element
        tierLabel.TextColor3 = Color3.fromRGB(180, 160, 200)
        tierLabel.TextScaled = true
        tierLabel.Font = Enum.Font.Gotham
        tierLabel.TextXAlignment = Enum.TextXAlignment.Left
        tierLabel.Parent = item
        
        -- Price + stock
        local priceLabel = Instance.new("TextLabel")
        priceLabel.Size = UDim2.new(0, 80, 0, 25)
        priceLabel.Position = UDim2.new(0.5, 0, 0, 5)
        priceLabel.BackgroundTransparency = 1
        priceLabel.Text = tostring(offer.price) .. " coins"
        priceLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
        priceLabel.TextScaled = true
        priceLabel.Font = Enum.Font.Gotham
        priceLabel.Parent = item
        
        local stockLabel = Instance.new("TextLabel")
        stockLabel.Name = "StockLabel"
        stockLabel.Size = UDim2.new(0, 80, 0, 20)
        stockLabel.Position = UDim2.new(0.5, 0, 0, 30)
        stockLabel.BackgroundTransparency = 1
        stockLabel.Text = "Stock: " .. tostring(offer.stock)
        stockLabel.TextColor3 = Color3.fromRGB(150, 150, 160)
        stockLabel.TextScaled = true
        stockLabel.Font = Enum.Font.Gotham
        stockLabel.Parent = item
        
        -- Buy button
        local buyBtn = Instance.new("TextButton")
        buyBtn.Name = "BuyBtn"
        buyBtn.Size = UDim2.new(0, 70, 0, 35)
        buyBtn.Position = UDim2.new(1, -80, 0, 10)
        buyBtn.BackgroundColor3 = Color3.fromRGB(60, 140, 60)
        buyBtn.Text = "Buy"
        buyBtn.TextColor3 = Color3.new(1, 1, 1)
        buyBtn.TextScaled = true
        buyBtn.Font = Enum.Font.GothamBold
        buyBtn.Parent = item
        Instance.new("UICorner", buyBtn).CornerRadius = UDim.new(0, 8)
        
        buyBtn.MouseButton1Click:Connect(function()
            Remotes.BuyIngredient:FireServer(offer.ingredientId, 1)
            -- Update stock locally for responsiveness
            offer.stock = math.max(0, offer.stock - 1)
            stockLabel.Text = "Stock: " .. tostring(offer.stock)
            if offer.stock <= 0 then
                buyBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
                buyBtn.Text = "Out"
            end
        end)
        
        if offer.stock <= 0 then
            buyBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
            buyBtn.Text = "Out"
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

print("[GameController] Market wired")

