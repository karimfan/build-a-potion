local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Types = require(RS.Shared.Types)
local Ingredients = require(RS.Shared.Config.Ingredients)
local Remotes = RS.Remotes

-- Forage cooldowns: forageCooldowns[userId][nodeId] = expiry time
local forageCooldowns = {}

-- Common ingredients that can be foraged
local FORAGEABLE = {"mushroom", "fern_leaf", "river_water", "dewdrop", "moss_clump", "wind_blossom"}

-- ForageNode handler
Remotes.ForageNode.OnServerEvent:Connect(function(player, nodeId)
    if type(nodeId) ~= "string" then return end
    
    local pds = _G.PlayerDataService
    if not pds then return end
    
    local data = pds.getData(player)
    if not data then return end
    
    -- Check cooldown
    local userId = player.UserId
    if not forageCooldowns[userId] then
        forageCooldowns[userId] = {}
    end
    
    local now = os.time()
    local expiry = forageCooldowns[userId][nodeId] or 0
    if now < expiry then
        return  -- still on cooldown
    end
    
    -- Set cooldown
    forageCooldowns[userId][nodeId] = now + Types.FORAGE_COOLDOWN_SECONDS
    
    -- Award random common ingredient
    local ingredientId = FORAGEABLE[math.random(1, #FORAGEABLE)]
    data.Ingredients[ingredientId] = (data.Ingredients[ingredientId] or 0) + 1
    
    local ingredient = Ingredients.Data[ingredientId]
    print("[ZoneService] " .. player.Name .. " foraged " .. ingredient.name .. " from node " .. nodeId)
    
    -- Notify client
    pds.notifyClient(player)
end)

-- Cleanup on leave
Players.PlayerRemoving:Connect(function(player)
    forageCooldowns[player.UserId] = nil
end)

print("[ZoneService] Initialized")
