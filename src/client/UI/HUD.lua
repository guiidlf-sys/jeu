--!strict
--[[
	HUD
	Interface de jeu : vie, énergie maudite, XP, rang, barre de techniques,
	monnaies et suivi de faille.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared.GameConfig)
local Remotes = require(Shared.Remotes)
local SkillCatalog = require(Shared.SkillCatalog)
local Util = require(Shared.Util)

local CombatController = require(script.Parent.Parent.CombatController)
local State = require(script.Parent.Parent.State)
local Theme = require(script.Parent.Theme)

local player = Players.LocalPlayer

local HUD = {}
HUD.__index = HUD

local function statLine(parent: Instance, order: number, color: Color3, label: string)
	local holder = Theme.create("Frame", {
		Size = UDim2.new(1, 0, 0, 26),
		BackgroundTransparency = 1,
		LayoutOrder = order,
		Parent = parent,
	})

	local caption = Theme.create("TextLabel", {
		Size = UDim2.new(0, 62, 1, 0),
		BackgroundTransparency = 1,
		Font = Theme.HeadingFont,
		Text = label,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = color,
		Parent = holder,
	})

	local background, fill = Theme.bar(color)
	background.Size = UDim2.new(1, -62, 0, 16)
	background.Position = UDim2.new(0, 62, 0.5, -8)
	background.Parent = holder

	local value = Theme.create("TextLabel", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Font = Theme.BodyFont,
		Text = "",
		TextSize = 12,
		TextColor3 = GameConfig.Palette.text,
		TextStrokeTransparency = 0.5,
		ZIndex = 3,
		Parent = background,
	})

	return fill, value, caption
end

function HUD.new(parent: ScreenGui)
	local self = setmetatable({}, HUD)

	local root = Theme.create("Frame", {
		Name = "HUD",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Visible = false,
		Parent = parent,
	})
	self.root = root

	------------------------------------------------------------------
	-- Bloc de gauche : identité + jauges
	------------------------------------------------------------------
	local panel = Theme.panel({
		Name = "Vitals",
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 18, 1, -18),
		Size = UDim2.new(0, 320, 0, 150),
		BackgroundTransparency = 0.15,
		Parent = root,
	})
	Theme.padding(12).Parent = panel

	Theme.create("UIListLayout", {
		Padding = UDim.new(0, 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = panel,
	})

	local header = Theme.create("Frame", {
		Size = UDim2.new(1, 0, 0, 34),
		BackgroundTransparency = 1,
		LayoutOrder = 1,
		Parent = panel,
	})

	self.rankLabel = Theme.create("TextLabel", {
		Size = UDim2.new(0, 120, 1, 0),
		BackgroundTransparency = 1,
		Font = Theme.TitleFont,
		Text = "GRADE 4",
		TextSize = 17,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = GameConfig.Palette.accent,
		Parent = header,
	})

	self.levelLabel = Theme.create("TextLabel", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.fromScale(1, 0),
		Size = UDim2.new(0, 150, 1, 0),
		BackgroundTransparency = 1,
		Font = Theme.HeadingFont,
		Text = "Niv. 1",
		TextSize = 16,
		TextXAlignment = Enum.TextXAlignment.Right,
		TextColor3 = GameConfig.Palette.text,
		Parent = header,
	})

	self.healthFill, self.healthValue = statLine(panel, 2, GameConfig.Palette.danger, "VIE")
	self.energyFill, self.energyValue = statLine(panel, 3, GameConfig.Palette.accentSoft, "ÉNERGIE")
	self.xpFill, self.xpValue = statLine(panel, 4, GameConfig.Palette.accent, "XP")

	------------------------------------------------------------------
	-- Monnaies (haut droite)
	------------------------------------------------------------------
	local wallet = Theme.panel({
		Name = "Bourse",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -18, 0, 18),
		Size = UDim2.new(0, 210, 0, 62),
		BackgroundTransparency = 0.15,
		Parent = root,
	})
	Theme.padding(10).Parent = wallet
	Theme.create("UIListLayout", { Padding = UDim.new(0, 2), Parent = wallet })

	self.yensLabel = Theme.create("TextLabel", {
		Size = UDim2.new(1, 0, 0, 20),
		BackgroundTransparency = 1,
		Font = Theme.HeadingFont,
		Text = "0 yens",
		TextSize = 15,
		TextXAlignment = Enum.TextXAlignment.Right,
		TextColor3 = GameConfig.Currencies.yens.color,
		Parent = wallet,
	})

	self.fragmentsLabel = Theme.create("TextLabel", {
		Size = UDim2.new(1, 0, 0, 20),
		BackgroundTransparency = 1,
		Font = Theme.HeadingFont,
		Text = "0 fragments",
		TextSize = 15,
		TextXAlignment = Enum.TextXAlignment.Right,
		TextColor3 = GameConfig.Currencies.fragments.color,
		Parent = wallet,
	})

	------------------------------------------------------------------
	-- Barre de techniques (bas centre)
	------------------------------------------------------------------
	local skillBar = Theme.create("Frame", {
		Name = "Techniques",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -18),
		Size = UDim2.new(0, 460, 0, 84),
		BackgroundTransparency = 1,
		Parent = root,
	}, {
		Theme.create("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			Padding = UDim.new(0, 10),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})

	self.skillSlots = {}
	for index, skill in ipairs(SkillCatalog.List) do
		local slot = Theme.create("TextButton", {
			Name = skill.id,
			Size = UDim2.fromOffset(78, 78),
			BackgroundColor3 = GameConfig.Palette.panel,
			BackgroundTransparency = 0.1,
			AutoButtonColor = false,
			Text = "",
			LayoutOrder = index,
			Parent = skillBar,
		}, {
			Theme.corner(8),
			Theme.stroke(skill.color, 2, 0.25),
		})

		local name = Theme.create("TextLabel", {
			Position = UDim2.fromScale(0, 0.08),
			Size = UDim2.new(1, 0, 0.42, 0),
			BackgroundTransparency = 1,
			Font = Theme.HeadingFont,
			Text = skill.name,
			TextSize = 11,
			TextWrapped = true,
			TextColor3 = skill.color,
			Parent = slot,
		})

		local key = Theme.create("TextLabel", {
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.fromScale(0.5, 0.96),
			Size = UDim2.new(1, 0, 0.3, 0),
			BackgroundTransparency = 1,
			Font = Theme.BodyFont,
			Text = if skill.keybind then skill.keybind.Name else "CLIC",
			TextSize = 12,
			TextColor3 = GameConfig.Palette.textDim,
			Parent = slot,
		})

		local overlay = Theme.create("Frame", {
			Name = "Recharge",
			AnchorPoint = Vector2.new(0, 1),
			Position = UDim2.fromScale(0, 1),
			Size = UDim2.fromScale(1, 0),
			BackgroundColor3 = Color3.fromRGB(0, 0, 0),
			BackgroundTransparency = 0.45,
			BorderSizePixel = 0,
			ZIndex = 4,
			Parent = slot,
		}, { Theme.corner(8) })

		local lock = Theme.create("TextLabel", {
			Name = "Verrou",
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = Color3.fromRGB(0, 0, 0),
			BackgroundTransparency = 0.5,
			Font = Theme.HeadingFont,
			Text = ("Niv. %d"):format(skill.unlockLevel),
			TextSize = 13,
			TextColor3 = GameConfig.Palette.textDim,
			ZIndex = 5,
			Visible = false,
			Parent = slot,
		}, { Theme.corner(8) })

		slot.Activated:Connect(function()
			CombatController.use(skill.id)
		end)

		table.insert(self.skillSlots, { skill = skill, button = slot, overlay = overlay, lock = lock, key = key, name = name })
	end

	------------------------------------------------------------------
	-- Suivi de faille (haut centre)
	------------------------------------------------------------------
	local riftPanel = Theme.panel({
		Name = "Faille",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 18),
		Size = UDim2.new(0, 340, 0, 92),
		BackgroundTransparency = 0.1,
		Visible = false,
		Parent = root,
	})
	Theme.padding(10).Parent = riftPanel
	self.riftPanel = riftPanel

	self.riftTitle = Theme.create("TextLabel", {
		Size = UDim2.new(1, 0, 0, 22),
		BackgroundTransparency = 1,
		Font = Theme.TitleFont,
		Text = "",
		TextSize = 16,
		TextColor3 = GameConfig.Palette.accent,
		Parent = riftPanel,
	})

	self.riftInfo = Theme.create("TextLabel", {
		Position = UDim2.new(0, 0, 0, 26),
		Size = UDim2.new(1, 0, 0, 20),
		BackgroundTransparency = 1,
		Font = Theme.BodyFont,
		Text = "",
		TextSize = 14,
		TextColor3 = GameConfig.Palette.text,
		Parent = riftPanel,
	})

	local leaveButton = Theme.create("TextButton", {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, 0),
		Size = UDim2.new(0, 150, 0, 24),
		BackgroundColor3 = GameConfig.Palette.danger,
		BackgroundTransparency = 0.25,
		AutoButtonColor = true,
		Font = Theme.HeadingFont,
		Text = "Abandonner",
		TextSize = 13,
		TextColor3 = GameConfig.Palette.text,
		Parent = riftPanel,
	}, { Theme.corner(6) })

	leaveButton.Activated:Connect(function()
		Remotes.event("LeaveRift"):FireServer()
	end)

	------------------------------------------------------------------
	-- Boutons latéraux
	------------------------------------------------------------------
	local sideBar = Theme.create("Frame", {
		Name = "Actions",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -18, 0.5, 0),
		Size = UDim2.new(0, 140, 0, 170),
		BackgroundTransparency = 1,
		Parent = root,
	}, {
		Theme.create("UIListLayout", {
			Padding = UDim.new(0, 8),
			HorizontalAlignment = Enum.HorizontalAlignment.Right,
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})
	self.sideBar = sideBar

	self.buttons = {}
	local sideDefinitions = {
		{ id = "stats", text = "STATISTIQUES (C)" },
		{ id = "quests", text = "QUÊTES (Q)" },
		{ id = "shop", text = "BOUTIQUE (B)" },
		{ id = "menu", text = "MENU (M)" },
	}

	for index, definition in ipairs(sideDefinitions) do
		local button = Theme.create("TextButton", {
			Name = definition.id,
			Size = UDim2.new(1, 0, 0, 34),
			BackgroundColor3 = GameConfig.Palette.panel,
			BackgroundTransparency = 0.1,
			AutoButtonColor = true,
			Font = Theme.HeadingFont,
			Text = definition.text,
			TextSize = 12,
			TextColor3 = GameConfig.Palette.text,
			LayoutOrder = index,
			Parent = sideBar,
		}, { Theme.corner(6), Theme.stroke(GameConfig.Palette.stroke, 1, 0.4) })

		self.buttons[definition.id] = button
	end

	-- Alerte de points de statistique disponibles.
	self.statAlert = Theme.create("TextLabel", {
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, 0, 0, -6),
		Size = UDim2.new(1, 0, 0, 18),
		BackgroundTransparency = 1,
		Font = Theme.HeadingFont,
		Text = "",
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Right,
		TextColor3 = GameConfig.Palette.success,
		Parent = self.buttons.stats,
	})

	self:_bind()
	return self
end

function HUD:_bind()
	-- Profil -> textes.
	State.observe(function(profile)
		local rank = GameConfig.rankForLevel(profile.level)
		self.rankLabel.Text = string.upper(rank.name)
		self.rankLabel.TextColor3 = rank.color
		self.levelLabel.Text = ("Niv. %d"):format(profile.level)

		local required = GameConfig.xpForNextLevel(profile.level)
		local ratio = math.clamp(profile.xp / math.max(required, 1), 0, 1)
		self.xpFill.Size = UDim2.fromScale(ratio, 1)
		self.xpValue.Text = ("%s / %s"):format(Util.formatNumber(profile.xp), Util.formatNumber(required))

		self.yensLabel.Text = ("%s yens"):format(Util.formatNumber(profile.currencies.yens))
		self.fragmentsLabel.Text = ("%s fragments"):format(Util.formatNumber(profile.currencies.fragments))

		self.statAlert.Text = if profile.statPoints > 0 then ("+%d"):format(profile.statPoints) else ""

		for _, slot in ipairs(self.skillSlots) do
			local locked = profile.level < slot.skill.unlockLevel
			slot.lock.Visible = locked
			slot.button.Active = not locked
		end
	end)

	-- Vie du personnage.
	local function watchCharacter(character: Model)
		local humanoid = character:WaitForChild("Humanoid", 10) :: Humanoid?
		if not humanoid then
			return
		end

		local function update()
			local ratio = if humanoid.MaxHealth > 0 then humanoid.Health / humanoid.MaxHealth else 0
			self.healthFill.Size = UDim2.fromScale(math.clamp(ratio, 0, 1), 1)
			self.healthValue.Text = ("%d / %d"):format(math.ceil(humanoid.Health), math.ceil(humanoid.MaxHealth))
		end

		humanoid.HealthChanged:Connect(update)
		humanoid:GetPropertyChangedSignal("MaxHealth"):Connect(update)
		update()
	end

	if player.Character then
		task.spawn(watchCharacter, player.Character)
	end
	player.CharacterAdded:Connect(function(character)
		task.spawn(watchCharacter, character)
	end)

	-- Énergie maudite (attributs répliqués par le serveur).
	local function updateEnergy()
		local current = player:GetAttribute("Energie") or 0
		local max = player:GetAttribute("EnergieMax") or GameConfig.BaseEnergy
		local ratio = math.clamp(current / math.max(max, 1), 0, 1)
		self.energyFill.Size = UDim2.fromScale(ratio, 1)
		self.energyValue.Text = ("%d / %d"):format(current, max)
	end

	player:GetAttributeChangedSignal("Energie"):Connect(updateEnergy)
	player:GetAttributeChangedSignal("EnergieMax"):Connect(updateEnergy)
	updateEnergy()

	-- Faille en cours.
	Remotes.event("RiftStateChanged").OnClientEvent:Connect(function(state)
		if not state or not state.inRift then
			self.riftPanel.Visible = false
			return
		end

		self.riftPanel.Visible = true
		self.riftTitle.Text = ("FAILLE %s — %s"):format(state.rank, state.riftName)
		self.riftInfo.Text = ("Vague %d/%d — %d esprit(s) restant(s)")
			:format(state.wave, state.totalWaves, state.remaining or 0)
	end)

	-- Recharges : mise à jour continue des voiles sur les techniques.
	RunService.RenderStepped:Connect(function()
		if not self.root.Visible then
			return
		end
		for _, slot in ipairs(self.skillSlots) do
			local remaining = CombatController.remaining(slot.skill.id)
			local ratio = if slot.skill.cooldown > 0 then remaining / slot.skill.cooldown else 0
			slot.overlay.Size = UDim2.fromScale(1, math.clamp(ratio, 0, 1))
		end
	end)
end

function HUD:setVisible(value: boolean)
	self.root.Visible = value
end

function HUD:flashDamage()
	local flash = Theme.create("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = GameConfig.Palette.danger,
		BackgroundTransparency = 0.75,
		BorderSizePixel = 0,
		ZIndex = 0,
		Parent = self.root,
	})
	TweenService:Create(flash, TweenInfo.new(0.35), { BackgroundTransparency = 1 }):Play()
	task.delay(0.4, function()
		flash:Destroy()
	end)
end

return HUD
