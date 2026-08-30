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
-- Les 4 stats investissables. `apply` décrit l'effet d'un point.
GameConfig.Stats = {
	{ id = "force", name = "Force", description = "+2 dégâts par point" },
	{ id = "agilite", name = "Agilité", description = "+0.4 vitesse, -0.5% cooldown" },
	{ id = "vitalite", name = "Vitalité", description = "+8 points de vie" },
	{ id = "energie", name = "Énergie", description = "+6 énergie maudite" },
}

GameConfig.BaseHealth = 100
GameConfig.BaseEnergy = 100
GameConfig.BaseDamage = 10
GameConfig.BaseWalkSpeed = 16

GameConfig.HealthPerVitality = 8
GameConfig.EnergyPerEnergyStat = 6
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

-- Combat ----------------------------------------------------------------
GameConfig.RespawnTime = 5
GameConfig.PvpEnabled = false
GameConfig.MaxHitsPerSwing = 8

-- Palette UI ------------------------------------------------------------
GameConfig.Palette = {
	background = Color3.fromRGB(10, 10, 16),
	panel = Color3.fromRGB(18, 18, 28),
	panelLight = Color3.fromRGB(28, 28, 42),
	stroke = Color3.fromRGB(120, 90, 220),
	accent = Color3.fromRGB(150, 110, 255),
	accentSoft = Color3.fromRGB(96, 200, 255),
	text = Color3.fromRGB(238, 238, 248),
	textDim = Color3.fromRGB(150, 150, 170),
	danger = Color3.fromRGB(235, 80, 90),
	success = Color3.fromRGB(110, 230, 150),
}

return GameConfig
