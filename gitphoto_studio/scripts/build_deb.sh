#!/usr/bin/env bash
# Construit le paquet Debian de GitPhoto Studio IA à partir de la version
# Linux compilée (flutter build linux --release).
#   bash scripts/build_deb.sh            → dist/gitphoto-studio_<version>_amd64.deb
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

PKG=gitphoto-studio
VERSION="$(sed -n 's/^version: \([0-9.]*\)+.*/\1/p' pubspec.yaml)"
ARCH=amd64
BUNDLE=build/linux/x64/release/bundle
STAGE="build/deb/${PKG}_${VERSION}_${ARCH}"
OUT=dist

[ -x "$BUNDLE/gitphoto_studio" ] || {
  echo "Version Linux absente : lancez d'abord « flutter build linux --release »." >&2
  exit 1
}

rm -rf "$STAGE"
mkdir -p "$STAGE/DEBIAN" "$STAGE/opt/$PKG" "$STAGE/usr/bin" \
  "$STAGE/usr/share/applications" "$STAGE/usr/share/doc/$PKG"

# Application complète (exécutable, bibliothèques, ressources).
cp -a "$BUNDLE/." "$STAGE/opt/$PKG/"
ln -s "../../opt/$PKG/gitphoto_studio" "$STAGE/usr/bin/$PKG"

# Menu des applications et icônes.
install -m 644 linux/packaging/com.nabu.gitphoto.gitphoto_studio.desktop \
  "$STAGE/usr/share/applications/"
for dir in linux/packaging/icons/*x*; do
  size="$(basename "$dir")"
  install -D -m 644 "$dir/$PKG.png" \
    "$STAGE/usr/share/icons/hicolor/$size/apps/$PKG.png"
done

# Documentation et licence.
install -m 644 LICENSE "$STAGE/usr/share/doc/$PKG/copyright"
install -m 644 docs/GUIDE_INSTALLATION.md docs/MODE_EMPLOI.md \
  "$STAGE/usr/share/doc/$PKG/"

# Droits normalisés : dossiers et exécutables 755, fichiers 644.
find "$STAGE" -type d -exec chmod 755 {} +
find "$STAGE" -type f -exec chmod 644 {} +
chmod 755 "$STAGE/opt/$PKG/gitphoto_studio"

SIZE="$(du -sk --exclude=DEBIAN "$STAGE" | cut -f1)"
cat > "$STAGE/DEBIAN/control" <<CONTROL
Package: $PKG
Version: $VERSION
Section: graphics
Priority: optional
Architecture: $ARCH
Installed-Size: $SIZE
Maintainer: stephaneG-frep <https://github.com/stephaneG-frep>
Homepage: https://github.com/stephaneG-frep/GitPhoto_Studio
Depends: libc6 (>= 2.34), libgtk-3-0, libglib2.0-0, libepoxy0, libsecret-1-0, libstdc++6
Recommends: gnome-keyring | kwalletmanager, xdg-utils
Suggests: ffmpeg, git
Description: Atelier photo et vidéo connecté à GitHub, avec agent IA
 GitPhoto Studio IA organise, optimise et publie des photos et des vidéos
 dans des dépôts GitHub sans manipuler Git : file d'attente avec reprise,
 Git LFS pour les gros fichiers, agent IA facultatif (Mistral prioritaire)
 qui propose des plans confirmés par l'utilisateur.
 .
 Le jeton GitHub et les clés d'IA sont gardés dans le trousseau du système
 (libsecret : GNOME Keyring ou KWallet). ffmpeg active la conversion vidéo.
CONTROL

mkdir -p "$OUT"
dpkg-deb --root-owner-group --build "$STAGE" "$OUT/${PKG}_${VERSION}_${ARCH}.deb"
