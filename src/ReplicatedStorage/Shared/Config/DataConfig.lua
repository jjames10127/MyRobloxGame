local GameConfig = require(script.Parent.GameConfig)

local DataConfig = {
	DataStoreName = "BasketballAFKRNGArena_PlayerData_v1",
	DefaultData = {
		Profile = {
			UserId = 0,
			Username = "",
			CreatedAt = 0,
			LastLoginAt = 0,
		},
		Currencies = {
			Coins = GameConfig.StartingCoins,
			Rep = GameConfig.StartingRep,
			Rings = GameConfig.StartingRings,
			PackTickets = GameConfig.StartingPackTickets,
		},
		Inventory = {
			Cards = {},
			TrollItems = {},
			Cosmetics = {},
		},
		Team = {
			EquippedLineup = {
				PG = nil,
				SG = nil,
				SF = nil,
				PF = nil,
				C = nil,
			},
			TeamOverall = 0,
		},
		Progression = {
			Wins = 0,
			Losses = 0,
			WinStreak = 0,
			BestWinStreak = 0,
			Championships = 0,
			PrestigeLevel = 0,
			Division = "Rookie",
		},
		Packs = {
			TotalPacksOpened = 0,
			BestRarityPulled = "None",
		},
		DailyRewards = {
			LastClaimTimestamp = 0,
			CurrentStreak = 0,
		},
		Boosts = {
			ActiveBoosts = {},
		},
		Settings = {
			MusicEnabled = true,
			SFXEnabled = true,
		},
	},
}

return DataConfig
