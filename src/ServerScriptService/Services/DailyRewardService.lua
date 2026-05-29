local ReplicatedStorage = game:GetService("ReplicatedStorage")

local shared = ReplicatedStorage:WaitForChild("Shared")
local config = shared:WaitForChild("Config")
local utility = shared:WaitForChild("Utility")

local GameConfig = require(config:WaitForChild("GameConfig"))
local DailyRewardConfig = require(config:WaitForChild("DailyRewardConfig"))
local TableUtil = require(utility:WaitForChild("TableUtil"))
local TimeUtil = require(utility:WaitForChild("TimeUtil"))

local DailyRewardService = {}

local dataService = nil
local currencyService = nil
local boostService = nil
local isInitialized = false
local claimInProgressByUserId = {}

local function debugLog(...)
	if GameConfig.IsDebug then
		print("[DailyRewardService]", ...)
	end
end

local function getDailyData(player)
	if not dataService or not dataService.IsLoaded(player) then
		return nil
	end

	local data = dataService.GetData(player)
	if not data then
		return nil
	end

	data.DailyRewards = data.DailyRewards or {}
	data.DailyRewards.LastClaimTimestamp = data.DailyRewards.LastClaimTimestamp or 0
	data.DailyRewards.CurrentStreak = data.DailyRewards.CurrentStreak or 0
	return data.DailyRewards
end

function DailyRewardService.Init(injectedDataService, injectedCurrencyService, injectedBoostService)
	if isInitialized then
		return
	end

	assert(injectedDataService, "DailyRewardService.Init requires DataService")
	assert(injectedCurrencyService, "DailyRewardService.Init requires CurrencyService")
	assert(injectedBoostService, "DailyRewardService.Init requires BoostService")

	dataService = injectedDataService
	currencyService = injectedCurrencyService
	boostService = injectedBoostService
	isInitialized = true
	debugLog("Initialized")
end

function DailyRewardService.ValidateDailyRewardData(player)
	local dailyData = getDailyData(player)
	return dailyData ~= nil
end

function DailyRewardService.CanClaim(player)
	local dailyData = getDailyData(player)
	if not dailyData then
		return false, "Data not loaded."
	end

	local lastClaim = dailyData.LastClaimTimestamp or 0
	if lastClaim == 0 then
		return true
	end

	return TimeUtil.Now() - lastClaim >= DailyRewardConfig.ClaimCooldownSeconds
end

function DailyRewardService.CalculateNextStreak(player)
	local dailyData = getDailyData(player)
	if not dailyData then
		return 1
	end

	local now = TimeUtil.Now()
	local lastClaim = dailyData.LastClaimTimestamp or 0
	local currentStreak = dailyData.CurrentStreak or 0
	if lastClaim > 0 and now - lastClaim > DailyRewardConfig.StreakResetSeconds then
		return 1
	end

	return (currentStreak % DailyRewardConfig.CycleLengthDays) + 1
end

function DailyRewardService.GetCurrentRewardDay(player)
	return DailyRewardService.CalculateNextStreak(player)
end

function DailyRewardService.GetStatus(player)
	local dailyData = getDailyData(player)
	if not dailyData then
		return {
			CanClaim = false,
			CurrentStreak = 0,
			CurrentDay = 1,
			NextReward = DailyRewardConfig.GetReward(1),
			LastClaimTimestamp = 0,
			SecondsUntilNextClaim = 0,
			Error = "Data not loaded.",
		}
	end

	local canClaim = DailyRewardService.CanClaim(player)
	local currentDay = DailyRewardService.GetCurrentRewardDay(player)
	local lastClaim = dailyData.LastClaimTimestamp or 0
	local secondsUntilNextClaim = 0
	if not canClaim and lastClaim > 0 then
		secondsUntilNextClaim = TimeUtil.SecondsUntil(lastClaim + DailyRewardConfig.ClaimCooldownSeconds)
	end

	return {
		CanClaim = canClaim,
		CurrentStreak = dailyData.CurrentStreak or 0,
		CurrentDay = currentDay,
		NextReward = TableUtil.DeepCopy(DailyRewardConfig.GetReward(currentDay)),
		LastClaimTimestamp = lastClaim,
		SecondsUntilNextClaim = secondsUntilNextClaim,
	}
end

function DailyRewardService.GrantReward(player, rewardData)
	if type(rewardData) ~= "table" then
		return false, "Invalid reward data."
	end

	if rewardData.Type == "Currency" then
		local success, result = currencyService.AddCurrency(
			player,
			rewardData.Currency,
			rewardData.Amount,
			"DailyReward:" .. tostring(rewardData.Currency)
		)
		if not success then
			return false, result
		end

		return true, TableUtil.DeepCopy(rewardData)
	end

	if rewardData.Type == "Boost" then
		local success, result = boostService.GiveBoost(
			player,
			rewardData.BoostType,
			rewardData.DurationSeconds,
			"DailyReward:" .. tostring(rewardData.BoostType)
		)
		if not success then
			return false, result
		end

		return true, TableUtil.DeepCopy(rewardData)
	end

	return false, "Unsupported reward type: " .. tostring(rewardData.Type)
end

function DailyRewardService.Claim(player)
	if not dataService or not dataService.IsLoaded(player) then
		return {
			Success = false,
			Error = "Data not loaded.",
		}
	end
	if claimInProgressByUserId[player.UserId] then
		return {
			Success = false,
			Error = "Daily reward claim already in progress.",
		}
	end

	claimInProgressByUserId[player.UserId] = true

	local function finish(result)
		claimInProgressByUserId[player.UserId] = nil
		return result
	end

	local canClaim, claimError = DailyRewardService.CanClaim(player)
	if not canClaim then
		return finish({
			Success = false,
			Error = claimError or "Daily reward already claimed.",
			Status = DailyRewardService.GetStatus(player),
		})
	end

	local rewardDay = DailyRewardService.CalculateNextStreak(player)
	local rewardConfig = DailyRewardConfig.GetReward(rewardDay)
	if not rewardConfig then
		return finish({
			Success = false,
			Error = "Daily reward config missing.",
		})
	end

	local rewardsGranted = {}
	for _, rewardData in ipairs(rewardConfig.Rewards) do
		local success, result = DailyRewardService.GrantReward(player, rewardData)
		if not success then
			return finish({
				Success = false,
				Error = result or "Reward grant failed.",
			})
		end
		table.insert(rewardsGranted, result)
	end

	local now = TimeUtil.Now()
	local updateSuccess, updateResult = dataService.UpdateData(player, function(data)
		data.DailyRewards = data.DailyRewards or {}
		data.DailyRewards.LastClaimTimestamp = now
		data.DailyRewards.CurrentStreak = rewardDay
	end)
	if not updateSuccess then
		return finish({
			Success = false,
			Error = updateResult or "Daily reward save failed.",
		})
	end

	debugLog("Claimed day", rewardDay, "for", player.Name)

	return finish({
		Success = true,
		Day = rewardDay,
		RewardsGranted = rewardsGranted,
		NewStatus = DailyRewardService.GetStatus(player),
	})
end

return DailyRewardService
