# Hall of Legends

A Pokémon FireRed ROM hack where you pick a trainer from across the first four
generations and battle the others in the Pokémon League.

There is no story: the game starts on a character select screen. Choose a
battle style, your trainer(s) and your opponent(s), and go.

## Features

- **13 trainers**: Red, Blue, Giovanni, Lance, Ethan, Silver, Steven, May,
  Wallace, Wally, Cynthia, Dawn and Barry, each with a level 100 team.
- **Three battle styles**: singles, doubles, and tag battles (two trainers a
  side, three Pokémon each).
- **Opponents**: pick one, go random, or take on the **Elite Four**: five
  random trainers in a row, from Lorelei's room to the Champion's room and
  the Hall of Fame.
- Smart opponent AI that predicts your moves.
- Pokémon from Generations 1–4 with Generation 4 battle mechanics.
- No money, no bag: only a small healing kit during Elite Four runs.

## Play

On a Mac with git, Python 3 and the Xcode Command Line Tools
(`xcode-select --install`):

```sh
git clone https://github.com/amoi-builds/halloflegends.git
cd halloflegends
scripts/play.sh
```

The first run downloads the tools and builds the game on your computer
(about 1 GB and 5–10 minutes), then opens it in your browser at
http://localhost:8080. After that, `scripts/play.sh` starts in seconds.
Nothing is hosted online: the game runs in your browser, served from your own
computer, on the mGBA emulator.

**Controls:** arrow keys, <kbd>X</kbd> = A, <kbd>Z</kbd> = B,
<kbd>Enter</kbd> = Start, <kbd>Right Shift</kbd> = Select (the credits, on the
battle style screen). On a phone or tablet, use the on-screen buttons.

**Linux / Windows (WSL):** install the toolchain as described in the
expansion's [INSTALL.md](https://github.com/rh-hideout/pokeemerald-expansion/blob/master/INSTALL.md)
(devkitARM or `arm-none-eabi-gcc`, plus `libpng`), then run `scripts/play.sh`.

**Prefer a desktop emulator?** The built game is
`pokeemerald-expansion/pokefirered.gba`; open it in mGBA or any GBA emulator.

## How it works

This repository only holds Hall of Legends' own changes, as a patch to
[pokeemerald-expansion](https://github.com/rh-hideout/pokeemerald-expansion),
plus the browser player in `web/`. `scripts/play.sh` runs these steps, which
also work one by one:

```sh
scripts/setup-macos.sh    # macOS only: ARM compiler, libpng, GNU make into .toolchain/
scripts/get-expansion.sh  # pokeemerald-expansion at the pinned commit + the patch
scripts/build.sh          # builds pokeemerald-expansion/pokefirered.gba (+ web/game/)
scripts/fetch-vendor.sh   # the browser emulator (Nostalgist + mGBA) into web/vendor/
scripts/serve.py          # serves web/ at http://localhost:8080 and opens it
```

No ROM is needed: the whole game builds from source.

### Making changes

Edit the game inside `pokeemerald-expansion/` (a regular git checkout of the
expansion), then run `scripts/save-patch.sh` to write every change to
`patches/hall-of-legends.patch` and commit that.
`pokeemerald-expansion/` itself isn't tracked by this repository.

## Credits

- Based on RHH's [pokeemerald-expansion](https://github.com/rh-hideout/pokeemerald-expansion)
  (commit `8fb02c6`, after 1.17.1), which is built on
  [pret](https://github.com/pret)'s pokeemerald and pokefirered
  decompilations. See its [CREDITS.md](https://github.com/rh-hideout/pokeemerald-expansion/blob/master/CREDITS.md)
  for all contributors.
- Trainer sprites from [The Spriters Resource](https://www.spriters-resource.com/):
  - Ethan: FourLeafSunny
  - Cynthia: lichen
  - Silver: Nx-Kun, mufasakong, Dragoon
  - Dawn: Kaori
  - Barry: Gridiron, Eevee, Zhen Lin, pika, Pipian
- Browser player: [Nostalgist.js](https://github.com/arianrhodsandlot/nostalgist)
  and [mGBA](https://github.com/mgba-emu/mgba)'s libretro core; see
  [web/licenses.txt](web/licenses.txt).

## Disclaimer

This is a non-commercial fan project and is not affiliated with Nintendo,
Game Freak or The Pokémon Company. Pokémon and all related names and
characters are trademarks of their respective owners. This repository
doesn't include pokeemerald-expansion, pret's decompilations or a built ROM:
the scripts download the source and build the game on your computer.
