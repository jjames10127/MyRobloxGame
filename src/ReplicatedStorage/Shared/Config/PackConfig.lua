local PackConfig = {}

PackConfig.Packs = {
	StarterPack = {
		DisplayName = "Starter Pack",
		CostCurrency = "Coins",
		CostAmount = 500,
		Odds = {
			Common = 70,
			Uncommon = 20,
			Rare = 8,
			Epic = 1.8,
			Legendary = 0.2,
			Mythic = 0,
			Secret = 0,
		},
	},
	ProPack = {
		DisplayName = "Pro Pack",
		CostCurrency = "Coins",
		CostAmount = 2500,
		Odds = {
			Common = 55,
			Uncommon = 25,
			Rare = 14,
			Epic = 5,
			Legendary = 0.9,
			Mythic = 0.1,
			Secret = 0,
		},
	},
	AllStarPack = {
		DisplayName = "All-Star Pack",
		CostCurrency = "Coins",
		CostAmount = 10000,
		Odds = {
			Common = 35,
			Uncommon = 25,
			Rare = 22,
			Epic = 13,
			Legendary = 4,
			Mythic = 0.95,
			Secret = 0.05,
		},
	},
	FinalsPack = {
		DisplayName = "Finals Pack",
		CostCurrency = "Rings",
		CostAmount = 3,
		Odds = {
			Common = 0,
			Uncommon = 20,
			Rare = 35,
			Epic = 30,
			Legendary = 12,
			Mythic = 2.8,
			Secret = 0.2,
		},
	},
}

function PackConfig.GetPack(packId)
	return PackConfig.Packs[packId]
end

function PackConfig.GetAllPacks()
	return PackConfig.Packs
end

function PackConfig.GetOdds(packId)
	local pack = PackConfig.GetPack(packId)
	if not pack then
		return nil
	end

	return pack.Odds
end

function PackConfig.ValidateOdds(packId)
	local pack = PackConfig.GetPack(packId)
	if not pack then
		return false, "Unknown pack: " .. tostring(packId)
	end

	local total = 0
	for _, chance in pairs(pack.Odds) do
		if type(chance) ~= "number" then
			return false, "Non-numeric odds found in " .. packId
		end
		total = total + chance
	end

	local isValid = math.abs(total - 100) < 0.0001
	if not isValid then
		return false, string.format("%s odds total %.4f, expected 100", packId, total)
	end

	return true, total
end

function PackConfig.ValidateAllPacks()
	local results = {}
	local allValid = true

	for packId in pairs(PackConfig.Packs) do
		local isValid, result = PackConfig.ValidateOdds(packId)
		results[packId] = {
			IsValid = isValid,
			Result = result,
		}

		if not isValid then
			allValid = false
		end
	end

	return allValid, results
end

return PackConfig
