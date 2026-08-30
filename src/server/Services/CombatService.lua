--!strict
--[[
	CombatService
	Toutes les attaques sont validées et résolues côté serveur : le client
	n'envoie qu'une intention (« j'utilise cette technique »).
]]

local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared.GameConfig)
local Remotes = require(Shared.Remotes)
local SkillCatalog = require(Shared.SkillCatalog)

local DataService = require(script.Parent.DataService)
local MobService = require(script.Parent.MobService)
local QuestService = require(script.Parent.QuestService)
local StatsService = require(script.Parent.StatsService)

local CRIT_CHANCE = 0.12
local CRIT_MULTIPLIER = 1.8

local CombatService = {}

local cooldowns: { [Player]: { [string]: number } } = {}
local random = Random.new()

local function feedback(player: Player, payload: any)
	Remotes.event("CombatFeedback"):FireClient(player, payload)
end

local function spawnVfx(skill: any, origin: CFrame)
	local part = Instance.new("Part")
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.Material = Enum.Material.Neon
	part.Color = skill.color
	part.Transparency = 0.25

	local goalSize: Vector3
	if skill.shape == "circle" then
		part.Shape = Enum.PartType.Ball
		part.Size = Vector3.new(2, 2, 2)
		part.CFrame = origin
		goalSize = Vector3.one * (skill.radius or 10) * 2
	elseif skill.shape == "line" then
		local length = skill.range
		local width = (skill.radius or 3) * 2
		part.Size = Vector3.new(width, width * 0.4, length)
		part.CFrame = origin * CFrame.new(0, 0, -length / 2)
		goalSize = Vector3.new(width * 0.3, width * 0.15, length)
	else -- arc
		part.Shape = Enum.PartType.Ball
		part.Size = Vector3.new(2, 2, 2)
		part.CFrame = origin * CFrame.new(0, 0, -skill.range * 0.4)
		goalSize = Vector3.one * skill.range
	end

	part.Parent = workspace
	TweenService:Create(part, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = goalSize,
		Transparency = 1,
	}):Play()
	Debris:AddItem(part, 0.5)
end

--- Renvoie les modèles d'esprits touchés par la technique.
local function collectTargets(skill: any, root: BasePart): { Model }
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { root.Parent :: Instance }
	params.MaxParts = 120

	local parts: { BasePart }
	if skill.shape == "line" then
		local length = skill.range
		local width = (skill.radius or 3) * 2
		local center = root.CFrame * CFrame.new(0, 0, -length / 2)
		parts = workspace:GetPartBoundsInBox(center, Vector3.new(width, 12, length), params)
	elseif skill.shape == "circle" then
		parts = workspace:GetPartBoundsInRadius(root.Position, skill.radius or 10, params)
	else
		parts = workspace:GetPartBoundsInRadius(root.Position, skill.range, params)
	end

	local seen: { [Model]: boolean } = {}
	local targets: { Model } = {}

	for _, part in ipairs(parts) do
		local model = part:FindFirstAncestorOfClass("Model")
		if not model or seen[model] or not MobService.isMob(model) then
			continue
		end

		local targetRoot = model.PrimaryPart
		if not targetRoot then
			continue
		end

		-- Filtre angulaire pour les attaques en arc (devant le joueur).
		if skill.shape == "arc" then
			local toTarget = (targetRoot.Position - root.Position)
			local flat = Vector3.new(toTarget.X, 0, toTarget.Z)
			if flat.Magnitude > 0.01 then
				local angle = math.deg(math.acos(math.clamp(flat.Unit:Dot(root.CFrame.LookVector), -1, 1)))
				if angle > (skill.angle or 120) / 2 then
					continue
				end
			end
		end

		seen[model] = true
		table.insert(targets, model)
		if #targets >= GameConfig.MaxHitsPerSwing then
			break
		end
	end

	return targets
end

local function useSkill(player: Player, skillId: string)
	local skill = SkillCatalog.get(skillId)
	local profile = DataService.get(player)
	if not skill or not profile then
		return
	end

	if profile.level < skill.unlockLevel then
		return
	end

	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not (character and humanoid and root) or humanoid.Health <= 0 then
		return
	end

	local derived = StatsService.getDerived(player)
	if not derived then
		return
	end

	local playerCooldowns = cooldowns[player]
	if not playerCooldowns then
		playerCooldowns = {}
		cooldowns[player] = playerCooldowns
	end

	local now = os.clock()
	local readyAt = playerCooldowns[skill.id] or 0
	if now < readyAt then
		return
	end

	if skill.cost > 0 and not StatsService.consumeEnergy(player, skill.cost) then
		feedback(player, { kind = "noEnergy", skillId = skill.id })
		return
	end

	playerCooldowns[skill.id] = now + skill.cooldown * derived.cooldownMultiplier
	StatsService.markCombat(player)
	spawnVfx(skill, root.CFrame)

	local targets = collectTargets(skill, root)
	if #targets == 0 then
		feedback(player, { kind = "miss", skillId = skill.id })
		return
	end

	-- Les techniques (celles qui coûtent de l'énergie) tapent avec la Magie,
	-- l'attaque de base avec la Force.
	local power = if skill.cost > 0 then derived.magicDamage else derived.damage

	local totalDealt = 0
	for _, target in ipairs(targets) do
		local isCrit = random:NextNumber() < CRIT_CHANCE
		local variance = random:NextNumber(0.95, 1.08)
		local amount = power * skill.damageMultiplier * variance
		if isCrit then
			amount *= CRIT_MULTIPLIER
		end
		amount = math.floor(amount)

		local dealt = MobService.damage(target, amount, player)
		totalDealt += dealt

		local targetRoot = target.PrimaryPart
		if targetRoot then
			feedback(player, {
				kind = "dealt",
				amount = amount,
				crit = isCrit,
				position = targetRoot.Position,
			})
		end
	end

	if totalDealt > 0 then
		QuestService.addProgress(player, "damage", math.floor(totalDealt))
	end
end

function CombatService.init()
	Remotes.event("UseSkill").OnServerEvent:Connect(function(player, skillId)
		if typeof(skillId) ~= "string" then
			return
		end
		local ok, err = pcall(useSkill, player, skillId)
		if not ok then
			warn("[CombatService] " .. tostring(err))
		end
	end)

	Players.PlayerRemoving:Connect(function(player)
		cooldowns[player] = nil
	end)
end

return CombatService
