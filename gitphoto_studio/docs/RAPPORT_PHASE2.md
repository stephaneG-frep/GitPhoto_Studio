# Rapport — Phase 2 (galerie)

Date : 2026-10-30

## Fonctionnalités livrées

- Import par le sélecteur système (`file_selector` : dialogue GTK sous Linux,
  sélecteur de documents sous Android, sans permission de stockage).
- Glisser-déposer de fichiers et de dossiers sous Linux (`desktop_drop`),
  parcours récursif sans suivre les liens symboliques, fichiers cachés ignorés.
- Bibliothèque du studio : chaque média est copié (copie de travail nommée
  par son empreinte SHA-256) ; l'original n'est jamais modifié ni supprimé.
  Sous Android, seule la copie temporaire créée par le sélecteur dans le cache
  de l'application est effacée après import.
- Doublons : détection par empreinte SHA-256 (calculée en flux, dans un
  isolat), le fichier n'est pas réimporté.
- Type détecté par signature binaire puis extension ; formats non
  multimédias refusés.
- Miniatures et dimensions par le décodeur natif du moteur Flutter
  (orientation EXIF appliquée — vérifié par test).
- Métadonnées EXIF : date de prise de vue, appareil, présence de coordonnées
  GPS (avertissement affiché : elles seraient publiques si l'image est
  publiée telle quelle).
- Vidéos sous Android : durée, dimensions et miniature via
  `MediaMetadataRetriever` (canal natif, `MainActivity.kt`) ; lecture
  intégrée `video_player`.
- Galerie : grille ou liste (mémorisé), recherche, filtres photos/vidéos,
  tris date/nom/type/taille croissant ou décroissant (mémorisés), sélection
  multiple, retrait de la bibliothèque avec confirmation.
- Visionneuse plein écran avec zoom, fiche d'informations, ouverture par
  l'application du système sous Linux (`xdg-open`, sans shell).
- Rapport d'import détaillé, progression, arrêt entre deux fichiers.
- Base : migration v2 (empreinte unique, copie de travail, miniature, type,
  appareil, GPS). Tableau de bord : espace local = base + bibliothèque.

## Tests

| Commande | Résultat |
|---|---|
| `flutter analyze` | aucun problème |
| `flutter test` | 118 réussis, 0 échec |
| `integration_test/app_test.dart` | Linux ✔, Android (MTN NX1M) ✔ |
| `integration_test/gallery_test.dart` (import réel, réouverture) | Linux ✔, Android ✔ |
| `integration_test/android_video_test.dart` (vraie vidéo MP4) | Android ✔ (1080×1080, 8,1 s, miniature, lecture démarrée) ; ignoré sous Linux |
| `flutter build linux --release` | réussi, aucune bibliothèque manquante |
| `flutter build apk --release --target-platform android-arm64` | réussi (21,9 Mio), installé et lancé sur le téléphone |

Le test vidéo Android nécessite de déposer un fichier non versionné (voir
l'en-tête du test) et `--no-uninstall`. Échantillon utilisé :
`Android/Sdk/emulator/resources/default.mp4`, supprimé du téléphone ensuite.

Défauts trouvés et corrigés grâce aux tests :
- double application de l'orientation EXIF (dimensions inversées pour les
  photos en portrait) ;
- message d'import restant affiché par-dessus la visionneuse et masquant les
  commandes vidéo.

## Non vérifié automatiquement

- Dialogue du sélecteur de fichiers (interface système) et glisser-déposer
  réel depuis le gestionnaire de fichiers : à essayer manuellement.
- Photos HEIC réelles d'un téléphone (décodage Android supposé par la
  documentation du moteur, non testé faute d'échantillon).
