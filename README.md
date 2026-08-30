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

---

## Lancer le jeu

Le projet utilise [Rojo](https://rojo.space) pour synchroniser les fichiers
avec Roblox Studio.

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
| `B` | Boutique |
| `M` | Menu principal |

---

## Contenu

- **Progression** : 120 niveaux, 6 grades (Grade 4 → Grade Spécial), 3 points
  de statistique par niveau à répartir entre Force, Agilité, Vitalité et
  Énergie.
- **5 techniques maudites** débloquées par niveau, avec coût en énergie,
  recharge et zone d'effet calculée côté serveur.
- **6 esprits maudits**, de la Larve au Roi des Ombres Maudites.
- **5 failles** (rangs E, D, C, B, S) : donjons à vagues instanciés par
  joueur dans une arène créée à la volée, avec récompenses à la clé.
- **Zone d'entraînement** dans le hall, où des esprits de bas rang
  réapparaissent en continu.
- **Boutique** : armes (bonus permanents), auras (cosmétiques) et reliques.
- **Quêtes quotidiennes** qui récompensent en points de statistique.
- **Sauvegarde DataStore** avec réessais, autosave et sauvegarde à la
  déconnexion.

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
│   └── Util.lua             utilitaires partagés
│
├── server/                  → ServerScriptService.Server
│   ├── init.server.lua      initialise les services dans l'ordre
│   └── Services/
│       ├── DataService.lua        profils & DataStore
│       ├── StatsService.lua       caractéristiques dérivées, énergie, régén
│       ├── ProgressionService.lua XP, niveaux, monnaies
│       ├── QuestService.lua       quêtes quotidiennes
│       ├── MobService.lua         rigs, IA et mort des esprits
│       ├── RewardService.lua      butin à la mort d'un esprit
│       ├── CombatService.lua      résolution des techniques
│       ├── ShopService.lua        achats et équipement
│       ├── RiftService.lua        failles instanciées
│       ├── TrainingService.lua    zone d'entraînement du hall
│       └── WorldBuilder.lua       génération du hall et des arènes
│
└── client/                  → StarterPlayer.StarterPlayerScripts.Client
    ├── init.client.lua      assemblage de l'UI et raccourcis
    ├── State.lua            copie locale du profil
    ├── CombatController.lua entrées → techniques
    └── UI/
        ├── Theme.lua        helpers d'interface
        ├── MainMenu.lua     menu de la maquette
        ├── HUD.lua          jauges, techniques, suivi de faille
        ├── Shop.lua         boutique
        ├── Credits.lua      fenêtre CRÉDIT
        ├── StatsPanel.lua   répartition des points
        ├── QuestPanel.lua   quêtes
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
- **Ajouter un article** : `ShopCatalog.lua`, avec son bonus et son prix.

---

## Idées pour la suite

- Invocation d'ombres (les esprits vaincus combattent à tes côtés).
- Failles coopératives à plusieurs joueurs.
- Classement des meilleurs sorciers (OrderedDataStore).
- Animations et effets sonores sur les techniques.
