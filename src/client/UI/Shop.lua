--!strict
--[[
	Shop
	Boutique en grille : deux rangées de trois articles par page, un sélecteur
	de monnaie (yens/fragments ↔ Robux) et une pagination.
]]

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared.GameConfig)
local Remotes = require(Shared.Remotes)
local ShopCatalog = require(Shared.ShopCatalog)
local Util = require(Shared.Util)

local State = require(script.Parent.Parent.State)
local Theme = require(script.Parent.Theme)

local ITEMS_PER_PAGE = 6
local ROBUX_COLOR = Color3.fromRGB(120, 230, 140)

local player = Players.LocalPlayer

local Shop = {}
Shop.__index = Shop

function Shop.new(parent: ScreenGui)
	local self = setmetatable({}, Shop)

	self.mode = "jeu" -- "jeu" ou "robux"
	self.page = 1
	self.pageCount = math.max(1, math.ceil(#ShopCatalog.List / ITEMS_PER_PAGE))

	local root, content = Theme.window(parent, "BOUTIQUE", UDim2.fromOffset(880, 620))
	self.root = root

	------------------------------------------------------------------
	-- Sélecteur de monnaie + solde
	------------------------------------------------------------------
	local topBar = Theme.create("Frame", {
		Name = "Barre",
		Size = UDim2.new(1, 0, 0, 40),
		BackgroundTransparency = 1,
		ZIndex = 32,
		Parent = content,
	})

	local switch = Theme.create("Frame", {
		Name = "Monnaie",
		Size = UDim2.fromOffset(340, 36),
		BackgroundColor3 = Color3.fromRGB(14, 14, 22),
		BorderSizePixel = 0,
		ZIndex = 32,
		Parent = topBar,
	}, {
		Theme.corner(8),
		Theme.stroke(GameConfig.Palette.stroke, 1, 0.4),
		Theme.create("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			Padding = UDim.new(0, 4),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
		Theme.padding(4),
	})

	self.modeButtons = {}
	for index, definition in ipairs({
		{ mode = "jeu", label = "MONNAIE DU JEU" },
		{ mode = "robux", label = "ROBUX" },
	}) do
		local button = Theme.create("TextButton", {
			Name = definition.mode,
			Size = UDim2.fromOffset(163, 28),
			BackgroundColor3 = GameConfig.Palette.panelLight,
			BackgroundTransparency = 0.2,
			AutoButtonColor = true,
			Font = Theme.HeadingFont,
			Text = definition.label,
			TextSize = 13,
			TextColor3 = GameConfig.Palette.textDim,
			LayoutOrder = index,
			ZIndex = 33,
			Parent = switch,
		}, { Theme.corner(6) })

		button.Activated:Connect(function()
			self:setMode(definition.mode)
		end)

		self.modeButtons[definition.mode] = button
	end

	self.balance = Theme.create("TextLabel", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		Size = UDim2.fromOffset(400, 36),
		BackgroundTransparency = 1,
		Font = Theme.HeadingFont,
		Text = "",
		TextSize = 15,
		TextXAlignment = Enum.TextXAlignment.Right,
		TextColor3 = GameConfig.Currencies.yens.color,
		ZIndex = 32,
		Parent = topBar,
	})

	------------------------------------------------------------------
	-- Grille : 3 colonnes × 2 rangées
	------------------------------------------------------------------
	local grid = Theme.create("Frame", {
		Name = "Grille",
		Position = UDim2.fromOffset(0, 48),
		Size = UDim2.new(1, 0, 1, -96),
		BackgroundTransparency = 1,
		ZIndex = 32,
		Parent = content,
	}, {
		Theme.create("UIGridLayout", {
			CellSize = UDim2.new(0.32, 0, 0.46, 0),
			CellPadding = UDim2.new(0.02, 0, 0.08, 0),
			SortOrder = Enum.SortOrder.LayoutOrder,
			FillDirectionMaxCells = 3,
		}),
	})

	-- Séparateur horizontal entre les deux rangées. Il est posé sur le
	-- conteneur et non dans la grille : le UIGridLayout lui donnerait sinon
	-- une case à lui tout seul.
	Theme.create("Frame", {
		Name = "Séparateur",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(1, 0, 0, 1),
		BackgroundColor3 = GameConfig.Palette.stroke,
		BackgroundTransparency = 0.5,
		BorderSizePixel = 0,
		ZIndex = 31,
		Parent = content,
	})

	self.slots = {}
	for index = 1, ITEMS_PER_PAGE do
		local card = Theme.panel({
			Name = "Case" .. index,
			BackgroundTransparency = 0.15,
			LayoutOrder = index,
			ZIndex = 33,
			Parent = grid,
		})

		local category = Theme.create("TextLabel", {
			Position = UDim2.fromScale(0.05, 0.05),
			Size = UDim2.fromScale(0.5, 0.1),
			BackgroundTransparency = 1,
			Font = Theme.HeadingFont,
			Text = "",
			TextSize = 11,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextColor3 = GameConfig.Palette.textDim,
			ZIndex = 34,
			Parent = card,
		})

		local level = Theme.create("TextLabel", {
			Position = UDim2.fromScale(0.45, 0.05),
			Size = UDim2.fromScale(0.5, 0.1),
			BackgroundTransparency = 1,
			Font = Theme.BodyFont,
			Text = "",
			TextSize = 11,
			TextXAlignment = Enum.TextXAlignment.Right,
			TextColor3 = GameConfig.Palette.textDim,
			ZIndex = 34,
			Parent = card,
		})

		local name = Theme.create("TextLabel", {
			Position = UDim2.fromScale(0.05, 0.17),
			Size = UDim2.fromScale(0.9, 0.16),
			BackgroundTransparency = 1,
			Font = Theme.HeadingFont,
			Text = "",
			TextSize = 16,
			TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextColor3 = GameConfig.Palette.text,
			ZIndex = 34,
			Parent = card,
		})

		local description = Theme.create("TextLabel", {
			Position = UDim2.fromScale(0.05, 0.34),
			Size = UDim2.fromScale(0.9, 0.28),
			BackgroundTransparency = 1,
			Font = Theme.BodyFont,
			Text = "",
			TextSize = 12,
			TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Top,
			TextColor3 = GameConfig.Palette.textDim,
			ZIndex = 34,
			Parent = card,
		})

		local price = Theme.create("TextLabel", {
			Position = UDim2.fromScale(0.05, 0.63),
			Size = UDim2.fromScale(0.9, 0.13),
			BackgroundTransparency = 1,
			Font = Theme.TitleFont,
			Text = "",
			TextSize = 17,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextColor3 = GameConfig.Currencies.yens.color,
			ZIndex = 34,
			Parent = card,
		})

		local action = Theme.create("TextButton", {
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.fromScale(0.5, 0.94),
			Size = UDim2.fromScale(0.9, 0.18),
			BackgroundColor3 = GameConfig.Palette.accent,
			BackgroundTransparency = 0.15,
			AutoButtonColor = true,
			Font = Theme.HeadingFont,
			Text = "",
			TextSize = 14,
			TextColor3 = GameConfig.Palette.text,
			ZIndex = 34,
			Parent = card,
		}, { Theme.corner(6) })

		local slot = {
			card = card,
			category = category,
			level = level,
			name = name,
			description = description,
			price = price,
			action = action,
			item = nil :: any,
		}

		action.Activated:Connect(function()
			self:activate(slot)
		end)

		table.insert(self.slots, slot)
	end

	------------------------------------------------------------------
	-- Pagination
	------------------------------------------------------------------
	local footer = Theme.create("Frame", {
		Name = "Pagination",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, 0),
		Size = UDim2.new(1, 0, 0, 40),
		BackgroundTransparency = 1,
		ZIndex = 32,
		Parent = content,
	}, {
		Theme.create("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			Padding = UDim.new(0, 14),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})

	local function arrow(text: string, delta: number, order: number): TextButton
		local button = Theme.create("TextButton", {
			Size = UDim2.fromOffset(46, 32),
			BackgroundColor3 = GameConfig.Palette.panelLight,
			AutoButtonColor = true,
			Font = Theme.TitleFont,
			Text = text,
			TextSize = 18,
			TextColor3 = GameConfig.Palette.text,
			LayoutOrder = order,
			ZIndex = 33,
			Parent = footer,
		}, { Theme.corner(6) })

		button.Activated:Connect(function()
			self:setPage(self.page + delta)
		end)
		return button
	end

	arrow("‹", -1, 1)

	self.pageLabel = Theme.create("TextLabel", {
		Size = UDim2.fromOffset(160, 32),
		BackgroundTransparency = 1,
		Font = Theme.HeadingFont,
		Text = "",
		TextSize = 14,
		TextColor3 = GameConfig.Palette.textDim,
		LayoutOrder = 2,
		ZIndex = 33,
		Parent = footer,
	})

	arrow("›", 1, 3)

	State.observe(function()
		self:refresh()
	end)

	self:setMode("jeu")
	return self
end

function Shop:setMode(mode: string)
	self.mode = mode

	for name, button in pairs(self.modeButtons) do
		local active = name == mode
		button.BackgroundColor3 = if active
			then (if mode == "robux" then ROBUX_COLOR else GameConfig.Palette.accent)
			else GameConfig.Palette.panelLight
		button.BackgroundTransparency = if active then 0.1 else 0.4
		button.TextColor3 = if active then Color3.fromRGB(10, 10, 16) else GameConfig.Palette.textDim
	end

	self:refresh()
end

function Shop:setPage(page: number)
	self.page = math.clamp(page, 1, self.pageCount)
	self:refresh()
end

--- Achat ou équipement, selon la monnaie choisie et l'état de l'article.
function Shop:activate(slot: any)
	local item = slot.item
	local profile = State.profile
	if not item or not profile then
		return
	end

	if profile.owned[item.id] then
		-- Déjà possédé : le bouton sert alors à équiper ou retirer.
		if item.category == "arme" or item.category == "aura" then
			Remotes.event("EquipItem"):FireServer(item.id)
		end
		return
	end

	if self.mode == "robux" then
		if item.productId == 0 then
			slot.action.Text = "Produit non configuré"
			task.delay(2, function()
				self:refresh()
			end)
			return
		end
		local ok, err = pcall(function()
			MarketplaceService:PromptProductPurchase(player, item.productId)
		end)
		if not ok then
			warn("[Shop] " .. tostring(err))
		end
		return
	end

	slot.action.Text = "..."
	local ok, result = pcall(function()
		return Remotes.func("PurchaseItem"):InvokeServer(item.id)
	end)
	if not ok or not result or not result.ok then
		slot.action.Text = if ok and result and result.reason ~= "" then result.reason else "Erreur"
		task.delay(2, function()
			self:refresh()
		end)
	end
end

--- Remplit une case avec un article (ou la masque si la page est incomplète).
function Shop:bind(slot: any, item: any?)
	slot.item = item
	slot.card.Visible = item ~= nil
	if not item then
		return
	end

	local profile = State.profile
	local stroke = slot.card:FindFirstChildOfClass("UIStroke")
	if stroke then
		stroke.Color = item.color
		stroke.Transparency = 0.3
	end

	slot.category.Text = ShopCatalog.CategoryLabels[item.category] or ""
	slot.category.TextColor3 = item.color
	slot.level.Text = if item.requiredLevel > 1 then ("Niv. %d"):format(item.requiredLevel) else ""
	slot.name.Text = item.name
	slot.name.TextColor3 = item.color
	slot.description.Text = item.description

	if self.mode == "robux" then
		slot.price.Text = ("R$ %d"):format(item.robuxPrice)
		slot.price.TextColor3 = ROBUX_COLOR
	else
		slot.price.Text = ("%s %s"):format(
			Util.formatNumber(item.price),
			GameConfig.Currencies[item.currency].name
		)
		slot.price.TextColor3 = GameConfig.Currencies[item.currency].color
	end

	if not profile then
		slot.action.Text = "..."
		return
	end

	local owned = profile.owned[item.id] == true
	local equipped = profile.equipped.arme == item.id or profile.equipped.aura == item.id

	if equipped then
		slot.action.Text = "Équipé — retirer"
		slot.action.BackgroundColor3 = GameConfig.Palette.success
		slot.action.Active = true
	elseif owned then
		local equipable = item.category == "arme" or item.category == "aura"
		slot.action.Text = if equipable then "Équiper" else "Acquis"
		slot.action.BackgroundColor3 = GameConfig.Palette.panelLight
		slot.action.Active = equipable
	elseif profile.level < item.requiredLevel then
		slot.action.Text = ("Niveau %d requis"):format(item.requiredLevel)
		slot.action.BackgroundColor3 = GameConfig.Palette.panelLight
		slot.action.Active = false
	elseif self.mode == "robux" then
		if item.productId == 0 then
			slot.action.Text = "Bientôt en Robux"
			slot.action.BackgroundColor3 = GameConfig.Palette.panelLight
			slot.action.Active = false
		else
			slot.action.Text = ("Acheter — R$ %d"):format(item.robuxPrice)
			slot.action.BackgroundColor3 = ROBUX_COLOR
			slot.action.Active = true
		end
	elseif (profile.currencies[item.currency] or 0) < item.price then
		slot.action.Text = "Fonds insuffisants"
		slot.action.BackgroundColor3 = GameConfig.Palette.panelLight
		slot.action.Active = false
	else
		slot.action.Text = "Acheter"
		slot.action.BackgroundColor3 = item.color
		slot.action.Active = true
	end
end

function Shop:refresh()
	local profile = State.profile

	if profile then
		local suffix = if self.mode == "robux" then "   •   Paiement géré par Roblox" else ""
		self.balance.Text = ("%s yens   •   %s fragments%s"):format(
			Util.formatNumber(profile.currencies.yens),
			Util.formatNumber(profile.currencies.fragments),
			suffix
		)
	end

	self.pageLabel.Text = ("PAGE %d / %d"):format(self.page, self.pageCount)

	local offset = (self.page - 1) * ITEMS_PER_PAGE
	for index, slot in ipairs(self.slots) do
		self:bind(slot, ShopCatalog.List[offset + index])
	end
end

function Shop:toggle()
	self.root.Visible = not self.root.Visible
	if self.root.Visible then
		self:refresh()
	end
end

function Shop:setVisible(value: boolean)
	self.root.Visible = value
	if value then
		self:refresh()
	end
end

return Shop
