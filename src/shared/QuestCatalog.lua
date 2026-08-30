--!strict
--[[
	QuestCatalog
	Quêtes quotidiennes façon "Système" : elles se réinitialisent chaque jour
	et récompensent en points de statistique.
]]

export type Quest = {
	id: string,
	name: string,
	description: string,
	goal: number,
	metric: "kills" | "damage" | "riftsCleared",
	reward: { yens: number, xp: number, statPoints: number },
}

local QuestCatalog = {}

local LIST: { Quest } = {
	{
		id = "purge",
		name = "Purge Quotidienne",
		description = "Éliminer 25 esprits maudits.",
		goal = 25,
		metric = "kills",
		reward = { yens = 400, xp = 300, statPoints = 1 },
	},
	{
		id = "puissance",
		name = "Démonstration de Force",
		description = "Infliger 5 000 dégâts.",
		goal = 5000,
		metric = "damage",
		reward = { yens = 600, xp = 450, statPoints = 1 },
	},
	{
		id = "explorateur",
		name = "Chasseur de Failles",
		description = "Nettoyer 3 failles.",
		goal = 3,
		metric = "riftsCleared",
		reward = { yens = 900, xp = 800, statPoints = 2 },
	},
}

QuestCatalog.List = LIST

local byId: { [string]: Quest } = {}
for _, quest in ipairs(LIST) do
	byId[quest.id] = quest
end

function QuestCatalog.get(id: string): Quest?
	return byId[id]
end

return QuestCatalog
