# Automatisation TikTok

Fabrique des clips verticaux 1080x1920 à partir d'un plan de contenu, puis
les envoie sur TikTok via l'API officielle. Piloté par GitHub Actions.

```
content_plan.yaml  →  ffmpeg  →  out/<clip>.mp4  →  Content Posting API
```

---

## Ce que ça fait, et ce que ça ne fait pas

**Ça fait** : fabriquer la vidéo (fond + textes animés + musique + filigrane),
gérer l'OAuth et la rotation du token, envoyer le fichier en blocs, attendre
le statut final, et journaliser ce qui est parti dans `state.json` pour ne
jamais reposter deux fois le même clip.

**Ça ne fait pas** : liker, suivre, commenter ou vues automatiques. Ce sont
des violations des conditions d'utilisation de TikTok, sanctionnées par la
suppression du compte, et l'API officielle ne les expose pas.

**Limite importante** : une app TikTok non auditée ne peut publier qu'en
**privé**. Deux modes en découlent.

| Mode | Portée | Scope OAuth | Audit |
| --- | --- | --- | --- |
| `inbox` (défaut) | la vidéo arrive dans la boîte de réception de l'app, tu finalises à la main | `video.upload` | non |
| `direct` | publication automatique complète | `video.publish` | oui, sinon `SELF_ONLY` imposé |

Le mode `inbox` est le bon point de départ : rien à faire valider, la vidéo
arrive dans ton téléphone avec une notification, tu ajoutes la légende (elle
est écrite dans `out/<clip>.caption.txt`) et tu publies d'un geste.

---

## Mise en place

### 1. Créer l'app TikTok

1. Va sur [developers.tiktok.com](https://developers.tiktok.com), connecte-toi
   avec le compte TikTok du jeu, crée une app.
2. Ajoute le produit **Content Posting API**.
3. Ajoute les scopes : `user.info.basic` et `video.upload` (ou `video.publish`
   pour le mode direct).
4. Déclare une **Redirect URI**. N'importe quelle URL que tu contrôles fait
   l'affaire — la page n'a même pas besoin d'exister, tu recopieras l'URL de
   redirection depuis la barre d'adresse.
5. Note le **Client key** et le **Client secret**.

### 2. Récupérer le refresh token

Sur ton PC, à la racine du dépôt :

```bash
cd tiktok
pip install -r requirements.txt
python auth_setup.py \
  --client-key TA_CLE \
  --client-secret TON_SECRET \
  --redirect-uri https://exemple.com/callback
```

Le script affiche une URL, tu l'ouvres, tu autorises, tu recolles l'URL
d'arrivée. Il affiche alors le refresh token.

### 3. Enregistrer les secrets GitHub

Dépôt → **Settings** → **Secrets and variables** → **Actions** :

| Secret | Contenu |
| --- | --- |
| `TIKTOK_CLIENT_KEY` | client key de l'app |
| `TIKTOK_CLIENT_SECRET` | client secret de l'app |
| `TIKTOK_REFRESH_TOKEN` | sortie de `auth_setup.py` |
| `SECRETS_ADMIN_TOKEN` | *(fortement conseillé)* jeton personnel à portée fine sur ce dépôt, permission **Secrets : lecture et écriture** |

`SECRETS_ADMIN_TOKEN` sert à une seule chose, mais elle est décisive : TikTok
renvoie parfois un **nouveau** refresh token à chaque rafraîchissement.
Sans réécriture du secret, l'ancien finit par ne plus être accepté et le
workflow tombe en panne au bout de quelques exécutions. Le `GITHUB_TOKEN`
fourni par Actions n'a pas le droit d'écrire des secrets, d'où le jeton à part.

### 4. Déposer les visuels

`assets/backgrounds/placeholder.png` est un dégradé neutre pour démarrer.
Remplace-le par de vraies captures du jeu — voir `assets/README.md`.

---

## Utilisation en local

```bash
cd tiktok
python -m tiktokbot check                        # plan, ffmpeg, police, secrets
python -m tiktokbot list                         # clips et déjà-envoyés
python -m tiktokbot render --clip 01-grade-4     # fabrique out/01-grade-4.mp4
python -m tiktokbot publish --dry-run            # prochain clip, sans envoi
python -m tiktokbot publish                      # prochain clip, avec envoi
```

Pour l'envoi en local, crée un fichier `tiktok/.env` (ignoré par git) :

```
TIKTOK_CLIENT_KEY=...
TIKTOK_CLIENT_SECRET=...
TIKTOK_REFRESH_TOKEN=...
TIKTOK_POST_MODE=inbox
```

`ffmpeg` doit être installé : `sudo apt-get install ffmpeg` sur Ubuntu,
`brew install ffmpeg` sur macOS, `winget install ffmpeg` sur Windows.

---

## Le workflow GitHub Actions

`.github/workflows/tiktok.yml` publie **le premier clip du plan qui n'est pas
encore dans `state.json`**, les lundi, mercredi et vendredi à 17:00 UTC.

Deux points à connaître :

- **Le cron ne se déclenche que depuis la branche par défaut.** Tant que ce
  fichier n'est pas fusionné dans `main`, seul le lancement manuel marche.
- **Le lancement manuel** (onglet Actions → *TikTok — publication automatique*
  → *Run workflow*) accepte trois entrées : un identifiant de clip précis, une
  case *dry run* qui fabrique la vidéo sans rien envoyer, et le mode d'envoi.
  La vidéo produite est toujours téléchargeable dans les artefacts du job,
  même en dry run — c'est la façon de valider un clip avant de le publier.

Après un envoi réussi, le job commite `state.json` sur la branche courante.
C'est ce qui rend le cron idempotent.

---

## Écrire un clip

Dans `content_plan.yaml` :

```yaml
- id: 07-domaine
  background: assets/backgrounds/domaine.png   # image ou vidéo
  duration: 12
  motion: zoom-in                              # zoom-in | zoom-out | none
  music: assets/music/theme.mp3                # facultatif
  caption: "Niveau 30. Domaine Restreint."
  hashtags: [roblox, animegame]
  slides:
    - text: "Niveau 30."
      position: center                         # top | center | bottom
      size: 88
    - text: "Le Domaine Restreint se débloque."
      position: center
      size: 66
```

Sans `start`/`end`, les slides se partagent la durée à parts égales. Les
valeurs de `defaults` s'appliquent à tous les clips qui ne les redéfinissent
pas. Le texte est coupé en lignes automatiquement selon la taille de police.

Un `python -m tiktokbot check` valide tout hors ligne : identifiants
dupliqués, fichiers manquants, durées incohérentes, positions inconnues.

---

## Quand ça casse

| Symptôme | Cause |
| --- | --- |
| `Secrets manquants` | les secrets GitHub ne sont pas définis, ou le `.env` local est absent |
| `Rafraîchissement du token refusé` | refresh token expiré (365 jours), révoqué, ou pivoté sans `SECRETS_ADMIN_TOKEN` — relance `auth_setup.py` |
| `scope_not_authorized` | l'app n'a pas le scope du mode choisi : `video.upload` pour `inbox`, `video.publish` pour `direct` |
| `privacy_level` refusé | app non auditée : seul `SELF_ONLY` passe en mode `direct` |
| `ffmpeg est introuvable` | installe ffmpeg (voir plus haut) |
| `fond introuvable` | le chemin de `background` ne correspond à aucun fichier dans `assets/` |
| Tous les clips sont marqués envoyés | ajoute des entrées au plan, ou republie avec `--clip <id>` |

Limites de débit côté TikTok : 6 envois de bloc par minute, 20 lectures
d'infos créateur par minute, 30 lectures de statut par minute. Le rythme
lundi/mercredi/vendredi est très en dessous.
