-- DemandBoardController: Updates the Daily Demand Board in Trading Post
local RS = game:GetService("ReplicatedStorage")
local Remotes = RS.Remotes
local Potions = require(RS.Shared.Config.Potions)

local function updateBoard()
    local board = workspace:FindFirstChild("Zones")
        and workspace.Zones:FindFirstChild("TradingPost")
        and workspace.Zones.TradingPost:FindFirstChild("DailyDemandBoard")
    if not board then return end

    local sg = board:FindFirstChild("DemandGui")
    if not sg then return end

    -- Fetch demand data
    local ok, demandData = pcall(function()
        return Remotes.GetDailyDemand:InvokeServer()
    end)
    if not ok or not demandData or not demandData.demands then return end

    for i, demand in ipairs(demandData.demands) do
        local slot = sg:FindFirstChild("Demand_" .. i)
        if not slot then continue end

        local potion = Potions.Data[demand.potionId]
        local nameLabel = slot:FindFirstChild("PotionName")
        local multLabel = slot:FindFirstChild("Multiplier")
        local tierLabel = slot:FindFirstChild("TierLabel")

        if nameLabel then
            nameLabel.Text = potion and potion.name or demand.potionId
        end
        if multLabel then
            multLabel.Text = demand.multiplier .. "x"
            -- Color by multiplier
            if demand.multiplier >= 5 then
                multLabel.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
            elseif demand.multiplier >= 3 then
                multLabel.BackgroundColor3 = Color3.fromRGB(255, 200, 50)
            else
                multLabel.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
            end
        end
        if tierLabel then
            tierLabel.Text = (potion and potion.tier or "") .. " | Sell for " .. demand.multiplier .. "x bonus!"
        end
    end
end

-- Update on load and periodically
task.spawn(function()
    task.wait(5)
    updateBoard()
end)

-- Refresh every 5 minutes
task.spawn(function()
    while true do
        task.wait(300)
        updateBoard()
    end
end)

print("[DemandBoardController] Initialized")
