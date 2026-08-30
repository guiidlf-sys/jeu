--!strict
--[[
	SkillCatalog
	Techniques maudites du joueur. `shape` décrit la zone de dégâts que le
	serveur calcule lui-même (le client ne fait qu'envoyer l'intention).
]]

export type Skill = {
	id: string,
	name: string,
	description: string,
	unlockLevel: number,
	cost: number, -- énergie maudite
	cooldown: number,
	damageMultiplier: number, -- multiplie les dégâts de base du joueur
	shape: "arc" | "circle" | "line",
	range: number,
	angle: number?, -- pour "arc", en degrés
	radius: number?, -- pour "circle" / "line"
	color: Color3,
	keybind: Enum.KeyCode?,
}

local SkillCatalog = {}

local LIST: { Skill } = {
	{
		id = "poing_maudit",
		name = "Poing Maudit",
		description = "Enchaînement rapide chargé d'énergie maudite.",
		unlockLevel = 1,
		cost = 0,
		cooldown = 0.55,
		damageMultiplier = 1,
		shape = "arc",
		range = 9,
		angle = 110,
		color = Color3.fromRGB(190, 190, 210),
		keybind = nil, -- clic gauche
	},
	{
		id = "lame_de_vide",
		name = "Lame de Vide",
		description = "Une entaille nette qui traverse tout sur son passage.",
		unlockLevel = 3,
		cost = 18,
		cooldown = 4,
		damageMultiplier = 2.2,
		shape = "line",
		range = 26,
		radius = 4,
		color = Color3.fromRGB(96, 200, 255),
		keybind = Enum.KeyCode.E,
	},
	{
		id = "eclat_dame",
		name = "Éclat d'Âme",
		description = "Détonation d'énergie autour de soi, repousse les esprits.",
		unlockLevel = 8,
		cost = 30,
		cooldown = 8,
		damageMultiplier = 2.8,
		shape = "circle",
		range = 0,
		radius = 18,
		color = Color3.fromRGB(150, 110, 255),
		keybind = Enum.KeyCode.R,
	},
	{
		id = "chaines_funestes",
		name = "Chaînes Funestes",
		description = "Des chaînes jaillissent du sol et entravent la cible.",
		unlockLevel = 15,
		cost = 40,
		cooldown = 12,
		damageMultiplier = 3.4,
		shape = "line",
		range = 34,
		radius = 6,
		color = Color3.fromRGB(255, 205, 90),
		keybind = Enum.KeyCode.F,
	},
	{
		id = "domaine_restreint",
		name = "Domaine Restreint",
		description = "Déploie ton domaine : rien n'en réchappe.",
		unlockLevel = 30,
		cost = 75,
		cooldown = 45,
		damageMultiplier = 7,
		shape = "circle",
		range = 0,
		radius = 34,
		color = Color3.fromRGB(235, 80, 90),
		keybind = Enum.KeyCode.G,
	},
}

SkillCatalog.List = LIST

local byId: { [string]: Skill } = {}
for _, skill in ipairs(LIST) do
	byId[skill.id] = skill
end

function SkillCatalog.get(id: string): Skill?
	return byId[id]
end

function SkillCatalog.unlockedFor(level: number): { Skill }
	local unlocked = {}
	for _, skill in ipairs(SkillCatalog.List) do
		if level >= skill.unlockLevel then
			table.insert(unlocked, skill)
		end
	end
	return unlocked :: any
end

return SkillCatalog
