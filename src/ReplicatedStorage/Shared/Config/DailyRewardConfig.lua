local DailyRewardConfig = {}

DailyRewardConfig.CycleLengthDays = 7
DailyRewardConfig.ClaimCooldownSeconds = 86400
DailyRewardConfig.StreakResetSeconds = 172800

DailyRewardConfig.Rewards = {
	[1] = {
		DisplayName = "Day 1 Reward",
		Rewards = {
			{ Type = "Currency", Currency = "Coins", Amount = 500 },
		},
	},
	[2] = {
		DisplayName = "Day 2 Reward",
		Rewards = {
			{ Type = "Currency", Currency = "Coins", Amount = 1000 },
		},
	},
	[3] = {
		DisplayName = "Day 3 Reward",
		Rewards = {
			{ Type = "Currency", Currency = "PackTickets", Amount = 1 },
		},
	},
	[4] = {
		DisplayName = "Day 4 Reward",
		Rewards = {
			{ Type = "Boost", BoostType = "Coins2x", DurationSeconds = 600 },
		},
	},
	[5] = {
		DisplayName = "Day 5 Reward",
		Rewards = {
			{ Type = "Currency", Currency = "Rep", Amount = 250 },
		},
	},
	[6] = {
		DisplayName = "Day 6 Reward",
		Rewards = {
			{ Type = "Currency", Currency = "PackTickets", Amount = 2 },
		},
	},
	[7] = {
		DisplayName = "Day 7 Reward",
		Rewards = {
			{ Type = "Currency", Currency = "Rings", Amount = 1 },
		},
	},
}

function DailyRewardConfig.GetReward(day)
	return DailyRewardConfig.Rewards[day]
end

function DailyRewardConfig.GetAllRewards()
	return DailyRewardConfig.Rewards
end

function DailyRewardConfig.ValidateRewards()
	for day = 1, DailyRewardConfig.CycleLengthDays do
		local rewardDay = DailyRewardConfig.Rewards[day]
		if type(rewardDay) ~= "table" then
			return false, "Missing daily reward for day " .. tostring(day)
		end
		if type(rewardDay.DisplayName) ~= "string" or rewardDay.DisplayName == "" then
			return false, "Daily reward day " .. tostring(day) .. " is missing DisplayName"
		end
		if type(rewardDay.Rewards) ~= "table" or #rewardDay.Rewards == 0 then
			return false, "Daily reward day " .. tostring(day) .. " has no rewards"
		end

		for _, reward in ipairs(rewardDay.Rewards) do
			if type(reward) ~= "table" or type(reward.Type) ~= "string" then
				return false, "Invalid reward entry on day " .. tostring(day)
			end
			if reward.Type == "Currency" then
				if type(reward.Currency) ~= "string" or type(reward.Amount) ~= "number" or reward.Amount <= 0 then
					return false, "Invalid currency reward on day " .. tostring(day)
				end
			elseif reward.Type == "Boost" then
				if
					type(reward.BoostType) ~= "string"
					or type(reward.DurationSeconds) ~= "number"
					or reward.DurationSeconds <= 0
				then
					return false, "Invalid boost reward on day " .. tostring(day)
				end
			else
				return false, "Unsupported daily reward type: " .. tostring(reward.Type)
			end
		end
	end

	return true, "Daily rewards validated"
end

return DailyRewardConfig
