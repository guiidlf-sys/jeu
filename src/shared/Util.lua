--!strict
--[[
	Util
	Petites fonctions partagées entre le serveur et le client.
]]

local Util = {}

--- Formate un nombre pour l'affichage : 12500 -> "12.5 K".
function Util.formatNumber(value: number): string
	local abs = math.abs(value)
	if abs >= 1e9 then
		return string.format("%.1f Md", value / 1e9)
	elseif abs >= 1e6 then
		return string.format("%.1f M", value / 1e6)
	elseif abs >= 1e4 then
		return string.format("%.1f K", value / 1e3)
	end
	return tostring(math.floor(value))
end

--- Numéro du jour courant (UTC), pour la réinitialisation des quêtes.
function Util.currentDay(): number
	return math.floor(os.time() / 86400)
end

--- Copie profonde d'une table simple (pas de cycles, pas de métatables).
function Util.deepCopy<T>(source: T): T
	if typeof(source) ~= "table" then
		return source
	end
	local copy = {}
	for key, value in pairs(source :: any) do
		copy[key] = Util.deepCopy(value)
	end
	return copy :: any
end

--- Remplit `target` avec les clés manquantes de `template` (migration de données).
function Util.reconcile(target: { [any]: any }, template: { [any]: any })
	for key, value in pairs(template) do
		if target[key] == nil then
			target[key] = Util.deepCopy(value)
		elseif typeof(value) == "table" and typeof(target[key]) == "table" then
			Util.reconcile(target[key], value)
		end
	end
end

--- Renvoie le modèle et l'humanoïde d'un descendant touché, s'il y en a un.
function Util.getCharacterFromPart(part: BasePart): (Model?, Humanoid?)
	local model = part:FindFirstAncestorOfClass("Model")
	while model do
		local humanoid = model:FindFirstChildOfClass("Humanoid")
		if humanoid then
			return model, humanoid
		end
		model = model:FindFirstAncestorOfClass("Model")
	end
	return nil, nil
end

return Util
