local ReplicatedStorage = game:GetService("ReplicatedStorage")

local shared = ReplicatedStorage:WaitForChild("Shared")
local config = shared:WaitForChild("Config")
local utility = shared:WaitForChild("Utility")

local GameConfig = require(config:WaitForChild("GameConfig"))
local PackConfig = require(config:WaitForChild("PackConfig"))
local RarityConfig = require(config:WaitForChild("RarityConfig"))
local NumberUtil = require(utility:WaitForChild("NumberUtil"))
local TableUtil = require(utility:WaitForChild("TableUtil"))

local CardGenerator = require(script.Parent.CardGenerator)

local PackService = {}

local dataService = nil
local currencyService = nil
local boostService = nil
local inventoryService = nil
local isInitialized = false

local HIGH_RARITY_WEIGHT = {
	Common = 0,
	Uncommon = 0.15,
	Rare = 0.45,
	Epic = 0.85,
	Legendary = 1.25,
	Mythic = 1.65,
	Secret = 2,
}

local function debugLog(...)
	if GameConfig.IsDebug then
		print("[PackService]", ...)
	end
end

local function getRarityOrder(rarity)
	local info = RarityConfig.GetRarity(rarity)
	return info and info.Order or 0
end

local function normalizeOdds(weightedOdds)
	local total = 0
	for _, chance in pairs(weightedOdds) do
		total = total + math.max(0, chance)
	end

	local normalized = {}
	local runningTotal = 0
	local lastRarity = RarityConfig.Order[#RarityConfig.Order]

	for _, rarity in ipairs(RarityConfig.Order) do
		if rarity == lastRarity then
			normalized[rarity] = NumberUtil.Round(100 - runningTotal, 4)
		else
			local value = 0
			if total > 0 then
				value = NumberUtil.Round((math.max(0, weightedOdds[rarity] or 0) / total) * 100, 4)
			end
			normalized[rarity] = value
			runningTotal = runningTotal + value
		end
	end

	return normalized
end

function PackService.Init(injectedDataService, injectedCurrencyService, injectedBoostService, injectedInventoryService)
	if isInitialized then
		return
	end

	assert(injectedDataService, "PackService.Init requires DataService")
	assert(injectedCurrencyService, "PackService.Init requires CurrencyService")
	assert(injectedBoostService, "PackService.Init requires BoostService")
	assert(injectedInventoryService, "PackService.Init requires InventoryService")

	dataService = injectedDataService
	currencyService = injectedCurrencyService
	boostService = injectedBoostService
	inventoryService = injectedInventoryService
	isInitialized = true
	debugLog("Initialized")
end

function PackService.ValidatePack(packId)
	local pack = PackConfig.GetPack(packId)
	if not pack then
		return false, "Invalid pack."
	end

	local oddsValid, oddsError = PackConfig.ValidateOdds(packId)
	if not oddsValid then
		return false, oddsError
	end

	return true, pack
end

function PackService.GetLuckMultiplier(player)
	local luck = 1
	if boostService.GetMultiplier(player, "Luck2x") > 1 then
		luck = luck * 2
	end

	local data = dataService.GetData(player)
	if data then
		local prestigeLevel = data.Progression and data.Progression.PrestigeLevel or 0
		local winStreak = data.Progression and data.Progression.WinStreak or 0
		luck = luck * (1 + prestigeLevel * 0.05)

		if winStreak >= 10 then
			luck = luck * 1.25
		elseif winStreak >= 5 then
			luck = luck * 1.10
		elseif winStreak >= 3 then
			luck = luck * 1.05
		end
	end

	return luck
end

function PackService.GetAdjustedOdds(player, packId)
	local isValid, packOrError = PackService.ValidatePack(packId)
	if not isValid then
		return nil, packOrError
	end

	local baseOdds = packOrError.Odds
	local luckMultiplier = PackService.GetLuckMultiplier(player)
	local weightedOdds = {}

	for _, rarity in ipairs(RarityConfig.Order) do
		local baseChance = baseOdds[rarity] or 0
		local highRarityWeight = HIGH_RARITY_WEIGHT[rarity] or 0
		local multiplier = 1 + ((luckMultiplier - 1) * highRarityWeight)
		weightedOdds[rarity] = baseChance * multiplier
	end

	weightedOdds.Common = (weightedOdds.Common or 0) / luckMultiplier
	weightedOdds.Uncommon = (weightedOdds.Uncommon or 0) / math.max(1, luckMultiplier * 0.75)

	return normalizeOdds(weightedOdds)
end

function PackService.GetPackOdds(player, packId)
	return PackService.GetAdjustedOdds(player, packId)
end

function PackService.RollRarity(adjustedOdds)
	local roll = math.random() * 100
	local cumulative = 0

	for _, rarity in ipairs(RarityConfig.Order) do
		cumulative = cumulative + (adjustedOdds[rarity] or 0)
		if roll <= cumulative then
			return rarity
		end
	end

	return "Common"
end

function PackService.CanOpenPack(player, packId)
	if not dataService.IsLoaded(player) then
		return false, "Data not loaded."
	end

	local isValid, packOrError = PackService.ValidatePack(packId)
	if not isValid then
		return false, packOrError
	end

	if not inventoryService.HasInventorySpace(player) then
		return false, "Inventory full."
	end

	if not currencyService.CanAfford(player, packOrError.CostCurrency, packOrError.CostAmount) then
		return false, "Not enough " .. packOrError.CostCurrency .. "."
	end

	return true, packOrError
end

function PackService.UpdatePackStats(player, card)
	return dataService.UpdateData(player, function(data)
		data.Packs.TotalPacksOpened = (data.Packs.TotalPacksOpened or 0) + 1
		local currentBest = data.Packs.BestRarityPulled or "None"
		if getRarityOrder(card.Rarity) > getRarityOrder(currentBest) then
			data.Packs.BestRarityPulled = card.Rarity
		end
	end)
end

function PackService.OpenPack(player, packId)
	local canOpen, packOrError = PackService.CanOpenPack(player, packId)
	if not canOpen then
		return {
			Success = false,
			Error = packOrError,
			PackId = packId,
		}
	end

	local adjustedOdds, oddsError = PackService.GetAdjustedOdds(player, packId)
	if not adjustedOdds then
		return {
			Success = false,
			Error = oddsError,
			PackId = packId,
		}
	end

	local rarity = PackService.RollRarity(adjustedOdds)
	local card, cardError = CardGenerator.GenerateCard(rarity)
	if not card then
		return {
			Success = false,
			Error = cardError or "Card generation failed.",
			PackId = packId,
			Odds = adjustedOdds,
		}
	end

	local removeSuccess, removeError = currencyService.RemoveCurrency(player, packOrError.CostCurrency, packOrError.CostAmount, "OpenPack:" .. packId)
	if not removeSuccess then
		return {
			Success = false,
			Error = removeError or "Currency charge failed.",
			PackId = packId,
			Odds = adjustedOdds,
		}
	end

	local addSuccess, addError = inventoryService.AddCard(player, card, "PackOpen:" .. packId)
	if not addSuccess then
		currencyService.AddCurrency(player, packOrError.CostCurrency, packOrError.CostAmount, "RefundFailedPackGrant")
		return {
			Success = false,
			Error = addError or "Card grant failed.",
			PackId = packId,
			Odds = adjustedOdds,
		}
	end

	PackService.UpdatePackStats(player, card)

	debugLog("Opened", packId, "for", player.Name, "and rolled", card.Rarity, card.Overall)

	return {
		Success = true,
		PackId = packId,
		Odds = adjustedOdds,
		Card = TableUtil.DeepCopy(card),
		Currencies = currencyService.GetAllCurrencies(player),
	}
end

function PackService.GetSafePackList()
	local packs = {}
	for packId, pack in pairs(PackConfig.GetAllPacks()) do
		packs[packId] = {
			DisplayName = pack.DisplayName,
			CostCurrency = pack.CostCurrency,
			CostAmount = pack.CostAmount,
			Odds = TableUtil.DeepCopy(pack.Odds),
		}
	end
	return packs
end

return PackService
