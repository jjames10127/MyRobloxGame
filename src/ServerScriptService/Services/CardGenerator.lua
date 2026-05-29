local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local shared = ReplicatedStorage:WaitForChild("Shared")
local config = shared:WaitForChild("Config")

local RarityConfig = require(config:WaitForChild("RarityConfig"))

local CardGenerator = {}

local POSITIONS = { "PG", "SG", "SF", "PF", "C" }
local FIRST_NAMES = {
	"Jaylen",
	"Marcus",
	"Andre",
	"Darius",
	"Jalen",
	"Malik",
	"Cameron",
	"Isaiah",
	"Jordan",
	"Tyler",
	"Zion",
	"Devin",
	"Kobe",
	"Miles",
	"Brandon",
}
local LAST_NAMES = {
	"Carter",
	"Johnson",
	"Williams",
	"Brooks",
	"Parker",
	"Davis",
	"Thompson",
	"Walker",
	"Harris",
	"Mitchell",
	"Evans",
	"Turner",
	"King",
	"Wright",
	"Anderson",
}
local BADGES = {
	"Clutch Shooter",
	"Lockdown Defender",
	"Floor General",
	"Glass Cleaner",
	"Fast Break Demon",
	"Deep Range",
	"Ankle Breaker",
	"Shot Creator",
	"Paint Beast",
	"Two-Way Star",
}

local function clampStat(value)
	return math.clamp(math.floor(value + 0.5), 40, 99)
end

function CardGenerator.GenerateCardId()
	return "CARD_" .. HttpService:GenerateGUID(false)
end

function CardGenerator.GenerateName()
	local firstName = FIRST_NAMES[math.random(1, #FIRST_NAMES)]
	local lastName = LAST_NAMES[math.random(1, #LAST_NAMES)]
	return firstName .. " " .. lastName
end

function CardGenerator.GeneratePosition()
	return POSITIONS[math.random(1, #POSITIONS)]
end

function CardGenerator.GenerateStats(overall, position)
	local stats = {
		Shooting = overall + math.random(-6, 6),
		Defense = overall + math.random(-6, 6),
		Speed = overall + math.random(-6, 6),
		Passing = overall + math.random(-6, 6),
		Rebounding = overall + math.random(-6, 6),
		Clutch = overall + math.random(-6, 6),
	}

	if position == "PG" then
		stats.Passing += 6
		stats.Speed += 5
		stats.Rebounding -= 7
	elseif position == "SG" then
		stats.Shooting += 6
		stats.Clutch += 5
		stats.Rebounding -= 4
	elseif position == "SF" then
		stats.Shooting += 2
		stats.Defense += 2
		stats.Speed += 2
	elseif position == "PF" then
		stats.Defense += 5
		stats.Rebounding += 6
		stats.Passing -= 4
	elseif position == "C" then
		stats.Rebounding += 8
		stats.Defense += 6
		stats.Speed -= 6
		stats.Passing -= 4
	end

	for statName, value in pairs(stats) do
		stats[statName] = clampStat(value)
	end

	return stats
end

function CardGenerator.GenerateBadge(rarity, position)
	if rarity == "Secret" or rarity == "Mythic" then
		return "Two-Way Star"
	end
	if position == "PG" then
		return math.random(1, 2) == 1 and "Floor General" or "Ankle Breaker"
	elseif position == "SG" then
		return math.random(1, 2) == 1 and "Deep Range" or "Clutch Shooter"
	elseif position == "PF" then
		return math.random(1, 2) == 1 and "Glass Cleaner" or "Paint Beast"
	elseif position == "C" then
		return math.random(1, 2) == 1 and "Paint Beast" or "Glass Cleaner"
	end

	return BADGES[math.random(1, #BADGES)]
end

function CardGenerator.GenerateCard(rarity)
	local rarityInfo = RarityConfig.GetRarity(rarity)
	if not rarityInfo then
		return nil, "Invalid rarity"
	end

	local overall = math.random(rarityInfo.MinOVR, rarityInfo.MaxOVR)
	if rarity == "Secret" then
		overall = 99
	end

	local position = CardGenerator.GeneratePosition()
	local card = {
		CardId = CardGenerator.GenerateCardId(),
		Name = CardGenerator.GenerateName(),
		Rarity = rarity,
		Overall = overall,
		Position = position,
		Stats = CardGenerator.GenerateStats(overall, position),
		Badge = CardGenerator.GenerateBadge(rarity, position),
		CreatedAt = os.time(),
		IsLocked = false,
	}

	return card
end

return CardGenerator
