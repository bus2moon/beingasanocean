# Dev Log

## 2026-10-20 — Session 1: Phase 0 and Phase 1 prototype

**Done**
- Repo scaffold, Git LFS rules, and the docs set.
- Player controller states: Idle, Move, Jump, Fall, Land, Vault (including step-up), Climb (standing and mid-air grab). Also coyote time, jump buffer, and a variable jump.
- Camera rig, debug HUD (F3), and keyboard and controller bindings.
- `tools/blender/gen_graybox_block.py` generates `assets/levels/graybox_block.glb` with lanes A–E.
- 17 headless tests (36 checks), all passing. Windowed capture: 60 FPS min/median on the M1.

- Swapped the capsule for the Quaternius UAL mannequin (CC0). AnimationController picks idle, walk, jog and sprint by speed, and uses jump and land clips. 18 tests, 40 checks, all passing; still 60 FPS.
- Pushed to github.com/bus2moon/beingasanocean (main + dev). This repo uses gh credentials (`credential.helper = !gh auth git-credential`) because the macOS keychain has an old login saved.

**Not verified**
- Feel. Nobody has played it with a controller or keyboard yet.

**Next**
1. Creator playtest, then tune the numbers.
2. The creator answers the NARRATIVE_BIBLE questions.
3. Start Phase 2: wall-run and the landing roll first.
