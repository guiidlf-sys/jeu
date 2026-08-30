--!strict
--[[
	ShopCatalog
	Boutique du menu principal. Les armes sont des bonus permanents,
	les auras sont cosmétiques.
]]

export type Item = {
	id: string,
	name: string,
	description: string,
	category: "arme" | "aura" | "consommable",
	currency: "yens" | "fragments",
	price: number,
	requiredLevel: number,
	bonus: { damage: number?, health: number?, energy: number?, speed: number? }?,
	color: Color3,
}

local ShopCatalog = {}

local LIST: { Item } = {
	{
		id = "arme_katana_ecole",
		name = "Katana d'École",
		description = "+8 dégâts. La lame réglementaire des apprentis sorciers.",
		category = "arme",
		currency = "yens",
		price = 500,
		requiredLevel = 1,
		bonus = { damage = 8 },
		color = Color3.fromRGB(150, 150, 170),
	},
	{
		id = "arme_lame_scellee",
		name = "Lame Scellée",
		description = "+22 dégâts, +30 énergie. Une relique difficile à dompter.",
		category = "arme",
		currency = "yens",
		price = 4200,
		requiredLevel = 15,
		bonus = { damage = 22, energy = 30 },
		color = Color3.fromRGB(96, 200, 255),
	},
	{
		id = "arme_faux_dombre",
		name = "Faux d'Ombre",
		description = "+55 dégâts, +2 vitesse. Forgée dans une faille de rang S.",
		category = "arme",
		currency = "fragments",
		price = 120,
		requiredLevel = 40,
		bonus = { damage = 55, speed = 2 },
		color = Color3.fromRGB(190, 110, 255),
	},
	{
		id = "aura_violette",
		name = "Aura Violette",
		description = "Une aura maudite qui suit chacun de tes pas.",
		category = "aura",
		currency = "yens",
		price = 1500,
		requiredLevel = 1,
		color = Color3.fromRGB(150, 110, 255),
	},
	{
		id = "aura_azur",
		name = "Aura d'Azur",
		description = "Le calme avant l'éveil.",
		category = "aura",
		currency = "yens",
		price = 3500,
		requiredLevel = 10,
		color = Color3.fromRGB(96, 200, 255),
	},
	{
		id = "aura_sanguine",
		name = "Aura Sanguine",
		description = "Réservée à ceux qui ont survécu au Trône des Ombres.",
		category = "aura",
		currency = "fragments",
		price = 60,
		requiredLevel = 30,
		color = Color3.fromRGB(235, 80, 90),
	},
	{
		id = "talisman_vie",
		name = "Talisman de Vie",
		description = "+120 points de vie permanents.",
		category = "consommable",
		currency = "fragments",
		price = 25,
		requiredLevel = 5,
		bonus = { health = 120 },
		color = Color3.fromRGB(110, 230, 150),
	},
}

ShopCatalog.List = LIST

local byId: { [string]: Item } = {}
for _, item in ipairs(LIST) do
	byId[item.id] = item
end

function ShopCatalog.get(id: string): Item?
	return byId[id]
end

return ShopCatalog
