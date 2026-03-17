local RS = game:GetService("ReplicatedStorage")
local Potions = require(RS.Shared.Config.Potions)
local Remotes = RS.Remotes

-- Current daily demand state
local DailyDemand = {
    dateKey = "",
    demands = {},
}

-- Generate deterministic demands from date
local function generateDemands()
    local now = os.time()
    local dateKey = os.date("!%Y-%m-%d", now)  -- UTC date
    
    if DailyDemand.dateKey == dateKey then
        return -- already generated for today
    end
    
    -- Deterministic seed from date
    local seed = 0
    for i = 1, #dateKey do
        seed = seed + string.byte(dateKey, i) * (i * 137)
    end
    math.randomseed(seed)
    
    -- Collect potions by tier
    local byTier = { Common = {}, Uncommon = {}, Rare = {}, Mythic = {}, Divine = {} }
    for id, potion in pairs(Potions.Data) do
        if id ~= "sludge" then
            local baseId = id
            local sep = id:find("__")
            if not sep then  -- skip mutation variants
                table.insert(byTier[potion.tier] or {}, id)
            end
        end
    end
    
    -- Pick demands: 1 Common (2x), 1 Uncommon/Rare (3x), 1 Rare/Mythic (5x)
    local demands = {}
    
    -- Demand 1: Common potion at 2x
    if #byTier.Common > 0 then
        local pick = byTier.Common[math.random(1, #byTier.Common)]
        table.insert(demands, { potionId = pick, multiplier = 2, tier = "Common" })
    end
    
    -- Demand 2: Uncommon or Rare at 3x
    local midPool = {}
    for _, id in ipairs(byTier.Uncommon) do table.insert(midPool, id) end
    for _, id in ipairs(byTier.Rare) do table.insert(midPool, id) end
    if #midPool > 0 then
        local pick = midPool[math.random(1, #midPool)]
        table.insert(demands, { potionId = pick, multiplier = 3, tier = Potions.Data[pick] and Potions.Data[pick].tier or "Uncommon" })
    end
    
    -- Demand 3: Rare or Mythic at 5x
    local highPool = {}
    for _, id in ipairs(byTier.Rare) do table.insert(highPool, id) end
    for _, id in ipairs(byTier.Mythic) do table.insert(highPool, id) end
    if #highPool > 0 then
        local pick = highPool[math.random(1, #highPool)]
        table.insert(demands, { potionId = pick, multiplier = 5, tier = Potions.Data[pick] and Potions.Data[pick].tier or "Rare" })
    end
    
    -- Reset random seed
    math.randomseed(os.time())
    
    DailyDemand.dateKey = dateKey
    DailyDemand.demands = demands
    
    -- Log
    local names = {}
    for _, d in ipairs(demands) do
        local p = Potions.Data[d.potionId]
        table.insert(names, (p and p.name or d.potionId) .. " " .. d.multiplier .. "x")
    end
    print("[DailyDemandService] Today's demands: " .. table.concat(names, ", "))
end

-- Public API
local module = {}

function module.getDemands()
    generateDemands()
    return DailyDemand
end

function module.getDemandMultiplier(potionId)
    generateDemands()
    -- Parse base ID from compound key
    local baseId = potionId
    local sep = potionId:find("__")
    if sep then baseId = potionId:sub(1, sep - 1) end
    
    for _, demand in ipairs(DailyDemand.demands) do
        if demand.potionId == baseId then
            return demand.multiplier
        end
    end
    return 1  -- no bonus
end

_G.DailyDemandService = module

-- Create GetDailyDemand remote if needed
if not Remotes:FindFirstChild("GetDailyDemand") then
    local r = Instance.new("RemoteFunction")
    r.Name = "GetDailyDemand"
    r.Parent = Remotes
end

Remotes.GetDailyDemand.OnServerInvoke = function(player)
    return module.getDemands()
end

-- Generate on startup
generateDemands()

-- Check for day change every 5 minutes
task.spawn(function()
    while true do
        task.wait(300)
        generateDemands()
    end
end)

print("[DailyDemandService] Initialized")