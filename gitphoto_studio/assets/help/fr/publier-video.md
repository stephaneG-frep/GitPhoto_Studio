# Préparer et publier une vidéo

Les vidéos de téléphone sont souvent lourdes. L'application peut en créer une **version plus légère** au format MP4 avant publication.

## Convertir une vidéo

1. Ouvrez l'[Éditeur](app:/editor) et choisissez la vidéo.
2. Dans **Préparation de la vidéo**, choisissez un préréglage :
   - **Légère (480p)** : la plus petite, idéale pour un aperçu ;
   - **720p** : bon compromis ;
   - **1080p** : meilleure qualité.
3. Cochez **Retirer le son** si la bande sonore est inutile : le fichier sera encore plus léger.
4. La **taille estimée** s'affiche ; touchez **Convertir en MP4**.

La vidéo d'origine est conservée. La nouvelle version n'est gardée **que si elle est plus petite** : sinon, l'application vous l'indique (la vidéo est sans doute déjà bien compressée).

## Moteur de conversion

- **Android** : Media3, intégré au système, rien à installer.
- **Linux** : ffmpeg. S'il manque : `sudo apt install ffmpeg`, puis **Paramètres › Diagnostic › Actualiser**.

## Publier

Publiez la version convertie comme une photo, avec l'assistant de [Publication](help:publier-photo). Au-delà de 50 Mio, le fichier passe automatiquement par [Git LFS](help:git-lfs) (2 Gio au maximum).

> Sous Linux, la lecture de la vidéo dans l'application nécessite un lecteur système ; à défaut, elle s'ouvre dans votre lecteur habituel.
