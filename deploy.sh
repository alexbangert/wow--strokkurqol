#!/usr/bin/env bash
# Kopiert das Addon in die WoW-Installation.
#   ./deploy.sh              -> _forever_
#   ./deploy.sh _classic_era_  (oder _retail_, _classic_, _ptr_, ...)
# WoW-Pfad per WOW_DIR überschreibbar.
set -euo pipefail

ADDON="StrokkurQoL"
FLAVOR="${1:-_forever_}"
WOW_DIR="${WOW_DIR:-/home/alex/Faugus/battlenet/drive_c/Program Files (x86)/World of Warcraft}"

SRC="$(cd "$(dirname "$0")" && pwd)/src/$ADDON/"
DEST="$WOW_DIR/$FLAVOR/Interface/AddOns/$ADDON/"

if [[ ! -d "$WOW_DIR/$FLAVOR" ]]; then
    echo "Fehler: '$WOW_DIR/$FLAVOR' existiert nicht." >&2
    exit 1
fi

mkdir -p "$DEST"
rsync -a --delete --exclude='.*' "$SRC" "$DEST"
echo "Deployed $ADDON -> $DEST"
echo "Im Spiel: /reload (bei neuen Dateien oder TOC-Änderungen: Neustart des Spiels)"
