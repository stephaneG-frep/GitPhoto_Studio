# Rapport — Phase 4 (multimédia)

Date : 2026-10-31

## Principe

Tout traitement produit une **nouvelle version** dans la bibliothèque, liée
à son original (« Version de … ») et rangée dans le même album. L'original et
sa copie de travail ne sont jamais modifiés.

## Fonctionnalités livrées

- **Éditeur** : choix d'un média, renommage (nom validé ; le fichier de
  travail n'est pas touché), album.
- **Optimisation d'image** : préréglages Web (1920 px), Léger (1280 px),
  Miniature (400 px) ou personnalisé (dimension, JPEG/PNG, qualité). Jamais
  d'agrandissement. Transparence composée sur blanc en JPEG.
  - Métadonnées : tout retirer (par défaut) ou garder date et appareil,
    **jamais la position GPS**. Orientation appliquée aux pixels.
  - **Aperçu** avant enregistrement : comparaison côte à côte, dimensions,
    taille avant/après et pourcentage.
  - **Optimisation par lot** depuis la sélection de la galerie.
- **Préparation vidéo** (MP4 H.264/AAC, 480p/720p/1080p, son retirable,
  estimation de taille, progression, annulation) :
  - Android : **Media3 Transformer 1.9.2** (Apache 2.0), encodeurs matériels ;
  - Linux : **ffmpeg** du système (arguments fixes, sans shell), détecté
    automatiquement — non installé sur cette machine.
  - Débit plafonné à celui de la source ; si le résultat n'est pas plus
    léger que l'original, la version **n'est pas conservée** et
    l'utilisateur est informé.
- **Doublons probables** : empreinte visuelle dHash 64 bits calculée à
  l'import (et a posteriori pour les médias existants), regroupement par
  proximité ; retrait confirmé. Les copies exactes restaient déjà refusées à
  l'import (SHA-256).
- **Albums** : création, renommage, suppression (les médias restent),
  rangement depuis la galerie, filtre par album, **classement automatique
  par année et mois** avec confirmation.
- Linux avec ffmpeg : durée, dimensions et miniatures des vidéos (ffprobe).
- Diagnostic : détection de ffmpeg, bouton de nouvelle détection.
- Base : migration v3 (version dérivée, empreinte visuelle, index albums).

## Tests

| Commande | Résultat |
|---|---|
| `flutter analyze` | aucun problème |
| `flutter test` | 189 réussis, 0 échec |
| Intégration Linux (`app`, `gallery`, `editor_device`) | ✔ (vidéo ignorée : pas de ffmpeg) |
| Intégration Android (MTN NX1M) `editor_device_test.dart` | ✔ 4/4 |
| Builds Linux et APK release (24,9 Mio), installé et lancé | ✔ |

Mesures réelles sur le téléphone :
- image 4000×3000 (8,8 Mo) → version web 1920×1440 (570 Ko) ;
- vidéo 1080×1080 déjà compressée (500 Ko) → 480p à 739 Ko : **refusée**
  par la garantie de taille, rien n'est ajouté ;
- vidéo 1080×1080 plus lourde (1,23 Mo) → 720×720 (823 Ko, −33 %) ;
- annulation d'une conversion : propre, aucun fichier partiel.

Défauts trouvés et corrigés grâce aux tests :
- fichier produit supprimé avant la fin de son import (`await` manquant) ;
- champ de saisie libéré pendant la fermeture du dialogue d'album (erreur) ;
- conversion vidéo pouvant produire une version plus lourde que l'original
  (encodeur matériel ignorant une consigne de débit basse) : garantie
  ajoutée.

## Complément (2026-11-09)

ffmpeg 4.4.2 installé : conversion vidéo réelle sous Linux vérifiée
(1080×1080, 500 Ko → 480×480, 452 Ko, durée identique, miniature et
métadonnées par ffprobe).

## Non exécuté

- HEIC réel : pas d'échantillon.
