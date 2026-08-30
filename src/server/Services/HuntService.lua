--!strict
--[[
	HuntService
	Contrats de chasse : acceptation, progression, récompenses.

	C'est aussi ce service qui décide quels esprits sont hostiles envers quel
	joueur : tant qu'aucun contrat ne vise une espèce, elle reste passive.
	Un cache par joueur évite de parcourir les contrats à chaque image.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local HuntCatalog = require(Shared.HuntCatalog)
local MobCatalog = require(Shared.MobCatalog)
local Remotes = require(Shared.Remotes)

local DataService = require(script.Parent.DataService)
local ProgressionService = require(script.Parent.ProgressionService)

local HuntService = {}

-- joueur -> { [mobId] = true } : les espèces qu'il chasse activement.
local hostileCache: { [Player]: { [string]: boolean } } = {}

local function rebuildCache(player: Player)
	local profile = DataService.get(player)
	if not profile then
		hostileCache[player] = nil
		return
	end

	local targets: { [string]: boolean } = {}
	for huntId, _ in pairs(profile.hunts.active) do
		local hunt = HuntCatalog.get(huntId)
		if hunt then
			for _, mobId in ipairs(hunt.targets) do
				targets[mobId] = true
			end
		end
	end
	hostileCache[player] = targets
end

--- Cette espèce est-elle en contrat pour ce joueur ?
function HuntService.isHunting(player: Player, mobId: string): boolean
	local targets = hostileCache[player]
	if not targets then
		return false
	end
	return targets[mobId] == true
end

--- Fait progresser les contrats qui visent l'esprit tué.
function HuntService.addKill(player: Player, mobId: string)
	local profile = DataService.get(player)
	if not profile then
		return
	end

	local changed = false
	for huntId, progress in pairs(profile.hunts.active) do
		local hunt = HuntCatalog.get(huntId)
		if not hunt or not HuntCatalog.targets(hunt, mobId) then
			continue
		end

		if progress >= hunt.goal then
			continue
		end

		local updated = math.min(progress + 1, hunt.goal)
		profile.hunts.active[huntId] = updated
		changed = true

		if updated >= hunt.goal then
			ProgressionService.notify(
				player,
				"CONTRAT REMPLI",
				("« %s » — récupère ta prime dans les quêtes (touche Q)."):format(hunt.name),
				"quest"
			)
		end
	end

	if changed then
		DataService.push(player)
	end
end

local function countActive(profile: any): number
	local count = 0
	for _ in pairs(profile.hunts.active) do
		count += 1
	end
	return count
end

--- Noms lisibles des espèces visées, pour les messages.
local function targetNames(hunt: any): string
	local names = {}
	for _, mobId in ipairs(hunt.targets) do
		local mob = MobCatalog.get(mobId)
		table.insert(names, if mob then mob.name else mobId)
	end
	return table.concat(names, ", ")
end

local function accept(player: Player, hunt: any)
	local profile = DataService.get(player)
	if not profile then
		return { ok = false, reason = "Profil indisponible." }
	end

	if profile.hunts.active[hunt.id] ~= nil then
		return { ok = false, reason = "Contrat déjà en cours." }
	end
	if profile.level < hunt.minLevel then
		return { ok = false, reason = ("Niveau %d requis."):format(hunt.minLevel) }
	end
	if countActive(profile) >= HuntCatalog.MaxActive then
		return { ok = false, reason = ("%d contrats maximum."):format(HuntCatalog.MaxActive) }
	end

	profile.hunts.active[hunt.id] = 0
	rebuildCache(player)
	DataService.push(player)

	ProgressionService.notify(
		player,
		"CONTRAT ACCEPTÉ",
		("%s\nCes esprits vont désormais t'attaquer à vue : %s."):format(hunt.name, targetNames(hunt)),
		"quest"
	)
	return { ok = true, reason = "" }
end

local function abandon(player: Player, hunt: any)
	local profile = DataService.get(player)
	if not profile or profile.hunts.active[hunt.id] == nil then
		return { ok = false, reason = "Contrat non actif." }
	end

	profile.hunts.active[hunt.id] = nil
	rebuildCache(player)
	DataService.push(player)

	ProgressionService.notify(
		player,
		"CONTRAT ABANDONNÉ",
		("%s — ces esprits te laissent de nouveau tranquille."):format(hunt.name),
		"info"
	)
	return { ok = true, reason = "" }
end

local function claim(player: Player, hunt: any)
	local profile = DataService.get(player)
	if not profile then
		return { ok = false, reason = "Profil indisponible." }
	end

	local progress = profile.hunts.active[hunt.id]
	if progress == nil then
		return { ok = false, reason = "Contrat non actif." }
	end
	if progress < hunt.goal then
		return { ok = false, reason = ("Encore %d à éliminer."):format(hunt.goal - progress) }
	end

	profile.hunts.active[hunt.id] = nil
	profile.hunts.completed[hunt.id] = (profile.hunts.completed[hunt.id] or 0) + 1
	rebuildCache(player)

	ProgressionService.grantRewards(player, hunt.reward)
	ProgressionService.notify(
		player,
		"PRIME VERSÉE",
		("%s : +%d yens, +%d XP, +%d fragment(s)."):format(
			hunt.name,
			hunt.reward.yens,
			hunt.reward.xp,
			hunt.reward.fragments
		),
		"success"
	)
	return { ok = true, reason = "" }
end

function HuntService.init()
	DataService.ProfileLoaded:connect(function(player: Player)
		rebuildCache(player)
	end)

	Players.PlayerRemoving:Connect(function(player)
		hostileCache[player] = nil
	end)

	Remotes.func("HuntRequest").OnServerInvoke = function(player, action, huntId)
		if typeof(action) ~= "string" or typeof(huntId) ~= "string" then
			return { ok = false, reason = "Requête invalide." }
		end

		local hunt = HuntCatalog.get(huntId)
		if not hunt then
			return { ok = false, reason = "Contrat inconnu." }
		end

		local handlers = { accept = accept, abandon = abandon, claim = claim }
		local handler = handlers[action]
		if not handler then
			return { ok = false, reason = "Action inconnue." }
		end

		local ok, result = pcall(handler, player, hunt)
		if not ok then
			warn("[HuntService] " .. tostring(result))
			return { ok = false, reason = "Erreur serveur." }
		end
		return result
	end
end

return HuntService
