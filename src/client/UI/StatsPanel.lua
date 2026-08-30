--!strict
--[[
	StatsPanel
	Répartition des points, et récapitulatif des valeurs réelles calculées par
	le serveur.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared.GameConfig)
local Remotes = require(Shared.Remotes)
local Util = require(Shared.Util)

local State = require(script.Parent.Parent.State)
local Theme = require(script.Parent.Theme)

local Palette = GameConfig.Palette
local player = Players.LocalPlayer

local STAT_COLORS = {
	magie = Palette.accent,
	force = Palette.danger,
	vie = Palette.success,
	agilite = Palette.accentSoft,
}

local StatsPanel = {}
StatsPanel.__index = StatsPanel

function StatsPanel.new(parent: ScreenGui)
	local self = setmetatable({}, StatsPanel)

	local root, content = Theme.window(parent, "STATISTIQUES", UDim2.fromOffset(620, 600))
	self.root = root

	self.pointsLabel = Theme.create("TextLabel", {
		Size = UDim2.new(1, 0, 0, 24),
		BackgroundTransparency = 1,
		Font = Theme.HeadingFont,
		Text = "",
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = Palette.success,
		ZIndex = 32,
		Parent = content,
	})

	local list = Theme.create("Frame", {
		Position = UDim2.fromOffset(0, 32),
		Size = UDim2.new(1, 0, 0, 268),
		BackgroundTransparency = 1,
		ZIndex = 32,
		Parent = content,
	}, { Theme.list(Enum.FillDirection.Vertical, 10) })

	self.rows = {}
	for index, stat in ipairs(GameConfig.Stats) do
		local color = STAT_COLORS[stat.id] or Palette.accent

		local row = Theme.panel({
			Size = UDim2.new(1, 0, 0, 60),
			LayoutOrder = index,
			ZIndex = 32,
			Parent = list,
		}, { accent = color, brackets = false })

		-- Initiale de la statistique, dans un carré coloré.
		local initial = Theme.create("TextLabel", {
			Position = UDim2.fromOffset(12, 12),
			Size = UDim2.fromOffset(36, 36),
			BackgroundColor3 = color,
			BackgroundTransparency = 0.82,
			Font = Theme.NumberFont,
			Text = string.upper(string.sub(stat.name, 1, 1)),
			TextSize = 20,
			TextColor3 = color,
			BorderSizePixel = 0,
			ZIndex = 33,
			Parent = row,
		}, { Theme.corner(3), Theme.stroke(color, 1, 0.5) })

		Theme.create("TextLabel", {
			Position = UDim2.fromOffset(58, 10),
			Size = UDim2.new(0.5, 0, 0, 20),
			BackgroundTransparency = 1,
			Font = Theme.HeadingFont,
			Text = string.upper(stat.name),
			TextSize = 15,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextColor3 = Palette.text,
			ZIndex = 33,
			Parent = row,
		})

		Theme.create("TextLabel", {
			Position = UDim2.fromOffset(58, 30),
			Size = UDim2.new(0.62, 0, 0, 18),
			BackgroundTransparency = 1,
			Font = Theme.BodyFont,
			Text = stat.description,
			TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextColor3 = Palette.textDim,
			ZIndex = 33,
			Parent = row,
		})

		local value = Theme.create("TextLabel", {
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -56, 0.5, 0),
			Size = UDim2.fromOffset(70, 30),
			BackgroundTransparency = 1,
			Font = Theme.NumberFont,
			Text = "0",
			TextSize = 22,
			TextXAlignment = Enum.TextXAlignment.Right,
			TextColor3 = color,
			ZIndex = 33,
			Parent = row,
		})

		local plus = Theme.button("+", color, {
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -12, 0.5, 0),
			Size = UDim2.fromOffset(38, 38),
			TextSize = 20,
			ZIndex = 33,
			Parent = row,
		})

		plus.Activated:Connect(function()
			Remotes.event("SpendStatPoint"):FireServer(stat.id, 1)
			-- Retour immédiat : le carré pulse même avant la réponse serveur.
			TweenService:Create(initial, TweenInfo.new(0.12), { BackgroundTransparency = 0.5 }):Play()
			task.delay(0.14, function()
				TweenService:Create(initial, TweenInfo.new(0.2), { BackgroundTransparency = 0.82 }):Play()
			end)
		end)

		self.rows[stat.id] = { value = value, plus = plus }
	end

	------------------------------------------------------------------
	-- Récapitulatif en tuiles
	------------------------------------------------------------------
	Theme.create("TextLabel", {
		Position = UDim2.fromOffset(0, 310),
		Size = UDim2.new(1, 0, 0, 20),
		BackgroundTransparency = 1,
		Font = Theme.DisplayFont,
		Text = "VALEURS RÉELLES",
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = Palette.textFaint,
		ZIndex = 32,
		Parent = content,
	})

	local tiles = Theme.create("Frame", {
		Position = UDim2.fromOffset(0, 334),
		Size = UDim2.new(1, 0, 0, 150),
		BackgroundTransparency = 1,
		ZIndex = 32,
		Parent = content,
	}, {
		Theme.create("UIGridLayout", {
			CellSize = UDim2.new(0.32, 0, 0, 62),
			CellPadding = UDim2.new(0.02, 0, 0, 10),
			SortOrder = Enum.SortOrder.LayoutOrder,
			FillDirectionMaxCells = 3,
		}),
	})

	self.tiles = {}
	for index, definition in ipairs({
		{ id = "physique", caption = "DÉGÂTS PHYSIQUES", color = Palette.danger },
		{ id = "magique", caption = "DÉGÂTS DE TECHNIQUE", color = Palette.accent },
		{ id = "energie", caption = "MAGIE MAXIMALE", color = Palette.accentSoft },
		{ id = "vitesse", caption = "VITESSE", color = Palette.success },
		{ id = "recharge", caption = "RÉDUCTION DE RECHARGE", color = Palette.gold },
		{ id = "kills", caption = "ESPRITS ÉLIMINÉS", color = Palette.textDim },
	}) do
		local tile = Theme.panel({
			LayoutOrder = index,
			ZIndex = 32,
			Parent = tiles,
		}, { accent = definition.color, brackets = false })

		local value = Theme.create("TextLabel", {
			Position = UDim2.fromScale(0, 0.12),
			Size = UDim2.fromScale(1, 0.45),
			BackgroundTransparency = 1,
			Font = Theme.NumberFont,
			Text = "0",
			TextScaled = true,
			TextColor3 = definition.color,
			ZIndex = 33,
			Parent = tile,
		})

		Theme.create("TextLabel", {
			Position = UDim2.fromScale(0.05, 0.62),
			Size = UDim2.fromScale(0.9, 0.26),
			BackgroundTransparency = 1,
			Font = Theme.BodyFont,
			Text = definition.caption,
			TextScaled = true,
			TextColor3 = Palette.textFaint,
			ZIndex = 33,
			Parent = tile,
		})

		self.tiles[definition.id] = value
	end

	self.footer = Theme.create("TextLabel", {
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 0, 1, 0),
		Size = UDim2.new(1, 0, 0, 36),
		BackgroundTransparency = 1,
		Font = Theme.BodyFont,
		Text = "",
		TextSize = 12,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		TextColor3 = Palette.textDim,
		ZIndex = 32,
		Parent = content,
	})

	local function refresh()
		local profile = State.profile
		if not profile then
			return
		end

		local points = profile.statPoints
		self.pointsLabel.Text = if points > 0
			then ("%d POINT(S) À RÉPARTIR"):format(points)
			else "Aucun point disponible — monte de niveau pour en gagner."
		self.pointsLabel.TextColor3 = if points > 0 then Palette.success else Palette.textDim

		for statId, row in pairs(self.rows) do
			row.value.Text = tostring(profile.stats[statId] or 0)
			row.plus.Visible = points > 0
		end

		self.tiles.physique.Text = tostring(player:GetAttribute("Degats") or 0)
		self.tiles.magique.Text = tostring(player:GetAttribute("DegatsMagie") or 0)
		self.tiles.energie.Text = tostring(player:GetAttribute("EnergieMax") or 0)
		self.tiles.vitesse.Text = string.format("%.1f", player:GetAttribute("Vitesse") or GameConfig.BaseWalkSpeed)
		self.tiles.recharge.Text = ("%d%%"):format(math.floor((player:GetAttribute("ReductionCooldown") or 0) * 100))
		self.tiles.kills.Text = Util.formatNumber(profile.totals.kills)

		local rank = GameConfig.rankForLevel(profile.level)
		self.footer.Text = ("Rang %s — niveau %d   •   Failles nettoyées : %d (meilleur rang %s)")
			:format(rank.name, profile.level, profile.totals.riftsCleared, profile.bestRiftRank)
	end

	State.observe(refresh)
	for _, attribute in ipairs({ "Degats", "DegatsMagie", "EnergieMax", "Vitesse", "ReductionCooldown" }) do
		player:GetAttributeChangedSignal(attribute):Connect(refresh)
	end

	return self
end

function StatsPanel:toggle()
	self.root.Visible = not self.root.Visible
end

function StatsPanel:setVisible(value: boolean)
	self.root.Visible = value
end

return StatsPanel
