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
    local nodePools = {
        ForageNode_1={"mushroom","willow_bark","snail_slime"},
        ForageNode_2={"river_water","rainwater","snail_slime"},
        ForageNode_3={"fern_leaf","mint_sprig","dandelion_puff"},
        ForageNode_4={"cobweb_strand","charcoal_chunk","pebble_dust"},
        ForageNode_5={"acorn_cap","pebble_dust","willow_bark"},
        ForageNode_6={"clay_mud","honey_drop","firefly_glow"},
        ForageNode_7={"mushroom","willow_bark","glowshroom_cap"},
        ForageNode_8={"river_water","rainwater","dewdrop_pearl"},
        ForageNode_9={"fern_leaf","mint_sprig","dandelion_puff"},
        ForageNode_10={"cobweb_strand","charcoal_chunk","nightshade_berry"},
        ForageNode_11={"acorn_cap","willow_bark","honey_drop"},
        ForageNode_12={"clay_mud","firefly_glow","mint_sprig"},
    }
    local pool = nodePools[nodeId] or {"mushroom"}
    local ingredientId = pool[math.random(1, #pool)]
    -- V3: Add as fresh stack
    local pdsModule = _G.PlayerDataService
    if pdsModule and pdsModule.addIngredientStack then
        pdsModule.addIngredientStack(data, ingredientId, 1, "forage")
    end

    local ingredient = Ingredients.Data[ingredientId]
    print("[ZoneService] " .. player.Name .. " foraged " .. (ingredient and ingredient.name or ingredientId) .. " from node " .. nodeId)

    -- Notify client
    pds.notifyClient(player)

    -- Soft storage warning
    if pds.isIngredientStorageFull and pds.isIngredientStorageFull(data) then
        local used = pds.getTotalIngredientUnits(data)
        local cap = pds.getIngredientCapacity(data)
        pcall(function()
            Remotes.GlobalAnnouncement:FireClient(player, "Inventory full! (" .. used .. "/" .. cap .. ") Brew or sell to make room.")
        end)
    end
end)

-- Cleanup on leave
Players.PlayerRemoving:Connect(function(player)
    forageCooldowns[player.UserId] = nil
end)

-- ========== RARE FORAGE NODES ==========
local RARE_UNCOMMON = {"moonpetal","ember_root","crystal_dust","frost_bloom","thundermoss","shadow_vine","sunstone_chip","dewdrop_pearl","pixie_wing","glowshroom_cap","mermaid_scale","nightshade_berry"}
local RARE_RARE = {"dragon_scale","phoenix_feather","void_essence","unicorn_tear","stormglass_shard","kraken_ink","frozen_amber","ghost_orchid"}

local rareNodeActive = false
local rareNodePart = nil

local function spawnRareNode()
    if rareNodeActive then return end
    rareNodeActive = true
    local grove = workspace.Zones and workspace.Zones:FindFirstChild("WildGrove")
    if not grove then rareNodeActive = false return end
    local x = math.random(-180, -80)
    local z = math.random(-50, 50)
    local isRare = math.random() < 0.30
    local pool = isRare and RARE_RARE or RARE_UNCOMMON
    local ingredientId = pool[math.random(1, #pool)]
    local ingData = Ingredients.Data[ingredientId]
    local tierName = isRare and "RARE" or "Uncommon"

    rareNodePart = Instance.new("Part")
    rareNodePart.Name = "RareForageNode"
    rareNodePart.Shape = Enum.PartType.Ball
    rareNodePart.Size = Vector3.new(5, 5, 5)
    rareNodePart.Position = Vector3.new(x, 4, z)
    rareNodePart.Anchored = true
    rareNodePart.CanCollide = false
    rareNodePart.Material = Enum.Material.Neon
    rareNodePart.Color = isRare and Color3.fromRGB(255, 200, 50) or Color3.fromRGB(100, 180, 255)
    rareNodePart.Parent = grove

    local light = Instance.new("PointLight")
    light.Color = rareNodePart.Color
    light.Brightness = 3
    light.Range = 25
    light.Parent = rareNodePart

    local particles = Instance.new("ParticleEmitter")
    particles.Color = ColorSequence.new(rareNodePart.Color)
    particles.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.5, 0.3), NumberSequenceKeypoint.new(1, 0)})
    particles.Lifetime = NumberRange.new(1, 3)
    particles.Rate = isRare and 15 or 8
    particles.Speed = NumberRange.new(1, 3)
    particles.SpreadAngle = Vector2.new(180, 180)
    particles.LightEmission = 1
    particles.Parent = rareNodePart

    local bb = Instance.new("BillboardGui")
    bb.Size = UDim2.new(0, 120, 0, 40)
    bb.StudsOffset = Vector3.new(0, 3, 0)
    bb.AlwaysOnTop = true
    bb.Parent = rareNodePart
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = tierName .. "!"
    label.TextColor3 = rareNodePart.Color
    label.TextScaled = true
    label.Font = Enum.Font.GothamBlack
    label.Parent = bb

    local prompt = Instance.new("ProximityPrompt")
    prompt.ActionText = "Forage"
    prompt.ObjectText = ingData and ingData.name or ingredientId
    prompt.MaxActivationDistance = 15
    prompt.RequiresLineOfSight = false
    prompt.Parent = rareNodePart

    prompt.Triggered:Connect(function(triggerPlayer)
        if not rareNodeActive then return end
        local pds = _G.PlayerDataService
        if not pds then return end
        local data = pds.getData(triggerPlayer)
        if not data then return end
        pds.addIngredientStack(data, ingredientId, 1, "forage")
        pds.notifyClient(triggerPlayer)
        print("[ZoneService] " .. triggerPlayer.Name .. " found " .. tierName .. ": " .. (ingData and ingData.name or ingredientId))
        rareNodeActive = false
        if rareNodePart then rareNodePart:Destroy() rareNodePart = nil end
        -- Soft storage warning
        if pds.isIngredientStorageFull and pds.isIngredientStorageFull(data) then
            local used = pds.getTotalIngredientUnits(data)
            local cap = pds.getIngredientCapacity(data)
            pcall(function()
                Remotes.GlobalAnnouncement:FireClient(triggerPlayer, "Inventory full! (" .. used .. "/" .. cap .. ") Brew or sell to make room.")
            end)
        end
    end)

    if Remotes:FindFirstChild("GlobalAnnouncement") then
        for _, p in ipairs(game.Players:GetPlayers()) do
            pcall(function() Remotes.GlobalAnnouncement:FireClient(p, "A " .. tierName .. " ingredient appeared in the Wild Grove!") end)
        end
    end

    print("[ZoneService] Rare node: " .. (ingData and ingData.name or ingredientId) .. " (" .. tierName .. ")")

    task.delay(60, function()
        if rareNodeActive and rareNodePart then
            rareNodePart:Destroy()
            rareNodePart = nil
            rareNodeActive = false
        end
    end)
end

task.spawn(function()
    task.wait(30)
    while true do
        spawnRareNode()
        task.wait(math.random(120, 240))
    end
end)


print("[ZoneService] Initialized")
