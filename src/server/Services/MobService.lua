--!strict
--[[
	MobService
	Création, IA et mort des esprits maudits. Les rigs sont générés par code
	pour que le jeu tourne dans une place vide, sans asset à importer.
]]

local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local MobCatalog = require(Shared.MobCatalog)
local Remotes = require(Shared.Remotes)
local Signal = require(Shared.Signal)

local AI_INTERVAL = 0.2
local LEASH_DISTANCE = 160

local MobService = {}

MobService.MobKilled = Signal.new() -- (mobDef, killer: Player?, model)

export type Record = {
	model: Model,
	humanoid: Humanoid,
	root: BasePart,
	def: any,
	owner: Player?,
	origin: Vector3,
	lastAttack: number,
	lastDamager: Player?,
	dead: boolean,
}

local records: { [Model]: Record } = {}

local mobsFolder = workspace:FindFirstChild("Esprits")
if not mobsFolder then
	local folder = Instance.new("Folder")
	folder.Name = "Esprits"
	folder.Parent = workspace
	mobsFolder = folder
end

local function createHealthBar(model: Model, def: any, humanoid: Humanoid, root: BasePart)
	local gui = Instance.new("BillboardGui")
	gui.Name = "Barre"
	gui.Size = UDim2.fromScale(6, 1.1)
	gui.StudsOffsetWorldSpace = Vector3.new(0, def.size.Y * 0.75 + 1.5, 0)
	gui.AlwaysOnTop = false
	gui.MaxDistance = 120
	gui.Adornee = root
	gui.Parent = root

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 0.45, 0)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.TextColor3 = def.glow
	label.TextStrokeTransparency = 0.4
	label.Text = def.name
	label.Parent = gui

	local barBack = Instance.new("Frame")
	barBack.Size = UDim2.new(1, 0, 0.3, 0)
	barBack.Position = UDim2.new(0, 0, 0.55, 0)
	barBack.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
	barBack.BorderSizePixel = 0
	barBack.Parent = gui

	local fill = Instance.new("Frame")
	fill.Size = UDim2.fromScale(1, 1)
	fill.BackgroundColor3 = Color3.fromRGB(220, 60, 70)
	fill.BorderSizePixel = 0
	fill.Parent = barBack

	humanoid.HealthChanged:Connect(function(health)
		local ratio = if humanoid.MaxHealth > 0 then health / humanoid.MaxHealth else 0
		fill.Size = UDim2.fromScale(math.clamp(ratio, 0, 1), 1)
	end)
end

local function buildRig(def: any): (Model, Humanoid, BasePart)
	local model = Instance.new("Model")
	model.Name = def.name

	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.Size = def.size
	root.Color = def.color
	root.Material = Enum.Material.Slate
	root.TopSurface = Enum.SurfaceType.Smooth
	root.BottomSurface = Enum.SurfaceType.Smooth
	root.Parent = model

	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Scale = Vector3.new(1, 1.1, 1)
	mesh.Parent = root

	local head = Instance.new("Part")
	head.Name = "Head"
	head.Size = Vector3.new(def.size.X * 0.5, def.size.Y * 0.35, def.size.Z * 0.5)
	head.Color = def.glow
	head.Material = Enum.Material.Neon
	head.CanCollide = false
	head.Massless = true
	head.Parent = model

	head.CFrame = root.CFrame * CFrame.new(0, def.size.Y * 0.55, 0)
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = root
	weld.Part1 = head
	weld.Parent = head

	local light = Instance.new("PointLight")
	light.Color = def.glow
	light.Range = 14
	light.Brightness = 1.6
	light.Parent = head

	local humanoid = Instance.new("Humanoid")
	humanoid.MaxHealth = def.health
	humanoid.Health = def.health
	humanoid.WalkSpeed = def.walkSpeed
	humanoid.HipHeight = def.size.Y * 0.5
	humanoid.RigType = Enum.HumanoidRigType.R15
	humanoid.RequiresNeck = false
	humanoid.BreakJointsOnDeath = false
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	humanoid.Parent = model

	model.PrimaryPart = root
	createHealthBar(model, def, humanoid, root)

	return model, humanoid, root
end

--- Fait apparaître un esprit. `owner` reçoit les récompenses par défaut.
function MobService.spawn(mobId: string, position: Vector3, parent: Instance?, owner: Player?): Model?
	local def = MobCatalog.get(mobId)
	if not def then
		warn("[MobService] esprit inconnu : " .. tostring(mobId))
		return nil
	end

	local model, humanoid, root = buildRig(def)
	model:SetAttribute("MobId", def.id)
	if owner then
		model:SetAttribute("OwnerUserId", owner.UserId)
	end

	-- PivotTo (et non root.CFrame) : les soudures ne sont pas encore actives,
	-- il faut déplacer le modèle entier pour garder la tête au bon endroit.
	model:PivotTo(CFrame.new(position + Vector3.new(0, def.size.Y, 0)))
	model.Parent = parent or mobsFolder

	records[model] = {
		model = model,
		humanoid = humanoid,
		root = root,
		def = def,
		owner = owner,
		origin = position,
		lastAttack = 0,
		lastDamager = nil,
		dead = false,
	}

	humanoid.Died:Connect(function()
		MobService.handleDeath(model)
	end)

	-- Apparition : fondu depuis l'invisible.
	root.Transparency = 1
	TweenService:Create(root, TweenInfo.new(0.45), { Transparency = 0 }):Play()

	local head = model:FindFirstChild("Head")
	if head and head:IsA("BasePart") then
		head.Transparency = 1
		TweenService:Create(head, TweenInfo.new(0.45), { Transparency = 0 }):Play()
	end

	return model
end

function MobService.isMob(model: Instance): boolean
	return records[model :: Model] ~= nil
end

function MobService.getRecord(model: Model): Record?
	return records[model]
end

--- Applique des dégâts en retenant l'auteur pour l'attribution des gains.
function MobService.damage(model: Model, amount: number, source: Player?): number
	local record = records[model]
	if not record or record.dead then
		return 0
	end

	local dealt = math.min(amount, record.humanoid.Health)
	record.lastDamager = source or record.lastDamager
	record.humanoid:TakeDamage(amount)
	return dealt
end

function MobService.handleDeath(model: Model)
	local record = records[model]
	if not record or record.dead then
		return
	end
	record.dead = true
	records[model] = nil

	local killer = record.lastDamager or record.owner
	MobService.MobKilled:fire(record.def, killer, model)

	-- Dissolution.
	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") then
			part.CanCollide = false
			part.Anchored = true
			TweenService:Create(part, TweenInfo.new(0.8), { Transparency = 1, Size = part.Size * 0.4 }):Play()
		elseif part:IsA("BillboardGui") then
			part.Enabled = false
		end
	end
	Debris:AddItem(model, 1)
end

function MobService.clearAll(parent: Instance)
	for model, _ in pairs(records) do
		if model:IsDescendantOf(parent) then
			records[model] = nil
			model:Destroy()
		end
	end
end

function MobService.countIn(parent: Instance): number
	local count = 0
	for model, record in pairs(records) do
		if not record.dead and model:IsDescendantOf(parent) then
			count += 1
		end
	end
	return count
end

local function nearestTarget(record: Record): (Model?, Humanoid?, number)
	local bestModel, bestHumanoid, bestDistance = nil, nil, math.huge
	local origin = record.root.Position

	for _, player in ipairs(Players:GetPlayers()) do
		-- Les joueurs de la zone sûre (hall, hub AFK) sont intouchables.
		if player:GetAttribute("ZoneSure") == true then
			continue
		end

		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if not (humanoid and root) or humanoid.Health <= 0 then
			continue
		end

		local distance = (root.Position - origin).Magnitude
		if distance < bestDistance and distance <= LEASH_DISTANCE then
			bestModel, bestHumanoid, bestDistance = character, humanoid, distance
		end
	end

	return bestModel, bestHumanoid, bestDistance
end

local function updateRecord(record: Record, now: number)
	if record.dead or record.humanoid.Health <= 0 then
		return
	end

	local targetModel, targetHumanoid, distance = nearestTarget(record)
	if not targetModel or not targetHumanoid then
		record.humanoid:MoveTo(record.origin)
		return
	end

	local targetRoot = targetModel:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not targetRoot then
		return
	end

	if distance > record.def.attackRange then
		record.humanoid:MoveTo(targetRoot.Position)
	else
		record.humanoid:MoveTo(record.root.Position)
		if now - record.lastAttack >= record.def.attackCooldown then
			record.lastAttack = now
			targetHumanoid:TakeDamage(record.def.damage)

			local player = Players:GetPlayerFromCharacter(targetModel)
			if player then
				Remotes.event("CombatFeedback"):FireClient(player, {
					kind = "taken",
					amount = record.def.damage,
					from = record.def.name,
				})
			end

			-- Petit effet visuel d'attaque.
			local flash = Instance.new("Part")
			flash.Anchored = true
			flash.CanCollide = false
			flash.CanQuery = false
			flash.Material = Enum.Material.Neon
			flash.Color = record.def.glow
			flash.Transparency = 0.35
			flash.Size = Vector3.new(1, 1, 1) * record.def.attackRange
			flash.CFrame = CFrame.new(record.root.Position)
			flash.Shape = Enum.PartType.Ball
			flash.Parent = workspace
			TweenService:Create(flash, TweenInfo.new(0.25), { Transparency = 1, Size = Vector3.zero }):Play()
			Debris:AddItem(flash, 0.3)
		end
	end
end

function MobService.init()
	local accumulator = 0
	RunService.Heartbeat:Connect(function(delta)
		accumulator += delta
		if accumulator < AI_INTERVAL then
			return
		end
		accumulator = 0

		local now = os.clock()
		for model, record in pairs(records) do
			if not model.Parent then
				records[model] = nil
				continue
			end
			local ok, err = pcall(updateRecord, record, now)
			if not ok then
				warn("[MobService] IA : " .. tostring(err))
			end
		end
	end)
end

return MobService
