--!strict
--[[
	StatsPanel
	Répartition des points de statistique, façon fenêtre du « Système ».
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared.GameConfig)
local Remotes = require(Shared.Remotes)
local Util = require(Shared.Util)

local State = require(script.Parent.Parent.State)
local Theme = require(script.Parent.Theme)

local player = Players.LocalPlayer

local StatsPanel = {}
StatsPanel.__index = StatsPanel

function StatsPanel.new(parent: ScreenGui)
	local self = setmetatable({}, StatsPanel)

	local root, content = Theme.window(parent, "STATISTIQUES", UDim2.fromOffset(560, 520))
	self.root = root

	self.pointsLabel = Theme.create("TextLabel", {
		Size = UDim2.new(1, 0, 0, 26),
		BackgroundTransparency = 1,
		Font = Theme.HeadingFont,
		Text = "Points disponibles : 0",
		TextSize = 16,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = GameConfig.Palette.success,
		ZIndex = 32,
		Parent = content,
	})

	local list = Theme.create("Frame", {
		Position = UDim2.fromOffset(0, 36),
		Size = UDim2.new(1, 0, 1, -130),
		BackgroundTransparency = 1,
		ZIndex = 32,
		Parent = content,
	}, {
		Theme.create("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder }),
	})

	self.rows = {}
	for index, stat in ipairs(GameConfig.Stats) do
		local row = Theme.panel({
			Size = UDim2.new(1, 0, 0, 62),
			BackgroundTransparency = 0.2,
			LayoutOrder = index,
			ZIndex = 32,
			Parent = list,
		})
		Theme.padding(10).Parent = row

		local name = Theme.create("TextLabel", {
			Size = UDim2.new(0.5, 0, 0, 20),
			BackgroundTransparency = 1,
			Font = Theme.HeadingFont,
			Text = stat.name,
			TextSize = 16,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextColor3 = GameConfig.Palette.text,
			ZIndex = 33,
			Parent = row,
		})

		Theme.create("TextLabel", {
			Position = UDim2.fromOffset(0, 22),
			Size = UDim2.new(0.7, 0, 0, 18),
			BackgroundTransparency = 1,
			Font = Theme.BodyFont,
			Text = stat.description,
			TextSize = 13,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextColor3 = GameConfig.Palette.textDim,
			ZIndex = 33,
			Parent = row,
		})

		local value = Theme.create("TextLabel", {
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -50, 0.5, 0),
			Size = UDim2.fromOffset(70, 30),
			BackgroundTransparency = 1,
			Font = Theme.TitleFont,
			Text = "0",
			TextSize = 22,
			TextXAlignment = Enum.TextXAlignment.Right,
			TextColor3 = GameConfig.Palette.accent,
			ZIndex = 33,
			Parent = row,
		})

		local plus = Theme.create("TextButton", {
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, 0, 0.5, 0),
			Size = UDim2.fromOffset(38, 38),
			BackgroundColor3 = GameConfig.Palette.accent,
			BackgroundTransparency = 0.2,
			AutoButtonColor = true,
			Font = Theme.TitleFont,
			Text = "+",
			TextSize = 22,
			TextColor3 = GameConfig.Palette.text,
			ZIndex = 33,
			Parent = row,
		}, { Theme.corner(8) })

		plus.Activated:Connect(function()
			Remotes.event("SpendStatPoint"):FireServer(stat.id, 1)
		end)

		self.rows[stat.id] = { value = value, plus = plus, name = name }
	end

	self.summary = Theme.create("TextLabel", {
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 0, 1, 0),
		Size = UDim2.new(1, 0, 0, 80),
		BackgroundTransparency = 1,
		Font = Theme.BodyFont,
		Text = "",
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		TextColor3 = GameConfig.Palette.textDim,
		ZIndex = 32,
		Parent = content,
	})

	local function refresh()
		local profile = State.profile
		if not profile then
			return
		end

		self.pointsLabel.Text = ("Points disponibles : %d"):format(profile.statPoints)
		for statId, row in pairs(self.rows) do
			row.value.Text = tostring(profile.stats[statId] or 0)
			row.plus.Visible = profile.statPoints > 0
		end

		local rank = GameConfig.rankForLevel(profile.level)
		self.summary.Text = ("Rang : %s   •   Dégâts : %d   •   Énergie max : %d   •   Vitesse : %.1f\nRéduction de recharge : %d%%   •   Éliminations : %s   •   Failles nettoyées : %d (meilleur rang %s)")
			:format(
				rank.name,
				player:GetAttribute("Degats") or 0,
				player:GetAttribute("EnergieMax") or 0,
				player:GetAttribute("Vitesse") or GameConfig.BaseWalkSpeed,
				math.floor((player:GetAttribute("ReductionCooldown") or 0) * 100),
				Util.formatNumber(profile.totals.kills),
				profile.totals.riftsCleared,
				profile.bestRiftRank
			)
	end

	State.observe(refresh)
	for _, attribute in ipairs({ "Degats", "EnergieMax", "Vitesse", "ReductionCooldown" }) do
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
