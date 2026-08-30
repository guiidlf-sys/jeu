--!strict
--[[
	Dialogue
	Boîte de dialogue des PNJ de la zone sûre : les répliques défilent, puis un
	bouton d'action ouvre la fenêtre correspondante (stats, boutique, donjons).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared.GameConfig)
local Guide = require(Shared.Guide)
local NpcCatalog = require(Shared.NpcCatalog)
local Remotes = require(Shared.Remotes)

local State = require(script.Parent.Parent.State)
local Theme = require(script.Parent.Theme)

local Dialogue = {}
Dialogue.__index = Dialogue

--- `actions` associe l'action d'un PNJ à la fenêtre à ouvrir.
function Dialogue.new(parent: ScreenGui, actions: { [string]: () -> () })
	local self = setmetatable({}, Dialogue)

	self.actions = actions
	self.lines = {} :: { string }
	self.index = 1
	self.npc = nil :: any

	local root = Theme.create("Frame", {
		Name = "Dialogue",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -18),
		Size = UDim2.fromOffset(760, 210),
		BackgroundTransparency = 1,
		Visible = false,
		ZIndex = 35,
		Parent = parent,
	})
	self.root = root

	local box = Theme.panel({
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 0.05,
		ZIndex = 35,
		Parent = root,
	})
	Theme.padding(18).Parent = box
	self.box = box

	self.nameLabel = Theme.create("TextLabel", {
		Size = UDim2.new(1, 0, 0, 24),
		BackgroundTransparency = 1,
		Font = Theme.TitleFont,
		Text = "",
		TextSize = 20,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = GameConfig.Palette.accent,
		ZIndex = 36,
		Parent = box,
	})

	self.roleLabel = Theme.create("TextLabel", {
		Position = UDim2.fromOffset(0, 24),
		Size = UDim2.new(1, 0, 0, 18),
		BackgroundTransparency = 1,
		Font = Theme.BodyFont,
		Text = "",
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = GameConfig.Palette.textDim,
		ZIndex = 36,
		Parent = box,
	})

	self.textLabel = Theme.create("TextLabel", {
		Position = UDim2.fromOffset(0, 50),
		Size = UDim2.new(1, 0, 0, 78),
		BackgroundTransparency = 1,
		Font = Theme.BodyFont,
		Text = "",
		TextSize = 16,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		TextColor3 = GameConfig.Palette.text,
		ZIndex = 36,
		Parent = box,
	})

	local buttons = Theme.create("Frame", {
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, 0, 1, 0),
		Size = UDim2.new(1, 0, 0, 38),
		BackgroundTransparency = 1,
		ZIndex = 36,
		Parent = box,
	}, {
		Theme.create("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Right,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			Padding = UDim.new(0, 10),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})

	local function makeButton(text: string, color: Color3, order: number): TextButton
		return Theme.create("TextButton", {
			Size = UDim2.fromOffset(240, 34),
			BackgroundColor3 = color,
			BackgroundTransparency = 0.15,
			AutoButtonColor = true,
			Font = Theme.HeadingFont,
			Text = text,
			TextSize = 14,
			TextColor3 = GameConfig.Palette.text,
			LayoutOrder = order,
			ZIndex = 37,
			Parent = buttons,
		}, { Theme.corner(6) })
	end

	self.closeButton = makeButton("Fermer", GameConfig.Palette.panelLight, 1)
	self.actionButton = makeButton("", GameConfig.Palette.accent, 2)
	self.nextButton = makeButton("Suivant ▸", GameConfig.Palette.accentSoft, 3)

	self.closeButton.Activated:Connect(function()
		self:close()
	end)

	self.nextButton.Activated:Connect(function()
		self:advance()
	end)

	self.actionButton.Activated:Connect(function()
		local npc = self.npc
		self:close()
		if npc then
			local action = self.actions[npc.action]
			if action then
				action()
			end
		end
	end)

	Remotes.event("NpcDialogue").OnClientEvent:Connect(function(npcId)
		if typeof(npcId) == "string" then
			self:open(npcId)
		end
	end)

	return self
end

--- Répliques du PNJ, complétées par l'objectif en cours pour le guide.
local function buildLines(npc: any): { string }
	local lines = table.clone(npc.lines)

	if npc.action == "guide" then
		local profile = State.profile
		local step = Guide.next(profile)
		if step then
			local done, total = Guide.progress(profile)
			table.insert(
				lines,
				("OBJECTIF (%d/%d) — %s\n%s"):format(done + 1, total, step.title, step.detail)
			)
		else
			table.insert(lines, "Tu as suivi tout mon enseignement. La suite ne dépend plus que de toi : les failles de rang S n'attendent personne.")
		end
	end

	return lines
end

function Dialogue:open(npcId: string)
	local npc = NpcCatalog.get(npcId)
	if not npc then
		return
	end

	self.npc = npc
	self.lines = buildLines(npc)
	self.index = 1

	self.nameLabel.Text = npc.name
	self.nameLabel.TextColor3 = npc.glow
	self.roleLabel.Text = npc.role
	self.actionButton.Text = npc.actionLabel

	local stroke = self.box:FindFirstChildOfClass("UIStroke")
	if stroke then
		stroke.Color = npc.glow
	end

	self:render()

	self.root.Visible = true
	self.root.Position = UDim2.new(0.5, 0, 1, 40)
	TweenService:Create(self.root, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Position = UDim2.new(0.5, 0, 1, -18),
	}):Play()
end

function Dialogue:render()
	self.textLabel.Text = self.lines[self.index] or ""
	local isLast = self.index >= #self.lines
	self.nextButton.Visible = not isLast
	self.actionButton.Visible = isLast
end

function Dialogue:advance()
	if self.index < #self.lines then
		self.index += 1
		self:render()
	end
end

function Dialogue:close()
	self.root.Visible = false
	self.npc = nil
end

function Dialogue:isOpen(): boolean
	return self.root.Visible
end

return Dialogue
