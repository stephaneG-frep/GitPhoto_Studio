# Rapport — Phase 1 (fondations)

Date : 2026-10-30

## Environnement vérifié

| Élément | Résultat |
|---|---|
| Flutter / Dart | 3.47.2 stable / 3.13.2 |
| Android SDK | 37.0.0, licences acceptées, JDK 21 (Android Studio) |
| Toolchain Linux | clang 14, cmake 3.22, ninja 1.10, GTK 3.24, libsecret 0.20.5 |
| Git | présent |
| Git LFS | **absent** sur cette machine |
| `flutter doctor` | aucun problème (avertissement : deux binaires `adb`) |

## Tests

| Commande | Résultat |
|---|---|
| `flutter analyze` | aucun problème |
| `flutter test` | 73 réussis, 0 échec |
| `flutter test integration_test -d linux` | 1 réussi |
| `flutter build linux --release` | réussi, démarrage vérifié (6 s, sans erreur) |
| `flutter build apk --release --target-platform android-arm64` | réussi (19,7 Mio) |
| Installation et lancement sur MTN NX1M (Android 16, arm64) | réussi, aucune erreur dans les journaux, base créée |

Tests unitaires : validation des chemins et traversées, nettoyage des noms,
masquage des secrets, migrations SQLite (application, réouverture, mise à
niveau, annulation en cas d'échec, refus d'un schéma plus récent), sauvegarde
sans écrasement, idempotence de la file d'attente, choix du transport,
détection d'outils, version, catalogue IA.

Tests de widgets : navigation téléphone et ordinateur, ouverture de chaque
écran, raccourcis, compteurs du tableau de bord issus de la base, absence de
bouton sur les écrans non implémentés, thème et langue persistés et restaurés,
états de chargement et d'erreur du diagnostic.

Test d'intégration (Linux) : base réelle sur disque, choix du thème, fermeture,
réouverture et restauration.

## Non exécuté

- APK signé avec la clé de débogage (signature release : phase 9).
- Aucun test GitHub, IA ou multimédia (phases suivantes).
