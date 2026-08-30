--!strict
--[[
	QuestPanel
	Deux listes dans la même fenêtre :
	  • les contrats de chasse, à accepter — ils rendent hostiles les espèces
	    visées, et c'est la seule façon d'être attaqué hors des failles ;
	  • les quêtes quotidiennes, suivies automatiquement.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared.GameConfig)
local HuntCatalog = require(Shared.HuntCatalog)
local MobCatalog = require(Shared.MobCatalog)
local QuestCatalog = require(Shared.QuestCatalog)
local Remotes = require(Shared.Remotes)
local Util = require(Shared.Util)

local State = require(script.Parent.Parent.State)
local Theme = require(script.Parent.Theme)

local QuestPanel = {}
QuestPanel.__index = QuestPanel

local function sectionTitle(parent: Instance, text: string, subtitle: string, order: number)
	local holder = Theme.create("Frame", {
		Size = UDim2.new(1, 0, 0, 46),
		BackgroundTransparency = 1,
		LayoutOrder = order,
		ZIndex = 33,
		Parent = parent,
	})

	Theme.create("TextLabel", {
		Size = UDim2.new(1, 0, 0, 24),
		BackgroundTransparency = 1,
		Font = Theme.TitleFont,
		Text = text,
		TextSize = 17,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = GameConfig.Palette.accentSoft,
		ZIndex = 34,
		Parent = holder,
	})

	Theme.create("TextLabel", {
		Position = UDim2.fromOffset(0, 24),
		Size = UDim2.new(1, 0, 0, 18),
		BackgroundTransparency = 1,
		Font = Theme.BodyFont,
		Text = subtitle,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = GameConfig.Palette.textDim,
		ZIndex = 34,
		Parent = holder,
	})
end

--- Noms lisibles des espèces visées par un contrat.
local function targetNames(hunt: any): string
	local names = {}
	for _, mobId in ipairs(hunt.targets) do
		local mob = MobCatalog.get(mobId)
		table.insert(names, if mob then mob.name else mobId)
	end
	return table.concat(names, ", ")
end

function QuestPanel.new(parent: ScreenGui)
	local self = setmetatable({}, QuestPanel)

	local root, content = Theme.window(parent, "QUÊTES & CONTRATS", UDim2.fromOffset(720, 580))
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
		Theme.create("UIListLayout", { Padding = UDim.new(0, 12), SortOrder = Enum.SortOrder.LayoutOrder }),
		Theme.create("UIPadding", { PaddingRight = UDim.new(0, 10) }),
	})

	local order = 0

	------------------------------------------------------------------
	-- Contrats de chasse
	------------------------------------------------------------------
	order += 1
	sectionTitle(
		scroll,
		"CONTRATS DE CHASSE",
		("Accepter un contrat rend son espèce hostile envers toi. %d contrats en cours au maximum.")
			:format(HuntCatalog.MaxActive),
		order
	)

	self.hunts = {}
	for _, hunt in ipairs(HuntCatalog.List) do
		order += 1
		local card = Theme.panel({
			Size = UDim2.new(1, 0, 0, 116),
			BackgroundTransparency = 0.2,
			LayoutOrder = order,
			ZIndex = 33,
			Parent = scroll,
		})
		Theme.padding(14).Parent = card

		local stroke = card:FindFirstChildOfClass("UIStroke")
		if stroke then
			stroke.Color = hunt.color
		end

		Theme.create("TextLabel", {
			Size = UDim2.new(0.62, 0, 0, 22),
			BackgroundTransparency = 1,
			Font = Theme.HeadingFont,
			Text = hunt.name,
			TextSize = 17,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextColor3 = hunt.color,
			ZIndex = 34,
			Parent = card,
		})

		Theme.create("TextLabel", {
			Position = UDim2.fromOffset(0, 22),
			Size = UDim2.new(0.62, 0, 0, 18),
			BackgroundTransparency = 1,
			Font = Theme.BodyFont,
			Text = hunt.description,
			TextSize = 13,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextColor3 = GameConfig.Palette.textDim,
			ZIndex = 34,
			Parent = card,
		})

		Theme.create("TextLabel", {
			Position = UDim2.fromOffset(0, 40),
			Size = UDim2.new(0.62, 0, 0, 18),
			BackgroundTransparency = 1,
			Font = Theme.BodyFont,
			Text = "Cibles : " .. targetNames(hunt),
			TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextColor3 = GameConfig.Palette.danger,
			ZIndex = 34,
			Parent = card,
		})

		local background, fill = Theme.bar(hunt.color)
		background.Position = UDim2.fromOffset(0, 64)
		background.Size = UDim2.new(0.62, 0, 0, 14)
		background.ZIndex = 34
		background.Parent = card
		fill.ZIndex = 34
		fill.Size = UDim2.fromScale(0, 1)

		local status = Theme.create("TextLabel", {
			Position = UDim2.fromOffset(0, 82),
			Size = UDim2.new(0.62, 0, 0, 16),
			BackgroundTransparency = 1,
			Font = Theme.BodyFont,
			Text = "",
			TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextColor3 = GameConfig.Palette.textDim,
			ZIndex = 34,
			Parent = card,
		})

		Theme.create("TextLabel", {
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, 0, 0, 0),
			Size = UDim2.fromOffset(210, 44),
			BackgroundTransparency = 1,
			Font = Theme.BodyFont,
			Text = ("+%s yens\n+%s XP • +%d fragment(s)"):format(
				Util.formatNumber(hunt.reward.yens),
				Util.formatNumber(hunt.reward.xp),
				hunt.reward.fragments
			),
			TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Right,
			TextColor3 = GameConfig.Currencies.yens.color,
			ZIndex = 34,
			Parent = card,
		})

		local action = Theme.create("TextButton", {
			AnchorPoint = Vector2.new(1, 1),
			Position = UDim2.new(1, 0, 1, 0),
			Size = UDim2.fromOffset(200, 34),
			BackgroundColor3 = hunt.color,
			BackgroundTransparency = 0.2,
			AutoButtonColor = true,
			Font = Theme.HeadingFont,
			Text = "Accepter",
			TextSize = 14,
			TextColor3 = Color3.fromRGB(10, 10, 16),
			ZIndex = 34,
			Parent = card,
		}, { Theme.corner(6) })

		local abandon = Theme.create("TextButton", {
			AnchorPoint = Vector2.new(1, 1),
			Position = UDim2.new(1, -208, 1, 0),
			Size = UDim2.fromOffset(110, 34),
			BackgroundColor3 = GameConfig.Palette.panelLight,
			AutoButtonColor = true,
			Font = Theme.BodyFont,
			Text = "Abandonner",
			TextSize = 12,
			TextColor3 = GameConfig.Palette.textDim,
			Visible = false,
			ZIndex = 34,
			Parent = card,
		}, { Theme.corner(6) })

		-- En cas de succès, l'état du profil rafraîchit le libellé tout seul ;
		-- en cas d'échec, on affiche la raison quelques secondes.
		local function request(actionName: string, button: TextButton, label: string)
			button.Text = "..."
			local ok, result = pcall(function()
				return Remotes.func("HuntRequest"):InvokeServer(actionName, hunt.id)
			end)
			if not ok or not result or not result.ok then
				button.Text = if ok and result and result.reason ~= "" then result.reason else "Erreur"
				task.delay(1.8, function()
					button.Text = label
				end)
			end
		end

		action.Activated:Connect(function()
			local profile = State.profile
			if not profile then
				return
			end
			local progress = profile.hunts.active[hunt.id]
			if progress == nil then
				request("accept", action, "Accepter")
			elseif progress >= hunt.goal then
				request("claim", action, "Réclamer la prime")
			end
		end)

		abandon.Activated:Connect(function()
			request("abandon", abandon, "Abandonner")
		end)

		self.hunts[hunt.id] = {
			hunt = hunt,
			fill = fill,
			status = status,
			action = action,
			abandon = abandon,
		}
	end

	------------------------------------------------------------------
	-- Quêtes quotidiennes
	------------------------------------------------------------------
	order += 1
	sectionTitle(
		scroll,
		"QUÊTES QUOTIDIENNES",
		"Suivies automatiquement, réinitialisées chaque jour. Elles rapportent des points de statistique.",
		order
	)

	self.quests = {}
	for _, quest in ipairs(QuestCatalog.List) do
		order += 1
		local row = Theme.panel({
			Size = UDim2.new(1, 0, 0, 96),
			BackgroundTransparency = 0.2,
			LayoutOrder = order,
			ZIndex = 33,
			Parent = scroll,
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
			ZIndex = 34,
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
			ZIndex = 34,
			Parent = row,
		})

		local background, fill = Theme.bar(GameConfig.Palette.accent)
		background.Position = UDim2.fromOffset(0, 50)
		background.Size = UDim2.new(0.65, 0, 0, 14)
		background.ZIndex = 34
		background.Parent = row
		fill.ZIndex = 34

		local progress = Theme.create("TextLabel", {
			Position = UDim2.fromOffset(0, 68),
			Size = UDim2.new(0.65, 0, 0, 16),
			BackgroundTransparency = 1,
			Font = Theme.BodyFont,
			Text = "0 / 0",
			TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextColor3 = GameConfig.Palette.textDim,
			ZIndex = 34,
			Parent = row,
		})

		Theme.create("TextLabel", {
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, 0, 0, 0),
			Size = UDim2.fromOffset(180, 44),
			BackgroundTransparency = 1,
			Font = Theme.BodyFont,
			Text = ("+%d yens\n+%d XP • +%d point(s)"):format(
				quest.reward.yens,
				quest.reward.xp,
				quest.reward.statPoints
			),
			TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Right,
			TextColor3 = GameConfig.Currencies.yens.color,
			ZIndex = 34,
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
			ZIndex = 34,
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

		self.quests[quest.id] = { quest = quest, fill = fill, progress = progress, claim = claim }
	end

	State.observe(function(profile)
		-- Contrats
		for huntId, row in pairs(self.hunts) do
			local hunt = row.hunt
			local progress = profile.hunts.active[huntId]
			local completed = profile.hunts.completed[huntId] or 0
			local locked = profile.level < hunt.minLevel

			row.abandon.Visible = progress ~= nil and progress < hunt.goal
			row.fill.Size = UDim2.fromScale(
				if progress then math.clamp(progress / hunt.goal, 0, 1) else 0,
				1
			)

			local suffix = if completed > 0 then (" — %d fois rempli"):format(completed) else ""

			if progress == nil then
				row.status.Text = ("Non accepté%s"):format(suffix)
				row.action.Text = if locked then ("Niveau %d requis"):format(hunt.minLevel) else "Accepter"
				row.action.BackgroundColor3 = if locked then GameConfig.Palette.panelLight else hunt.color
				row.action.Active = not locked
			elseif progress >= hunt.goal then
				row.status.Text = ("Terminé : %d / %d%s"):format(progress, hunt.goal, suffix)
				row.action.Text = "Réclamer la prime"
				row.action.BackgroundColor3 = GameConfig.Palette.success
				row.action.Active = true
			else
				row.status.Text = ("En cours : %d / %d — ces esprits t'attaquent à vue%s")
					:format(progress, hunt.goal, suffix)
				row.action.Text = ("%d / %d"):format(progress, hunt.goal)
				row.action.BackgroundColor3 = GameConfig.Palette.panelLight
				row.action.Active = false
			end
		end

		-- Quêtes quotidiennes
		for questId, row in pairs(self.quests) do
			local quest = row.quest
			local current = profile.quests.progress[quest.metric] or 0
			row.fill.Size = UDim2.fromScale(math.clamp(current / quest.goal, 0, 1), 1)
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
