# GitPhoto Studio IA — L'atelier des médias connectés

Application Flutter (Android ARM64, Linux `.deb`) pour organiser, optimiser et
publier photos et vidéos dans des dépôts GitHub sans manipuler Git, avec un
mode classique et un agent IA (Mistral en priorité) à exécution contrôlée.

Cahier des charges : [SPEC.md](SPEC.md). État d'avancement : **phase 6 —
agent IA** (voir [docs/RAPPORT_PHASE6.md](docs/RAPPORT_PHASE6.md) et
[docs/LIMITATIONS.md](docs/LIMITATIONS.md)).

## Prérequis

- Flutter stable (testé : 3.47.2 / Dart 3.13.2)
- Linux : clang, cmake, ninja, pkg-config, GTK 3 (`libgtk-3-dev`)
- Android : SDK Android, JDK 17+

## Commandes

```bash
flutter pub get
flutter analyze
flutter test                          # tests unitaires et widgets
flutter test integration_test/app_test.dart -d linux      # un fichier à la fois
flutter test integration_test/gallery_test.dart -d linux
# Test réel Mistral (clé dans ~/.config/gitphoto/mistral_key, droits 600) :
flutter test integration_test/mistral_real_test.dart -d linux
flutter run -d linux
flutter build linux --release
flutter build apk --release --target-platform android-arm64
```

## Architecture

```text
lib/
├── main.dart              ouverture de la base, lancement
├── app/                   application, routeur, navigation adaptative, thème
├── core/
│   ├── database/          SQLite + migrations + préférences non sensibles
│   ├── security/          validation de chemins, masquage des secrets
│   ├── secrets/           contrat du stockage sécurisé (implémenté en phase 3)
│   ├── logging/           journal technique expurgé
│   ├── platform/          détection de Git / Git LFS
│   └── utils/
├── features/<module>/     dashboard, gallery, media_editor, github,
│   ├── domain/            publishing, ai_agent, history, settings, help
│   ├── application/
│   └── presentation/
├── shared/widgets/        Pixel, gabarits d'écran
└── l10n/                  fr (par défaut), en
```

Le dossier `_legacy/` contient l'ancien code, conservé tel quel et exclu de
l'analyse et des builds.
