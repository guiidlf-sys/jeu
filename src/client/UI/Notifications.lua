--!strict
--[[
	Notifications
	Fenêtres « Système » qui glissent depuis la droite (montées de niveau,
	quêtes, entrées/sorties de faille).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared.GameConfig)
local Remotes = require(Shared.Remotes)

local Theme = require(script.Parent.Theme)

local KIND_COLORS = {
	info = GameConfig.Palette.accentSoft,
	levelup = GameConfig.Palette.accent,
	quest = GameConfig.Currencies.yens.color,
	success = GameConfig.Palette.success,
	danger = GameConfig.Palette.danger,
}

local LIFETIME = 5

local Notifications = {}
Notifications.__index = Notifications

function Notifications.new(parent: ScreenGui)
	local self = setmetatable({}, Notifications)

	self.container = Theme.create("Frame", {
		Name = "Notifications",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -18, 0, 92),
		Size = UDim2.new(0, 320, 0, 400),
		BackgroundTransparency = 1,
		ZIndex = 40,
		Parent = parent,
	}, {
		Theme.create("UIListLayout", {
			Padding = UDim.new(0, 8),
			HorizontalAlignment = Enum.HorizontalAlignment.Right,
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})

	self.counter = 0

	Remotes.event("SystemMessage").OnClientEvent:Connect(function(message)
		if typeof(message) == "table" then
			self:push(message.title or "SYSTÈME", message.body or "", message.kind)
		end
	end)

	return self
end

function Notifications:push(title: string, body: string, kind: string?)
	local color = KIND_COLORS[kind or "info"] or GameConfig.Palette.accentSoft
	self.counter += 1

	local card = Theme.panel({
		Name = "Notif" .. self.counter,
		Size = UDim2.new(1, 0, 0, 10),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 0.05,
		LayoutOrder = self.counter,
		ZIndex = 41,
		Parent = self.container,
	})
	Theme.padding(12).Parent = card

	local stroke = card:FindFirstChildOfClass("UIStroke")
	if stroke then
		stroke.Color = color
		stroke.Transparency = 0.1
	end

	Theme.create("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder, Parent = card })

	Theme.create("TextLabel", {
		Size = UDim2.new(1, 0, 0, 20),
		BackgroundTransparency = 1,
		Font = Theme.TitleFont,
		Text = title,
		TextSize = 15,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = color,
		LayoutOrder = 1,
		ZIndex = 42,
		Parent = card,
	})

	Theme.create("TextLabel", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Font = Theme.BodyFont,
		Text = body,
		TextSize = 13,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		TextColor3 = GameConfig.Palette.text,
		LayoutOrder = 2,
		ZIndex = 42,
		Parent = card,
	})

	-- Entrée : glissement + fondu.
	card.BackgroundTransparency = 1
	card.Position = UDim2.fromOffset(40, 0)
	TweenService:Create(card, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		BackgroundTransparency = 0.05,
		Position = UDim2.fromOffset(0, 0),
	}):Play()

	task.delay(LIFETIME, function()
		if not card.Parent then
			return
		end
		local fade = TweenService:Create(card, TweenInfo.new(0.35), {
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(40, 0),
		})
		for _, child in ipairs(card:GetDescendants()) do
			if child:IsA("TextLabel") then
				TweenService:Create(child, TweenInfo.new(0.35), { TextTransparency = 1 }):Play()
			elseif child:IsA("UIStroke") then
				TweenService:Create(child, TweenInfo.new(0.35), { Transparency = 1 }):Play()
			end
		end
		fade:Play()
		fade.Completed:Wait()
		card:Destroy()
	end)
end

return Notifications
