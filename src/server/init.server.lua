--!strict
--[[
	Point d'entrée serveur de MALÉDICTION : ÉVEIL.
	Les services sont initialisés dans l'ordre de leurs dépendances.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared.GameConfig)
require(Shared.Remotes) -- crée les RemoteEvent/RemoteFunction avant tout le reste

local Services = script.Services

local ORDER = {
	"DataService",
	"StatsService",
	"ProgressionService",
	"QuestService",
	"MobService",
	"RewardService",
	"CombatService",
	"ShopService",
	"RiftService",
	"TrainingService",
}

for _, name in ipairs(ORDER) do
	local module = Services:FindFirstChild(name)
	if not module then
		warn("[Serveur] service manquant : " .. name)
		continue
	end

	local service = require(module) :: any
	if typeof(service.init) == "function" then
		local ok, err = pcall(service.init)
		if not ok then
			warn(("[Serveur] échec de l'initialisation de %s : %s"):format(name, tostring(err)))
		end
	end
end

print(("[%s] serveur prêt (v%s)"):format(GameConfig.GameName, GameConfig.Version))
