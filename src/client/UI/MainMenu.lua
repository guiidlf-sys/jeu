--!strict
--[[
	MainMenu
	Reprend la maquette : un grand cadre, le nom du jeu en haut, puis les
	boutons JOUER / BOUTIQUE / CRÉDIT empilés au centre.
	Le fond est une vue caméra qui tourne lentement autour du hall.
]]

local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared.GameConfig)

local Theme = require(script.Parent.Theme)

local ORBIT_CENTER = Vector3.new(0, 14, 0)
local ORBIT_RADIUS = 105
local ORBIT_SPEED = 0.06

local MainMenu = {}
MainMenu.__index = MainMenu

local player = Players.LocalPlayer

function MainMenu.new(parent: ScreenGui, handlers: { [string]: () -> () })
	local self = setmetatable({}, MainMenu)

	self.visible = false
	self._orbitConnection = nil :: any

	local root = Theme.create("Frame", {
		Name = "MenuPrincipal",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = GameConfig.Palette.background,
		BackgroundTransparency = 0.25,
		BorderSizePixel = 0,
		Visible = false,
		ZIndex = 20,
		Parent = parent,
	})
	self.root = root

	-- Dégradé sombre : lisibilité du texte par-dessus la vue 3D.
	Theme.create("UIGradient", {
		Color = ColorSequence.new(Color3.fromRGB(4, 4, 10), Color3.fromRGB(16, 10, 30)),
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.15),
			NumberSequenceKeypoint.new(0.5, 0.55),
			NumberSequenceKeypoint.new(1, 0.15),
		}),
		Rotation = 90,
		Parent = root,
	})

	-- Le grand cadre du croquis.
	local board = Theme.create("Frame", {
		Name = "Cadre",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.78, 0.8),
		BackgroundColor3 = Color3.fromRGB(8, 8, 14),
		BackgroundTransparency = 0.35,
		BorderSizePixel = 0,
		ZIndex = 21,
		Parent = root,
	}, {
		Theme.corner(4),
		Theme.stroke(GameConfig.Palette.text, 3, 0.1),
		Theme.create("UIAspectRatioConstraint", { AspectRatio = 1.55, DominantAxis = Enum.DominantAxis.Width }),
	})

	local title = Theme.create("TextLabel", {
		Name = "Titre",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0.06),
		Size = UDim2.fromScale(0.9, 0.16),
		BackgroundTransparency = 1,
		Font = Theme.TitleFont,
		Text = GameConfig.GameName,
		TextScaled = true,
		TextColor3 = GameConfig.Palette.text,
		TextStrokeTransparency = 0.6,
		ZIndex = 22,
		Parent = board,
	}, {
		Theme.create("UIGradient", {
			Color = ColorSequence.new(GameConfig.Palette.text, GameConfig.Palette.accent),
			Rotation = 90,
		}),
	})
	self.title = title

	local subtitle = Theme.create("TextLabel", {
		Name = "SousTitre",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0.225),
		Size = UDim2.fromScale(0.8, 0.05),
		BackgroundTransparency = 1,
		Font = Theme.BodyFont,
		Text = "Deviens le sorcier le plus fort — une faille à la fois.",
		TextScaled = true,
		TextColor3 = GameConfig.Palette.textDim,
		ZIndex = 22,
		Parent = board,
	})
	self.subtitle = subtitle

	-- Colonne de boutons, comme sur la maquette.
	local buttons = Theme.create("Frame", {
		Name = "Boutons",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.58),
		Size = UDim2.fromScale(0.44, 0.42),
		BackgroundTransparency = 1,
		ZIndex = 22,
		Parent = board,
	}, {
		Theme.create("UIListLayout", {
			FillDirection = Enum.FillDirection.Vertical,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			Padding = UDim.new(0, 18),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})

	local definitions = {
		{ text = "JOUER", handler = "onPlay" },
		{ text = "BOUTIQUE", handler = "onShop" },
		{ text = "CRÉDIT", handler = "onCredits" },
	}

	for index, definition in ipairs(definitions) do
		local button = Theme.menuButton(definition.text, index)
		button.ZIndex = 23
		button.Parent = buttons

		local stroke = button:FindFirstChildOfClass("UIStroke")

		button.MouseEnter:Connect(function()
			TweenService:Create(button, TweenInfo.new(0.15), {
				BackgroundColor3 = GameConfig.Palette.accent,
				BackgroundTransparency = 0.35,
			}):Play()
			if stroke then
				TweenService:Create(stroke, TweenInfo.new(0.15), { Color = GameConfig.Palette.accent }):Play()
			end
		end)

		button.MouseLeave:Connect(function()
			TweenService:Create(button, TweenInfo.new(0.15), {
				BackgroundColor3 = GameConfig.Palette.panel,
				BackgroundTransparency = 0.15,
			}):Play()
			if stroke then
				TweenService:Create(stroke, TweenInfo.new(0.15), { Color = GameConfig.Palette.text }):Play()
			end
		end)

		button.Activated:Connect(function()
			local handler = handlers[definition.handler]
			if handler then
				handler()
			end
		end)
	end

	local version = Theme.create("TextLabel", {
		Name = "Version",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.fromScale(0.5, 0.97),
		Size = UDim2.fromScale(0.6, 0.045),
		BackgroundTransparency = 1,
		Font = Theme.BodyFont,
		Text = ("v%s — touche M pour rouvrir le menu"):format(GameConfig.Version),
		TextScaled = true,
		TextColor3 = GameConfig.Palette.textDim,
		TextTransparency = 0.25,
		ZIndex = 22,
		Parent = board,
	})
	self.version = version

	self.blur = Theme.create("BlurEffect", { Name = "MenuBlur", Size = 0, Parent = Lighting })

	return self
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
		local position = ORBIT_CENTER
			+ Vector3.new(math.cos(angle) * ORBIT_RADIUS, 34, math.sin(angle) * ORBIT_RADIUS)
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

function MainMenu:show()
	if self.visible then
		return
	end
	self.visible = true
	self.root.Visible = true

	TweenService:Create(self.blur, TweenInfo.new(0.4), { Size = 18 }):Play()
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
