local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Types = require(RS.Shared.Types)
local Ingredients = require(RS.Shared.Config.Ingredients)
local Remotes = RS.Remotes

-- Forage cooldowns: forageCooldowns[userId][nodeId] = expiry time
local forageCooldowns = {}

-- Common ingredients that can be foraged
local FORAGEABLE = {"mushroom", "fern_leaf", "river_water", "charcoal_chunk", "dandelion_puff", "clay_mud", "pebble_dust", "mint_sprig", "snail_slime", "willow_bark", "rainwater", "acorn_cap", "cobweb_strand"}

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
    local NP={ForageNode_1={"mushroom","willow_bark","snail_slime"},ForageNode_2={"river_water","rainwater","snail_slime"},ForageNode_3={"fern_leaf","mint_sprig","dandelion_puff"},ForageNode_4={"cobweb_strand","charcoal_chunk","pebble_dust"},ForageNode_5={"acorn_cap","pebble_dust","willow_bark"},ForageNode_6={"clay_mud","honey_drop","firefly_glow"}}
    local pool = NP[nodeId] or {"mushroom"}
    local ingredientId = pool[math.random(1, #pool)]
    -- V3: Add as fresh stack
    local pdsModule = _G.PlayerDataService
    if pdsModule and pdsModule.addIngredientStack then
        pdsModule.addIngredientStack(data, ingredientId, 1, "forage")
    end
    
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
