local RarityConfig = {
	Order = {
		"Common",
		"Uncommon",
		"Rare",
		"Epic",
		"Legendary",
		"Mythic",
		"Secret",
	},
	Rarities = {
		Common = {
			DisplayName = "Common",
			Order = 1,
			MinOVR = 60,
			MaxOVR = 69,
		},
		Uncommon = {
			DisplayName = "Uncommon",
			Order = 2,
			MinOVR = 70,
			MaxOVR = 74,
		},
		Rare = {
			DisplayName = "Rare",
			Order = 3,
			MinOVR = 75,
			MaxOVR = 79,
		},
		Epic = {
			DisplayName = "Epic",
			Order = 4,
			MinOVR = 80,
			MaxOVR = 86,
		},
		Legendary = {
			DisplayName = "Legendary",
			Order = 5,
			MinOVR = 87,
			MaxOVR = 93,
		},
		Mythic = {
			DisplayName = "Mythic",
			Order = 6,
			MinOVR = 94,
			MaxOVR = 98,
		},
		Secret = {
			DisplayName = "Secret",
			Order = 7,
			MinOVR = 99,
			MaxOVR = 99,
		},
	},
}

function RarityConfig.GetRarity(rarityName)
	return RarityConfig.Rarities[rarityName]
end

return RarityConfig
