# Mode d'emploi — GitPhoto Studio IA

> Document généré par `scripts/generate_guides.py` à partir du mode d'emploi intégré à l'application (Mode d'emploi). Ne pas modifier à la main : modifier `assets/help/fr/` puis relancer le script.

## Premiers pas

GitPhoto Studio IA range vos photos et vidéos, les allège si besoin, puis les publie dans un **dépôt GitHub** sans que vous ayez à utiliser Git vous-même.

> Le plus simple : suivez le **parcours guidé** en haut du sommaire. Ses étapes se cochent toutes seules quand vous les avez faites.

### Les écrans

- **Accueil** : résumé de la bibliothèque, du dépôt actif et des derniers commits.
- **Galerie** : vos médias importés, avec recherche, tri, filtres et albums.
- **Éditeur** : optimisation des images, préparation des vidéos, albums et doublons.
- **GitHub** : connexion, liste et création de dépôts, navigation dans un dépôt.
- **Publication** : l'assistant qui envoie vos fichiers sur GitHub.
- **Agent IA** : un assistant facultatif qui prépare des plans à votre place.
- **Historique** : toutes les publications, leur résultat et leur reprise.
- **Paramètres** : apparence, publication, IA, diagnostic.

Sur téléphone, les quatre premiers écrans sont dans la barre du bas ; les autres sont dans **Plus**. Le bouton **?** en haut de chaque écran ouvre l'aide correspondante.

### Importer vos premiers médias

1. Ouvrez la Galerie.
2. Touchez **Importer** et choisissez des photos ou des vidéos. Sur ordinateur, vous pouvez aussi glisser-déposer des fichiers ou des dossiers dans la fenêtre.
3. Un rapport indique ce qui a été importé, ignoré ou refusé.

L'application garde une **copie de travail** de chaque fichier. Vos originaux ne sont jamais modifiés ni déplacés. Un fichier déjà présent (même contenu) est refusé, même sous un autre nom.

### Retirer un média

Sélectionnez-le puis **Retirer de la bibliothèque** : seules les copies du studio sont effacées, jamais vos fichiers d'origine, ni ce qui est déjà publié sur GitHub.

### Et ensuite ?

- Se connecter à GitHub
- Créer un dépôt
- Publier une photo

## Connexion à GitHub

Pour publier, l'application a besoin d'un **jeton d'accès** : une sorte de mot de passe limité, que vous créez sur GitHub et que vous pouvez révoquer à tout moment.

> Le jeton est vérifié auprès de GitHub puis gardé **uniquement** dans le trousseau sécurisé du système (Keystore sous Android, GNOME Keyring ou KWallet sous Linux). Il n'est jamais écrit dans la base de l'application ni dans les journaux.

### Créer un jeton « fine-grained » (recommandé)

1. Sur GitHub, ouvrez votre photo de profil › **Settings** › **Developer settings** › **Personal access tokens** › **Fine-grained tokens**, puis **Generate new token**. Le bouton **Créer un jeton sur GitHub** de l'écran GitHub y mène directement.
2. Donnez-lui un nom (par exemple « GitPhoto ») et une date d'expiration.
3. **Repository access** : choisissez **Only select repositories** et cochez seulement vos dépôts de photos.
4. **Permissions** › **Repository permissions** › **Contents** : **Read and write**. La permission **Metadata** (lecture) est ajoutée automatiquement.
5. Facultatif : pour créer des dépôts depuis l'application, ajoutez **Administration** : **Read and write**.
6. Cliquez sur **Generate token** et copiez le jeton (il ne sera plus affiché).

### Se connecter

1. Ouvrez l'écran GitHub.
2. Collez le jeton dans **Jeton GitHub** puis touchez **Vérifier et se connecter**.
3. L'écran affiche « Connecté en tant que … », vos dépôts et, quand GitHub les fournit, les portées et la date d'expiration du jeton.

Ne communiquez jamais votre jeton, même à un assistant ou à une IA.

### Connexion par le navigateur

Si vous disposez d'une application OAuth ou d'une GitHub App avec le **Device Flow** activé, saisissez son **Client ID** puis **Se connecter avec le navigateur** : un code s'affiche, à recopier sur la page GitHub qui s'ouvre. Aucun secret n'est nécessaire.

### Se déconnecter

**Se déconnecter** efface le jeton de cet appareil. Pour l'invalider définitivement, supprimez-le aussi sur GitHub (**Gérer mes jetons sur GitHub**).

### Problèmes fréquents

- **« GitHub refuse le jeton »** : il est mal copié, expiré ou révoqué. Créez-en un nouveau.
- **« Permission insuffisante »** : le dépôt n'est pas coché dans le jeton, ou **Contents** n'est pas en écriture.
- **« Le trousseau sécurisé du système est inaccessible »** (Linux) : démarrez et déverrouillez GNOME Keyring ou KWallet, puis relancez l'application.

Voir aussi : Comprendre les erreurs.

## Créer ou choisir un dépôt

Un **dépôt** est un dossier en ligne sur GitHub, avec l'historique de toutes ses versions. Vous pouvez en utiliser un existant ou en créer un.

### Créer un dépôt

1. Écran GitHub › **Nouveau dépôt**.
2. Choisissez un nom : lettres, chiffres, « - », « _ » et « . » uniquement, 100 caractères au maximum.
3. Ajoutez une description si vous le souhaitez.
4. Choisissez la visibilité :
   - **Privé** : visible par vous et les personnes que vous invitez. Recommandé pour des photos personnelles.
   - **Public** : visible par tout le monde sur Internet. L'application demande une **seconde confirmation**.
5. Touchez **Créer**.

Le jeton doit avoir la permission **Administration** en écriture ; sinon, créez le dépôt sur github.com puis ajoutez-le à votre jeton.

> Un dépôt public montre aussi les métadonnées de vos photos, dont la **position GPS**. Optimisez vos images avant de les publier : les copies optimisées n'en contiennent pas.

### Choisir le dépôt actif

Ouvrez un dépôt dans la liste puis **Définir comme dépôt actif**. Il est proposé par défaut dans l'assistant de publication, et ses derniers commits apparaissent à l'Accueil.

### Parcourir un dépôt

En ouvrant un dépôt, vous voyez ses dossiers et fichiers, la **branche** affichée (modifiable) et ses derniers commits. **Publier ici** ouvre l'assistant avec ce dépôt, cette branche et ce dossier déjà choisis.

Voir aussi : Les branches, Publier une photo.

## Publier une photo

L'assistant de Publication vous montre **exactement** ce qui sera envoyé avant de toucher à GitHub.

### Les étapes

1. **Médias** : cochez les photos ou vidéos à publier.
2. **Destination** : dépôt, branche et dossier (par exemple `photos/2024`). Un dossier inexistant est créé automatiquement ; laissez vide pour la racine.
3. **Analyse** : l'application compare vos fichiers avec le dépôt :
   - **Nouveau** : le fichier sera ajouté ;
   - **Identique sur GitHub — ignoré** : il est déjà publié, rien n'est renvoyé ;
   - **Nom déjà pris — publié sous un autre nom** : un fichier différent porte ce nom ; le vôtre est renommé pour ne rien écraser. Cochez **Remplacer plutôt que renommer** seulement si vous voulez vraiment remplacer l'ancien.
4. **Message** : la phrase qui décrit la publication dans l'historique de GitHub (le *message de commit*).
5. **Vérification** : la liste finale ; puis **Publier sur GitHub** et une confirmation.
6. **Résultat** : le commit créé, vérifié sur GitHub, avec un lien pour l'ouvrir.

### Ce qu'il faut savoir

- Tous les fichiers partent en **un seul commit**. Pour un dépôt vide, un premier commit l'initialise avec un fichier, puis un second regroupe les autres.
- La publication passe par une **file d'attente** : vous pouvez quitter l'écran, elle continue et reste visible dans l'Historique.
- Si quelqu'un modifie le dépôt pendant la publication, rien n'est écrasé : soit l'application reconstruit le commit (fichiers différents), soit elle s'arrête sans rien publier.
- Une photo contenant une **position GPS** publiée dans un dépôt public est signalée. Pensez à optimiser vos images avant.
- Les fichiers de plus de 50 Mio passent par Git LFS.

### Après une coupure

En cas de perte de connexion, l'application réessaie seule deux fois. Sinon, reprenez la publication depuis l'Historique : seuls les fichiers manquants seront envoyés.

## Préparer et publier une vidéo

Les vidéos de téléphone sont souvent lourdes. L'application peut en créer une **version plus légère** au format MP4 avant publication.

### Convertir une vidéo

1. Ouvrez l'Éditeur et choisissez la vidéo.
2. Dans **Préparation de la vidéo**, choisissez un préréglage :
   - **Légère (480p)** : la plus petite, idéale pour un aperçu ;
   - **720p** : bon compromis ;
   - **1080p** : meilleure qualité.
3. Cochez **Retirer le son** si la bande sonore est inutile : le fichier sera encore plus léger.
4. La **taille estimée** s'affiche ; touchez **Convertir en MP4**.

La vidéo d'origine est conservée. La nouvelle version n'est gardée **que si elle est plus petite** : sinon, l'application vous l'indique (la vidéo est sans doute déjà bien compressée).

### Moteur de conversion

- **Android** : Media3, intégré au système, rien à installer.
- **Linux** : ffmpeg. S'il manque : `sudo apt install ffmpeg`, puis **Paramètres › Diagnostic › Actualiser**.

### Publier

Publiez la version convertie comme une photo, avec l'assistant de Publication. Au-delà de 50 Mio, le fichier passe automatiquement par Git LFS (2 Gio au maximum).

> Sous Linux, la lecture de la vidéo dans l'application nécessite un lecteur système ; à défaut, elle s'ouvre dans votre lecteur habituel.

## Optimiser et organiser

Chaque traitement crée une **nouvelle version** : l'original n'est jamais modifié.

### Optimiser une image

Dans l'Éditeur, choisissez une image puis un préréglage :

- **Web (1920 px)** : pour un site ou un portfolio ;
- **Léger (1280 px)** : plus petit, encore net à l'écran ;
- **Miniature (400 px)** : vignettes ;
- **Personnalisé** : plus grand côté, format (JPEG ou PNG), qualité.

**Métadonnées** :
- **Tout retirer** (recommandé pour publier) : ni date, ni appareil, ni position GPS ;
- **Garder date et appareil** : jamais la position GPS.

L'**Aperçu** compare la taille avant et après. **Enregistrer comme nouvelle version** ajoute la copie à la bibliothèque, liée à son original et rangée dans le même album.

Pour plusieurs images à la fois : sélectionnez-les dans la Galerie puis **Optimiser**.

### Albums

- Galerie : sélection › **Ranger dans un album** (existant ou nouveau).
- Éditeur › **Albums** : créer, renommer, supprimer un album (les médias restent dans la bibliothèque), et **Classer par année et mois** pour ranger automatiquement les médias hors album dans des albums « AAAA-MM » selon leur date de prise de vue.

### Doublons probables

Éditeur › **Doublons probables** regroupe les images visuellement très proches (redimensionnées, recompressées…). Vous pouvez retirer celles en trop. Les copies exactes, elles, sont déjà refusées à l'import.

### Renommer

Dans l'Éditeur, modifiez le **Nom du fichier** puis **Renommer**. C'est ce nom qui sera utilisé sur GitHub.

## Les commits

Un **commit** est une photographie de votre dépôt à un instant donné : il enregistre quels fichiers ont été ajoutés ou modifiés, par qui, quand, avec un message qui décrit le changement.

### Pourquoi c'est utile

- Rien ne se perd : chaque version précédente reste consultable dans l'historique de GitHub.
- Vous savez ce qui a changé et quand.
- Chaque commit a un identifiant unique (une suite de 40 caractères, souvent abrégée en 7, par exemple `e6358d7`).

### Dans GitPhoto Studio

- Une publication = **un commit**, même avec cent fichiers. Exception : un dépôt vide reçoit d'abord un commit d'initialisation.
- Vous écrivez le **message de commit** à l'étape **Message** ; un message par défaut est proposé (« Ajout de 3 médias via GitPhoto Studio »).
- Après l'envoi, l'application **vérifie** sur GitHub que chaque fichier est bien présent avec le contenu attendu.
- L'identifiant et le lien du commit figurent dans le résultat et dans l'Historique.

### Remplacer un fichier

Si vous choisissez de remplacer un fichier existant, l'ancienne version n'est pas détruite : elle reste dans l'historique Git, accessible sur GitHub.

Voir aussi : Les branches.

## Les branches

Une **branche** est une ligne de versions parallèle dans un dépôt. La branche principale s'appelle généralement `main` (parfois `master`).

### À quoi ça sert

On crée une branche pour préparer des changements sans toucher à la version principale, puis on les fusionne quand ils sont prêts. Pour publier des photos, la branche principale suffit presque toujours.

### Dans GitPhoto Studio

- L'assistant de publication propose la **branche par défaut** du dépôt ; vous pouvez en choisir une autre parmi celles qui existent.
- Dans l'écran GitHub, la navigation dans un dépôt affiche la branche choisie et ses derniers commits.
- L'application **ne crée pas** de branche et **ne force jamais** une publication : si la branche a avancé entre-temps, elle s'adapte ou s'arrête, sans rien écraser.

> Les branches se créent et se fusionnent sur github.com si vous en avez besoin.

## Git LFS (gros fichiers)

GitHub refuse les fichiers de plus de **100 Mio** dans un dépôt normal et signale ceux de plus de 50 Mio. **Git LFS** (Large File Storage) stocke ces gros fichiers à part : le dépôt ne contient qu'un petit fichier « pointeur ».

### Comment l'application l'utilise

- Au-delà de **50 Mio**, un fichier est envoyé automatiquement par Git LFS (badge **Git LFS** à l'analyse).
- Maximum : **2 Gio** par fichier (limite d'un compte GitHub gratuit). Au-delà, le fichier est bloqué avant tout envoi.
- Le fichier est envoyé en flux, sans être chargé entièrement en mémoire.
- L'application ajoute aussi la règle correspondante dans le fichier `.gitattributes` du dépôt, dans le même commit.
- Cela fonctionne **sous Android comme sous Linux**, sans rien installer : l'application parle directement au service LFS de GitHub.

### Quota

Les fichiers LFS utilisent le **quota de stockage LFS** de votre compte GitHub, qui est limité (voir **Settings › Billing** sur GitHub). Un objet LFS ne peut être supprimé qu'en supprimant le dépôt entier.

### Désactiver Git LFS

**Paramètres › Publication › Git LFS pour les fichiers de plus de 50 Mio**. Les fichiers de plus de 100 Mio seront alors bloqués.

> Conseil : convertissez d'abord vos vidéos en version plus légère (voir Préparer une vidéo) ; elles passeront souvent sous les 50 Mio.

## Historique et reprise

L'Historique liste chaque publication : date, dépôt et branche, fichiers, message, commit, statut, erreurs éventuelles et lien vers GitHub. Touchez une ligne pour voir le détail fichier par fichier.

### Statuts

- **En file d'attente** : confirmée, elle attend son tour (ou une connexion à GitHub).
- **En cours** : envoi en cours, avec la progression.
- **Réussie** : commit créé et vérifié.
- **Échouée** : une erreur l'a arrêtée ; le message explique pourquoi.
- **Interrompue** : l'application a été fermée pendant l'envoi ; le résultat est inconnu.
- **Annulée** : vous l'avez arrêtée.

### Reprendre

**Reprendre** relit d'abord le dépôt sur GitHub :
- un fichier déjà publié n'est **jamais renvoyé** ;
- un fichier déjà transmis mais pas encore validé n'est pas retransmis ;
- si un fichier visé a été modifié par quelqu'un d'autre entre-temps, rien n'est publié.

Après une perte de connexion, l'application réessaie seule deux fois (après 5 s puis 30 s) avant de vous laisser reprendre.

### Annuler

**Annuler** arrête une publication en attente ou en cours, entre deux fichiers. Ce qui est déjà sur GitHub n'est pas retiré, et rien n'est jamais publié à moitié : le commit n'est créé qu'à la fin.

> La file fonctionne tant que l'application est ouverte. Si vous la fermez, la publication reprendra au prochain lancement.

## Utiliser l'agent IA

L'agent comprend des demandes en langage courant et prépare un **plan** que vous validez. Il est **désactivé par défaut** : toute l'application fonctionne sans lui.

### Activer l'agent

1. **Paramètres › Fournisseurs IA** › **Activer l'assistant IA**.
2. Choisissez un fournisseur (Mistral est recommandé), enregistrez votre clé, choisissez un modèle et touchez **Tester la connexion**. Voir Fournisseurs IA.
3. Ouvrez l'Agent IA et acceptez l'envoi des métadonnées.

### Exemples de demandes

- « Publie les photos sélectionnées dans mon dépôt Portfolio. »
- « Classe mes images dans des albums par année et par mois. »
- « Réduis la taille des photos sans trop perdre en qualité. »
- « Prépare un album de voyage et génère un README. »
- « Explique pourquoi ma dernière publication a échoué. »
- « Trouve les doublons avant la publication. »
- « Quelles vidéos passeront par Git LFS ? »

« Ces photos » désigne la **sélection** de la galerie.

### Comment il travaille

1. Il **consulte** les informations utiles : sélection, bibliothèque, albums, doublons, état GitHub, historique, aperçu d'une publication. Ces consultations ne modifient rien ; elles sont indiquées sous sa réponse.
2. Pour agir, il **propose un plan** : une liste d'étapes numérotées, avec les avertissements calculés par l'application (position GPS, dépôt public…).
3. Vous touchez **Exécuter le plan** puis confirmez, ou **Refuser**.
4. L'application exécute les étapes une par une, vérifie chaque résultat et affiche le compte rendu. Vous pouvez **Arrêter** entre deux fichiers.

### Ce qu'il peut faire (et rien d'autre)

- ranger des médias dans un album, ou par année / mois ;
- créer des versions optimisées d'images ;
- créer des versions converties de vidéos ;
- publier sur GitHub en un commit, avec un README facultatif.

Il **ne peut pas** supprimer, remplacer un fichier existant, exécuter une commande ou accéder à vos autres fichiers. L'application vérifie chaque plan : un média ou un dépôt inventé, un dossier dangereux ou une branche invalide sont refusés.

### Bon à savoir

- Un plan non confirmé devient caduc dès que vous envoyez une nouvelle demande.
- L'agent ne voit **pas** le contenu de vos images, seulement leurs informations (nom, taille, dates…). Il ne peut donc pas choisir « les plus belles photos ».
- Les conversations ne sont enregistrées que si vous l'autorisez dans les paramètres.

## Fournisseurs IA et clés

L'agent peut utiliser plusieurs fournisseurs. **Mistral** est le fournisseur recommandé : c'est celui qui a été testé avec le vrai service (indiqué « Testé avec le vrai service » dans les paramètres). Les autres sont prêts mais n'ont été testés qu'avec un serveur simulé.

### Configuration

**Paramètres › Fournisseurs IA** :
1. **Activer l'assistant IA**.
2. **Fournisseur** : choisissez dans la liste.
3. **Clé d'API** : collez-la puis **Enregistrer la clé**. Elle est gardée dans le trousseau sécurisé du système, jamais dans la base de l'application, et le champ est vidé aussitôt.
4. **Modèle** : touchez l'icône de liste pour charger les modèles disponibles ; choisissez un modèle qui sait utiliser des **outils** (mention « outils » chez Mistral).
5. **Tester la connexion**.

### Obtenir une clé

- **Mistral AI** : console.mistral.ai › **API Keys** › **Create new key**. Modèle conseillé : `mistral-small-latest`.
- **OpenAI** : platform.openai.com › **API keys**.
- **Anthropic Claude** : console.anthropic.com › **API Keys**.
- **Google Gemini** : aistudio.google.com › **Get API key**.

Le bouton **Obtenir une clé** ouvre la bonne page. Ces services sont généralement **payants à l'usage** : consultez leurs tarifs. Ne partagez jamais votre clé.

### Ollama (local, sans clé)

Ollama fait tourner un modèle sur votre ordinateur, sans envoyer de données sur Internet.

```
ollama pull llama3.1
ollama serve
```

- Sous Linux, l'adresse par défaut `http://localhost:11434/v1` convient.
- Sur le téléphone, `localhost` désigne le téléphone lui-même : indiquez l'adresse de l'ordinateur sur le réseau local (par exemple `http://192.168.1.20:11434/v1`) et lancez Ollama avec `OLLAMA_HOST=0.0.0.0`.
- Choisissez un modèle qui gère les outils ; sinon l'agent ne pourra que converser.

### Désactiver l'IA

Décochez **Activer l'assistant IA**. Pour effacer la clé : **Supprimer la clé**. Pour effacer l'historique : **Effacer les conversations enregistrées**.

Voir aussi : Confidentialité.

## Comprendre les erreurs

Chaque erreur est expliquée en clair dans l'application. Voici les plus fréquentes et quoi faire.

### GitHub

- **GitHub refuse le jeton** : jeton invalide, expiré ou révoqué. Créez-en un nouveau et reconnectez-vous (Connexion).
- **Permission insuffisante** : le dépôt n'est pas inclus dans votre jeton, ou il manque **Contents** en écriture (ou **Administration** pour créer un dépôt). Modifiez le jeton sur GitHub.
- **Introuvable** : le dépôt, la branche ou le dossier n'existe pas, ou le jeton n'y a pas accès.
- **Limite de requêtes GitHub atteinte** : attendez l'heure indiquée, puis reprenez.
- **La branche a été modifiée sur GitHub pendant la publication** ou **« … » a été modifié sur GitHub depuis l'analyse** : quelqu'un a changé le dépôt en même temps. Rien n'a été publié ; relancez l'analyse.
- **« … » est déjà en attente de publication** : la même publication est déjà dans la file ; consultez l'Historique.
- **Connexion à GitHub impossible** : vérifiez Internet. L'application réessaie seule deux fois.
- **GitHub rencontre un problème (erreur serveur)** : réessayez plus tard.

### Publication

- **Nom de fichier incompatible avec un dépôt** : renommez le média dans l'Éditeur.
- **Plus de 100 Mio alors que Git LFS est désactivé** : réactivez Git LFS dans les paramètres ou allégez le fichier.
- **Plus de 2 Gio** : convertissez la vidéo en version plus légère.
- **Publié, mais la vérification distante n'a pas pu confirmer tous les fichiers** : le commit existe ; ouvrez-le sur GitHub pour contrôler.
- **Interrompue** : l'application a été fermée pendant l'envoi. **Reprendre** ignorera ce qui est déjà publié.

### Vidéo

- **Conversion vidéo indisponible : ffmpeg n'est pas installé** (Linux) : `sudo apt install ffmpeg`, puis **Paramètres › Diagnostic › Actualiser**.
- **La conversion ne réduit pas la taille** : la vidéo est déjà compressée ; essayez **Retirer le son** ou un préréglage plus bas.

### Agent IA

- **Clé d'API refusée** : vérifiez ou remplacez la clé dans les paramètres.
- **Trop de requêtes ou quota épuisé** : attendez, ou vérifiez votre crédit chez le fournisseur.
- **Ce modèle ne sait pas utiliser d'outils** : choisissez un autre modèle (par exemple `mistral-small-latest`).
- **Impossible de joindre le fournisseur** : vérifiez Internet, ou l'adresse du serveur pour Ollama.

### Trousseau

- **Le trousseau sécurisé du système est inaccessible** (Linux) : démarrez et déverrouillez GNOME Keyring ou KWallet. Sans lui, aucun jeton ni aucune clé ne peut être enregistré.

### Demander de l'aide

**Paramètres › Diagnostic › Copier le rapport** produit un résumé technique sans jeton, clé, nom de compte ni nom de fichier, à joindre à votre demande. Le **Journal technique** détaille les événements de la session.

## Confidentialité et sécurité

### Ce qui reste sur votre appareil

- Les copies de travail de vos médias et leurs miniatures, dans le dossier privé de l'application.
- La base locale : bibliothèque, albums, historique, préférences, et conversations avec l'agent **seulement si vous l'autorisez**.
- Vos fichiers d'origine ne sont jamais modifiés.

### Jetons et clés

- Le jeton GitHub et les clés d'IA sont gardés **uniquement** dans le trousseau sécurisé du système.
- Ils ne sont jamais écrits dans la base, dans les journaux, dans l'export des paramètres ni dans le rapport de diagnostic.
- Ils ne sont jamais transmis au modèle d'IA.

### Position GPS

Beaucoup de photos contiennent l'endroit où elles ont été prises. L'application :
- l'indique dans les informations du média (**Position GPS : Présente**) ;
- vous avertit avant une publication dans un dépôt public ;
- la retire toujours des versions optimisées.

### Agent IA

- Désactivé par défaut ; un accord explicite est demandé avant le premier envoi.
- Seules des informations textuelles sont transmises : votre message, des noms de fichiers, tailles, dates, albums, la **présence** d'une position GPS (jamais la position), les noms de vos dépôts et l'historique des publications.
- **Aucune image ni vidéo n'est envoyée.**
- Avec Ollama en local, rien ne quitte votre réseau.

### Ce qui n'est jamais fait sans vous

Aucune publication, aucune suppression distante, aucun remplacement de fichier n'a lieu sans votre confirmation. Un dépôt public n'est jamais créé sans une seconde confirmation.

### Effacer vos données

- Retirer des médias : Galerie › sélection › **Retirer de la bibliothèque**.
- Déconnecter GitHub : écran GitHub › **Se déconnecter** (puis révoquez le jeton sur GitHub).
- Clé IA : **Paramètres › Fournisseurs IA › Supprimer la clé** ; conversations : **Effacer les conversations enregistrées**.
- Tout effacer : désinstallez l'application.

## Questions fréquentes

### Mes photos d'origine sont-elles modifiées ?

Non. L'application travaille sur des copies. Optimiser, convertir, renommer ou retirer de la bibliothèque n'affecte jamais vos fichiers d'origine.

### Faut-il connaître Git ?

Non. L'application crée les commits pour vous et vérifie le résultat. Les rubriques Commits et Branches expliquent les notions si vous êtes curieux.

### Puis-je publier sans Internet ?

Non, mais vous pouvez préparer vos médias hors ligne. Une publication confirmée attend dans la file et part dès que la connexion revient (application ouverte).

### Une photo a été publiée deux fois ?

C'est évité : un fichier identique déjà présent à cet emplacement est ignoré, et une même publication ne peut pas être mise deux fois en file. Si un fichier différent porte le même nom, le vôtre est renommé.

### Comment supprimer une photo publiée sur GitHub ?

L'application ne supprime jamais rien sur GitHub. Faites-le sur github.com (ouvrir le fichier › menu › **Delete file**). L'ancienne version restera dans l'historique Git.

### Pourquoi un dépôt privé ?

Seuls vous et les personnes invitées y ont accès. Un dépôt public est visible par tout le monde, y compris les métadonnées des photos.

### Le jeton expire, que faire ?

Créez-en un nouveau sur GitHub, puis reconnectez-vous dans l'écran GitHub. Les publications en attente reprendront.

### L'IA est-elle obligatoire ?

Non. Elle est désactivée par défaut et toutes les fonctions marchent sans elle.

### Combien coûte l'agent IA ?

L'application est gratuite ; les fournisseurs d'IA en ligne facturent généralement à l'usage, sur votre compte chez eux. Ollama, en local, est gratuit.

### Pourquoi la conversion vidéo n'est-elle pas proposée ?

Sous Linux, installez ffmpeg (`sudo apt install ffmpeg`) puis actualisez **Paramètres › Diagnostic**.

### Quelle taille maximale ?

Jusqu'à 50 Mio par l'API GitHub ; de 50 Mio à 2 Gio par Git LFS (quota de votre compte) ; au-delà, refusé.

### Où trouver plus d'aide ?

Cherchez un mot dans le sommaire du mode d'emploi, ou copiez le rapport de diagnostic (**Paramètres › Diagnostic**) pour le joindre à une demande d'aide.

## Glossaire

- **Agent IA** : assistant facultatif qui comprend une demande écrite et propose un plan à confirmer.
- **Album** : regroupement de médias dans la bibliothèque de l'application (n'existe pas sur GitHub).
- **API** : porte d'entrée par laquelle un programme parle à un service (ici GitHub ou un fournisseur d'IA).
- **Branche** : ligne de versions d'un dépôt ; la principale s'appelle souvent `main`.
- **Clé d'API** : identifiant secret qui autorise l'application à utiliser un service d'IA.
- **Commit** : enregistrement d'un ensemble de changements dans un dépôt, avec un message, un auteur et une date.
- **Conflit** : situation où le dépôt a changé entre l'analyse et la publication ; l'application s'arrête plutôt que d'écraser.
- **Dépôt (repository)** : dossier en ligne sur GitHub qui conserve les fichiers et tout leur historique.
- **Dépôt actif** : le dépôt proposé par défaut pour publier.
- **Device Flow** : connexion à GitHub en recopiant un code dans le navigateur.
- **EXIF** : informations enregistrées dans une photo (date, appareil, position GPS…).
- **Empreinte (SHA)** : code calculé à partir du contenu d'un fichier ; deux fichiers identiques ont la même.
- **File d'attente** : liste des publications confirmées, exécutées une par une.
- **Fine-grained (jeton)** : jeton GitHub limité à des dépôts et des permissions précis.
- **Fournisseur IA** : service qui fait fonctionner le modèle d'IA (Mistral, OpenAI, Anthropic, Gemini, Ollama).
- **Git** : logiciel qui gère les versions des fichiers ; GitHub l'héberge en ligne.
- **GitHub** : site qui héberge des dépôts Git.
- **Git LFS** : extension de Git pour les gros fichiers, stockés à part.
- **`.gitattributes`** : fichier du dépôt qui indique, entre autres, quels fichiers passent par Git LFS.
- **Jeton (token)** : mot de passe limité et révocable qui autorise l'application à agir sur vos dépôts.
- **Message de commit** : phrase qui décrit une publication.
- **Métadonnées** : informations sur un fichier (nom, taille, date, appareil, position…).
- **Modèle** : le programme d'IA lui-même (par exemple `mistral-small-latest`).
- **Ollama** : logiciel pour faire tourner un modèle d'IA sur son propre ordinateur.
- **Plan** : liste d'étapes proposée par l'agent, exécutée seulement après votre confirmation.
- **Pointeur LFS** : petit fichier texte placé dans le dépôt à la place d'un gros fichier.
- **Privé / public** : visibilité d'un dépôt (vous et vos invités / tout le monde).
- **Push** : envoi de commits vers GitHub.
- **README** : fichier de présentation affiché sur la page d'accueil d'un dépôt.
- **Trousseau** : coffre-fort du système pour les mots de passe (Keystore, GNOME Keyring, KWallet).
- **Version** : copie d'un média créée par l'application (optimisée, convertie) ; l'original reste intact.
