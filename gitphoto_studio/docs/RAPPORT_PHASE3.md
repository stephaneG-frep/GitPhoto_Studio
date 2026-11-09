# Rapport — Phase 3 (GitHub)

Date : 2026-10-30

## Fonctionnalités livrées

- **Connexion par jeton fine-grained** (recommandée, permissions minimales
  par dépôt) : le jeton est vérifié auprès de GitHub (`GET /user`) avant
  d'être enregistré ; un jeton refusé n'est jamais conservé.
- **Connexion par navigateur (Device Flow)** : implémentée ; nécessite le
  Client ID public d'une application OAuth ou GitHub App avec le Device Flow
  activé (saisi dans l'écran ou fourni par `--dart-define=GITHUB_CLIENT_ID`).
  Aucun secret client n'est embarqué.
- **Stockage sécurisé** : `flutter_secure_storage` (Keystore Android,
  Secret Service/libsecret sous Linux). Disponibilité vérifiée réellement ;
  message explicite si le trousseau est inaccessible. Rien dans SQLite.
- Compte connecté (portées ou type de jeton, date d'expiration),
  déconnexion avec effacement local et lien vers la révocation GitHub.
- Liste des dépôts (pagination), filtre, badges privé/public/lecture seule.
- **Création de dépôt** : privé par défaut, nom validé, dépôt public
  uniquement après une seconde confirmation explicite.
- Navigation : branches, dossiers (fil d'Ariane), fichiers, derniers commits,
  ouverture dans le navigateur, dépôt actif (tableau de bord).
- **Assistant de publication** : médias → destination (dossier validé, créé
  par l'ajout des fichiers) → analyse → message → vérification → résultat.
  - Analyse : empreinte Git locale comparée à l'arborescence distante ;
    fichier identique ignoré (pas de doublon), conflit renommé par défaut,
    remplacement uniquement si demandé fichier par fichier ; avertissement
    GPS pour un dépôt public ; > 50 Mio signalé ; > 100 Mio bloqué (LFS en
    phase 5).
  - Publication **en un seul commit** (API Git : blobs → arbre → commit →
    avancée de branche **sans forçage**). Si la branche a changé entre-temps,
    GitHub refuse et rien n'est publié.
  - Dépôt vide : un commit par fichier, annoncé comme tel.
  - **Vérification distante** après publication (tête de branche et
    empreintes des fichiers relues sur GitHub).
- **Historique** (SQLite) : date, dépôt, branche, fichiers, message,
  commit, statut, erreur (expurgée), lien. Une opération restée « en cours »
  au démarrage est marquée « interrompue ».
- Erreurs expliquées en français : jeton refusé, permission insuffisante,
  introuvable, limite de débit (avec heure de reprise), conflit, réseau,
  serveur.

## Tests

| Commande | Résultat |
|---|---|
| `flutter analyze` | aucun problème |
| `flutter test` | 161 réussis, 0 échec |
| Trousseau réel Linux (GNOME Keyring) | ✔ |
| Trousseau réel Android (Keystore) | ✔ |
| Intégration Linux `app_test`, `gallery_test` | ✔ |
| APK release sur le téléphone : appel réel à GitHub (jeton volontairement faux → refus 401 affiché) | ✔ |
| **Publication réelle sur GitHub** (`integration_test/github_real_test.dart`, dépôt `stephaneG-frep/test-gitphoto`, 2026-11-09) | ✔ jeton invalide refusé (401), 2 images en **un seul commit** (`39a3859`), vérification distante OK, republication : 0 fichier envoyé |
| Builds Linux et APK release (23,1 Mio) | ✔ |

Tests unitaires et d'écran contre un faux serveur GitHub en mémoire
(`test/support/fake_github_server.dart`, réservé aux tests) : client API,
erreurs typées, pagination, publication en un commit, republication sans
doublon, conflit de branche concurrent, dépôt vide, permission refusée,
fichier modifié après analyse, Device Flow, session, historique, assistant
complet.

Défauts trouvés et corrigés :
- le bouton « Publier sur GitHub » de l'étape de vérification restait
  désactivé (aucune publication possible) ;
- la permission `INTERNET` manquait dans l'APK release (Flutter ne l'ajoute
  qu'aux versions de débogage) : aucun accès à GitHub n'aurait été possible
  sur Android.
