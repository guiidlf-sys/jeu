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

	-- Barrières invisibles pour ne pas tomber du hall.
	for _, offset in ipairs({ Vector3.new(112, 0, 0), Vector3.new(-112, 0, 0), Vector3.new(0, 0, 112), Vector3.new(0, 0, -112) }) do
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

	return folder
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
