local ReplicatedStorage = game:GetService("ReplicatedStorage")

local shared = ReplicatedStorage:WaitForChild("Shared")
local config = shared:WaitForChild("Config")
local utility = shared:WaitForChild("Utility")

local GameConfig = require(config:WaitForChild("GameConfig"))
local RarityConfig = require(config:WaitForChild("RarityConfig"))
local TableUtil = require(utility:WaitForChild("TableUtil"))

local InventoryService = {}

local dataService = nil
local isInitialized = false

local function debugLog(...)
	if GameConfig.IsDebug then
		print("[InventoryService]", ...)
	end
end

local function getCardsContainer(player)
	if not dataService or not dataService.IsLoaded(player) then
		return nil
	end

	local data = dataService.GetData(player)
	if not data then
		return nil
	end

	data.Inventory = data.Inventory or {}
	data.Inventory.Cards = data.Inventory.Cards or {}
	return data.Inventory.Cards
end

local function isValidCardData(cardData)
	if type(cardData) ~= "table" then
		return false, "Card data must be a table"
	end
	if type(cardData.CardId) ~= "string" or cardData.CardId == "" then
		return false, "CardId is required"
	end
	if type(cardData.Name) ~= "string" or cardData.Name == "" then
		return false, "Name is required"
	end
	if not RarityConfig.GetRarity(cardData.Rarity) then
		return false, "Invalid rarity"
	end
	if type(cardData.Overall) ~= "number" then
		return false, "Overall must be a number"
	end
	if type(cardData.Position) ~= "string" then
		return false, "Position is required"
	end
	if type(cardData.Stats) ~= "table" then
		return false, "Stats are required"
	end
	if type(cardData.Badge) ~= "string" then
		return false, "Badge is required"
	end

	return true
end

function InventoryService.Init(injectedDataService)
	if isInitialized then
		return
	end

	assert(injectedDataService, "InventoryService.Init requires DataService")
	dataService = injectedDataService
	isInitialized = true
	debugLog("Initialized")
end

function InventoryService.GetCards(player)
	local cards = getCardsContainer(player)
	if not cards then
		return {}
	end

	return TableUtil.DeepCopy(cards)
end

function InventoryService.GetCard(player, cardId)
	local cards = getCardsContainer(player)
	if not cards then
		return nil
	end

	for _, card in ipairs(cards) do
		if card.CardId == cardId then
			return TableUtil.DeepCopy(card)
		end
	end

	return nil
end

function InventoryService.GetCardCount(player)
	local cards = getCardsContainer(player)
	return cards and #cards or 0
end

function InventoryService.HasInventorySpace(player)
	return InventoryService.GetCardCount(player) < GameConfig.MaxCardsPerPlayer
end

function InventoryService.AddCard(player, cardData, reason)
	local isValid, validationError = isValidCardData(cardData)
	if not isValid then
		return false, validationError
	end

	if not InventoryService.HasInventorySpace(player) then
		return false, "Inventory full"
	end

	local cardToSave = TableUtil.DeepCopy(cardData)
	local success, result = dataService.UpdateData(player, function(data)
		data.Inventory = data.Inventory or {}
		data.Inventory.Cards = data.Inventory.Cards or {}
		table.insert(data.Inventory.Cards, cardToSave)
	end)

	if success then
		debugLog("Added card", cardData.CardId, "to", player.Name, reason or "No reason")
	end

	return success, result
end

function InventoryService.RemoveCard(player, cardId, reason)
	local removedCard = nil
	local success, result = dataService.UpdateData(player, function(data)
		local cards = data.Inventory and data.Inventory.Cards
		if not cards then
			return
		end

		for index, card in ipairs(cards) do
			if card.CardId == cardId then
				if card.IsLocked then
					error("Card is locked")
				end

				removedCard = table.remove(cards, index)
				break
			end
		end
	end)

	if success then
		debugLog("Removed card", cardId, "from", player.Name, reason or "No reason")
	end

	return success, removedCard or result
end

function InventoryService.LockCard(player, cardId)
	return dataService.UpdateData(player, function(data)
		for _, card in ipairs(data.Inventory.Cards) do
			if card.CardId == cardId then
				card.IsLocked = true
				return
			end
		end
	end)
end

function InventoryService.UnlockCard(player, cardId)
	return dataService.UpdateData(player, function(data)
		for _, card in ipairs(data.Inventory.Cards) do
			if card.CardId == cardId then
				card.IsLocked = false
				return
			end
		end
	end)
end

function InventoryService.GetBestCard(player)
	local cards = getCardsContainer(player)
	if not cards or #cards == 0 then
		return nil
	end

	local bestCard = cards[1]
	for _, card in ipairs(cards) do
		if card.Overall > bestCard.Overall then
			bestCard = card
		end
	end

	return TableUtil.DeepCopy(bestCard)
end

return InventoryService
