# Guide d'installation — GitPhoto Studio IA

Version **1.0.0**. Livrables (dossier `dist/`, publiés à part du code) :

| Fichier | Contenu |
|---|---|
| `gitphoto-studio-1.0.0-arm64.apk` | Android ARM64 |
| `gitphoto-studio_1.0.0_amd64.deb` | Linux x86-64 (Debian, Ubuntu…) |
| `gitphoto-studio-1.0.0-source.zip` | code source |
| `SHA256SUMS` | empreintes pour vérifier les fichiers |

Vérifier l'intégrité d'un fichier téléchargé :

```
sha256sum -c SHA256SUMS --ignore-missing
```

## Android (ARM64)

**Configuration requise** : Android 7.0 (API 24) ou plus récent, processeur
ARM 64 bits. Testé sur un téléphone MTN NX1M.

**Permissions** : accès à Internet (GitHub et, si vous l'activez, le
fournisseur d'IA). Le lecteur vidéo intégré (Media3) ajoute deux permissions
techniques accordées automatiquement, sans demande : état du réseau et
maintien de l'écran allumé pendant la lecture. Aucun accès général à vos
fichiers : les photos et vidéos sont choisies par le sélecteur du système.
La sauvegarde automatique Android est désactivée.

### Installer

1. Copiez `gitphoto-studio-1.0.0-arm64.apk` sur le téléphone.
2. Ouvrez-le depuis le gestionnaire de fichiers. Android demande d'autoriser
   l'installation depuis cette source : acceptez pour cette fois.
3. Lancez **GitPhoto Studio IA**.

Depuis un ordinateur, avec le débogage USB activé :

```
adb install -r gitphoto-studio-1.0.0-arm64.apk
```

L'option `-r` met à jour l'application en **conservant ses données**
(bibliothèque, historique, connexion GitHub).

### Désinstaller

Paramètres Android › Applications › GitPhoto Studio IA › Désinstaller. Les
copies de travail, la base locale, le jeton GitHub et les clés d'IA de
l'application sont effacés. Vos photos d'origine ne sont pas touchées.

### Signature

Choix du propriétaire : application **personnelle**, signée avec la **clé
de développement** d'Android (certificat « Android Debug »). Les mises à
jour s'installent par-dessus sans perte de données, depuis la même machine
de compilation.

Pour une diffusion publique, il faudrait une clé de livraison, **à garder
précieusement hors du dépôt** (la perdre empêche toute mise à jour) :

```
keytool -genkey -v -keystore ~/.config/gitphoto/gitphoto-release.jks \
  -keyalg RSA -keysize 4096 -validity 10000 -alias gitphoto
```

puis un fichier `android/key.properties` (ignoré par Git) et une
configuration `signingConfigs.release` dans `android/app/build.gradle.kts`.
Changer de clé impose de désinstaller la version signée avec l'ancienne
(les données de l'application sont alors effacées).

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

### Installer le paquet .deb

```
sudo apt install ./gitphoto-studio_1.0.0_amd64.deb
```

`apt` installe aussi les dépendances manquantes. L'application apparaît dans
le menu (« GitPhoto Studio IA ») et se lance aussi par la commande
`gitphoto-studio`. Fichiers installés : `/opt/gitphoto-studio/`
(application), `/usr/bin/gitphoto-studio`, le raccourci du menu, l'icône et
la documentation dans `/usr/share/doc/gitphoto-studio/`.

### Désinstaller

```
sudo apt remove gitphoto-studio
```

Les données personnelles ne sont pas supprimées par la désinstallation :
`~/.local/share/com.nabu.gitphoto.gitphoto_studio/` (base locale, copies de
travail, miniatures). Pour tout effacer : se déconnecter de GitHub dans
l'application (le jeton est retiré du trousseau), puis supprimer ce dossier.

### Sans installation

Le dossier `build/linux/x64/release/bundle/` (après compilation) contient
l'application complète : `./gitphoto_studio`.

## Compiler depuis les sources

Prérequis : Flutter stable (testé : 3.47.2 / Dart 3.13.2) ; pour Linux :
`clang cmake ninja-build pkg-config libgtk-3-dev libsecret-1-dev` ; pour
Android : SDK Android et JDK 17+.

```
flutter pub get
flutter test
flutter build linux --release
flutter build apk --release --target-platform android-arm64
bash scripts/build_deb.sh          # → dist/gitphoto-studio_<version>_amd64.deb
bash scripts/build_source_zip.sh   # → dist/gitphoto-studio-<version>-source.zip
```

Icône : `flutter test tool/icon/render_icon_test.dart` puis
`python3 tool/icon/resize_icons.py` (rendue à partir de la mascotte Pixel).

## Premiers pas après l'installation

Ouvrez **Mode d'emploi** dans l'application : le parcours guidé vous mène de
l'import de la première photo à la première publication. Le même contenu
existe en fichier : [MODE_EMPLOI.md](MODE_EMPLOI.md). Pour GitHub :
[GUIDE_GITHUB.md](GUIDE_GITHUB.md) ; pour l'IA : [GUIDE_IA.md](GUIDE_IA.md).
