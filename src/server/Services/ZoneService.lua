--!strict
--[[
	ZoneService
	Gère les trois lieux du jeu : le hall (zone sûre), le terrain de chasse et
	le hub AFK. Marque les joueurs protégés, déplace les personnages et
	distribue les gains passifs du hub.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared.GameConfig)
local Remotes = require(Shared.Remotes)

local DataService = require(script.Parent.DataService)
local ProgressionService = require(script.Parent.ProgressionService)
local RiftService = require(script.Parent.RiftService)
local WorldBuilder = require(script.Parent.WorldBuilder)

local SAFE_ATTRIBUTE = "ZoneSure"
local ZONE_ATTRIBUTE = "Zone"

local ZoneService = {}

local afkPlayers: { [Player]: number } = {} -- joueur -> horodatage d'entrée
local afkSpawn: CFrame = CFrame.new(GameConfig.AfkCenter + Vector3.new(0, 6, 0))

local function hallSpawnCFrame(): CFrame
	local hall = workspace:FindFirstChild("Hall")
	local spawnPart = hall and hall:FindFirstChild("Départ")
	if spawnPart and spawnPart:IsA("BasePart") then
		return spawnPart.CFrame + Vector3.new(0, 5, 0)
	end
	return CFrame.new(0, 8, 0)
end

ZoneService.hallSpawnCFrame = hallSpawnCFrame

local function setZone(player: Player, zone: string)
	player:SetAttribute(ZONE_ATTRIBUTE, zone)
	Remotes.event("ZoneChanged"):FireClient(player, zone)
end

--- Déplace le personnage, en quittant d'abord une éventuelle faille.
function ZoneService.teleport(player: Player, destination: string)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not character or not humanoid or humanoid.Health <= 0 then
		return
	end

	if RiftService.isInRift(player) then
		RiftService.leave(player)
		task.wait(0.3)
		character = player.Character
		if not character then
			return
		end
	end

	if destination == "afk" then
		afkPlayers[player] = os.clock()
		character:PivotTo(afkSpawn)
		setZone(player, "afk")
		ProgressionService.notify(
			player,
			"HUB AFK",
			("Gains passifs actifs : de l'XP et des yens toutes les %d secondes, même sans rien faire.")
				:format(GameConfig.AfkRewardInterval),
			"info"
		)
	else
		afkPlayers[player] = nil
		character:PivotTo(hallSpawnCFrame())
		setZone(player, "hall")
	end
end

function ZoneService.isAfk(player: Player): boolean
	return afkPlayers[player] ~= nil
end

function ZoneService.init()
	WorldBuilder.buildLobby()
	WorldBuilder.buildAfkHub(GameConfig.AfkCenter)

	Remotes.event("Teleport").OnServerEvent:Connect(function(player, destination)
		if typeof(destination) ~= "string" then
			return
		end
		if destination ~= "hall" and destination ~= "afk" then
			return
		end
		local ok, err = pcall(ZoneService.teleport, player, destination)
		if not ok then
			warn("[ZoneService] " .. tostring(err))
		end
	end)

	Players.PlayerRemoving:Connect(function(player)
		afkPlayers[player] = nil
	end)

	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function()
			-- On réapparaît toujours dans la zone sûre.
			afkPlayers[player] = nil
			setZone(player, "hall")
		end)
	end)

	-- Marquage de la zone sûre : les esprits ignorent les joueurs protégés.
	task.spawn(function()
		while true do
			task.wait(0.4)
			for _, player in ipairs(Players:GetPlayers()) do
				local character = player.Character
				local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
				if not root then
					continue
				end

				local inAfk = afkPlayers[player] ~= nil
				local flat = Vector3.new(root.Position.X, 0, root.Position.Z)
				local inHall = not inAfk
					and flat.Magnitude <= GameConfig.SafeZoneRadius
					and math.abs(root.Position.Y) < 200

				local safe = inHall or inAfk
				if player:GetAttribute(SAFE_ATTRIBUTE) ~= safe then
					player:SetAttribute(SAFE_ATTRIBUTE, safe)
				end

				local zone = if inAfk then "afk" elseif inHall then "hall" else "chasse"
				if RiftService.isInRift(player) then
					zone = "faille"
				end
				if player:GetAttribute(ZONE_ATTRIBUTE) ~= zone then
					setZone(player, zone)
				end
			end
		end
	end)

	-- Gains passifs du hub AFK.
	task.spawn(function()
		while true do
			task.wait(GameConfig.AfkRewardInterval)
			for player, _ in pairs(afkPlayers) do
				local profile = DataService.get(player)
				if not player.Parent or not profile then
					afkPlayers[player] = nil
					continue
				end

				local character = player.Character
				local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
				if not root or (root.Position - GameConfig.AfkCenter).Magnitude > 120 then
					-- Le joueur a quitté l'île : plus de gains.
					afkPlayers[player] = nil
					continue
				end

				ProgressionService.grantRewards(player, {
					xp = 10 + profile.level * 3,
					yens = 6 + profile.level * 2,
				})
			end
		end
	end)
end

return ZoneService
