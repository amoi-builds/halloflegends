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

## Building

This repository only holds Hall of Legends' own changes, as a patch to
[pokeemerald-expansion](https://github.com/rh-hideout/pokeemerald-expansion).
The scripts download the expansion at a pinned commit, apply the patch, and
build the game. No ROM is needed: the whole game builds from source.

**macOS** (no Homebrew or devkitARM needed; git, Python 3 and the Xcode
Command Line Tools must be installed):

```sh
scripts/setup-macos.sh    # one time: ARM compiler, libpng, GNU make into .toolchain/ (~1 GB)
scripts/get-expansion.sh  # pokeemerald-expansion at the pinned commit + the patch
scripts/build.sh          # builds pokeemerald-expansion/pokefirered.gba
```

**Linux / Windows (WSL)**: install the toolchain as described in the
expansion's [INSTALL.md](https://github.com/rh-hideout/pokeemerald-expansion/blob/master/INSTALL.md),
then:

```sh
scripts/get-expansion.sh
make -C pokeemerald-expansion firered
```

Open `pokeemerald-expansion/pokefirered.gba` in mGBA or any GBA emulator.

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

## Disclaimer

This is a non-commercial fan project and is not affiliated with Nintendo,
Game Freak or The Pokémon Company. Pokémon and all related names and
characters are trademarks of their respective owners. This repository
doesn't include pokeemerald-expansion, pret's decompilations or a built ROM.
