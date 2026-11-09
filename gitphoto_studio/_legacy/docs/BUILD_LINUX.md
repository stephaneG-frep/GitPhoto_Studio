# Build Linux pour GitPhoto Studio IA

## 📋 Résumé

Ce guide explique comment builder GitPhoto Studio IA pour Linux. Le projet utilise Flutter 3.47+ et nécessite des outils spécifiques pour générer un package `.deb`.

---

## 🔧 Prérequis

### 1. Système d'exploitation compatible

| Distribution | Version minimum | Statut |
|-------------|-----------------|--------|
| Ubuntu | 22.04 LTS | ✅ Recommandé |
| Debian | 11 (Bullseye) | ✅ |
| Fedora | 36+ | ✅ |
| Arch Linux | Latest | ✅ |
| Ubuntu | 20.04 LTS | ⚠️ Possible avec mises à jour |

> **⚠️ IMPORTANT** : Ubuntu 22.04 ou plus récent est **fortement recommandé** pour éviter les problèmes de dépendances.

---

## ⚡ Installation des dépendances

### Ubuntu/Debian

```bash
# Mise à jour complète du système
sudo apt update && sudo apt upgrade -y

# Outils de base
sudo apt install -y git curl wget unzip zip cmake ninja-build pkg-config

# Bibliothèques Flutter pour Linux
sudo apt install -y libgtk-3-dev liblzma-dev libstdc++6 libgstreamer1.0-dev

# Outils de développement
sudo apt install -y g++ gcc make

# Vérifier les versions
cmake --version    # Doit être >= 3.10
clang++ --version  # Doit être >= 9.0
ninja --version    # Doit être installé
```

### Fedora

```bash
sudo dnf install -y git curl wget unzip zip cmake clang ninja-build pkgconfig
sudo dnf install -y gtk3-devel xz-devel libstdc++-devel gstreamer1-devel
```

### Arch Linux

```bash
sudo pacman -Syu --needed git curl wget unzip zip cmake clang ninja pkgconf
sudo pacman -S --needed gtk3 xz libstdc++ gstreamer
```

---

## 🚨 Résolution des problèmes de GLIBCXX

Si vous obtenez des erreurs comme :
```
/usr/bin/cmake: /home/nabucodeoneother/.vscode/extensions/.../libstdc++.so.6: version `GLIBCXX_3.4.30' not found
```

### Solution 1 : Utiliser Ubuntu 22.04+ (Recommandé) ⭐

Le moyen le plus simple est d'utiliser une distribution récente :
```bash
# Sur Ubuntu 22.04 ou 24.04, tout devrait fonctionner
lsb_release -a
```

### Solution 2 : Utiliser le SDK Android NDK

Le SDK Android inclut des versions de cmake et clang compatibles :

```bash
# Configurer les variables d'environnement
export ANDROID_HOME=$HOME/Android/Sdk
export PATH=$ANDROID_HOME/cmake/3.22.1/bin:$ANDROID_HOME/ndk/28.2.13676358/toolchains/llvm/prebuilt/linux-x86_64/bin:$PATH
export CMAKE_CXX_COMPILER=$ANDROID_HOME/ndk/28.2.13676358/toolchains/llvm/prebuilt/linux-x86_64/bin/clang++

# Puis builder
flutter build linux
```

### Solution 3 : Installer manuellement libstdc++ récent

```bash
# Sur Ubuntu/Debian
sudo add-apt-repository ppa:ubuntu-toolchain-r/test
sudo apt update
sudo apt install -y g++-12 libstdc++6

# Sélectionner la version par défaut
sudo update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-12 100
sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-12 100
```

### Solution 4 : Utiliser un conteneur Docker

```bash
# Installer Docker
docker pull ubuntu:22.04

# Lancer un conteneur avec toutes les dépendances
docker run -it --rm \
  -v $(pwd):/app \
  -v /tmp:/tmp \
  ubuntu:22.04 bash -c "
  apt update && apt install -y curl git wget unzip zip \
  apt install -y cmake clang ninja-build pkg-config \
  apt install -y libgtk-3-dev liblzma-dev libstdc++6 \
  apt install -y libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev \
  apt install -y libx11-dev libxkbcommon-dev libxrandr-dev libxrender-dev \
  
  # Installer Flutter
  curl https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.19.5-stable.tar.xz -o flutter.tar.xz \
  tar xf flutter.tar.xz \
  export PATH=/app/flutter/bin:/app/flutter/bin/cache/dart-sdk/bin:$PATH \
  
  cd /app && \
  flutter doctor && \
  flutter pub get && \
  flutter build linux --release
"
```

### Solution 5 : Utiliser le script de build automatique

```bash
# Donner les permissions d'exécution
chmod +x scripts/build_linux.sh

# Exécuter le script
./scripts/build_linux.sh
```

Le script vérifie automatiquement les dépendances et propose des solutions.

---

## 🏗️ Build de l'application

### 1. Récupérer les dépendances Dart

```bash
cd gitphoto_studio
flutter pub get
```

### 2. Builder en mode debug (pour test)

```bash
flutter build linux
```

**Résultat** : L'exécutable se trouve dans `build/linux/x64/debug/bundle/`

### 3. Builder en mode release (pour production)

```bash
flutter build linux --release
```

### 4. Générer le package .deb

Le build release génère automatiquement un package `.deb` :

```bash
# Le package se trouve dans
ls -la build/linux/deb/

# Exemple de sortie:
# gitphoto_studio-1.0.0+1-linux-x64.deb
```

### 5. Installer le package

```bash
# Installer
sudo dpkg -i build/linux/deb/gitphoto_studio-*.deb

# Résoudre les dépendances manquantes
sudo apt --fix-broken install
```

### 6. Désinstaller

```bash
sudo dpkg -r gitphoto_studio
```

### 7. Exécuter l'application

```bash
# Depuis la ligne de commande
gitphoto_studio

# Ou depuis le menu des applications (si installé)
```

---

## ⚠️ Problèmes courants et solutions

### ❌ Erreur: "CMAKE_BUILD_WITH_INSTALL_RPATH"

```
CMake Error: The install of the gitphoto_studio target requires changing an RPATH
```

**Solution 1** : Configurer CMake pour utiliser make au lieu de ninja

```bash
# Créer un fichier toolchain
cat > linux.cmake << 'EOF'
set(CMAKE_BUILD_WITH_INSTALL_RPATH ON)
set(CMAKE_INSTALL_RPATH "\$ORIGIN")
EOF

flutter build linux --cmake -C linux.cmake
```

**Solution 2** : Utiliser une version récente de CMake

```bash
# Installer CMake 3.25+
wget https://github.com/Kitware/CMake/releases/download/v3.28.3/cmake-3.28.3-linux-x86_64.tar.gz
tar xf cmake-3.28.3-linux-x86_64.tar.gz
export PATH=$(pwd)/cmake-3.28.3-linux-x86_64/bin:$PATH
flutter build linux
```

**Solution 3** : Modifier le CMakeLists.txt (temporaire)

Dans `linux/runner/CMakeLists.txt`, ajouter avant `add_executable` :
```cmake
set(CMAKE_BUILD_WITH_INSTALL_RPATH ON)
```

### ❌ Erreur: "permission_handler: Compile SDK version is 36 but target SDK is 34"

**Solution** : Mettre à jour le compileSdk dans `android/app/build.gradle`

```gradle
android {
    compileSdk 36
    # ...
}
```

### ❌ Erreur: "Unable to access driver information using 'eglinfo'"

```bash
sudo apt install mesa-utils libgl1-mesa-dev
```

### ❌ Erreur: "No valid Android SDK platforms found"

Ce warning peut être ignoré pour le build Linux. Si vous voulez le supprimer :

```bash
flutter config --no-android-sdk
```

### ❌ Erreur: "The plugin `desktop_drop` doesn't have a implementation for linux"

Ce plugin est compatible Linux. Vérifiez votre version :

```yaml
# Dans pubspec.yaml
desktop_drop: ^0.4.4
```

---

## 🔄 Build incrémental

Pour gagner du temps lors du développement :

```bash
# Build incrémental (plus rapide)
flutter run -d linux

# Avec hot reload
flutter run -d linux --hot-reload
```

---

## 🧪 Tests

### Exécuter les tests

```bash
flutter test
```

### Exécuter un test spécifique

```bash
flutter test test/photo_model_test.dart
```

---

## 📦 Structure du build

```
build/
├── linux/
│   ├── deb/                    # Package .deb
│   │   └── gitphoto_studio-1.0.0+1-linux-x64.deb
│   └── x64/
│       ├── debug/
│       │   └── bundle/        # Version debug
│       └── release/
│           └── bundle/        # Version release
└── app/
    └── outputs/
        └── flutter-apk/       # APK Android
            └── app-debug.apk
```

---

## 🔧 Configuration avancée

### Personnaliser le package .deb

Vous pouvez modifier les informations du package dans `linux/runner/debian/` :

- `control` : Métadonnées du package (nom, version, description)
- `changelog` : Historique des changements
- `copyright` : Informations de copyright

### Builder avec des flags personnalisés

```bash
# Builder avec optimisation
flutter build linux --release --no-tree-shake-icon-fonts

# Builder sans compression (pour debug)
flutter build linux --release --no-compress
```

---

## 📊 Performances

| Action | Temps estimé | Espace disque |
|--------|--------------|---------------|
| Build debug | 1-3 min | ~1.5 Go |
| Build release | 3-8 min | ~2.0 Go |
| Tests | 10-30 sec | - |

**Recommandations** :
- Utiliser un SSD pour des builds plus rapides
- Avoir au moins 8 Go de RAM
- Utiliser `--release` pour les builds de production

---

## 🐛 Dépannage

### 1. Vérifier l'environnement

```bash
flutter doctor -v
```

Assurez-vous que toutes les cases sont cochées pour Linux.

### 2. Vérifier les logs de build

```bash
# Afficher les logs complets
flutter build linux -v
```

### 3. Nettoyer le build

```bash
flutter clean
flutter pub get
flutter build linux
```

### 4. Vérifier les dépendances système

```bash
# Vérifier cmake
cmake --version

# Vérifier clang++
clang++ --version

# Vérifier ninja
ninja --version
```

---

## 📚 Ressources

- [Flutter Linux Desktop Support](https://docs.flutter.dev/desktop)
- [Flutter Build Linux Docs](https://docs.flutter.dev/deployment/linux)
- [CMake Documentation](https://cmake.org/documentation/)
- [Android NDK](https://developer.android.com/ndk)

---

## 🎯 Support

Si vous rencontrez des problèmes persistants :

1. **Vérifiez `flutter doctor -v`**
2. **Consultez les logs dans `build/linux/x64/release/`**
3. **Essayez dans un conteneur Docker propre**
4. **Ouvrez une issue avec :**
   - La sortie complète de `flutter doctor -v`
   - La version de votre distribution (`lsb_release -a`)
   - Les logs de build complets

---

**✅ Dernière mise à jour : Phase 4 - Drag & Drop natif implémenté**

Le code est prêt pour le build Linux. Les problèmes éventuels sont liés à l'environnement de build, pas au code lui-même.
