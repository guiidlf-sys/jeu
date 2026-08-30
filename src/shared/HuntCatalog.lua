--!strict
--[[
	HuntCatalog
	Contrats de chasse. Contrairement aux quêtes quotidiennes, ils doivent être
	acceptés — et tant qu'un contrat est actif, les espèces visées deviennent
	hostiles envers le chasseur. Ils sont répétables.
]]

export type Hunt = {
	id: string,
	name: string,
	description: string,
	targets: { string }, -- identifiants d'esprits rendus hostiles
	goal: number,
	minLevel: number,
	color: Color3,
	reward: { yens: number, xp: number, fragments: number },
}

local HuntCatalog = {}

HuntCatalog.MaxActive = 3

local LIST: { Hunt } = {
	{
		id = "contrat_larves",
		name = "Contrat : Larves Maudites",
		description = "Les larves pullulent au nord du hall. Éliminez-en 10.",
		targets = { "larve" },
		goal = 10,
		minLevel = 1,
		color = Color3.fromRGB(150, 110, 255),
		reward = { yens = 250, xp = 220, fragments = 0 },
	},
	{
		id = "contrat_rampants",
		name = "Contrat : Rampants Difformes",
		description = "Plus lourds, plus tenaces. Éliminez 10 Rampants Difformes.",
		targets = { "rampant" },
		goal = 10,
		minLevel = 6,
		color = Color3.fromRGB(120, 255, 170),
		reward = { yens = 700, xp = 600, fragments = 1 },
	},
	{
		id = "contrat_purge",
		name = "Contrat : Purge du Terrain",
		description = "Peu importe l'espèce : 20 esprits de bas rang, tous types confondus.",
		targets = { "larve", "rampant", "hurleur" },
		goal = 20,
		minLevel = 10,
		color = Color3.fromRGB(96, 200, 255),
		reward = { yens = 1800, xp = 1600, fragments = 3 },
	},
	{
		id = "contrat_hurleurs",
		name = "Contrat : Hurleurs d'Ossements",
		description = "Leur cri annonce les failles. Faites-en taire 12.",
		targets = { "hurleur" },
		goal = 12,
		minLevel = 16,
		color = Color3.fromRGB(255, 205, 90),
		reward = { yens = 2600, xp = 2800, fragments = 5 },
	},
	{
		id = "contrat_spectres",
		name = "Contrat : Spectres Voraces",
		description = "Ils se nourrissent de l'énergie des sorciers. 12 spectres.",
		targets = { "spectre" },
		goal = 12,
		minLevel = 28,
		color = Color3.fromRGB(96, 200, 255),
		reward = { yens = 6000, xp = 9000, fragments = 12 },
	},
	{
		id = "contrat_calamites",
		name = "Contrat : Calamités Sans Nom",
		description = "Réservé aux grades supérieurs. 10 calamités, rien de moins.",
		targets = { "calamite" },
		goal = 10,
		minLevel = 42,
		color = Color3.fromRGB(235, 80, 90),
		reward = { yens = 16000, xp = 30000, fragments = 30 },
	},
}

HuntCatalog.List = LIST

local byId: { [string]: Hunt } = {}
for _, hunt in ipairs(LIST) do
	byId[hunt.id] = hunt
end

function HuntCatalog.get(id: string): Hunt?
	return byId[id]
end

--- Vrai si ce contrat vise ce type d'esprit.
function HuntCatalog.targets(hunt: Hunt, mobId: string): boolean
	return table.find(hunt.targets, mobId) ~= nil
end

return HuntCatalog
