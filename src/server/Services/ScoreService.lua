local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Potions = require(RS.Shared.Config.Potions)

-- Score tier weights
local TierWeights = {
    Common = 10,
    Uncommon = 25,
    Rare = 100,
    Mythic = 500,
    Divine = 5000,
}

-- Mutation point bonuses
local MutationBonusPoints = {
    Glowing = 10,
    Bubbling = 20,
    Crystallized = 30,
    Shadow = 60,
    Rainbow = 120,
    Golden = 250,
}

local module = {}

-- Recompute composite score from player data
function module.recomputeScore(data)
    if not data or not data.Score then return 0 end
    
    local score = data.Score
    
    -- Time score: 1 point per minute played
    local timeScore = math.floor(score.TimePlayedMinutes or 0)
    
    -- Brew score: sum of tier weights * count for all brewed potions
    local brewScore = 0
    local mutationScore = 0
    if data.BrewStats and data.BrewStats.PotionCounts then
        for potionKey, count in pairs(data.BrewStats.PotionCounts) do
            -- Parse compound key for mutations
            local baseId = potionKey
            local mutation = nil
            local sep = potionKey:find("__")
            if sep then
                baseId = potionKey:sub(1, sep - 1)
                mutation = potionKey:sub(sep + 2)
            end
            
            local potion = Potions.Data[baseId]
            if potion then
                local weight = TierWeights[potion.tier] or 10
                brewScore = brewScore + (weight * count)
            end
            
            if mutation and MutationBonusPoints[mutation] then
                mutationScore = mutationScore + (MutationBonusPoints[mutation] * count)
            end
        end
    end
    
    -- Trade score: 1 point per 10 coins earned from selling
    local tradeScore = math.floor((score.TotalCoinsFromSelling or 0) / 10)
    
    -- Composite
    local composite = timeScore + brewScore + mutationScore + tradeScore
    
    -- Cache the values
    score.BrewScoreCache = brewScore
    score.MutationScoreCache = mutationScore
    score.CompositeScore = composite
    
    return composite
end

-- Increment time played (called every 60 seconds)
function module.incrementPlayTime(data)
    if not data or not data.Score then return end
    data.Score.TimePlayedMinutes = (data.Score.TimePlayedMinutes or 0) + 1
    module.recomputeScore(data)
end

-- Record coins earned from selling
function module.addSellCoins(data, coins)
    if not data or not data.Score then return end
    data.Score.TotalCoinsFromSelling = (data.Score.TotalCoinsFromSelling or 0) + coins
    module.recomputeScore(data)
end

_G.ScoreService = module

-- Time tracking loop: increment every 60s for all connected players
task.spawn(function()
    while true do
        task.wait(60)
        local pds = _G.PlayerDataService
        if pds then
            for _, player in ipairs(Players:GetPlayers()) do
                local data = pds.getData(player)
                if data then
                    module.incrementPlayTime(data)
                    pds.notifyClient(player)
                end
            end
        end
    end
end)

print("[ScoreService] Initialized")