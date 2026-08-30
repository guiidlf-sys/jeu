--!strict
--[[
	MobCatalog
	Esprits maudits. `tier` sert au choix des vagues dans les failles.
]]

export type Mob = {
	id: string,
	name: string,
	tier: number,
	health: number,
	damage: number,
	walkSpeed: number,
	attackRange: number,
	attackCooldown: number,
	xp: number,
	yens: number,
	fragmentChance: number,
	size: Vector3,
	color: Color3,
	glow: Color3,
}

local MobCatalog = {}

local LIST: { Mob } = {
	{
		id = "larve",
		name = "Larve Maudite",
		tier = 1,
		health = 60,
		damage = 6,
		walkSpeed = 11,
		attackRange = 6,
		attackCooldown = 1.6,
		xp = 18,
		yens = 12,
		fragmentChance = 0.02,
		size = Vector3.new(2.4, 2.6, 2.4),
		color = Color3.fromRGB(70, 60, 90),
		glow = Color3.fromRGB(150, 110, 255),
	},
	{
		id = "rampant",
		name = "Rampant Difforme",
		tier = 2,
		health = 140,
		damage = 12,
		walkSpeed = 14,
		attackRange = 6.5,
		attackCooldown = 1.4,
		xp = 45,
		yens = 28,
		fragmentChance = 0.05,
		size = Vector3.new(3, 3.4, 3),
		color = Color3.fromRGB(58, 74, 66),
		glow = Color3.fromRGB(120, 255, 170),
	},
	{
		id = "hurleur",
		name = "Hurleur d'Ossements",
		tier = 3,
		health = 320,
		damage = 22,
		walkSpeed = 16,
		attackRange = 7,
		attackCooldown = 1.3,
		xp = 105,
		yens = 60,
		fragmentChance = 0.09,
		size = Vector3.new(3.6, 4.4, 3.6),
		color = Color3.fromRGB(94, 82, 70),
		glow = Color3.fromRGB(255, 205, 90),
	},
	{
		id = "spectre",
		name = "Spectre Vorace",
		tier = 4,
		health = 700,
		damage = 36,
		walkSpeed = 18,
		attackRange = 7.5,
		attackCooldown = 1.2,
		xp = 240,
		yens = 130,
		fragmentChance = 0.14,
		size = Vector3.new(4, 5.2, 4),
		color = Color3.fromRGB(40, 44, 78),
		glow = Color3.fromRGB(96, 200, 255),
	},
	{
		id = "calamite",
		name = "Calamité Sans Nom",
		tier = 5,
		health = 1500,
		damage = 55,
		walkSpeed = 19,
		attackRange = 8,
		attackCooldown = 1.1,
		xp = 620,
		yens = 320,
		fragmentChance = 0.25,
		size = Vector3.new(5, 6.4, 5),
		color = Color3.fromRGB(70, 24, 34),
		glow = Color3.fromRGB(235, 80, 90),
	},
	-- Boss de fin de faille : plus lents, beaucoup plus résistants.
	{
		id = "roi_maudit",
		name = "Roi des Ombres Maudites",
		tier = 6,
		health = 4200,
		damage = 78,
		walkSpeed = 17,
		attackRange = 10,
		attackCooldown = 1.5,
		xp = 2200,
		yens = 1100,
		fragmentChance = 1,
		size = Vector3.new(7, 9, 7),
		color = Color3.fromRGB(24, 18, 40),
		glow = Color3.fromRGB(190, 110, 255),
	},
}

MobCatalog.List = LIST

local byId: { [string]: Mob } = {}
for _, mob in ipairs(LIST) do
	byId[mob.id] = mob
end

function MobCatalog.get(id: string): Mob?
	return byId[id]
end

return MobCatalog
