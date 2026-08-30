--!strict
--[[
	QuestService
	Quêtes quotidiennes du "Système". La progression est enregistrée dans le
	profil et remise à zéro au changement de jour.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local QuestCatalog = require(Shared.QuestCatalog)
local Remotes = require(Shared.Remotes)
local Util = require(Shared.Util)

local DataService = require(script.Parent.DataService)
local ProgressionService = require(script.Parent.ProgressionService)

local QuestService = {}

local function refreshDay(profile: any): boolean
	local today = Util.currentDay()
	if profile.quests.day ~= today then
		profile.quests.day = today
		profile.quests.progress = { kills = 0, damage = 0, riftsCleared = 0 }
		profile.quests.claimed = {}
		return true
	end
	return false
end

--- Fait progresser une métrique de quête (kills / damage / riftsCleared).
function QuestService.addProgress(player: Player, metric: string, amount: number)
	local profile = DataService.get(player)
	if not profile or amount <= 0 then
		return
	end

	refreshDay(profile)
	local progress = profile.quests.progress
	if progress[metric] == nil then
		return
	end

	progress[metric] += amount

	-- Prévient le joueur quand une quête devient réclamable.
	for _, quest in ipairs(QuestCatalog.List) do
		if quest.metric == metric and not profile.quests.claimed[quest.id] then
			local before = progress[metric] - amount
			if before < quest.goal and progress[metric] >= quest.goal then
				ProgressionService.notify(
					player,
					"QUÊTE TERMINÉE",
					("« %s » est prête à être réclamée."):format(quest.name),
					"quest"
				)
			end
		end
	end

	DataService.push(player)
end

function QuestService.init()
	DataService.ProfileLoaded:connect(function(player: Player, profile: any)
		if refreshDay(profile) then
			DataService.push(player)
		end
	end)

	Remotes.func("ClaimQuest").OnServerInvoke = function(player, questId)
		if typeof(questId) ~= "string" then
			return { ok = false, reason = "Quête inconnue." }
		end

		local quest = QuestCatalog.get(questId)
		local profile = DataService.get(player)
		if not quest or not profile then
			return { ok = false, reason = "Quête inconnue." }
		end

		refreshDay(profile)

		if profile.quests.claimed[quest.id] then
			return { ok = false, reason = "Déjà réclamée aujourd'hui." }
		end
		if (profile.quests.progress[quest.metric] or 0) < quest.goal then
			return { ok = false, reason = "Objectif non atteint." }
		end

		profile.quests.claimed[quest.id] = true
		ProgressionService.grantRewards(player, quest.reward)
		ProgressionService.notify(
			player,
			"RÉCOMPENSE",
			("%s : +%d yens, +%d XP, +%d point(s) de statistique.")
				:format(quest.name, quest.reward.yens, quest.reward.xp, quest.reward.statPoints),
			"quest"
		)

		return { ok = true, reason = "" }
	end
end

return QuestService
