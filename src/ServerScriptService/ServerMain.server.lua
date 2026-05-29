local ReplicatedStorage = game:GetService("ReplicatedStorage")

local shared = ReplicatedStorage:WaitForChild("Shared")
local config = shared:WaitForChild("Config")
local utility = shared:WaitForChild("Utility")

local GameConfig = require(config:WaitForChild("GameConfig"))
local PackConfig = require(config:WaitForChild("PackConfig"))
local DailyRewardConfig = require(config:WaitForChild("DailyRewardConfig"))
local ShopConfig = require(config:WaitForChild("ShopConfig"))
local TableUtil = require(utility:WaitForChild("TableUtil"))

local DataService = require(script.Parent.Services.DataService)
local CurrencyService = require(script.Parent.Services.CurrencyService)
local ArenaBuildService = require(script.Parent.Services.ArenaBuildService)
local BoostService = require(script.Parent.Services.BoostService)
local AFKService = require(script.Parent.Services.AFKService)
local InventoryService = require(script.Parent.Services.InventoryService)
local PackService = require(script.Parent.Services.PackService)
local DailyRewardService = require(script.Parent.Services.DailyRewardService)
local ShopService = require(script.Parent.Services.ShopService)

local function getOrCreate(parent, className, name)
	local existing = parent:FindFirstChild(name)
	if existing then
		if existing.ClassName ~= className then
			warn(
				string.format(
					"[ServerMain] Replacing %s because it was %s, expected %s",
					name,
					existing.ClassName,
					className
				)
			)
			existing:Destroy()
		else
			return existing
		end
	end

	local instance = Instance.new(className)
	instance.Name = name
	instance.Parent = parent
	return instance
end

local function ensureRemote(parent, className, name)
	local existing = parent:FindFirstChild(name)
	if existing then
		if existing.ClassName ~= className then
			warn(
				string.format(
					"[ServerMain] Replacing remote %s because it was %s, expected %s",
					name,
					existing.ClassName,
					className
				)
			)
			existing:Destroy()
		else
			return existing
		end
	end

	local instance = Instance.new(className)
	instance.Name = name
	instance.Parent = parent
	return instance
end

local remotesFolder = getOrCreate(ReplicatedStorage, "Folder", "Remotes")
local dataRemotes = getOrCreate(remotesFolder, "Folder", "Data")
local currencyRemotes = getOrCreate(remotesFolder, "Folder", "Currency")
local systemRemotes = getOrCreate(remotesFolder, "Folder", "System")
local boostRemotes = getOrCreate(remotesFolder, "Folder", "Boosts")
local afkRemotes = getOrCreate(remotesFolder, "Folder", "AFK")
local packRemotes = getOrCreate(remotesFolder, "Folder", "Packs")
local inventoryRemotes = getOrCreate(remotesFolder, "Folder", "Inventory")
local dailyRewardRemotes = getOrCreate(remotesFolder, "Folder", "DailyRewards")
local shopRemotes = getOrCreate(remotesFolder, "Folder", "Shop")

local getPlayerDataRemote = ensureRemote(dataRemotes, "RemoteFunction", "GetPlayerData")
local getCurrenciesRemote = ensureRemote(currencyRemotes, "RemoteFunction", "GetCurrencies")
ensureRemote(systemRemotes, "RemoteEvent", "Notify")
local getActiveBoostsRemote = ensureRemote(boostRemotes, "RemoteFunction", "GetActiveBoosts")
local getAFKStatsRemote = ensureRemote(afkRemotes, "RemoteFunction", "GetAFKStats")
local getPacksRemote = ensureRemote(packRemotes, "RemoteFunction", "GetPacks")
local getPackOddsRemote = ensureRemote(packRemotes, "RemoteFunction", "GetPackOdds")
local openPackRemote = ensureRemote(packRemotes, "RemoteFunction", "OpenPack")
local getCardsRemote = ensureRemote(inventoryRemotes, "RemoteFunction", "GetCards")
local getBestCardRemote = ensureRemote(inventoryRemotes, "RemoteFunction", "GetBestCard")
local getDailyRewardStatusRemote = ensureRemote(dailyRewardRemotes, "RemoteFunction", "GetDailyRewardStatus")
local claimDailyRewardRemote = ensureRemote(dailyRewardRemotes, "RemoteFunction", "ClaimDailyReward")
local getShopItemsRemote = ensureRemote(shopRemotes, "RemoteFunction", "GetShopItems")
local purchaseShopItemRemote = ensureRemote(shopRemotes, "RemoteFunction", "PurchaseShopItem")

print(string.format("[%s] Starting server v%s", GameConfig.GameName, GameConfig.Version))

DataService.Init()
CurrencyService.Init(DataService)
BoostService.Init(DataService)
AFKService.Init(DataService, CurrencyService, BoostService)
InventoryService.Init(DataService)
PackService.Init(DataService, CurrencyService, BoostService, InventoryService)
DailyRewardService.Init(DataService, CurrencyService, BoostService)
ShopService.Init(DataService, CurrencyService, BoostService)
AFKService.Start()

local allPacksValid, packValidationResults = PackConfig.ValidateAllPacks()
for packId, validationResult in pairs(packValidationResults) do
	if validationResult.IsValid then
		print("[PackConfig] " .. packId .. " odds validated: " .. tostring(validationResult.Result))
	else
		warn("[PackConfig] " .. tostring(validationResult.Result))
	end
end
if not allPacksValid then
	warn("[PackConfig] One or more packs have invalid odds.")
end

local dailyRewardsValid, dailyRewardResult = DailyRewardConfig.ValidateRewards()
if dailyRewardsValid then
	print("[DailyRewardConfig] " .. tostring(dailyRewardResult))
else
	warn("[DailyRewardConfig] " .. tostring(dailyRewardResult))
end

local allShopItemsValid, shopValidationResults = ShopConfig.ValidateAllItems()
for itemId, validationResult in pairs(shopValidationResults) do
	if validationResult.IsValid then
		print("[ShopConfig] " .. itemId .. " validated")
	else
		warn("[ShopConfig] " .. tostring(validationResult.Result))
	end
end
if not allShopItemsValid then
	warn("[ShopConfig] One or more shop items are invalid.")
end

ArenaBuildService.Init()

getPlayerDataRemote.OnServerInvoke = function(player)
	local data = DataService.GetData(player)
	if not data then
		return nil
	end

	return TableUtil.DeepCopy(data)
end

getCurrenciesRemote.OnServerInvoke = function(player)
	return CurrencyService.GetAllCurrencies(player)
end

getActiveBoostsRemote.OnServerInvoke = function(player)
	return BoostService.GetActiveBoosts(player)
end

getAFKStatsRemote.OnServerInvoke = function(player)
	return AFKService.GetAFKStats(player)
end

getPacksRemote.OnServerInvoke = function()
	return PackService.GetSafePackList()
end

getPackOddsRemote.OnServerInvoke = function(player, packId)
	local odds, errorMessage = PackService.GetPackOdds(player, packId)
	if not odds then
		return {
			Success = false,
			Error = errorMessage,
		}
	end

	return {
		Success = true,
		PackId = packId,
		Odds = odds,
	}
end

openPackRemote.OnServerInvoke = function(player, packId)
	return PackService.OpenPack(player, packId)
end

getCardsRemote.OnServerInvoke = function(player)
	return InventoryService.GetCards(player)
end

getBestCardRemote.OnServerInvoke = function(player)
	return InventoryService.GetBestCard(player)
end

getDailyRewardStatusRemote.OnServerInvoke = function(player)
	return DailyRewardService.GetStatus(player)
end

claimDailyRewardRemote.OnServerInvoke = function(player)
	return DailyRewardService.Claim(player)
end

getShopItemsRemote.OnServerInvoke = function(player)
	return ShopService.GetShopItems(player)
end

purchaseShopItemRemote.OnServerInvoke = function(player, itemId)
	return ShopService.PurchaseItem(player, itemId)
end

local function isDebugAllowed(player)
	if not player then
		return false
	end

	for _, userId in ipairs(GameConfig.DebugAllowedUserIds) do
		if player.UserId == userId then
			return true
		end
	end

	return false
end

_G.BasketballDebug = {
	GiveBoost = function(player, boostType, durationSeconds)
		if not isDebugAllowed(player) then
			warn("[Debug] User is not allowed to use debug helpers:", player and player.Name)
			return false
		end

		return BoostService.GiveBoost(player, boostType, durationSeconds, "ServerDebug")
	end,
	GiveCoins = function(player, amount)
		if not isDebugAllowed(player) then
			warn("[Debug] User is not allowed to use debug helpers:", player and player.Name)
			return false
		end

		return CurrencyService.AddCurrency(player, "Coins", amount, "ServerDebug")
	end,
	GiveRings = function(player, amount)
		if not isDebugAllowed(player) then
			warn("[Debug] User is not allowed to use debug helpers:", player and player.Name)
			return false
		end

		return CurrencyService.AddCurrency(player, "Rings", amount, "ServerDebug")
	end,
	AddCurrency = function(player, currencyName, amount)
		if not isDebugAllowed(player) then
			warn("[Debug] User is not allowed to use debug helpers:", player and player.Name)
			return false
		end

		return CurrencyService.AddCurrency(player, currencyName, amount, "ServerDebug")
	end,
	OpenTestPack = function(player, packId)
		if not isDebugAllowed(player) then
			warn("[Debug] User is not allowed to use debug helpers:", player and player.Name)
			return false
		end

		return PackService.OpenPack(player, packId)
	end,
	GiveLuckBoost = function(player)
		if not isDebugAllowed(player) then
			warn("[Debug] User is not allowed to use debug helpers:", player and player.Name)
			return false
		end

		return BoostService.GiveBoost(player, "Luck2x", 600, "ServerDebug")
	end,
	PrintAFKStats = function(player)
		if not isDebugAllowed(player) then
			warn("[Debug] User is not allowed to use debug helpers:", player and player.Name)
			return nil
		end

		local stats = AFKService.GetAFKStats(player)
		print("[Debug] AFK stats for", player.Name, stats)
		return stats
	end,
	PrintInventory = function(player)
		if not isDebugAllowed(player) then
			warn("[Debug] User is not allowed to use debug helpers:", player and player.Name)
			return nil
		end

		local cards = InventoryService.GetCards(player)
		print("[Debug] Inventory for", player.Name, cards)
		return cards
	end,
	ClearInventory = function(player)
		if not isDebugAllowed(player) then
			warn("[Debug] User is not allowed to use debug helpers:", player and player.Name)
			return false
		end

		return DataService.UpdateData(player, function(data)
			data.Inventory.Cards = {}
		end)
	end,
	ResetDailyReward = function(player)
		if not isDebugAllowed(player) then
			warn("[Debug] User is not allowed to use debug helpers:", player and player.Name)
			return false
		end

		return DataService.UpdateData(player, function(data)
			data.DailyRewards.LastClaimTimestamp = 0
			data.DailyRewards.CurrentStreak = 0
		end)
	end,
	ForceDailyClaimReady = function(player)
		if not isDebugAllowed(player) then
			warn("[Debug] User is not allowed to use debug helpers:", player and player.Name)
			return false
		end

		return DataService.UpdateData(player, function(data)
			data.DailyRewards.LastClaimTimestamp = 0
		end)
	end,
	GiveCoinsForShopTesting = function(player, amount)
		if not isDebugAllowed(player) then
			warn("[Debug] User is not allowed to use debug helpers:", player and player.Name)
			return false
		end

		return CurrencyService.AddCurrency(player, "Coins", amount, "ShopDebug")
	end,
	PurchaseTestItem = function(player, itemId)
		if not isDebugAllowed(player) then
			warn("[Debug] User is not allowed to use debug helpers:", player and player.Name)
			return false
		end

		return ShopService.PurchaseItem(player, itemId)
	end,
	PrintShopItems = function()
		local items = ShopService.GetShopItems()
		print("[Debug] Shop items:", items)
		return items
	end,
	PrintDailyStatus = function(player)
		if not isDebugAllowed(player) then
			warn("[Debug] User is not allowed to use debug helpers:", player and player.Name)
			return nil
		end

		local status = DailyRewardService.GetStatus(player)
		print("[Debug] Daily status for", player.Name, status)
		return status
	end,
}

print("Basketball AFK RNG Arena server started.")
