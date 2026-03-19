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
local inventoryGui = nil  -- created later in INVENTORY GUI section

-- ========== UTILITY ==========
local function closeAllGuis()
    marketGui.Enabled = false
    cauldronGui.Enabled = false
    sellGui.Enabled = false
    recipeBookGui.Enabled = false
    if inventoryGui then inventoryGui.Enabled = false end
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
    if myData and myData.BrewStats and starLabel then
        starLabel.Text = tostring(myData.BrewStats.StarCount or 0)
    end
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

-- Add Arena button if it doesn't exist
if not navContainer:FindFirstChild("Nav_Arena") then
    local arenaBtn = Instance.new("TextButton")
    arenaBtn.Name = "Nav_Arena"
    arenaBtn.Text = "Arena"
    arenaBtn.Size = UDim2.new(0, 85, 0, 26)
    arenaBtn.BackgroundColor3 = Color3.fromRGB(160, 50, 50)
    arenaBtn.TextColor3 = Color3.new(1, 1, 1)
    arenaBtn.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold)
    arenaBtn.TextSize = 13
    arenaBtn.LayoutOrder = 5
    arenaBtn.AutoButtonColor = true
    arenaBtn.BorderSizePixel = 0
    arenaBtn.Parent = navContainer
    local corner = Instance.new("UICorner")
    corner.Parent = arenaBtn
end

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
    
    for _, child in ipairs(list:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end
    
    local elementTints = {
        Fire = Color3.fromRGB(60, 30, 25), Water = Color3.fromRGB(25, 35, 60),
        Earth = Color3.fromRGB(45, 35, 25), Air = Color3.fromRGB(35, 45, 55),
        Shadow = Color3.fromRGB(35, 25, 50), Light = Color3.fromRGB(55, 50, 30),
    }
    local rarityBorderColors = {
        Common = Color3.fromRGB(100, 100, 100), Uncommon = Color3.fromRGB(60, 140, 220),
        Rare = Color3.fromRGB(255, 200, 50), Mythic = Color3.fromRGB(200, 80, 255),
        Divine = Color3.fromRGB(255, 255, 220),
    }
    
    for i, offer in ipairs(marketState.Offers) do
        local ingData = Ingredients.Data[offer.ingredientId]
        local element = offer.element or "Earth"
        local tier = offer.tier or "Common"
        local borderColor = rarityBorderColors[tier] or rarityBorderColors.Common
        
        local card = Instance.new("Frame")
        card.Name = "Offer_" .. offer.ingredientId
        card.Size = UDim2.new(1, 0, 0, 80)
        card.BackgroundColor3 = elementTints[element] or Color3.fromRGB(40, 35, 45)
        card.LayoutOrder = i
        card.Parent = list
        Instance.new("UICorner", card).CornerRadius = UDim.new(0, 10)
        
        local stroke = Instance.new("UIStroke")
        stroke.Color = borderColor
        stroke.Thickness = tier == "Common" and 1 or (tier == "Uncommon" and 2 or 3)
        stroke.Parent = card
        
        -- 3D ViewportFrame preview
        local viewport = Instance.new("ViewportFrame")
        viewport.Size = UDim2.new(0, 65, 0, 65)
        viewport.Position = UDim2.new(0, 8, 0, 8)
        viewport.BackgroundTransparency = 1
        viewport.Parent = card
        Instance.new("UICorner", viewport).CornerRadius = UDim.new(0, 8)
        
        if ingData and IngredientVisualFactory then
            local ok, err = pcall(function()
                IngredientVisualFactory.renderInViewport(ingData, viewport)
            end)
            if not ok then
                warn("[Market] Render failed: " .. tostring(offer.ingredientId) .. " - " .. tostring(err))
            end
        end
        
        -- Name
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(0.45, -80, 0, 22)
        nameLabel.Position = UDim2.new(0, 80, 0, 5)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = offer.name
        nameLabel.TextColor3 = Color3.new(1, 1, 1)
        nameLabel.TextScaled = true
        nameLabel.Font = Enum.Font.GothamBold
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.Parent = card
        
        -- Tier + Element
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
        
        -- Price + Stock
        local priceLabel = Instance.new("TextLabel")
        priceLabel.Size = UDim2.new(0, 140, 0, 18)
        priceLabel.Position = UDim2.new(0, 80, 0, 50)
        priceLabel.BackgroundTransparency = 1
        priceLabel.Text = offer.price .. " coins | Stock: " .. offer.stock
        priceLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
        priceLabel.TextScaled = true
        priceLabel.Font = Enum.Font.Gotham
        priceLabel.TextXAlignment = Enum.TextXAlignment.Left
        priceLabel.Parent = card
        
        -- Buy button
        local buyBtn = Instance.new("TextButton")
        buyBtn.Name = "BuyBtn"
        buyBtn.Size = UDim2.new(0, 60, 0, 50)
        buyBtn.Position = UDim2.new(1, -70, 0, 15)
        buyBtn.BackgroundColor3 = Color3.fromRGB(50, 130, 50)
        buyBtn.Text = "Buy"
        buyBtn.TextColor3 = Color3.new(1, 1, 1)
        buyBtn.TextScaled = true
        buyBtn.Font = Enum.Font.GothamBold
        buyBtn.Parent = card
        Instance.new("UICorner", buyBtn).CornerRadius = UDim.new(0, 8)
        
        buyBtn.MouseButton1Click:Connect(function()
            if offer.stock <= 0 then return end
            buyBtn.Text = "..."
            Remotes.BuyIngredient:FireServer(offer.ingredientId, 1)
            -- Do NOT optimistically decrement stock — wait for server MarketRefresh
        end)
        
        if offer.stock <= 0 then
            buyBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
            buyBtn.Text = "Out"
        end
        
        -- Flash Sale badge (gold, prominent)
        if offer.flashSale then
            local flashBadge = Instance.new("TextLabel")
            flashBadge.Size = UDim2.new(0, 80, 0, 18)
            flashBadge.Position = UDim2.new(1, -145, 0, 2)
            flashBadge.BackgroundColor3 = Color3.fromRGB(255, 200, 50)
            flashBadge.Text = "FLASH SALE"
            flashBadge.TextColor3 = Color3.fromRGB(40, 20, 0)
            flashBadge.TextScaled = true
            flashBadge.Font = Enum.Font.GothamBlack
            flashBadge.Parent = card
            Instance.new("UICorner", flashBadge).CornerRadius = UDim.new(0, 6)
            -- Gold border for flash sale
            stroke.Color = Color3.fromRGB(255, 215, 0)
            stroke.Thickness = 3
        elseif tier == "Rare" or tier == "Mythic" or tier == "Divine" then
            -- Rarity badge
            local badge = Instance.new("TextLabel")
            badge.Size = UDim2.new(0, 55, 0, 16)
            badge.Position = UDim2.new(1, -130, 0, 2)
            badge.BackgroundColor3 = borderColor
            badge.Text = tier == "Divine" and "DIVINE!" or (tier == "Mythic" and "MYTHIC!" or "RARE!")
            badge.TextColor3 = tier == "Divine" and Color3.fromRGB(50, 50, 50) or Color3.new(1, 1, 1)
            badge.TextScaled = true
            badge.Font = Enum.Font.GothamBlack
            badge.Parent = card
            Instance.new("UICorner", badge).CornerRadius = UDim.new(0, 6)
        end

        -- Sold Out state
        if offer.stock <= 0 then
            buyBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
            buyBtn.Text = "Sold Out"
            buyBtn.TextColor3 = Color3.fromRGB(150, 150, 150)
            card.BackgroundTransparency = 0.4
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

-- Refresh market data whenever the market GUI becomes visible
-- This ensures items are always shown when player opens the market
marketGui:GetPropertyChangedSignal("Enabled"):Connect(function()
    if marketGui.Enabled then
        task.spawn(function()
            local freshState = Remotes.GetMarketOffers:InvokeServer()
            if freshState then
                marketState = freshState
                refreshMarketUI()
            end
        end)
    end
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
            brewTimerWidget.PotionName.Text = "Claiming..."
            brewTimerWidget.Countdown.Text = "..."
            -- Auto-claim the completed brew
            task.spawn(function()
                local claimResult = Remotes.ClaimBrewResult:InvokeServer()
                if claimResult and claimResult.success then
                    local name = claimResult.potionName or "Potion"
                    local mutPrefix = claimResult.mutation and (claimResult.mutation .. " ") or ""
                    brewTimerWidget.PotionName.Text = mutPrefix .. name .. "!"
                    brewTimerWidget.Countdown.Text = "+" .. (claimResult.finalSellValue or claimResult.sellValue or 0)
                    brewTimerWidget.ProgressBg.Fill.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
                    task.wait(3)
                    brewTimerWidget.Visible = false
                else
                    brewTimerWidget.PotionName.Text = "Open cauldron to claim"
                    brewTimerWidget.Countdown.Text = "TAP"
                end
            end)
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

-- ========== INVENTORY GUI ==========
inventoryGui = Instance.new("ScreenGui")
inventoryGui.Name = "InventoryGui"
inventoryGui.DisplayOrder = 10
inventoryGui.ResetOnSpawn = false
inventoryGui.Enabled = false
inventoryGui.Parent = playerGui

local invMain = Instance.new("Frame")
invMain.Name = "MainFrame"
invMain.Size = UDim2.new(0, 340, 0, 420)
invMain.Position = UDim2.new(0.5, -170, 0.5, -210)
invMain.BackgroundColor3 = Color3.fromRGB(30, 25, 35)
invMain.Parent = inventoryGui
Instance.new("UICorner", invMain).CornerRadius = UDim.new(0, 12)
local invStroke = Instance.new("UIStroke")
invStroke.Color = Color3.fromRGB(100, 80, 140)
invStroke.Thickness = 2
invStroke.Parent = invMain

-- Title bar
local invTitle = Instance.new("Frame")
invTitle.Name = "TitleBar"
invTitle.Size = UDim2.new(1, 0, 0, 36)
invTitle.BackgroundColor3 = Color3.fromRGB(45, 35, 55)
invTitle.Parent = invMain
Instance.new("UICorner", invTitle).CornerRadius = UDim.new(0, 12)

local invTitleLabel = Instance.new("TextLabel")
invTitleLabel.Size = UDim2.new(1, -40, 1, 0)
invTitleLabel.Position = UDim2.new(0, 12, 0, 0)
invTitleLabel.BackgroundTransparency = 1
invTitleLabel.Text = "Inventory"
invTitleLabel.TextColor3 = Color3.new(1, 1, 1)
invTitleLabel.TextScaled = true
invTitleLabel.Font = Enum.Font.GothamBold
invTitleLabel.TextXAlignment = Enum.TextXAlignment.Left
invTitleLabel.Parent = invTitle

local invCloseBtn = Instance.new("TextButton")
invCloseBtn.Name = "CloseBtn"
invCloseBtn.Size = UDim2.new(0, 28, 0, 28)
invCloseBtn.Position = UDim2.new(1, -32, 0, 4)
invCloseBtn.BackgroundColor3 = Color3.fromRGB(180, 60, 60)
invCloseBtn.Text = "X"
invCloseBtn.TextColor3 = Color3.new(1, 1, 1)
invCloseBtn.TextScaled = true
invCloseBtn.Font = Enum.Font.GothamBold
invCloseBtn.Parent = invTitle
Instance.new("UICorner", invCloseBtn).CornerRadius = UDim.new(0, 6)

-- Scrolling list
local invList = Instance.new("ScrollingFrame")
invList.Name = "IngredientList"
invList.Size = UDim2.new(1, -16, 1, -44)
invList.Position = UDim2.new(0, 8, 0, 40)
invList.BackgroundTransparency = 1
invList.ScrollBarThickness = 6
invList.CanvasSize = UDim2.new(0, 0, 0, 0)
invList.AutomaticCanvasSize = Enum.AutomaticSize.Y
invList.Parent = invMain
local invListLayout = Instance.new("UIListLayout")
invListLayout.Padding = UDim.new(0, 4)
invListLayout.SortOrder = Enum.SortOrder.LayoutOrder
invListLayout.Parent = invList

-- Empty state label
local invEmptyLabel = Instance.new("TextLabel")
invEmptyLabel.Name = "EmptyLabel"
invEmptyLabel.Size = UDim2.new(1, 0, 0, 40)
invEmptyLabel.BackgroundTransparency = 1
invEmptyLabel.Text = "No ingredients yet. Forage or buy some!"
invEmptyLabel.TextColor3 = Color3.fromRGB(120, 120, 130)
invEmptyLabel.TextScaled = true
invEmptyLabel.Font = Enum.Font.Gotham
invEmptyLabel.Visible = false
invEmptyLabel.Parent = invList

local tierOrder = { Common = 1, Uncommon = 2, Rare = 3, Mythic = 4, Divine = 5 }
local tierBorderColors = {
    Common = Color3.fromRGB(100, 100, 100),
    Uncommon = Color3.fromRGB(60, 140, 220),
    Rare = Color3.fromRGB(255, 200, 50),
    Mythic = Color3.fromRGB(200, 80, 255),
    Divine = Color3.fromRGB(255, 255, 220),
}
local elementTints = {
    Fire = Color3.fromRGB(60, 30, 25), Water = Color3.fromRGB(25, 35, 60),
    Earth = Color3.fromRGB(45, 35, 25), Air = Color3.fromRGB(35, 45, 55),
    Shadow = Color3.fromRGB(35, 25, 50), Light = Color3.fromRGB(55, 50, 30),
}

local function refreshInventoryUI()
    local data = myData
    if not data then return end
    -- Clear old items
    for _, child in ipairs(invList:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end

    -- Collect owned ingredients
    local items = {}
    for ingredientId, entry in pairs(data.Ingredients or {}) do
        local qty = 0
        if type(entry) == "number" then
            qty = entry
        elseif type(entry) == "table" and entry.stacks then
            for _, stack in ipairs(entry.stacks) do
                qty = qty + (stack.amount or 0)
            end
        end
        if qty > 0 then
            local ing = Ingredients.Data[ingredientId]
            if ing then
                table.insert(items, { id = ingredientId, data = ing, qty = qty })
            end
        end
    end

    invEmptyLabel.Visible = #items == 0

    -- Sort by tier then name
    table.sort(items, function(a, b)
        local ta = tierOrder[a.data.tier] or 0
        local tb = tierOrder[b.data.tier] or 0
        if ta ~= tb then return ta < tb end
        return a.data.name < b.data.name
    end)

    for i, item in ipairs(items) do
        local ing = item.data
        local tier = ing.tier or "Common"
        local element = ing.element or "Earth"
        local borderColor = tierBorderColors[tier] or tierBorderColors.Common

        local row = Instance.new("Frame")
        row.Name = "Inv_" .. item.id
        row.Size = UDim2.new(1, -4, 0, 42)
        row.BackgroundColor3 = elementTints[element] or Color3.fromRGB(40, 35, 45)
        row.LayoutOrder = i
        row.Parent = invList
        Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)

        local stroke = Instance.new("UIStroke")
        stroke.Color = borderColor
        stroke.Thickness = tier == "Common" and 1 or (tier == "Uncommon" and 2 or 3)
        stroke.Parent = row

        -- Name + quantity
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(0.55, -10, 1, 0)
        nameLabel.Position = UDim2.new(0, 10, 0, 0)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = ing.name .. "  x" .. item.qty
        nameLabel.TextColor3 = Color3.new(1, 1, 1)
        nameLabel.TextScaled = true
        nameLabel.Font = Enum.Font.GothamBold
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.Parent = row

        -- Tier | Element badge
        local badge = Instance.new("TextLabel")
        badge.Size = UDim2.new(0.42, -10, 0, 20)
        badge.Position = UDim2.new(0.58, 0, 0.5, -10)
        badge.BackgroundTransparency = 1
        badge.Text = tier .. " | " .. element
        badge.TextColor3 = borderColor
        badge.TextScaled = true
        badge.Font = Enum.Font.Gotham
        badge.TextXAlignment = Enum.TextXAlignment.Right
        badge.Parent = row
    end
end

-- Inventory HUD button (below Recipe Book)
local invBtn = Instance.new("TextButton")
invBtn.Name = "InventoryBtn"
invBtn.Size = UDim2.new(0, 130, 0, 28)
invBtn.Position = UDim2.new(1, -145, 0, 120)
invBtn.BackgroundColor3 = Color3.fromRGB(50, 80, 50)
invBtn.Text = "Inventory"
invBtn.TextColor3 = Color3.new(1, 1, 1)
invBtn.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold)
invBtn.TextSize = 13
invBtn.Parent = hudGui
Instance.new("UICorner", invBtn).CornerRadius = UDim.new(0, 8)

invBtn.MouseButton1Click:Connect(function()
    if inventoryGui.Enabled then
        inventoryGui.Enabled = false
    else
        closeAllGuis()
        refreshInventoryUI()
        inventoryGui.Enabled = true
    end
end)

invCloseBtn.MouseButton1Click:Connect(function()
    inventoryGui.Enabled = false
end)

-- Auto-refresh inventory if open when data updates
Remotes.PlayerDataUpdate.OnClientEvent:Connect(function(data)
    if inventoryGui.Enabled then
        refreshInventoryUI()
    end
end)

-- ========== STAR HUD ==========
-- Hide the old CompositeScore frame (baked in .rbxl) and replace with StarCount
local scoreFrame = hudGui:FindFirstChild("ScoreFrame")
if scoreFrame then
    scoreFrame.Visible = false
end

-- Reuse the same position for star count
local starFrame = Instance.new("Frame")
starFrame.Name = "StarFrame"
starFrame.Size = UDim2.new(0, 100, 0, 32)
starFrame.Position = UDim2.new(0, 10, 0, 10)
starFrame.BackgroundColor3 = Color3.fromRGB(50, 40, 20)
starFrame.BackgroundTransparency = 0.3
starFrame.Parent = hudGui
Instance.new("UICorner", starFrame).CornerRadius = UDim.new(0, 8)

local starIcon = Instance.new("TextLabel")
starIcon.Name = "StarIcon"
starIcon.Size = UDim2.new(0, 25, 1, 0)
starIcon.Position = UDim2.new(0, 5, 0, 0)
starIcon.BackgroundTransparency = 1
starIcon.Text = "⭐"
starIcon.TextScaled = true
starIcon.Parent = starFrame

local starLabel = Instance.new("TextLabel")
starLabel.Name = "StarLabel"
starLabel.Size = UDim2.new(1, -35, 1, 0)
starLabel.Position = UDim2.new(0, 30, 0, 0)
starLabel.BackgroundTransparency = 1
starLabel.Text = "0"
starLabel.TextColor3 = Color3.fromRGB(255, 215, 100)
starLabel.TextScaled = true
starLabel.Font = Enum.Font.GothamBold
starLabel.TextXAlignment = Enum.TextXAlignment.Left
starLabel.Parent = starFrame

Remotes.PlayerDataUpdate.OnClientEvent:Connect(function(data)
    if data and data.BrewStats then
        starLabel.Text = tostring(data.BrewStats.StarCount or 0)
    end
end)

print("[GameController] Market wired")