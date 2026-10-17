#!/usr/bin/env bash
# Saves every change made inside pokeemerald-expansion/ (edited and new files)
# to patches/hall-of-legends.patch. Run it after editing the game and commit
# the patch: pokeemerald-expansion/ itself isn't tracked by this repository.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GAME_DIR="$ROOT/pokeemerald-expansion"
BASE="$(sed -n 's/^RHH_COMMIT="\(.*\)"$/\1/p' "$ROOT/scripts/get-expansion.sh")"

mkdir -p "$ROOT/patches"
# Mark new files as "intent to add" so they appear in the diff (ignored build
# outputs stay out, thanks to the expansion's own .gitignore).
git -C "$GAME_DIR" add --intent-to-add .
git -C "$GAME_DIR" diff --binary "$BASE" > "$ROOT/patches/hall-of-legends.patch"
git -C "$GAME_DIR" diff --stat "$BASE" | tail -1
echo "Saved patches/hall-of-legends.patch"
