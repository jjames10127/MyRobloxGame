local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local mainUI = playerGui:WaitForChild("MainUI")
mainUI.ResetOnSpawn = false

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local dataRemotes = remotes:WaitForChild("Data")
local currencyRemotes = remotes:WaitForChild("Currency")
local boostRemotes = remotes:WaitForChild("Boosts")
local afkRemotes = remotes:WaitForChild("AFK")
local packRemotes = remotes:WaitForChild("Packs")
local inventoryRemotes = remotes:WaitForChild("Inventory")
local dailyRewardRemotes = remotes:WaitForChild("DailyRewards")
local shopRemotes = remotes:WaitForChild("Shop")

local getPlayerData = dataRemotes:WaitForChild("GetPlayerData")
local getCurrencies = currencyRemotes:WaitForChild("GetCurrencies")
local getActiveBoosts = boostRemotes:WaitForChild("GetActiveBoosts")
local getAFKStats = afkRemotes:WaitForChild("GetAFKStats")
local getPacks = packRemotes:WaitForChild("GetPacks")
local getPackOdds = packRemotes:WaitForChild("GetPackOdds")
local openPack = packRemotes:WaitForChild("OpenPack")
local getCards = inventoryRemotes:WaitForChild("GetCards")
local getDailyRewardStatus = dailyRewardRemotes:WaitForChild("GetDailyRewardStatus")
local claimDailyReward = dailyRewardRemotes:WaitForChild("ClaimDailyReward")
local getShopItems = shopRemotes:WaitForChild("GetShopItems")
local purchaseShopItem = shopRemotes:WaitForChild("PurchaseShopItem")

local playerData = getPlayerData:InvokeServer() or {}
local currencies = getCurrencies:InvokeServer() or {}
local activeBoosts = getActiveBoosts:InvokeServer() or {}
local afkStats = getAFKStats:InvokeServer() or {}
local packs = getPacks:InvokeServer() or {}
local cards = getCards:InvokeServer() or {}
local dailyStatus = getDailyRewardStatus:InvokeServer() or {}
local shopItems = getShopItems:InvokeServer() or {}

print("[ClientMain] Read-only player data received:", playerData)
print("[ClientMain] Read-only currencies received:", currencies)
print("[ClientMain] Read-only active boosts received:", activeBoosts)
print("[ClientMain] Read-only AFK stats received:", afkStats)
print("[ClientMain] Read-only packs received:", packs)
print("[ClientMain] Read-only cards received:", cards)
print("[ClientMain] Read-only daily status received:", dailyStatus)
print("[ClientMain] Read-only shop items received:", shopItems)

local COLORS = {
	Panel = Color3.fromRGB(13, 17, 23),
	PanelLight = Color3.fromRGB(25, 31, 40),
	Button = Color3.fromRGB(35, 52, 76),
	ButtonHot = Color3.fromRGB(28, 110, 122),
	Text = Color3.fromRGB(242, 245, 248),
	Muted = Color3.fromRGB(174, 183, 193),
	Accent = Color3.fromRGB(72, 210, 217),
	Gold = Color3.fromRGB(232, 178, 75),
	Orange = Color3.fromRGB(224, 101, 31),
}

local RARITY_COLORS = {
	Common = Color3.fromRGB(210, 214, 218),
	Uncommon = Color3.fromRGB(88, 210, 128),
	Rare = Color3.fromRGB(88, 156, 255),
	Epic = Color3.fromRGB(176, 94, 255),
	Legendary = Color3.fromRGB(255, 194, 76),
	Mythic = Color3.fromRGB(255, 92, 92),
	Secret = Color3.fromRGB(72, 235, 230),
}

local selectedPackId = "StarterPack"
local panels = {}
local hudCurrencyLabel
local bestCardsList
local cardPreviewWidget
local cardPreviewExpanded = true
local rightStatsLabel
local updateProfileDisplay
local inventoryList
local packDetailLabel
local packResultLabel
local dailyStatusLabel
local dailyResultLabel
local shopResultLabel
local teamList

local function clearExistingUi(name)
	local existing = mainUI:FindFirstChild(name)
	if existing then
		existing:Destroy()
	end
end

for _, uiName in ipairs({
	"Placeholder",
	"HudRoot",
	"PackUI",
	"InventoryUI",
	"DailyRewardUI",
	"ShopUI",
	"TeamUI",
	"PracticeUI",
}) do
	clearExistingUi(uiName)
end

local function addCorner(instance, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius or 8)
	corner.Parent = instance
	return corner
end

local function addStroke(instance, color, transparency)
	local stroke = Instance.new("UIStroke")
	stroke.Color = color or COLORS.Accent
	stroke.Transparency = transparency or 0.65
	stroke.Thickness = 1
	stroke.Parent = instance
	return stroke
end

local function makeLabel(parent, name, text, position, size, textSize)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.BackgroundTransparency = 1
	label.Position = position
	label.Size = size
	label.Font = Enum.Font.GothamMedium
	label.Text = text
	label.TextColor3 = COLORS.Text
	label.TextSize = textSize or 14
	label.TextWrapped = true
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Center
	label.Parent = parent
	return label
end

local function makeButton(parent, name, text, position, size)
	local button = Instance.new("TextButton")
	button.Name = name
	button.BackgroundColor3 = COLORS.Button
	button.BackgroundTransparency = 0.08
	button.BorderSizePixel = 0
	button.Position = position
	button.Size = size
	button.Font = Enum.Font.GothamBold
	button.Text = text
	button.TextColor3 = COLORS.Text
	button.TextSize = 13
	button.TextWrapped = true
	button.Parent = parent
	addCorner(button, 7)
	return button
end

local function makeCard(parent, name, position, size)
	local frame = Instance.new("Frame")
	frame.Name = name
	frame.BackgroundColor3 = COLORS.Panel
	frame.BackgroundTransparency = 0.22
	frame.BorderSizePixel = 0
	frame.Position = position
	frame.Size = size
	frame.Parent = parent
	addCorner(frame, 10)
	addStroke(frame, COLORS.Accent, 0.72)
	return frame
end

local function getOrCreateStroke(instance)
	local stroke = instance:FindFirstChildOfClass("UIStroke")
	if stroke then
		return stroke
	end
	return addStroke(instance, COLORS.Accent, 0.72)
end

local function makePanel(name, title)
	local frame = makeCard(mainUI, name, UDim2.fromScale(0.5, 0.52), UDim2.fromScale(0.6, 0.62))
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.BackgroundTransparency = 0.18
	frame.Visible = false
	frame.ZIndex = 20

	local sizeConstraint = Instance.new("UISizeConstraint")
	sizeConstraint.MinSize = Vector2.new(560, 360)
	sizeConstraint.MaxSize = Vector2.new(780, 540)
	sizeConstraint.Parent = frame

	makeLabel(frame, "Title", title, UDim2.fromOffset(20, 14), UDim2.new(1, -70, 0, 32), 20).Font = Enum.Font.GothamBold
	local closeButton = makeButton(frame, "CloseButton", "X", UDim2.new(1, -46, 0, 14), UDim2.fromOffset(28, 28))
	closeButton.BackgroundColor3 = Color3.fromRGB(80, 45, 50)
	closeButton.MouseButton1Click:Connect(function()
		frame.Visible = false
	end)

	panels[name] = frame
	return frame
end

local function formatReward(reward)
	if reward.Type == "Currency" then
		return string.format("%d %s", reward.Amount, reward.Currency)
	end
	if reward.Type == "Boost" then
		return string.format("%s for %ds", reward.BoostType, reward.DurationSeconds)
	end
	if reward.Type == "TrollItem" then
		return string.format("%dx %s", reward.Amount, reward.ItemId)
	end
	return tostring(reward.Type)
end

local function getWins()
	local progression = playerData.Progression
	return progression and progression.Wins or 0
end

local function getLosses()
	local progression = playerData.Progression
	return progression and progression.Losses or 0
end

local function getLeague()
	local progression = playerData.Progression
	return progression and progression.Division or "Rookie"
end

local function getLevel()
	local progression = playerData.Progression
	return (progression and progression.PrestigeLevel or 0) + 1
end

local function getTeamOverall()
	local team = playerData.Team
	return team and team.TeamOverall or 0
end

local function getBestCards(limit)
	local sortedCards = {}
	for _, card in ipairs(cards) do
		table.insert(sortedCards, card)
	end
	table.sort(sortedCards, function(left, right)
		return (left.Overall or 0) > (right.Overall or 0)
	end)

	local bestCards = {}
	for index = 1, limit do
		bestCards[index] = sortedCards[index]
	end
	return bestCards
end

local function formatCardLine(card, emptyText)
	if not card then
		return emptyText
	end
	return string.format("%s\n%s | %d OVR | %s", card.Name, card.Rarity, card.Overall, card.Position)
end

local function getStat(card, statName, fallback)
	if not card or type(card.Stats) ~= "table" then
		return fallback or 0
	end
	return card.Stats[statName] or fallback or 0
end

local function getProfileStats(card)
	if not card then
		return {
			PAC = 0,
			SHO = 0,
			PAS = 0,
			DRI = 0,
			DEF = 0,
			PHY = 0,
		}
	end

	return {
		PAC = getStat(card, "Speed", card.Overall),
		SHO = getStat(card, "Shooting", card.Overall),
		PAS = getStat(card, "Passing", card.Overall),
		DRI = math.floor(((getStat(card, "Speed", card.Overall) + getStat(card, "Passing", card.Overall)) / 2) + 0.5),
		DEF = getStat(card, "Defense", card.Overall),
		PHY = getStat(card, "Rebounding", card.Overall),
	}
end

local function refreshData()
	playerData = getPlayerData:InvokeServer() or playerData or {}
	currencies = getCurrencies:InvokeServer() or currencies or {}
	activeBoosts = getActiveBoosts:InvokeServer() or activeBoosts or {}
	afkStats = getAFKStats:InvokeServer() or afkStats or {}
	cards = getCards:InvokeServer() or cards or {}
end

local function refreshHud()
	refreshData()

	if hudCurrencyLabel then
		hudCurrencyLabel.Text = string.format("Coins: %d    Wins: %d", currencies.Coins or 0, getWins())
	end

	if bestCardsList then
		local bestCards = getBestCards(3)
		for index = 1, 3 do
			local slot = bestCardsList:FindFirstChild("BestCard" .. index)
			if slot then
				local label = slot:FindFirstChild("CardText")
				if label then
					label.Text = formatCardLine(bestCards[index], "Empty Slot " .. tostring(index))
				end
				local stroke = getOrCreateStroke(slot)
				local rarity = bestCards[index] and bestCards[index].Rarity or "Common"
				stroke.Color = RARITY_COLORS[rarity] or COLORS.Accent
				stroke.Transparency = bestCards[index] and 0.2 or 0.7
			end
		end
	end

	if rightStatsLabel then
		rightStatsLabel.Text = string.format(
			"Level  %d\nSkill Points  %d\nTeam OVR  %d\nRecord  %d-%d\nLeague  %s\nQuest  Daily / Packs",
			getLevel(),
			0,
			getTeamOverall(),
			getWins(),
			getLosses(),
			getLeague()
		)
	end

	if updateProfileDisplay then
		updateProfileDisplay()
	end
end

local function makeWorldPart(parent, name, size, cframe, color, material)
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = true
	part.Size = size
	part.CFrame = cframe
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent
	return part
end

local function makeProfileSurface(parent, adornee, name)
	local gui = Instance.new("SurfaceGui")
	gui.Name = name
	gui.Adornee = adornee
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 55
	gui.Parent = parent

	local label = Instance.new("TextLabel")
	label.Name = "ProfileText"
	label.BackgroundTransparency = 1
	label.Position = UDim2.fromScale(0.06, 0.06)
	label.Size = UDim2.fromScale(0.88, 0.88)
	label.Font = Enum.Font.GothamBold
	label.TextColor3 = COLORS.Text
	label.TextScaled = true
	label.TextWrapped = true
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Top
	label.Parent = gui

	return label
end

local function buildLocalProfileDisplay()
	local existing = Workspace:FindFirstChild("LocalPlayerProfileDisplay")
	if existing then
		existing:Destroy()
	end

	local model = Instance.new("Model")
	model.Name = "LocalPlayerProfileDisplay"
	model.Parent = Workspace

	makeWorldPart(
		model,
		"ProfilePedestal",
		Vector3.new(13, 0.7, 7),
		CFrame.new(-86, 1.05, -32),
		Color3.fromRGB(222, 222, 216),
		Enum.Material.SmoothPlastic
	)
	makeWorldPart(
		model,
		"PedestalAccent",
		Vector3.new(13.3, 0.18, 7.3),
		CFrame.new(-86, 1.52, -32),
		COLORS.Gold,
		Enum.Material.SmoothPlastic
	)
	local cardBoard = makeWorldPart(
		model,
		"PremiumProfileCard",
		Vector3.new(8.6, 11.5, 0.38),
		CFrame.new(-81.8, 7.2, -34.9) * CFrame.Angles(0, math.rad(180), 0),
		Color3.fromRGB(16, 22, 30),
		Enum.Material.SmoothPlastic
	)
	cardBoard.Reflectance = 0.06
	makeWorldPart(
		model,
		"ProfileCardTopTrim",
		Vector3.new(9, 0.18, 0.14),
		CFrame.new(-81.8, 13.16, -35.12),
		COLORS.Gold,
		Enum.Material.SmoothPlastic
	)
	makeWorldPart(
		model,
		"ProfileCardBottomTrim",
		Vector3.new(9, 0.18, 0.14),
		CFrame.new(-81.8, 1.24, -35.12),
		COLORS.Gold,
		Enum.Material.SmoothPlastic
	)
	makeWorldPart(
		model,
		"ProfileCardLeftTrim",
		Vector3.new(0.18, 12, 0.14),
		CFrame.new(-86.3, 7.2, -35.12),
		COLORS.Gold,
		Enum.Material.SmoothPlastic
	)
	makeWorldPart(
		model,
		"ProfileCardRightTrim",
		Vector3.new(0.18, 12, 0.14),
		CFrame.new(-77.3, 7.2, -35.12),
		COLORS.Gold,
		Enum.Material.SmoothPlastic
	)

	local surfaceText = makeProfileSurface(model, cardBoard, "ProfileCardGui")
	task.spawn(function()
		local success, avatarModel = pcall(function()
			return Players:CreateHumanoidModelFromUserId(player.UserId)
		end)
		if success and avatarModel then
			avatarModel.Name = "PlayerAvatarPreview"
			avatarModel.Parent = model
			for _, descendant in ipairs(avatarModel:GetDescendants()) do
				if descendant:IsA("BasePart") then
					descendant.Anchored = true
					descendant.CanCollide = false
				end
			end
			avatarModel:PivotTo(CFrame.new(-90.8, 3.2, -33.8) * CFrame.Angles(0, math.rad(180), 0))
		end
	end)

	updateProfileDisplay = function()
		local bestCard = getBestCards(1)[1]
		local stats = getProfileStats(bestCard)
		local cardName = bestCard and bestCard.Name or "No Card Equipped"
		local overall = bestCard and bestCard.Overall or getTeamOverall()
		local position = bestCard and bestCard.Position or "N/A"
		surfaceText.Text = string.format(
			"%s\n%s\nOVR %d   POS %s\n\nPAC %d   SHO %d\nPAS %d   DRI %d\nDEF %d   PHY %d\n\nRecord %d-%d\nLeague %s",
			player.Name,
			cardName,
			overall,
			position,
			stats.PAC,
			stats.SHO,
			stats.PAS,
			stats.DRI,
			stats.DEF,
			stats.PHY,
			getWins(),
			getLosses(),
			getLeague()
		)
	end

	updateProfileDisplay()
end

local function openPanel(panelName)
	for _, panel in pairs(panels) do
		panel.Visible = false
	end

	local panel = panels[panelName]
	if panel then
		panel.Visible = true
	end
end

local hudRoot = Instance.new("Frame")
hudRoot.Name = "HudRoot"
hudRoot.BackgroundTransparency = 1
hudRoot.Size = UDim2.fromScale(1, 1)
hudRoot.Parent = mainUI

local titleHud = makeCard(hudRoot, "TitleHud", UDim2.fromOffset(18, 18), UDim2.fromOffset(205, 34))
makeLabel(titleHud, "Title", "Basketball AFK RNG", UDim2.fromOffset(12, 0), UDim2.new(1, -24, 1, 0), 14).Font =
	Enum.Font.GothamBold

local currencyHud = makeCard(hudRoot, "CurrencyHud", UDim2.new(1, -238, 0, 18), UDim2.fromOffset(220, 34))
hudCurrencyLabel =
	makeLabel(currencyHud, "CurrencyText", "Coins: 0    Wins: 0", UDim2.fromOffset(12, 0), UDim2.new(1, -24, 1, 0), 14)
hudCurrencyLabel.TextXAlignment = Enum.TextXAlignment.Right

local rightStatsHud = makeCard(hudRoot, "StatsHud", UDim2.new(1, -238, 0, 64), UDim2.fromOffset(220, 178))
rightStatsHud.BackgroundTransparency = 0.42
makeLabel(rightStatsHud, "Title", "PLAYER STATS", UDim2.fromOffset(12, 8), UDim2.new(1, -24, 0, 18), 12).Font =
	Enum.Font.GothamBold
rightStatsLabel = makeLabel(rightStatsHud, "Stats", "", UDim2.fromOffset(12, 30), UDim2.new(1, -24, 1, -38), 13)
rightStatsLabel.TextYAlignment = Enum.TextYAlignment.Top

local navHud = Instance.new("Frame")
navHud.Name = "NavButtons"
navHud.BackgroundTransparency = 1
navHud.Position = UDim2.fromOffset(18, 68)
navHud.Size = UDim2.fromOffset(112, 272)
navHud.Parent = hudRoot

local navButtons = {
	{ "PlayButton", "Play", "PracticeUI" },
	{ "PracticeButton", "1v1", "PracticeUI" },
	{ "PacksButton", "Packs", "PackUI" },
	{ "InventoryButton", "Inventory", "InventoryUI" },
	{ "TeamButton", "Team", "TeamUI" },
	{ "ShopButton", "Shop", "ShopUI" },
	{ "DailyButton", "Daily", "DailyRewardUI" },
}

for index, buttonInfo in ipairs(navButtons) do
	local button = makeButton(
		navHud,
		buttonInfo[1],
		buttonInfo[2],
		UDim2.fromOffset(0, (index - 1) * 36),
		UDim2.fromOffset(104, 30)
	)
	button.MouseButton1Click:Connect(function()
		openPanel(buttonInfo[3])
	end)
end

cardPreviewWidget = makeCard(hudRoot, "BestCardsWidget", UDim2.fromOffset(18, 286), UDim2.fromOffset(238, 190))
cardPreviewWidget.BackgroundTransparency = 0.45
makeLabel(cardPreviewWidget, "Title", "Best Cards", UDim2.fromOffset(12, 8), UDim2.new(1, -54, 0, 22), 14).Font =
	Enum.Font.GothamBold
local collapseCardsButton =
	makeButton(cardPreviewWidget, "CollapseButton", "-", UDim2.new(1, -36, 0, 8), UDim2.fromOffset(24, 24))
bestCardsList = Instance.new("Frame")
bestCardsList.Name = "BestCardsList"
bestCardsList.BackgroundTransparency = 1
bestCardsList.Position = UDim2.fromOffset(12, 40)
bestCardsList.Size = UDim2.new(1, -24, 0, 138)
bestCardsList.Parent = cardPreviewWidget

for index = 1, 3 do
	local slot =
		makeCard(bestCardsList, "BestCard" .. index, UDim2.fromOffset(0, (index - 1) * 46), UDim2.new(1, 0, 0, 40))
	slot.BackgroundTransparency = 0.34
	local label = makeLabel(
		slot,
		"CardText",
		"Empty Slot " .. tostring(index),
		UDim2.fromOffset(10, 4),
		UDim2.new(1, -20, 1, -8),
		12
	)
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Center
end

collapseCardsButton.MouseButton1Click:Connect(function()
	cardPreviewExpanded = not cardPreviewExpanded
	bestCardsList.Visible = cardPreviewExpanded
	collapseCardsButton.Text = cardPreviewExpanded and "-" or "Cards"
	cardPreviewWidget.Size = cardPreviewExpanded and UDim2.fromOffset(238, 190) or UDim2.fromOffset(92, 38)
end)

local function formatOdds(odds)
	local lines = {}
	for _, rarity in ipairs({ "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Secret" }) do
		table.insert(lines, string.format("%s: %.4g%%", rarity, odds[rarity] or 0))
	end
	return table.concat(lines, "\n")
end

local function refreshPackDetails()
	local response = getPackOdds:InvokeServer(selectedPackId)
	local pack = packs[selectedPackId]
	if not response or not response.Success or not pack then
		packDetailLabel.Text = response and response.Error or "Failed to load odds."
		return
	end

	packDetailLabel.Text = string.format(
		"%s\nCost: %d %s\n\n%s",
		pack.DisplayName,
		pack.CostAmount,
		pack.CostCurrency,
		formatOdds(response.Odds)
	)
end

local packPanel = makePanel("PackUI", "Packs")
local packList = makeCard(packPanel, "PackList", UDim2.fromOffset(20, 60), UDim2.new(0, 160, 1, -86))
packList.BackgroundTransparency = 0.32
packDetailLabel =
	makeLabel(packPanel, "PackDetails", "Select a pack.", UDim2.fromOffset(200, 64), UDim2.new(1, -230, 0, 210), 14)
packDetailLabel.TextYAlignment = Enum.TextYAlignment.Top
packResultLabel =
	makeLabel(packPanel, "PackResult", "No pack opened yet.", UDim2.fromOffset(200, 296), UDim2.new(1, -230, 0, 80), 13)
packResultLabel.TextYAlignment = Enum.TextYAlignment.Top

local packOrder = {
	{ "StarterPack", "Starter Pack" },
	{ "ProPack", "Pro Pack" },
	{ "AllStarPack", "All-Star Pack" },
	{ "FinalsPack", "Finals Pack" },
}

for index, packInfo in ipairs(packOrder) do
	local packId = packInfo[1]
	local button = makeButton(
		packList,
		packId .. "Button",
		packInfo[2],
		UDim2.fromOffset(12, 14 + (index - 1) * 40),
		UDim2.new(1, -24, 0, 30)
	)
	button.MouseButton1Click:Connect(function()
		selectedPackId = packId
		refreshPackDetails()
	end)
end

local openPackButton =
	makeButton(packPanel, "OpenPackButton", "Open Pack", UDim2.fromOffset(200, 250), UDim2.fromOffset(150, 34))
openPackButton.BackgroundColor3 = COLORS.ButtonHot
openPackButton.MouseButton1Click:Connect(function()
	local result = openPack:InvokeServer(selectedPackId)
	if not result or not result.Success then
		packResultLabel.Text = result and result.Error or "Pack failed."
		return
	end

	local card = result.Card
	packResultLabel.Text = string.format(
		"Pulled: %s\n%s | %d OVR | %s\n%s",
		card.Name,
		card.Rarity,
		card.Overall,
		card.Position,
		card.Badge
	)
	refreshHud()
	refreshPackDetails()
end)

local inventoryPanel = makePanel("InventoryUI", "Inventory")
inventoryList = Instance.new("ScrollingFrame")
inventoryList.Name = "InventoryList"
inventoryList.BackgroundTransparency = 1
inventoryList.BorderSizePixel = 0
inventoryList.Position = UDim2.fromOffset(20, 58)
inventoryList.Size = UDim2.new(1, -40, 1, -82)
inventoryList.ScrollBarThickness = 5
inventoryList.CanvasSize = UDim2.fromOffset(0, 0)
inventoryList.Parent = inventoryPanel

local inventoryGrid = Instance.new("UIGridLayout")
inventoryGrid.CellPadding = UDim2.fromOffset(10, 10)
inventoryGrid.CellSize = UDim2.fromOffset(160, 76)
inventoryGrid.SortOrder = Enum.SortOrder.LayoutOrder
inventoryGrid.Parent = inventoryList
local inventoryEmptyLabel =
	makeLabel(inventoryPanel, "EmptyText", "No cards yet.", UDim2.fromOffset(20, 160), UDim2.new(1, -40, 0, 30), 14)
inventoryEmptyLabel.TextXAlignment = Enum.TextXAlignment.Center
inventoryEmptyLabel.Visible = false

local function refreshInventoryPanel()
	for _, child in ipairs(inventoryList:GetChildren()) do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end

	cards = getCards:InvokeServer() or {}
	if #cards == 0 then
		inventoryEmptyLabel.Visible = true
		inventoryList.CanvasSize = UDim2.fromOffset(0, 0)
		return
	end
	inventoryEmptyLabel.Visible = false

	for index, card in ipairs(cards) do
		local cardFrame =
			makeCard(inventoryList, "Card" .. tostring(index), UDim2.fromOffset(0, 0), UDim2.fromOffset(160, 76))
		cardFrame.LayoutOrder = index
		local label = makeLabel(
			cardFrame,
			"CardText",
			formatCardLine(card, ""),
			UDim2.fromOffset(8, 6),
			UDim2.new(1, -16, 1, -12),
			12
		)
		label.TextYAlignment = Enum.TextYAlignment.Center
	end

	local rows = math.ceil(#cards / 3)
	inventoryList.CanvasSize = UDim2.fromOffset(0, math.max(0, rows * 86))
end

local function getRewardText(rewardDay)
	local rewards = {}
	if rewardDay and rewardDay.Rewards then
		for _, reward in ipairs(rewardDay.Rewards) do
			table.insert(rewards, formatReward(reward))
		end
	end
	return table.concat(rewards, ", ")
end

local dailyPanel = makePanel("DailyRewardUI", "Daily Rewards")
dailyStatusLabel =
	makeLabel(dailyPanel, "Status", "Loading daily rewards...", UDim2.fromOffset(24, 70), UDim2.new(1, -48, 0, 130), 15)
dailyStatusLabel.TextYAlignment = Enum.TextYAlignment.Top
dailyResultLabel =
	makeLabel(dailyPanel, "Result", "No reward claimed yet.", UDim2.fromOffset(24, 262), UDim2.new(1, -48, 0, 60), 13)
dailyResultLabel.TextYAlignment = Enum.TextYAlignment.Top

local function refreshDailyStatus()
	dailyStatus = getDailyRewardStatus:InvokeServer() or {}
	local rewardText = getRewardText(dailyStatus.NextReward)
	dailyStatusLabel.Text = string.format(
		"Current Streak: %d\nCurrent Day: %d\nNext Reward: %s\nCan Claim: %s\nNext Claim In: %ds",
		dailyStatus.CurrentStreak or 0,
		dailyStatus.CurrentDay or 1,
		rewardText ~= "" and rewardText or "Unknown",
		tostring(dailyStatus.CanClaim == true),
		dailyStatus.SecondsUntilNextClaim or 0
	)
end

local claimButton =
	makeButton(dailyPanel, "ClaimButton", "Claim Daily Reward", UDim2.fromOffset(24, 212), UDim2.fromOffset(170, 34))
claimButton.BackgroundColor3 = COLORS.ButtonHot
claimButton.MouseButton1Click:Connect(function()
	local result = claimDailyReward:InvokeServer()
	if not result or not result.Success then
		dailyResultLabel.Text = result and result.Error or "Claim failed."
		refreshDailyStatus()
		return
	end

	local grantedText = {}
	for _, reward in ipairs(result.RewardsGranted) do
		table.insert(grantedText, formatReward(reward))
	end
	dailyResultLabel.Text = "Claimed: " .. table.concat(grantedText, ", ")
	refreshHud()
	refreshDailyStatus()
end)

local shopPanel = makePanel("ShopUI", "Shop")
local shopList = Instance.new("ScrollingFrame")
shopList.Name = "ShopList"
shopList.BackgroundTransparency = 1
shopList.BorderSizePixel = 0
shopList.Position = UDim2.fromOffset(20, 58)
shopList.Size = UDim2.new(1, -40, 1, -126)
shopList.ScrollBarThickness = 5
shopList.CanvasSize = UDim2.fromOffset(0, 0)
shopList.Parent = shopPanel

local shopLayout = Instance.new("UIListLayout")
shopLayout.Padding = UDim.new(0, 8)
shopLayout.SortOrder = Enum.SortOrder.LayoutOrder
shopLayout.Parent = shopList
shopResultLabel = makeLabel(
	shopPanel,
	"Result",
	"Select an item to purchase.",
	UDim2.new(0, 20, 1, -58),
	UDim2.new(1, -40, 0, 42),
	13
)
shopResultLabel.TextYAlignment = Enum.TextYAlignment.Top

local shopOrder = {
	"Coins2xBoost",
	"Luck2xBoost",
	"Rep2xBoost",
	"AutoOpenBoost",
	"ShieldBoost",
	"TrollPack",
	"StarterBundle",
	"VIP",
}

for index, itemId in ipairs(shopOrder) do
	local item = shopItems[itemId]
	if item then
		local row = makeCard(shopList, itemId .. "Row", UDim2.fromOffset(0, 0), UDim2.new(1, -8, 0, 58))
		row.LayoutOrder = index
		row.BackgroundTransparency = 0.28

		local costText = item.PurchaseType == "SoftCurrency"
				and (tostring(item.CostAmount) .. " " .. tostring(item.CostCurrency))
			or "Not implemented"
		local itemLabel = makeLabel(
			row,
			"ItemText",
			string.format("%s\n%s", item.DisplayName, costText),
			UDim2.fromOffset(12, 6),
			UDim2.new(1, -144, 1, -12),
			12
		)
		itemLabel.TextYAlignment = Enum.TextYAlignment.Center

		local buyButton = makeButton(
			row,
			"BuyButton",
			item.PurchaseType == "SoftCurrency" and "Buy" or "Soon",
			UDim2.new(1, -112, 0.5, -14),
			UDim2.fromOffset(92, 28)
		)
		if item.PurchaseType == "RobuxPlaceholder" then
			buyButton.BackgroundColor3 = Color3.fromRGB(62, 62, 66)
		end
		buyButton.MouseButton1Click:Connect(function()
			local result = purchaseShopItem:InvokeServer(itemId)
			if not result or not result.Success then
				shopResultLabel.Text = result and result.Error or "Purchase failed."
				return
			end

			local grantedText = {}
			for _, reward in ipairs(result.RewardsGranted) do
				table.insert(grantedText, formatReward(reward))
			end
			shopResultLabel.Text = "Purchased: " .. table.concat(grantedText, ", ")
			refreshHud()
		end)
	end
end
shopList.CanvasSize = UDim2.fromOffset(0, #shopOrder * 66)

local teamPanel = makePanel("TeamUI", "Team")
teamList = makeLabel(
	teamPanel,
	"TeamList",
	"Best cards will appear here.",
	UDim2.fromOffset(24, 70),
	UDim2.new(1, -48, 0, 220),
	14
)
teamList.TextYAlignment = Enum.TextYAlignment.Top

local function refreshTeamPanel()
	local bestCards = getBestCards(3)
	local lines = { "Current preview lineup" }
	for index = 1, 3 do
		table.insert(
			lines,
			tostring(index) .. ". " .. formatCardLine(bestCards[index], "Empty Slot " .. tostring(index))
		)
	end
	teamList.Text = table.concat(lines, "\n\n")
end

local practicePanel = makePanel("PracticeUI", "1v1 NPC")
local practiceText = makeLabel(
	practicePanel,
	"PracticeText",
	"Practice Match\n\nWalk to the 1v1 NPC station on the left side of the main entrance.\n\nUse the ProximityPrompt at the trainer to start a practice request.\n\nFull match simulation is not implemented yet.",
	UDim2.fromOffset(24, 72),
	UDim2.new(1, -48, 0, 220),
	15
)
practiceText.TextYAlignment = Enum.TextYAlignment.Top

for panelName, panel in pairs(panels) do
	panel:GetPropertyChangedSignal("Visible"):Connect(function()
		if not panel.Visible then
			return
		end

		if panelName == "PackUI" then
			refreshPackDetails()
		elseif panelName == "InventoryUI" then
			refreshInventoryPanel()
		elseif panelName == "DailyRewardUI" then
			refreshDailyStatus()
		elseif panelName == "TeamUI" then
			refreshHud()
			refreshTeamPanel()
		end
	end)
end

buildLocalProfileDisplay()
refreshHud()
refreshPackDetails()
refreshDailyStatus()
