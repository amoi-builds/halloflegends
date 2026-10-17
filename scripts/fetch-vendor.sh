#!/usr/bin/env bash
# Downloads the browser player's third-party files into web/vendor/ so the
# page needs nothing from the internet while you play. Versions and checksums
# are pinned.
#
#   - Nostalgist.js (MIT): small JS API around RetroArch's Emscripten build
#   - mGBA libretro core compiled to WebAssembly (GPL-3.0 / MPL-2.0),
#     from https://github.com/arianrhodsandlot/retroarch-emscripten-build
#   - Pixelify Sans, latin subset (SIL Open Font License 1.1)
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VENDOR="$ROOT/web/vendor"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

NOSTALGIST_VER="0.22.0"
NOSTALGIST_SHA="e0bb4a7c0adefd4399034c4931dcc13720ff87aaedd6e1f20d88db3564da5876"
CORE_REL="v1.22.2"
CORE_SHA="d195371c3ea626c9246e9d3ab82ded4d93f3f99f85634af1588724cc44d47644"
FONT_URL="https://fonts.gstatic.com/s/pixelifysans/v3/CHylV-3HFUT7aC4iv1TxGDR9Jn0Ei0tSaJ0.woff2"
FONT_SHA="0f2216c1b7bf13b775e7b825c15e1c8414f3899cbd4120f275cdc96001a053a0"
FONT_LICENSE_URL="https://raw.githubusercontent.com/google/fonts/main/ofl/pixelifysans/OFL.txt"

sha256() { if command -v shasum >/dev/null 2>&1; then shasum -a 256 "$1"; else sha256sum "$1"; fi | awk '{print $1}'; }

check() { # file sha
  local actual
  actual="$(sha256 "$1")"
  [ "$actual" = "$2" ] || { echo "Checksum mismatch: $1 ($actual)"; exit 1; }
}

mkdir -p "$VENDOR"

echo ">> Nostalgist $NOSTALGIST_VER"
curl -fsSL -o "$TMP/nostalgist.tgz" "https://registry.npmjs.org/nostalgist/-/nostalgist-$NOSTALGIST_VER.tgz"
check "$TMP/nostalgist.tgz" "$NOSTALGIST_SHA"
tar -xzf "$TMP/nostalgist.tgz" -C "$TMP"
cp "$TMP/package/dist/nostalgist.js" "$VENDOR/nostalgist.js"
cp "$TMP/package/license" "$VENDOR/nostalgist.LICENSE.txt"

echo ">> mGBA core ($CORE_REL)"
curl -fsSL -o "$TMP/mgba.zip" \
  "https://cdn.jsdelivr.net/gh/arianrhodsandlot/retroarch-emscripten-build@$CORE_REL/retroarch/mgba_libretro.zip"
check "$TMP/mgba.zip" "$CORE_SHA"
unzip -oq "$TMP/mgba.zip" -d "$VENDOR"

echo ">> Pixelify Sans"
curl -fsSL -o "$TMP/font.woff2" "$FONT_URL"
check "$TMP/font.woff2" "$FONT_SHA"
cp "$TMP/font.woff2" "$VENDOR/pixelify-sans.woff2"
curl -fsSL -o "$VENDOR/pixelify-sans.OFL.txt" "$FONT_LICENSE_URL"

echo ">> Emulator files ready in web/vendor/"
