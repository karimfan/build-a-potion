local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Types = require(RS.Shared.Types)
local Ingredients = require(RS.Shared.Config.Ingredients)
local MarketTuning = require(RS.Shared.Config.MarketTuning)
local Remotes = RS.Remotes

local module = {}

local REFRESH_SECONDS = MarketTuning.REFRESH_SECONDS

-- Current market state (global per server)
local MarketState = {
	RefreshTime = 0,
	Offers = {},
}

-- Generate offers with guaranteed minimums per tier
local function generateOffers()
	local offers = {}
	local tierCounts = { Common = 0, Uncommon = 0, Rare = 0, Mythic = 0, Divine = 0 }
	local usedIds = {}
	local now = os.time()

	-- Collect all market-eligible ingredients
	local eligible = Ingredients.getMarketEligible()

	-- Shuffle for fairness
	for i = #eligible, 2, -1 do
		local j = math.random(1, i)
		eligible[i], eligible[j] = eligible[j], eligible[i]
	end

	local function addOffer(ing, isFlashSale)
		local tier = ing.tier
		local stockCfg = MarketTuning.TierRules[tier]
		local minStock = stockCfg and stockCfg.minStock or 10
		local maxStock = stockCfg and stockCfg.maxStock or 20
		local stock = math.random(minStock, maxStock)

		table.insert(offers, {
			ingredientId = ing.id,
			name = ing.name,
			tier = ing.tier,
			element = ing.element,
			price = ing.cost,
			stock = stock,
			generatedAtUnix = now,
			flashSale = isFlashSale or false,
		})

		tierCounts[tier] = (tierCounts[tier] or 0) + 1
		usedIds[ing.id] = true
	end

	-- Step 1: Roll each ingredient probabilistically (existing logic)
	local tierCaps = MarketTuning.TierCaps
	for _, ing in ipairs(eligible) do
		local tier = ing.tier
		local cap = tierCaps[tier] or 5

		if tierCounts[tier] and tierCounts[tier] >= cap then
			continue
		end

		if math.random() <= (ing.marketChance or 0) then
			addOffer(ing, false)
		end
	end

	-- Step 2: Deterministic backfill to meet guaranteed minimums
	local function backfillTier(tierName, minimum)
		if tierCounts[tierName] >= minimum then return end
		local pool = Ingredients.getByTier(tierName)
		-- Shuffle
		for i = #pool, 2, -1 do
			local j = math.random(1, i)
			pool[i], pool[j] = pool[j], pool[i]
		end
		for _, ing in ipairs(pool) do
			if tierCounts[tierName] >= minimum then break end
			if not usedIds[ing.id] and ing.acquisition and ing.acquisition.market then
				addOffer(ing, false)
			end
		end
	end

	backfillTier("Common", MarketTuning.MinCommon)
	backfillTier("Uncommon", MarketTuning.MinUncommon)

	-- Step 3: Guarantee at least 1 Rare+ (the flash sale)
	local rarePlusCount = (tierCounts.Rare or 0) + (tierCounts.Mythic or 0) + (tierCounts.Divine or 0)
	if rarePlusCount < MarketTuning.MinRarePlus then
		-- Try to add a Rare first, then Mythic, then Divine
		local flashAdded = false
		for _, tierName in ipairs({"Rare", "Mythic", "Divine"}) do
			if flashAdded then break end
			local pool = Ingredients.getByTier(tierName)
			for i = #pool, 2, -1 do
				local j = math.random(1, i)
				pool[i], pool[j] = pool[j], pool[i]
			end
			for _, ing in ipairs(pool) do
				if not usedIds[ing.id] and ing.acquisition and ing.acquisition.market then
					addOffer(ing, true) -- Mark as flash sale
					flashAdded = true
					break
				end
			end
		end
	else
		-- Mark an existing Rare+ offer as flash sale
		for _, offer in ipairs(offers) do
			if offer.tier == "Rare" or offer.tier == "Mythic" or offer.tier == "Divine" then
				offer.flashSale = true
				break
			end
		end
	end

	return offers, tierCounts
end

-- Broadcast current state to all clients
function module.broadcastState()
	for _, player in ipairs(Players:GetPlayers()) do
		pcall(function()
			Remotes.MarketRefresh:FireClient(player, MarketState)
		end)
	end
end

-- Deduct stock atomically (returns true on success, false on failure)
function module.deductStock(ingredientId, quantity)
	for _, offer in ipairs(MarketState.Offers) do
		if offer.ingredientId == ingredientId then
			if offer.stock >= quantity then
				offer.stock = offer.stock - quantity
				module.broadcastState()
				return true
			else
				return false -- insufficient stock
			end
		end
	end
	return false -- offer not found
end

-- Get current state snapshot
function module.getState()
	return MarketState
end

-- Refresh market
local function refreshMarket()
	local offers, tierCounts = generateOffers()
	MarketState.Offers = offers
	MarketState.RefreshTime = os.time() + REFRESH_SECONDS

	-- Log
	local summary = {}
	for tier, count in pairs(tierCounts) do
		if count > 0 then table.insert(summary, tier .. "=" .. count) end
	end
	print("[MarketService] Refreshed with " .. #offers .. " offers (" .. table.concat(summary, ", ") .. ")")

	-- Flash sale announcement via GlobalAnnouncement
	for _, offer in ipairs(offers) do
		if offer.flashSale then
			local msg = "Flash Sale! " .. offer.name .. " now available at the Market!"
			for _, player in ipairs(Players:GetPlayers()) do
				pcall(function()
					if Remotes:FindFirstChild("GlobalAnnouncement") then
						Remotes.GlobalAnnouncement:FireClient(player, msg)
					end
				end)
			end
			print("[MarketService] FLASH SALE: " .. offer.name .. " (" .. offer.tier .. ")")
			break -- only announce first flash sale
		end
	end

	-- Also announce Mythic/Divine (non-flash-sale)
	for _, offer in ipairs(offers) do
		if not offer.flashSale and (offer.tier == "Mythic" or offer.tier == "Divine") then
			local msg = "A " .. offer.name .. " has appeared in the market!"
			for _, player in ipairs(Players:GetPlayers()) do
				pcall(function()
					if Remotes:FindFirstChild("GlobalAnnouncement") then
						Remotes.GlobalAnnouncement:FireClient(player, msg)
					end
				end)
			end
		end
	end

	-- Broadcast updated state
	module.broadcastState()
end

-- Initial refresh
refreshMarket()

-- Refresh loop
task.spawn(function()
	while true do
		task.wait(REFRESH_SECONDS)
		refreshMarket()
	end
end)

-- GetMarketOffers RemoteFunction
Remotes.GetMarketOffers.OnServerInvoke = function(player)
	return MarketState
end

-- Register as global service
_G.MarketService = module

print("[MarketService] Initialized (module pattern, deductStock, guaranteed minimums, flash sales)")
