# Being As An Ocean

The working title is **PROJECT CUB**. It's a third-person action-adventure about parkour, skateboarding and music, following Cub from age 16 to the stage. It's built in Godot 4 and Blender.

**Current phase:** Phase 1, the movement prototype ("Graybox Block"). A placeholder mannequin Cub (Quaternius, CC0) runs, jumps, vaults and climbs on a graybox test course. Third-party assets are listed in [CREDITS.md](CREDITS.md).

## Requirements

| Tool | Version | Notes |
|---|---|---|
| Godot | **4.7.2 stable** (standard, not .NET) | Pinned in [DECISIONS.md](docs/DECISIONS.md) D-002 |
| Blender | **4.5 LTS** | Only needed to regenerate levels |
| Git LFS | any | `brew install git-lfs && git lfs install`. Large binaries such as `.glb`, `.blend` and audio are stored in LFS. |

## Run the game

1. `git clone https://github.com/bus2moon/beingasanocean && cd beingasanocean && git lfs pull`
2. Open Godot 4.7.2. Choose **Import**, select `project.godot`, then click **Import & Edit**.
3. Press **F5**, the Run Project button. This opens `scenes/main.tscn`.

From the terminal (macOS):
```sh
/Applications/Godot.app/Contents/MacOS/Godot --path .
```

## Controls

| Action | Keyboard / mouse | Controller (Xbox layout) |
|---|---|---|
| Move | WASD | Left stick (a light push walks) |
| Camera | Mouse | Right stick |
| Sprint | Shift (hold) | RB (hold) |
| Jump / vault / climb | Space (hold for a higher jump) | A |
| Debug readout | F3 | Back / View |
| Release mouse | Esc (click to recapture) | Start |

How movement works:
- Press jump facing a low wall to vault it, a waist-high block to step up onto it, or a ledge up to 2.3 m high to climb it.
- Sprinting into anything low vaults it automatically.
- Jumping at a ledge in mid-air grabs it if it's within 1.4 m of your feet.

## The test course (Graybox Block)

Lanes run away from the spawn point along -Z:

| Lane | x | What's there |
|---|---|---|
| A | -12 | Yellow vault walls: 0.5 / 0.8 / 1.1 m |
| B | -6 | Blue blocks: 1.0 (step up), 1.5 / 2.0 / 2.3 (climb). Red 2.8 m block (out of reach on purpose) |
| C | 0 | Ramp up to a gap course at 1.5 m, gaps of 1 to 5 m |
| D | 9 / 14 | Stairs to a 2 m deck, a 4 m and 6 m tower (for testing hard landings), a 15° slope |
| E | 24 | Crate stack up to a rooftop row: gaps of 2.5 / 3.0 / 3.5 m, a vent and an AC unit |

To regenerate the level after editing the generator:
```sh
/Applications/Blender.app/Contents/MacOS/Blender --background --factory-startup \
  --python tools/blender/gen_graybox_block.py -- assets/levels/graybox_block.glb
```

## Tests

```sh
./tools/run_tests.sh          # headless; exit code 0 = all movement tests pass
```
If Godot isn't in `/Applications` or `~/Downloads`, run `GODOT=/path/to/Godot ./tools/run_tests.sh` instead.

The tests prove the behaviour: state changes, heights, speeds, and that the level has collision. They can't prove how it *feels*. That needs someone to play it.

A windowed smoke run that logs FPS and saves a screenshot to Godot's user data folder:
```sh
/Applications/Godot.app/Contents/MacOS/Godot --path . res://tests/capture.tscn
```

## Project map

```
scripts/core/      Settings (input bindings) autoload, main scene script
scripts/player/    Player body, TraversalMetrics, TraversalSensors, InputBuffer, StateMachine
scripts/player/states/   Idle Move Jump Fall Land Vault Climb
scripts/camera/    CameraRig
scenes/            main.tscn, player/, levels/
assets/levels/     Generated GLBs (Git LFS)
tools/blender/     Blender Python generators
tests/             Headless test runner, windowed capture
docs/              Design, architecture, asset guide, bibles, roadmap, backlog, decisions, devlog
```

Start with [docs/DEVLOG.md](docs/DEVLOG.md). It records where the last session stopped and what comes next.
