-- InteractionController: Cauldron, Sell, Recipe Book, Proximity Prompts
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local ProximityPromptService = game:GetService("ProximityPromptService")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local Remotes = RS:WaitForChild("Remotes")
local Ingredients = require(RS.Shared.Config.Ingredients)
local Potions = require(RS.Shared.Config.Potions)
local Recipes = require(RS.Shared.Config.Recipes)

local cauldronGui = playerGui:WaitForChild("CauldronGui")
local sellGui = playerGui:WaitForChild("SellGui")
local recipeBookGui = playerGui:WaitForChild("RecipeBookGui")
local marketGui = playerGui:WaitForChild("MarketGui")
local hudGui = playerGui:WaitForChild("HudGui")

-- Wait for data to be available
local function getMyData()
    return Remotes.GetPlayerData:InvokeServer()
end

local function closeAllGuis()
    marketGui.Enabled = false
    cauldronGui.Enabled = false
    sellGui.Enabled = false
    recipeBookGui.Enabled = false
end

-- ========== CAULDRON ==========
local selectedSlots = {nil, nil, nil}
local isBrewing = false
local brewEndTime = 0
local brewTimerConnection = nil

local function updateSlotDisplay()
    -- Check if 3rd slot is unlocked
    local data = getMyData()
    local slot3Unlocked = data and data.BrewStats and data.BrewStats.TotalBrewed >= 10
    local slot3 = cauldronGui.MainFrame.SlotsFrame:FindFirstChild("Slot3")
    if slot3 then
        slot3.Visible = true
        if not slot3Unlocked then
            slot3.Label.Text = "Locked (10 brews)"
            slot3.Label.TextColor3 = Color3.fromRGB(100, 100, 110)
            slot3.BackgroundColor3 = Color3.fromRGB(35, 30, 40)
        end
    end
    for i = 1, (slot3Unlocked and 3 or 2) do
        local slot = cauldronGui.MainFrame.SlotsFrame["Slot" .. i]
        local label = slot.Label
        if selectedSlots[i] then
            local ing = Ingredients.Data[selectedSlots[i]]
            label.Text = ing and ing.name or selectedSlots[i]
            label.TextColor3 = Color3.new(1, 1, 1)
            slot.BackgroundColor3 = Color3.fromRGB(80, 100, 80)
        else
            label.Text = "Slot " .. i .. ": Tap ingredient"
            label.TextColor3 = Color3.fromRGB(150, 150, 160)
            slot.BackgroundColor3 = Color3.fromRGB(60, 55, 65)
        end
    end

    -- Brew preview: show what this combo will produce
    local brewBtn = cauldronGui.MainFrame.BrewBtn
    if selectedSlots[1] and selectedSlots[2] then
        local previewId = Recipes.lookup(selectedSlots[1], selectedSlots[2], selectedSlots[3] ~= "" and selectedSlots[3] or nil)
        if previewId and previewId ~= "sludge" then
            local potion = Potions.Data[previewId]
            local potionName = potion and potion.name or previewId
            local tier = potion and potion.tier or "Common"
            local value = potion and potion.sellValue or 0
            brewBtn.Text = "Brew: " .. potionName .. " (" .. tier .. ", " .. value .. " coins)"
            brewBtn.BackgroundColor3 = Color3.fromRGB(50, 140, 50)
        else
            brewBtn.Text = "Brew: Unknown combo (might be sludge!)"
            brewBtn.BackgroundColor3 = Color3.fromRGB(140, 100, 40)
        end
    else
        brewBtn.Text = "Select 2 ingredients"
        brewBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 90)
    end
end

local function refreshCauldronIngredients()
    local data = getMyData()
    if not data then return end
    local grid = cauldronGui.MainFrame.IngredientGrid
    for _, child in ipairs(grid:GetChildren()) do
        if child:IsA("TextButton") or child:IsA("TextLabel") then child:Destroy() end
    end

    -- Collect owned ingredients with quantities
    local owned = {}
    local ownedIds = {}
    local order = 0
    for ingredientId, entry in pairs(data.Ingredients) do
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
                order = order + 1
                owned[ingredientId] = qty
                table.insert(ownedIds, ingredientId)
                local btn = Instance.new("TextButton")
                btn.Name = "Ing_" .. ingredientId
                btn.Size = UDim2.new(1, -10, 0, 36)
                btn.BackgroundColor3 = Color3.fromRGB(55, 50, 60)
                btn.Text = ing.name .. "  x" .. qty
                btn.TextColor3 = Color3.new(1, 1, 1)
                btn.TextScaled = true
                btn.Font = Enum.Font.Gotham
                btn.TextXAlignment = Enum.TextXAlignment.Left
                btn.LayoutOrder = order
                btn.Parent = grid
                Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
                -- Left padding
                local pad = Instance.new("UIPadding")
                pad.PaddingLeft = UDim.new(0, 10)
                pad.Parent = btn
                btn.MouseButton1Click:Connect(function()
                    if isBrewing then return end
                    if not selectedSlots[1] then
                        selectedSlots[1] = ingredientId
                    elseif not selectedSlots[2] then
                        selectedSlots[2] = ingredientId
                    elseif not selectedSlots[3] then
                        local d = getMyData()
                        if d and d.BrewStats and d.BrewStats.TotalBrewed >= 10 then
                            selectedSlots[3] = ingredientId
                        end
                    else
                        selectedSlots[1] = selectedSlots[2]
                        selectedSlots[2] = selectedSlots[3] or ingredientId
                        selectedSlots[3] = ingredientId
                    end
                    updateSlotDisplay()
                end)
            end
        end
    end

    -- Brew hints: show possible recipes with owned ingredients
    if #ownedIds >= 2 then
        local hints = {}
        for i = 1, #ownedIds do
            for j = i, #ownedIds do
                local id1, id2 = ownedIds[i], ownedIds[j]
                if id1 == id2 and (owned[id1] or 0) < 2 then continue end
                local potionId = Recipes.lookup(id1, id2)
                if potionId and potionId ~= "sludge" then
                    local potion = Potions.Data[potionId]
                    if potion then
                        local ing1 = Ingredients.Data[id1]
                        local ing2 = Ingredients.Data[id2]
                        local name1 = ing1 and ing1.name or id1
                        local name2 = ing2 and ing2.name or id2
                        table.insert(hints, name1 .. " + " .. name2 .. " = " .. potion.name)
                    end
                end
            end
        end
        if #hints > 0 then
            order = order + 1
            local divider = Instance.new("TextLabel")
            divider.Name = "HintHeader"
            divider.Size = UDim2.new(1, -10, 0, 28)
            divider.BackgroundTransparency = 1
            divider.Text = "You can brew:"
            divider.TextColor3 = Color3.fromRGB(255, 215, 100)
            divider.TextScaled = true
            divider.Font = Enum.Font.GothamBold
            divider.TextXAlignment = Enum.TextXAlignment.Left
            divider.LayoutOrder = order + 1000
            divider.Parent = grid
            for h, hint in ipairs(hints) do
                if h > 5 then break end
                order = order + 1
                local hintLabel = Instance.new("TextLabel")
                hintLabel.Name = "Hint_" .. h
                hintLabel.Size = UDim2.new(1, -10, 0, 24)
                hintLabel.BackgroundColor3 = Color3.fromRGB(40, 50, 35)
                hintLabel.Text = "  " .. hint
                hintLabel.TextColor3 = Color3.fromRGB(150, 255, 130)
                hintLabel.TextScaled = true
                hintLabel.Font = Enum.Font.Gotham
                hintLabel.TextXAlignment = Enum.TextXAlignment.Left
                hintLabel.LayoutOrder = order + 1000
                hintLabel.Parent = grid
                Instance.new("UICorner", hintLabel).CornerRadius = UDim.new(0, 6)
            end
        end
    end
end

local function setBrewingUIState(state)
    local mf = cauldronGui.MainFrame
    local progressBg = mf:FindFirstChild("ProgressBarBg")
    local timerLabel = mf:FindFirstChild("TimerLabel")
    local rarityBadge = mf:FindFirstChild("RarityBadge")
    local brewStatus = mf:FindFirstChild("BrewStatusLabel")
    local resultLabel = mf.ResultLabel
    local brewBtn = mf.BrewBtn
    local slotsFrame = mf.SlotsFrame
    local grid = mf.IngredientGrid
    if state == "idle" then
        if progressBg then progressBg.Visible = false end
        if timerLabel then timerLabel.Visible = false end
        if rarityBadge then rarityBadge.Visible = false end
        if brewStatus then brewStatus.Visible = false end
        resultLabel.Visible = false
        brewBtn.Visible = true
        slotsFrame.Visible = true
        grid.Visible = true
    elseif state == "brewing" then
        if progressBg then progressBg.Visible = true end
        if timerLabel then timerLabel.Visible = true end
        if rarityBadge then rarityBadge.Visible = true end
        if brewStatus then brewStatus.Visible = true end
        resultLabel.Visible = false
        brewBtn.Visible = false
        slotsFrame.Visible = false
        grid.Visible = false
    elseif state == "result" then
        if progressBg then progressBg.Visible = false end
        if timerLabel then timerLabel.Visible = false end
        if rarityBadge then rarityBadge.Visible = false end
        if brewStatus then brewStatus.Visible = false end
        resultLabel.Visible = true
        brewBtn.Visible = true
        slotsFrame.Visible = true
        grid.Visible = true
    end
end

local function startBrewTimer(duration, endTime)
    local mf = cauldronGui.MainFrame
    local progressBg = mf:FindFirstChild("ProgressBarBg")
    local timerLabel = mf:FindFirstChild("TimerLabel")
    local brewStatus = mf:FindFirstChild("BrewStatusLabel")
    local fill = progressBg and progressBg:FindFirstChild("Fill")
    isBrewing = true
    brewEndTime = endTime
    -- Close the cauldron GUI - brew timer shows on HUD widget instead
    cauldronGui.Enabled = false
    -- Activate HUD brew timer widget
    local hudGui = player:WaitForChild("PlayerGui"):FindFirstChild("HudGui")
    if hudGui then
        local widget = hudGui:FindFirstChild("BrewTimerWidget")
        if widget then
            widget.Visible = true
            widget.PotionName.Text = "Brewing..."
        end
    end
    local statusMessages = {
        "Your cauldron is bubbling...",
        "Ingredients are melding together...",
        "Magical energy is building...",
        "The brew is taking shape...",
        "Almost there... hold steady...",
    }
    if brewTimerConnection then brewTimerConnection:Disconnect() end
    brewTimerConnection = game:GetService("RunService").Heartbeat:Connect(function()
        local now = os.time()
        local remaining = math.max(0, endTime - now)
        local elapsed = duration - remaining
        local pct = math.clamp(elapsed / duration, 0, 1)
        if fill then
            fill.Size = UDim2.new(pct, 0, 1, 0)
            fill.BackgroundColor3 = Color3.new(0.3 + pct * 0.7, 0.8 - pct * 0.2, 0.5 - pct * 0.3)
        end
        if timerLabel then
            local mins = math.floor(remaining / 60)
            local secs = remaining % 60
            timerLabel.Text = string.format("Brewing... %d:%02d", mins, secs)
        end
        if brewStatus then
            local msgIdx = math.clamp(math.floor(pct * #statusMessages) + 1, 1, #statusMessages)
            brewStatus.Text = statusMessages[msgIdx]
        end
        if remaining <= 0 then
            if brewTimerConnection then brewTimerConnection:Disconnect() brewTimerConnection = nil end
            task.spawn(function()
                local claimResult = Remotes.ClaimBrewResult:InvokeServer()
                isBrewing = false
                if claimResult and claimResult.success then
                    setBrewingUIState("result")
                    local resultLabel = cauldronGui.MainFrame.ResultLabel
                    if claimResult.isNewDiscovery then
                        resultLabel.Text = "NEW DISCOVERY!\n" .. claimResult.potionName .. "\nWorth " .. claimResult.sellValue .. " coins"
                        resultLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
                    else
                        local mutText = ""
                    if claimResult.mutation then
                        mutText = claimResult.mutation .. " "
                        resultLabel.Text = claimResult.mutation .. " " .. claimResult.potionName .. "!\nWorth " .. (claimResult.finalSellValue or claimResult.sellValue) .. " coins (" .. (claimResult.mutationMultiplier or 1) .. "x!)"
                    else
                        resultLabel.Text = "Brewed: " .. claimResult.potionName .. "\nWorth " .. claimResult.sellValue .. " coins"
                    end
                        resultLabel.TextColor3 = claimResult.potionId == "sludge" and Color3.fromRGB(150, 150, 100) or Color3.fromRGB(100, 255, 100)
                    end
                    if claimResult.tierChanged and claimResult.newTier then
                        task.delay(1, function() resultLabel.Text = resultLabel.Text .. "\n\nCAULDRON EVOLVED: " .. claimResult.newTier.name .. "!" end)
                    end
                    selectedSlots = {nil, nil, nil}
                    updateSlotDisplay()
                    refreshCauldronIngredients()
                    task.delay(5, function() if not isBrewing then setBrewingUIState("idle") end end)
                else
                    setBrewingUIState("idle")
                end
            end)
        end
    end)
end

local function checkActiveBrewState()
    local state = Remotes.GetActiveBrewState:InvokeServer()
    if not state then return false end
    if state.status == "brewing" then
        local remaining = math.max(0, state.endUnix - os.time())
        local duration = state.endUnix - state.startUnix
        if remaining > 0 then
            startBrewTimer(duration, state.endUnix)
            return true
        end
    end
    if state.status == "completed_unclaimed" or (state.status == "brewing" and os.time() >= state.endUnix) then
        task.spawn(function()
            local claimResult = Remotes.ClaimBrewResult:InvokeServer()
            if claimResult and claimResult.success then
                setBrewingUIState("result")
                local resultLabel = cauldronGui.MainFrame.ResultLabel
                resultLabel.Text = "Your brew finished!\n" .. claimResult.potionName .. "\nWorth " .. claimResult.sellValue .. " coins"
                resultLabel.TextColor3 = Color3.fromRGB(100, 255, 200)
                refreshCauldronIngredients()
                task.delay(5, function() if not isBrewing then setBrewingUIState("idle") end end)
            end
        end)
        return true
    end
    return false
end

for i = 1, 3 do
    local slot = cauldronGui.MainFrame.SlotsFrame["Slot" .. i]
    slot.InputBegan:Connect(function(input)
        if isBrewing then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            selectedSlots[i] = nil
            updateSlotDisplay()
        end
    end)
end

cauldronGui.MainFrame.BrewBtn.MouseButton1Click:Connect(function()
    if isBrewing then return end
    if not selectedSlots[1] or not selectedSlots[2] then return end
    local resultLabel = cauldronGui.MainFrame.ResultLabel
    resultLabel.Text = "Starting brew..."
    resultLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    resultLabel.Visible = true
    local result = Remotes.BrewPotion:InvokeServer(selectedSlots[1], selectedSlots[2], selectedSlots[3] or "")
    if result and result.success then
        local badge = cauldronGui.MainFrame:FindFirstChild("RarityBadge")
        if badge then
            badge.Text = result.rarity
            local rc = {Common=Color3.fromRGB(80,140,80), Uncommon=Color3.fromRGB(60,120,180), Rare=Color3.fromRGB(200,170,50), Mythic=Color3.fromRGB(180,60,200)}
            badge.BackgroundColor3 = rc[result.rarity] or Color3.fromRGB(100, 80, 150)
        end
        startBrewTimer(result.brewDuration, result.endUnix)
        
        -- Fire VFX event
        local brewEvent = game.ReplicatedStorage:WaitForChild("BrewStateEvent", 5)
        if brewEvent then
            brewEvent:Fire("start", { duration = result.brewDuration, endUnix = result.endUnix, rarity = result.rarity })
        end    else
        resultLabel.Text = result and result.error or "Brew failed!"
        resultLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
        task.delay(3, function() resultLabel.Visible = false end)
    end
end)

cauldronGui:GetPropertyChangedSignal("Enabled"):Connect(function()
    if cauldronGui.Enabled then
        if not checkActiveBrewState() then
            setBrewingUIState("idle")
            refreshCauldronIngredients()
            selectedSlots = {nil, nil, nil}
            updateSlotDisplay()
        end
    end
end)

cauldronGui.MainFrame.TitleBar.CloseBtn.MouseButton1Click:Connect(function()
    cauldronGui.Enabled = false
end)



-- ========== SELL GUI ==========
local function refreshSellUI()
    local data = getMyData()
    if not data then return end
    
    local list = sellGui.MainFrame.PotionList
    for _, child in ipairs(list:GetChildren()) do
        if child:IsA("Frame") or (child:IsA("TextLabel") and child.Name ~= "EmptyLabel") then
            child:Destroy()
        end
    end
    
    local hasItems = false
    local order = 0
    for potionId, qty in pairs(data.Potions) do
        if qty > 0 then
            hasItems = true
            order = order + 1
            local baseId, mutation = Potions.parsePotionKey(potionId)
            local potion = Potions.Data[baseId]
            if not potion then continue end
            local displayName = mutation and (mutation .. " " .. potion.name) or potion.name
            local unitValue = Potions.getSellValue(potionId)
            
            local item = Instance.new("Frame")
            item.Size = UDim2.new(1, 0, 0, 55)
            item.BackgroundColor3 = Color3.fromRGB(50, 45, 35)
            item.LayoutOrder = order
            item.Parent = list
            Instance.new("UICorner", item).CornerRadius = UDim.new(0, 8)
            
            local nameLabel = Instance.new("TextLabel")
            nameLabel.Size = UDim2.new(0.4, 0, 0, 25)
            nameLabel.Position = UDim2.new(0, 10, 0, 5)
            nameLabel.BackgroundTransparency = 1
            nameLabel.Text = displayName .. " x" .. qty
            nameLabel.TextColor3 = Color3.new(1, 1, 1)
            nameLabel.TextScaled = true
            nameLabel.Font = Enum.Font.GothamBold
            nameLabel.TextXAlignment = Enum.TextXAlignment.Left
            nameLabel.Parent = item
            
            local valueLabel = Instance.new("TextLabel")
            valueLabel.Size = UDim2.new(0, 100, 0, 25)
            valueLabel.Position = UDim2.new(0.4, 10, 0, 5)
            valueLabel.BackgroundTransparency = 1
            valueLabel.Text = tostring(unitValue) .. " coins"
            valueLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
            valueLabel.TextScaled = true
            valueLabel.Font = Enum.Font.Gotham
            valueLabel.Parent = item
            
            local sellBtn = Instance.new("TextButton")
            sellBtn.Size = UDim2.new(0, 70, 0, 35)
            sellBtn.Position = UDim2.new(1, -80, 0, 10)
            sellBtn.BackgroundColor3 = Color3.fromRGB(180, 140, 50)
            sellBtn.Text = "Sell"
            sellBtn.TextColor3 = Color3.new(1, 1, 1)
            sellBtn.TextScaled = true
            sellBtn.Font = Enum.Font.GothamBold
            sellBtn.Parent = item
            Instance.new("UICorner", sellBtn).CornerRadius = UDim.new(0, 8)
            
            sellBtn.MouseButton1Click:Connect(function()
                Remotes.SellPotion:FireServer(potionId, 1)
                task.wait(0.3)
                refreshSellUI()
            end)
        end
    end
    
    local emptyLabel = list:FindFirstChild("EmptyLabel")
    if emptyLabel then
        emptyLabel.Visible = not hasItems
    end
end

sellGui.MainFrame.TitleBar.CloseBtn.MouseButton1Click:Connect(function()
    sellGui.Enabled = false
end)

-- ========== RECIPE BOOK ==========
local function refreshRecipeBook()
    local data = getMyData()
    if not data then return end
    
    local list = recipeBookGui.MainFrame.RecipeList
    for _, child in ipairs(list:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end
    
    local allRecipes = Recipes.getAllRecipeIds()
    local discoveredCount = 0
    local totalCount = 0
    local order = 0
    
    for recipeKey, potionId in pairs(allRecipes) do
        totalCount = totalCount + 1
        order = order + 1
        local discovered = data.DiscoveredRecipes[recipeKey] == true
        if discovered then discoveredCount = discoveredCount + 1 end
        
        local potion = Potions.Data[potionId]
        local parts = string.split(recipeKey, "|")
        local ing1 = Ingredients.Data[parts[1]]
        local ing2 = Ingredients.Data[parts[2]]
        
        local item = Instance.new("Frame")
        item.Size = UDim2.new(1, 0, 0, 50)
        item.BackgroundColor3 = discovered and Color3.fromRGB(50, 45, 60) or Color3.fromRGB(35, 35, 40)
        item.LayoutOrder = order
        item.Parent = list
        Instance.new("UICorner", item).CornerRadius = UDim.new(0, 8)
        
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(0.5, -5, 0, 25)
        nameLabel.Position = UDim2.new(0, 10, 0, 3)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Font = Enum.Font.GothamBold
        nameLabel.TextScaled = true
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.Parent = item
        
        local detailLabel = Instance.new("TextLabel")
        detailLabel.Size = UDim2.new(1, -20, 0, 18)
        detailLabel.Position = UDim2.new(0, 10, 0, 28)
        detailLabel.BackgroundTransparency = 1
        detailLabel.Font = Enum.Font.Gotham
        detailLabel.TextScaled = true
        detailLabel.TextXAlignment = Enum.TextXAlignment.Left
        detailLabel.Parent = item
        
        if discovered then
            nameLabel.Text = potion and potion.name or potionId
            nameLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
            local ing1Name = ing1 and ing1.name or parts[1]
            local ing2Name = ing2 and ing2.name or parts[2]
            local ing3Name = parts[3] and (Ingredients.Data[parts[3]] and Ingredients.Data[parts[3]].name or parts[3]) or nil
            local combo = ing1Name .. " + " .. ing2Name .. (ing3Name and (" + " .. ing3Name) or "")
            detailLabel.Text = combo .. " → " .. (potion and tostring(potion.sellValue) or "?") .. " coins"
            detailLabel.TextColor3 = Color3.fromRGB(180, 170, 200)
        else
            -- Show ingredient hints so players know what to try
            local ing1Name = ing1 and ing1.name or parts[1]
            local ing2Name = ing2 and ing2.name or parts[2]
            local ing3Name = parts[3] and (Ingredients.Data[parts[3]] and Ingredients.Data[parts[3]].name or parts[3]) or nil
            local hint = ing1Name .. " + " .. ing2Name .. (ing3Name and (" + " .. ing3Name) or "")
            nameLabel.Text = "??? — Try: " .. hint
            nameLabel.TextColor3 = Color3.fromRGB(180, 160, 100)
            local tier = potion and potion.tier or "Unknown"
            detailLabel.Text = "Hint: " .. tier .. " tier potion"
            detailLabel.TextColor3 = Color3.fromRGB(120, 110, 80)
        end
    end
    
    recipeBookGui.MainFrame.DiscoveryCounter.Text = "Discovered: " .. discoveredCount .. " / " .. totalCount
end

recipeBookGui.MainFrame.TitleBar.CloseBtn.MouseButton1Click:Connect(function()
    recipeBookGui.Enabled = false
end)

-- Recipe book button in HUD
hudGui.RecipeBookBtn.MouseButton1Click:Connect(function()
    if recipeBookGui.Enabled then
        recipeBookGui.Enabled = false
    else
        closeAllGuis()
        refreshRecipeBook()
        recipeBookGui.Enabled = true
    end
end)

-- ========== PROXIMITY PROMPTS ==========
ProximityPromptService.PromptTriggered:Connect(function(prompt, triggerPlayer)
    if triggerPlayer ~= player then return end
    
    local parent = prompt.Parent
    if not parent then return end
    
    if parent.Name == "MarketStall" then
        closeAllGuis()
        marketGui.Enabled = true
    elseif parent.Name == "Cauldron" then
        closeAllGuis()
        selectedSlots = {nil, nil, nil}
        updateSlotDisplay()
        refreshCauldronIngredients()
        cauldronGui.Enabled = true
    elseif parent.Name == "SellCounter" then
        closeAllGuis()
        refreshSellUI()
        sellGui.Enabled = true
    elseif parent.Name:match("ForageNode") then
        Remotes.ForageNode:FireServer(parent.Name)
    end
end)

-- Update data listener to refresh open GUIs
Remotes.PlayerDataUpdate.OnClientEvent:Connect(function(data)
    -- If cauldron is open, refresh ingredient list
    if cauldronGui.Enabled then
        refreshCauldronIngredients()
    end
    -- If sell gui is open, refresh potion list
    if sellGui.Enabled then
        refreshSellUI()
    end
end)

print("[InteractionController] Initialized - all interactions wired")
