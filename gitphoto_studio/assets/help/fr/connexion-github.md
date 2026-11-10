# Connexion à GitHub

Pour publier, l'application a besoin d'un **jeton d'accès** : une sorte de mot de passe limité, que vous créez sur GitHub et que vous pouvez révoquer à tout moment.

> Le jeton est vérifié auprès de GitHub puis gardé **uniquement** dans le trousseau sécurisé du système (Keystore sous Android, GNOME Keyring ou KWallet sous Linux). Il n'est jamais écrit dans la base de l'application ni dans les journaux.

## Créer un jeton « fine-grained » (recommandé)

1. Sur GitHub, ouvrez votre photo de profil › **Settings** › **Developer settings** › **Personal access tokens** › **Fine-grained tokens**, puis **Generate new token**. Le bouton **Créer un jeton sur GitHub** de l'écran GitHub y mène directement.
2. Donnez-lui un nom (par exemple « GitPhoto ») et une date d'expiration.
3. **Repository access** : choisissez **Only select repositories** et cochez seulement vos dépôts de photos.
4. **Permissions** › **Repository permissions** › **Contents** : **Read and write**. La permission **Metadata** (lecture) est ajoutée automatiquement.
5. Facultatif : pour créer des dépôts depuis l'application, ajoutez **Administration** : **Read and write**.
6. Cliquez sur **Generate token** et copiez le jeton (il ne sera plus affiché).

## Se connecter

1. Ouvrez l'écran [GitHub](app:/github).
2. Collez le jeton dans **Jeton GitHub** puis touchez **Vérifier et se connecter**.
3. L'écran affiche « Connecté en tant que … », vos dépôts et, quand GitHub les fournit, les portées et la date d'expiration du jeton.

Ne communiquez jamais votre jeton, même à un assistant ou à une IA.

## Connexion par le navigateur

Si vous disposez d'une application OAuth ou d'une GitHub App avec le **Device Flow** activé, saisissez son **Client ID** puis **Se connecter avec le navigateur** : un code s'affiche, à recopier sur la page GitHub qui s'ouvre. Aucun secret n'est nécessaire.

## Se déconnecter

**Se déconnecter** efface le jeton de cet appareil. Pour l'invalider définitivement, supprimez-le aussi sur GitHub (**Gérer mes jetons sur GitHub**).

## Problèmes fréquents

- **« GitHub refuse le jeton »** : il est mal copié, expiré ou révoqué. Créez-en un nouveau.
- **« Permission insuffisante »** : le dépôt n'est pas coché dans le jeton, ou **Contents** n'est pas en écriture.
- **« Le trousseau sécurisé du système est inaccessible »** (Linux) : démarrez et déverrouillez GNOME Keyring ou KWallet, puis relancez l'application.

Voir aussi : [Comprendre les erreurs](help:erreurs).
