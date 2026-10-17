#!/usr/bin/env bash
# From a fresh clone to playing in your browser in one command: sets up
# whatever is missing (toolchain on macOS, pokeemerald-expansion + the patch,
# the emulator files), builds the game and opens it at http://localhost:8080.
# Later runs skip the finished steps and only rebuild what changed.
#
#   scripts/play.sh [port] [--no-open]
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

if [ "$(uname)" = Darwin ] && { [ ! -x .toolchain/arm-none-eabi/bin/arm-none-eabi-gcc ] ||
    [ ! -x .toolchain/make/bin/make ] || [ ! -f .toolchain/libpng/lib/libpng.a ]; }; then
  scripts/setup-macos.sh
fi
[ -d pokeemerald-expansion ] || scripts/get-expansion.sh
scripts/build.sh
if [ ! -f web/vendor/nostalgist.js ] || [ ! -f web/vendor/mgba_libretro.wasm ]; then
  scripts/fetch-vendor.sh
fi
echo
exec python3 scripts/serve.py "$@"
