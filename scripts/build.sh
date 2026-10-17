#!/usr/bin/env bash
# Builds the game in pokeemerald-expansion/ (see scripts/get-expansion.sh)
# with the project-local toolchain and GNU make 4 (see scripts/setup-macos.sh).
# Builds FireRed unless BUILD says otherwise; args are passed to make as-is.
#
#   scripts/build.sh                      # pokeemerald-expansion/pokefirered.gba
#   scripts/build.sh check                # the expansion's test suite, FireRed build
#   scripts/build.sh clean                # needed when switching games
#   BUILD=leafgreen scripts/build.sh      # pokeleafgreen.gba
#   BUILD=emerald scripts/build.sh        # pokeemerald.gba
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TC="$ROOT/.toolchain"
GAME_DIR="$ROOT/pokeemerald-expansion"

if [ ! -x "$TC/arm-none-eabi/bin/arm-none-eabi-gcc" ] || [ ! -x "$TC/make/bin/make" ]; then
  echo "Toolchain missing. Run scripts/setup-macos.sh first."; exit 1
fi
if [ ! -d "$GAME_DIR" ]; then
  echo "pokeemerald-expansion/ missing. Run scripts/get-expansion.sh first."; exit 1
fi

# gbagfx/rsfont ask pkg-config for libpng; clang also honours these variables,
# which lets it find our static libpng without pkg-config/Homebrew.
export CPATH="$TC/libpng/include${CPATH:+:$CPATH}"
export LIBRARY_PATH="$TC/libpng/lib${LIBRARY_PATH:+:$LIBRARY_PATH}"
# A no-op pkg-config so the tool Makefiles don't print "command not found".
export PATH="$ROOT/scripts/shims:$PATH"

JOBS="$(sysctl -n hw.ncpu 2>/dev/null || nproc)"
GAME="${BUILD:-firered}"
# The Makefile treats any value other than firered/leafgreen as Emerald.
[ "$GAME" = emerald ] && GAME=""

"$TC/make/bin/make" -C "$GAME_DIR" -j"$JOBS" TOOLCHAIN="$TC/arm-none-eabi" BUILD="$GAME" "$@"
