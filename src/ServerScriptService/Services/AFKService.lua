local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local shared = ReplicatedStorage:WaitForChild("Shared")
local config = shared:WaitForChild("Config")

local GameConfig = require(config:WaitForChild("GameConfig"))

local AFKService = {}

local dataService = nil
local currencyService = nil
local boostService = nil
local isInitialized = false
local isRunning = false
local firstTickScheduledByUserId = {}

local function debugLog(...)
	if GameConfig.IsDebug then
		print("[AFKService]", ...)
	end
end

function AFKService.Init(injectedDataService, injectedCurrencyService, injectedBoostService)
	if isInitialized then
		return
	end

	assert(injectedDataService, "AFKService.Init requires DataService")
	assert(injectedCurrencyService, "AFKService.Init requires CurrencyService")
	assert(injectedBoostService, "AFKService.Init requires BoostService")

	dataService = injectedDataService
	currencyService = injectedCurrencyService
	boostService = injectedBoostService
	isInitialized = true
	debugLog("Initialized")
end

function AFKService.CalculateEarnings(player)
	if not dataService or not dataService.IsLoaded(player) then
		return {
			Coins = 0,
			Rep = 0,
			TeamMultiplier = 1,
			PrestigeMultiplier = 1,
			CoinsBoostMultiplier = 1,
			RepBoostMultiplier = 1,
		}
	end

	local data = dataService.GetData(player)
	if not data then
		return {
			Coins = 0,
			Rep = 0,
			TeamMultiplier = 1,
			PrestigeMultiplier = 1,
			CoinsBoostMultiplier = 1,
			RepBoostMultiplier = 1,
		}
	end

	local teamOverall = data.Team and data.Team.TeamOverall or 0
	local prestigeLevel = data.Progression and data.Progression.PrestigeLevel or 0
	local teamMultiplier = 1
	if teamOverall > 0 then
		teamMultiplier = 1 + (teamOverall / 500)
	end

	local prestigeMultiplier = 1 + (prestigeLevel * GameConfig.PrestigeCoinBonusPerLevel)
	local coinsBoostMultiplier = boostService.GetMultiplier(player, "Coins2x")
	local repBoostMultiplier = boostService.GetMultiplier(player, "Rep2x")

	local coinsEarned = math.floor(GameConfig.BaseCoinsPerAFKTick * teamMultiplier * prestigeMultiplier * coinsBoostMultiplier)
	local repEarned = math.floor(GameConfig.BaseRepPerAFKTick * prestigeMultiplier * repBoostMultiplier)

	return {
		Coins = math.max(0, coinsEarned),
		Rep = math.max(0, repEarned),
		TeamMultiplier = teamMultiplier,
		PrestigeMultiplier = prestigeMultiplier,
		CoinsBoostMultiplier = coinsBoostMultiplier,
		RepBoostMultiplier = repBoostMultiplier,
	}
end

function AFKService.ProcessTick(player)
	if not dataService or not dataService.IsLoaded(player) then
		return false, "Player data is not loaded"
	end

	boostService.CleanupExpiredBoosts(player)

	local earnings = AFKService.CalculateEarnings(player)
	if earnings.Coins > 0 then
		currencyService.AddCurrency(player, "Coins", earnings.Coins, "AFKTick")
	end
	if earnings.Rep > 0 then
		currencyService.AddCurrency(player, "Rep", earnings.Rep, "AFKTick")
	end

	debugLog(string.format("Awarded %s: +%d Coins, +%d Rep", player.Name, earnings.Coins, earnings.Rep))
	return true, earnings
end

function AFKService.GetAFKStats(player)
	local earnings = AFKService.CalculateEarnings(player)
	return {
		TickSeconds = GameConfig.AFKTickSeconds,
		FirstTickDelaySeconds = GameConfig.FirstAFKTickDelaySeconds,
		BaseCoinsPerTick = GameConfig.BaseCoinsPerAFKTick,
		BaseRepPerTick = GameConfig.BaseRepPerAFKTick,
		ProjectedCoinsPerTick = earnings.Coins,
		ProjectedRepPerTick = earnings.Rep,
		TeamMultiplier = earnings.TeamMultiplier,
		PrestigeMultiplier = earnings.PrestigeMultiplier,
		CoinsBoostMultiplier = earnings.CoinsBoostMultiplier,
		RepBoostMultiplier = earnings.RepBoostMultiplier,
	}
end

local function scheduleFirstTick(player)
	if firstTickScheduledByUserId[player.UserId] then
		return
	end

	firstTickScheduledByUserId[player.UserId] = true

	task.spawn(function()
		local elapsed = 0
		while elapsed < GameConfig.FirstAFKTickDelaySeconds do
			if not player.Parent or not isRunning then
				firstTickScheduledByUserId[player.UserId] = nil
				return
			end

			task.wait(1)
			elapsed = elapsed + 1
		end

		while player.Parent and isRunning and dataService and not dataService.IsLoaded(player) do
			task.wait(0.5)
		end

		if player.Parent and isRunning and dataService and dataService.IsLoaded(player) then
			AFKService.ProcessTick(player)
		end
	end)
end

function AFKService.Start()
	if isRunning then
		return
	end

	assert(isInitialized, "AFKService must be initialized before Start")
	isRunning = true
	debugLog("Started")

	Players.PlayerAdded:Connect(function(player)
		scheduleFirstTick(player)
	end)

	Players.PlayerRemoving:Connect(function(player)
		firstTickScheduledByUserId[player.UserId] = nil
	end)

	for _, player in ipairs(Players:GetPlayers()) do
		scheduleFirstTick(player)
	end

	task.spawn(function()
		while isRunning do
			task.wait(GameConfig.AFKTickSeconds)
			boostService.CleanupAllPlayers()
			for _, player in ipairs(Players:GetPlayers()) do
				AFKService.ProcessTick(player)
			end
		end
	end)
end

function AFKService.Stop()
	isRunning = false
	debugLog("Stopped")
end

return AFKService
