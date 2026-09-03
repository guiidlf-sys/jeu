# Assets

Ce dossier contient les images, vidéos et musiques utilisées par les clips.
Rien ici n'est généré automatiquement : c'est toi qui déposes les fichiers.

```
assets/
├── backgrounds/   captures du jeu (.png/.jpg) ou rushes (.mp4/.mov)
├── music/         pistes audio (.mp3/.m4a/.wav)
└── font.ttf       police personnalisée (facultatif)
```

## Fonds

`backgrounds/placeholder.png` est un dégradé neutre livré pour que le
pipeline tourne dès le premier `render`. Remplace-le par de vraies captures :

1. Ouvre `MaledictionEveil.rbxlx` dans Roblox Studio, appuie sur **Play**.
2. Cadre une scène (le hall, une faille, le Domaine Restreint).
3. Capture l'écran, recadre en **9:16** si tu peux — sinon le script recadre
   au centre tout seul.
4. Dépose le fichier ici et pointe-le dans `content_plan.yaml`.

Une vidéo marche aussi : elle est recadrée en 9:16, bouclée si elle est plus
courte que le clip, et sa piste audio est ignorée (seule la musique du plan
est utilisée).

## Musique

N'utilise que des pistes libres de droits, ou la bibliothèque de sons
commerciale de TikTok. Une musique sous copyright déposée via l'API fait
couper le son de la vidéo, voire retirer le post — l'API n'a pas accès au
catalogue musical de l'app.

## Police

Sans `font.ttf`, le script prend DejaVu Sans Bold (déjà présent sur les
runners GitHub et la plupart des Linux). Dépose une police plus expressive
ici pour changer le rendu, ou définis `TIKTOK_FONT=/chemin/vers/police.ttf`.
