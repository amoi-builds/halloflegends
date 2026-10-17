#!/usr/bin/env bash
# Recreates pokeemerald-expansion/ from scratch: fetches RHH's
# pokeemerald-expansion at the pinned commit and applies the Hall of Legends
# changes from patches/.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GAME_DIR="$ROOT/pokeemerald-expansion"
PATCH="$ROOT/patches/hall-of-legends.patch"
RHH_URL="https://github.com/rh-hideout/pokeemerald-expansion.git"
RHH_COMMIT="8fb02c6f2b81271e795d3f6aca61733fec739016"

if [ -e "$GAME_DIR" ]; then
  echo "pokeemerald-expansion/ already exists. Delete it first to start from a fresh copy."
  exit 1
fi

git init -q "$GAME_DIR"
git -C "$GAME_DIR" remote add RHH "$RHH_URL"
echo ">> Fetching pokeemerald-expansion @ ${RHH_COMMIT:0:10}"
git -C "$GAME_DIR" fetch -q --depth 1 RHH "$RHH_COMMIT"
git -C "$GAME_DIR" checkout -q FETCH_HEAD
echo ">> Applying $(basename "$PATCH")"
git -C "$GAME_DIR" apply --whitespace=nowarn "$PATCH"
echo "Done. Build with: scripts/build.sh"
