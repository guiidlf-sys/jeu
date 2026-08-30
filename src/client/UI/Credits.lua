--!strict
--[[
	Credits
	Fenêtre « CRÉDIT » : l'équipe, les commandes, la façon de progresser, et
	le parcours du joueur.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared.GameConfig)
local Util = require(Shared.Util)

local State = require(script.Parent.Parent.State)
local Theme = require(script.Parent.Theme)

local Palette = GameConfig.Palette

local SECTIONS = {
	{
		title = "L'ÉQUIPE",
		accent = Palette.accent,
		body = "Conception & développement : toi.\nMoteur : Roblox / Luau.\nUnivers original inspiré des récits de sorciers et d'esprits maudits.",
	},
	{
		title = "COMBAT",
		accent = Palette.danger,
		body = "Clic gauche — Poing Maudit (Force)\nE — Lame de Vide\nR — Éclat d'Âme\nF — Chaînes Funestes\nG — Domaine Restreint\n\nLes techniques puisent dans la Magie, l'attaque de base dans la Force.",
	},
	{
		title = "INTERFACE",
		accent = Palette.accentSoft,
		body = "C — Statistiques\nQ — Quêtes & contrats\nJ — Donjons\nB — Boutique\nM — Menu principal\nE — Parler à un PNJ",
	},
	{
		title = "COMMENT PROGRESSER",
		accent = Palette.success,
		body = "Le hall est une zone sûre : cinq PNJ t'y attendent, dont Maître Renzo qui t'indique toujours ta prochaine étape. Traverse le pont au nord pour t'entraîner, puis lance-toi dans les failles.\n\nLes esprits sont passifs : ils n'attaquent que si tu les frappes, ou si tu as signé un contrat sur leur espèce.\n\nChaque niveau octroie 3 points : MAGIE, FORCE, VIE, AGILITÉ.",
	},
}

local Credits = {}
Credits.__index = Credits

function Credits.new(parent: ScreenGui)
	local self = setmetatable({}, Credits)

	local root, content = Theme.window(parent, "CRÉDIT", UDim2.fromOffset(660, 580))
	self.root = root

	local scroll = Theme.create("ScrollingFrame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 4,
		ScrollBarImageColor3 = Palette.accent,
		ZIndex = 32,
		Parent = content,
	}, {
		Theme.list(Enum.FillDirection.Vertical, 12),
		Theme.create("UIPadding", { PaddingRight = UDim.new(0, 12) }),
	})

	local header = Theme.create("Frame", {
		Size = UDim2.new(1, 0, 0, 54),
		BackgroundTransparency = 1,
		LayoutOrder = 0,
		ZIndex = 33,
		Parent = scroll,
	})

	Theme.create("TextLabel", {
		Size = UDim2.new(1, 0, 0, 30),
		BackgroundTransparency = 1,
		Font = Theme.TitleFont,
		Text = GameConfig.GameName,
		TextSize = 24,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = Palette.text,
		ZIndex = 34,
		Parent = header,
	})

	Theme.create("TextLabel", {
		Position = UDim2.fromOffset(0, 30),
		Size = UDim2.new(1, 0, 0, 18),
		BackgroundTransparency = 1,
		Font = Theme.BodyFont,
		Text = ("version %s   •   un jeu de sorcellerie et de failles"):format(GameConfig.Version),
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = Palette.textDim,
		ZIndex = 34,
		Parent = header,
	})

	for index, section in ipairs(SECTIONS) do
		local card = Theme.panel({
			Size = UDim2.new(1, 0, 0, 10),
			AutomaticSize = Enum.AutomaticSize.Y,
			LayoutOrder = index,
			ZIndex = 33,
			Parent = scroll,
		}, { accent = section.accent, brackets = false })

		Theme.create("Frame", {
			Name = "Accent",
			Size = UDim2.new(0, 2, 1, 0),
			BackgroundColor3 = section.accent,
			BorderSizePixel = 0,
			ZIndex = 34,
			Parent = card,
		})

		local cardContent = Theme.create("Frame", {
			Name = "Contenu",
			Size = UDim2.new(1, 0, 0, 10),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			ZIndex = 34,
			Parent = card,
		}, { Theme.list(Enum.FillDirection.Vertical, 6), Theme.padding(14, 18) })

		Theme.create("TextLabel", {
			Size = UDim2.new(1, 0, 0, 20),
			BackgroundTransparency = 1,
			Font = Theme.DisplayFont,
			Text = section.title,
			TextSize = 14,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextColor3 = section.accent,
			LayoutOrder = 1,
			ZIndex = 35,
			Parent = cardContent,
		})

		Theme.create("TextLabel", {
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			Font = Theme.BodyFont,
			Text = section.body,
			TextSize = 13,
			TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Top,
			TextColor3 = Palette.textDim,
			LayoutOrder = 2,
			ZIndex = 35,
			Parent = cardContent,
		})
	end

	local statsCard = Theme.panel({
		Size = UDim2.new(1, 0, 0, 10),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = #SECTIONS + 1,
		ZIndex = 33,
		Parent = scroll,
	}, { accent = Palette.gold, brackets = true })

	local statsContent = Theme.create("Frame", {
		Name = "Contenu",
		Size = UDim2.new(1, 0, 0, 10),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		ZIndex = 34,
		Parent = statsCard,
	}, { Theme.list(Enum.FillDirection.Vertical, 6), Theme.padding(14, 18) })

	Theme.create("TextLabel", {
		Size = UDim2.new(1, 0, 0, 20),
		BackgroundTransparency = 1,
		Font = Theme.DisplayFont,
		Text = "TON PARCOURS",
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = Palette.gold,
		LayoutOrder = 1,
		ZIndex = 35,
		Parent = statsContent,
	})

	self.statsLabel = Theme.create("TextLabel", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Font = Theme.BodyFont,
		Text = "",
		TextSize = 13,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		TextColor3 = Palette.text,
		LayoutOrder = 2,
		ZIndex = 35,
		Parent = statsContent,
	})

	State.observe(function(profile)
		local rank = GameConfig.rankForLevel(profile.level)
		self.statsLabel.Text = ("Rang : %s (niveau %d)\nEsprits éliminés : %s\nFailles nettoyées : %d — meilleur rang : %s\nTemps de jeu : %d minutes")
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
