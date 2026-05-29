local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

local ArenaBuildService = {}

local MODEL_NAME = "ModernBasketballFacility"
local isInitialized = false

local COLORS = {
	Maple = Color3.fromRGB(198, 146, 82),
	MapleLight = Color3.fromRGB(219, 170, 103),
	MapleDark = Color3.fromRGB(172, 117, 65),
	Line = Color3.fromRGB(244, 244, 238),
	Graphite = Color3.fromRGB(92, 96, 101),
	Charcoal = Color3.fromRGB(58, 62, 67),
	Navy = Color3.fromRGB(32, 48, 72),
	OffWhite = Color3.fromRGB(242, 240, 232),
	Teal = Color3.fromRGB(35, 178, 190),
	Amber = Color3.fromRGB(248, 190, 72),
	Metal = Color3.fromRGB(154, 160, 166),
	Glass = Color3.fromRGB(205, 235, 242),
	Orange = Color3.fromRGB(219, 91, 25),
	Screen = Color3.fromRGB(12, 18, 24),
	Wall = Color3.fromRGB(190, 194, 198),
	WallTrim = Color3.fromRGB(235, 236, 232),
	Light = Color3.fromRGB(255, 251, 238),
}

local function makePart(parent, name, size, cframe, color, material)
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

local function makeTextPanel(parent, name, text, size, cframe, textColor, backgroundColor)
	local panel = makePart(parent, name, size, cframe, backgroundColor or COLORS.Screen, Enum.Material.SmoothPlastic)
	local gui = Instance.new("SurfaceGui")
	gui.Name = name .. "Gui"
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 55
	gui.Parent = panel

	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Enum.Font.GothamBold
	label.Text = text
	label.TextColor3 = textColor or COLORS.OffWhite
	label.TextScaled = true
	label.TextWrapped = true
	label.Parent = gui

	return panel
end

local function addSurfaceLight(parent, brightness, range, color)
	local light = Instance.new("SurfaceLight")
	light.Name = "DisplayLight"
	light.Brightness = brightness or 1.2
	light.Range = range or 18
	light.Color = color or COLORS.Light
	light.Face = Enum.NormalId.Front
	light.Shadows = false
	light.Parent = parent
	return light
end

local function makeLeaderboardPanel(parent, name, title, rows, cframe)
	local panel = makePart(parent, name, Vector3.new(28, 10, 0.28), cframe, COLORS.Screen, Enum.Material.SmoothPlastic)
	panel.Reflectance = 0.08

	local gui = Instance.new("SurfaceGui")
	gui.Name = name .. "Gui"
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 42
	gui.Parent = panel

	local titleLabel = Instance.new("TextLabel")
	titleLabel.BackgroundTransparency = 1
	titleLabel.Position = UDim2.fromScale(0.05, 0.05)
	titleLabel.Size = UDim2.fromScale(0.9, 0.18)
	titleLabel.Font = Enum.Font.GothamBlack
	titleLabel.Text = title
	titleLabel.TextColor3 = COLORS.Amber
	titleLabel.TextScaled = true
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.Parent = gui

	for index, rowText in ipairs(rows) do
		local row = Instance.new("TextLabel")
		row.BackgroundTransparency = index % 2 == 0 and 0.88 or 1
		row.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		row.Position = UDim2.fromScale(0.055, 0.25 + (index - 1) * 0.13)
		row.Size = UDim2.fromScale(0.89, 0.1)
		row.Font = Enum.Font.GothamBold
		row.Text = rowText
		row.TextColor3 = index == 1 and COLORS.Teal or COLORS.OffWhite
		row.TextScaled = true
		row.TextXAlignment = Enum.TextXAlignment.Left
		row.Parent = gui
	end

	return panel
end

local function makeLine(parent, centerX, centerZ, width, depth)
	makePart(parent, "CourtLine", Vector3.new(width, 0.1, depth), CFrame.new(centerX, 0.72, centerZ), COLORS.Line)
end

local function makeArc(parent, centerX, centerZ, radius, startAngle, endAngle, segments)
	for i = 1, segments do
		local t = startAngle + (endAngle - startAngle) * (i - 0.5) / segments
		local x = centerX + math.cos(t) * radius
		local z = centerZ + math.sin(t) * radius
		makePart(
			parent,
			"CourtArc",
			Vector3.new(1.25, 0.1, 0.22),
			CFrame.new(x, 0.74, z) * CFrame.Angles(0, -t, 0),
			COLORS.Line
		)
	end
end

local function makeHoop(parent, courtX, baselineZ, directionToCourt)
	local hoop = Instance.new("Model")
	hoop.Name = directionToCourt > 0 and "HomeHoop" or "AwayHoop"
	hoop.Parent = parent

	local baseZ = baselineZ - directionToCourt * 6.7
	local boardZ = baselineZ - directionToCourt * 1.85
	local rimZ = baselineZ + directionToCourt * 1.2
	local rimY = 10

	local support = Instance.new("Model")
	support.Name = "Support"
	support.Parent = hoop
	makePart(support, "FloorBase", Vector3.new(5.2, 0.8, 3.7), CFrame.new(courtX, 0.78, baseZ), COLORS.Charcoal)
	makePart(
		support,
		"BasePadding",
		Vector3.new(5.5, 1.05, 4),
		CFrame.new(courtX, 1.16, baseZ + directionToCourt * 0.12),
		COLORS.Navy
	)
	makePart(
		support,
		"Stanchion",
		Vector3.new(0.52, 9.1, 0.52),
		CFrame.new(courtX, 6.05, baseZ + directionToCourt * 1.05) * CFrame.Angles(math.rad(6) * directionToCourt, 0, 0),
		COLORS.Metal,
		Enum.Material.Metal
	)
	makePart(
		support,
		"UpperArm",
		Vector3.new(0.5, 0.5, 6.1),
		CFrame.new(courtX, 11.48, baseZ + directionToCourt * 3.85),
		COLORS.Metal,
		Enum.Material.Metal
	)
	makePart(
		support,
		"BackboardMount",
		Vector3.new(3.4, 0.38, 0.38),
		CFrame.new(courtX, 11.45, boardZ - directionToCourt * 0.45),
		COLORS.Metal,
		Enum.Material.Metal
	)

	local backboardModel = Instance.new("Model")
	backboardModel.Name = "Backboard"
	backboardModel.Parent = hoop
	local backboard = makePart(
		backboardModel,
		"GlassPanel",
		Vector3.new(8.8, 5.1, 0.16),
		CFrame.new(courtX, 11.75, boardZ),
		COLORS.Glass,
		Enum.Material.Glass
	)
	backboard.Transparency = 0.58
	backboard.Reflectance = 0.04
	makePart(
		backboardModel,
		"TopFrame",
		Vector3.new(9.2, 0.14, 0.16),
		CFrame.new(courtX, 14.38, boardZ + directionToCourt * 0.12),
		COLORS.OffWhite
	)
	makePart(
		backboardModel,
		"BottomFrame",
		Vector3.new(9.2, 0.14, 0.16),
		CFrame.new(courtX, 9.12, boardZ + directionToCourt * 0.12),
		COLORS.OffWhite
	)
	makePart(
		backboardModel,
		"LeftFrame",
		Vector3.new(0.14, 5.3, 0.16),
		CFrame.new(courtX - 4.6, 11.75, boardZ + directionToCourt * 0.12),
		COLORS.OffWhite
	)
	makePart(
		backboardModel,
		"RightFrame",
		Vector3.new(0.14, 5.3, 0.16),
		CFrame.new(courtX + 4.6, 11.75, boardZ + directionToCourt * 0.12),
		COLORS.OffWhite
	)

	local targetBox = Instance.new("Model")
	targetBox.Name = "TargetBox"
	targetBox.Parent = hoop
	makePart(
		targetBox,
		"TopLine",
		Vector3.new(3.25, 0.08, 0.12),
		CFrame.new(courtX, 12.78, boardZ + directionToCourt * 0.24),
		COLORS.OffWhite
	)
	makePart(
		targetBox,
		"BottomLine",
		Vector3.new(3.25, 0.08, 0.12),
		CFrame.new(courtX, 10.98, boardZ + directionToCourt * 0.24),
		COLORS.OffWhite
	)
	makePart(
		targetBox,
		"LeftLine",
		Vector3.new(0.08, 1.8, 0.12),
		CFrame.new(courtX - 1.62, 11.88, boardZ + directionToCourt * 0.24),
		COLORS.OffWhite
	)
	makePart(
		targetBox,
		"RightLine",
		Vector3.new(0.08, 1.8, 0.12),
		CFrame.new(courtX + 1.62, 11.88, boardZ + directionToCourt * 0.24),
		COLORS.OffWhite
	)

	local rim = Instance.new("Model")
	rim.Name = "Rim"
	rim.Parent = hoop
	for i = 1, 24 do
		local angle = (i - 1) / 24 * math.pi * 2
		local x = courtX + math.cos(angle) * 1.6
		local z = rimZ + math.sin(angle) * 1.6
		makePart(
			rim,
			"RimSegment",
			Vector3.new(0.48, 0.11, 0.11),
			CFrame.new(x, rimY, z) * CFrame.Angles(0, -angle, 0),
			COLORS.Orange,
			Enum.Material.Metal
		)
	end
	makePart(
		rim,
		"RimConnector",
		Vector3.new(0.28, 0.12, 1.05),
		CFrame.new(courtX, rimY, rimZ - directionToCourt * 1.25),
		COLORS.Orange,
		Enum.Material.Metal
	)

	local net = Instance.new("Model")
	net.Name = "Net"
	net.Parent = hoop
	for i = 1, 12 do
		local angle = (i - 1) / 12 * math.pi * 2
		local topX = courtX + math.cos(angle) * 1.9
		local topZ = rimZ + math.sin(angle) * 1.05
		local bottomX = courtX + math.cos(angle) * 1.25
		local bottomZ = rimZ + math.sin(angle) * 0.7
		local cord = makePart(
			net,
			"VerticalCord",
			Vector3.new(0.045, 2.15, 0.045),
			CFrame.new((topX + bottomX) / 2, rimY - 1.12, (topZ + bottomZ) / 2),
			COLORS.OffWhite
		)
		cord.Transparency = 0.12
	end
	for i = 1, 8 do
		local angle = (i - 1) / 8 * math.pi * 2
		local x = courtX + math.cos(angle) * 1.08
		local z = rimZ + math.sin(angle) * 1.08
		local braid = makePart(
			net,
			"NetBraid",
			Vector3.new(0.04, 0.95, 0.04),
			CFrame.new(x, rimY - 1.45, z) * CFrame.Angles(math.rad(22), 0, math.rad(18)),
			COLORS.OffWhite
		)
		braid.Transparency = 0.18
	end
end

local function makeCourt(parent, name, centerX, label)
	local court = Instance.new("Model")
	court.Name = name
	court.Parent = parent

	makePart(
		court,
		"MapleCourtFloor",
		Vector3.new(58, 0.55, 100),
		CFrame.new(centerX, 0.25, 0),
		COLORS.Maple,
		Enum.Material.WoodPlanks
	)
	for i = -5, 5 do
		local stripeColor = i % 2 == 0 and COLORS.MapleLight or COLORS.MapleDark
		local stripe = makePart(
			court,
			"WoodGrainStripe",
			Vector3.new(4.6, 0.04, 98),
			CFrame.new(centerX + i * 4.7, 0.57, 0),
			stripeColor,
			Enum.Material.WoodPlanks
		)
		stripe.Transparency = 0.32
	end

	makeLine(court, centerX - 25, 0, 0.28, 94)
	makeLine(court, centerX + 25, 0, 0.28, 94)
	makeLine(court, centerX, 47, 50, 0.28)
	makeLine(court, centerX, -47, 50, 0.28)
	makeLine(court, centerX, 0, 50, 0.22)
	makeArc(court, centerX, 0, 6.2, 0, math.pi * 2, 48)

	for _, side in ipairs({ -1, 1 }) do
		local baselineZ = side * 47
		local laneCenterZ = side * 36.4
		local freeThrowZ = side * 28
		local paint = makePart(
			court,
			"SubtlePaintArea",
			Vector3.new(16, 0.05, 18.5),
			CFrame.new(centerX, 0.76, laneCenterZ),
			COLORS.Graphite
		)
		paint.Transparency = 0.22
		makeLine(court, centerX - 8, laneCenterZ, 0.22, 18.5)
		makeLine(court, centerX + 8, laneCenterZ, 0.22, 18.5)
		makeLine(court, centerX, freeThrowZ, 16, 0.22)
		makeLine(court, centerX, side * 45.3, 16, 0.22)
		makeArc(
			court,
			centerX,
			baselineZ,
			23.5,
			side > 0 and math.rad(210) or math.rad(30),
			side > 0 and math.rad(330) or math.rad(150),
			44
		)
		makeArc(
			court,
			centerX,
			freeThrowZ,
			8,
			side > 0 and math.rad(180) or 0,
			side > 0 and math.rad(360) or math.rad(180),
			24
		)
		makeHoop(court, centerX, baselineZ, -side)
	end

	local labelPanel = makeTextPanel(
		court,
		"CourtLabel",
		label,
		Vector3.new(9, 0.08, 2.2),
		CFrame.new(centerX, 0.85, -3) * CFrame.Angles(math.rad(-90), 0, 0),
		COLORS.Teal,
		COLORS.Maple
	)
	labelPanel.Transparency = 1
end

local function makeSpawn(parent, name, position, lookAt)
	local marker = makePart(
		parent,
		name .. "FloorMarker",
		Vector3.new(4.5, 0.06, 4.5),
		CFrame.new(position.X, 0.78, position.Z),
		COLORS.Amber
	)
	marker.Transparency = 0.82
	marker.CanCollide = false

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = name
	spawn.Anchored = true
	spawn.Size = Vector3.new(4, 0.4, 4)
	spawn.CFrame = CFrame.lookAt(position, lookAt)
	spawn.Color = COLORS.Teal
	spawn.Material = Enum.Material.SmoothPlastic
	spawn.Transparency = 1
	spawn.CanCollide = false
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Parent = parent
end

local function makeFeaturedPacksStore(parent)
	local store = Instance.new("Model")
	store.Name = "FeaturedPacksStore"
	store.Parent = parent

	makePart(
		store,
		"StoreFloor",
		Vector3.new(42, 0.12, 28),
		CFrame.new(56, 0.66, -58),
		Color3.fromRGB(235, 231, 218),
		Enum.Material.SmoothPlastic
	)
	makePart(
		store,
		"GoldFloorTrim",
		Vector3.new(42.5, 0.08, 1.2),
		CFrame.new(56, 0.76, -72.4),
		COLORS.Amber,
		Enum.Material.SmoothPlastic
	)
	makePart(
		store,
		"StoreCounter",
		Vector3.new(28, 3.4, 3.8),
		CFrame.new(56, 2.4, -68.5),
		COLORS.OffWhite,
		Enum.Material.SmoothPlastic
	)
	makePart(
		store,
		"CounterTop",
		Vector3.new(29, 0.35, 4.3),
		CFrame.new(56, 4.25, -68.5),
		COLORS.Navy,
		Enum.Material.SmoothPlastic
	)

	local wall = makePart(
		store,
		"FeaturedDisplayWall",
		Vector3.new(34, 13, 0.35),
		CFrame.new(56, 8.4, -73.8),
		COLORS.Screen,
		Enum.Material.SmoothPlastic
	)
	wall.Reflectance = 0.08
	addSurfaceLight(wall, 1.25, 22, Color3.fromRGB(255, 238, 190))
	makeTextPanel(
		store,
		"FeaturedPacksSign",
		"FEATURED PACKS\nLIMITED DROPS",
		Vector3.new(24, 5.2, 0.25),
		CFrame.new(56, 10.4, -73.55),
		COLORS.Amber,
		COLORS.Screen
	)

	for index, xOffset in ipairs({ -10, 0, 10 }) do
		local case = makePart(
			store,
			"PackGlassCase" .. index,
			Vector3.new(6, 4.2, 4.2),
			CFrame.new(56 + xOffset, 3.1, -61.8),
			COLORS.Glass,
			Enum.Material.Glass
		)
		case.Transparency = 0.42
		case.Reflectance = 0.08
		makePart(
			store,
			"PackPedestal" .. index,
			Vector3.new(5.4, 1.15, 3.6),
			CFrame.new(56 + xOffset, 1.35, -61.8),
			COLORS.Navy,
			Enum.Material.SmoothPlastic
		)
		makePart(
			store,
			"PackCard" .. index,
			Vector3.new(2.7, 3.7, 0.22),
			CFrame.new(56 + xOffset, 3.25, -61.2),
			index == 2 and COLORS.Amber or COLORS.Teal,
			Enum.Material.SmoothPlastic
		)
	end

	makeTextPanel(
		store,
		"RobuxShopPanel",
		"SHOP\nBOOSTS + PACKS",
		Vector3.new(10, 4.5, 0.25),
		CFrame.new(75.6, 5.6, -58) * CFrame.Angles(0, math.rad(-90), 0),
		COLORS.OffWhite,
		COLORS.Screen
	)
end

local function makeOneVsOneStation(parent)
	local station = Instance.new("Model")
	station.Name = "OneVsOneNPCStation"
	station.Parent = parent

	makePart(
		station,
		"PracticeFloor",
		Vector3.new(32, 0.12, 24),
		CFrame.new(-55, 0.66, -58),
		Color3.fromRGB(236, 232, 220),
		Enum.Material.SmoothPlastic
	)
	makePart(
		station,
		"PracticeArc",
		Vector3.new(22, 0.08, 1.2),
		CFrame.new(-55, 0.78, -67.4),
		COLORS.Orange,
		Enum.Material.SmoothPlastic
	)
	makeTextPanel(
		station,
		"PracticeSign",
		"1v1 NPC\nPRACTICE MATCH",
		Vector3.new(18, 4.2, 0.3),
		CFrame.new(-55, 8.3, -70.8),
		COLORS.Amber,
		COLORS.Screen
	)

	local npc = Instance.new("Model")
	npc.Name = "PracticeNPC"
	npc.Parent = station
	local root = makePart(
		npc,
		"HumanoidRootPart",
		Vector3.new(2, 2.2, 1),
		CFrame.new(-55, 3, -61),
		COLORS.Navy,
		Enum.Material.SmoothPlastic
	)
	root.Transparency = 1
	makePart(
		npc,
		"Body",
		Vector3.new(2.6, 3.6, 1.2),
		CFrame.new(-55, 3.4, -61),
		Color3.fromRGB(245, 245, 240),
		Enum.Material.SmoothPlastic
	)
	makePart(
		npc,
		"Head",
		Vector3.new(1.7, 1.7, 1.7),
		CFrame.new(-55, 6.1, -61),
		Color3.fromRGB(205, 154, 110),
		Enum.Material.SmoothPlastic
	)
	makePart(
		npc,
		"LeftArm",
		Vector3.new(0.7, 3, 0.8),
		CFrame.new(-56.75, 3.55, -61),
		COLORS.Navy,
		Enum.Material.SmoothPlastic
	)
	makePart(
		npc,
		"RightArm",
		Vector3.new(0.7, 3, 0.8),
		CFrame.new(-53.25, 3.55, -61),
		COLORS.Navy,
		Enum.Material.SmoothPlastic
	)
	makePart(
		npc,
		"LeftLeg",
		Vector3.new(0.8, 2.5, 0.8),
		CFrame.new(-55.55, 1.25, -61),
		Color3.fromRGB(35, 35, 38),
		Enum.Material.SmoothPlastic
	)
	makePart(
		npc,
		"RightLeg",
		Vector3.new(0.8, 2.5, 0.8),
		CFrame.new(-54.45, 1.25, -61),
		Color3.fromRGB(35, 35, 38),
		Enum.Material.SmoothPlastic
	)
	local ball = makePart(
		npc,
		"Basketball",
		Vector3.new(1.25, 1.25, 1.25),
		CFrame.new(-53, 4.1, -60.4),
		COLORS.Orange,
		Enum.Material.SmoothPlastic
	)
	ball.Shape = Enum.PartType.Ball

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "PracticeMatchPrompt"
	prompt.ActionText = "Start Practice"
	prompt.ObjectText = "1v1 NPC"
	prompt.HoldDuration = 0.15
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.Parent = root
	prompt.Triggered:Connect(function(player)
		player:SetAttribute("PracticeMatchRequested", true)
		local character = player.Character
		if character then
			character:PivotTo(CFrame.lookAt(Vector3.new(-42, 2.6, -18), Vector3.new(-42, 2.6, 0)))
		end
		print(
			"[ArenaBuildService] "
				.. player.Name
				.. " started a 1v1 NPC practice request. Full match flow is not implemented yet."
		)
	end)
end

local function buildFacility()
	local existing = Workspace:FindFirstChild(MODEL_NAME)
	if existing then
		existing:Destroy()
	end

	local model = Instance.new("Model")
	model.Name = MODEL_NAME
	model.Parent = Workspace

	Lighting.Brightness = 2.65
	Lighting.ExposureCompensation = 0.05
	Lighting.Ambient = Color3.fromRGB(178, 184, 190)
	Lighting.OutdoorAmbient = Color3.fromRGB(150, 154, 160)
	Lighting.GlobalShadows = true
	Lighting.EnvironmentDiffuseScale = 0.55
	Lighting.EnvironmentSpecularScale = 0.45
	Lighting.ClockTime = 13

	for _, child in ipairs(Lighting:GetChildren()) do
		if child.Name == "ArenaBloom" or child.Name == "ArenaColorCorrection" then
			child:Destroy()
		end
	end

	local bloom = Instance.new("BloomEffect")
	bloom.Name = "ArenaBloom"
	bloom.Intensity = 0.16
	bloom.Size = 18
	bloom.Threshold = 1.35
	bloom.Parent = Lighting

	local colorCorrection = Instance.new("ColorCorrectionEffect")
	colorCorrection.Name = "ArenaColorCorrection"
	colorCorrection.Brightness = 0.03
	colorCorrection.Contrast = 0.08
	colorCorrection.Saturation = 0.08
	colorCorrection.TintColor = Color3.fromRGB(255, 250, 240)
	colorCorrection.Parent = Lighting

	makePart(
		model,
		"MainFloor",
		Vector3.new(218, 0.5, 178),
		CFrame.new(0, -0.05, 0),
		Color3.fromRGB(142, 145, 145),
		Enum.Material.Concrete
	)
	makePart(model, "CenterWalkway", Vector3.new(22, 0.08, 130), CFrame.new(0, 0.58, 0), Color3.fromRGB(218, 218, 210))
	makePart(model, "ArrivalRunway", Vector3.new(48, 0.09, 48), CFrame.new(0, 0.6, -64), Color3.fromRGB(230, 226, 215))

	makeCourt(model, "Court1", -42, "COURT 1")
	makeCourt(model, "Court2", 42, "COURT 2")

	makePart(model, "SouthWall", Vector3.new(220, 38, 2), CFrame.new(0, 19, -88), COLORS.Wall, Enum.Material.Concrete)
	makePart(model, "NorthWall", Vector3.new(220, 38, 2), CFrame.new(0, 19, 88), COLORS.Wall, Enum.Material.Concrete)
	makePart(model, "WestWall", Vector3.new(2, 38, 180), CFrame.new(-110, 19, 0), COLORS.Wall, Enum.Material.Concrete)
	makePart(model, "EastWall", Vector3.new(2, 38, 180), CFrame.new(110, 19, 0), COLORS.Wall, Enum.Material.Concrete)
	makePart(
		model,
		"HighRoof",
		Vector3.new(222, 2, 182),
		CFrame.new(0, 39, 0),
		Color3.fromRGB(222, 224, 226),
		Enum.Material.Metal
	)
	makePart(
		model,
		"NorthWallTrim",
		Vector3.new(218, 2, 0.4),
		CFrame.new(0, 9, 86.8),
		COLORS.WallTrim,
		Enum.Material.SmoothPlastic
	)
	makePart(
		model,
		"SouthWallTrim",
		Vector3.new(218, 2, 0.4),
		CFrame.new(0, 9, -86.8),
		COLORS.WallTrim,
		Enum.Material.SmoothPlastic
	)
	makePart(
		model,
		"NavyUpperBandNorth",
		Vector3.new(218, 4, 0.35),
		CFrame.new(0, 28, 86.7),
		COLORS.Navy,
		Enum.Material.SmoothPlastic
	)
	makePart(
		model,
		"NavyUpperBandSouth",
		Vector3.new(218, 4, 0.35),
		CFrame.new(0, 28, -86.7),
		COLORS.Navy,
		Enum.Material.SmoothPlastic
	)

	makeTextPanel(
		model,
		"FacilityHeader",
		"INDOOR HOOPS CENTER",
		Vector3.new(30, 3, 0.4),
		CFrame.new(0, 24, -89.5),
		COLORS.OffWhite,
		COLORS.Screen
	)
	makeFeaturedPacksStore(model)
	makeOneVsOneStation(model)
	makeTextPanel(
		model,
		"ShopSign",
		"PRO SHOP",
		Vector3.new(18, 3, 0.35),
		CFrame.new(91, 7.9, -22.15),
		COLORS.Amber,
		COLORS.Screen
	)
	makeLeaderboardPanel(
		model,
		"TopDonorsBoard",
		"TOP DONORS",
		{ "#  NAME        VALUE", "1  OPEN SLOT   0", "2  OPEN SLOT   0", "3  OPEN SLOT   0", "4  OPEN SLOT   0" },
		CFrame.new(-54, 16, 86.5) * CFrame.Angles(0, math.rad(180), 0)
	)
	makeLeaderboardPanel(model, "ChampionsBoard", "CHAMPIONS / MYTHIC", {
		"#  NAME        PULL",
		"1  OPEN SLOT   NONE",
		"2  OPEN SLOT   NONE",
		"3  OPEN SLOT   NONE",
		"4  OPEN SLOT   NONE",
	}, CFrame.new(0, 16, 86.5) * CFrame.Angles(0, math.rad(180), 0))
	makeLeaderboardPanel(
		model,
		"TopOverallBoard",
		"TOP OVERALL",
		{ "#  NAME        OVR", "1  OPEN SLOT   000", "2  OPEN SLOT   000", "3  OPEN SLOT   000", "4  OPEN SLOT   000" },
		CFrame.new(54, 16, 86.5) * CFrame.Angles(0, math.rad(180), 0)
	)
	makeLeaderboardPanel(
		model,
		"TopRecordBoard",
		"TOP RECORD",
		{ "#  NAME        W-L", "1  OPEN SLOT   0-0", "2  OPEN SLOT   0-0", "3  OPEN SLOT   0-0", "4  OPEN SLOT   0-0" },
		CFrame.new(-109.25, 16, -36) * CFrame.Angles(0, math.rad(90), 0)
	)

	local jumbo = Instance.new("Model")
	jumbo.Name = "CentralJumbotron"
	jumbo.Parent = model
	makePart(jumbo, "JumbotronCore", Vector3.new(30, 12, 18), CFrame.new(0, 27, 6), COLORS.Navy, Enum.Material.Metal)
	makeTextPanel(
		jumbo,
		"JumboSouthScreen",
		"FEATURED PACKS\nOPEN NOW",
		Vector3.new(25, 8, 0.45),
		CFrame.new(0, 27, -3.35),
		COLORS.Amber,
		COLORS.Screen
	)
	makeTextPanel(
		jumbo,
		"JumboNorthScreen",
		"PLAY OF THE GAME\nCOMING SOON",
		Vector3.new(25, 8, 0.45),
		CFrame.new(0, 27, 15.35) * CFrame.Angles(0, math.rad(180), 0),
		COLORS.OffWhite,
		COLORS.Screen
	)

	for x = -78, 78, 26 do
		for z = -48, 48, 24 do
			local fixture = makePart(
				model,
				"LinearLightFixture",
				Vector3.new(12, 0.18, 2.2),
				CFrame.new(x, 36.6, z),
				COLORS.Light,
				Enum.Material.SmoothPlastic
			)
			fixture.Transparency = 0.06
			local light = Instance.new("SurfaceLight")
			light.Name = "CleanArenaLight"
			light.Brightness = 3.2
			light.Range = 52
			light.Color = Color3.fromRGB(244, 244, 232)
			light.Shadows = true
			light.Face = Enum.NormalId.Bottom
			light.Parent = fixture
		end
	end

	for index, x in ipairs({ -8, 0, 8 }) do
		makeSpawn(model, "EntrySpawn" .. index, Vector3.new(x, 1.1, -78), Vector3.new(0, 1.1, 0))
	end
end

function ArenaBuildService.Init()
	if isInitialized then
		return
	end

	isInitialized = true
	buildFacility()
	print("[ArenaBuildService] Modern basketball facility built.")
end

return ArenaBuildService
