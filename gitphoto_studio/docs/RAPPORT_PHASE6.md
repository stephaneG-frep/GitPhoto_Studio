# Rapport — Phase 6 (agent IA)

Date : 2026-11-09

## Fonctionnalités livrées

- **Fournisseurs** (`lib/features/ai_agent/data/`) derrière l'interface
  `AiProvider`, chacun déclarant ses capacités :
  - format « chat completions » : **Mistral** (prioritaire), OpenAI, Ollama
    (point d'accès `/v1`, local) ;
  - Anthropic (API Messages) ;
  - Google Gemini (`generateContent`, clé en en-tête, jamais dans l'URL ;
    signature de raisonnement renvoyée telle quelle).
  Erreurs typées (clé refusée, quota, modèle introuvable, modèle sans
  outils, réseau, délai…), toujours expurgées : la clé est retirée de tout
  message, même si un serveur la recopiait.
- **Paramètres IA** : IA **désactivée par défaut** ; choix du fournisseur ;
  clé enregistrée **uniquement** dans le trousseau du système (Keystore /
  libsecret), jamais dans SQLite ; adresse du serveur modifiable pour Ollama
  seulement (HTTPS, ou HTTP local) ; chargement de la liste des modèles (avec
  la mention « outils » publiée par Mistral) ; test de connexion ; accord
  d'envoi ; enregistrement facultatif des conversations et effacement.
- **Accord explicite** avant le premier envoi : l'écran liste ce qui est
  transmis (message, noms, tailles, dates, albums, présence d'une position
  GPS, noms des dépôts, historique). **Aucune image ni vidéo n'est envoyée** ;
  la vision des modèles n'est pas utilisée.
- **Interface conversationnelle** (écran Agent IA) : exemples de demandes,
  indication des informations consultées, arrêt, nouvelle conversation,
  conversations restaurées si l'utilisateur l'a autorisé.
- **Outils typés** :
  - consultation, exécutée sans confirmation et sans effet : sélection de la
    galerie, recherche de médias (type, album, dates, nom), albums, doublons
    visuels, état GitHub et dépôts, historique avec erreurs, aperçu de
    publication (chemins finaux, fichiers identiques, renommages, Git LFS,
    blocages) ;
  - action : un seul outil, `propose_plan`, qui **n'exécute rien**.
- **Plans d'action validés** : 5 actions seulement, aucune destructive —
  ranger dans un album, ranger par année/mois, créer des versions
  optimisées, créer des versions vidéo converties, publier (un commit,
  README facultatif). Chaque champ est revalidé par l'application : médias
  existants, types de média, préréglages, dépôt réellement accessible en
  écriture, nom de branche, dossier sans traversée, références entre
  étapes. Un plan invalide est renvoyé au modèle avec les erreurs (3 essais
  au maximum). Les avertissements (GPS, dépôt public, conversion vidéo
  indisponible) sont calculés par l'application, pas par le modèle.
- **Confirmations** : bouton « Exécuter le plan » puis boîte de dialogue
  récapitulative ; « Refuser » ; un plan non confirmé devient caduc dès la
  demande suivante ; un plan restauré d'une ancienne conversation n'est
  jamais réexécutable.
- **Exécution contrôlée** (`PlanExecutor`) : par les services existants
  (albums, optimisation, conversion, file de publication de la phase 5), étape
  par étape, arrêt possible, arrêt à la première étape en échec (les
  suivantes sont marquées « non exécutées »), **vérification** de chaque
  résultat (album relu, copies présentes, commit relu sur GitHub). Une
  publication est réanalysée au moment de l'exécution et ne remplace jamais
  un fichier existant (renommage). Le compte rendu est transmis au modèle
  avec le message suivant, pour qu'il puisse expliquer les erreurs.
- **Publication d'un fichier hors bibliothèque** (README rédigé par
  l'agent) : migration **v5** (`transfer_queue.local_path`), reprise
  possible comme pour un média.
- Refactorisation : l'analyse de publication (`PublicationAnalyzer`) est
  partagée entre l'assistant de publication et l'agent.

## Sécurité

- Le modèle n'a accès à aucun shell, aucun fichier, aucune suppression,
  aucun écrasement : ces opérations ne sont tout simplement pas
  représentables dans un plan. Un outil inconnu demandé par le modèle est
  refusé.
- Arguments lus strictement (types, bornes, caractères de contrôle, dates).
- Résultats d'outils expurgés des secrets et tronqués (12 000 caractères).
- Boucle limitée à 8 échanges avec le modèle par demande.

## Tests

- `flutter analyze` : aucun problème.
- `flutter test` : **281 tests réussis** (221 en phase 5).
  - Adaptateurs (15) contre un serveur HTTP **simulé** : format exact des
    requêtes (en-têtes, outils, historique avec appels et résultats),
    lecture des appels d'outils, erreurs typées, clé jamais recopiée,
    identifiant de modèle dangereux refusé.
  - Validation des plans (15) : identifiants inventés, dépôts inconnus ou
    en lecture seule, traversées de dossier, branches invalides, types
    d'étape inconnus (« supprimer », « shell »…), références entre étapes.
  - Boucle de l'agent (13) : consultation puis plan sans exécution,
    correction après refus, abandon après 3 plans invalides, outil
    inexistant refusé, limite d'échanges, annulation, historique tronqué.
  - Exécution (5) avec les **vrais services** de l'application (seul GitHub
    est simulé) : optimisation réelle (copies plus petites, sans GPS,
    originaux conservés), rangement par mois de prise de vue, publication
    des copies + README en un commit vérifié, rejeu sans nouveau commit,
    README existant jamais remplacé, arrêt à la première erreur, arrêt
    demandé, média retiré entre proposition et confirmation.
  - Écrans (11) : IA désactivée, clé manquante, accord exigé, réponse et
    outils consultés, refus d'un plan, confirmation puis exécution vérifiée,
    plan caduc, erreur compréhensible, conversations enregistrées seulement
    si autorisé puis restaurées, téléphone, clé stockée dans le trousseau et
    jamais dans SQLite.
  - Migration v4 → v5 avec une file existante.
- **Réel, Mistral** (`integration_test/mistral_real_test.dart`, Linux,
  modèle `mistral-small-latest`, bibliothèque et dépôts simulés pour ne
  rien envoyer de personnel) — **5/5 réussis** :
  - connexion et liste des modèles (38 modèles de conversation, capacité
    « outils » publiée) ✔ ;
  - question « combien de vidéos ? » : le modèle consulte la bibliothèque
    (`search_media`) et répond « Il y a 1 vidéo dans ta bibliothèque. » ✔ ;
  - « range les photos sélectionnées dans un album Vacances 2024 » : le
    modèle consulte la sélection puis propose un plan **validé**
    (déplacement des médias 1 et 2), rien n'est exécuté ✔ ;
  - « supprime définitivement plage.jpg » : refus expliqué, aucun plan ✔ ;
  - clé invalide : refus classé « clé refusée », clé non recopiée ✔.
  Défaut constaté et corrigé : le modèle répondait en Markdown (astérisques
  affichées telles quelles) ; consigne « texte simple » ajoutée et vérifiée.
  Mistral est désormais marqué « Testé avec le vrai service ».
- **Builds** : Linux release ✔ ; APK ARM64 25,3 Mo ✔, installé sur le
  téléphone (MTN NX1M) et lancé sans erreur ; écran Agent IA et section
  Paramètres affichés correctement ; **migration v5 appliquée sur le
  téléphone** avec ses données existantes (« Schéma v5 », médias
  conservés).
- **Écran de l'agent sur le téléphone** (`integration_test/agent_device_test.dart`,
  `--no-uninstall`, base temporaire, fournisseur **simulé**) : saisie, plan,
  dialogue de confirmation, exécution vérifiée ✔. Version release
  réinstallée ensuite ; données de l'application intactes (2 médias).

## Défauts trouvés et corrigés pendant la phase

- La boucle transmettait au fournisseur une liste de messages qu'elle
  continuait de modifier ensuite : copie figée désormais.
- Après l'ajout des fichiers hors bibliothèque, la reprise d'une
  publication dont le média avait été retiré affichait un message trompeur
  (« fichier local retiré ») : message d'origine rétabli.

## Non vérifié

- OpenAI, Anthropic, Gemini et Ollama : testés uniquement contre un serveur
  simulé (indiqué dans les paramètres : « Non testé avec le vrai service »).
- Agent réel sur le téléphone avec Mistral (le fournisseur réel a été testé
  sous Linux ; le code est identique sous Android).
