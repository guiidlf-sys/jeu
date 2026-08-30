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
		ScrollBarThickness = 6,
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
			Size = UDim2.new(1, 0, 0, 108),
			BackgroundTransparency = 0.2,
			LayoutOrder = index,
			ZIndex = 33,
			Parent = scroll,
		})
		Theme.padding(14).Parent = card

		local stroke = card:FindFirstChildOfClass("UIStroke")
		if stroke then
			stroke.Color = rift.color
		end

		Theme.create("TextLabel", {
			Size = UDim2.fromOffset(70, 44),
			BackgroundColor3 = rift.color,
			BackgroundTransparency = 0.75,
			Font = Theme.TitleFont,
			Text = rift.rank,
			TextSize = 28,
			TextColor3 = rift.color,
			ZIndex = 34,
			Parent = card,
		}, { Theme.corner(8) })

		Theme.create("TextLabel", {
			Position = UDim2.fromOffset(84, 0),
			Size = UDim2.new(0.6, 0, 0, 24),
			BackgroundTransparency = 1,
			Font = Theme.HeadingFont,
			Text = rift.name,
			TextSize = 18,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextColor3 = rift.color,
			ZIndex = 34,
			Parent = card,
		})

		Theme.create("TextLabel", {
			Position = UDim2.fromOffset(84, 24),
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

		local enter = Theme.create("TextButton", {
			AnchorPoint = Vector2.new(1, 1),
			Position = UDim2.new(1, 0, 1, 0),
			Size = UDim2.fromOffset(190, 38),
			BackgroundColor3 = rift.color,
			BackgroundTransparency = 0.2,
			AutoButtonColor = true,
			Font = Theme.HeadingFont,
			Text = "Entrer",
			TextSize = 15,
			TextColor3 = Color3.fromRGB(10, 10, 16),
			ZIndex = 34,
			Parent = card,
		}, { Theme.corner(6) })

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
			row.enter.Text = if locked then ("Niveau %d requis"):format(row.rift.minLevel) else "Entrer"
			row.enter.BackgroundColor3 = if locked then GameConfig.Palette.panelLight else row.rift.color
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
