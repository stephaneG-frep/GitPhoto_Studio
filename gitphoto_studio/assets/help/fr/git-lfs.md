# Git LFS (gros fichiers)

GitHub refuse les fichiers de plus de **100 Mio** dans un dépôt normal et signale ceux de plus de 50 Mio. **Git LFS** (Large File Storage) stocke ces gros fichiers à part : le dépôt ne contient qu'un petit fichier « pointeur ».

## Comment l'application l'utilise

- Au-delà de **50 Mio**, un fichier est envoyé automatiquement par Git LFS (badge **Git LFS** à l'analyse).
- Maximum : **2 Gio** par fichier (limite d'un compte GitHub gratuit). Au-delà, le fichier est bloqué avant tout envoi.
- Le fichier est envoyé en flux, sans être chargé entièrement en mémoire.
- L'application ajoute aussi la règle correspondante dans le fichier `.gitattributes` du dépôt, dans le même commit.
- Cela fonctionne **sous Android comme sous Linux**, sans rien installer : l'application parle directement au service LFS de GitHub.

## Quota

Les fichiers LFS utilisent le **quota de stockage LFS** de votre compte GitHub, qui est limité (voir **Settings › Billing** sur GitHub). Un objet LFS ne peut être supprimé qu'en supprimant le dépôt entier.

## Désactiver Git LFS

**Paramètres › Publication › Git LFS pour les fichiers de plus de 50 Mio**. Les fichiers de plus de 100 Mio seront alors bloqués.

> Conseil : convertissez d'abord vos vidéos en version plus légère (voir [Préparer une vidéo](help:publier-video)) ; elles passeront souvent sous les 50 Mio.
