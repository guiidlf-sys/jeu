--!strict
--[[
	DungeonList
	Registre des failles : accessible depuis le menu JOUER → DONJONS et depuis
	l'archiviste du hall. Entrer ferme le menu et téléporte le joueur.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared.GameConfig)
local Remotes = require(Shared.Remotes)
local RiftCatalog = require(Shared.RiftCatalog)
local Util = require(Shared.Util)

local State = require(script.Parent.Parent.State)
local Theme = require(script.Parent.Theme)

local DungeonList = {}
DungeonList.__index = DungeonList

--- `onEnter` est appelé juste avant l'entrée, pour refermer le menu.
function DungeonList.new(parent: ScreenGui, onEnter: (() -> ())?)
	local self = setmetatable({}, DungeonList)

	local root, content = Theme.window(parent, "DONJONS", UDim2.fromOffset(720, 560))
	self.root = root

	Theme.create("TextLabel", {
		Size = UDim2.new(1, 0, 0, 24),
		BackgroundTransparency = 1,
		Font = Theme.BodyFont,
		Text = "Trois vagues par faille. Tu peux abandonner à tout moment, mais sans récompense.",
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = GameConfig.Palette.textDim,
		ZIndex = 32,
		Parent = content,
	})

	local scroll = Theme.create("ScrollingFrame", {
		Position = UDim2.fromOffset(0, 32),
		Size = UDim2.new(1, 0, 1, -32),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 4,
		ScrollBarImageColor3 = GameConfig.Palette.accent,
		ZIndex = 32,
		Parent = content,
	}, {
		Theme.create("UIListLayout", { Padding = UDim.new(0, 12), SortOrder = Enum.SortOrder.LayoutOrder }),
		Theme.create("UIPadding", { PaddingRight = UDim.new(0, 10) }),
	})

	self.rows = {}
	for index, rift in ipairs(RiftCatalog.List) do
		local card = Theme.panel({
			Size = UDim2.new(1, 0, 0, 112),
			LayoutOrder = index,
			ZIndex = 33,
			Parent = scroll,
		}, { accent = rift.color, brackets = true })
		Theme.padding(14, 16).Parent = card

		-- Écusson de rang.
		Theme.create("TextLabel", {
			Size = UDim2.fromOffset(62, 46),
			BackgroundColor3 = rift.color,
			BackgroundTransparency = 0.82,
			Font = Theme.NumberFont,
			Text = rift.rank,
			TextSize = 26,
			TextColor3 = rift.color,
			BorderSizePixel = 0,
			ZIndex = 34,
			Parent = card,
		}, { Theme.corner(3), Theme.stroke(rift.color, 1, 0.4) })

		Theme.create("TextLabel", {
			Position = UDim2.fromOffset(76, 0),
			Size = UDim2.new(0.6, 0, 0, 24),
			BackgroundTransparency = 1,
			Font = Theme.DisplayFont,
			Text = rift.name,
			TextSize = 18,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextColor3 = rift.color,
			ZIndex = 34,
			Parent = card,
		})

		Theme.create("TextLabel", {
			Position = UDim2.fromOffset(76, 26),
			Size = UDim2.new(0.6, 0, 0, 20),
			BackgroundTransparency = 1,
			Font = Theme.BodyFont,
			Text = ("Niveau %d requis — %d vagues"):format(rift.minLevel, #rift.waves),
			TextSize = 13,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextColor3 = GameConfig.Palette.textDim,
			ZIndex = 34,
			Parent = card,
		})

		Theme.create("TextLabel", {
			Position = UDim2.fromOffset(0, 56),
			Size = UDim2.new(0.62, 0, 0, 20),
			BackgroundTransparency = 1,
			Font = Theme.BodyFont,
			Text = ("Récompenses : %s yens • %d fragments • %s XP")
				:format(Util.formatNumber(rift.rewards.yens), rift.rewards.fragments, Util.formatNumber(rift.rewards.xp)),
			TextSize = 13,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextColor3 = GameConfig.Currencies.yens.color,
			ZIndex = 34,
			Parent = card,
		})

		local enter = Theme.button("ENTRER DANS LA FAILLE", rift.color, {
			AnchorPoint = Vector2.new(1, 1),
			Position = UDim2.new(1, 0, 1, 0),
			Size = UDim2.fromOffset(230, 34),
			TextSize = 13,
			ZIndex = 34,
			Parent = card,
		})

		enter.Activated:Connect(function()
			local profile = State.profile
			if profile and profile.level < rift.minLevel then
				return
			end
			self.root.Visible = false
			if onEnter then
				onEnter()
			end
			task.wait(0.2)
			Remotes.event("EnterRift"):FireServer(rift.id)
		end)

		self.rows[rift.id] = { rift = rift, enter = enter }
	end

	State.observe(function(profile)
		for _, row in pairs(self.rows) do
			local locked = profile.level < row.rift.minLevel
			row.enter.Text = if locked
				then ("NIVEAU %d REQUIS"):format(row.rift.minLevel)
				else "ENTRER DANS LA FAILLE"
			row.enter.BackgroundColor3 = if locked then GameConfig.Palette.panelLight else row.rift.color
			row.enter.BackgroundTransparency = if locked then 0.4 else 0.25
			row.enter.TextColor3 = if locked then GameConfig.Palette.textDim else GameConfig.Palette.text
			row.enter.Active = not locked
		end
	end)

	return self
end

function DungeonList:toggle()
	self.root.Visible = not self.root.Visible
end

function DungeonList:setVisible(value: boolean)
	self.root.Visible = value
end

return DungeonList
