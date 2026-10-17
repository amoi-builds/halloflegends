#!/usr/bin/env bash
# Builds the game in pokeemerald-expansion/ (see scripts/get-expansion.sh).
# On macOS it uses the project-local toolchain and GNU make 4 from
# scripts/setup-macos.sh; elsewhere, the toolchain from the expansion's
# INSTALL.md (devkitARM or arm-none-eabi-gcc) and the system's make.
# Builds FireRed unless BUILD says otherwise; args are passed to make as-is.
#
#   scripts/build.sh                      # pokeemerald-expansion/pokefirered.gba
#   scripts/build.sh check                # the expansion's test suite, FireRed build
#   scripts/build.sh clean                # needed when switching games
#   BUILD=leafgreen scripts/build.sh      # pokeleafgreen.gba
#   BUILD=emerald scripts/build.sh        # pokeemerald.gba
#
# A plain FireRed build also writes the browser player's copy of the game
# (web/game/, see scripts/serve.py).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TC="$ROOT/.toolchain"
GAME_DIR="$ROOT/pokeemerald-expansion"

if [ ! -d "$GAME_DIR" ]; then
  echo "pokeemerald-expansion/ missing. Run scripts/get-expansion.sh first."; exit 1
fi

MAKE_ARGS=()
if [ -x "$TC/arm-none-eabi/bin/arm-none-eabi-gcc" ] && [ -x "$TC/make/bin/make" ]; then
  MAKE="$TC/make/bin/make"
  MAKE_ARGS+=(TOOLCHAIN="$TC/arm-none-eabi")
  # gbagfx/rsfont ask pkg-config for libpng; clang also honours these variables,
  # which lets it find our static libpng without pkg-config/Homebrew.
  export CPATH="$TC/libpng/include${CPATH:+:$CPATH}"
  export LIBRARY_PATH="$TC/libpng/lib${LIBRARY_PATH:+:$LIBRARY_PATH}"
  # A no-op pkg-config so the tool Makefiles don't print "command not found".
  export PATH="$ROOT/scripts/shims:$PATH"
elif [ "$(uname)" = Darwin ]; then
  echo "Toolchain missing. Run scripts/setup-macos.sh first."; exit 1
else
  MAKE=make
fi

JOBS="$(sysctl -n hw.ncpu 2>/dev/null || nproc)"
GAME="${BUILD:-firered}"
# The Makefile treats any value other than firered/leafgreen as Emerald.
[ "$GAME" = emerald ] && GAME=""

"$MAKE" -C "$GAME_DIR" -j"$JOBS" ${MAKE_ARGS[@]+"${MAKE_ARGS[@]}"} BUILD="$GAME" "$@"

if [ "$#" -eq 0 ] && [ "$GAME" = firered ]; then
  # The browser player downloads a gzipped copy (32 MB -> about a third, the
  # rest of the cartridge is padding) and unpacks it in the browser.
  mkdir -p "$ROOT/web/game"
  gzip -9 -n -c "$GAME_DIR/pokefirered.gba" > "$ROOT/web/game/halloflegends.gba.gz"
  echo
  echo "Built pokeemerald-expansion/pokefirered.gba"
  [ -n "${HOL_PLAY:-}" ] || echo "Browser copy: web/game/halloflegends.gba.gz (play it with scripts/serve.py)"
fi
