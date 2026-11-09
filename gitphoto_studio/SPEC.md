
# PROMPT CLAUDE CODE — GITPHOTO STUDIO IA

## 1. Mission

Tu es un ingénieur logiciel senior spécialisé en Flutter, Dart, Android, Linux, Git, GitHub, cybersécurité, multimédia et intégration d'agents IA.

Ta mission est de concevoir, développer, tester, documenter et livrer **GitPhoto Studio IA**, une application Flutter professionnelle, originale et complète.

Cette application permet à un utilisateur de sélectionner, organiser, optimiser et publier ses photos, images et vidéos dans des dépôts GitHub, sans devoir maîtriser les commandes Git.

L'application comporte deux modes :
1. Un mode classique avec interface graphique.
2. Un mode agent IA conversationnel avec exécution contrôlée.

**Plateformes obligatoires :**
- Android : APK ARM64 installable.
- Linux Ubuntu/Lubuntu : paquet `.deb` installable.
- Architecture préparée pour de futures versions Windows et macOS.

**Langue :** français par défaut, internationalisation anglais préparée.

**Exigence fondamentale :** aucun bouton factice, aucune simulation présentée comme réelle, aucune fonctionnalité annoncée comme terminée sans test correspondant.

Ne prétends jamais qu'un APK, un DEB ou un transfert GitHub fonctionne si cela n'a pas été vérifié.

---

## 2. Architecture technique

Utiliser :
- Flutter stable compatible avec l'environnement.
- Dart avec null safety.
- Material 3.
- Riverpod pour la gestion d'état.
- GoRouter pour la navigation.
- Dio pour les requêtes HTTP.
- GitHub REST API.
- Git en ligne de commande pour Linux lorsque pertinent.
- SQLite avec migrations pour les données locales.
- flutter_secure_storage ou solution sécurisée adaptée à chaque plateforme.
- image_picker ou file_picker selon les besoins.
- video_player pour les aperçus vidéo.
- Bibliothèques de traitement d'images maintenues et compatibles.
- flutter_test, tests unitaires, tests de widgets et tests d'intégration.

Utiliser une architecture modulaire avec séparation entre :
- Présentation.
- Logique métier.
- Services.
- Accès aux données.
- Fournisseurs IA.
- Publication GitHub.
- Traitement multimédia.
- Gestion des transferts.

Prévoir des interfaces permettant de remplacer les implémentations techniques sans modifier les écrans.

Ne pas ajouter de dépendance sans justification.

---

## 3. Identité visuelle

Créer un univers original appelé **GitPhoto Studio IA — L'atelier des médias connectés**.

### Direction artistique

Ambiance laboratoire multimédia futuriste et créatif.

Palette indicative :
- Bleu nuit : `#10182B`
- Violet électrique : `#7954F6`
- Cyan lumineux : `#19D9E6`
- Orange créatif : `#FF984B`
- Vert réussite : `#35D9A1`

Prévoir :
- Mode sombre et clair.
- Cartes arrondies.
- Gradients subtils.
- Effets de transparence lorsque les performances le permettent.
- Animations de transfert.
- Indicateurs de progression.
- Galerie avec miniatures.
- Interfaces adaptatives pour téléphone, tablette et ordinateur.
- Accessibilité : contrastes, tailles de texte et lecteurs d'écran.

Créer une mascotte robot originale nommée **Pixel**, assistant du studio.

Pixel accompagne les opérations, explique les erreurs et intervient dans les tutoriels. Sa présence ne doit pas gêner l'utilisation.

---

## 4. Navigation et écrans

Créer les écrans suivants.

### Écran 1 — Accueil

Tableau de bord avec :
- Dépôt GitHub actif.
- Nombre de médias locaux.
- Nombre de fichiers en attente.
- Derniers commits.
- État des transferts.
- Espace occupé localement.
- Raccourcis vers les fonctions principales.
- Zone d'accès à Pixel.

### Écran 2 — Galerie

Fonctions :
- Importer photos et vidéos.
- Sélection multiple.
- Glisser-déposer sur Linux.
- Affichage grille et liste.
- Aperçu plein écran.
- Lecture vidéo.
- Recherche et filtres.
- Tri par nom, date, type et taille.
- Détection des doublons par empreinte cryptographique.
- Consultation des métadonnées disponibles.

Les fichiers originaux doivent rester intacts par défaut.

### Écran 3 — Éditeur multimédia

Fonctions :
- Renommer.
- Redimensionner les images.
- Convertir les formats compatibles.
- Compresser les images.
- Générer des miniatures.
- Préparer les vidéos pour publication.
- Prévisualiser le résultat.
- Comparer taille originale et taille optimisée.

Utiliser des copies de travail. Ne jamais modifier ou supprimer un original sans consentement explicite.

Pour les vidéos, employer un moteur réellement disponible et vérifier ses licences, son empaquetage et sa compatibilité avec Android et Linux.

### Écran 4 — Gestionnaire GitHub

Fonctions :
- Connexion GitHub sécurisée.
- Affichage du compte connecté.
- Liste des dépôts accessibles.
- Création de dépôts publics ou privés.
- Navigation dans les dossiers.
- Création de dossiers par ajout de fichiers.
- Choix de la branche.
- Affichage des commits.
- Ouverture du dépôt dans le navigateur.
- Gestion des permissions insuffisantes.
- Déconnexion et révocation locale des identifiants.

Ne jamais créer de dépôt public automatiquement sans confirmation explicite.

### Écran 5 — Publication

Assistant étape par étape :

1. Sélection des médias.
2. Sélection du dépôt.
3. Sélection de la branche et du dossier.
4. Analyse des tailles et des conflits.
5. Optimisation facultative.
6. Préparation du message de commit.
7. Affichage des modifications prévues.
8. Validation.
9. Publication.
10. Résultat avec liens GitHub.

Prévoir une option pour regrouper les fichiers dans un même commit lorsque la méthode technique le permet.

Éviter de présenter plusieurs commits indépendants comme une transaction atomique.

### Écran 6 — Agent IA

Créer une interface conversationnelle complète.

Exemples de commandes :

« Publie ces dix photos dans mon dépôt Portfolio. »

« Classe mes images dans des dossiers par année et par mois. »

« Réduis la taille des photos sans trop perdre en qualité. »

« Prépare un album de voyage et génère un README. »

« Explique pourquoi mon dernier push a échoué. »

« Trouve les doublons avant la publication. »

« Prépare mes vidéos pour Git LFS. »

L'agent doit :
- Comprendre la demande.
- Identifier les fichiers concernés.
- Consulter les informations autorisées.
- Construire un plan d'action structuré.
- Présenter les opérations proposées.
- Demander confirmation.
- Exécuter les opérations validées.
- Vérifier les résultats.
- Expliquer les erreurs.

Utiliser des outils typés et validés, jamais une exécution libre de commandes arbitraires produites par le modèle.

L'agent ne doit jamais disposer d'un accès shell illimité.

### Écran 7 — Historique

Afficher :
- Date et heure.
- Dépôt et branche.
- Fichiers concernés.
- Message de commit.
- Identifiant du commit.
- Statut.
- Éventuelles erreurs.
- Lien vers GitHub.

Prévoir la consultation des détails et une possibilité de relancer les opérations échouées sans doublons.

### Écran 8 — Paramètres

Prévoir :
- Compte GitHub.
- Gestion des fournisseurs IA.
- Préférences d'optimisation.
- Limites de taille.
- Thème.
- Langue.
- Gestion des données locales.
- Export des paramètres non sensibles.
- Diagnostic.
- Journal technique.
- Informations de version.

### Écran 9 — Mode d'emploi

Créer une documentation intégrée, accessible hors ligne, avec :
- Premiers pas.
- Connexion GitHub.
- Création d'un dépôt.
- Publication d'une photo.
- Publication d'une vidéo.
- Fonctionnement des commits.
- Fonctionnement des branches.
- Utilisation de Git LFS.
- Utilisation de l'agent IA.
- Explication des erreurs.
- Questions fréquentes.
- Glossaire Git/GitHub.

Inclure un parcours guidé pour débutants.

---

## 5. Fournisseurs IA

Créer une interface `AIProvider` indépendante.

Prévoir des adaptateurs pour :
- OpenAI.
- Anthropic Claude.
- Google Gemini.
- Mistral.
- Ollama local lorsque accessible.

Ne pas supposer que tous les fournisseurs prennent en charge les mêmes fonctionnalités.

Chaque adaptateur doit déclarer ses capacités :
- Conversation.
- Vision.
- Analyse de métadonnées.
- Appels d'outils structurés.
- Disponibilité.

L'utilisateur doit pouvoir :
- Choisir un fournisseur.
- Configurer ses identifiants.
- Tester la connexion.
- Choisir un modèle compatible.
- Voir les erreurs.
- Désactiver l'IA.

Les fonctionnalités classiques doivent fonctionner sans IA.

Ne jamais inscrire les clés API dans le code, les fichiers de configuration livrés ou les journaux.

Aucun média ne doit être transmis à une IA externe sans consentement explicite.

---

## 6. GitHub et sécurité

### Authentification

Privilégier une authentification GitHub adaptée aux applications natives.

Étudier OAuth avec PKCE et/ou Device Flow selon les possibilités réelles de GitHub.

Prévoir une solution par jeton GitHub fine-grained avec permissions minimales lorsque nécessaire.

Ne pas embarquer de secret client confidentiel dans l'APK ou le DEB.

Stocker les identifiants dans un stockage sécurisé compatible avec les plateformes.

Sur Linux, vérifier la disponibilité du trousseau de secrets et proposer une gestion claire des erreurs.

### Permissions

Demander uniquement les permissions nécessaires aux dépôts choisis.

Informer l'utilisateur des permissions manquantes.

### Protection

Implémenter :
- Validation des chemins.
- Protection contre les traversées de répertoires.
- Vérification des noms de fichiers.
- Gestion des erreurs HTTP.
- Protection des secrets dans les logs.
- Gestion des limites de débit GitHub.
- Vérification des conflits de branche.
- Contrôle avant écrasement.
- Confirmation des opérations destructives.

Aucune suppression distante ou publication ne doit être exécutée silencieusement.

---

## 7. Gros fichiers et Git LFS

Créer un service de publication avec plusieurs stratégies.

### Stratégie A — Fichiers ordinaires

Utiliser les API GitHub appropriées, en respectant leurs limites documentées.

### Stratégie B — Git natif

Sur Linux, permettre l'utilisation contrôlée de Git pour les opérations compatibles.

### Stratégie C — Git LFS

Prévoir Git LFS pour les gros fichiers lorsque les outils et le compte le permettent.

Vérifier :
- Installation de Git.
- Disponibilité de Git LFS.
- Configuration des attributs.
- Limites du compte.
- Compatibilité du dépôt.
- Gestion des erreurs de transfert.

### Particularité Android

Ne pas supposer que Git ou Git LFS est installé.

Créer une abstraction de transport capable de distinguer les fonctionnalités réellement disponibles sur chaque plateforme.

Si un transfert LFS natif Android est développé, implémenter et tester les protocoles requis, notamment les étapes de transfert et de publication Git.

Ne pas présenter l'envoi de gros fichiers Android comme fonctionnel sans tests réels.

Lorsque la fonctionnalité est indisponible, afficher une explication et proposer une alternative compatible.

### Fiabilité

Prévoir :
- File d'attente persistante.
- États de transfert.
- Reprise contrôlée après interruption.
- Gestion des pertes de connexion.
- Annulation.
- Vérification des résultats.
- Protection contre les doubles publications.
- Nettoyage des fichiers temporaires.

Ne jamais prétendre qu'un transfert HTTP simple peut reprendre au milieu si le protocole employé ne le permet pas.

---

## 8. Base de données locale

Utiliser SQLite.

Stocker :
- Préférences non sensibles.
- Références des médias.
- Albums.
- Empreintes des fichiers.
- Dépôts enregistrés.
- Historique des opérations.
- File d'attente.
- Statuts de transfert.
- Conversations locales si l'utilisateur l'autorise.

Prévoir des migrations et des sauvegardes locales.

Ne jamais enregistrer les jetons GitHub ni les clés IA en clair dans SQLite.

---

## 9. Organisation du projet

Proposer une arborescence structurée, par exemple :

```text
gitphoto_studio_ia/
├── android/
├── linux/
├── assets/
│   ├── images/
│   ├── icons/
│   └── help/
├── lib/
│   ├── main.dart
│   ├── app/
│   ├── core/
│   ├── features/
│   │   ├── dashboard/
│   │   ├── gallery/
│   │   ├── media_editor/
│   │   ├── github/
│   │   ├── publishing/
│   │   ├── ai_agent/
│   │   ├── history/
│   │   ├── settings/
│   │   └── help/
│   └── l10n/
├── test/
├── integration_test/
├── scripts/
├── docs/
├── README.md
├── SPEC.md
└── pubspec.yaml
```

Séparer les services de publication de l'interface utilisateur.

Prévoir des adaptateurs GitHub et IA simulés uniquement pour les tests, clairement identifiés et jamais utilisés comme preuve de fonctionnement réel.

---

## 10. Tests obligatoires

### Tests unitaires
- Validation des chemins.
- Calcul des empreintes.
- Détection des doublons.
- Planification des publications.
- Choix du transport.
- Gestion des erreurs.
- Gestion des conflits.
- Validation des réponses IA.

### Tests de widgets
- Navigation.
- Sélection des médias.
- Formulaires.
- Confirmations.
- États de chargement.
- États d'erreur.

### Tests d'intégration
- Import réel de fichiers.
- Connexion GitHub dans un environnement de test autorisé.
- Publication d'un fichier.
- Vérification du commit.
- Gestion des conflits.
- Transfert interrompu.
- Réouverture de l'application.
- Gestion des gros fichiers sur les plateformes compatibles.

Ne jamais utiliser le dépôt personnel de l'utilisateur pour des tests automatiques sans son autorisation explicite.

Exécuter :
- `flutter analyze`
- `flutter test`
- Les tests d'intégration disponibles.
- Les builds Android et Linux.

Produire un rapport indiquant les tests réussis, échoués et non exécutés.

---

## 11. Livrables

### Android
- APK ARM64 release.
- Nom d'application correct.
- Icône originale.
- Permissions minimales.
- Signature release documentée.
- Procédure d'installation.

### Linux
- Application Flutter Linux release.
- Paquet `.deb`.
- Fichier `.desktop`.
- Icône.
- Dépendances déclarées.
- Installation et désinstallation testées.

### Code et documentation
- Projet Flutter complet.
- Archive ZIP du code source.
- README.
- Guide d'installation.
- Mode d'emploi.
- Guide de configuration GitHub.
- Guide des fournisseurs IA.
- Rapport de tests.
- Journal des limitations connues.
- Fichier de licence à définir avec le propriétaire.

Aucun secret, fichier de signature privé ou identifiant personnel ne doit figurer dans les archives.

---

## 12. Méthode de développement

Procéder par phases.

**Phase 1 — Fondations**
- Examiner l'environnement Flutter.
- Vérifier les SDK et dépendances.
- Initialiser le projet.
- Créer l'architecture.
- Créer le thème.
- Créer la navigation.
- Implémenter les premiers tests.

**Phase 2 — Galerie**
- Import et sélection.
- Miniatures.
- Aperçus.
- Métadonnées.
- Stockage local.

**Phase 3 — GitHub**
- Authentification.
- Liste des dépôts.
- Navigation.
- Création de dépôts.
- Publication simple réelle.

**Phase 4 — Multimédia**
- Optimisation des images.
- Préparation des vidéos.
- Gestion des doublons.
- Organisation des albums.

**Phase 5 — Publications avancées**
- Commits.
- Gestion des conflits.
- Files d'attente.
- Reprises.
- Git LFS sur Linux.
- Étude et implémentation Android selon faisabilité vérifiée.

**Phase 6 — Agent IA**
- Fournisseurs.
- Interface conversationnelle.
- Outils typés.
- Plans d'action.
- Confirmations.
- Exécution contrôlée.

**Phase 7 — Documentation**
- Tutoriels.
- Aide contextuelle.
- Glossaire.
- Diagnostic.

**Phase 8 — Qualité**
- Tests.
- Analyse statique.
- Sécurité.
- Optimisation.
- Corrections.
- Vérification des parcours complets.

**Phase 9 — Livraison**
- APK.
- DEB.
- ZIP.
- Documentation.
- Rapport de validation.

À la fin de chaque phase :
1. Résumer les fichiers créés ou modifiés.
2. Exécuter les tests correspondants.
3. Présenter les résultats.
4. Signaler les limitations.
5. Attendre la validation de l'utilisateur avant de poursuivre.

---

## 13. Critères d'acceptation

L'application est considérée comme livrable lorsque :

- Elle démarre sans erreur sur les plateformes effectivement testées.
- L'utilisateur peut sélectionner et prévisualiser ses médias.
- Il peut se connecter à GitHub.
- Il peut choisir un dépôt et une branche.
- Il peut publier un fichier ordinaire et vérifier le commit distant.
- Il peut consulter son historique.
- L'agent IA peut préparer un plan d'action et demander une validation.
- Les identifiants sont protégés.
- Les erreurs sont compréhensibles.
- Le mode d'emploi est utilisable.
- Les fonctionnalités annoncées comme opérationnelles sont testées.
- Les APK, DEB et ZIP demandés sont réellement générés et vérifiés.

Si une fonctionnalité reste indisponible, elle doit être signalée explicitement et ne pas être remplacée par une simulation trompeuse.

---

## 14. Instruction de démarrage

Commence par examiner l'environnement de développement, puis crée `SPEC.md` avec ce cahier des charges.

Réalise **uniquement la Phase 1**.

Présente ensuite :
- L'arborescence.
- Les choix techniques.
- Les écrans réalisés.
- Les tests exécutés.
- Les problèmes éventuels.
- Les prochaines étapes.

Arrête-toi à la fin de la Phase 1 pour demander ma validation.

Ne saute aucune phase et ne déclare pas le projet terminé avant d'avoir vérifié les livrables.
