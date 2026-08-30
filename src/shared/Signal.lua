--!strict
--[[
	Signal
	Événement minimaliste (sans BindableEvent) pour la communication interne
	entre services serveur.
]]

export type Connection = { disconnect: (Connection) -> () }

local Signal = {}
Signal.__index = Signal

function Signal.new()
	return setmetatable({ _handlers = {} }, Signal)
end

function Signal:connect(handler: (...any) -> ()): Connection
	local handlers = self._handlers
	table.insert(handlers, handler)

	local connection
	connection = {
		disconnect = function()
			local index = table.find(handlers, handler)
			if index then
				table.remove(handlers, index)
			end
		end,
	}
	return connection
end

function Signal:fire(...: any)
	-- Copie : un handler peut se déconnecter pendant l'émission.
	for _, handler in ipairs(table.clone(self._handlers)) do
		task.spawn(handler, ...)
	end
end

function Signal:destroy()
	table.clear(self._handlers)
end

return Signal
