--!strict
--[[
	TrainingService
	Terrain d'entraînement, au nord du hall et hors de la zone sûre : des
	esprits de bas rang y réapparaissent en continu pour que le joueur ait
	toujours de quoi progresser sans entrer en faille.
]]

local MobService = require(script.Parent.MobService)
local WorldBuilder = require(script.Parent.WorldBuilder)

local FIELD_CENTER = Vector3.new(0, 0, 230)
local FIELD_SIZE = 150
local ZONE_CENTER = FIELD_CENTER + Vector3.new(0, 3, 0)
local ZONE_RADIUS = 58
local MAX_MOBS = 10
local RESPAWN_INTERVAL = 3.5

local TrainingService = {}

local zoneFolder: Folder

local function buildZone()
	zoneFolder = WorldBuilder.buildTrainingField(FIELD_CENTER, FIELD_SIZE)
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
