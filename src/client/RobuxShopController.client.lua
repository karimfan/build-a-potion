-- RobuxShopController: Robux Shop UI accessible from HUD
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local Remotes = RS:WaitForChild("Remotes")
local RobuxShopTuning = require(RS:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("RobuxShopTuning"))

-- ============================================================
-- CREATE SHOP GUI
-- ============================================================
local shopGui = Instance.new("ScreenGui")
shopGui.Name = "RobuxShopGui"
shopGui.DisplayOrder = 15
shopGui.ResetOnSpawn = false
shopGui.Enabled = false
shopGui.Parent = playerGui

local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0.65, 0, 0.7, 0)
mainFrame.Position = UDim2.new(0.175, 0, 0.15, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(18, 12, 28)
mainFrame.BackgroundTransparency = 0.03
mainFrame.Parent = shopGui
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 16)
local border = Instance.new("UIStroke")
border.Color = Color3.fromRGB(255, 200, 50)
border.Thickness = 3
border.Parent = mainFrame

-- Title bar
local titleBar = Instance.new("Frame")
titleBar.Name = "TitleBar"
titleBar.Size = UDim2.new(1, 0, 0, 50)
titleBar.BackgroundColor3 = Color3.fromRGB(30, 20, 45)
titleBar.Parent = mainFrame
Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 16)

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(0.7, 0, 1, 0)
titleLabel.Position = UDim2.new(0, 15, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "ROBUX SHOP"
titleLabel.TextColor3 = Color3.fromRGB(255, 215, 50)
titleLabel.TextScaled = true
titleLabel.Font = Enum.Font.GothamBlack
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = titleBar

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 40, 0, 40)
closeBtn.Position = UDim2.new(1, -45, 0, 5)
closeBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.new(1, 1, 1)
closeBtn.TextScaled = true
closeBtn.Font = Enum.Font.GothamBold
closeBtn.Parent = titleBar
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 8)
closeBtn.MouseButton1Click:Connect(function() shopGui.Enabled = false end)

-- Content scroll frame
local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Name = "ProductList"
scrollFrame.Size = UDim2.new(1, -20, 1, -60)
scrollFrame.Position = UDim2.new(0, 10, 0, 55)
scrollFrame.BackgroundTransparency = 1
scrollFrame.ScrollBarThickness = 6
scrollFrame.ScrollBarImageColor3 = Color3.fromRGB(255, 200, 50)
scrollFrame.Parent = mainFrame

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 8)
listLayout.Parent = scrollFrame
listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 20)
end)

-- ============================================================
-- POPULATE SHOP
-- ============================================================
local function buildShop()
    for _, child in ipairs(scrollFrame:GetChildren()) do
        if child:IsA("Frame") or child:IsA("TextLabel") then child:Destroy() end
    end

    local order = 0
    for _, category in ipairs(RobuxShopTuning.Categories) do
        -- Category header
        order = order + 1
        local header = Instance.new("TextLabel")
        header.Name = "Header_" .. category
        header.Size = UDim2.new(1, -10, 0, 35)
        header.BackgroundColor3 = Color3.fromRGB(40, 30, 60)
        header.Text = "  " .. category:upper()
        header.TextColor3 = Color3.fromRGB(255, 200, 100)
        header.TextScaled = true
        header.Font = Enum.Font.GothamBlack
        header.TextXAlignment = Enum.TextXAlignment.Left
        header.LayoutOrder = order
        header.Parent = scrollFrame
        Instance.new("UICorner", header).CornerRadius = UDim.new(0, 8)

        -- Products in this category
        local products = RobuxShopTuning.getByCategory(category)
        for _, product in ipairs(products) do
            order = order + 1
            local card = Instance.new("Frame")
            card.Name = "Product_" .. product.name:gsub(" ", "")
            card.Size = UDim2.new(1, -10, 0, 70)
            card.BackgroundColor3 = Color3.fromRGB(30, 25, 42)
            card.LayoutOrder = order
            card.Parent = scrollFrame
            Instance.new("UICorner", card).CornerRadius = UDim.new(0, 10)

            -- Tier color indicator
            local tierColor = RobuxShopTuning.TierColors[product.grantTier] or Color3.fromRGB(150, 150, 150)
            if product.grantType == "instant_brew" then tierColor = Color3.fromRGB(100, 200, 255) end
            if product.grantType == "mutation_charm" then tierColor = Color3.fromRGB(200, 100, 255) end

            local indicator = Instance.new("Frame")
            indicator.Size = UDim2.new(0, 5, 1, -10)
            indicator.Position = UDim2.new(0, 5, 0, 5)
            indicator.BackgroundColor3 = tierColor
            indicator.Parent = card
            Instance.new("UICorner", indicator).CornerRadius = UDim.new(0, 3)

            -- Product name
            local nameLabel = Instance.new("TextLabel")
            nameLabel.Size = UDim2.new(0.55, -20, 0, 25)
            nameLabel.Position = UDim2.new(0, 18, 0, 8)
            nameLabel.BackgroundTransparency = 1
            nameLabel.Text = product.name
            nameLabel.TextColor3 = Color3.new(1, 1, 1)
            nameLabel.TextScaled = true
            nameLabel.Font = Enum.Font.GothamBold
            nameLabel.TextXAlignment = Enum.TextXAlignment.Left
            nameLabel.Parent = card

            -- Description
            local descLabel = Instance.new("TextLabel")
            descLabel.Size = UDim2.new(0.55, -20, 0, 18)
            descLabel.Position = UDim2.new(0, 18, 0, 35)
            descLabel.BackgroundTransparency = 1
            descLabel.Text = product.description
            descLabel.TextColor3 = Color3.fromRGB(170, 165, 185)
            descLabel.TextScaled = true
            descLabel.Font = Enum.Font.Gotham
            descLabel.TextXAlignment = Enum.TextXAlignment.Left
            descLabel.Parent = card

            -- Buy button with Robux price
            local buyBtn = Instance.new("TextButton")
            buyBtn.Size = UDim2.new(0, 120, 0, 40)
            buyBtn.Position = UDim2.new(1, -130, 0, 15)
            buyBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 80)
            buyBtn.Text = "R$ " .. product.robux
            buyBtn.TextColor3 = Color3.new(1, 1, 1)
            buyBtn.TextScaled = true
            buyBtn.Font = Enum.Font.GothamBlack
            buyBtn.Parent = card
            Instance.new("UICorner", buyBtn).CornerRadius = UDim.new(0, 10)

            local buyStroke = Instance.new("UIStroke")
            buyStroke.Color = Color3.fromRGB(0, 220, 100)
            buyStroke.Thickness = 2
            buyStroke.Parent = buyBtn

            -- Find product index for server communication
            local productIndex = nil
            for idx, p in ipairs(RobuxShopTuning.Products) do
                if p.name == product.name then productIndex = idx break end
            end

            buyBtn.MouseButton1Click:Connect(function()
                if not productIndex then return end
                buyBtn.Text = "..."
                buyBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
                Remotes.PromptRobuxPurchase:FireServer(productIndex)
                task.delay(2, function()
                    buyBtn.Text = "R$ " .. product.robux
                    buyBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 80)
                end)
            end)
        end
    end
end

buildShop()

-- ============================================================
-- HUD BUTTON (Shop icon in top bar)
-- ============================================================
local hudGui = playerGui:WaitForChild("HudGui", 10)
if hudGui then
    -- Add shop button next to existing HUD elements
    local shopBtn = Instance.new("TextButton")
    shopBtn.Name = "RobuxShopBtn"
    shopBtn.Size = UDim2.new(0, 50, 0, 50)
    shopBtn.Position = UDim2.new(0, 80, 0, 5)
    shopBtn.BackgroundColor3 = Color3.fromRGB(0, 170, 80)
    shopBtn.Text = "R$"
    shopBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    shopBtn.TextScaled = true
    shopBtn.Font = Enum.Font.GothamBlack
    shopBtn.ZIndex = 10
    shopBtn.Parent = hudGui
    Instance.new("UICorner", shopBtn).CornerRadius = UDim.new(0, 12)

    local shopStroke = Instance.new("UIStroke")
    shopStroke.Color = Color3.fromRGB(255, 215, 50)
    shopStroke.Thickness = 2
    shopStroke.Parent = shopBtn

    shopBtn.MouseButton1Click:Connect(function()
        shopGui.Enabled = not shopGui.Enabled
    end)
end

print("[RobuxShopController] Initialized (Sprint 013 - Robux Shop)")
