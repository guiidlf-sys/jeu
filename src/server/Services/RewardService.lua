--!strict
--[[
	RewardService
	Distribue XP, yens et fragments à la mort d'un esprit maudit, et met à
	jour les compteurs de quête.
]]

local DataService = require(script.Parent.DataService)
local HuntService = require(script.Parent.HuntService)
local MobService = require(script.Parent.MobService)
local ProgressionService = require(script.Parent.ProgressionService)
local QuestService = require(script.Parent.QuestService)

local RewardService = {}

local random = Random.new()

function RewardService.init()
	MobService.MobKilled:connect(function(def: any, killer: Player?)
		if not killer or not killer.Parent then
			return
		end

		local profile = DataService.get(killer)
		if not profile then
			return
		end

		profile.totals.kills += 1

		ProgressionService.grantCurrency(killer, "yens", def.yens)
		if random:NextNumber() < def.fragmentChance then
			ProgressionService.grantCurrency(killer, "fragments", 1)
		end
		ProgressionService.grantXp(killer, def.xp)
		QuestService.addProgress(killer, "kills", 1)
		HuntService.addKill(killer, def.id)
	end)
end

return RewardService
