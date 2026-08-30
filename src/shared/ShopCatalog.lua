--!strict
--[[
	ShopCatalog
	Boutique : armes, packs, auras et reliques.

	Chaque article a deux prix : un prix en monnaie du jeu (yens ou fragments)
	et un prix en Robux. La boutique permet de basculer de l'un à l'autre.

	IMPORTANT — les achats en Robux passent par des « produits développeur »
	qu'il faut créer soi-même sur le tableau de bord Roblox
	(Créations → ton jeu → Associated Items → Developer Products), puis coller
	l'identifiant obtenu dans le champ `productId` ci-dessous. Tant qu'il vaut
	0, la boutique affiche l'article comme non configuré et refuse l'achat en
	Robux — le prix en monnaie du jeu, lui, fonctionne tout de suite.

	Équilibrage : les prix supposent qu'on joue pour les payer. Un esprit de
	bas rang rapporte ~12 yens, une faille de rang E ~120, une de rang C ~850,
	un contrat de chasse 250 à 16 000. Les paliers de niveau empêchent
	d'acheter tout le catalogue trop tôt.
]]

export type Item = {
	id: string,
	name: string,
	description: string,
	category: "arme" | "pack" | "aura" | "relique",
	currency: "yens" | "fragments",
	price: number,
	robuxPrice: number,
	productId: number, -- 0 = produit développeur non configuré
	requiredLevel: number,
	bonus: { damage: number?, health: number?, energy: number?, speed: number? }?,
	contents: { string }?, -- packs : articles offerts
	color: Color3,
}

local ShopCatalog = {}

ShopCatalog.CategoryLabels = {
	arme = "ARME",
	pack = "PACK",
	aura = "AURA",
	relique = "RELIQUE",
}

local LIST: { Item } = {
	------------------------------------------------------------------
	-- Armes : la progression principale
	------------------------------------------------------------------
	{
		id = "arme_katana_ecole",
		name = "Katana d'École",
		description = "La lame réglementaire des apprentis. +8 dégâts physiques.",
		category = "arme",
		currency = "yens",
		price = 500,
		robuxPrice = 25,
		productId = 0,
		requiredLevel = 1,
		bonus = { damage = 8 },
		color = Color3.fromRGB(150, 150, 170),
	},
	{
		id = "arme_lame_scellee",
		name = "Lame Scellée",
		description = "Une relique difficile à dompter. +22 dégâts, +30 énergie.",
		category = "arme",
		currency = "yens",
		price = 4200,
		robuxPrice = 60,
		productId = 0,
		requiredLevel = 15,
		bonus = { damage = 22, energy = 30 },
		color = Color3.fromRGB(96, 200, 255),
	},
	{
		id = "arme_sabre_cendres",
		name = "Sabre de Cendres",
		description = "Forgé dans les braises d'un sanctuaire souillé. +34 dégâts.",
		category = "arme",
		currency = "yens",
		price = 12000,
		robuxPrice = 99,
		productId = 0,
		requiredLevel = 22,
		bonus = { damage = 34 },
		color = Color3.fromRGB(255, 130, 90),
	},
	{
		id = "arme_eventail_brumes",
		name = "Éventail des Brumes",
		description = "Chaque mouvement rappelle de l'énergie. +42 dégâts, +45 énergie.",
		category = "arme",
		currency = "yens",
		price = 26000,
		robuxPrice = 149,
		productId = 0,
		requiredLevel = 30,
		bonus = { damage = 42, energy = 45 },
		color = Color3.fromRGB(120, 255, 170),
	},
	{
		id = "arme_lance_du_vide",
		name = "Lance du Vide",
		description = "Sa pointe n'existe pas tout à fait. +48 dégâts, +1 vitesse.",
		category = "arme",
		currency = "fragments",
		price = 45,
		robuxPrice = 199,
		productId = 0,
		requiredLevel = 35,
		bonus = { damage = 48, speed = 1 },
		color = Color3.fromRGB(96, 200, 255),
	},
	{
		id = "arme_faux_dombre",
		name = "Faux d'Ombre",
		description = "Forgée dans une faille de rang S. +55 dégâts, +2 vitesse.",
		category = "arme",
		currency = "fragments",
		price = 120,
		robuxPrice = 299,
		productId = 0,
		requiredLevel = 40,
		bonus = { damage = 55, speed = 2 },
		color = Color3.fromRGB(190, 110, 255),
	},
	{
		id = "arme_griffes_jumelles",
		name = "Griffes Jumelles",
		description = "Deux lames, aucune hésitation. +62 dégâts, +2 vitesse.",
		category = "arme",
		currency = "yens",
		price = 60000,
		robuxPrice = 349,
		productId = 0,
		requiredLevel = 48,
		bonus = { damage = 62, speed = 2 },
		color = Color3.fromRGB(255, 205, 90),
	},
	{
		id = "arme_neuf_sceaux",
		name = "Katana des Neuf Sceaux",
		description = "Neuf sceaux, neuf malédictions contenues. +85 dégâts, +60 énergie.",
		category = "arme",
		currency = "fragments",
		price = 200,
		robuxPrice = 449,
		productId = 0,
		requiredLevel = 60,
		bonus = { damage = 85, energy = 60 },
		color = Color3.fromRGB(235, 80, 90),
	},

	------------------------------------------------------------------
	-- Packs : un lot d'articles, ~20 % moins cher que séparément
	------------------------------------------------------------------
	{
		id = "pack_novice",
		name = "Pack Novice",
		description = "Katana d'École + Aura Violette. De quoi bien commencer.",
		category = "pack",
		currency = "yens",
		price = 1600,
		robuxPrice = 79,
		productId = 0,
		requiredLevel = 1,
		contents = { "arme_katana_ecole", "aura_violette" },
		color = Color3.fromRGB(150, 110, 255),
	},
	{
		id = "pack_chasseur",
		name = "Pack Chasseur",
		description = "Lame Scellée + Sabre de Cendres + Aura d'Azur.",
		category = "pack",
		currency = "yens",
		price = 15500,
		robuxPrice = 199,
		productId = 0,
		requiredLevel = 22,
		contents = { "arme_lame_scellee", "arme_sabre_cendres", "aura_azur" },
		color = Color3.fromRGB(96, 200, 255),
	},
	{
		id = "pack_sorcier",
		name = "Pack Sorcier Confirmé",
		description = "Éventail des Brumes + Griffes Jumelles + Talisman de Vie.",
		category = "pack",
		currency = "yens",
		price = 68000,
		robuxPrice = 349,
		productId = 0,
		requiredLevel = 48,
		contents = { "arme_eventail_brumes", "arme_griffes_jumelles", "talisman_vie" },
		color = Color3.fromRGB(255, 205, 90),
	},
	{
		id = "pack_grade_special",
		name = "Pack Grade Spécial",
		description = "Katana des Neuf Sceaux + Faux d'Ombre + Lance du Vide + Aura Sanguine.",
		category = "pack",
		currency = "fragments",
		price = 330,
		robuxPrice = 799,
		productId = 0,
		requiredLevel = 60,
		contents = { "arme_neuf_sceaux", "arme_faux_dombre", "arme_lance_du_vide", "aura_sanguine" },
		color = Color3.fromRGB(190, 110, 255),
	},

	------------------------------------------------------------------
	-- Auras : purement cosmétiques
	------------------------------------------------------------------
	{
		id = "aura_violette",
		name = "Aura Violette",
		description = "Une aura maudite qui suit chacun de tes pas.",
		category = "aura",
		currency = "yens",
		price = 1500,
		robuxPrice = 39,
		productId = 0,
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
		robuxPrice = 59,
		productId = 0,
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
		robuxPrice = 129,
		productId = 0,
		requiredLevel = 30,
		color = Color3.fromRGB(235, 80, 90),
	},

	------------------------------------------------------------------
	-- Reliques : bonus permanents, sans équipement
	------------------------------------------------------------------
	{
		id = "talisman_vie",
		name = "Talisman de Vie",
		description = "+120 points de vie, définitivement.",
		category = "relique",
		currency = "fragments",
		price = 25,
		robuxPrice = 89,
		productId = 0,
		requiredLevel = 5,
		bonus = { health = 120 },
		color = Color3.fromRGB(110, 230, 150),
	},
	{
		id = "talisman_flux",
		name = "Talisman de Flux",
		description = "+80 énergie maudite, définitivement.",
		category = "relique",
		currency = "fragments",
		price = 40,
		robuxPrice = 119,
		productId = 0,
		requiredLevel = 18,
		bonus = { energy = 80 },
		color = Color3.fromRGB(96, 200, 255),
	},
	{
		id = "talisman_fureur",
		name = "Talisman de Fureur",
		description = "+18 dégâts sur toutes tes attaques, définitivement.",
		category = "relique",
		currency = "fragments",
		price = 90,
		robuxPrice = 199,
		productId = 0,
		requiredLevel = 34,
		bonus = { damage = 18 },
		color = Color3.fromRGB(235, 80, 90),
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

--- Retrouve l'article associé à un produit développeur (achat en Robux).
function ShopCatalog.getByProductId(productId: number): Item?
	if productId == 0 then
		return nil
	end
	for _, item in ipairs(LIST) do
		if item.productId == productId then
			return item
		end
	end
	return nil
end

return ShopCatalog
