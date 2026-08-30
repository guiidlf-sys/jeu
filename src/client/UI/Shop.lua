--!strict
--[[
	Shop
	Boutique accessible depuis le menu principal et depuis le HUD (touche B).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared.GameConfig)
local Remotes = require(Shared.Remotes)
local ShopCatalog = require(Shared.ShopCatalog)
local Util = require(Shared.Util)

local State = require(script.Parent.Parent.State)
local Theme = require(script.Parent.Theme)

local CATEGORY_LABELS = {
	arme = "ARMES",
	aura = "AURAS",
	consommable = "RELIQUES",
}

local Shop = {}
Shop.__index = Shop

function Shop.new(parent: ScreenGui)
	local self = setmetatable({}, Shop)

	local root, content = Theme.window(parent, "BOUTIQUE", UDim2.fromOffset(760, 560))
	self.root = root

	self.balance = Theme.create("TextLabel", {
		Size = UDim2.new(1, 0, 0, 24),
		BackgroundTransparency = 1,
		Font = Theme.HeadingFont,
		Text = "0 yens • 0 fragments",
		TextSize = 15,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = GameConfig.Currencies.yens.color,
		ZIndex = 32,
		Parent = content,
	})

	local scroll = Theme.create("ScrollingFrame", {
		Position = UDim2.fromOffset(0, 34),
		Size = UDim2.new(1, 0, 1, -34),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 6,
		ScrollBarImageColor3 = GameConfig.Palette.accent,
		ZIndex = 32,
		Parent = content,
	}, {
		Theme.create("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder }),
		Theme.create("UIPadding", { PaddingRight = UDim.new(0, 10) }),
	})

	self.cards = {}

	-- Regroupement par catégorie, dans l'ordre du catalogue.
	local order = 0
	for _, category in ipairs({ "arme", "aura", "consommable" }) do
		order += 1
		Theme.create("TextLabel", {
			Size = UDim2.new(1, 0, 0, 26),
			BackgroundTransparency = 1,
			Font = Theme.TitleFont,
			Text = CATEGORY_LABELS[category],
			TextSize = 16,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextColor3 = GameConfig.Palette.accentSoft,
			LayoutOrder = order,
			ZIndex = 33,
			Parent = scroll,
		})

		for _, item in ipairs(ShopCatalog.List) do
			if item.category ~= category then
				continue
			end

			order += 1
			local card = Theme.panel({
				Size = UDim2.new(1, 0, 0, 92),
				BackgroundTransparency = 0.2,
				LayoutOrder = order,
				ZIndex = 33,
				Parent = scroll,
			})
			Theme.padding(12).Parent = card

			Theme.create("Frame", {
				Size = UDim2.fromOffset(6, 68),
				Position = UDim2.fromOffset(-4, 0),
				BackgroundColor3 = item.color,
				BorderSizePixel = 0,
				ZIndex = 34,
				Parent = card,
			}, { Theme.corner(3) })

			Theme.create("TextLabel", {
				Position = UDim2.fromOffset(12, 0),
				Size = UDim2.new(0.6, 0, 0, 22),
				BackgroundTransparency = 1,
				Font = Theme.HeadingFont,
				Text = item.name,
				TextSize = 17,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextColor3 = item.color,
				ZIndex = 34,
				Parent = card,
			})

			Theme.create("TextLabel", {
				Position = UDim2.fromOffset(12, 24),
				Size = UDim2.new(0.62, 0, 0, 36),
				BackgroundTransparency = 1,
				Font = Theme.BodyFont,
				Text = item.description,
				TextSize = 13,
				TextWrapped = true,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = Enum.TextYAlignment.Top,
				TextColor3 = GameConfig.Palette.textDim,
				ZIndex = 34,
				Parent = card,
			})

			local price = Theme.create("TextLabel", {
				AnchorPoint = Vector2.new(1, 0),
				Position = UDim2.new(1, 0, 0, 0),
				Size = UDim2.fromOffset(220, 22),
				BackgroundTransparency = 1,
				Font = Theme.HeadingFont,
				Text = ("%s %s"):format(Util.formatNumber(item.price), GameConfig.Currencies[item.currency].name),
				TextSize = 15,
				TextXAlignment = Enum.TextXAlignment.Right,
				TextColor3 = GameConfig.Currencies[item.currency].color,
				ZIndex = 34,
				Parent = card,
			})

			local action = Theme.create("TextButton", {
				AnchorPoint = Vector2.new(1, 1),
				Position = UDim2.new(1, 0, 1, 0),
				Size = UDim2.fromOffset(180, 34),
				BackgroundColor3 = GameConfig.Palette.accent,
				BackgroundTransparency = 0.15,
				AutoButtonColor = true,
				Font = Theme.HeadingFont,
				Text = "Acheter",
				TextSize = 14,
				TextColor3 = GameConfig.Palette.text,
				ZIndex = 34,
				Parent = card,
			}, { Theme.corner(6) })

			action.Activated:Connect(function()
				local profile = State.profile
				if profile and profile.owned[item.id] then
					Remotes.event("EquipItem"):FireServer(item.id)
					return
				end

				action.Text = "..."
				local ok, result = pcall(function()
					return Remotes.func("PurchaseItem"):InvokeServer(item.id)
				end)
				if not ok or not result or not result.ok then
					action.Text = if ok and result then result.reason else "Erreur"
					task.delay(1.8, function()
						action.Text = "Acheter"
					end)
				end
			end)

			self.cards[item.id] = { item = item, action = action, price = price }
		end
	end

	State.observe(function(profile)
		self.balance.Text = ("%s yens   •   %s fragments"):format(
			Util.formatNumber(profile.currencies.yens),
			Util.formatNumber(profile.currencies.fragments)
		)

		for itemId, card in pairs(self.cards) do
			local item = card.item
			local owned = profile.owned[itemId] == true
			local equipped = profile.equipped.arme == itemId or profile.equipped.aura == itemId

			if equipped then
				card.action.Text = "Équipé — retirer"
				card.action.BackgroundColor3 = GameConfig.Palette.success
			elseif owned then
				card.action.Text = if item.category == "consommable" then "Acquis" else "Équiper"
				card.action.BackgroundColor3 = GameConfig.Palette.panelLight
			elseif profile.level < item.requiredLevel then
				card.action.Text = ("Niveau %d requis"):format(item.requiredLevel)
				card.action.BackgroundColor3 = GameConfig.Palette.panelLight
			elseif (profile.currencies[item.currency] or 0) < item.price then
				card.action.Text = "Fonds insuffisants"
				card.action.BackgroundColor3 = GameConfig.Palette.panelLight
			else
				card.action.Text = "Acheter"
				card.action.BackgroundColor3 = GameConfig.Palette.accent
			end
		end
	end)

	return self
end

function Shop:toggle()
	self.root.Visible = not self.root.Visible
end

function Shop:setVisible(value: boolean)
	self.root.Visible = value
end

return Shop
