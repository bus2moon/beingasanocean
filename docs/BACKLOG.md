# Backlog

## Phase 1 (finish)
- [ ] Creator playtest pass, then tune `TraversalMetrics` from the feedback
- [ ] Step-up for curbs below 0.4 m, so there's no need for ramp collision on every curb
- [ ] Sweep Vault and Climb paths for collisions (they currently place the body directly)
- [ ] Blender asset validator (scale applied, naming, polygon budget) in `tools/blender/`
- [ ] Settings menu with rebinding and sensitivity; save to `user://settings.cfg`

## Animation
- [ ] Vault and climb clips. Quaternius UAL 2 has parkour clips (its free Standard version is on itch.io and has to be downloaded in a browser). Vault and Climb play the air loop until then.
- [ ] Tune `AnimationController.GAITS` reference speeds to cut down foot sliding
- [ ] Use `Roll` for the Phase 2 landing roll

## Phase 2
- [ ] Wall-run, wall-jump, slide, timed landing roll (cancels Land), ledge hang and shimmy, balance beam, pipe and rail traversal
- [ ] Rooftop obstacle course level
- [ ] Debug ghost: record and replay a run to compare tuning changes

## Later
- [ ] Animation controller (AnimationTree) once the Cub rig exists
- [ ] `Events`, `GameState`, `SaveManager`, `AudioManager` autoloads
- [ ] `SongDef` resource and an adaptive stem player for Lines

## Known bugs
- (none logged yet)
