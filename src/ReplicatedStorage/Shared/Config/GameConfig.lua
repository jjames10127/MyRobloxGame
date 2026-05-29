local GameConfig = {
	GameName = "Basketball AFK RNG Arena",
	Version = "0.1.0",
	IsDebug = true,
	SaveIntervalSeconds = 120,
	AFKTickSeconds = 30,
	FirstAFKTickDelaySeconds = 5,
	BaseCoinsPerAFKTick = 25,
	BaseRepPerAFKTick = 2,
	PrestigeCoinBonusPerLevel = 0.10,
	MaxCardsPerPlayer = 500,
	StartingCoins = 500,
	StartingRep = 0,
	StartingRings = 0,
	StartingPackTickets = 0,
	DebugAllowedUserIds = {
		-- Add trusted Roblox user IDs here for server-only debug helpers.
	},
}

return GameConfig
