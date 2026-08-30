--!strict
--[[
	Credits
	Fenêtre « CRÉDIT » du menu : équipe, commandes et statistiques du joueur.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared.GameConfig)
local Util = require(Shared.Util)

local State = require(script.Parent.Parent.State)
local Theme = require(script.Parent.Theme)

local SECTIONS = {
	{
		title = "L'ÉQUIPE",
		body = "Conception & développement : toi.\nMoteur : Roblox / Luau.\nUnivers original inspiré des récits de sorciers et d'esprits maudits.",
	},
	{
		title = "COMMANDES",
		body = "Clic gauche — Poing Maudit\nE — Lame de Vide\nR — Éclat d'Âme\nF — Chaînes Funestes\nG — Domaine Restreint\nC — Statistiques   •   Q — Quêtes   •   B — Boutique   •   M — Menu",
	},
	{
		title = "COMMENT PROGRESSER",
		body = "Élimine les esprits de la zone d'entraînement pour tes premiers niveaux, puis franchis les portails de failles autour du hall. Chaque niveau octroie 3 points à répartir : Force, Agilité, Vitalité, Énergie.",
	},
}

local Credits = {}
Credits.__index = Credits

function Credits.new(parent: ScreenGui)
	local self = setmetatable({}, Credits)

	local root, content = Theme.window(parent, "CRÉDIT", UDim2.fromOffset(620, 540))
	self.root = root

	local scroll = Theme.create("ScrollingFrame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 6,
		ScrollBarImageColor3 = GameConfig.Palette.accent,
		ZIndex = 32,
		Parent = content,
	}, {
		Theme.create("UIListLayout", { Padding = UDim.new(0, 14), SortOrder = Enum.SortOrder.LayoutOrder }),
		Theme.create("UIPadding", { PaddingRight = UDim.new(0, 10) }),
	})

	Theme.create("TextLabel", {
		Size = UDim2.new(1, 0, 0, 40),
		BackgroundTransparency = 1,
		Font = Theme.TitleFont,
		Text = ("%s — v%s"):format(GameConfig.GameName, GameConfig.Version),
		TextSize = 22,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = GameConfig.Palette.accent,
		LayoutOrder = 0,
		ZIndex = 33,
		Parent = scroll,
	})

	for index, section in ipairs(SECTIONS) do
		local card = Theme.panel({
			Size = UDim2.new(1, 0, 0, 10),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 0.2,
			LayoutOrder = index,
			ZIndex = 33,
			Parent = scroll,
		})
		Theme.padding(14).Parent = card
		Theme.create("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = card })

		Theme.create("TextLabel", {
			Size = UDim2.new(1, 0, 0, 22),
			BackgroundTransparency = 1,
			Font = Theme.HeadingFont,
			Text = section.title,
			TextSize = 16,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextColor3 = GameConfig.Palette.accentSoft,
			LayoutOrder = 1,
			ZIndex = 34,
			Parent = card,
		})

		Theme.create("TextLabel", {
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			Font = Theme.BodyFont,
			Text = section.body,
			TextSize = 14,
			TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Top,
			TextColor3 = GameConfig.Palette.textDim,
			LayoutOrder = 2,
			ZIndex = 34,
			Parent = card,
		})
	end

	local statsCard = Theme.panel({
		Size = UDim2.new(1, 0, 0, 10),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 0.2,
		LayoutOrder = #SECTIONS + 1,
		ZIndex = 33,
		Parent = scroll,
	})
	Theme.padding(14).Parent = statsCard

	self.statsLabel = Theme.create("TextLabel", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Font = Theme.BodyFont,
		Text = "",
		TextSize = 14,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		TextColor3 = GameConfig.Palette.text,
		ZIndex = 34,
		Parent = statsCard,
	})

	State.observe(function(profile)
		local rank = GameConfig.rankForLevel(profile.level)
		self.statsLabel.Text = ("TON PARCOURS\nRang : %s (niveau %d)\nEsprits éliminés : %s\nFailles nettoyées : %d — meilleur rang : %s\nTemps de jeu : %d min")
			:format(
				rank.name,
				profile.level,
				Util.formatNumber(profile.totals.kills),
				profile.totals.riftsCleared,
				profile.bestRiftRank,
				math.floor(profile.playtime / 60)
			)
	end)

	return self
end

function Credits:toggle()
	self.root.Visible = not self.root.Visible
end

function Credits:setVisible(value: boolean)
	self.root.Visible = value
end

return Credits
