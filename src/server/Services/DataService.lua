--!strict
--[[
	DataService
	Chargement / sauvegarde des profils joueurs (DataStore avec repli mémoire
	quand les DataStores ne sont pas disponibles, ex. Studio hors ligne).
]]

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared.Remotes)
local Signal = require(Shared.Signal)
local Util = require(Shared.Util)

local DATASTORE_NAME = "MaledictionEveil_Profiles_v1"
local AUTOSAVE_INTERVAL = 120
local MAX_RETRIES = 4

local DataService = {}

DataService.ProfileLoaded = Signal.new()
DataService.ProfileChanged = Signal.new()

local store: DataStore? = nil
do
	local ok, result = pcall(function()
		return DataStoreService:GetDataStore(DATASTORE_NAME)
	end)
	if ok then
		store = result
	else
		warn("[DataService] DataStore indisponible, sauvegarde en mémoire uniquement.")
	end
end

local TEMPLATE = {
	level = 1,
	xp = 0,
	statPoints = 0,
	stats = { force = 0, agilite = 0, vitalite = 0, energie = 0 },
	currencies = { yens = 0, fragments = 0 },
	owned = {},
	equipped = { arme = "", aura = "" },
	quests = { day = 0, progress = { kills = 0, damage = 0, riftsCleared = 0 }, claimed = {} },
	totals = { kills = 0, riftsCleared = 0, deaths = 0 },
	bestRiftRank = "-",
	playtime = 0,
}

DataService.Template = TEMPLATE

local profiles: { [Player]: any } = {}
local loading: { [Player]: boolean } = {}

local function key(player: Player): string
	return ("player_%d"):format(player.UserId)
end

local function retry<T>(operation: () -> T): (boolean, T?)
	local delaySeconds = 1
	for attempt = 1, MAX_RETRIES do
		local ok, result = pcall(operation)
		if ok then
			return true, result
		end
		warn(("[DataService] tentative %d échouée : %s"):format(attempt, tostring(result)))
		if attempt < MAX_RETRIES then
			task.wait(delaySeconds)
			delaySeconds *= 2
		end
	end
	return false, nil
end

function DataService.get(player: Player): any?
	return profiles[player]
end

--- Attend que le profil soit disponible (utile juste après l'arrivée du joueur).
function DataService.await(player: Player, timeout: number?): any?
	local deadline = os.clock() + (timeout or 10)
	while os.clock() < deadline do
		local profile = profiles[player]
		if profile then
			return profile
		end
		if not player.Parent then
			return nil
		end
		task.wait(0.1)
	end
	return profiles[player]
end

--- Envoie le profil au client et prévient les autres services.
function DataService.push(player: Player)
	local profile = profiles[player]
	if not profile then
		return
	end
	DataService.ProfileChanged:fire(player, profile)
	Remotes.event("ProfileUpdated"):FireClient(player, profile)
end

local function load(player: Player)
	loading[player] = true

	local data
	if store then
		local dataStore = store :: DataStore
		local ok, result = retry(function()
			return dataStore:GetAsync(key(player))
		end)
		if ok then
			data = result
		else
			warn(("[DataService] Impossible de charger %s, profil temporaire."):format(player.Name))
		end
	end

	if typeof(data) ~= "table" then
		data = Util.deepCopy(TEMPLATE)
	else
		Util.reconcile(data, TEMPLATE)
	end

	loading[player] = nil
	if not player.Parent then
		return
	end

	profiles[player] = data
	DataService.ProfileLoaded:fire(player, data)
	DataService.push(player)
end

local function save(player: Player, release: boolean?)
	local profile = profiles[player]
	if not profile or not store then
		if release then
			profiles[player] = nil
		end
		return
	end

	local snapshot = Util.deepCopy(profile)
	local dataStore = store :: DataStore
	retry(function()
		dataStore:UpdateAsync(key(player), function()
			return snapshot
		end)
		return true
	end)

	if release then
		profiles[player] = nil
	end
end

DataService.save = save

function DataService.init()
	Players.PlayerAdded:Connect(function(player)
		task.spawn(load, player)
	end)

	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(load, player)
	end

	Players.PlayerRemoving:Connect(function(player)
		save(player, true)
	end)

	-- Autosave échelonné pour ne pas saturer les requêtes.
	task.spawn(function()
		while true do
			task.wait(AUTOSAVE_INTERVAL)
			for _, player in ipairs(Players:GetPlayers()) do
				task.spawn(save, player, false)
				task.wait(1)
			end
		end
	end)

	-- Comptabilise le temps de jeu (statistique affichée dans les crédits).
	task.spawn(function()
		while true do
			task.wait(60)
			for player, profile in pairs(profiles) do
				if player.Parent then
					profile.playtime += 60
				end
			end
		end
	end)

	game:BindToClose(function()
		if RunService:IsStudio() then
			return
		end
		for _, player in ipairs(Players:GetPlayers()) do
			task.spawn(save, player, true)
		end
		task.wait(3)
	end)

	Remotes.func("GetProfile").OnServerInvoke = function(player)
		return DataService.await(player, 15)
	end
end

return DataService
