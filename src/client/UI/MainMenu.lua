--!strict
--[[
	MainMenu
	Deux pages dans le même cadre : le nom du jeu puis JOUER / BOUTIQUE /
	CRÉDIT, et la page JOUER avec IN THE GAME / DONJONS / HUB AFK.

	Le fond est une vue caméra qui tourne autour du hall, assombrie par un
	vignettage et parcourue de poussières d'énergie maudite.
]]

local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared.GameConfig)

local Theme = require(script.Parent.Theme)

local ORBIT_CENTER = Vector3.new(0, 16, 0)
local ORBIT_RADIUS = 112
local ORBIT_SPEED = 0.05
local DUST_COUNT = 22

local PAGES = {
	main = {
		title = GameConfig.GameName,
		subtitle = "Deviens le sorcier le plus fort — une faille à la fois.",
		buttons = {
			{ text = "JOUER", handler = "onPlayPage" },
			{ text = "BOUTIQUE", handler = "onShop" },
			{ text = "CRÉDIT", handler = "onCredits" },
		},
	},
	play = {
		title = "JOUER",
		subtitle = "Où veux-tu aller ?",
		buttons = {
			{ text = "IN THE GAME", handler = "onInGame", hint = "Le hall des sorciers — zone sûre" },
			{ text = "DONJONS", handler = "onDungeons", hint = "Choisir une faille à nettoyer" },
			{ text = "HUB AFK", handler = "onAfk", hint = "Gains passifs, aucun danger" },
		},
	},
}

local MainMenu = {}
MainMenu.__index = MainMenu

local player = Players.LocalPlayer

--- Espace les lettres d'un titre, à la manière des jaquettes d'anime.
local function spaced(text: string): string
	local pieces = {}
	for _, code in utf8.codes(text) do
		table.insert(pieces, utf8.char(code))
	end
	return table.concat(pieces, utf8.char(0x2009))
end

function MainMenu.new(parent: ScreenGui, handlers: { [string]: () -> () })
	local self = setmetatable({}, MainMenu)

	self.visible = false
	self.page = "main"
	self._orbitConnection = nil :: any

	local root = Theme.create("Frame", {
		Name = "MenuPrincipal",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = GameConfig.Palette.void,
		BackgroundTransparency = 0.28,
		BorderSizePixel = 0,
		Visible = false,
		ZIndex = 20,
		Parent = parent,
	})
	self.root = root

	-- Vignettage : sombre en haut et en bas, dégagé au centre.
	Theme.create("UIGradient", {
		Color = ColorSequence.new(GameConfig.Palette.void, Color3.fromRGB(18, 10, 34)),
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.02),
			NumberSequenceKeypoint.new(0.45, 0.6),
			NumberSequenceKeypoint.new(0.55, 0.6),
			NumberSequenceKeypoint.new(1, 0.02),
		}),
		Rotation = 90,
		Parent = root,
	})

	-- Poussières d'énergie qui montent lentement.
	local dust = Theme.create("Frame", {
		Name = "Poussières",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		ZIndex = 20,
		Parent = root,
	})

	for index = 1, DUST_COUNT do
		local size = math.random(2, 4)
		local mote = Theme.create("Frame", {
			Name = "Poussière" .. index,
			Size = UDim2.fromOffset(size, size),
			Position = UDim2.fromScale(math.random(), math.random()),
			BackgroundColor3 = if index % 3 == 0 then GameConfig.Palette.accentSoft else GameConfig.Palette.accent,
			BackgroundTransparency = 0.35 + math.random() * 0.4,
			BorderSizePixel = 0,
			ZIndex = 20,
			Parent = dust,
		}, { Theme.corner(size) })

		task.spawn(function()
			while mote.Parent do
				local duration = 9 + math.random() * 10
				local startX = math.random()
				mote.Position = UDim2.fromScale(startX, 1.05)
				local drift = startX + (math.random() - 0.5) * 0.08
				local tween = TweenService:Create(mote, TweenInfo.new(duration, Enum.EasingStyle.Linear), {
					Position = UDim2.fromScale(drift, -0.05),
				})
				tween:Play()
				tween.Completed:Wait()
			end
		end)
	end

	-- Le grand cadre de la maquette.
	local board = Theme.create("Frame", {
		Name = "Cadre",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.8, 0.82),
		BackgroundColor3 = Color3.fromRGB(7, 6, 12),
		BackgroundTransparency = 0.42,
		BorderSizePixel = 0,
		ZIndex = 21,
		Parent = root,
	}, {
		Theme.corner(4),
		Theme.stroke(GameConfig.Palette.stroke, 1, 0.25),
		Theme.create("UIAspectRatioConstraint", { AspectRatio = 1.6, DominantAxis = Enum.DominantAxis.Width }),
	})
	Theme.brackets(board, GameConfig.Palette.accent, 34, 3)
	Theme.glow(board, GameConfig.Palette.accentDeep, 1.4)

	-- Bandeau supérieur : petite mention « système ».
	Theme.create("TextLabel", {
		Name = "Mention",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0.045),
		Size = UDim2.fromScale(0.6, 0.035),
		BackgroundTransparency = 1,
		Font = Theme.DisplayFont,
		Text = spaced("SYSTÈME D'ÉVEIL"),
		TextScaled = true,
		TextColor3 = GameConfig.Palette.accentSoft,
		TextTransparency = 0.35,
		ZIndex = 22,
		Parent = board,
	})

	self.title = Theme.create("TextLabel", {
		Name = "Titre",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0.095),
		Size = UDim2.fromScale(0.92, 0.13),
		BackgroundTransparency = 1,
		Font = Theme.TitleFont,
		Text = spaced(GameConfig.GameName),
		TextScaled = true,
		TextColor3 = GameConfig.Palette.text,
		ZIndex = 22,
		Parent = board,
	})
	Theme.shimmer(self.title, GameConfig.Palette.text, 4.5)

	local underline = Theme.create("Frame", {
		Name = "Filet",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0.235),
		Size = UDim2.fromScale(0.34, 0.004),
		BackgroundColor3 = GameConfig.Palette.accent,
		BorderSizePixel = 0,
		ZIndex = 22,
		Parent = board,
	})
	Theme.shimmer(underline, GameConfig.Palette.accent, 3)

	self.subtitle = Theme.create("TextLabel", {
		Name = "SousTitre",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0.255),
		Size = UDim2.fromScale(0.8, 0.042),
		BackgroundTransparency = 1,
		Font = Theme.BodyFont,
		Text = PAGES.main.subtitle,
		TextScaled = true,
		TextColor3 = GameConfig.Palette.textDim,
		ZIndex = 22,
		Parent = board,
	})

	-- Une colonne de boutons par page, superposées.
	self.pages = {}
	for pageName, page in pairs(PAGES) do
		local column = Theme.create("Frame", {
			Name = "Page_" .. pageName,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.615),
			Size = UDim2.fromScale(0.5, 0.44),
			BackgroundTransparency = 1,
			Visible = pageName == "main",
			ZIndex = 22,
			Parent = board,
		}, {
			Theme.create("UIListLayout", {
				FillDirection = Enum.FillDirection.Vertical,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				Padding = UDim.new(0, 14),
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
		})

		for index, definition in ipairs(page.buttons) do
			local button = Theme.menuButton(definition.text, index)
			button.ZIndex = 23
			button.Parent = column

			local label = Theme.create("TextLabel", {
				Name = "Libellé",
				Position = UDim2.fromScale(0.08, if definition.hint then 0.14 else 0.22),
				Size = UDim2.fromScale(0.84, if definition.hint then 0.42 else 0.56),
				BackgroundTransparency = 1,
				Font = Theme.HeadingFont,
				Text = spaced(definition.text),
				TextScaled = true,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextColor3 = GameConfig.Palette.text,
				ZIndex = 24,
				Parent = button,
			})

			if definition.hint then
				Theme.create("TextLabel", {
					Name = "Indice",
					Position = UDim2.fromScale(0.08, 0.58),
					Size = UDim2.fromScale(0.84, 0.26),
					BackgroundTransparency = 1,
					Font = Theme.BodyFont,
					Text = definition.hint,
					TextScaled = true,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextColor3 = GameConfig.Palette.textDim,
					ZIndex = 24,
					Parent = button,
				})
			end

			-- Chevron discret à droite.
			Theme.create("TextLabel", {
				Name = "Chevron",
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.fromScale(0.94, 0.5),
				Size = UDim2.fromScale(0.06, 0.4),
				BackgroundTransparency = 1,
				Font = Theme.HeadingFont,
				Text = "›",
				TextScaled = true,
				TextColor3 = GameConfig.Palette.accent,
				TextTransparency = 0.3,
				ZIndex = 24,
				Parent = button,
			})

			button.MouseEnter:Connect(function()
				TweenService:Create(label, TweenInfo.new(0.15), { TextColor3 = GameConfig.Palette.accent }):Play()
			end)
			button.MouseLeave:Connect(function()
				TweenService:Create(label, TweenInfo.new(0.15), { TextColor3 = GameConfig.Palette.text }):Play()
			end)

			button.Activated:Connect(function()
				if definition.handler == "onPlayPage" then
					self:setPage("play")
					return
				end
				local handler = handlers[definition.handler]
				if handler then
					handler()
				end
			end)
		end

		self.pages[pageName] = column
	end

	self.backButton = Theme.button("‹  RETOUR", GameConfig.Palette.stroke, {
		Name = "Retour",
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.fromScale(0.07, 0.93),
		Size = UDim2.fromScale(0.16, 0.06),
		TextColor3 = GameConfig.Palette.textDim,
		Visible = false,
		ZIndex = 23,
		Parent = board,
	})

	self.backButton.Activated:Connect(function()
		self:setPage("main")
	end)

	Theme.create("TextLabel", {
		Name = "Version",
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.fromScale(0.93, 0.93),
		Size = UDim2.fromScale(0.4, 0.04),
		BackgroundTransparency = 1,
		Font = Theme.BodyFont,
		Text = ("v%s   •   touche M pour rouvrir le menu"):format(GameConfig.Version),
		TextScaled = true,
		TextXAlignment = Enum.TextXAlignment.Right,
		TextColor3 = GameConfig.Palette.textFaint,
		ZIndex = 22,
		Parent = board,
	})

	self.blur = Theme.create("BlurEffect", { Name = "MenuBlur", Size = 0, Parent = Lighting })

	return self
end

function MainMenu:setPage(pageName: string)
	local page = PAGES[pageName]
	if not page then
		return
	end

	self.page = pageName
	self.title.Text = spaced(page.title)
	self.subtitle.Text = page.subtitle
	self.backButton.Visible = pageName ~= "main"

	for name, column in pairs(self.pages) do
		local active = name == pageName
		column.Visible = active
		if active then
			-- Petite entrée par le bas, pour marquer le changement de page.
			column.Position = UDim2.fromScale(0.5, 0.66)
			TweenService:Create(column, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
				Position = UDim2.fromScale(0.5, 0.615),
			}):Play()
		end
	end
end

local function startOrbit(self)
	local camera = workspace.CurrentCamera
	if not camera then
		return
	end

	camera.CameraType = Enum.CameraType.Scriptable
	local angle = 0

	self._orbitConnection = RunService.RenderStepped:Connect(function(delta)
		angle += delta * ORBIT_SPEED
		local height = 36 + math.sin(angle * 0.7) * 8
		local position = ORBIT_CENTER
			+ Vector3.new(math.cos(angle) * ORBIT_RADIUS, height, math.sin(angle) * ORBIT_RADIUS)
		camera.CFrame = CFrame.lookAt(position, ORBIT_CENTER)
	end)
end

local function stopOrbit(self)
	if self._orbitConnection then
		self._orbitConnection:Disconnect()
		self._orbitConnection = nil
	end

	local camera = workspace.CurrentCamera
	if camera then
		camera.CameraType = Enum.CameraType.Custom
		camera.CameraSubject = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	end
end

function MainMenu:show(pageName: string?)
	self:setPage(pageName or "main")

	if self.visible then
		return
	end
	self.visible = true
	self.root.Visible = true

	TweenService:Create(self.blur, TweenInfo.new(0.45), { Size = 22 }):Play()
	startOrbit(self)
end

function MainMenu:hide()
	if not self.visible then
		return
	end
	self.visible = false
	self.root.Visible = false

	TweenService:Create(self.blur, TweenInfo.new(0.3), { Size = 0 }):Play()
	stopOrbit(self)
end

function MainMenu:isVisible(): boolean
	return self.visible
end

return MainMenu
