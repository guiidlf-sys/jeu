--!strict
--[[
	RiftService
	Les failles : donjons à vagues, instanciés par joueur dans une arène créée
	à la volée très loin du hall.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local RiftCatalog = require(Shared.RiftCatalog)
local Remotes = require(Shared.Remotes)

local DataService = require(script.Parent.DataService)
local MobService = require(script.Parent.MobService)
local ProgressionService = require(script.Parent.ProgressionService)
local QuestService = require(script.Parent.QuestService)
local StatsService = require(script.Parent.StatsService)
local WorldBuilder = require(script.Parent.WorldBuilder)

local ARENA_ORIGIN = Vector3.new(20000, 800, 0)
local ARENA_SPACING = 1200
local WAVE_PAUSE = 3
local EXIT_DELAY = 4
local MAX_WAVE_DURATION = 300

local RiftService = {}

type Session = {
	player: Player,
	rift: any,
	folder: Folder,
	spawnCFrame: CFrame,
	slot: number,
	wave: number,
	active: boolean,
}

local sessions: { [Player]: Session } = {}
local usedSlots: { [number]: boolean } = {}

local riftsFolder = Instance.new("Folder")
riftsFolder.Name = "Failles"
riftsFolder.Parent = workspace

local function allocateSlot(): number
	local slot = 1
	while usedSlots[slot] do
		slot += 1
	end
	usedSlots[slot] = true
	return slot
end

local function pushState(player: Player, state: any)
	Remotes.event("RiftStateChanged"):FireClient(player, state)
end

local function teleportToLobby(player: Player)
	local character = player.Character
	if not character or not character.PrimaryPart then
		return
	end
	local hall = workspace:FindFirstChild("Hall")
	local spawnPart = hall and hall:FindFirstChild("Départ")
	local target = if spawnPart and spawnPart:IsA("BasePart")
		then spawnPart.CFrame + Vector3.new(0, 5, 0)
		else CFrame.new(0, 8, 0)
	character:PivotTo(target)
end

local function cleanup(session: Session, returnToLobby: boolean)
	if not session.active then
		return
	end
	session.active = false
	sessions[session.player] = nil
	usedSlots[session.slot] = nil

	MobService.clearAll(session.folder)
	session.folder:Destroy()

	if returnToLobby and session.player.Parent then
		teleportToLobby(session.player)
		pushState(session.player, { inRift = false })
	end
end

local function randomSpawnPosition(center: Vector3, size: number): Vector3
	local radius = size * 0.35
	local angle = math.random() * math.pi * 2
	local distance = radius * (0.4 + math.random() * 0.6)
	return center + Vector3.new(math.cos(angle) * distance, 4, math.sin(angle) * distance)
end

local function playerIsAlive(player: Player): boolean
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	return humanoid ~= nil and humanoid.Health > 0
end

local function runRift(session: Session)
	local rift = session.rift
	local center = session.spawnCFrame.Position - Vector3.new(0, 6, 0)

	for waveIndex, wave in ipairs(rift.waves) do
		if not session.active then
			return
		end

		session.wave = waveIndex
		pushState(session.player, {
			inRift = true,
			riftId = rift.id,
			riftName = rift.name,
			rank = rift.rank,
			wave = waveIndex,
			totalWaves = #rift.waves,
			remaining = 0,
		})

		for _, entry in ipairs(wave.mobs) do
			for _ = 1, entry.count do
				if not session.active then
					return
				end
				-- En faille, tout est hostile d'office : c'est le principe.
				MobService.spawn(
					entry.id,
					randomSpawnPosition(center, rift.arenaSize),
					session.folder,
					session.player,
					{ hostile = true }
				)
				task.wait(0.15)
			end
		end

		local deadline = os.clock() + MAX_WAVE_DURATION
		while session.active and os.clock() < deadline do
			local remaining = MobService.countIn(session.folder)
			pushState(session.player, {
				inRift = true,
				riftId = rift.id,
				riftName = rift.name,
				rank = rift.rank,
				wave = waveIndex,
				totalWaves = #rift.waves,
				remaining = remaining,
			})

			if remaining <= 0 then
				break
			end

			if not playerIsAlive(session.player) then
				ProgressionService.notify(
					session.player,
					"ÉCHEC",
					("Tu es tombé dans « %s ». La faille se referme."):format(rift.name),
					"danger"
				)
				task.wait(2)
				cleanup(session, true)
				return
			end

			task.wait(0.5)
		end

		if not session.active then
			return
		end

		if waveIndex < #rift.waves then
			ProgressionService.notify(
				session.player,
				"VAGUE " .. waveIndex .. " NETTOYÉE",
				("Prépare-toi : vague %d sur %d dans %d secondes.")
					:format(waveIndex + 1, #rift.waves, WAVE_PAUSE),
				"info"
			)
			task.wait(WAVE_PAUSE)
		end
	end

	if not session.active then
		return
	end

	-- Faille nettoyée.
	local player = session.player
	local profile = DataService.get(player)
	if profile then
		profile.totals.riftsCleared += 1
		-- Conserve le meilleur rang atteint, dans l'ordre E < D < C < B < S.
		local order = { E = 1, D = 2, C = 3, B = 4, S = 5 }
		if (order[rift.rank] or 0) > (order[profile.bestRiftRank] or 0) then
			profile.bestRiftRank = rift.rank
		end
	end

	ProgressionService.grantRewards(player, rift.rewards)
	QuestService.addProgress(player, "riftsCleared", 1)
	ProgressionService.notify(
		player,
		"FAILLE NETTOYÉE",
		("%s (rang %s) : +%d yens, +%d fragments, +%d XP.")
			:format(rift.name, rift.rank, rift.rewards.yens, rift.rewards.fragments, rift.rewards.xp),
		"success"
	)

	task.wait(EXIT_DELAY)
	cleanup(session, true)
end

function RiftService.enter(player: Player, riftId: string)
	local rift = RiftCatalog.get(riftId)
	local profile = DataService.get(player)
	if not rift or not profile then
		return
	end

	if sessions[player] then
		ProgressionService.notify(player, "IMPOSSIBLE", "Tu es déjà dans une faille.", "danger")
		return
	end

	if profile.level < rift.minLevel then
		ProgressionService.notify(
			player,
			"ACCÈS REFUSÉ",
			("Niveau %d requis pour « %s »."):format(rift.minLevel, rift.name),
			"danger"
		)
		return
	end

	local character = player.Character
	if not character or not playerIsAlive(player) then
		return
	end

	local slot = allocateSlot()
	local center = ARENA_ORIGIN + Vector3.new(0, 0, slot * ARENA_SPACING)
	local folder, spawnCFrame = WorldBuilder.buildArena(
		("Faille_%s_%d"):format(rift.id, slot),
		center,
		rift.arenaSize,
		rift.color
	)
	folder.Parent = riftsFolder

	local session: Session = {
		player = player,
		rift = rift,
		folder = folder,
		spawnCFrame = spawnCFrame,
		slot = slot,
		wave = 0,
		active = true,
	}
	sessions[player] = session

	character:PivotTo(spawnCFrame + Vector3.new(0, 4, 0))
	StatsService.markCombat(player)

	ProgressionService.notify(
		player,
		("FAILLE %s"):format(rift.rank),
		("« %s » : %d vagues. Bonne chasse."):format(rift.name, #rift.waves),
		"info"
	)

	task.spawn(function()
		local ok, err = pcall(runRift, session)
		if not ok then
			warn("[RiftService] " .. tostring(err))
			cleanup(session, true)
		end
	end)
end

function RiftService.leave(player: Player)
	local session = sessions[player]
	if not session then
		return
	end
	ProgressionService.notify(player, "RETRAIT", "Tu as quitté la faille. Aucune récompense.", "danger")
	cleanup(session, true)
end

function RiftService.isInRift(player: Player): boolean
	return sessions[player] ~= nil
end

function RiftService.init()
	local hall = WorldBuilder.buildLobby()

	-- Un portail par faille, disposés en arc autour du hall.
	local count = #RiftCatalog.List
	for index, rift in ipairs(RiftCatalog.List) do
		local angle = math.rad(-70 + (index - 1) * (140 / math.max(count - 1, 1)))
		local position = Vector3.new(math.sin(angle) * 78, 2, -math.cos(angle) * 78)
		local _, prompt = WorldBuilder.buildPortal(rift, position, hall)

		prompt.Triggered:Connect(function(player)
			RiftService.enter(player, rift.id)
		end)
	end

	Remotes.event("EnterRift").OnServerEvent:Connect(function(player, riftId)
		if typeof(riftId) == "string" then
			RiftService.enter(player, riftId)
		end
	end)

	Remotes.event("LeaveRift").OnServerEvent:Connect(function(player)
		RiftService.leave(player)
	end)

	Players.PlayerRemoving:Connect(function(player)
		local session = sessions[player]
		if session then
			cleanup(session, false)
		end
	end)

	-- Si le joueur réapparaît (mort) alors qu'une session traîne, on ferme.
	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function()
			local session = sessions[player]
			if session then
				task.wait(0.5)
				cleanup(session, true)
			end
		end)
	end)
end

return RiftService
