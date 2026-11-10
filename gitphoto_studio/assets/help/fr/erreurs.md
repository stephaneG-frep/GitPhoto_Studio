# Comprendre les erreurs

Chaque erreur est expliquée en clair dans l'application. Voici les plus fréquentes et quoi faire.

## GitHub

- **GitHub refuse le jeton** : jeton invalide, expiré ou révoqué. Créez-en un nouveau et reconnectez-vous ([Connexion](help:connexion-github)).
- **Permission insuffisante** : le dépôt n'est pas inclus dans votre jeton, ou il manque **Contents** en écriture (ou **Administration** pour créer un dépôt). Modifiez le jeton sur GitHub.
- **Introuvable** : le dépôt, la branche ou le dossier n'existe pas, ou le jeton n'y a pas accès.
- **Limite de requêtes GitHub atteinte** : attendez l'heure indiquée, puis reprenez.
- **La branche a été modifiée sur GitHub pendant la publication** ou **« … » a été modifié sur GitHub depuis l'analyse** : quelqu'un a changé le dépôt en même temps. Rien n'a été publié ; relancez l'analyse.
- **« … » est déjà en attente de publication** : la même publication est déjà dans la file ; consultez l'Historique.
- **Connexion à GitHub impossible** : vérifiez Internet. L'application réessaie seule deux fois.
- **GitHub rencontre un problème (erreur serveur)** : réessayez plus tard.

## Publication

- **Nom de fichier incompatible avec un dépôt** : renommez le média dans l'Éditeur.
- **Plus de 100 Mio alors que Git LFS est désactivé** : réactivez Git LFS dans les paramètres ou allégez le fichier.
- **Plus de 2 Gio** : convertissez la vidéo en version plus légère.
- **Publié, mais la vérification distante n'a pas pu confirmer tous les fichiers** : le commit existe ; ouvrez-le sur GitHub pour contrôler.
- **Interrompue** : l'application a été fermée pendant l'envoi. **Reprendre** ignorera ce qui est déjà publié.

## Vidéo

- **Conversion vidéo indisponible : ffmpeg n'est pas installé** (Linux) : `sudo apt install ffmpeg`, puis **Paramètres › Diagnostic › Actualiser**.
- **La conversion ne réduit pas la taille** : la vidéo est déjà compressée ; essayez **Retirer le son** ou un préréglage plus bas.

## Agent IA

- **Clé d'API refusée** : vérifiez ou remplacez la clé dans les paramètres.
- **Trop de requêtes ou quota épuisé** : attendez, ou vérifiez votre crédit chez le fournisseur.
- **Ce modèle ne sait pas utiliser d'outils** : choisissez un autre modèle (par exemple `mistral-small-latest`).
- **Impossible de joindre le fournisseur** : vérifiez Internet, ou l'adresse du serveur pour Ollama.

## Trousseau

- **Le trousseau sécurisé du système est inaccessible** (Linux) : démarrez et déverrouillez GNOME Keyring ou KWallet. Sans lui, aucun jeton ni aucune clé ne peut être enregistré.

## Demander de l'aide

**Paramètres › Diagnostic › Copier le rapport** produit un résumé technique sans jeton, clé, nom de compte ni nom de fichier, à joindre à votre demande. Le **Journal technique** détaille les événements de la session.
