--!strict
--[[
	CombatController
	Traduit les entrées du joueur en demandes de technique. Le serveur reste
	l'autorité : ici on ne fait qu'un suivi local des recharges pour l'UI.
]]

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared.Remotes)
local SkillCatalog = require(Shared.SkillCatalog)
local Signal = require(Shared.Signal)

local State = require(script.Parent.State)

local player = Players.LocalPlayer

local CombatController = {}

CombatController.cooldowns = {} :: { [string]: number }
CombatController.SkillUsed = Signal.new()

local enabled = false
local basicHeld = false

local function cooldownMultiplier(): number
	return 1 - (player:GetAttribute("ReductionCooldown") or 0)
end

function CombatController.setEnabled(value: boolean)
	enabled = value
	if not value then
		basicHeld = false
	end
end

function CombatController.remaining(skillId: string): number
	return math.max(0, (CombatController.cooldowns[skillId] or 0) - os.clock())
end

function CombatController.use(skillId: string): boolean
	if not enabled then
		return false
	end

	local skill = SkillCatalog.get(skillId)
	if not skill then
		return false
	end

	local profile = State.profile
	if profile and profile.level < skill.unlockLevel then
		return false
	end

	if CombatController.remaining(skillId) > 0 then
		return false
	end

	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return false
	end

	CombatController.cooldowns[skillId] = os.clock() + skill.cooldown * cooldownMultiplier()
	Remotes.event("UseSkill"):FireServer(skillId)
	CombatController.SkillUsed:fire(skillId)
	return true
end

function CombatController.init()
	-- Attaque de base : clic maintenu.
	ContextActionService:BindAction("AttaqueBase", function(_, state)
		if state == Enum.UserInputState.Begin then
			basicHeld = true
		elseif state == Enum.UserInputState.End then
			basicHeld = false
		end
		return Enum.ContextActionResult.Pass
	end, false, Enum.UserInputType.MouseButton1, Enum.UserInputType.Touch)

	task.spawn(function()
		while true do
			if basicHeld and enabled and not UserInputService:GetFocusedTextBox() then
				CombatController.use("poing_maudit")
			end
			task.wait(0.1)
		end
	end)

	-- Techniques liées à une touche.
	for _, skill in ipairs(SkillCatalog.List) do
		if not skill.keybind then
			continue
		end
		ContextActionService:BindAction("Technique_" .. skill.id, function(_, state)
			if state == Enum.UserInputState.Begin and not UserInputService:GetFocusedTextBox() then
				CombatController.use(skill.id)
			end
			return Enum.ContextActionResult.Pass
		end, false, skill.keybind)
	end
end

return CombatController
