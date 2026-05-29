local ReplicatedStorage = game:GetService("ReplicatedStorage")

local shared = ReplicatedStorage:WaitForChild("Shared")
local config = shared:WaitForChild("Config")
local utility = shared:WaitForChild("Utility")

local GameConfig = require(config:WaitForChild("GameConfig"))
local ShopConfig = require(config:WaitForChild("ShopConfig"))
local TrollConfig = require(config:WaitForChild("TrollConfig"))
local TableUtil = require(utility:WaitForChild("TableUtil"))

local ShopService = {}

local dataService = nil
local currencyService = nil
local boostService = nil
local isInitialized = false

local function debugLog(...)
	if GameConfig.IsDebug then
		print("[ShopService]", ...)
	end
end

local function getSafeItem(itemId, item)
	return {
		ItemId = itemId,
		DisplayName = item.DisplayName,
		Description = item.Description,
		PurchaseType = item.PurchaseType,
		CostCurrency = item.CostCurrency,
		CostAmount = item.CostAmount,
		DeveloperProductId = item.DeveloperProductId,
		Grants = TableUtil.DeepCopy(item.Grants),
	}
end

function ShopService.Init(injectedDataService, injectedCurrencyService, injectedBoostService)
	if isInitialized then
		return
	end

	assert(injectedDataService, "ShopService.Init requires DataService")
	assert(injectedCurrencyService, "ShopService.Init requires CurrencyService")
	assert(injectedBoostService, "ShopService.Init requires BoostService")

	dataService = injectedDataService
	currencyService = injectedCurrencyService
	boostService = injectedBoostService
	isInitialized = true
	debugLog("Initialized")
end

function ShopService.ValidateShopData(player)
	if not dataService or not dataService.IsLoaded(player) then
		return false
	end

	local data = dataService.GetData(player)
	if not data then
		return false
	end

	data.Inventory = data.Inventory or {}
	data.Inventory.TrollItems = data.Inventory.TrollItems or {}
	return true
end

function ShopService.GetShopItems()
	local safeItems = {}
	for itemId, item in pairs(ShopConfig.GetAllItems()) do
		safeItems[itemId] = getSafeItem(itemId, item)
	end
	return safeItems
end

function ShopService.CanPurchase(player, itemId)
	if not dataService or not dataService.IsLoaded(player) then
		return false, "Data not loaded."
	end

	local isValid, validationResult = ShopConfig.ValidateItem(itemId)
	if not isValid then
		return false, validationResult
	end

	local item = ShopConfig.GetItem(itemId)
	if item.PurchaseType == "RobuxPlaceholder" then
		return false, "Robux purchases are not implemented yet."
	end

	if item.PurchaseType ~= "SoftCurrency" then
		return false, "Unsupported purchase type."
	end

	if not currencyService.CanAfford(player, item.CostCurrency, item.CostAmount) then
		return false, "Not enough " .. tostring(item.CostCurrency) .. "."
	end

	return true, item
end

function ShopService.AddTrollItem(player, itemId, amount)
	if not TrollConfig.Items[itemId] then
		return false, "Invalid troll item: " .. tostring(itemId)
	end
	if type(amount) ~= "number" or amount <= 0 then
		return false, "Troll item amount must be positive."
	end

	local success, result = dataService.UpdateData(player, function(data)
		data.Inventory = data.Inventory or {}
		data.Inventory.TrollItems = data.Inventory.TrollItems or {}
		local currentAmount = data.Inventory.TrollItems[itemId] or 0
		data.Inventory.TrollItems[itemId] = math.max(0, currentAmount + amount)
	end)

	if not success then
		return false, result
	end

	return true, {
		Type = "TrollItem",
		ItemId = itemId,
		Amount = amount,
	}
end

function ShopService.GrantReward(player, reward)
	if type(reward) ~= "table" then
		return false, "Invalid reward."
	end

	if reward.Type == "Currency" then
		local success, result = currencyService.AddCurrency(player, reward.Currency, reward.Amount, "ShopGrant")
		if not success then
			return false, result
		end
		return true, TableUtil.DeepCopy(reward)
	end

	if reward.Type == "Boost" then
		local success, result = boostService.GiveBoost(player, reward.BoostType, reward.DurationSeconds, "ShopPurchase")
		if not success then
			return false, result
		end
		return true, TableUtil.DeepCopy(reward)
	end

	if reward.Type == "TrollItem" then
		return ShopService.AddTrollItem(player, reward.ItemId, reward.Amount)
	end

	return false, "Unsupported reward type: " .. tostring(reward.Type)
end

function ShopService.GrantShopItem(player, shopItem)
	local rewardsGranted = {}
	for _, reward in ipairs(shopItem.Grants) do
		local success, result = ShopService.GrantReward(player, reward)
		if not success then
			return false, result, rewardsGranted
		end
		table.insert(rewardsGranted, result)
	end

	return true, rewardsGranted
end

function ShopService.PurchaseItem(player, itemId)
	local canPurchase, itemOrError = ShopService.CanPurchase(player, itemId)
	if not canPurchase then
		return {
			Success = false,
			Error = itemOrError,
			ItemId = itemId,
		}
	end

	local item = itemOrError
	local removeSuccess, removeError =
		currencyService.RemoveCurrency(player, item.CostCurrency, item.CostAmount, "ShopPurchase:" .. tostring(itemId))
	if not removeSuccess then
		return {
			Success = false,
			Error = removeError or "Currency charge failed.",
			ItemId = itemId,
		}
	end

	local grantSuccess, grantResult = ShopService.GrantShopItem(player, item)
	if not grantSuccess then
		currencyService.AddCurrency(player, item.CostCurrency, item.CostAmount, "RefundFailedShopGrant")
		return {
			Success = false,
			Error = grantResult or "Shop reward grant failed.",
			ItemId = itemId,
		}
	end

	debugLog("Purchased", itemId, "for", player.Name)

	return {
		Success = true,
		ItemId = itemId,
		RewardsGranted = grantResult,
		UpdatedCurrencies = currencyService.GetAllCurrencies(player),
	}
end

return ShopService
