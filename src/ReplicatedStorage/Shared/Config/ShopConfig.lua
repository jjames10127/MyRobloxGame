local ShopConfig = {}

ShopConfig.Items = {
	Coins2xBoost = {
		DisplayName = "2x Coins Boost",
		Description = "Doubles AFK coin earnings for 15 minutes.",
		PurchaseType = "SoftCurrency",
		CostCurrency = "Coins",
		CostAmount = 1500,
		DeveloperProductId = 0,
		Grants = {
			{ Type = "Boost", BoostType = "Coins2x", DurationSeconds = 900 },
		},
	},
	Luck2xBoost = {
		DisplayName = "2x Luck Boost",
		Description = "Doubles pack luck for 10 minutes.",
		PurchaseType = "SoftCurrency",
		CostCurrency = "Coins",
		CostAmount = 3000,
		DeveloperProductId = 0,
		Grants = {
			{ Type = "Boost", BoostType = "Luck2x", DurationSeconds = 600 },
		},
	},
	Rep2xBoost = {
		DisplayName = "2x Rep Boost",
		Description = "Doubles rep earnings for 15 minutes.",
		PurchaseType = "SoftCurrency",
		CostCurrency = "Coins",
		CostAmount = 2000,
		DeveloperProductId = 0,
		Grants = {
			{ Type = "Boost", BoostType = "Rep2x", DurationSeconds = 900 },
		},
	},
	AutoOpenBoost = {
		DisplayName = "Auto Pack Opener",
		Description = "Placeholder for future automatic pack opening.",
		PurchaseType = "SoftCurrency",
		CostCurrency = "Coins",
		CostAmount = 5000,
		DeveloperProductId = 0,
		Grants = {
			{ Type = "Boost", BoostType = "AutoOpen", DurationSeconds = 600 },
		},
	},
	ShieldBoost = {
		DisplayName = "Troll Shield",
		Description = "Blocks troll effects for 10 minutes.",
		PurchaseType = "SoftCurrency",
		CostCurrency = "Coins",
		CostAmount = 2500,
		DeveloperProductId = 0,
		Grants = {
			{ Type = "Boost", BoostType = "Shield", DurationSeconds = 600 },
		},
	},
	TrollPack = {
		DisplayName = "Troll Pack",
		Description = "Gives random troll items for future use.",
		PurchaseType = "SoftCurrency",
		CostCurrency = "Coins",
		CostAmount = 1000,
		DeveloperProductId = 0,
		Grants = {
			{ Type = "TrollItem", ItemId = "ConfettiBomb", Amount = 1 },
			{ Type = "TrollItem", ItemId = "Airhorn", Amount = 1 },
		},
	},
	StarterBundle = {
		DisplayName = "Starter Bundle",
		Description = "Placeholder starter bundle.",
		PurchaseType = "RobuxPlaceholder",
		CostCurrency = nil,
		CostAmount = 0,
		DeveloperProductId = 0,
		Grants = {
			{ Type = "Currency", Currency = "Coins", Amount = 2500 },
			{ Type = "Currency", Currency = "PackTickets", Amount = 3 },
		},
	},
	VIP = {
		DisplayName = "VIP",
		Description = "Placeholder VIP pass.",
		PurchaseType = "RobuxPlaceholder",
		CostCurrency = nil,
		CostAmount = 0,
		DeveloperProductId = 0,
		Grants = {},
	},
}

function ShopConfig.GetItem(itemId)
	return ShopConfig.Items[itemId]
end

function ShopConfig.GetAllItems()
	return ShopConfig.Items
end

function ShopConfig.ValidateItem(itemId)
	local item = ShopConfig.GetItem(itemId)
	if not item then
		return false, "Unknown shop item: " .. tostring(itemId)
	end
	if type(item.DisplayName) ~= "string" or item.DisplayName == "" then
		return false, itemId .. " is missing DisplayName"
	end
	if type(item.Description) ~= "string" then
		return false, itemId .. " is missing Description"
	end
	if item.PurchaseType ~= "SoftCurrency" and item.PurchaseType ~= "RobuxPlaceholder" then
		return false, itemId .. " has invalid PurchaseType"
	end
	if item.PurchaseType == "SoftCurrency" then
		if type(item.CostCurrency) ~= "string" or type(item.CostAmount) ~= "number" or item.CostAmount < 0 then
			return false, itemId .. " has invalid soft-currency cost"
		end
	end
	if type(item.DeveloperProductId) ~= "number" then
		return false, itemId .. " is missing DeveloperProductId"
	end
	if type(item.Grants) ~= "table" then
		return false, itemId .. " Grants must be a table"
	end

	for _, grant in ipairs(item.Grants) do
		if type(grant) ~= "table" or type(grant.Type) ~= "string" then
			return false, itemId .. " has an invalid grant"
		end
		if grant.Type == "Currency" then
			if type(grant.Currency) ~= "string" or type(grant.Amount) ~= "number" or grant.Amount <= 0 then
				return false, itemId .. " has an invalid currency grant"
			end
		elseif grant.Type == "Boost" then
			if
				type(grant.BoostType) ~= "string"
				or type(grant.DurationSeconds) ~= "number"
				or grant.DurationSeconds <= 0
			then
				return false, itemId .. " has an invalid boost grant"
			end
		elseif grant.Type == "TrollItem" then
			if type(grant.ItemId) ~= "string" or type(grant.Amount) ~= "number" or grant.Amount <= 0 then
				return false, itemId .. " has an invalid troll item grant"
			end
		else
			return false, itemId .. " has unsupported grant type: " .. tostring(grant.Type)
		end
	end

	return true, "Shop item validated"
end

function ShopConfig.ValidateAllItems()
	local results = {}
	local allValid = true

	for itemId in pairs(ShopConfig.Items) do
		local isValid, result = ShopConfig.ValidateItem(itemId)
		results[itemId] = {
			IsValid = isValid,
			Result = result,
		}
		if not isValid then
			allValid = false
		end
	end

	return allValid, results
end

return ShopConfig
