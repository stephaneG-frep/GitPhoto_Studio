#!/usr/bin/env bash
# Archive ZIP du code source (fichiers suivis ou non ignorés par Git), sans
# sorties de compilation, ancien code (_legacy) ni livrables.
#   bash scripts/build_source_zip.sh  → dist/gitphoto-studio-<version>-source.zip
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
VERSION="$(sed -n 's/^version: \([0-9.]*\)+.*/\1/p' pubspec.yaml)"
OUT="$ROOT/dist/gitphoto-studio-${VERSION}-source.zip"
mkdir -p dist
rm -f "$OUT"

git ls-files --cached --others --exclude-standard -z \
  | tr '\0' '\n' \
  | grep -vE '^(_legacy/|android/build/|dist/|build/|coverage/|tool/icon/out/)' \
  | grep -vE '(^|/)(key\.properties|local\.properties|.*\.(jks|keystore|p12|pem))$' \
  | while IFS= read -r f; do [ -f "$f" ] && printf '%s\n' "$f"; done \
  | sed 's#^#gitphoto_studio/#' > dist/.zip-list

(cd .. && zip -q -X "$OUT" -@ < gitphoto_studio/dist/.zip-list)
rm dist/.zip-list
echo "$OUT"
