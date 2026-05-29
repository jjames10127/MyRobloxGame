local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local shared = ReplicatedStorage:WaitForChild("Shared")
local config = shared:WaitForChild("Config")
local utility = shared:WaitForChild("Utility")

local GameConfig = require(config:WaitForChild("GameConfig"))
local BoostConfig = require(config:WaitForChild("BoostConfig"))
local TableUtil = require(utility:WaitForChild("TableUtil"))
local TimeUtil = require(utility:WaitForChild("TimeUtil"))

local BoostService = {}

local dataService = nil
local isInitialized = false

local function debugLog(...)
	if GameConfig.IsDebug then
		print("[BoostService]", ...)
	end
end

local function getBoostInfo(boostType)
	return BoostConfig.Boosts[boostType]
end

local function getBoostContainer(player)
	if not dataService or not dataService.IsLoaded(player) then
		return nil
	end

	local data = dataService.GetData(player)
	if not data then
		return nil
	end

	data.Boosts = data.Boosts or {}
	data.Boosts.ActiveBoosts = data.Boosts.ActiveBoosts or {}
	return data.Boosts.ActiveBoosts
end

function BoostService.Init(injectedDataService)
	if isInitialized then
		return
	end

	assert(injectedDataService, "BoostService.Init requires DataService")
	dataService = injectedDataService
	isInitialized = true
	debugLog("Initialized")
end

function BoostService.GiveBoost(player, boostType, durationOverrideSeconds, reason)
	local boostInfo = getBoostInfo(boostType)
	if not boostInfo then
		return false, "Invalid boost type: " .. tostring(boostType)
	end

	local duration = durationOverrideSeconds or boostInfo.DurationSeconds
	if type(duration) ~= "number" or duration <= 0 then
		return false, "Duration must be a positive number"
	end

	local success, result = dataService.UpdateData(player, function(data)
		data.Boosts = data.Boosts or {}
		data.Boosts.ActiveBoosts = data.Boosts.ActiveBoosts or {}

		local now = TimeUtil.Now()
		local activeBoost = data.Boosts.ActiveBoosts[boostType]
		local baseExpiresAt = now
		if activeBoost and type(activeBoost.ExpiresAt) == "number" and activeBoost.ExpiresAt > now then
			baseExpiresAt = activeBoost.ExpiresAt
		end

		data.Boosts.ActiveBoosts[boostType] = {
			BoostType = boostType,
			ExpiresAt = baseExpiresAt + duration,
			Multiplier = boostInfo.Multiplier or 1,
		}
	end)

	if success then
		debugLog("Gave", boostType, "to", player.Name, "for", duration, "seconds.", reason or "No reason")
	end

	return success, result
end

function BoostService.RemoveBoost(player, boostType, reason)
	if not getBoostInfo(boostType) then
		return false, "Invalid boost type: " .. tostring(boostType)
	end

	local success, result = dataService.UpdateData(player, function(data)
		if data.Boosts and data.Boosts.ActiveBoosts then
			data.Boosts.ActiveBoosts[boostType] = nil
		end
	end)

	if success then
		debugLog("Removed", boostType, "from", player.Name, reason or "No reason")
	end

	return success, result
end

function BoostService.CleanupExpiredBoosts(player)
	local activeBoosts = getBoostContainer(player)
	if not activeBoosts then
		return
	end

	local now = TimeUtil.Now()
	for boostType, boostData in pairs(activeBoosts) do
		if type(boostData) ~= "table" or type(boostData.ExpiresAt) ~= "number" or boostData.ExpiresAt <= now then
			activeBoosts[boostType] = nil
			debugLog("Expired", boostType, "for", player.Name)
		end
	end
end

function BoostService.CleanupAllPlayers()
	for _, player in ipairs(Players:GetPlayers()) do
		BoostService.CleanupExpiredBoosts(player)
	end
end

function BoostService.IsBoostActive(player, boostType)
	if not getBoostInfo(boostType) then
		return false
	end

	BoostService.CleanupExpiredBoosts(player)

	local activeBoosts = getBoostContainer(player)
	local boostData = activeBoosts and activeBoosts[boostType]
	return type(boostData) == "table" and type(boostData.ExpiresAt) == "number" and boostData.ExpiresAt > TimeUtil.Now()
end

function BoostService.GetActiveBoosts(player)
	BoostService.CleanupExpiredBoosts(player)

	local activeBoosts = getBoostContainer(player)
	if not activeBoosts then
		return {}
	end

	local activeBoostsCopy = TableUtil.DeepCopy(activeBoosts)
	for _, boostData in pairs(activeBoostsCopy) do
		if type(boostData) == "table" and type(boostData.ExpiresAt) == "number" then
			boostData.TimeRemaining = TimeUtil.SecondsUntil(boostData.ExpiresAt)
		end
	end

	return activeBoostsCopy
end

function BoostService.GetMultiplier(player, boostType)
	if not BoostService.IsBoostActive(player, boostType) then
		return 1
	end

	local activeBoosts = getBoostContainer(player)
	local boostData = activeBoosts and activeBoosts[boostType]
	return boostData.Multiplier or 1
end

function BoostService.GetBoostTimeRemaining(player, boostType)
	if not BoostService.IsBoostActive(player, boostType) then
		return 0
	end

	local activeBoosts = getBoostContainer(player)
	local boostData = activeBoosts and activeBoosts[boostType]
	return TimeUtil.SecondsUntil(boostData.ExpiresAt)
end

return BoostService
