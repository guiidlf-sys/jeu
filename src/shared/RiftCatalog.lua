--!strict
--[[
	RiftCatalog
	Les "Failles" : donjons instanciés à vagues, l'équivalent des portails.
	Chaque faille est générée dans une arène créée à la volée pour le joueur.
]]

export type Wave = {
	mobs: { { id: string, count: number } },
}

export type Rift = {
	id: string,
	name: string,
	rank: string,
	minLevel: number,
	color: Color3,
	arenaSize: number,
	waves: { Wave },
	rewards: { yens: number, fragments: number, xp: number },
}

local RiftCatalog = {}

local LIST: { Rift } = {
	{
		id = "faille_e",
		name = "Ruelle Hantée",
		rank = "E",
		minLevel = 1,
		color = Color3.fromRGB(120, 255, 170),
		arenaSize = 120,
		waves = {
			{ mobs = { { id = "larve", count = 4 } } },
			{ mobs = { { id = "larve", count = 6 } } },
			{ mobs = { { id = "larve", count = 5 }, { id = "rampant", count = 2 } } },
		},
		rewards = { yens = 120, fragments = 1, xp = 80 },
	},
	{
		id = "faille_d",
		name = "Sanctuaire Souillé",
		rank = "D",
		minLevel = 8,
		color = Color3.fromRGB(96, 200, 255),
		arenaSize = 140,
		waves = {
			{ mobs = { { id = "rampant", count = 5 } } },
			{ mobs = { { id = "rampant", count = 6 }, { id = "hurleur", count = 1 } } },
			{ mobs = { { id = "hurleur", count = 3 }, { id = "rampant", count = 4 } } },
		},
		rewards = { yens = 340, fragments = 3, xp = 260 },
	},
	{
		id = "faille_c",
		name = "Hôpital Abandonné",
		rank = "C",
		minLevel = 18,
		color = Color3.fromRGB(255, 205, 90),
		arenaSize = 160,
		waves = {
			{ mobs = { { id = "hurleur", count = 5 } } },
			{ mobs = { { id = "hurleur", count = 6 }, { id = "spectre", count = 1 } } },
			{ mobs = { { id = "spectre", count = 3 }, { id = "hurleur", count = 4 } } },
		},
		rewards = { yens = 850, fragments = 8, xp = 900 },
	},
	{
		id = "faille_b",
		name = "Gouffre de Cendres",
		rank = "B",
		minLevel = 32,
		color = Color3.fromRGB(255, 130, 90),
		arenaSize = 180,
		waves = {
			{ mobs = { { id = "spectre", count = 5 } } },
			{ mobs = { { id = "spectre", count = 6 }, { id = "calamite", count = 1 } } },
			{ mobs = { { id = "calamite", count = 3 }, { id = "spectre", count = 4 } } },
		},
		rewards = { yens = 2200, fragments = 20, xp = 3200 },
	},
	{
		id = "faille_s",
		name = "Trône des Ombres",
		rank = "S",
		minLevel = 50,
		color = Color3.fromRGB(190, 110, 255),
		arenaSize = 210,
		waves = {
			{ mobs = { { id = "calamite", count = 4 } } },
			{ mobs = { { id = "calamite", count = 6 }, { id = "spectre", count = 6 } } },
			{ mobs = { { id = "roi_maudit", count = 1 }, { id = "calamite", count = 3 } } },
		},
		rewards = { yens = 7500, fragments = 70, xp = 14000 },
	},
}

RiftCatalog.List = LIST

local byId: { [string]: Rift } = {}
for _, rift in ipairs(LIST) do
	byId[rift.id] = rift
end

function RiftCatalog.get(id: string): Rift?
	return byId[id]
end

return RiftCatalog
