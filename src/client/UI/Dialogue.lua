--!strict
--[[
	Dialogue
	Boîte de dialogue des PNJ : plaque de nom, texte qui s'écrit lettre à
	lettre, et un bouton d'action qui ouvre la fenêtre concernée.
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

local Palette = GameConfig.Palette
local TYPE_SPEED = 90 -- caractères par seconde

local Dialogue = {}
Dialogue.__index = Dialogue

function Dialogue.new(parent: ScreenGui, actions: { [string]: () -> () })
	local self = setmetatable({}, Dialogue)

	self.actions = actions
	self.lines = {} :: { string }
	self.index = 1
	self.npc = nil :: any
	self.typing = false

	local root = Theme.create("Frame", {
		Name = "Dialogue",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -24),
		Size = UDim2.fromOffset(820, 216),
		BackgroundTransparency = 1,
		Visible = false,
		ZIndex = 35,
		Parent = parent,
	})
	self.root = root

	local box = Theme.panel({
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.fromScale(0.5, 1),
		Size = UDim2.new(1, 0, 0, 186),
		BackgroundTransparency = 0.02,
		ZIndex = 35,
		Parent = root,
	}, { accent = Palette.accent, brackets = true, glow = true })
	self.box = box

	-- Plaque de nom, posée à cheval sur le haut du cadre.
	local plate = Theme.panel({
		Name = "Plaque",
		Position = UDim2.fromOffset(24, 0),
		Size = UDim2.fromOffset(300, 42),
		BackgroundTransparency = 0.02,
		ZIndex = 37,
		Parent = root,
	}, { accent = Palette.accent, brackets = false })
	self.plate = plate

	self.nameLabel = Theme.create("TextLabel", {
		Position = UDim2.fromOffset(14, 4),
		Size = UDim2.new(1, -28, 0, 20),
		BackgroundTransparency = 1,
		Font = Theme.DisplayFont,
		Text = "",
		TextSize = 15,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = Palette.accent,
		ZIndex = 38,
		Parent = plate,
	})

	self.roleLabel = Theme.create("TextLabel", {
		Position = UDim2.fromOffset(14, 23),
		Size = UDim2.new(1, -28, 0, 14),
		BackgroundTransparency = 1,
		Font = Theme.BodyFont,
		Text = "",
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = Palette.textDim,
		ZIndex = 38,
		Parent = plate,
	})

	local content = Theme.content(box, 22, 26)

	self.textLabel = Theme.create("TextLabel", {
		Position = UDim2.fromOffset(0, 16),
		Size = UDim2.new(1, 0, 0, 92),
		BackgroundTransparency = 1,
		Font = Theme.BodyFont,
		Text = "",
		TextSize = 17,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		TextColor3 = Palette.text,
		ZIndex = 37,
		Parent = content,
	})

	local buttons = Theme.create("Frame", {
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, 0, 1, 0),
		Size = UDim2.new(1, 0, 0, 34),
		BackgroundTransparency = 1,
		ZIndex = 37,
		Parent = content,
	}, { Theme.list(Enum.FillDirection.Horizontal, 10, Enum.HorizontalAlignment.Right) })

	self.closeButton = Theme.button("FERMER", Palette.stroke, {
		Size = UDim2.fromOffset(160, 32),
		TextSize = 12,
		TextColor3 = Palette.textDim,
		LayoutOrder = 1,
		ZIndex = 38,
		Parent = buttons,
	})

	self.actionButton = Theme.button("", Palette.accent, {
		Size = UDim2.fromOffset(300, 32),
		TextSize = 13,
		LayoutOrder = 2,
		ZIndex = 38,
		Parent = buttons,
	})

	self.nextButton = Theme.button("SUIVANT  ›", Palette.accentSoft, {
		Size = UDim2.fromOffset(180, 32),
		TextSize = 13,
		LayoutOrder = 3,
		ZIndex = 38,
		Parent = buttons,
	})

	-- Compteur de répliques, discret, en bas à gauche.
	self.counter = Theme.create("TextLabel", {
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 0, 1, -8),
		Size = UDim2.fromOffset(120, 16),
		BackgroundTransparency = 1,
		Font = Theme.BodyFont,
		Text = "",
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = Palette.textFaint,
		ZIndex = 37,
		Parent = content,
	})

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
			table.insert(lines, ("OBJECTIF %d/%d — %s\n%s"):format(done + 1, total, step.title, step.detail))
		else
			table.insert(
				lines,
				"Tu as suivi tout mon enseignement. La suite ne dépend plus que de toi : les failles de rang S n'attendent personne."
			)
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
	self.actionButton.Text = string.upper(npc.actionLabel)

	for _, target in ipairs({ self.box, self.plate }) do
		local stroke = target:FindFirstChildOfClass("UIStroke")
		if stroke then
			stroke.Color = npc.glow
		end
		local accent = target:FindFirstChild("Équerres")
		if accent then
			for _, bar in ipairs(accent:GetChildren()) do
				if bar:IsA("Frame") then
					bar.BackgroundColor3 = npc.glow
				end
			end
		end
	end

	self:render()

	self.root.Visible = true
	self.root.Position = UDim2.new(0.5, 0, 1, 60)
	TweenService:Create(self.root, TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
		Position = UDim2.new(0.5, 0, 1, -24),
	}):Play()
end

--- Écrit la réplique lettre à lettre ; un second appui affiche tout.
function Dialogue:render()
	local text = self.lines[self.index] or ""
	self.textLabel.Text = text
	self.counter.Text = ("%d / %d"):format(self.index, #self.lines)

	local isLast = self.index >= #self.lines
	self.nextButton.Visible = not isLast
	self.actionButton.Visible = isLast

	local total = utf8.len(text) or #text
	self.textLabel.MaxVisibleGraphemes = 0
	self.typing = true

	task.spawn(function()
		local shown = 0
		while self.typing and shown < total do
			shown = math.min(total, shown + math.max(1, math.floor(TYPE_SPEED * 0.03)))
			self.textLabel.MaxVisibleGraphemes = shown
			task.wait(0.03)
		end
		self.textLabel.MaxVisibleGraphemes = -1
		self.typing = false
	end)
end

function Dialogue:advance()
	if self.typing then
		-- Première pression : on affiche la réplique entière.
		self.typing = false
		self.textLabel.MaxVisibleGraphemes = -1
		return
	end

	if self.index < #self.lines then
		self.index += 1
		self:render()
	end
end

function Dialogue:close()
	self.typing = false
	self.root.Visible = false
	self.npc = nil
end

function Dialogue:isOpen(): boolean
	return self.root.Visible
end

return Dialogue
