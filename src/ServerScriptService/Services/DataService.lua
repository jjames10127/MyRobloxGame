local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local shared = ReplicatedStorage:WaitForChild("Shared")
local config = shared:WaitForChild("Config")
local utility = shared:WaitForChild("Utility")

local GameConfig = require(config:WaitForChild("GameConfig"))
local DataConfig = require(config:WaitForChild("DataConfig"))
local TableUtil = require(utility:WaitForChild("TableUtil"))
local TimeUtil = require(utility:WaitForChild("TimeUtil"))

local DataService = {}

local dataStore = DataStoreService:GetDataStore(DataConfig.DataStoreName)
local playerDataByUserId = {}
local loadedByUserId = {}
local isInitialized = false

local function getKey(player)
	return "Player_" .. tostring(player.UserId)
end

local function debugLog(...)
	if GameConfig.IsDebug then
		print("[DataService]", ...)
	end
end

local function warnDataStoreIssue(action, player, result)
	warn(string.format(
		"[DataService] Failed to %s data for %s. Studio API access may be disabled, or the experience may not be published. Error: %s",
		action,
		player.Name,
		tostring(result)
	))
end

function DataService.CreateDefaultData(player)
	local data = TableUtil.DeepCopy(DataConfig.DefaultData)
	local now = TimeUtil.Now()

	data.Profile.UserId = player.UserId
	data.Profile.Username = player.Name
	data.Profile.CreatedAt = now
	data.Profile.LastLoginAt = now

	return data
end

function DataService.LoadPlayer(player)
	local key = getKey(player)
	local defaultData = DataService.CreateDefaultData(player)

	local success, loadedData = pcall(function()
		return dataStore:GetAsync(key)
	end)

	if not success then
		warnDataStoreIssue("load", player, loadedData)
		warn("[DataService] Using temporary default data for " .. player.Name .. ". This session can continue, but persistence may not work until DataStores are available.")
		loadedData = nil
	end

	local reconciledData = TableUtil.Reconcile(defaultData, loadedData)
	reconciledData.Profile.UserId = player.UserId
	reconciledData.Profile.Username = player.Name
	reconciledData.Profile.LastLoginAt = TimeUtil.Now()

	playerDataByUserId[player.UserId] = reconciledData
	loadedByUserId[player.UserId] = true

	debugLog("Data loaded for", player.Name)
	return reconciledData
end

function DataService.SavePlayer(player)
	if not DataService.IsLoaded(player) then
		return false, "Player data is not loaded"
	end

	local data = playerDataByUserId[player.UserId]
	local key = getKey(player)

	local success, result = pcall(function()
		dataStore:SetAsync(key, data)
	end)

	if not success then
		warnDataStoreIssue("save", player, result)
		return false, result
	end

	debugLog("Data saved for", player.Name)
	return true
end

function DataService.GetData(player)
	if not DataService.IsLoaded(player) then
		return nil
	end

	return playerDataByUserId[player.UserId]
end

function DataService.SetData(player, newData)
	if type(newData) ~= "table" then
		return false, "newData must be a table"
	end

	playerDataByUserId[player.UserId] = TableUtil.Reconcile(DataConfig.DefaultData, newData)
	loadedByUserId[player.UserId] = true
	return true
end

function DataService.UpdateData(player, callback)
	if type(callback) ~= "function" then
		return false, "callback must be a function"
	end

	local data = DataService.GetData(player)
	if not data then
		return false, "Player data is not loaded"
	end

	local success, result = pcall(callback, data)
	if not success then
		warn("[DataService] UpdateData failed for " .. player.Name, result)
		return false, result
	end

	if type(result) == "table" then
		playerDataByUserId[player.UserId] = TableUtil.Reconcile(DataConfig.DefaultData, result)
	end

	return true, DataService.GetData(player)
end

function DataService.IsLoaded(player)
	return loadedByUserId[player.UserId] == true
end

function DataService.SaveAll()
	for _, player in ipairs(Players:GetPlayers()) do
		DataService.SavePlayer(player)
	end
end

function DataService.Init()
	if isInitialized then
		return
	end

	isInitialized = true

	Players.PlayerAdded:Connect(function(player)
		DataService.LoadPlayer(player)
	end)

	Players.PlayerRemoving:Connect(function(player)
		DataService.SavePlayer(player)
		playerDataByUserId[player.UserId] = nil
		loadedByUserId[player.UserId] = nil
	end)

	game:BindToClose(function()
		DataService.SaveAll()
	end)

	task.spawn(function()
		while isInitialized do
			task.wait(GameConfig.SaveIntervalSeconds)
			DataService.SaveAll()
		end
	end)

	for _, player in ipairs(Players:GetPlayers()) do
		if not DataService.IsLoaded(player) then
			DataService.LoadPlayer(player)
		end
	end

	debugLog("Initialized")
end

return DataService
