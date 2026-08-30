--!strict
--[[
	Notifications
	Fenêtres « Système » qui glissent depuis la droite. Les montées de niveau
	ont droit à un bandeau plein écran, plus solennel.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared.GameConfig)
local Remotes = require(Shared.Remotes)

local Theme = require(script.Parent.Theme)

local Palette = GameConfig.Palette

local KIND_COLORS = {
	info = Palette.accentSoft,
	levelup = Palette.accent,
	quest = Palette.gold,
	success = Palette.success,
	danger = Palette.danger,
}

local LIFETIME = 5.5

local Notifications = {}
Notifications.__index = Notifications

function Notifications.new(parent: ScreenGui)
	local self = setmetatable({}, Notifications)

	self.container = Theme.create("Frame", {
		Name = "Notifications",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -20, 0, 96),
		Size = UDim2.fromOffset(330, 460),
		BackgroundTransparency = 1,
		ZIndex = 40,
		Parent = parent,
	}, { Theme.list(Enum.FillDirection.Vertical, 8, Enum.HorizontalAlignment.Right) })

	-- Bandeau de montée de niveau, au centre de l'écran.
	self.banner = Theme.create("Frame", {
		Name = "Bandeau",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.3),
		Size = UDim2.new(1, 0, 0, 96),
		BackgroundColor3 = Palette.void,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Visible = false,
		ZIndex = 45,
		Parent = parent,
	})

	self.bannerTitle = Theme.create("TextLabel", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.42),
		Size = UDim2.fromScale(0.8, 0.5),
		BackgroundTransparency = 1,
		Font = Theme.TitleFont,
		Text = "",
		TextScaled = true,
		TextColor3 = Palette.accent,
		ZIndex = 46,
		Parent = self.banner,
	})

	self.bannerBody = Theme.create("TextLabel", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.82),
		Size = UDim2.fromScale(0.7, 0.24),
		BackgroundTransparency = 1,
		Font = Theme.BodyFont,
		Text = "",
		TextScaled = true,
		TextColor3 = Palette.textDim,
		ZIndex = 46,
		Parent = self.banner,
	})

	self.counter = 0

	Remotes.event("SystemMessage").OnClientEvent:Connect(function(message)
		if typeof(message) ~= "table" then
			return
		end
		if message.kind == "levelup" then
			self:banner_(message.title or "", message.body or "")
		end
		self:push(message.title or "SYSTÈME", message.body or "", message.kind)
	end)

	return self
end

--- Bandeau central, réservé aux moments forts.
function Notifications:banner_(title: string, body: string)
	self.bannerTitle.Text = title
	self.bannerBody.Text = body
	self.banner.Visible = true

	self.banner.BackgroundTransparency = 0.25
	self.bannerTitle.TextTransparency = 1
	self.bannerTitle.Size = UDim2.fromScale(0.6, 0.5)

	TweenService:Create(self.bannerTitle, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		TextTransparency = 0,
		Size = UDim2.fromScale(0.8, 0.5),
	}):Play()

	task.delay(1.8, function()
		TweenService:Create(self.banner, TweenInfo.new(0.5), { BackgroundTransparency = 1 }):Play()
		TweenService:Create(self.bannerTitle, TweenInfo.new(0.5), { TextTransparency = 1 }):Play()
		TweenService:Create(self.bannerBody, TweenInfo.new(0.5), { TextTransparency = 1 }):Play()
		task.wait(0.55)
		self.banner.Visible = false
		self.bannerBody.TextTransparency = 0
	end)
end

function Notifications:push(title: string, body: string, kind: string?)
	local color = KIND_COLORS[kind or "info"] or Palette.accentSoft
	self.counter += 1

	local card = Theme.panel({
		Name = "Notif" .. self.counter,
		Size = UDim2.new(1, 0, 0, 10),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 0.03,
		LayoutOrder = self.counter,
		ZIndex = 41,
		Parent = self.container,
	}, { accent = color, brackets = false })

	-- Barre d'accent verticale, comme une fiche de dossier.
	Theme.create("Frame", {
		Name = "Accent",
		Size = UDim2.new(0, 2, 1, 0),
		BackgroundColor3 = color,
		BorderSizePixel = 0,
		ZIndex = 42,
		Parent = card,
	})

	local content = Theme.create("Frame", {
		Name = "Contenu",
		Size = UDim2.new(1, 0, 0, 10),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		ZIndex = 42,
		Parent = card,
	}, { Theme.list(Enum.FillDirection.Vertical, 4), Theme.padding(12, 14) })

	Theme.create("TextLabel", {
		Size = UDim2.new(1, 0, 0, 18),
		BackgroundTransparency = 1,
		Font = Theme.DisplayFont,
		Text = title,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = color,
		LayoutOrder = 1,
		ZIndex = 43,
		Parent = content,
	})

	Theme.create("TextLabel", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Font = Theme.BodyFont,
		Text = body,
		TextSize = 12,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		TextColor3 = Palette.text,
		LayoutOrder = 2,
		ZIndex = 43,
		Parent = content,
	})

	-- Entrée : glissement depuis la droite.
	card.BackgroundTransparency = 1
	card.Position = UDim2.fromOffset(50, 0)
	TweenService:Create(card, TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
		BackgroundTransparency = 0.03,
		Position = UDim2.fromOffset(0, 0),
	}):Play()

	task.delay(LIFETIME, function()
		if not card.Parent then
			return
		end
		for _, child in ipairs(card:GetDescendants()) do
			if child:IsA("TextLabel") then
				TweenService:Create(child, TweenInfo.new(0.35), { TextTransparency = 1 }):Play()
			elseif child:IsA("UIStroke") then
				TweenService:Create(child, TweenInfo.new(0.35), { Transparency = 1 }):Play()
			elseif child:IsA("Frame") then
				TweenService:Create(child, TweenInfo.new(0.35), { BackgroundTransparency = 1 }):Play()
			end
		end
		local fade = TweenService:Create(card, TweenInfo.new(0.35), {
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(50, 0),
		})
		fade:Play()
		fade.Completed:Wait()
		card:Destroy()
	end)
end

return Notifications
