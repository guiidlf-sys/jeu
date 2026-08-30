--!strict
--[[
	WorldBuilder
	Génère le hall (lobby) et les arènes de faille par code, pour que la place
	Roblox puisse être totalement vide au départ.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared.GameConfig)

local WorldBuilder = {}

local function part(props: { [string]: any }): Part
	local instance = Instance.new("Part")
	instance.Anchored = true
	instance.TopSurface = Enum.SurfaceType.Smooth
	instance.BottomSurface = Enum.SurfaceType.Smooth
	for key, value in pairs(props) do
		(instance :: any)[key] = value
	end
	return instance
end

--- Construit le hall central et renvoie son dossier.
function WorldBuilder.buildLobby(): Folder
	local existing = workspace:FindFirstChild("Hall")
	if existing then
		return existing :: Folder
	end

	local folder = Instance.new("Folder")
	folder.Name = "Hall"
	folder.Parent = workspace

	local floor = part({
		Name = "Sol",
		Size = Vector3.new(220, 4, 220),
		Position = Vector3.new(0, 0, 0),
		Color = Color3.fromRGB(26, 26, 38),
		Material = Enum.Material.Slate,
	})
	floor.Parent = folder

	-- Cercle rituel au centre.
	local circle = part({
		Name = "Cercle",
		Size = Vector3.new(48, 0.4, 48),
		Position = Vector3.new(0, 2.1, 0),
		Color = GameConfig.Palette.accent,
		Material = Enum.Material.Neon,
		Shape = Enum.PartType.Cylinder,
		Transparency = 0.55,
		CanCollide = false,
	})
	circle.CFrame = CFrame.new(0, 2.1, 0) * CFrame.Angles(0, 0, math.rad(90))
	circle.Parent = folder

	local spawnLocation = Instance.new("SpawnLocation")
	spawnLocation.Name = "Départ"
	spawnLocation.Size = Vector3.new(14, 1, 14)
	spawnLocation.Position = Vector3.new(0, 2.5, 0)
	spawnLocation.Anchored = true
	spawnLocation.Transparency = 1
	spawnLocation.CanCollide = false
	spawnLocation.Neutral = true
	spawnLocation.Parent = folder

	-- Piliers d'ambiance autour du hall.
	for index = 0, 7 do
		local angle = (index / 8) * math.pi * 2
		local pillar = part({
			Name = "Pilier",
			Size = Vector3.new(7, 42, 7),
			Position = Vector3.new(math.cos(angle) * 88, 23, math.sin(angle) * 88),
			Color = Color3.fromRGB(18, 18, 28),
			Material = Enum.Material.Concrete,
		})
		pillar.Parent = folder

		local crown = part({
			Name = "Couronne",
			Size = Vector3.new(7.6, 1.4, 7.6),
			Position = pillar.Position + Vector3.new(0, 22, 0),
			Color = GameConfig.Palette.accentSoft,
			Material = Enum.Material.Neon,
			CanCollide = false,
		})
		crown.Parent = folder

		local light = Instance.new("PointLight")
		light.Color = GameConfig.Palette.accentSoft
		light.Range = 40
		light.Brightness = 2
		light.Parent = crown
	end

	-- Anneau de zone sûre : repère visuel de la limite protégée.
	local ring = part({
		Name = "AnneauZoneSure",
		Size = Vector3.new(GameConfig.SafeZoneRadius * 2, 0.2, GameConfig.SafeZoneRadius * 2),
		Position = Vector3.new(0, 2.05, 0),
		Color = GameConfig.Palette.success,
		Material = Enum.Material.Neon,
		Shape = Enum.PartType.Cylinder,
		Transparency = 0.92,
		CanCollide = false,
	})
	ring.CFrame = CFrame.new(0, 2.05, 0) * CFrame.Angles(0, 0, math.rad(90))
	ring.Parent = folder

	-- Barrières invisibles pour ne pas tomber du hall, avec une ouverture au
	-- nord (+Z) vers le pont du terrain d'entraînement.
	for _, offset in ipairs({ Vector3.new(112, 0, 0), Vector3.new(-112, 0, 0), Vector3.new(0, 0, -112) }) do
		local isX = math.abs(offset.X) > 0
		local wall = part({
			Name = "Barrière",
			Size = if isX then Vector3.new(4, 60, 224) else Vector3.new(224, 60, 4),
			Position = offset + Vector3.new(0, 30, 0),
			Transparency = 1,
			CanCollide = true,
		})
		wall.Parent = folder
	end

	for _, side in ipairs({ 1, -1 }) do
		local wall = part({
			Name = "Barrière",
			Size = Vector3.new(99, 60, 4),
			Position = Vector3.new(side * 62.5, 30, 112),
			Transparency = 1,
			CanCollide = true,
		})
		wall.Parent = folder
	end

	-- Pont vers le terrain d'entraînement.
	local bridge = part({
		Name = "Pont",
		Size = Vector3.new(26, 4, 60),
		Position = Vector3.new(0, 0, 140),
		Color = Color3.fromRGB(22, 22, 34),
		Material = Enum.Material.Slate,
	})
	bridge.Parent = folder

	for _, side in ipairs({ 1, -1 }) do
		local rail = part({
			Name = "Rambarde",
			Size = Vector3.new(1, 5, 60),
			Position = Vector3.new(side * 13, 4, 140),
			Color = GameConfig.Palette.accentSoft,
			Material = Enum.Material.Neon,
			Transparency = 0.5,
		})
		rail.Parent = folder
	end

	return folder
end

--- Terrain d'entraînement, hors de la zone sûre, relié au hall par le pont.
function WorldBuilder.buildTrainingField(center: Vector3, size: number): Folder
	local folder = Instance.new("Folder")
	folder.Name = "TerrainEntrainement"
	folder.Parent = workspace

	local floor = part({
		Name = "Sol",
		Size = Vector3.new(size, 4, size),
		Position = center,
		Color = Color3.fromRGB(20, 20, 30),
		Material = Enum.Material.Slate,
	})
	floor.Parent = folder

	local glow = part({
		Name = "Runes",
		Size = Vector3.new(size * 0.8, 0.3, size * 0.8),
		Position = center + Vector3.new(0, 2.2, 0),
		Color = GameConfig.Palette.danger,
		Material = Enum.Material.Neon,
		Transparency = 0.88,
		CanCollide = false,
	})
	glow.Parent = folder

	-- Murs sur trois côtés : l'accès se fait par le pont, au sud.
	local half = size / 2
	local sides = {
		{ offset = Vector3.new(half, 0, 0), size = Vector3.new(4, 60, size) },
		{ offset = Vector3.new(-half, 0, 0), size = Vector3.new(4, 60, size) },
		{ offset = Vector3.new(0, 0, half), size = Vector3.new(size, 60, 4) },
	}
	for _, side in ipairs(sides) do
		local wall = part({
			Name = "Barrière",
			Size = side.size,
			Position = center + side.offset + Vector3.new(0, 30, 0),
			Transparency = 1,
			CanCollide = true,
		})
		wall.Parent = folder
	end

	-- Côté sud : deux segments, en laissant passer le pont.
	for _, side in ipairs({ 1, -1 }) do
		local segment = (size - 26) / 2
		local wall = part({
			Name = "Barrière",
			Size = Vector3.new(segment, 60, 4),
			Position = center + Vector3.new(side * (13 + segment / 2), 30, -half),
			Transparency = 1,
			CanCollide = true,
		})
		wall.Parent = folder
	end

	local sign = part({
		Name = "Panneau",
		Size = Vector3.new(20, 1, 1),
		Position = center + Vector3.new(0, 14, -half + 2),
		Color = GameConfig.Palette.danger,
		Material = Enum.Material.Neon,
		CanCollide = false,
	})
	sign.Parent = folder

	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromScale(22, 5)
	gui.StudsOffsetWorldSpace = Vector3.new(0, 5, 0)
	gui.MaxDistance = 260
	gui.Adornee = sign
	gui.Parent = sign

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 0.6)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBlack
	label.TextScaled = true
	label.TextColor3 = GameConfig.Palette.danger
	label.TextStrokeTransparency = 0.3
	label.Text = "TERRAIN D'ENTRAÎNEMENT"
	label.Parent = gui

	local warning = Instance.new("TextLabel")
	warning.Size = UDim2.fromScale(1, 0.4)
	warning.Position = UDim2.fromScale(0, 0.6)
	warning.BackgroundTransparency = 1
	warning.Font = Enum.Font.Gotham
	warning.TextScaled = true
	warning.TextColor3 = GameConfig.Palette.textDim
	warning.Text = "Tu quittes la zone sûre — les esprits attaquent ici"
	warning.Parent = gui

	return folder
end

--- Île flottante du hub AFK.
function WorldBuilder.buildAfkHub(center: Vector3): (Folder, CFrame)
	local folder = Instance.new("Folder")
	folder.Name = "HubAFK"
	folder.Parent = workspace

	local floor = part({
		Name = "Sol",
		Size = Vector3.new(90, 4, 90),
		Position = center,
		Color = Color3.fromRGB(24, 22, 40),
		Material = Enum.Material.Slate,
	})
	floor.Parent = folder

	local glow = part({
		Name = "Halo",
		Size = Vector3.new(70, 0.4, 70),
		Position = center + Vector3.new(0, 2.2, 0),
		Color = GameConfig.Palette.accent,
		Material = Enum.Material.Neon,
		Transparency = 0.6,
		CanCollide = false,
	})
	glow.Parent = folder

	local light = Instance.new("PointLight")
	light.Color = GameConfig.Palette.accent
	light.Range = 60
	light.Brightness = 3
	light.Parent = glow

	for _, offset in ipairs({
		Vector3.new(45, 0, 0),
		Vector3.new(-45, 0, 0),
		Vector3.new(0, 0, 45),
		Vector3.new(0, 0, -45),
	}) do
		local isX = math.abs(offset.X) > 0
		local wall = part({
			Name = "Barrière",
			Size = if isX then Vector3.new(2, 40, 90) else Vector3.new(90, 40, 2),
			Position = center + offset + Vector3.new(0, 20, 0),
			Color = GameConfig.Palette.accent,
			Material = Enum.Material.ForceField,
			Transparency = 0.75,
		})
		wall.Parent = folder
	end

	for index = 0, 3 do
		local angle = (index / 4) * math.pi * 2 + math.pi / 4
		local pillar = part({
			Name = "Pilier",
			Size = Vector3.new(5, 26, 5),
			Position = center + Vector3.new(math.cos(angle) * 32, 15, math.sin(angle) * 32),
			Color = Color3.fromRGB(16, 16, 26),
			Material = Enum.Material.Concrete,
		})
		pillar.Parent = folder
	end

	return folder, CFrame.new(center + Vector3.new(0, 6, 0))
end

--- Personnage non joueur : une silhouette ancrée avec son dialogue.
function WorldBuilder.buildNpc(def: any, parent: Instance): (Model, ProximityPrompt)
	local model = Instance.new("Model")
	model.Name = "PNJ_" .. def.id

	local body = part({
		Name = "Corps",
		Size = Vector3.new(2.6, 4.4, 2.6),
		Position = def.position + Vector3.new(0, 2.2, 0),
		Color = def.color,
		Material = Enum.Material.Fabric,
	})
	body.Parent = model
	model.PrimaryPart = body

	local head = part({
		Name = "Tête",
		Size = Vector3.new(1.8, 1.8, 1.8),
		Position = def.position + Vector3.new(0, 5.4, 0),
		Color = def.glow,
		Material = Enum.Material.Neon,
		CanCollide = false,
	})
	head.Parent = model

	local halo = part({
		Name = "Halo",
		Size = Vector3.new(3.2, 0.25, 3.2),
		Position = def.position + Vector3.new(0, 7, 0),
		Color = def.glow,
		Material = Enum.Material.Neon,
		Shape = Enum.PartType.Cylinder,
		Transparency = 0.35,
		CanCollide = false,
	})
	halo.CFrame = CFrame.new(halo.Position) * CFrame.Angles(0, 0, math.rad(90))
	halo.Parent = model

	local light = Instance.new("PointLight")
	light.Color = def.glow
	light.Range = 20
	light.Brightness = 2
	light.Parent = head

	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromScale(11, 3.4)
	gui.StudsOffsetWorldSpace = Vector3.new(0, 9, 0)
	gui.MaxDistance = 160
	gui.Adornee = head
	gui.Parent = head

	local name = Instance.new("TextLabel")
	name.Size = UDim2.fromScale(1, 0.55)
	name.BackgroundTransparency = 1
	name.Font = Enum.Font.GothamBold
	name.TextScaled = true
	name.TextColor3 = def.glow
	name.TextStrokeTransparency = 0.35
	name.Text = def.name
	name.Parent = gui

	local role = Instance.new("TextLabel")
	role.Size = UDim2.fromScale(1, 0.45)
	role.Position = UDim2.fromScale(0, 0.55)
	role.BackgroundTransparency = 1
	role.Font = Enum.Font.Gotham
	role.TextScaled = true
	role.TextColor3 = GameConfig.Palette.textDim
	role.Text = def.role
	role.Parent = gui

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Parler"
	prompt.ObjectText = def.name
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.Parent = body

	model.Parent = parent
	return model, prompt
end

--- Construit une arène de faille à la position donnée.
function WorldBuilder.buildArena(name: string, center: Vector3, size: number, color: Color3): (Folder, CFrame)
	local folder = Instance.new("Folder")
	folder.Name = name

	local floor = part({
		Name = "Sol",
		Size = Vector3.new(size, 4, size),
		Position = center,
		Color = Color3.fromRGB(16, 14, 24),
		Material = Enum.Material.Slate,
	})
	floor.Parent = folder

	local glow = part({
		Name = "Runes",
		Size = Vector3.new(size * 0.7, 0.3, size * 0.7),
		Position = center + Vector3.new(0, 2.2, 0),
		Color = color,
		Material = Enum.Material.Neon,
		Transparency = 0.75,
		CanCollide = false,
	})
	glow.Parent = folder

	local half = size / 2
	for _, offset in ipairs({
		Vector3.new(half, 0, 0),
		Vector3.new(-half, 0, 0),
		Vector3.new(0, 0, half),
		Vector3.new(0, 0, -half),
	}) do
		local isX = math.abs(offset.X) > 0
		local wall = part({
			Name = "Mur",
			Size = if isX then Vector3.new(2, 80, size) else Vector3.new(size, 80, 2),
			Position = center + offset + Vector3.new(0, 40, 0),
			Color = color,
			Material = Enum.Material.ForceField,
			Transparency = 0.7,
		})
		wall.Parent = folder
	end

	local light = Instance.new("PointLight")
	light.Color = color
	light.Range = 60
	light.Brightness = 3
	light.Parent = glow

	return folder, CFrame.new(center + Vector3.new(0, 6, 0))
end

--- Crée un portail cliquable dans le hall.
function WorldBuilder.buildPortal(rift: any, position: Vector3, parent: Instance): (Model, ProximityPrompt)
	local model = Instance.new("Model")
	model.Name = "Portail_" .. rift.id

	local frame = part({
		Name = "Anneau",
		Size = Vector3.new(16, 22, 2),
		Position = position + Vector3.new(0, 11, 0),
		Color = Color3.fromRGB(16, 16, 24),
		Material = Enum.Material.Metal,
	})
	frame.Parent = model

	local portal = part({
		Name = "Voile",
		Size = Vector3.new(13, 19, 1),
		Position = position + Vector3.new(0, 11, 0),
		Color = rift.color,
		Material = Enum.Material.Neon,
		Transparency = 0.35,
		CanCollide = false,
	})
	portal.Parent = model
	model.PrimaryPart = portal

	local light = Instance.new("PointLight")
	light.Color = rift.color
	light.Range = 36
	light.Brightness = 3
	light.Parent = portal

	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromScale(12, 4)
	gui.StudsOffsetWorldSpace = Vector3.new(0, 14, 0)
	gui.MaxDistance = 220
	gui.Adornee = portal
	gui.Parent = portal

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0.55, 0)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBold
	title.TextScaled = true
	title.TextColor3 = rift.color
	title.TextStrokeTransparency = 0.3
	title.Text = ("FAILLE %s — %s"):format(rift.rank, rift.name)
	title.Parent = gui

	local subtitle = Instance.new("TextLabel")
	subtitle.Size = UDim2.new(1, 0, 0.4, 0)
	subtitle.Position = UDim2.new(0, 0, 0.58, 0)
	subtitle.BackgroundTransparency = 1
	subtitle.Font = Enum.Font.Gotham
	subtitle.TextScaled = true
	subtitle.TextColor3 = GameConfig.Palette.textDim
	subtitle.Text = ("Niveau %d requis"):format(rift.minLevel)
	subtitle.Parent = gui

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Entrer"
	prompt.ObjectText = ("Faille %s"):format(rift.rank)
	prompt.HoldDuration = 0.6
	prompt.MaxActivationDistance = 14
	prompt.RequiresLineOfSight = false
	prompt.Parent = portal

	model.Parent = parent
	return model, prompt
end

return WorldBuilder
