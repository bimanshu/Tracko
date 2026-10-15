#!/bin/sh
# Downloads Satoshi into the app's font folder.
#
# Satoshi comes from Fontshare under the ITF Free Font License: you may embed it in your own
# app, but not redistribute the font files, and this repository is public. So it isn't
# committed: run this once (and CI runs it before building) to fetch your own copy. The files
# are git-ignored. Without them the app still builds; Satoshi just isn't available to pick.
set -eu
cd "$(dirname "$0")/.."
DEST=Tracko/DesignSystem/Fonts
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

curl -fsSL -o "$TMP/satoshi.zip" "https://api.fontshare.com/v2/fonts/download/satoshi"
unzip -q -o "$TMP/satoshi.zip" -d "$TMP"
for weight in Regular Medium Bold Black; do
  file=$(find "$TMP" -name "Satoshi-$weight.ttf" | head -n 1)
  cp "$file" "$DEST/Satoshi-$weight.ttf"
done
cp "$(find "$TMP" -name 'FFL.txt' | head -n 1)" "$DEST/Satoshi-FFL.txt"
echo "Satoshi installed in $DEST (git-ignored)."
