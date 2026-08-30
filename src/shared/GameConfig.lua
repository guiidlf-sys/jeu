--!strict
--[[
	GameConfig
	Constantes centrales du jeu. Tout ce qui est "équilibrage" vit ici pour
	pouvoir être ajusté sans toucher à la logique.
]]

local GameConfig = {}

GameConfig.GameName = "MALÉDICTION : ÉVEIL"
GameConfig.Version = "0.1.0"

-- Progression -----------------------------------------------------------
GameConfig.MaxLevel = 120
GameConfig.StatPointsPerLevel = 3

-- XP nécessaire pour passer du niveau `level` au suivant.
function GameConfig.xpForNextLevel(level: number): number
	return math.floor(80 * (level ^ 1.45)) + 40 * level
end

-- Rangs de sorcier, du plus faible au plus fort (style "grades").
GameConfig.Ranks = {
	{ name = "Grade 4", minLevel = 1, color = Color3.fromRGB(150, 150, 160) },
	{ name = "Grade 3", minLevel = 10, color = Color3.fromRGB(105, 190, 255) },
	{ name = "Grade 2", minLevel = 25, color = Color3.fromRGB(120, 255, 170) },
	{ name = "Grade 1", minLevel = 45, color = Color3.fromRGB(255, 205, 90) },
	{ name = "Semi-Spécial", minLevel = 70, color = Color3.fromRGB(255, 130, 90) },
	{ name = "Grade Spécial", minLevel = 95, color = Color3.fromRGB(190, 110, 255) },
}

function GameConfig.rankForLevel(level: number)
	local current = GameConfig.Ranks[1]
	for _, rank in ipairs(GameConfig.Ranks) do
		if level >= rank.minLevel then
			current = rank
		end
	end
	return current
end

-- Statistiques ----------------------------------------------------------
-- Les 4 stats investissables.
-- La Force porte les coups physiques, la Magie porte les techniques.
GameConfig.Stats = {
	{ id = "magie", name = "Magie", description = "+3 dégâts de technique, +6 énergie" },
	{ id = "force", name = "Force", description = "+2 dégâts d'attaque physique" },
	{ id = "vie", name = "Vie", description = "+8 points de vie" },
	{ id = "agilite", name = "Agilité", description = "+0.4 vitesse, -0.5 % de recharge" },
}

GameConfig.BaseHealth = 100
GameConfig.BaseEnergy = 100
GameConfig.BaseDamage = 10
GameConfig.BaseMagicDamage = 12
GameConfig.BaseWalkSpeed = 16

GameConfig.HealthPerVie = 8
GameConfig.EnergyPerMagie = 6
GameConfig.MagicDamagePerMagie = 3
GameConfig.DamagePerStrength = 2
GameConfig.SpeedPerAgility = 0.4
GameConfig.CooldownReductionPerAgility = 0.005 -- 0.5 %, plafonné plus bas
GameConfig.MaxCooldownReduction = 0.45

GameConfig.EnergyRegenPerSecond = 4
GameConfig.HealthRegenPerSecond = 1.5
GameConfig.OutOfCombatDelay = 5 -- secondes avant la régénération

-- Monnaies --------------------------------------------------------------
GameConfig.Currencies = {
	yens = { name = "Yens", color = Color3.fromRGB(255, 205, 90) },
	fragments = { name = "Fragments", color = Color3.fromRGB(190, 110, 255) },
}

-- Zone sûre & hub AFK ---------------------------------------------------
GameConfig.SafeZoneRadius = 105 -- rayon du hall, aucun esprit n'y entre
GameConfig.AfkRewardInterval = 15
GameConfig.AfkCenter = Vector3.new(0, 3000, 0)

-- Combat ----------------------------------------------------------------
GameConfig.RespawnTime = 5
GameConfig.PvpEnabled = false
GameConfig.MaxHitsPerSwing = 8

-- Palette UI ------------------------------------------------------------
-- Fond très sombre, deux accents (violet maudit, cyan spirituel) et trois
-- couleurs d'état. Tout le reste de l'interface s'y réfère.
GameConfig.Palette = {
	void = Color3.fromRGB(4, 4, 8), -- le noir absolu, derrière tout
	background = Color3.fromRGB(9, 8, 14),
	panel = Color3.fromRGB(16, 15, 24),
	panelLight = Color3.fromRGB(26, 25, 38),
	panelRaised = Color3.fromRGB(34, 32, 50),
	stroke = Color3.fromRGB(78, 66, 128),
	accent = Color3.fromRGB(168, 120, 255), -- violet : énergie maudite
	accentDeep = Color3.fromRGB(96, 52, 190),
	accentSoft = Color3.fromRGB(88, 214, 255), -- cyan : énergie spirituelle
	gold = Color3.fromRGB(255, 205, 110),
	text = Color3.fromRGB(242, 241, 250),
	textDim = Color3.fromRGB(152, 148, 178),
	textFaint = Color3.fromRGB(96, 92, 122),
	danger = Color3.fromRGB(255, 74, 96),
	success = Color3.fromRGB(96, 235, 162),
}

return GameConfig
