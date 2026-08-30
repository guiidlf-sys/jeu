--!strict
--[[
	ShopService
	Achats et équipement. Le prix et le niveau requis sont revérifiés côté
	serveur, le client ne fait qu'afficher le catalogue.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared.Remotes)
local ShopCatalog = require(Shared.ShopCatalog)

local DataService = require(script.Parent.DataService)
local ProgressionService = require(script.Parent.ProgressionService)
local StatsService = require(script.Parent.StatsService)

local ShopService = {}

local function applyAura(player: Player)
	local profile = DataService.get(player)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not (profile and root) then
		return
	end

	local existing = root:FindFirstChild("AuraMaudite")
	if existing then
		existing:Destroy()
	end

	local auraId = profile.equipped.aura
	local item = if auraId ~= "" then ShopCatalog.get(auraId) else nil
	if not item then
		return
	end

	local emitter = Instance.new("ParticleEmitter")
	emitter.Name = "AuraMaudite"
	emitter.Color = ColorSequence.new(item.color)
	emitter.LightEmission = 0.8
	emitter.Rate = 28
	emitter.Lifetime = NumberRange.new(0.6, 1.1)
	emitter.Speed = NumberRange.new(1, 3)
	emitter.SpreadAngle = Vector2.new(20, 20)
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1.6),
		NumberSequenceKeypoint.new(1, 0),
	})
	emitter.Transparency = NumberSequence.new(0.25)
	emitter.Parent = root
end

ShopService.applyAura = applyAura

local function purchase(player: Player, itemId: string)
	local item = ShopCatalog.get(itemId)
	local profile = DataService.get(player)
	if not item or not profile then
		return { ok = false, reason = "Article introuvable." }
	end

	if profile.owned[item.id] then
		return { ok = false, reason = "Tu possèdes déjà cet article." }
	end

	if profile.level < item.requiredLevel then
		return { ok = false, reason = ("Niveau %d requis."):format(item.requiredLevel) }
	end

	local balance = profile.currencies[item.currency] or 0
	if balance < item.price then
		return { ok = false, reason = "Fonds insuffisants." }
	end

	profile.currencies[item.currency] = balance - item.price
	profile.owned[item.id] = true

	-- Équipement automatique de la catégorie concernée.
	if item.category == "arme" then
		profile.equipped.arme = item.id
	elseif item.category == "aura" then
		profile.equipped.aura = item.id
	end

	StatsService.apply(player)
	applyAura(player)
	DataService.push(player)

	ProgressionService.notify(player, "ACHAT", ("« %s » acquis."):format(item.name), "success")
	return { ok = true, reason = "" }
end

local function equip(player: Player, itemId: string)
	local profile = DataService.get(player)
	if not profile then
		return
	end

	if itemId == "" then
		return
	end

	local item = ShopCatalog.get(itemId)
	if not item or not profile.owned[item.id] then
		return
	end

	if item.category == "arme" then
		profile.equipped.arme = if profile.equipped.arme == item.id then "" else item.id
	elseif item.category == "aura" then
		profile.equipped.aura = if profile.equipped.aura == item.id then "" else item.id
	else
		return
	end

	StatsService.apply(player)
	applyAura(player)
	DataService.push(player)
end

function ShopService.init()
	Remotes.func("PurchaseItem").OnServerInvoke = function(player, itemId)
		if typeof(itemId) ~= "string" then
			return { ok = false, reason = "Requête invalide." }
		end
		local ok, result = pcall(purchase, player, itemId)
		if not ok then
			warn("[ShopService] " .. tostring(result))
			return { ok = false, reason = "Erreur serveur." }
		end
		return result
	end

	Remotes.event("EquipItem").OnServerEvent:Connect(function(player, itemId)
		if typeof(itemId) == "string" then
			equip(player, itemId)
		end
	end)

	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function()
			task.wait(0.4)
			applyAura(player)
		end)
	end)
end

return ShopService
