local GameConfig = require(script.Parent.GameConfig)

local CurrencyConfig = {
	Currencies = {
		Coins = {
			DisplayName = "Coins",
			ShortName = "Coins",
			DefaultValue = GameConfig.StartingCoins,
			CanBeNegative = false,
		},
		Rep = {
			DisplayName = "Reputation",
			ShortName = "Rep",
			DefaultValue = GameConfig.StartingRep,
			CanBeNegative = false,
		},
		Rings = {
			DisplayName = "Championship Rings",
			ShortName = "Rings",
			DefaultValue = GameConfig.StartingRings,
			CanBeNegative = false,
		},
		PackTickets = {
			DisplayName = "Pack Tickets",
			ShortName = "Tickets",
			DefaultValue = GameConfig.StartingPackTickets,
			CanBeNegative = false,
		},
	},
}

function CurrencyConfig.GetCurrency(currencyName)
	return CurrencyConfig.Currencies[currencyName]
end

return CurrencyConfig
