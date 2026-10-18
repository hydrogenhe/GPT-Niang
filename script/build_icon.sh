#!/usr/bin/env bash
set -euo pipefail

SOURCE="${1:?Usage: build_icon.sh source.png output.icns}"
OUTPUT="${2:?Usage: build_icon.sh source.png output.icns}"
ICON_WORK="$(mktemp -d "${TMPDIR:-/tmp}/gpt-niang-icon.XXXXXX")"
trap 'rm -rf "$ICON_WORK"' EXIT
ICONSET="$ICON_WORK/AppIcon.iconset"
mkdir -p "$ICONSET"

for SIZE in 16 32 128 256 512; do
  /usr/bin/sips -z "$SIZE" "$SIZE" "$SOURCE" --out "$ICONSET/icon_${SIZE}x${SIZE}.png" >/dev/null
  DOUBLE=$((SIZE * 2))
  /usr/bin/sips -z "$DOUBLE" "$DOUBLE" "$SOURCE" --out "$ICONSET/icon_${SIZE}x${SIZE}@2x.png" >/dev/null
done
/usr/bin/iconutil -c icns "$ICONSET" -o "$OUTPUT"
