# Guide de configuration GitHub

> Document généré par `scripts/generate_guides.py` à partir du mode d'emploi intégré à l'application (Mode d'emploi). Ne pas modifier à la main : modifier `assets/help/fr/` puis relancer le script.

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
