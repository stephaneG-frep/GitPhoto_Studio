# Rapport — Phase 5 (publications avancées)

Date : 2026-11-09

## Fonctionnalités livrées

- **File d'attente persistante** (SQLite, migration v4) : une publication =
  une opération (un commit) + un enregistrement par fichier (stratégie,
  empreinte, taille, décision « ajout/remplacement », blob déjà envoyé).
  Elle survit à la fermeture de l'application ; les opérations confirmées
  reprennent dès qu'une session GitHub est disponible.
- **Reprise contrôlée** : une opération échouée ou interrompue se reprend
  depuis l'Historique. L'état réel du dépôt est d'abord relu : un fichier
  déjà publié est ignoré (aucune double publication), un chemin modifié par
  quelqu'un d'autre arrête l'opération. Reprise **fichier par fichier** (les
  blobs déjà envoyés ne sont pas renvoyés ; renvoi automatique s'ils ont
  disparu) — jamais au milieu d'un fichier, le protocole ne le permettant
  pas.
- **Pertes de connexion** : erreurs réseau, serveur ou limite de débit →
  deux nouveaux essais automatiques (5 s, 30 s), puis reprise manuelle.
- **Annulation** : immédiate pour une opération en attente, entre deux
  fichiers pour une opération en cours ; impossible après l'avancée de la
  branche (rien n'est alors à moitié publié).
- **Doublons** : une publication identique déjà en file vers le même chemin
  est refusée.
- **Conflits** : avant chaque commit, l'arborescence actuelle est comparée à
  celle de l'analyse ; si la branche a avancé sans toucher aux mêmes
  fichiers, le commit est reconstruit sur la nouvelle tête (2 essais) ;
  sinon, rien n'est publié.
- **Stratégie C — Git LFS en HTTP** (protocole « batch » de GitHub,
  transfert « basic ») : au-delà de 50 Mio, contenu envoyé **en flux** au
  stockage LFS, puis pointeur et règle `.gitattributes` (chemin exact
  échappé) dans le même commit ; vérification de l'objet après coup.
  **Fonctionne sous Android et Linux sans l'outil `git-lfs`.** Au-delà de
  2 Gio : refusé (limite GitHub LFS d'un compte gratuit).
- **Stratégie B — Git natif (Linux)** : clone partiel sans contenus, commit
  par commandes de bas niveau, `push` sans forçage ; jeton transmis par
  `GIT_ASKPASS` (jamais dans l'URL ni les arguments), assistants
  d'identifiants neutralisés ; auteur = adresse « noreply » GitHub.
  Distinction conflit (branche avancée) / refus (branche protégée).
- Dépôt vide : initialisation puis **un seul** commit pour le reste.
- Interface : Historique (statut de chaque fichier, stratégie, tentatives,
  Reprendre/Annuler, progression), assistant (badges LFS/Git, annulation),
  Paramètres › Publication (Git LFS, Git natif).

## Défauts trouvés et corrigés

- **Écrasement silencieux** : le publieur relisait la tête de branche après
  l'envoi et pouvait écraser un fichier modifié entre-temps par un autre
  auteur. Vérification des chemins ajoutée avant chaque commit.
- Refus de push par une règle du dépôt présenté comme un conflit.

## Tests

| Commande | Résultat |
|---|---|
| `flutter analyze` | aucun problème |
| `flutter test` | 221 réussis, 0 échec |
| Git natif contre un dépôt Git local (vrai `git`) | ✔ commit unique, conflit déterministe, refus de règle, jeton jamais écrit |
| **GitHub réel, Linux** (`github_real_phase5_test.dart`) | ✔ LFS HTTP (commit `e6358d7`), Git natif (commit `e820e2c`), jeton invalide refusé |
| **GitHub réel, Android** (téléphone) | ✔ LFS HTTP (commit `e5d0ffc`) — jeton déposé temporairement puis effacé |
| Intégration Linux `app`, `gallery`, `editor_device` (avec ffmpeg) | ✔ |
| Builds Linux et APK release (25,0 Mio), installé et lancé | ✔ |

## Non vérifié

- Gros fichiers réels (centaines de Mio) : LFS testé avec 10 Kio pour
  préserver le quota du dépôt de test.
- Quota LFS dépassé : message de GitHub relayé, non provoqué.
