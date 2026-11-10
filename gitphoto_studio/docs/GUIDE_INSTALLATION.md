# Guide d'installation — GitPhoto Studio IA

> État : phase 7. Les paquets définitifs (APK signé de livraison, paquet
> `.deb`, archive ZIP) seront produits et vérifiés en **phase 9**. Ce guide
> décrit l'installation telle qu'elle est testée aujourd'hui.

## Android (ARM64)

**Configuration requise** : Android 7.0 (API 24) ou plus récent, processeur
ARM 64 bits. Testé sur un téléphone MTN NX1M.

**Permission demandée** : accès à Internet uniquement (GitHub et, si vous
l'activez, le fournisseur d'IA). Les photos et vidéos sont choisies par le
sélecteur du système : l'application n'a pas d'accès général à vos fichiers.

### Installer

1. Copiez `app-release.apk` sur le téléphone.
2. Ouvrez-le depuis le gestionnaire de fichiers. Android demande d'autoriser
   l'installation depuis cette source : acceptez pour cette fois.
3. Lancez **GitPhoto Studio IA**.

Depuis un ordinateur, avec le débogage USB activé :

```
adb install -r app-release.apk
```

L'option `-r` met à jour l'application en **conservant ses données**
(bibliothèque, historique, connexion GitHub).

### Désinstaller

Paramètres Android › Applications › GitPhoto Studio IA › Désinstaller. Les
copies de travail, la base locale, le jeton GitHub et les clés d'IA de
l'application sont effacés. Vos photos d'origine ne sont pas touchées.

> La signature actuelle est une signature de développement. La signature de
> livraison et sa procédure seront documentées en phase 9.

## Linux (x86-64)

Testé sous Ubuntu 22.04 (noyau 6.8).

### Dépendances

| Paquet | Rôle | Obligatoire |
|---|---|---|
| `libgtk-3-0` | interface | oui |
| `libsecret-1-0` + GNOME Keyring ou KWallet actif | trousseau sécurisé (jeton GitHub, clés IA) | oui pour se connecter |
| `ffmpeg` | conversion vidéo | non |
| `git` | publication par Git natif (option) | non |

```
sudo apt install libgtk-3-0 libsecret-1-0 gnome-keyring ffmpeg git
```

Git LFS n'a pas besoin d'être installé : l'application parle directement au
service LFS de GitHub.

### Lancer la version compilée

Le dossier `build/linux/x64/release/bundle/` contient l'application complète
(exécutable, bibliothèques, ressources). Copiez ce dossier où vous voulez,
puis :

```
./gitphoto_studio
```

Données de l'application : `~/.local/share/com.nabu.gitphoto.gitphoto_studio/`
(base locale, copies de travail, miniatures). Pour tout effacer, supprimez ce
dossier après avoir quitté l'application, et retirez le jeton du trousseau
(écran GitHub › Se déconnecter, avant suppression).

## Compiler depuis les sources

Prérequis : Flutter stable (testé : 3.47.2 / Dart 3.13.2) ; pour Linux :
`clang cmake ninja-build pkg-config libgtk-3-dev libsecret-1-dev` ; pour
Android : SDK Android et JDK 17+.

```
flutter pub get
flutter test
flutter build linux --release
flutter build apk --release --target-platform android-arm64
```

## Premiers pas après l'installation

Ouvrez **Mode d'emploi** dans l'application : le parcours guidé vous mène de
l'import de la première photo à la première publication. Le même contenu
existe en fichier : [MODE_EMPLOI.md](MODE_EMPLOI.md). Pour GitHub :
[GUIDE_GITHUB.md](GUIDE_GITHUB.md) ; pour l'IA : [GUIDE_IA.md](GUIDE_IA.md).
