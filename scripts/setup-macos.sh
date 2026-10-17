#!/usr/bin/env bash
# Installs everything needed to build the ROM on macOS, into ./.toolchain
# (no sudo, no Homebrew, no devkitARM, nothing written outside this project):
#
#   - xPack GNU Arm Embedded GCC (arm-none-eabi-gcc + binutils + newlib),
#     passed to the expansion's Makefile via TOOLCHAIN=...
#     (Arm's own macOS x86_64 tarballs link cc1 against Homebrew's zstd and
#     crash without it; the xPack builds are self-contained.)
#   - libpng (static), needed by tools/gbagfx and tools/rsfont
#   - GNU make 4.4 (macOS's /usr/bin/make 3.81 is too old for the Makefile)
#
# Python 3 and the Xcode Command Line Tools must already be installed.
# Re-running is safe: finished steps are skipped.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TC="$ROOT/.toolchain"
mkdir -p "$TC/downloads"

GCC_VER="14.2.1-1.1"
LIBPNG_VER="1.6.44"
MAKE_VER="4.4.1"
MAKE_SHA256="dd16fb1d67bfab79a72f5e8390735c49e3e8e70b4945a15ab1f81ddb78658fb3"

case "$(uname -m)" in
  x86_64) GCC_HOST="darwin-x64" ;;
  arm64)  GCC_HOST="darwin-arm64" ;;
  *) echo "Unsupported CPU: $(uname -m)"; exit 1 ;;
esac

if ! xcode-select -p >/dev/null 2>&1; then
  echo "Xcode Command Line Tools are required. Run: xcode-select --install"
  exit 1
fi
if ! command -v python3 >/dev/null 2>&1; then
  echo "python3 is required (the build runs Python scripts). Get it from python.org."
  exit 1
fi

# --- arm-none-eabi GCC --------------------------------------------------------
GCC_NAME="xpack-arm-none-eabi-gcc-$GCC_VER"
if [ ! -x "$TC/arm-none-eabi/bin/arm-none-eabi-gcc" ]; then
  tarball="$GCC_NAME-$GCC_HOST.tar.gz"
  url="https://github.com/xpack-dev-tools/arm-none-eabi-gcc-xpack/releases/download/v$GCC_VER/$tarball"
  echo ">> Downloading $tarball"
  curl -fL --retry 3 -o "$TC/downloads/$tarball" "$url"
  curl -fsL -o "$TC/downloads/$tarball.sha" "$url.sha"
  expected="$(awk '{print $1}' "$TC/downloads/$tarball.sha")"
  actual="$(shasum -a 256 "$TC/downloads/$tarball" | awk '{print $1}')"
  [ "$expected" = "$actual" ] || { echo "Checksum mismatch for $tarball"; exit 1; }
  echo ">> Checksum OK, extracting"
  tar -xzf "$TC/downloads/$tarball" -C "$TC"
  rm -f "$TC/arm-none-eabi"
  ln -s "$GCC_NAME" "$TC/arm-none-eabi"
  rm -f "$TC/downloads/$tarball"
fi
"$TC/arm-none-eabi/bin/arm-none-eabi-gcc" --version | head -1
# Fail early if the compiler can't actually run (e.g. missing dylibs).
echo 'int f(void){return 0;}' | "$TC/arm-none-eabi/bin/arm-none-eabi-gcc" -x c -c -o /dev/null -

# --- libpng (static, built with the system clang) ----------------------------
if [ ! -f "$TC/libpng/lib/libpng.a" ]; then
  echo ">> Building libpng $LIBPNG_VER"
  src="$TC/downloads/libpng-$LIBPNG_VER"
  rm -rf "$src"
  curl -fL --retry 3 -o "$src.tar.gz" \
    "https://github.com/pnggroup/libpng/archive/refs/tags/v$LIBPNG_VER.tar.gz"
  tar -xzf "$src.tar.gz" -C "$TC/downloads"
  cp "$src/scripts/pnglibconf.h.prebuilt" "$src/pnglibconf.h"
  mkdir -p "$TC/libpng/include" "$TC/libpng/lib" "$src/obj"
  # Disable the optional SIMD paths so no extra arch-specific sources are needed.
  for f in png pngerror pngget pngmem pngpread pngread pngrio pngrtran pngrutil \
           pngset pngtrans pngwio pngwrite pngwtran pngwutil; do
    cc -O2 -DPNG_ARM_NEON_OPT=0 -DPNG_INTEL_SSE_OPT=0 -I"$src" \
       -c "$src/$f.c" -o "$src/obj/$f.o"
  done
  ar rcs "$TC/libpng/lib/libpng.a" "$src"/obj/*.o
  cp "$src/png.h" "$src/pngconf.h" "$src/pnglibconf.h" "$TC/libpng/include/"
fi
echo ">> libpng: $TC/libpng/lib/libpng.a"

# --- GNU make 4.x ------------------------------------------------------------
# macOS ships make 3.81, whose $(shell) sub-makes don't see command-line
# variables and which lacks .SHELLSTATUS: the Makefile's generate step then
# builds the wrong game and its failures go unnoticed.
if [ ! -x "$TC/make/bin/make" ]; then
  echo ">> Building GNU make $MAKE_VER"
  src="$TC/downloads/make-$MAKE_VER"
  rm -rf "$src"
  curl -fL --retry 3 -o "$src.tar.gz" "https://ftp.gnu.org/gnu/make/make-$MAKE_VER.tar.gz"
  actual="$(shasum -a 256 "$src.tar.gz" | awk '{print $1}')"
  [ "$MAKE_SHA256" = "$actual" ] || { echo "Checksum mismatch for make-$MAKE_VER"; exit 1; }
  tar -xzf "$src.tar.gz" -C "$TC/downloads"
  # Its compiler warnings are harmless; keep them in a log unless the build fails.
  (cd "$src" && ./configure --prefix="$TC/make" --disable-nls && ./build.sh) > "$src.log" 2>&1 ||
    { tail -20 "$src.log"; echo "Building GNU make failed (full log: $src.log)"; exit 1; }
  mkdir -p "$TC/make/bin"
  cp "$src/make" "$TC/make/bin/make"
fi
"$TC/make/bin/make" --version | head -1

if [ -z "${HOL_PLAY:-}" ]; then  # scripts/play.sh goes on by itself
  echo
  echo "Toolchain ready. Next: scripts/get-expansion.sh, then scripts/build.sh"
  echo "(or just scripts/play.sh, which does every step and opens the game)."
fi
