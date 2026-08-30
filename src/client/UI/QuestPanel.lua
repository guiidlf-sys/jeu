--!strict
--[[
	QuestPanel
	Quêtes quotidiennes : progression et réclamation des récompenses.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared.GameConfig)
local QuestCatalog = require(Shared.QuestCatalog)
local Remotes = require(Shared.Remotes)
local Util = require(Shared.Util)

local State = require(script.Parent.Parent.State)
local Theme = require(script.Parent.Theme)

local QuestPanel = {}
QuestPanel.__index = QuestPanel

function QuestPanel.new(parent: ScreenGui)
	local self = setmetatable({}, QuestPanel)

	local root, content = Theme.window(parent, "QUÊTES QUOTIDIENNES", UDim2.fromOffset(600, 480))
	self.root = root

	Theme.create("TextLabel", {
		Size = UDim2.new(1, 0, 0, 22),
		BackgroundTransparency = 1,
		Font = Theme.BodyFont,
		Text = "Réinitialisées chaque jour. Les récompenses incluent des points de statistique.",
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = GameConfig.Palette.textDim,
		ZIndex = 32,
		Parent = content,
	})

	local list = Theme.create("Frame", {
		Position = UDim2.fromOffset(0, 32),
		Size = UDim2.new(1, 0, 1, -32),
		BackgroundTransparency = 1,
		ZIndex = 32,
		Parent = content,
	}, {
		Theme.create("UIListLayout", { Padding = UDim.new(0, 12), SortOrder = Enum.SortOrder.LayoutOrder }),
	})

	self.rows = {}
	for index, quest in ipairs(QuestCatalog.List) do
		local row = Theme.panel({
			Size = UDim2.new(1, 0, 0, 96),
			BackgroundTransparency = 0.2,
			LayoutOrder = index,
			ZIndex = 32,
			Parent = list,
		})
		Theme.padding(12).Parent = row

		Theme.create("TextLabel", {
			Size = UDim2.new(0.65, 0, 0, 20),
			BackgroundTransparency = 1,
			Font = Theme.HeadingFont,
			Text = quest.name,
			TextSize = 16,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextColor3 = GameConfig.Palette.text,
			ZIndex = 33,
			Parent = row,
		})

		Theme.create("TextLabel", {
			Position = UDim2.fromOffset(0, 22),
			Size = UDim2.new(0.65, 0, 0, 18),
			BackgroundTransparency = 1,
			Font = Theme.BodyFont,
			Text = quest.description,
			TextSize = 13,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextColor3 = GameConfig.Palette.textDim,
			ZIndex = 33,
			Parent = row,
		})

		local background, fill = Theme.bar(GameConfig.Palette.accent)
		background.Position = UDim2.fromOffset(0, 50)
		background.Size = UDim2.new(0.65, 0, 0, 14)
		background.ZIndex = 33
		background.Parent = row
		fill.ZIndex = 33

		local progress = Theme.create("TextLabel", {
			Position = UDim2.fromOffset(0, 68),
			Size = UDim2.new(0.65, 0, 0, 16),
			BackgroundTransparency = 1,
			Font = Theme.BodyFont,
			Text = "0 / 0",
			TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextColor3 = GameConfig.Palette.textDim,
			ZIndex = 33,
			Parent = row,
		})

		local reward = Theme.create("TextLabel", {
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, 0, 0, 0),
			Size = UDim2.fromOffset(180, 44),
			BackgroundTransparency = 1,
			Font = Theme.BodyFont,
			Text = ("+%d yens\n+%d XP • +%d point(s)"):format(quest.reward.yens, quest.reward.xp, quest.reward.statPoints),
			TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Right,
			TextColor3 = GameConfig.Currencies.yens.color,
			ZIndex = 33,
			Parent = row,
		})

		local claim = Theme.create("TextButton", {
			AnchorPoint = Vector2.new(1, 1),
			Position = UDim2.new(1, 0, 1, 0),
			Size = UDim2.fromOffset(160, 32),
			BackgroundColor3 = GameConfig.Palette.success,
			BackgroundTransparency = 0.2,
			AutoButtonColor = true,
			Font = Theme.HeadingFont,
			Text = "Réclamer",
			TextSize = 14,
			TextColor3 = Color3.fromRGB(12, 20, 14),
			ZIndex = 33,
			Parent = row,
		}, { Theme.corner(6) })

		claim.Activated:Connect(function()
			claim.Text = "..."
			local ok, result = pcall(function()
				return Remotes.func("ClaimQuest"):InvokeServer(quest.id)
			end)
			if not ok or not result or not result.ok then
				claim.Text = if ok and result then result.reason else "Erreur"
				task.delay(1.5, function()
					claim.Text = "Réclamer"
				end)
			end
		end)

		self.rows[quest.id] = { fill = fill, progress = progress, claim = claim, quest = quest, reward = reward }
	end

	State.observe(function(profile)
		for questId, row in pairs(self.rows) do
			local quest = row.quest
			local current = profile.quests.progress[quest.metric] or 0
			local ratio = math.clamp(current / quest.goal, 0, 1)
			row.fill.Size = UDim2.fromScale(ratio, 1)
			row.progress.Text = ("%s / %s"):format(Util.formatNumber(current), Util.formatNumber(quest.goal))

			if profile.quests.claimed[questId] then
				row.claim.Text = "Réclamée"
				row.claim.BackgroundColor3 = GameConfig.Palette.panelLight
				row.claim.Active = false
			elseif current >= quest.goal then
				row.claim.Text = "Réclamer"
				row.claim.BackgroundColor3 = GameConfig.Palette.success
				row.claim.Active = true
			else
				row.claim.Text = "En cours"
				row.claim.BackgroundColor3 = GameConfig.Palette.panelLight
				row.claim.Active = false
			end
		end
	end)

	return self
end

function QuestPanel:toggle()
	self.root.Visible = not self.root.Visible
end

function QuestPanel:setVisible(value: boolean)
	self.root.Visible = value
end

return QuestPanel
