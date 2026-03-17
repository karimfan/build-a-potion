-- RobuxShopService: Handles Developer Product purchases via MarketplaceService
local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local RS = game:GetService("ReplicatedStorage")
local Ingredients = require(RS.Shared.Config.Ingredients)
local Potions = require(RS.Shared.Config.Potions)
local RobuxShopTuning = require(RS:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("RobuxShopTuning"))
local Remotes = RS:WaitForChild("Remotes")

-- Create shop remotes
if not Remotes:FindFirstChild("PromptRobuxPurchase") then
    local r = Instance.new("RemoteEvent"); r.Name = "PromptRobuxPurchase"; r.Parent = Remotes
end

-- ============================================================
-- GRANT FUNCTIONS
-- ============================================================

local function getRandomFromTier(dataTable, tier)
    local pool = {}
    for id, data in pairs(dataTable) do
        if data.tier == tier then
            table.insert(pool, id)
        end
    end
    if #pool == 0 then return nil end
    return pool[math.random(1, #pool)]
end

local function grantRandomIngredients(player, tier, count)
    local pds = _G.PlayerDataService
    if not pds then return false end
    local data = pds.getData(player)
    if not data then return false end

    local granted = {}
    for _ = 1, count do
        local ingredientId = getRandomFromTier(Ingredients.Data, tier)
        if ingredientId then
            pds.addIngredientStack(data, ingredientId, 1, "robux")
            table.insert(granted, ingredientId)
        end
    end

    pds.notifyClient(player)
    pds.forceSave(player)

    local names = {}
    for _, id in ipairs(granted) do
        local ing = Ingredients.Data[id]
        table.insert(names, ing and ing.name or id)
    end
    print("[RobuxShopService] " .. player.Name .. " received " .. count .. "x " .. tier .. " ingredients: " .. table.concat(names, ", "))

    -- Announce if rare+
    if tier == "Rare" or tier == "Mythic" or tier == "Divine" then
        pcall(function()
            if Remotes:FindFirstChild("GlobalAnnouncement") then
                Remotes.GlobalAnnouncement:FireClient(player, "Received " .. table.concat(names, ", ") .. " from the Robux Shop!")
            end
        end)
    end

    return true
end

local function grantRandomPotions(player, tier, count)
    local pds = _G.PlayerDataService
    if not pds then return false end
    local data = pds.getData(player)
    if not data then return false end

    local granted = {}
    for _ = 1, count do
        local potionId = getRandomFromTier(Potions.Data, tier)
        if potionId and potionId ~= "sludge" then
            data.Potions[potionId] = (data.Potions[potionId] or 0) + 1
            table.insert(granted, potionId)
        end
    end

    pds.notifyClient(player)
    pds.forceSave(player)

    local names = {}
    for _, id in ipairs(granted) do
        local p = Potions.Data[id]
        table.insert(names, p and p.name or id)
    end
    print("[RobuxShopService] " .. player.Name .. " received " .. count .. "x " .. tier .. " potions: " .. table.concat(names, ", "))

    if tier == "Rare" or tier == "Mythic" or tier == "Divine" then
        pcall(function()
            if Remotes:FindFirstChild("GlobalAnnouncement") then
                Remotes.GlobalAnnouncement:FireClient(player, "Received " .. table.concat(names, ", ") .. " from the Robux Shop!")
            end
        end)
    end

    return true
end

local function grantInstantBrew(player)
    local pds = _G.PlayerDataService
    if not pds then return false end
    local data = pds.getData(player)
    if not data or not data.ActiveBrew then return false end

    if data.ActiveBrew.Status == "brewing" then
        data.ActiveBrew.EndUnix = os.time() -- Set to now, making it instantly claimable
        pds.notifyClient(player)
        pds.forceSave(player)
        print("[RobuxShopService] " .. player.Name .. " used Instant Brew")
        return true
    end

    -- Refund scenario: not currently brewing
    pcall(function()
        if Remotes:FindFirstChild("GlobalAnnouncement") then
            Remotes.GlobalAnnouncement:FireClient(player, "No active brew to skip! Start a brew first.")
        end
    end)
    return false
end

local function grantMutationCharm(player)
    local pds = _G.PlayerDataService
    if not pds then return false end
    local data = pds.getData(player)
    if not data then return false end

    -- Store charm flag in player data
    if not data.Charms then data.Charms = {} end
    data.Charms.MutationGuarantee = true

    pds.notifyClient(player)
    pds.forceSave(player)
    print("[RobuxShopService] " .. player.Name .. " activated Mutation Charm")

    pcall(function()
        if Remotes:FindFirstChild("GlobalAnnouncement") then
            Remotes.GlobalAnnouncement:FireClient(player, "Mutation Charm activated! Your next brew is guaranteed to mutate!")
        end
    end)

    return true
end

-- ============================================================
-- PROCESS RECEIPT (Roblox callback)
-- ============================================================
local function processReceipt(receiptInfo)
    local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
    if not player then
        return Enum.ProductPurchaseDecision.NotProcessedYet
    end

    local product = RobuxShopTuning.getProductById(receiptInfo.ProductId)
    if not product then
        warn("[RobuxShopService] Unknown product ID: " .. tostring(receiptInfo.ProductId))
        return Enum.ProductPurchaseDecision.NotProcessedYet
    end

    local success = false

    if product.grantType == "random_ingredients" then
        success = grantRandomIngredients(player, product.grantTier, product.grantCount)
    elseif product.grantType == "random_potions" then
        success = grantRandomPotions(player, product.grantTier, product.grantCount)
    elseif product.grantType == "instant_brew" then
        success = grantInstantBrew(player)
    elseif product.grantType == "mutation_charm" then
        success = grantMutationCharm(player)
    else
        warn("[RobuxShopService] Unknown grant type: " .. tostring(product.grantType))
    end

    if success then
        print("[RobuxShopService] Purchase processed: " .. product.name .. " for " .. player.Name)
        return Enum.ProductPurchaseDecision.PurchaseGranted
    else
        return Enum.ProductPurchaseDecision.NotProcessedYet
    end
end

MarketplaceService.ProcessReceipt = processReceipt

-- ============================================================
-- PROMPT PURCHASE (from client)
-- ============================================================
Remotes.PromptRobuxPurchase.OnServerEvent:Connect(function(player, productIndex)
    if type(productIndex) ~= "number" then return end
    local product = RobuxShopTuning.Products[productIndex]
    if not product then return end
    if product.productId == 0 then
        -- Placeholder ID — products not yet created in Creator Dashboard
        pcall(function()
            Remotes.GlobalAnnouncement:FireClient(player, "This product hasn't been configured yet! Create Developer Products in the Creator Dashboard first.")
        end)
        return
    end
    MarketplaceService:PromptProductPurchase(player, product.productId)
end)

_G.RobuxShopService = {}
print("[RobuxShopService] Initialized (Sprint 013 - Robux Shop)")
