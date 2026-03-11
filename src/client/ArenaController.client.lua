-- ArenaController: Challenge board, loadout UI, fight VFX + boost, result reveal
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local Remotes = RS:WaitForChild("Remotes")
local Potions = require(RS:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("Potions"))
local ArenaTuning = require(RS.Shared.Config:WaitForChild("ArenaTuning"))
local MutationTuning = require(RS.Shared.Config:WaitForChild("MutationTuning"))
local ProximityPromptService = game:GetService("ProximityPromptService")

local currentDuel = nil
local boostConnection = nil
local fightVFXParts = {}
local fightSounds = {}

-- ============================================================
-- ARENA UI CREATION
-- ============================================================
local arenaGui = Instance.new("ScreenGui")
arenaGui.Name = "ArenaGui"
arenaGui.DisplayOrder = 20
arenaGui.ResetOnSpawn = false
arenaGui.Enabled = false
arenaGui.Parent = playerGui

-- Main frame
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0.7, 0, 0.75, 0)
mainFrame.Position = UDim2.new(0.15, 0, 0.12, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(20, 15, 30)
mainFrame.BackgroundTransparency = 0.05
mainFrame.Parent = arenaGui
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 16)
local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(200, 100, 255)
stroke.Thickness = 3
stroke.Parent = mainFrame

-- Title
local title = Instance.new("TextLabel")
title.Name = "Title"
title.Size = UDim2.new(1, 0, 0, 50)
title.BackgroundTransparency = 1
title.Text = "POTION ARENA"
title.TextColor3 = Color3.fromRGB(255, 200, 100)
title.TextScaled = true
title.Font = Enum.Font.GothamBlack
title.Parent = mainFrame

-- Close button
local closeBtn = Instance.new("TextButton")
closeBtn.Name = "CloseBtn"
closeBtn.Size = UDim2.new(0, 40, 0, 40)
closeBtn.Position = UDim2.new(1, -45, 0, 5)
closeBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.new(1, 1, 1)
closeBtn.TextScaled = true
closeBtn.Font = Enum.Font.GothamBold
closeBtn.Parent = mainFrame
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 8)
closeBtn.MouseButton1Click:Connect(function() arenaGui.Enabled = false end)

-- Content area (changes based on state)
local content = Instance.new("Frame")
content.Name = "Content"
content.Size = UDim2.new(1, -20, 1, -60)
content.Position = UDim2.new(0, 10, 0, 55)
content.BackgroundTransparency = 1
content.Parent = mainFrame

-- ============================================================
-- CHALLENGE BOARD (player list)
-- ============================================================
local function showChallengeBoard()
    for _, c in ipairs(content:GetChildren()) do c:Destroy() end
    title.Text = "POTION ARENA — Challenge Board"

    local subtitle = Instance.new("TextLabel")
    subtitle.Size = UDim2.new(1, 0, 0, 25)
    subtitle.BackgroundTransparency = 1
    subtitle.Text = "Select a player to challenge (min " .. ArenaTuning.MinStarsToEnter .. " stars, " .. ArenaTuning.MinPotionsToEnter .. " potions)"
    subtitle.TextColor3 = Color3.fromRGB(180, 180, 200)
    subtitle.TextScaled = true
    subtitle.Font = Enum.Font.Gotham
    subtitle.Parent = content

    local list = Instance.new("ScrollingFrame")
    list.Name = "PlayerList"
    list.Size = UDim2.new(1, 0, 1, -35)
    list.Position = UDim2.new(0, 0, 0, 30)
    list.BackgroundTransparency = 0.9
    list.ScrollBarThickness = 6
    list.Parent = content
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 6)
    layout.Parent = list

    for _, other in ipairs(Players:GetPlayers()) do
        if other ~= player then
            local card = Instance.new("Frame")
            card.Size = UDim2.new(1, -10, 0, 50)
            card.BackgroundColor3 = Color3.fromRGB(35, 30, 50)
            card.Parent = list
            Instance.new("UICorner", card).CornerRadius = UDim.new(0, 8)

            local nameLabel = Instance.new("TextLabel")
            nameLabel.Size = UDim2.new(0.5, 0, 1, 0)
            nameLabel.Position = UDim2.new(0, 10, 0, 0)
            nameLabel.BackgroundTransparency = 1
            nameLabel.Text = other.Name
            nameLabel.TextColor3 = Color3.new(1, 1, 1)
            nameLabel.TextScaled = true
            nameLabel.Font = Enum.Font.GothamBold
            nameLabel.TextXAlignment = Enum.TextXAlignment.Left
            nameLabel.Parent = card

            local challengeBtn = Instance.new("TextButton")
            challengeBtn.Size = UDim2.new(0, 100, 0, 35)
            challengeBtn.Position = UDim2.new(1, -110, 0, 8)
            challengeBtn.BackgroundColor3 = Color3.fromRGB(180, 80, 255)
            challengeBtn.Text = "Challenge!"
            challengeBtn.TextColor3 = Color3.new(1, 1, 1)
            challengeBtn.TextScaled = true
            challengeBtn.Font = Enum.Font.GothamBold
            challengeBtn.Parent = card
            Instance.new("UICorner", challengeBtn).CornerRadius = UDim.new(0, 8)

            challengeBtn.MouseButton1Click:Connect(function()
                challengeBtn.Text = "Sent!"
                challengeBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 100)
                Remotes.ChallengePlayer:FireServer(other.UserId)
            end)
        end
    end
end

-- ============================================================
-- CHALLENGE INCOMING NOTIFICATION
-- ============================================================
local function showChallengeIncoming(challengerUserId, challengerName, challengerStars)
    -- Show accept/decline popup
    local popup = Instance.new("ScreenGui")
    popup.Name = "ChallengePopup"
    popup.DisplayOrder = 25
    popup.Parent = playerGui

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0.4, 0, 0, 120)
    frame.Position = UDim2.new(0.3, 0, 0.3, 0)
    frame.BackgroundColor3 = Color3.fromRGB(30, 20, 50)
    frame.Parent = popup
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 12)
    local s = Instance.new("UIStroke"); s.Color = Color3.fromRGB(255, 200, 100); s.Thickness = 2; s.Parent = frame

    local msg = Instance.new("TextLabel")
    msg.Size = UDim2.new(1, -20, 0, 50)
    msg.Position = UDim2.new(0, 10, 0, 10)
    msg.BackgroundTransparency = 1
    msg.Text = challengerName .. " (" .. challengerStars .. " stars) challenges you to a duel!"
    msg.TextColor3 = Color3.fromRGB(255, 215, 100)
    msg.TextScaled = true
    msg.Font = Enum.Font.GothamBold
    msg.Parent = frame

    local acceptBtn = Instance.new("TextButton")
    acceptBtn.Size = UDim2.new(0.4, 0, 0, 35)
    acceptBtn.Position = UDim2.new(0.05, 0, 0, 70)
    acceptBtn.BackgroundColor3 = Color3.fromRGB(50, 180, 50)
    acceptBtn.Text = "ACCEPT"
    acceptBtn.TextColor3 = Color3.new(1, 1, 1)
    acceptBtn.TextScaled = true
    acceptBtn.Font = Enum.Font.GothamBold
    acceptBtn.Parent = frame
    Instance.new("UICorner", acceptBtn).CornerRadius = UDim.new(0, 8)

    local declineBtn = Instance.new("TextButton")
    declineBtn.Size = UDim2.new(0.4, 0, 0, 35)
    declineBtn.Position = UDim2.new(0.55, 0, 0, 70)
    declineBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
    declineBtn.Text = "DECLINE"
    declineBtn.TextColor3 = Color3.new(1, 1, 1)
    declineBtn.TextScaled = true
    declineBtn.Font = Enum.Font.GothamBold
    declineBtn.Parent = frame
    Instance.new("UICorner", declineBtn).CornerRadius = UDim.new(0, 8)

    acceptBtn.MouseButton1Click:Connect(function()
        Remotes.ChallengeResponse:FireServer("accept", challengerUserId)
        popup:Destroy()
    end)
    declineBtn.MouseButton1Click:Connect(function()
        Remotes.ChallengeResponse:FireServer("decline", challengerUserId)
        popup:Destroy()
    end)

    -- Auto-dismiss after 20s
    task.delay(20, function() if popup.Parent then popup:Destroy() end end)
end

-- ============================================================
-- LOADOUT UI
-- ============================================================
local function showLoadoutUI(duelState)
    for _, c in ipairs(content:GetChildren()) do c:Destroy() end
    title.Text = "LOADOUT — Pick up to 3 potions to wager!"
    arenaGui.Enabled = true

    -- Timer
    local timer = Instance.new("TextLabel")
    timer.Name = "LoadoutTimer"
    timer.Size = UDim2.new(1, 0, 0, 30)
    timer.BackgroundTransparency = 1
    timer.TextColor3 = Color3.fromRGB(255, 150, 100)
    timer.TextScaled = true
    timer.Font = Enum.Font.GothamBold
    timer.Parent = content

    -- Potion list
    local potionList = Instance.new("ScrollingFrame")
    potionList.Name = "PotionList"
    potionList.Size = UDim2.new(0.65, 0, 1, -80)
    potionList.Position = UDim2.new(0, 0, 0, 35)
    potionList.BackgroundTransparency = 0.9
    potionList.ScrollBarThickness = 6
    potionList.Parent = content
    local listLayout = Instance.new("UIListLayout"); listLayout.Padding = UDim.new(0, 4); listLayout.Parent = potionList

    -- Wager summary
    local wagerPanel = Instance.new("Frame")
    wagerPanel.Size = UDim2.new(0.32, 0, 1, -80)
    wagerPanel.Position = UDim2.new(0.67, 0, 0, 35)
    wagerPanel.BackgroundColor3 = Color3.fromRGB(30, 25, 45)
    wagerPanel.Parent = content
    Instance.new("UICorner", wagerPanel).CornerRadius = UDim.new(0, 10)

    local wagerTitle = Instance.new("TextLabel")
    wagerTitle.Size = UDim2.new(1, 0, 0, 25)
    wagerTitle.BackgroundTransparency = 1
    wagerTitle.Text = "Your Wagers"
    wagerTitle.TextColor3 = Color3.fromRGB(255, 200, 100)
    wagerTitle.TextScaled = true
    wagerTitle.Font = Enum.Font.GothamBold
    wagerTitle.Parent = wagerPanel

    local wagerList = Instance.new("TextLabel")
    wagerList.Name = "WagerList"
    wagerList.Size = UDim2.new(1, -10, 0, 100)
    wagerList.Position = UDim2.new(0, 5, 0, 30)
    wagerList.BackgroundTransparency = 1
    wagerList.Text = "None yet"
    wagerList.TextColor3 = Color3.fromRGB(200, 200, 220)
    wagerList.TextScaled = true
    wagerList.Font = Enum.Font.Gotham
    wagerList.TextYAlignment = Enum.TextYAlignment.Top
    wagerList.Parent = wagerPanel

    local powerLabel = Instance.new("TextLabel")
    powerLabel.Name = "PowerLabel"
    powerLabel.Size = UDim2.new(1, 0, 0, 30)
    powerLabel.Position = UDim2.new(0, 0, 0, 135)
    powerLabel.BackgroundTransparency = 1
    powerLabel.Text = "Power: 0"
    powerLabel.TextColor3 = Color3.fromRGB(255, 150, 255)
    powerLabel.TextScaled = true
    powerLabel.Font = Enum.Font.GothamBlack
    powerLabel.Parent = wagerPanel

    -- Confirm button
    local confirmBtn = Instance.new("TextButton")
    confirmBtn.Name = "ConfirmBtn"
    confirmBtn.Size = UDim2.new(0.9, 0, 0, 40)
    confirmBtn.Position = UDim2.new(0.05, 0, 1, -50)
    confirmBtn.BackgroundColor3 = Color3.fromRGB(50, 180, 50)
    confirmBtn.Text = "READY TO FIGHT!"
    confirmBtn.TextColor3 = Color3.new(1, 1, 1)
    confirmBtn.TextScaled = true
    confirmBtn.Font = Enum.Font.GothamBlack
    confirmBtn.Parent = wagerPanel
    Instance.new("UICorner", confirmBtn).CornerRadius = UDim.new(0, 10)

    confirmBtn.MouseButton1Click:Connect(function()
        Remotes.ConfirmLoadout:FireServer()
        confirmBtn.Text = "WAITING..."
        confirmBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 100)
    end)

    -- Populate potion list from inventory
    local myData = Remotes.GetPlayerData:InvokeServer()
    local wagers = {}

    local function refreshWagerDisplay()
        local texts = {}
        local totalPower = 0
        for _, pid in ipairs(wagers) do
            local baseId, mut = Potions.parsePotionKey(pid)
            local p = Potions.Data[baseId]
            local name = p and p.name or pid
            if mut then name = mut .. " " .. name end
            local power = ArenaTuning.getPotionPower(pid, Potions.Data, MutationTuning)
            totalPower = totalPower + power
            table.insert(texts, name .. " (" .. power .. ")")
        end
        wagerList.Text = #texts > 0 and table.concat(texts, "\n") or "None yet"
        powerLabel.Text = "Power: " .. totalPower
    end

    if myData and myData.Potions then
        for potionId, qty in pairs(myData.Potions) do
            if qty > 0 then
                local baseId, mut = Potions.parsePotionKey(potionId)
                local p = Potions.Data[baseId]
                if not p then continue end
                local displayName = mut and (mut .. " " .. p.name) or p.name
                local power = ArenaTuning.getPotionPower(potionId, Potions.Data, MutationTuning)

                local btn = Instance.new("TextButton")
                btn.Size = UDim2.new(1, -10, 0, 36)
                btn.BackgroundColor3 = Color3.fromRGB(45, 40, 60)
                btn.Text = displayName .. " x" .. qty .. "  [" .. power .. " power]"
                btn.TextColor3 = Color3.new(1, 1, 1)
                btn.TextScaled = true
                btn.Font = Enum.Font.Gotham
                btn.TextXAlignment = Enum.TextXAlignment.Left
                btn.Parent = potionList
                Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
                local pad = Instance.new("UIPadding"); pad.PaddingLeft = UDim.new(0, 8); pad.Parent = btn

                btn.MouseButton1Click:Connect(function()
                    if #wagers >= ArenaTuning.MaxWagers then return end
                    Remotes.WagerPotion:FireServer(potionId)
                    table.insert(wagers, potionId)
                    refreshWagerDisplay()
                    btn.BackgroundColor3 = Color3.fromRGB(80, 60, 100)
                end)
            end
        end
    end

    -- Timer update
    task.spawn(function()
        while arenaGui.Enabled and content:FindFirstChild("LoadoutTimer") do
            local remaining = (duelState.phaseEndUnix or 0) - os.time()
            if remaining < 0 then remaining = 0 end
            timer.Text = "Time remaining: " .. remaining .. "s"
            task.wait(1)
        end
    end)
end

-- ============================================================
-- FIGHT UI + VFX + AUDIO + BOOST
-- ============================================================
local function showFightUI(duelState)
    for _, c in ipairs(content:GetChildren()) do c:Destroy() end
    title.Text = "FIGHT!"
    arenaGui.Enabled = true

    -- VS display
    local vsLabel = Instance.new("TextLabel")
    vsLabel.Size = UDim2.new(1, 0, 0, 40)
    vsLabel.BackgroundTransparency = 1
    vsLabel.Text = duelState.player1.name .. "  VS  " .. duelState.player2.name
    vsLabel.TextColor3 = Color3.fromRGB(255, 215, 100)
    vsLabel.TextScaled = true
    vsLabel.Font = Enum.Font.GothamBlack
    vsLabel.Parent = content

    -- Energy bars (side by side)
    local barFrame = Instance.new("Frame")
    barFrame.Size = UDim2.new(1, 0, 0, 40)
    barFrame.Position = UDim2.new(0, 0, 0, 50)
    barFrame.BackgroundTransparency = 1
    barFrame.Parent = content

    -- Player 1 bar (left)
    local bar1Bg = Instance.new("Frame")
    bar1Bg.Size = UDim2.new(0.45, 0, 1, 0)
    bar1Bg.BackgroundColor3 = Color3.fromRGB(40, 30, 60)
    bar1Bg.Parent = barFrame
    Instance.new("UICorner", bar1Bg).CornerRadius = UDim.new(0, 8)
    local bar1Fill = Instance.new("Frame")
    bar1Fill.Name = "Fill1"
    bar1Fill.Size = UDim2.new(0, 0, 1, 0)
    bar1Fill.BackgroundColor3 = Color3.fromRGB(100, 200, 255)
    bar1Fill.Parent = bar1Bg
    Instance.new("UICorner", bar1Fill).CornerRadius = UDim.new(0, 8)

    -- Player 2 bar (right)
    local bar2Bg = Instance.new("Frame")
    bar2Bg.Size = UDim2.new(0.45, 0, 1, 0)
    bar2Bg.Position = UDim2.new(0.55, 0, 0, 0)
    bar2Bg.BackgroundColor3 = Color3.fromRGB(40, 30, 60)
    bar2Bg.Parent = barFrame
    Instance.new("UICorner", bar2Bg).CornerRadius = UDim.new(0, 8)
    local bar2Fill = Instance.new("Frame")
    bar2Fill.Name = "Fill2"
    bar2Fill.Size = UDim2.new(0, 0, 1, 0)
    bar2Fill.BackgroundColor3 = Color3.fromRGB(255, 100, 200)
    bar2Fill.Parent = bar2Bg
    Instance.new("UICorner", bar2Fill).CornerRadius = UDim.new(0, 8)

    -- Click counter
    local clickLabel = Instance.new("TextLabel")
    clickLabel.Name = "ClickCount"
    clickLabel.Size = UDim2.new(1, 0, 0, 30)
    clickLabel.Position = UDim2.new(0, 0, 0, 95)
    clickLabel.BackgroundTransparency = 1
    clickLabel.Text = "BOOST: 0 / " .. ArenaTuning.MaxBoostClicks
    clickLabel.TextColor3 = Color3.fromRGB(255, 255, 200)
    clickLabel.TextScaled = true
    clickLabel.Font = Enum.Font.GothamBold
    clickLabel.Parent = content

    -- BIG PULSING BOOST BUTTON
    local boostBtn = Instance.new("TextButton")
    boostBtn.Name = "BoostBtn"
    boostBtn.Size = UDim2.new(0.5, 0, 0, 100)
    boostBtn.Position = UDim2.new(0.25, 0, 0.5, -20)
    boostBtn.BackgroundColor3 = Color3.fromRGB(255, 150, 50)
    boostBtn.Text = "BOOST!"
    boostBtn.TextColor3 = Color3.new(1, 1, 1)
    boostBtn.TextScaled = true
    boostBtn.Font = Enum.Font.GothamBlack
    boostBtn.Parent = content
    Instance.new("UICorner", boostBtn).CornerRadius = UDim.new(0, 20)
    local boostStroke = Instance.new("UIStroke")
    boostStroke.Color = Color3.fromRGB(255, 220, 100)
    boostStroke.Thickness = 4
    boostStroke.Parent = boostBtn

    -- Timer
    local fightTimer = Instance.new("TextLabel")
    fightTimer.Name = "FightTimer"
    fightTimer.Size = UDim2.new(1, 0, 0, 30)
    fightTimer.Position = UDim2.new(0, 0, 1, -35)
    fightTimer.BackgroundTransparency = 1
    fightTimer.TextColor3 = Color3.fromRGB(255, 100, 100)
    fightTimer.TextScaled = true
    fightTimer.Font = Enum.Font.GothamBold
    fightTimer.Parent = content

    -- Boost click handler
    local myClicks = 0
    local isMyP1 = duelState.player1.userId == player.UserId

    boostBtn.MouseButton1Click:Connect(function()
        if myClicks >= ArenaTuning.MaxBoostClicks then return end
        myClicks = myClicks + 1
        Remotes.BoostClick:FireServer()
        clickLabel.Text = "BOOST: " .. myClicks .. " / " .. ArenaTuning.MaxBoostClicks

        -- Visual feedback: flash the button
        boostBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 150)
        task.delay(0.05, function()
            if boostBtn.Parent then
                boostBtn.BackgroundColor3 = Color3.fromRGB(255, 150, 50)
            end
        end)

        -- Update my energy bar
        local pct = myClicks / ArenaTuning.MaxBoostClicks
        local myFill = isMyP1 and bar1Fill or bar2Fill
        TweenService:Create(myFill, TweenInfo.new(0.1), { Size = UDim2.new(pct, 0, 1, 0) }):Play()
    end)

    -- Pulse animation on boost button
    task.spawn(function()
        while boostBtn.Parent do
            TweenService:Create(boostBtn, TweenInfo.new(0.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
                Size = UDim2.new(0.55, 0, 0, 110),
                Position = UDim2.new(0.225, 0, 0.5, -25),
            }):Play()
            task.wait(0.4)
            TweenService:Create(boostBtn, TweenInfo.new(0.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
                Size = UDim2.new(0.5, 0, 0, 100),
                Position = UDim2.new(0.25, 0, 0.5, -20),
            }):Play()
            task.wait(0.4)
        end
    end)

    -- === FIGHT AUDIO ===
    local arena = workspace:FindFirstChild("Zones") and workspace.Zones:FindFirstChild("Arena")
    local soundParent = arena or workspace

    -- Epic battle music
    local battleMusic = Instance.new("Sound")
    battleMusic.Name = "BattleMusic"
    battleMusic.SoundId = "rbxassetid://1837849285"
    battleMusic.Looped = true
    battleMusic.Volume = 0.4
    battleMusic.PlaybackSpeed = 1.3
    battleMusic.Parent = soundParent
    battleMusic:Play()
    table.insert(fightSounds, battleMusic)

    -- Rumble loop
    local rumble = Instance.new("Sound")
    rumble.Name = "FightRumble"
    rumble.SoundId = "rbxasset://sounds/action_falling.mp3"
    rumble.Looped = true
    rumble.Volume = 0.3
    rumble.PlaybackSpeed = 0.5
    rumble.Parent = soundParent
    rumble:Play()
    table.insert(fightSounds, rumble)

    -- Escalate audio with time
    task.spawn(function()
        local startTime = tick()
        while boostBtn.Parent do
            local elapsed = tick() - startTime
            local pct = math.clamp(elapsed / ArenaTuning.FightSeconds, 0, 1)
            battleMusic.Volume = 0.3 + pct * 0.5
            battleMusic.PlaybackSpeed = 1.3 + pct * 0.4
            rumble.Volume = 0.2 + pct * 0.6
            rumble.PlaybackSpeed = 0.5 + pct * 0.4

            -- Random fire bursts at high intensity
            if pct > 0.5 and math.random() < 0.15 then
                local burst = Instance.new("Sound")
                burst.SoundId = "rbxassetid://130113370"
                burst.Volume = 0.3 + pct * 0.4
                burst.PlaybackSpeed = 0.8 + math.random() * 0.4
                burst.Parent = soundParent
                burst:Play()
                table.insert(fightSounds, burst)
            end

            -- Thunder at very high intensity
            if pct > 0.75 and math.random() < 0.08 then
                local thunder = Instance.new("Sound")
                thunder.SoundId = "rbxassetid://142070127"
                thunder.Volume = 0.5 + pct * 0.3
                thunder.Parent = soundParent
                thunder:Play()
                table.insert(fightSounds, thunder)
            end

            -- Timer display
            local remaining = math.max(0, ArenaTuning.FightSeconds - elapsed)
            fightTimer.Text = string.format("%.1f", remaining)

            task.wait(0.1)
        end
    end)

    -- === FIGHT VFX (camera shake + screen flash) ===
    task.spawn(function()
        local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
        local startTime = tick()
        while boostBtn.Parent do
            local elapsed = tick() - startTime
            local pct = math.clamp(elapsed / ArenaTuning.FightSeconds, 0, 1)
            if hum then
                local intensity = 0.05 + pct * 0.3
                local x = (math.random() - 0.5) * 2 * intensity
                local y = (math.random() - 0.5) * 2 * intensity
                hum.CameraOffset = Vector3.new(x, y, 0)
            end
            task.wait(0.03)
        end
        if hum then hum.CameraOffset = Vector3.new(0, 0, 0) end
    end)
end

-- ============================================================
-- RESULT UI
-- ============================================================
local function showResultUI(duelState)
    for _, c in ipairs(content:GetChildren()) do c:Destroy() end

    -- Stop fight audio
    for _, s in ipairs(fightSounds) do
        if s and s.Parent then s:Destroy() end
    end
    fightSounds = {}

    local isWinner = duelState.winnerId == player.UserId
    title.Text = isWinner and "VICTORY!" or "DEFEAT"
    arenaGui.Enabled = true

    -- Play result sounds
    if isWinner then
        local victorySound = Instance.new("Sound")
        victorySound.SoundId = "rbxassetid://9125402735"
        victorySound.Volume = 1
        victorySound.Parent = workspace
        victorySound:Play()

        local chime = Instance.new("Sound")
        chime.SoundId = "rbxassetid://169380525"
        chime.Volume = 0.8
        chime.PlaybackSpeed = 0.7
        chime.Parent = workspace
        chime:Play()

        task.delay(3, function() victorySound:Destroy() chime:Destroy() end)
    else
        local defeatSound = Instance.new("Sound")
        defeatSound.SoundId = "rbxassetid://142070127"
        defeatSound.Volume = 0.6
        defeatSound.Parent = workspace
        defeatSound:Play()
        task.delay(3, function() defeatSound:Destroy() end)
    end

    -- Result message
    local resultMsg = Instance.new("TextLabel")
    resultMsg.Size = UDim2.new(1, 0, 0, 40)
    resultMsg.BackgroundTransparency = 1
    resultMsg.Text = duelState.player1.name .. " (" .. (duelState.player1.power or "?") .. ") vs " .. duelState.player2.name .. " (" .. (duelState.player2.power or "?") .. ")"
    resultMsg.TextColor3 = Color3.fromRGB(200, 200, 220)
    resultMsg.TextScaled = true
    resultMsg.Font = Enum.Font.GothamBold
    resultMsg.Parent = content

    if isWinner then
        -- Show loser's wagers to pick from
        local pickLabel = Instance.new("TextLabel")
        pickLabel.Size = UDim2.new(1, 0, 0, 30)
        pickLabel.Position = UDim2.new(0, 0, 0, 50)
        pickLabel.BackgroundTransparency = 1
        pickLabel.Text = "Choose your reward from their wagers:"
        pickLabel.TextColor3 = Color3.fromRGB(255, 215, 100)
        pickLabel.TextScaled = true
        pickLabel.Font = Enum.Font.GothamBold
        pickLabel.Parent = content

        -- Fetch full duel state to see opponent wagers
        local fullState = Remotes.GetDuelState:InvokeServer()
        local opponentWagers = fullState and fullState.opponentWagers or {}

        local y = 90
        for _, potionId in ipairs(opponentWagers) do
            local baseId, mut = Potions.parsePotionKey(potionId)
            local p = Potions.Data[baseId]
            local displayName = p and p.name or potionId
            if mut then displayName = mut .. " " .. displayName end
            local power = ArenaTuning.getPotionPower(potionId, Potions.Data, MutationTuning)

            local claimBtn = Instance.new("TextButton")
            claimBtn.Size = UDim2.new(0.8, 0, 0, 40)
            claimBtn.Position = UDim2.new(0.1, 0, 0, y)
            claimBtn.BackgroundColor3 = Color3.fromRGB(200, 150, 50)
            claimBtn.Text = "CLAIM: " .. displayName .. " (" .. power .. " power)"
            claimBtn.TextColor3 = Color3.new(1, 1, 1)
            claimBtn.TextScaled = true
            claimBtn.Font = Enum.Font.GothamBold
            claimBtn.Parent = content
            Instance.new("UICorner", claimBtn).CornerRadius = UDim.new(0, 10)

            claimBtn.MouseButton1Click:Connect(function()
                Remotes.ClaimDuelReward:FireServer(potionId)
                claimBtn.Text = "CLAIMED!"
                claimBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
                task.delay(2, function() arenaGui.Enabled = false end)
            end)

            y = y + 50
        end
    else
        local lossMsg = Instance.new("TextLabel")
        lossMsg.Size = UDim2.new(1, 0, 0, 40)
        lossMsg.Position = UDim2.new(0, 0, 0, 60)
        lossMsg.BackgroundTransparency = 1
        lossMsg.Text = "Your opponent is choosing a potion from your wagers..."
        lossMsg.TextColor3 = Color3.fromRGB(200, 150, 150)
        lossMsg.TextScaled = true
        lossMsg.Font = Enum.Font.Gotham
        lossMsg.Parent = content
    end
end

-- ============================================================
-- DUEL STATE LISTENER
-- ============================================================
Remotes.DuelStateUpdate.OnClientEvent:Connect(function(duelState)
    currentDuel = duelState
    if duelState.state == "loadout" then
        showLoadoutUI(duelState)
    elseif duelState.state == "fighting" then
        showFightUI(duelState)
    elseif duelState.state == "result" then
        showResultUI(duelState)
    elseif duelState.state == "done" then
        arenaGui.Enabled = false
        currentDuel = nil
    end
end)

-- Listen for incoming challenges
Remotes.ChallengeResponse.OnClientEvent:Connect(function(action, challengerUserId, challengerName, challengerStars)
    if action == "incoming" then
        showChallengeIncoming(challengerUserId, challengerName, challengerStars)
    end
end)

-- ============================================================
-- ARENA PROXIMITY PROMPT (Challenge Board)
-- ============================================================
ProximityPromptService.PromptTriggered:Connect(function(prompt, triggerPlayer)
    if triggerPlayer ~= player then return end
    if prompt.Parent and prompt.Parent.Name == "ChallengeBoard" then
        arenaGui.Enabled = true
        showChallengeBoard()
    end
end)

print("[ArenaController] Initialized (Sprint 012 - Potion Arena)")
