--!strict
--[[
	Remotes
	Crée (côté serveur) et récupère (côté client) les RemoteEvent/RemoteFunction.
	Un seul point d'entrée évite les WaitForChild dispersés dans le code.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local IS_SERVER = RunService:IsServer()
local FOLDER_NAME = "Remotes"

local EVENTS = {
	-- Serveur -> client
	"ProfileUpdated", -- table du profil (niveau, xp, stats, monnaies...)
	"SystemMessage", -- notification style "Système"
	"CombatFeedback", -- dégâts infligés / reçus, pour les chiffres flottants
	"RiftStateChanged", -- progression de la faille en cours
	"NpcDialogue", -- ouverture d'un dialogue de PNJ
	"ZoneChanged", -- hall / faille / hub AFK
	-- Client -> serveur
	"UseSkill",
	"Teleport", -- "hall" ou "afk"
	"SpendStatPoint",
	"EnterRift",
	"LeaveRift",
	"EquipItem",
}

local FUNCTIONS = {
	"GetProfile",
	"PurchaseItem",
	"ClaimQuest",
	"HuntRequest", -- accepter / abandonner / réclamer un contrat de chasse
}

local Remotes = {}

local folder: Folder

if IS_SERVER then
	folder = ReplicatedStorage:FindFirstChild(FOLDER_NAME) :: Folder
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = FOLDER_NAME
		folder.Parent = ReplicatedStorage
	end

	for _, name in ipairs(EVENTS) do
		if not folder:FindFirstChild(name) then
			local remote = Instance.new("RemoteEvent")
			remote.Name = name
			remote.Parent = folder
		end
	end

	for _, name in ipairs(FUNCTIONS) do
		if not folder:FindFirstChild(name) then
			local remote = Instance.new("RemoteFunction")
			remote.Name = name
			remote.Parent = folder
		end
	end
else
	folder = ReplicatedStorage:WaitForChild(FOLDER_NAME) :: Folder
end

function Remotes.event(name: string): RemoteEvent
	local remote = folder:WaitForChild(name, 10)
	assert(remote and remote:IsA("RemoteEvent"), ("RemoteEvent introuvable : %s"):format(name))
	return remote :: RemoteEvent
end

function Remotes.func(name: string): RemoteFunction
	local remote = folder:WaitForChild(name, 10)
	assert(remote and remote:IsA("RemoteFunction"), ("RemoteFunction introuvable : %s"):format(name))
	return remote :: RemoteFunction
end

return Remotes
