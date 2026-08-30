# MALÉDICTION : ÉVEIL

Un jeu Roblox à la *Solo Leveling*, transposé dans un univers original de
sorciers et d'esprits maudits (ambiance *Jujutsu Kaisen*, sans reprendre de
noms ni de personnages existants).

Boucle de jeu : tu commences au plus bas grade, tu purges des esprits, tu
montes de niveau, tu répartis tes points de statistique, tu débloques des
techniques maudites, et tu franchis des **failles** de rang E à S de plus en
plus dangereuses.

Le menu principal reprend la maquette : le nom du jeu en haut, puis
**JOUER**, **BOUTIQUE** et **CRÉDIT** empilés au centre d'un grand cadre.
**JOUER** ouvre une seconde page, dans le même cadre, avec trois
destinations : **IN THE GAME** (le hall), **DONJONS** (choisir une faille) et
**HUB AFK** (gains passifs).

---

## Lancer le jeu

### Le plus simple : ouvrir la place déjà construite

Le fichier **`MaledictionEveil.rbxlx`** à la racine du dépôt est le jeu déjà
assemblé. Aucun outil à installer :

1. Télécharge `MaledictionEveil.rbxlx` (sur GitHub : clique sur le fichier,
   puis sur le bouton de téléchargement).
2. Double-clique dessus, ou dans Roblox Studio : **File → Open from File**.
3. Appuie sur **Play**.

Pour le publier : **File → Publish to Roblox As...**

> Ce fichier est régénéré avec `rojo build -o MaledictionEveil.rbxlx` après
> toute modification du code source.

### Pour développer : la synchronisation en direct

Le projet utilise [Rojo](https://rojo.space) pour synchroniser les fichiers
avec Roblox Studio. Les commandes ci-dessous se tapent dans le **terminal de
ton ordinateur** (PowerShell sur Windows, Terminal sur macOS), à la racine du
dépôt — pas dans Roblox Studio.

```bash
# 1. Installer les outils (rokit, ou aftman/foreman si tu préfères)
rokit install

# 2. Lancer le serveur de synchronisation
rojo serve
```

Puis dans Roblox Studio :

1. Crée une **place vide** (Baseplate ou même totalement vide — le hall, les
   arènes et les esprits sont générés par code au démarrage du serveur).
2. Installe le plugin Rojo, clique sur **Connect**.
3. Appuie sur **Play**.

Alternative sans serveur : `rojo build -o jeu.rbxlx`, puis ouvre le fichier
dans Studio.

> Pense à activer les **API Services** (Game Settings → Security →
> Enable Studio Access to API Services) pour que les sauvegardes DataStore
> fonctionnent. Sans ça, le jeu tourne quand même, mais la progression n'est
> pas conservée entre deux sessions.

---

## Commandes

| Touche | Action |
| --- | --- |
| Clic gauche (maintenu) | Poing Maudit — attaque de base |
| `E` | Lame de Vide (niveau 3) |
| `R` | Éclat d'Âme (niveau 8) |
| `F` | Chaînes Funestes (niveau 15) |
| `G` | Domaine Restreint (niveau 30) |
| `C` | Statistiques |
| `Q` | Quêtes quotidiennes |
| `J` | Donjons |
| `B` | Boutique |
| `M` | Menu principal |
| `E` (près d'un PNJ) | Parler |

---

## Contenu

- **Progression** : 120 niveaux, 6 grades (Grade 4 → Grade Spécial), 3 points
  de statistique par niveau à répartir entre :
  - **Magie** — dégâts de toutes les techniques, et réserve d'énergie
  - **Force** — dégâts de l'attaque de base, qui ne coûte rien
  - **Vie** — points de vie
  - **Agilité** — vitesse de déplacement et réduction des recharges
- **Zone sûre** : le hall est protégé, aucun esprit ne peut y entrer. Quatre
  PNJ y tiennent boutique et conseil, dont Maître Renzo qui indique en
  permanence la prochaine étape à accomplir (le HUD l'affiche aussi).
- **Hub AFK** : une île flottante où l'XP et les yens tombent tout seuls.
- **5 techniques maudites** débloquées par niveau, avec coût en énergie,
  recharge et zone d'effet calculée côté serveur.
- **6 esprits maudits**, de la Larve au Roi des Ombres Maudites.
- **5 failles** (rangs E, D, C, B, S) : donjons à vagues instanciés par
  joueur dans une arène créée à la volée, avec récompenses à la clé.
- **Terrain d'entraînement** au nord du hall, hors de la zone sûre, où des
  esprits de bas rang réapparaissent en continu.
- **Boutique** en grille paginée : 18 articles répartis sur 3 pages de 6 —
  8 armes, 4 packs, 3 auras et 3 reliques — avec un sélecteur pour payer en
  monnaie du jeu **ou en Robux**.
- **Esprits passifs par défaut** : hors des failles, un esprit ne t'attaque
  que si tu l'as frappé le premier, ou si tu as accepté un contrat de chasse
  sur son espèce. Chaque esprit affiche son état (« passif » / « hostile »).
- **Contrats de chasse** : six contrats répétables à accepter (trois en cours
  au maximum). Ils rapportent gros, mais l'espèce visée t'attaque à vue tant
  que le contrat est actif — on peut le rompre à tout moment.
- **Quêtes quotidiennes** qui récompensent en points de statistique.
- **Sauvegarde DataStore** avec réessais, autosave et sauvegarde à la
  déconnexion.

---

## Direction artistique

L'interface suit un système de design unique, centralisé dans
`src/client/UI/Theme.lua` : c'est le seul fichier à toucher pour changer
l'allure de tout le jeu.

- **Cadres nets** plutôt que coins arrondis, avec des **équerres lumineuses**
  aux quatre angles — la signature visuelle du jeu.
- **Deux accents** : violet (énergie maudite) et cyan (énergie spirituelle),
  plus l'or des récompenses, le rouge du danger et le vert du système.
- **Halos** simulés par des cadres concentriques translucides, faute
  d'ombres portées dans Roblox.
- **Typographies** : une police d'affichage large pour les titres, une
  police de texte lisible pour le corps, résolues avec repli sûr si le
  client ne connaît pas la police demandée.
- **Animations** : balayage lumineux sur les titres, entrées glissées des
  fenêtres, éclat des techniques quand elles redeviennent prêtes, texte des
  dialogues qui s'écrit lettre à lettre.
- **Ambiance 3D** : brume atmosphérique, bloom et étalonnage des couleurs
  configurés directement dans `default.project.json`.

Helpers principaux : `Theme.panel`, `Theme.button`, `Theme.window`,
`Theme.bar`, `Theme.chip`, `Theme.brackets`, `Theme.glow`, `Theme.shimmer`.
`Theme.content` crée la zone de contenu d'un panneau — indispensable dès
qu'on y met un layout, sinon les décorations occuperaient une place.

---

## Boutique : monnaie du jeu et Robux

Chaque article a deux prix. Le sélecteur en haut de la boutique bascule entre
les deux, la grille reste la même.

**Monnaie du jeu** — fonctionne immédiatement, rien à configurer.

**Robux** — il faut d'abord créer les produits sur le tableau de bord :

1. Publie le jeu (**File → Publish to Roblox As...**).
2. Va sur [create.roblox.com](https://create.roblox.com) → ton jeu →
   **Associated Items** → **Developer Products** → **Create Developer
   Product**. Un produit par article que tu veux vendre, avec son prix en
   Robux.
3. Copie l'identifiant de chaque produit dans le champ `productId` de
   l'article correspondant, dans `src/shared/ShopCatalog.lua`.

Tant qu'un `productId` vaut `0`, l'article affiche « Bientôt en Robux » et
l'achat est refusé — le prix en monnaie du jeu, lui, marche depuis le début.
Côté serveur, `ShopService` implémente `ProcessReceipt` : le reçu est
enregistré dans le profil avant d'être validé, pour qu'un article ne soit
jamais délivré deux fois ni perdu en cas de coupure.

### Équilibrage des prix

Les prix supposent qu'on joue pour les payer, et chaque article a un palier
de niveau qui empêche d'acheter tout le catalogue trop tôt.

| Article | Prix | Niveau |
| --- | --- | --- |
| Katana d'École | 500 yens | 1 |
| Pack Novice | 1 600 yens | 1 |
| Lame Scellée | 4 200 yens | 15 |
| Pack Chasseur | 15 500 yens | 22 |
| Sabre de Cendres | 12 000 yens | 22 |
| Éventail des Brumes | 26 000 yens | 30 |
| Lance du Vide | 45 fragments | 35 |
| Faux d'Ombre | 120 fragments | 40 |
| Griffes Jumelles | 60 000 yens | 48 |
| Pack Sorcier Confirmé | 68 000 yens | 48 |
| Katana des Neuf Sceaux | 200 fragments | 60 |
| Pack Grade Spécial | 330 fragments | 60 |

Pour situer les revenus : un esprit de bas rang rapporte ~12 yens, une faille
de rang E 120, une de rang C 850, une de rang S 7 500 ; les contrats de chasse
vont de 250 à 16 000. Les packs coûtent environ 20 % de moins que leur contenu
acheté séparément.

---

## Architecture

```
src/
├── shared/                  → ReplicatedStorage.Shared
│   ├── GameConfig.lua       équilibrage central (XP, stats, rangs, couleurs)
│   ├── Remotes.lua          création/récupération des RemoteEvent & Function
│   ├── Signal.lua           événement interne léger
│   ├── SkillCatalog.lua     techniques maudites
│   ├── MobCatalog.lua       esprits maudits
│   ├── RiftCatalog.lua      failles et leurs vagues
│   ├── ShopCatalog.lua      articles de la boutique
│   ├── QuestCatalog.lua     quêtes quotidiennes
│   ├── HuntCatalog.lua      contrats de chasse
│   ├── NpcCatalog.lua       PNJ de la zone sûre et leurs dialogues
│   ├── Guide.lua            fil conducteur : la prochaine étape du joueur
│   └── Util.lua             utilitaires partagés
│
├── server/                  → ServerScriptService.Server
│   ├── init.server.lua      initialise les services dans l'ordre
│   └── Services/
│       ├── DataService.lua        profils & DataStore
│       ├── StatsService.lua       caractéristiques dérivées, énergie, régén
│       ├── ProgressionService.lua XP, niveaux, monnaies
│       ├── QuestService.lua       quêtes quotidiennes
│       ├── HuntService.lua        contrats de chasse et hostilité des esprits
│       ├── MobService.lua         rigs, IA et mort des esprits
│       ├── RewardService.lua      butin à la mort d'un esprit
│       ├── CombatService.lua      résolution des techniques
│       ├── ShopService.lua        achats et équipement
│       ├── RiftService.lua        failles instanciées
│       ├── ZoneService.lua        zone sûre, téléportations, hub AFK
│       ├── NpcService.lua         PNJ et dialogues
│       ├── TrainingService.lua    terrain d'entraînement
│       └── WorldBuilder.lua       génération du monde
│
└── client/                  → StarterPlayer.StarterPlayerScripts.Client
    ├── init.client.lua      assemblage de l'UI et raccourcis
    ├── State.lua            copie locale du profil
    ├── CombatController.lua entrées → techniques
    └── UI/
        ├── Theme.lua        helpers d'interface
        ├── MainMenu.lua     menu de la maquette (2 pages)
        ├── DungeonList.lua  registre des failles
        ├── QuestPanel.lua   contrats de chasse et quêtes quotidiennes
        ├── Dialogue.lua     boîte de dialogue des PNJ
        ├── HUD.lua          jauges, techniques, objectif, suivi de faille
        ├── Shop.lua         boutique
        ├── Credits.lua      fenêtre CRÉDIT
        ├── StatsPanel.lua   répartition des points
        ├── Notifications.lua fenêtres « Système »
        └── DamageNumbers.lua chiffres de dégâts flottants
```

### Sécurité

Le client n'envoie que des intentions. Le serveur revérifie systématiquement
le niveau requis, la recharge, le coût en énergie, la portée, le prix des
articles et les objectifs de quête. Aucun dégât, gain d'XP ou achat n'est
décidé côté client.

---

## Personnaliser

- **Nom du jeu** : `GameConfig.GameName` dans `src/shared/GameConfig.lua`.
- **Équilibrage** (XP, dégâts, régénération, rangs) : le même fichier.
- **Ajouter une technique** : une entrée dans `SkillCatalog.lua` suffit — le
  HUD, les recharges et le serveur la prennent en compte automatiquement.
- **Ajouter un esprit ou une faille** : `MobCatalog.lua` / `RiftCatalog.lua`.
  Un portail est créé automatiquement dans le hall pour chaque faille.
- **Ajouter un article** : `ShopCatalog.lua` — prix en monnaie du jeu, prix
  en Robux, niveau requis, bonus, et `contents` pour un pack.
- **Ajouter un PNJ ou changer ses répliques** : `NpcCatalog.lua` (position,
  couleur, dialogue, action du bouton).
- **Ajouter un contrat de chasse** : `HuntCatalog.lua` — `targets` liste les
  espèces qui deviennent hostiles pendant le contrat.
- **Rendre les esprits agressifs d'office** : passer `{ hostile = true }` à
  `MobService.spawn` (c'est ce que fait `RiftService` pour les failles).
- **Changer le fil conducteur** : `Guide.lua` — chaque étape a un titre, un
  détail et une condition d'accomplissement.

---

## Idées pour la suite

- Invocation d'ombres (les esprits vaincus combattent à tes côtés).
- Quêtes données par les PNJ, avec suivi et récompenses dédiées.
- Failles coopératives à plusieurs joueurs.
- Classement des meilleurs sorciers (OrderedDataStore).
- Animations et effets sonores sur les techniques.
