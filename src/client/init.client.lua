--!strict
--[[
	Point d'entrée client de MALÉDICTION : ÉVEIL.
	Assemble le menu principal, le HUD et les fenêtres, puis gère les
	raccourcis clavier.
]]

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local CombatController = require(script.CombatController)
local State = require(script.State)

local UI = script.UI
local Credits = require(UI.Credits)
local DamageNumbers = require(UI.DamageNumbers)
local HUD = require(UI.HUD)
local MainMenu = require(UI.MainMenu)
local Notifications = require(UI.Notifications)
local QuestPanel = require(UI.QuestPanel)
local Shop = require(UI.Shop)
local StatsPanel = require(UI.StatsPanel)

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MaledictionUI"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

State.init()

local hud = HUD.new(screenGui)
local shop = Shop.new(screenGui)
local credits = Credits.new(screenGui)
local statsPanel = StatsPanel.new(screenGui)
local questPanel = QuestPanel.new(screenGui)
local notifications = Notifications.new(screenGui)

DamageNumbers.init(function()
	hud:flashDamage()
end)

local menu
local inGame = false

-- Contrôles du joueur (module Roblox standard) : désactivés dans le menu.
local controls
task.spawn(function()
	local playerScripts = player:WaitForChild("PlayerScripts")
	local playerModule = playerScripts:WaitForChild("PlayerModule", 10)
	if not playerModule then
		return
	end

	local ok, module = pcall(require, playerModule)
	if not ok then
		return
	end

	controls = (module :: any):GetControls()
	-- Le module peut arriver après l'ouverture du menu : on resynchronise.
	if inGame then
		controls:Enable()
	else
		controls:Disable()
	end
end)

local function closeAllWindows()
	shop:setVisible(false)
	credits:setVisible(false)
	statsPanel:setVisible(false)
	questPanel:setVisible(false)
end

local function enterGame()
	inGame = true
	menu:hide()
	closeAllWindows()
	hud:setVisible(true)
	CombatController.setEnabled(true)
	if controls then
		controls:Enable()
	end
end

local function openMenu()
	inGame = false
	closeAllWindows()
	hud:setVisible(false)
	CombatController.setEnabled(false)
	if controls then
		controls:Disable()
	end
	menu:show()
end

menu = MainMenu.new(screenGui, {
	onPlay = enterGame,
	onShop = function()
		shop:setVisible(true)
	end,
	onCredits = function()
		credits:setVisible(true)
	end,
})

hud.buttons.stats.Activated:Connect(function()
	statsPanel:toggle()
end)
hud.buttons.quests.Activated:Connect(function()
	questPanel:toggle()
end)
hud.buttons.shop.Activated:Connect(function()
	shop:toggle()
end)
hud.buttons.menu.Activated:Connect(openMenu)

CombatController.init()

-- Raccourcis clavier.
local SHORTCUTS = {
	[Enum.KeyCode.C] = function()
		if inGame then
			statsPanel:toggle()
		end
	end,
	[Enum.KeyCode.Q] = function()
		if inGame then
			questPanel:toggle()
		end
	end,
	[Enum.KeyCode.B] = function()
		if inGame then
			shop:toggle()
		end
	end,
	[Enum.KeyCode.M] = function()
		if inGame then
			openMenu()
		else
			enterGame()
		end
	end,
}

ContextActionService:BindAction("Raccourcis", function(_, state, input)
	if state ~= Enum.UserInputState.Begin or UserInputService:GetFocusedTextBox() then
		return Enum.ContextActionResult.Pass
	end
	local action = SHORTCUTS[input.KeyCode]
	if action then
		action()
	end
	return Enum.ContextActionResult.Pass
end, false, Enum.KeyCode.C, Enum.KeyCode.Q, Enum.KeyCode.B, Enum.KeyCode.M)

-- On démarre sur le menu, comme sur la maquette.
openMenu()

notifications:push(
	"SYSTÈME",
	"Les failles s'ouvrent. Appuie sur JOUER pour rejoindre le hall des sorciers.",
	"info"
)
