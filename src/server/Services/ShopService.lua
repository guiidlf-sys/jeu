--!strict
--[[
	ShopService
	Achats en monnaie du jeu, achats en Robux (produits développeur) et
	équipement. Le prix, le niveau requis et le contenu des packs sont
	revérifiés côté serveur — le client ne fait qu'afficher le catalogue.
]]

local MarketplaceService = game:GetService("MarketplaceService")
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

--- Ajoute un article au profil, en équipant ce qui peut l'être.
--- Un pack délivre tout son contenu.
local function grant(profile: any, item: any)
	profile.owned[item.id] = true

	if item.category == "arme" then
		profile.equipped.arme = item.id
	elseif item.category == "aura" then
		profile.equipped.aura = item.id
	elseif item.category == "pack" and item.contents then
		for _, contentId in ipairs(item.contents) do
			local content = ShopCatalog.get(contentId)
			if content then
				grant(profile, content)
			end
		end
	end
end

--- Achat en monnaie du jeu.
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
	grant(profile, item)

	StatsService.apply(player)
	applyAura(player)
	DataService.push(player)

	ProgressionService.notify(player, "ACHAT", ("« %s » acquis."):format(item.name), "success")
	return { ok = true, reason = "" }
end

--- Délivre un article payé en Robux (appelé depuis ProcessReceipt).
local function grantRobuxPurchase(player: Player, item: any): boolean
	local profile = DataService.get(player)
	if not profile then
		return false
	end

	grant(profile, item)
	StatsService.apply(player)
	applyAura(player)
	DataService.push(player)

	ProgressionService.notify(
		player,
		"ACHAT ROBUX",
		("« %s » a été ajouté à ton inventaire. Merci du soutien."):format(item.name),
		"success"
	)
	return true
end

local function equip(player: Player, itemId: string)
	local profile = DataService.get(player)
	if not profile or itemId == "" then
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

	-- Achats en Robux. Roblox rappelle ce gestionnaire tant qu'on n'a pas
	-- renvoyé PurchaseGranted : on sauvegarde donc avant de valider.
	MarketplaceService.ProcessReceipt = function(receiptInfo)
		local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
		if not player then
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end

		local profile = DataService.get(player)
		if not profile then
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end

		local receiptKey = tostring(receiptInfo.PurchaseId)
		if profile.purchases[receiptKey] then
			return Enum.ProductPurchaseDecision.PurchaseGranted
		end

		local item = ShopCatalog.getByProductId(receiptInfo.ProductId)
		if not item then
			warn(("[ShopService] produit développeur inconnu : %d"):format(receiptInfo.ProductId))
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end

		local ok, granted = pcall(grantRobuxPurchase, player, item)
		if not ok or not granted then
			warn("[ShopService] achat Robux non délivré : " .. tostring(granted))
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end

		profile.purchases[receiptKey] = true
		DataService.save(player, false)

		return Enum.ProductPurchaseDecision.PurchaseGranted
	end
end

return ShopService
