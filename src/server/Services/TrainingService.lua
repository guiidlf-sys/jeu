--!strict
--[[
	TrainingService
	Zone d'entraînement du hall : des esprits de bas rang y réapparaissent en
	continu pour que le joueur ait toujours de quoi farmer sans faille.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared.GameConfig)

local MobService = require(script.Parent.MobService)

local ZONE_CENTER = Vector3.new(0, 3, 80)
local ZONE_RADIUS = 34
local MAX_MOBS = 8
local RESPAWN_INTERVAL = 4

local TrainingService = {}

local zoneFolder: Folder

local function buildZone()
	zoneFolder = Instance.new("Folder")
	zoneFolder.Name = "Entrainement"
	zoneFolder.Parent = workspace

	local pad = Instance.new("Part")
	pad.Name = "Terrain"
	pad.Anchored = true
	pad.CanCollide = false
	pad.Size = Vector3.new(ZONE_RADIUS * 2, 0.4, ZONE_RADIUS * 2)
	pad.Position = ZONE_CENTER - Vector3.new(0, 0.8, 0)
	pad.Material = Enum.Material.Neon
	pad.Color = GameConfig.Palette.accentSoft
	pad.Transparency = 0.85
	pad.Parent = zoneFolder

	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromScale(16, 3)
	gui.StudsOffsetWorldSpace = Vector3.new(0, 12, 0)
	gui.MaxDistance = 200
	gui.Adornee = pad
	gui.Parent = pad

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.TextColor3 = GameConfig.Palette.accentSoft
	label.TextStrokeTransparency = 0.35
	label.Text = "ZONE D'ENTRAÎNEMENT"
	label.Parent = gui
end

local function randomPosition(): Vector3
	local angle = math.random() * math.pi * 2
	local distance = ZONE_RADIUS * (0.2 + math.random() * 0.75)
	return ZONE_CENTER + Vector3.new(math.cos(angle) * distance, 1, math.sin(angle) * distance)
end

function TrainingService.init()
	buildZone()

	task.spawn(function()
		while true do
			local alive = MobService.countIn(zoneFolder)
			if alive < MAX_MOBS then
				local mobId = if math.random() < 0.75 then "larve" else "rampant"
				MobService.spawn(mobId, randomPosition(), zoneFolder, nil)
			end
			task.wait(RESPAWN_INTERVAL)
		end
	end)
end

return TrainingService
