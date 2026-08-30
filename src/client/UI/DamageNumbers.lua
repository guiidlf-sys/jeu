--!strict
--[[
	DamageNumbers
	Chiffres de dégâts flottants et retour visuel quand on encaisse un coup.
]]

local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared.GameConfig)
local Remotes = require(Shared.Remotes)
local Util = require(Shared.Util)

local Theme = require(script.Parent.Theme)

local DamageNumbers = {}

--- Affiche un chiffre de dégâts dans le monde, à la position touchée.
local function spawnNumber(position: Vector3, amount: number, crit: boolean)
	local anchor = Instance.new("Part")
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.CanTouch = false
	anchor.Transparency = 1
	anchor.Size = Vector3.one
	anchor.Position = position + Vector3.new(math.random(-2, 2), 3, math.random(-2, 2))
	anchor.Parent = workspace

	local gui = Theme.create("BillboardGui", {
		Size = UDim2.fromScale(4, 2),
		AlwaysOnTop = true,
		MaxDistance = 200,
		Adornee = anchor,
		Parent = anchor,
	})

	local label = Theme.create("TextLabel", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Font = if crit then Theme.TitleFont else Theme.HeadingFont,
		Text = if crit then ("%s !"):format(Util.formatNumber(amount)) else Util.formatNumber(amount),
		TextScaled = true,
		TextColor3 = if crit then GameConfig.Palette.danger else GameConfig.Palette.text,
		TextStrokeTransparency = 0.35,
		Parent = gui,
	})

	local goal = anchor.Position + Vector3.new(0, 6, 0)
	TweenService:Create(anchor, TweenInfo.new(0.9, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Position = goal,
	}):Play()
	TweenService:Create(label, TweenInfo.new(0.9), {
		TextTransparency = 1,
		TextStrokeTransparency = 1,
	}):Play()

	Debris:AddItem(anchor, 1)
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
