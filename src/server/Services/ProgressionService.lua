--!strict
--[[
	ProgressionService
	XP, niveaux, rangs et gains de monnaie. Toute modification du profil liée
	à la progression passe par ici.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared.GameConfig)
local Remotes = require(Shared.Remotes)
local Signal = require(Shared.Signal)

local DataService = require(script.Parent.DataService)
local StatsService = require(script.Parent.StatsService)

local ProgressionService = {}

ProgressionService.LeveledUp = Signal.new()

local function notify(player: Player, title: string, body: string, kind: string?)
	Remotes.event("SystemMessage"):FireClient(player, {
		title = title,
		body = body,
		kind = kind or "info",
	})
end

ProgressionService.notify = notify

--- Ajoute de l'XP et gère les montées de niveau en chaîne.
function ProgressionService.grantXp(player: Player, amount: number)
	local profile = DataService.get(player)
	if not profile or amount <= 0 then
		return
	end

	profile.xp += math.floor(amount)

	local levelsGained = 0
	while profile.level < GameConfig.MaxLevel do
		local required = GameConfig.xpForNextLevel(profile.level)
		if profile.xp < required then
			break
		end
		profile.xp -= required
		profile.level += 1
		profile.statPoints += GameConfig.StatPointsPerLevel
		levelsGained += 1
	end

	if profile.level >= GameConfig.MaxLevel then
		profile.xp = 0
	end

	if levelsGained > 0 then
		local rank = GameConfig.rankForLevel(profile.level)
		StatsService.apply(player)
		ProgressionService.LeveledUp:fire(player, profile.level)

		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if humanoid and humanoid.Health > 0 then
			humanoid.Health = humanoid.MaxHealth
		end

		notify(
			player,
			"NIVEAU " .. profile.level,
			("Tu es monté de %d niveau(x). %d points de statistique disponibles. Rang : %s.")
				:format(levelsGained, profile.statPoints, rank.name),
			"levelup"
		)
	end

	DataService.push(player)
end

function ProgressionService.grantCurrency(player: Player, currency: string, amount: number)
	local profile = DataService.get(player)
	if not profile or profile.currencies[currency] == nil or amount == 0 then
		return
	end
	profile.currencies[currency] = math.max(0, profile.currencies[currency] + math.floor(amount))
	DataService.push(player)
end

function ProgressionService.grantStatPoints(player: Player, amount: number)
	local profile = DataService.get(player)
	if not profile or amount <= 0 then
		return
	end
	profile.statPoints += math.floor(amount)
	DataService.push(player)
end

--- Récompense complète (utilisée par les failles et les quêtes).
function ProgressionService.grantRewards(player: Player, rewards: { xp: number?, yens: number?, fragments: number?, statPoints: number? })
	if rewards.yens then
		ProgressionService.grantCurrency(player, "yens", rewards.yens)
	end
	if rewards.fragments then
		ProgressionService.grantCurrency(player, "fragments", rewards.fragments)
	end
	if rewards.statPoints then
		ProgressionService.grantStatPoints(player, rewards.statPoints)
	end
	if rewards.xp then
		ProgressionService.grantXp(player, rewards.xp)
	end
end

function ProgressionService.init()
	DataService.ProfileLoaded:connect(function(player: Player, profile: any)
		local rank = GameConfig.rankForLevel(profile.level)
		notify(
			player,
			"SYSTÈME",
			("Bienvenue, sorcier de %s. Niveau %d."):format(rank.name, profile.level),
			"info"
		)
	end)
end

return ProgressionService
