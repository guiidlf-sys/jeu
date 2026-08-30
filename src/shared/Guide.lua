--!strict
--[[
	Guide
	Fil conducteur du joueur : à partir du profil, indique la prochaine étape.
	Partagé, pour que le PNJ guide et le HUD affichent exactement la même chose.
]]

export type Step = {
	id: string,
	title: string,
	detail: string,
	done: (profile: any) -> boolean,
}

local Guide = {}

local function spentPoints(profile: any): number
	local total = 0
	for _, value in pairs(profile.stats) do
		total += value
	end
	return total
end

local STEPS: { Step } = {
	{
		id = "premiers_esprits",
		title = "Élimine 5 esprits maudits",
		detail = "Traverse le pont au nord du hall : le terrain d'entraînement t'attend. Clic gauche pour frapper.",
		done = function(profile)
			return profile.totals.kills >= 5
		end,
	},
	{
		id = "premier_point",
		title = "Dépense un point de statistique",
		detail = "Chaque niveau te donne 3 points. Ouvre les statistiques (touche C) et investis-les en Magie, Force, Vie ou Agilité.",
		done = function(profile)
			return spentPoints(profile) >= 1
		end,
	},
	{
		id = "niveau_3",
		title = "Atteins le niveau 3",
		detail = "Au niveau 3 tu débloques la Lame de Vide (touche E), ta première vraie technique.",
		done = function(profile)
			return profile.level >= 3
		end,
	},
	{
		id = "premiere_faille",
		title = "Nettoie une faille de rang E",
		detail = "Menu (M) → JOUER → DONJONS, ou approche-toi d'un portail dans le hall. Trois vagues à survivre.",
		done = function(profile)
			return profile.totals.riftsCleared >= 1
		end,
	},
	{
		id = "premier_achat",
		title = "Équipe ta première arme",
		detail = "Le marchand du hall vend le Katana d'École pour 500 yens. Touche B pour ouvrir la boutique.",
		done = function(profile)
			return next(profile.owned) ~= nil
		end,
	},
	{
		id = "quete_du_jour",
		title = "Termine une quête quotidienne",
		detail = "Touche Q. Les quêtes rapportent des points de statistique en plus de l'XP.",
		done = function(profile)
			return next(profile.quests.claimed) ~= nil
		end,
	},
	{
		id = "niveau_8",
		title = "Atteins le niveau 8",
		detail = "L'Éclat d'Âme (touche R) se débloque au niveau 8, et la faille de rang D s'ouvre à toi.",
		done = function(profile)
			return profile.level >= 8
		end,
	},
	{
		id = "faille_d",
		title = "Nettoie une faille de rang D ou mieux",
		detail = "Les récompenses grimpent vite : yens, fragments et XP. Pense à répartir tes points avant d'entrer.",
		done = function(profile)
			local order = { E = 1, D = 2, C = 3, B = 4, S = 5 }
			return (order[profile.bestRiftRank] or 0) >= 2
		end,
	},
}

Guide.Steps = STEPS

--- Prochaine étape non terminée, ou nil si le joueur a tout fait.
function Guide.next(profile: any): Step?
	if not profile then
		return nil
	end
	for _, step in ipairs(STEPS) do
		local ok, done = pcall(step.done, profile)
		if ok and not done then
			return step
		end
	end
	return nil
end

--- Position dans la progression, pour l'affichage « étape 3 / 8 ».
function Guide.progress(profile: any): (number, number)
	local completed = 0
	for _, step in ipairs(STEPS) do
		local ok, done = pcall(step.done, profile)
		if ok and done then
			completed += 1
		end
	end
	return completed, #STEPS
end

return Guide
