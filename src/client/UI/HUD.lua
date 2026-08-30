--!strict
--[[
	HUD
	L'interface de jeu : bloc vital en bas à gauche, objectif en haut à gauche,
	bourse en haut à droite, techniques en bas au centre, actions à droite,
	et les bandeaux de faille / hub AFK en haut au centre.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared.GameConfig)
local Guide = require(Shared.Guide)
local Remotes = require(Shared.Remotes)
local SkillCatalog = require(Shared.SkillCatalog)
local Util = require(Shared.Util)

local CombatController = require(script.Parent.Parent.CombatController)
local State = require(script.Parent.Parent.State)
local Theme = require(script.Parent.Theme)

local Palette = GameConfig.Palette
local player = Players.LocalPlayer

local HUD = {}
HUD.__index = HUD

--- Une jauge du bloc vital : libellé, barre, valeur chiffrée par-dessus.
local function gauge(parent: Instance, y: number, height: number, color: Color3, caption: string)
	Theme.create("TextLabel", {
		Position = UDim2.fromOffset(0, y),
		Size = UDim2.fromOffset(58, height),
		BackgroundTransparency = 1,
		Font = Theme.HeadingFont,
		Text = caption,
		TextSize = 10,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = color,
		Parent = parent,
	})

	local background, fill = Theme.bar(color)
	background.Position = UDim2.new(0, 58, 0, y)
	background.Size = UDim2.new(1, -58, 0, height)
	background.Parent = parent

	local value = Theme.create("TextLabel", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Font = Theme.BodyFont,
		Text = "",
		TextSize = 11,
		TextColor3 = Palette.text,
		TextStrokeTransparency = 0.4,
		ZIndex = 5,
		Parent = background,
	})

	return fill, value
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
	-- Bloc vital (bas gauche)
	------------------------------------------------------------------
	local vitals = Theme.panel({
		Name = "Vitalité",
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 20, 1, -20),
		Size = UDim2.fromOffset(350, 132),
		Parent = root,
	}, { accent = Palette.accent, brackets = true })
	local vitalsContent = Theme.content(vitals, 12, 14)

	-- Écusson de niveau.
	local badge = Theme.create("Frame", {
		Name = "Niveau",
		Size = UDim2.fromOffset(52, 52),
		BackgroundColor3 = Palette.panelRaised,
		BorderSizePixel = 0,
		Parent = vitalsContent,
	}, { Theme.corner(3), Theme.stroke(Palette.accent, 1, 0.2) })
	self.badge = badge
	self.badgeStroke = badge:FindFirstChildOfClass("UIStroke")

	self.levelNumber = Theme.create("TextLabel", {
		Position = UDim2.fromScale(0, 0.06),
		Size = UDim2.fromScale(1, 0.62),
		BackgroundTransparency = 1,
		Font = Theme.NumberFont,
		Text = "1",
		TextScaled = true,
		TextColor3 = Palette.text,
		Parent = badge,
	})

	Theme.create("TextLabel", {
		Position = UDim2.fromScale(0, 0.66),
		Size = UDim2.fromScale(1, 0.28),
		BackgroundTransparency = 1,
		Font = Theme.BodyFont,
		Text = "NIVEAU",
		TextScaled = true,
		TextColor3 = Palette.textFaint,
		Parent = badge,
	})

	self.rankLabel = Theme.create("TextLabel", {
		Position = UDim2.fromOffset(62, 2),
		Size = UDim2.new(1, -62, 0, 20),
		BackgroundTransparency = 1,
		Font = Theme.DisplayFont,
		Text = "GRADE 4",
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = Palette.accent,
		Parent = vitalsContent,
	})

	self.nameLabel = Theme.create("TextLabel", {
		Position = UDim2.fromOffset(62, 22),
		Size = UDim2.new(1, -62, 0, 16),
		BackgroundTransparency = 1,
		Font = Theme.BodyFont,
		Text = player.DisplayName,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = Palette.textDim,
		Parent = vitalsContent,
	})

	self.healthFill, self.healthValue = gauge(vitalsContent, 60, 16, Palette.danger, "VIE")
	self.energyFill, self.energyValue = gauge(vitalsContent, 80, 16, Palette.accentSoft, "MAGIE")
	self.xpFill, self.xpValue = gauge(vitalsContent, 100, 10, Palette.accent, "XP")
	self.xpValue.TextSize = 9

	------------------------------------------------------------------
	-- Objectif + zone (haut gauche)
	------------------------------------------------------------------
	local objective = Theme.panel({
		Name = "Objectif",
		Position = UDim2.fromOffset(20, 20),
		Size = UDim2.fromOffset(340, 84),
		Parent = root,
	}, { accent = Palette.success, brackets = false })
	self.objectivePanel = objective

	Theme.create("Frame", {
		Name = "Accent",
		Size = UDim2.new(0, 2, 1, 0),
		BackgroundColor3 = Palette.success,
		BorderSizePixel = 0,
		ZIndex = 3,
		Parent = objective,
	})

	local objectiveContent = Theme.content(objective, 10, 14)

	Theme.create("TextLabel", {
		Size = UDim2.new(1, 0, 0, 12),
		BackgroundTransparency = 1,
		Font = Theme.DisplayFont,
		Text = "SYSTÈME",
		TextSize = 9,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = Palette.textFaint,
		Parent = objectiveContent,
	})

	self.objectiveTitle = Theme.create("TextLabel", {
		Position = UDim2.fromOffset(0, 14),
		Size = UDim2.new(1, 0, 0, 18),
		BackgroundTransparency = 1,
		Font = Theme.HeadingFont,
		Text = "",
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = Palette.success,
		Parent = objectiveContent,
	})

	self.objectiveDetail = Theme.create("TextLabel", {
		Position = UDim2.fromOffset(0, 34),
		Size = UDim2.new(1, 0, 0, 30),
		BackgroundTransparency = 1,
		Font = Theme.BodyFont,
		Text = "",
		TextSize = 11,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		TextColor3 = Palette.textDim,
		Parent = objectiveContent,
	})

	self.zoneBadge = Theme.chip("ZONE SÛRE", Palette.success, {
		Name = "Zone",
		Position = UDim2.fromOffset(20, 112),
		Size = UDim2.fromOffset(168, 24),
		TextSize = 11,
		Parent = root,
	})

	------------------------------------------------------------------
	-- Bourse (haut droite)
	------------------------------------------------------------------
	local wallet = Theme.create("Frame", {
		Name = "Bourse",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -20, 0, 20),
		Size = UDim2.fromOffset(220, 64),
		BackgroundTransparency = 1,
		Parent = root,
	}, { Theme.list(Enum.FillDirection.Vertical, 6, Enum.HorizontalAlignment.Right) })

	local function purse(color: Color3, order: number): TextLabel
		local pill = Theme.panel({
			Size = UDim2.fromOffset(210, 28),
			LayoutOrder = order,
			Parent = wallet,
		}, { accent = color, brackets = false })

		return Theme.create("TextLabel", {
			Size = UDim2.new(1, -14, 1, 0),
			Position = UDim2.fromOffset(7, 0),
			BackgroundTransparency = 1,
			Font = Theme.HeadingFont,
			Text = "0",
			TextSize = 14,
			TextXAlignment = Enum.TextXAlignment.Right,
			TextColor3 = color,
			ZIndex = 3,
			Parent = pill,
		})
	end

	self.yensLabel = purse(Palette.gold, 1)
	self.fragmentsLabel = purse(Palette.accent, 2)

	------------------------------------------------------------------
	-- Techniques (bas centre)
	------------------------------------------------------------------
	local skillBar = Theme.create("Frame", {
		Name = "Techniques",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -20),
		Size = UDim2.fromOffset(490, 92),
		BackgroundTransparency = 1,
		Parent = root,
	}, {
		Theme.create("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			VerticalAlignment = Enum.VerticalAlignment.Bottom,
			Padding = UDim.new(0, 10),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})

	self.skillSlots = {}
	for index, skill in ipairs(SkillCatalog.List) do
		local slot = Theme.create("TextButton", {
			Name = skill.id,
			Size = UDim2.fromOffset(84, 84),
			BackgroundColor3 = Palette.panel,
			BackgroundTransparency = 0.1,
			AutoButtonColor = false,
			Text = "",
			LayoutOrder = index,
			BorderSizePixel = 0,
		}, {
			Theme.corner(3),
			Theme.stroke(skill.color, 1, 0.4),
			Theme.create("UIGradient", {
				Color = ColorSequence.new(Palette.panelLight, Palette.panel),
				Rotation = 90,
			}),
		})
		slot.Parent = skillBar
		Theme.brackets(slot, skill.color, 10, 2)

		Theme.create("TextLabel", {
			Position = UDim2.fromScale(0.08, 0.12),
			Size = UDim2.fromScale(0.84, 0.4),
			BackgroundTransparency = 1,
			Font = Theme.HeadingFont,
			Text = skill.name,
			TextSize = 11,
			TextWrapped = true,
			TextColor3 = skill.color,
			ZIndex = 3,
			Parent = slot,
		})

		Theme.create("TextLabel", {
			Position = UDim2.fromScale(0.08, 0.54),
			Size = UDim2.fromScale(0.84, 0.16),
			BackgroundTransparency = 1,
			Font = Theme.BodyFont,
			Text = if skill.cost > 0 then ("%d magie"):format(skill.cost) else "sans coût",
			TextSize = 9,
			TextColor3 = Palette.textFaint,
			ZIndex = 3,
			Parent = slot,
		})

		local key = Theme.chip(if skill.keybind then skill.keybind.Name else "CLIC", skill.color, {
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.fromScale(0.5, 0.94),
			Size = UDim2.fromOffset(48, 16),
			TextSize = 10,
			ZIndex = 3,
			Parent = slot,
		})

		local overlay = Theme.create("Frame", {
			Name = "Recharge",
			AnchorPoint = Vector2.new(0, 1),
			Position = UDim2.fromScale(0, 1),
			Size = UDim2.fromScale(1, 0),
			BackgroundColor3 = Palette.void,
			BackgroundTransparency = 0.35,
			BorderSizePixel = 0,
			ZIndex = 6,
			Parent = slot,
		}, { Theme.corner(3) })

		local lock = Theme.create("TextLabel", {
			Name = "Verrou",
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = Palette.void,
			BackgroundTransparency = 0.35,
			Font = Theme.HeadingFont,
			Text = ("NIV. %d"):format(skill.unlockLevel),
			TextSize = 12,
			TextColor3 = Palette.textFaint,
			ZIndex = 7,
			Visible = false,
			Parent = slot,
		}, { Theme.corner(3) })

		slot.Activated:Connect(function()
			CombatController.use(skill.id)
		end)

		table.insert(self.skillSlots, {
			skill = skill,
			button = slot,
			overlay = overlay,
			lock = lock,
			key = key,
			stroke = slot:FindFirstChildOfClass("UIStroke"),
			wasReady = true,
		})
	end

	------------------------------------------------------------------
	-- Actions (droite)
	------------------------------------------------------------------
	local sideBar = Theme.create("Frame", {
		Name = "Actions",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -20, 0.5, 0),
		Size = UDim2.fromOffset(168, 200),
		BackgroundTransparency = 1,
		Parent = root,
	}, { Theme.list(Enum.FillDirection.Vertical, 8, Enum.HorizontalAlignment.Right) })

	self.buttons = {}
	for index, definition in ipairs({
		{ id = "stats", text = "STATISTIQUES", key = "C" },
		{ id = "quests", text = "QUÊTES", key = "Q" },
		{ id = "dungeons", text = "DONJONS", key = "J" },
		{ id = "shop", text = "BOUTIQUE", key = "B" },
		{ id = "menu", text = "MENU", key = "M" },
	}) do
		local button = Theme.button(definition.text, Palette.accent, {
			Name = definition.id,
			Size = UDim2.fromOffset(168, 32),
			TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Left,
			LayoutOrder = index,
			Parent = sideBar,
		})
		Theme.padding(0, 12).Parent = button

		Theme.chip(definition.key, Palette.textDim, {
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -8, 0.5, 0),
			Size = UDim2.fromOffset(22, 18),
			TextSize = 10,
			ZIndex = 3,
			Parent = button,
		})

		self.buttons[definition.id] = button
	end

	-- Pastille de points de statistique à répartir.
	self.statAlert = Theme.create("TextLabel", {
		Name = "Alerte",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, -10, 0.5, 0),
		Size = UDim2.fromOffset(24, 20),
		BackgroundColor3 = Palette.success,
		BackgroundTransparency = 0.1,
		Font = Theme.HeadingFont,
		Text = "",
		TextSize = 11,
		TextColor3 = Palette.void,
		Visible = false,
		ZIndex = 4,
		Parent = self.buttons.stats,
	}, { Theme.corner(3) })

	------------------------------------------------------------------
	-- Bandeaux de faille et de hub AFK (haut centre)
	------------------------------------------------------------------
	local riftPanel = Theme.panel({
		Name = "Faille",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 20),
		Size = UDim2.fromOffset(380, 104),
		Visible = false,
		Parent = root,
	}, { accent = Palette.danger, brackets = true, glow = true })
	self.riftPanel = riftPanel
	local riftContent = Theme.content(riftPanel, 12, 16)

	self.riftTitle = Theme.create("TextLabel", {
		Size = UDim2.new(1, 0, 0, 20),
		BackgroundTransparency = 1,
		Font = Theme.DisplayFont,
		Text = "",
		TextSize = 14,
		TextColor3 = Palette.danger,
		Parent = riftContent,
	})

	self.riftInfo = Theme.create("TextLabel", {
		Position = UDim2.fromOffset(0, 24),
		Size = UDim2.new(1, 0, 0, 18),
		BackgroundTransparency = 1,
		Font = Theme.BodyFont,
		Text = "",
		TextSize = 13,
		TextColor3 = Palette.text,
		Parent = riftContent,
	})

	local riftBackground, riftFill = Theme.bar(Palette.danger)
	riftBackground.Position = UDim2.fromOffset(0, 46)
	riftBackground.Size = UDim2.new(1, 0, 0, 8)
	riftBackground.Parent = riftContent
	self.riftFill = riftFill

	local leaveButton = Theme.button("ABANDONNER", Palette.danger, {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, 0),
		Size = UDim2.fromOffset(180, 24),
		TextSize = 11,
		Parent = riftContent,
	})
	leaveButton.Activated:Connect(function()
		Remotes.event("LeaveRift"):FireServer()
	end)

	local afkPanel = Theme.panel({
		Name = "HubAFK",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 20),
		Size = UDim2.fromOffset(360, 104),
		Visible = false,
		Parent = root,
	}, { accent = Palette.accent, brackets = true, glow = true })
	self.afkPanel = afkPanel
	local afkContent = Theme.content(afkPanel, 12, 16)

	Theme.create("TextLabel", {
		Size = UDim2.new(1, 0, 0, 20),
		BackgroundTransparency = 1,
		Font = Theme.DisplayFont,
		Text = "HUB AFK",
		TextSize = 15,
		TextColor3 = Palette.accent,
		Parent = afkContent,
	})

	Theme.create("TextLabel", {
		Position = UDim2.fromOffset(0, 24),
		Size = UDim2.new(1, 0, 0, 32),
		BackgroundTransparency = 1,
		Font = Theme.BodyFont,
		Text = ("Gains passifs toutes les %d secondes.\nAucun esprit ne peut t'atteindre ici."):format(
			GameConfig.AfkRewardInterval
		),
		TextSize = 12,
		TextWrapped = true,
		TextColor3 = Palette.textDim,
		Parent = afkContent,
	})

	local returnButton = Theme.button("RETOUR AU HALL", Palette.accentSoft, {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, 0),
		Size = UDim2.fromOffset(200, 26),
		TextSize = 12,
		Parent = afkContent,
	})
	returnButton.Activated:Connect(function()
		Remotes.event("Teleport"):FireServer("hall")
	end)

	self:_bind()
	return self
end

function HUD:_bind()
	State.observe(function(profile)
		local rank = GameConfig.rankForLevel(profile.level)
		self.rankLabel.Text = string.upper(rank.name)
		self.rankLabel.TextColor3 = rank.color
		self.levelNumber.Text = tostring(profile.level)
		if self.badgeStroke then
			self.badgeStroke.Color = rank.color
		end

		local required = GameConfig.xpForNextLevel(profile.level)
		local ratio = math.clamp(profile.xp / math.max(required, 1), 0, 1)
		TweenService:Create(self.xpFill, TweenInfo.new(0.3), { Size = UDim2.fromScale(ratio, 1) }):Play()
		self.xpValue.Text = ("%s / %s"):format(Util.formatNumber(profile.xp), Util.formatNumber(required))

		self.yensLabel.Text = ("%s  YENS"):format(Util.formatNumber(profile.currencies.yens))
		self.fragmentsLabel.Text = ("%s  FRAGMENTS"):format(Util.formatNumber(profile.currencies.fragments))

		self.statAlert.Visible = profile.statPoints > 0
		self.statAlert.Text = tostring(profile.statPoints)

		local step = Guide.next(profile)
		if step then
			local done, total = Guide.progress(profile)
			self.objectiveTitle.Text = ("%d/%d  •  %s"):format(done + 1, total, step.title)
			self.objectiveDetail.Text = step.detail
		else
			self.objectiveTitle.Text = "TOUS LES OBJECTIFS TERMINÉS"
			self.objectiveDetail.Text = "Les failles de rang S t'attendent."
		end

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
			TweenService:Create(self.healthFill, TweenInfo.new(0.2), {
				Size = UDim2.fromScale(math.clamp(ratio, 0, 1), 1),
			}):Play()
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

	-- Zone courante.
	local ZONES = {
		hall = { text = "ZONE SÛRE — HALL", color = Palette.success },
		afk = { text = "HUB AFK — SÛR", color = Palette.accent },
		chasse = { text = "TERRAIN DE CHASSE", color = Palette.danger },
		faille = { text = "FAILLE OUVERTE", color = Palette.danger },
	}

	local function updateZone(zone: string?)
		local info = ZONES[zone or "hall"] or ZONES.hall
		self.zoneBadge.Text = info.text
		self.zoneBadge.TextColor3 = info.color
		self.zoneBadge.BackgroundColor3 = info.color
		local stroke = self.zoneBadge:FindFirstChildOfClass("UIStroke")
		if stroke then
			stroke.Color = info.color
		end

		self.afkPanel.Visible = zone == "afk"
		self.objectivePanel.Visible = zone ~= "faille"
	end

	Remotes.event("ZoneChanged").OnClientEvent:Connect(updateZone)
	updateZone(player:GetAttribute("Zone"))

	-- Faille en cours.
	Remotes.event("RiftStateChanged").OnClientEvent:Connect(function(state)
		if not state or not state.inRift then
			self.riftPanel.Visible = false
			return
		end

		self.riftPanel.Visible = true
		self.riftTitle.Text = ("FAILLE %s — %s"):format(state.rank, state.riftName)
		self.riftInfo.Text = ("Vague %d/%d   •   %d esprit(s) restant(s)")
			:format(state.wave, state.totalWaves, state.remaining or 0)
		self.riftFill.Size = UDim2.fromScale(
			math.clamp((state.wave - 1) / math.max(state.totalWaves, 1), 0, 1),
			1
		)
	end)

	-- Recharges : voile qui descend, éclat quand la technique redevient prête.
	RunService.RenderStepped:Connect(function()
		if not self.root.Visible then
			return
		end
		for _, slot in ipairs(self.skillSlots) do
			local remaining = CombatController.remaining(slot.skill.id)
			local ratio = if slot.skill.cooldown > 0 then remaining / slot.skill.cooldown else 0
			slot.overlay.Size = UDim2.fromScale(1, math.clamp(ratio, 0, 1))

			local ready = remaining <= 0
			if ready ~= slot.wasReady then
				slot.wasReady = ready
				if ready and slot.stroke then
					slot.stroke.Transparency = 0
					TweenService:Create(slot.stroke, TweenInfo.new(0.45), { Transparency = 0.4 }):Play()
				end
			end
		end
	end)
end

function HUD:setVisible(value: boolean)
	self.root.Visible = value
end

--- Éclat rouge sur les bords quand on encaisse un coup.
function HUD:flashDamage()
	local flash = Theme.create("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ZIndex = 0,
		Parent = self.root,
	}, {
		Theme.stroke(Palette.danger, 6, 0.15),
	})

	local stroke = flash:FindFirstChildOfClass("UIStroke")
	if stroke then
		TweenService:Create(stroke, TweenInfo.new(0.45), { Transparency = 1, Thickness = 14 }):Play()
	end
	task.delay(0.5, function()
		flash:Destroy()
	end)
end

return HUD
