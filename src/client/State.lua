--!strict
--[[
	State
	Copie locale du profil, tenue à jour par le serveur. Les modules d'UI s'y
	abonnent au lieu d'écouter le remote chacun de leur côté.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared.Remotes)
local Signal = require(Shared.Signal)

local State = {}

State.profile = nil :: any
State.Changed = Signal.new()

function State.init()
	Remotes.event("ProfileUpdated").OnClientEvent:Connect(function(profile)
		State.profile = profile
		State.Changed:fire(profile)
	end)

	task.spawn(function()
		local ok, profile = pcall(function()
			return Remotes.func("GetProfile"):InvokeServer()
		end)
		if ok and profile and not State.profile then
			State.profile = profile
			State.Changed:fire(profile)
		end
	end)
end

--- Abonne un callback et l'appelle immédiatement si le profil est déjà là.
function State.observe(callback: (any) -> ())
	State.Changed:connect(callback)
	if State.profile then
		task.spawn(callback, State.profile)
	end
end

return State
