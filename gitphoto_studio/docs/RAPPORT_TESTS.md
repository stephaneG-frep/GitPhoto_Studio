# Rapport de tests — GitPhoto Studio IA 1.0.0

Date : 2026-11-11 · Flutter 3.47.2 / Dart 3.13.2 · Ubuntu 22.04 (x86-64) ·
téléphone MTN NX1M (Android, ARM64).

## 1. Tests automatisés (`flutter test`)

**354 tests, tous réussis.** Analyse statique stricte : aucun problème.
Couverture : 83,7 % du code de l'application (traductions générées exclues).

| Domaine | Exemples de vérifications |
|---|---|
| Base de données | migrations v1 → v5, mise à niveau avec données, réouverture |
| Sécurité | chemins (traversée, caractères interdits), expurgation des secrets, liens `https` seuls, jeton/clé jamais en base |
| Galerie | import, doublons exacts refusés, EXIF/orientation, albums, doublons visuels |
| Éditeur | optimisation (GPS retiré), versions, vidéo (taille garantie plus petite) |
| GitHub | API, Device Flow, erreurs typées, limites de débit |
| Publication | plan (ajout, identique, renommage, LFS, blocage), un commit, dépôt vide, conflits, file persistante, reprise sans doublon, annulation, Git natif, Git LFS |
| Agent IA | 5 adaptateurs (format exact des requêtes), validation des plans, boucle, outils, exécution avec les vrais services, rappel « plan en texte » |
| Écrans | navigation, formulaires, confirmations, chargements, historique, agent, paramètres, aide, diagnostic |
| Accessibilité | contraste, cibles 48 dp, libellés (9 écrans, clair/sombre, écrans remplis), texte à 200 % |
| Performance | 5 000 médias : galerie < 0,2 s, Accueil < 0,1 s, recherche de l'agent ≈ 0,1 s |
| Documentation | 16 rubriques × 2 langues, liens valides, guides `docs/` synchronisés |

Les serveurs GitHub et IA **simulés** utilisés par ces tests vérifient le
format des échanges ; ils ne prouvent pas le fonctionnement réel, établi
par les tests de la section 2.

## 2. Tests réels

Sur le dépôt de test autorisé `stephaneG-frep/test-gitphoto` (dossier
`gitphoto-tests/`) et l'API Mistral réelle.

| Test | Plateforme | Résultat |
|---|---|---|
| Connexion, publication simple vérifiée, jeton invalide refusé | Linux | ✔ |
| Git LFS (envoi réel, objet vérifié) | Linux, Android | ✔ (phase 5) |
| Git natif (commit vérifié) | Linux | ✔ (phase 5) |
| Git LFS en lecture seule (client modifié en phase 8) | Linux | ✔ |
| Parcours classique : import → optimisation → publication → historique → republication sans doublon | Linux | ✔ |
| Mistral : connexion, consultation, plan validé, refus d'une suppression, clé invalide | Linux | ✔ 5/5 |
| Parcours IA de bout en bout (Mistral + GitHub, confirmation, commit vérifié) | Linux | ✔ 3/3 |

## 3. Tests sur appareils

| Test | Résultat |
|---|---|
| Android : conversion vidéo réelle (Media3), éditeur | ✔ (phase 4) |
| Android : écran de l'agent (saisie, plan, confirmation, exécution) | ✔ |
| Android : APK 1.0.0 installé par mise à jour, lancement, données conservées, icône | ✔ |
| Linux : base SQLite réelle et réouverture, galerie | ✔ |
| Linux : conversion vidéo ffmpeg | ✔ (phase 5) |
| Linux : application extraite du paquet `.deb`, lancée (données isolées) | ✔ |
| Linux : installation / désinstallation du `.deb` par `apt` (lancées par le propriétaire, journaux vérifiés) | ✔ |

## 4. Non testé

- Fournisseurs OpenAI, Anthropic, Gemini et Ollama contre leurs vrais
  services (serveur simulé uniquement ; indiqué dans l'application).
- Fichiers de plusieurs centaines de Mo et dépassement du quota Git LFS.
- Autres appareils Android et autres distributions Linux.
