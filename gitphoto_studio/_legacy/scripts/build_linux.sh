#!/bin/bash

# Script de build Linux pour GitPhoto Studio IA
# Ce script vérifie les dépendances et tente de builder l'application

set -e

echo "=========================================="
echo "GitPhoto Studio IA - Build Linux"
echo "=========================================="
echo ""

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Fonction pour vérifier une commande
test_command() {
    if command -v $1 >/dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} $1 est installé"
        return 0
    else
        echo -e "${RED}✗${NC} $1 n'est pas installé"
        return 1
    fi
}

# Fonction pour vérifier une bibliothèque
check_library() {
    if ldd /usr/bin/$1 2>/dev/null | grep -q "not found"; then
        echo -e "${RED}✗${NC} $1 a des dépendances manquantes"
        return 1
    else
        echo -e "${GREEN}✓${NC} $1 est fonctionnel"
        return 0
    fi
}

echo "Vérification des dépendances..."
echo ""

# Vérifier cmake
echo "1. Vérification de cmake..."
if test_command cmake; then
    cmake_version=$(cmake --version | head -1 | awk '{print $3}')
    echo "   Version: $cmake_version"
    
    # Vérifier que cmake est utilisable
    if cmake --version >/dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} cmake est utilisable"
    else
        echo -e "${RED}✗${NC} cmake n'est pas utilisable (erreur GLIBCXX)"
        echo "   Solution: Installez une version plus récente de cmake ou utilisez celle du SDK Android"
        exit 1
    fi
else
    echo ""
    echo -e "${YELLOW}Pour installer cmake:${NC}"
    echo "   Ubuntu/Debian: sudo apt install cmake"
    echo "   Fedora: sudo dnf install cmake"
    echo "   Arch: sudo pacman -S cmake"
    echo ""
    exit 1
fi

# Vérifier clang
echo ""
echo "2. Vérification de clang++..."
if test_command clang++; then
    clang_version=$(clang++ --version | head -1 | awk '{print $3}')
    echo "   Version: $clang_version"
    
    # Vérifier que clang++ est utilisable
    if clang++ --version >/dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} clang++ est utilisable"
    else
        echo -e "${RED}✗${NC} clang++ n'est pas utilisable (erreur GLIBCXX)"
        echo "   Solution: Installez une version plus récente de clang ou utilisez celle du SDK Android"
        exit 1
    fi
else
    echo ""
    echo -e "${YELLOW}Pour installer clang++:${NC}"
    echo "   Ubuntu/Debian: sudo apt install clang"
    echo "   Fedora: sudo dnf install clang"
    echo "   Arch: sudo pacman -S clang"
    echo ""
    exit 1
fi

# Vérifier ninja
echo ""
echo "3. Vérification de ninja..."
if test_command ninja; then
    ninja_version=$(ninja --version | head -1)
    echo "   Version: $ninja_version"
else
    echo ""
    echo -e "${YELLOW}Pour installer ninja:${NC}"
    echo "   Ubuntu/Debian: sudo apt install ninja-build"
    echo "   Fedora: sudo dnf install ninja-build"
    echo "   Arch: sudo pacman -S ninja"
    echo ""
    exit 1
fi

# Vérifier pkg-config
echo ""
echo "4. Vérification de pkg-config..."
if test_command pkg-config; then
    pkg_config_version=$(pkg-config --version | head -1)
    echo "   Version: $pkg_config_version"
else
    echo ""
    echo -e "${YELLOW}Pour installer pkg-config:${NC}"
    echo "   Ubuntu/Debian: sudo apt install pkg-config"
    echo "   Fedora: sudo dnf install pkgconfig"
    echo "   Arch: sudo pacman -S pkgconf"
    echo ""
    exit 1
fi

# Vérifier Flutter
echo ""
echo "5. Vérification de Flutter..."
if test_command flutter; then
    flutter_version=$(flutter --version | head -1)
    echo "   Version: $flutter_version"
else
    echo ""
    echo -e "${RED}Flutter n'est pas installé ou n'est pas dans le PATH${NC}"
    echo "   Solution: Suivez les instructions sur https://docs.flutter.dev/get-started/install"
    echo ""
    exit 1
fi

echo ""
echo "=========================================="
echo "Toutes les dépendances sont installées"
echo "=========================================="
echo ""

# Essayer de builder
echo "Lancement du build..."
echo ""

cd $(dirname "$0")/..

# Build en mode release
flutter build linux --release

if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}Build réussi !${NC}"
    echo ""
    echo "Le package .deb a été généré dans:"
    echo "   build/linux/deb/"
    echo ""
    echo "Pour installer:"
    echo "   sudo dpkg -i build/linux/deb/gitphoto_studio-*.deb"
else
    echo ""
    echo -e "${RED}Build échoué${NC}"
    echo ""
    echo "Si l'erreur mentionne GLIBCXX, votre système a besoin de bibliothèques plus récentes."
    echo "Solutions possibles:"
    echo ""
    echo "1. Mettre à jour votre distribution"
    echo "   sudo apt update && sudo apt upgrade"
    echo ""
    echo "2. Utiliser le cmake et clang du SDK Android"
    echo "   export PATH=\"\$ANDROID_HOME/cmake/3.22.1/bin:\$PATH\""
    echo "   export CMAKE_CXX_COMPILER=\"\$ANDROID_HOME/ndk/25.2.9519653/toolchains/llvm/prebuilt/linux-x86_64/bin/clang++\""
    echo ""
    echo "3. Utiliser un conteneur Docker avec les bonnes dépendances"
    echo "   docker run -it ubuntu:22.04"
    echo "   apt update && apt install -y cmake clang ninja-build pkg-config"
    echo ""
    exit 1
fi
