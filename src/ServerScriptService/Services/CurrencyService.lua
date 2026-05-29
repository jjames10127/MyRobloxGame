local ReplicatedStorage = game:GetService("ReplicatedStorage")

local shared = ReplicatedStorage:WaitForChild("Shared")
local config = shared:WaitForChild("Config")
local utility = shared:WaitForChild("Utility")

local GameConfig = require(config:WaitForChild("GameConfig"))
local CurrencyConfig = require(config:WaitForChild("CurrencyConfig"))
local TableUtil = require(utility:WaitForChild("TableUtil"))

local CurrencyService = {}

local dataService = nil
local isInitialized = false

local function debugLog(...)
	if GameConfig.IsDebug then
		print("[CurrencyService]", ...)
	end
end

local function getCurrencyInfo(currencyName)
	return CurrencyConfig.GetCurrency(currencyName)
end

local function validateAmount(amount)
	return type(amount) == "number" and amount == amount and amount ~= math.huge and amount ~= -math.huge
end

local function isReady()
	return isInitialized and dataService ~= nil
end

function CurrencyService.Init(injectedDataService)
	if isInitialized then
		return
	end

	assert(injectedDataService, "CurrencyService.Init requires DataService")
	dataService = injectedDataService
	isInitialized = true
	debugLog("Initialized")
end

function CurrencyService.GetCurrency(player, currencyName)
	if not isReady() then
		return nil
	end

	if not getCurrencyInfo(currencyName) then
		return nil
	end

	local data = dataService.GetData(player)
	if not data then
		return nil
	end

	return data.Currencies[currencyName]
end

function CurrencyService.SetCurrency(player, currencyName, amount, reason)
	if not isReady() then
		return false, "CurrencyService is not initialized"
	end

	local currencyInfo = getCurrencyInfo(currencyName)
	if not currencyInfo then
		return false, "Invalid currency: " .. tostring(currencyName)
	end

	if not validateAmount(amount) then
		return false, "Amount must be a valid number"
	end

	local finalAmount = amount
	if not currencyInfo.CanBeNegative then
		finalAmount = math.max(0, finalAmount)
	end

	local success, result = dataService.UpdateData(player, function(data)
		data.Currencies[currencyName] = finalAmount
	end)

	if success then
		debugLog("Set", player.Name, currencyName, finalAmount, reason or "No reason")
	end

	return success, result
end

function CurrencyService.AddCurrency(player, currencyName, amount, reason)
	if not validateAmount(amount) then
		return false, "Amount must be a valid number"
	end
	if amount < 0 then
		return false, "Amount must be positive"
	end

	local currentAmount = CurrencyService.GetCurrency(player, currencyName)
	if currentAmount == nil then
		return false, "Currency unavailable"
	end

	return CurrencyService.SetCurrency(player, currencyName, currentAmount + amount, reason)
end

function CurrencyService.RemoveCurrency(player, currencyName, amount, reason)
	if not validateAmount(amount) then
		return false, "Amount must be a valid number"
	end

	if amount < 0 then
		return false, "Amount must be positive"
	end

	if not CurrencyService.CanAfford(player, currencyName, amount) then
		return false, "Cannot afford"
	end

	local currentAmount = CurrencyService.GetCurrency(player, currencyName)
	return CurrencyService.SetCurrency(player, currencyName, currentAmount - amount, reason)
end

function CurrencyService.CanAfford(player, currencyName, amount)
	if not validateAmount(amount) then
		return false
	end

	local currentAmount = CurrencyService.GetCurrency(player, currencyName)
	return currentAmount ~= nil and currentAmount >= amount
end

function CurrencyService.GetAllCurrencies(player)
	if not isReady() then
		return nil
	end

	local data = dataService.GetData(player)
	if not data then
		return nil
	end

	return TableUtil.DeepCopy(data.Currencies)
end

return CurrencyService
