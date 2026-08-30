--!strict
--[[
	DamageNumbers
	Chiffres de dégâts flottants. Les coups critiques sont plus gros, dorés,
	et partent plus haut.
]]

local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared.GameConfig)
local Remotes = require(Shared.Remotes)
local Util = require(Shared.Util)

local Theme = require(script.Parent.Theme)

local Palette = GameConfig.Palette

local DamageNumbers = {}

local function spawnNumber(position: Vector3, amount: number, crit: boolean)
	local anchor = Instance.new("Part")
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.CanTouch = false
	anchor.Transparency = 1
	anchor.Size = Vector3.one
	anchor.Position = position + Vector3.new(math.random(-25, 25) / 10, 3, math.random(-25, 25) / 10)
	anchor.Parent = workspace

	local gui = Theme.create("BillboardGui", {
		Size = if crit then UDim2.fromScale(7, 3.4) else UDim2.fromScale(4.4, 2.2),
		AlwaysOnTop = true,
		MaxDistance = 220,
		Adornee = anchor,
		Parent = anchor,
	})

	Theme.create("TextLabel", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Font = Theme.NumberFont,
		Text = Util.formatNumber(amount),
		TextScaled = true,
		TextColor3 = if crit then Palette.gold else Palette.text,
		TextStrokeTransparency = 0.25,
		Parent = gui,
	})

	if crit then
		Theme.create("TextLabel", {
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.fromScale(0.5, 0.72),
			Size = UDim2.fromScale(1, 0.28),
			BackgroundTransparency = 1,
			Font = Theme.DisplayFont,
			Text = "CRITIQUE",
			TextScaled = true,
			TextColor3 = Palette.danger,
			TextStrokeTransparency = 0.4,
			Parent = gui,
		})
	end

	-- Montée avec une légère dérive latérale.
	local rise = if crit then 8 else 5.5
	local drift = Vector3.new(math.random(-15, 15) / 10, rise, math.random(-15, 15) / 10)
	local duration = if crit then 1.15 else 0.85

	TweenService:Create(anchor, TweenInfo.new(duration, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
		Position = anchor.Position + drift,
	}):Play()

	-- Petit sursaut d'échelle à l'apparition.
	local target = gui.Size
	gui.Size = UDim2.fromScale(target.X.Scale * 0.5, target.Y.Scale * 0.5)
	TweenService:Create(gui, TweenInfo.new(0.16, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = target,
	}):Play()

	task.delay(duration * 0.4, function()
		for _, child in ipairs(gui:GetChildren()) do
			if child:IsA("TextLabel") then
				TweenService:Create(child, TweenInfo.new(duration * 0.6), {
					TextTransparency = 1,
					TextStrokeTransparency = 1,
				}):Play()
			end
		end
	end)

	Debris:AddItem(anchor, duration + 0.3)
end

function DamageNumbers.init(onDamageTaken: (() -> ())?)
	Remotes.event("CombatFeedback").OnClientEvent:Connect(function(payload)
		if typeof(payload) ~= "table" then
			return
		end

		if payload.kind == "dealt" and payload.position then
			spawnNumber(payload.position, payload.amount or 0, payload.crit == true)
		elseif payload.kind == "taken" and onDamageTaken then
			onDamageTaken()
		end
	end)
end

return DamageNumbers
