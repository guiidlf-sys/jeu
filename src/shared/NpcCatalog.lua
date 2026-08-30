--!strict
--[[
	NpcCatalog
	Les PNJ de la zone sûre. Le serveur construit les silhouettes et déclenche
	les dialogues, le client affiche les répliques listées ici.

	`action` indique ce que propose le bouton du dialogue :
	  guide    → rappelle l'objectif en cours
	  stats    → ouvre la fenêtre de statistiques
	  shop     → ouvre la boutique
	  dungeons → ouvre la liste des donjons
	  quests   → ouvre les quêtes et contrats de chasse
]]

export type Npc = {
	id: string,
	name: string,
	role: string,
	color: Color3,
	glow: Color3,
	position: Vector3,
	action: string,
	actionLabel: string,
	lines: { string },
}

local NpcCatalog = {}

local LIST: { Npc } = {
	{
		id = "renzo",
		name = "Maître Renzo",
		role = "Guide des jeunes sorciers",
		color = Color3.fromRGB(48, 42, 78),
		glow = Color3.fromRGB(150, 110, 255),
		position = Vector3.new(-24, 2, 20),
		action = "guide",
		actionLabel = "Quelle est ma prochaine étape ?",
		lines = {
			"Te voilà enfin. Cette énergie autour de toi... tu ne la contrôles pas encore, mais elle est réelle.",
			"Ici, dans le hall, aucun esprit ne peut t'atteindre. C'est une zone sûre : reprends ton souffle, parle aux autres, prépare-toi.",
			"Dehors, c'est différent. Le pont au nord mène au terrain d'entraînement, et les portails autour de nous mènent aux failles.",
			"Un conseil qui t'évitera bien des ennuis : les esprits ne t'attaquent pas d'eux-mêmes. Ils ne réagissent que si tu les frappes — ou si tu as signé un contrat sur leur espèce.",
			"Je te dirai toujours quoi faire ensuite. Reviens me voir dès que tu es perdu.",
		},
	},
	{
		id = "hana",
		name = "Instructrice Hana",
		role = "Maîtrise des statistiques",
		color = Color3.fromRGB(30, 56, 48),
		glow = Color3.fromRGB(120, 255, 170),
		position = Vector3.new(24, 2, 20),
		action = "stats",
		actionLabel = "Répartir mes points",
		lines = {
			"Chaque niveau te donne trois points. Ce que tu en fais décide du sorcier que tu deviendras.",
			"La MAGIE nourrit tes techniques : plus de dégâts sur la Lame de Vide, l'Éclat d'Âme, le Domaine. Et une réserve d'énergie plus grande.",
			"La FORCE ne touche que tes coups à mains nues, mais elle ne coûte aucune énergie. Un bon filet de sécurité.",
			"La VIE te garde debout, l'AGILITÉ te fait courir plus vite et réduit tes temps de recharge.",
			"Mon conseil : Magie et Vie en priorité, un peu d'Agilité ensuite. Mais c'est ton chemin, pas le mien.",
		},
	},
	{
		id = "osamu",
		name = "Osamu",
		role = "Marchand d'armes",
		color = Color3.fromRGB(62, 48, 30),
		glow = Color3.fromRGB(255, 205, 90),
		position = Vector3.new(-36, 2, -12),
		action = "shop",
		actionLabel = "Voir la marchandise",
		lines = {
			"Des yens ? Alors on peut discuter.",
			"Les esprits que tu abats en laissent tomber. Les failles en rapportent bien plus, et parfois des fragments — ceux-là, j'en veux toujours.",
			"Une arme, ça n'est pas de la décoration : elle ajoute des dégâts en permanence. Commence par le Katana d'École, il fera l'affaire.",
		},
	},
	{
		id = "yuna",
		name = "Archiviste Yuna",
		role = "Registre des failles",
		color = Color3.fromRGB(28, 44, 70),
		glow = Color3.fromRGB(96, 200, 255),
		position = Vector3.new(36, 2, -12),
		action = "dungeons",
		actionLabel = "Consulter le registre",
		lines = {
			"Cinq failles recensées, du rang E au rang S. Chacune se referme sur celui qui n'est pas prêt.",
			"Trois vagues par faille. La dernière est toujours la pire — au rang S, le Roi des Ombres Maudites t'y attend.",
			"Tu peux y entrer d'ici, ou franchir un portail dans le hall. Vérifie ton niveau avant, je ne ramasse pas les morceaux.",
		},
	},
	{
		id = "kade",
		name = "Chasseur Kade",
		role = "Contrats de chasse",
		color = Color3.fromRGB(58, 30, 34),
		glow = Color3.fromRGB(235, 80, 90),
		position = Vector3.new(0, 2, -44),
		action = "quests",
		actionLabel = "Voir les contrats",
		lines = {
			"Tu as remarqué ? Les esprits ne bougent pas quand tu passes. Ils dorment, ils rôdent, mais ils ne voient pas en toi une proie.",
			"Ça change à deux conditions. Si tu lèves la main sur l'un d'eux, il ne l'oubliera jamais. Et si tu signes un contrat sur une espèce, toute l'espèce le sent.",
			"C'est le prix de la prime : tu deviens la cible autant qu'eux. Trois contrats en cours au maximum, et tu peux les rompre à tout moment.",
			"En faille, n'espère rien de tout ça : là-bas, tout ce qui bouge te veut mort.",
		},
	},
}

NpcCatalog.List = LIST

local byId: { [string]: Npc } = {}
for _, npc in ipairs(LIST) do
	byId[npc.id] = npc
end

function NpcCatalog.get(id: string): Npc?
	return byId[id]
end

return NpcCatalog
