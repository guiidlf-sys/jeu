--!strict
--[[
	NpcService
	Construit les PNJ de la zone sûre et déclenche leurs dialogues. Le premier
	échange avec le guide offre une mise de départ.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local NpcCatalog = require(Shared.NpcCatalog)
local Remotes = require(Shared.Remotes)

local DataService = require(script.Parent.DataService)
local ProgressionService = require(script.Parent.ProgressionService)
local WorldBuilder = require(script.Parent.WorldBuilder)

local STARTER_YENS = 300

local NpcService = {}

local function grantStarterGift(player: Player)
	local profile = DataService.get(player)
	if not profile or profile.flags.starterGift then
		return
	end

	profile.flags.starterGift = true
	ProgressionService.grantCurrency(player, "yens", STARTER_YENS)
	ProgressionService.notify(
		player,
		"CADEAU DE BIENVENUE",
		("Maître Renzo te remet %d yens pour tes débuts."):format(STARTER_YENS),
		"success"
	)
end

function NpcService.init()
	local hall = WorldBuilder.buildLobby()

	local folder = Instance.new("Folder")
	folder.Name = "PNJ"
	folder.Parent = hall

	for _, npc in ipairs(NpcCatalog.List) do
		local model, prompt = WorldBuilder.buildNpc(npc, folder)

		-- Orientation vers le centre du hall.
		local primary = model.PrimaryPart
		if primary then
			model:PivotTo(CFrame.new(primary.Position) * CFrame.Angles(0, math.rad(npc.facing), 0))
		end

		prompt.Triggered:Connect(function(player)
			if npc.action == "guide" then
				grantStarterGift(player)
			end
			Remotes.event("NpcDialogue"):FireClient(player, npc.id)
		end)
	end
end

return NpcService
