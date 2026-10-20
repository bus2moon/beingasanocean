# Technical Architecture

**Engine:** Godot 4.7.2 stable
- Renderer: Forward+ (Metal on macOS)
- Physics: **Jolt** (`physics/3d/physics_engine="Jolt Physics"`), ticking at 60 Hz
- Language: GDScript with static typing

## Player
```
Player (CharacterBody3D, layer 2, mask 1)      scripts/player/player.gd
├── CollisionShape3D   capsule r0.3 h1.75, feet at origin
├── Visual             placeholder mesh; rotated to `facing`
├── StateMachine       scripts/player/state_machine.gd
│   ├── Idle, Move     extend GroundState (states/ground_state.gd)
│   ├── Jump, Fall     extend AirState    (states/air_state.gd)
│   ├── Land           hard-landing recovery
│   └── Vault, Climb   scripted traversal arcs
└── CameraRig          top_level orbit camera (scripts/camera/camera_rig.gd)
```

### Rules
- **Intent in, movement out.** `Player` turns device input into a `PlayerIntent` once per physics tick. States read only the intent. Tests, cutscenes and AI set `player.scripted_intent`.
- **The motor helpers live on `Player`:** `ground_move`, `air_move`, `apply_gravity`, `face_toward`. States decide *when* to use them and which state comes next.
- **Code drives movement; animation follows.** In Phase 4, the AnimationController will read the state and speed. It never moves the body. Root motion is allowed only inside scripted moves such as Vault and Climb.
- **`TraversalMetrics` (a Resource) is the movement contract.** Level geometry is built to its numbers. If you change a number, log it in DECISIONS.md.
- **`TraversalSensors` is pure physics queries.** It returns a `Ledge` with a kind (VAULT, STEP_UP or CLIMB) plus the edge and end points.
- **`InputBuffer`** holds jump presses for `jump_buffer_time`. `coyote_open` allows a jump for `coyote_time` after walking off an edge.

## Collision layers
| Layer | Use |
|---|---|
| 1 | World (static level geometry) |
| 2 | Player |

## Autoloads
- `Settings`: default input bindings, kept in code so they can be diffed and rebound. It also holds mouse and stick sensitivity.
- Planned: `Events` (signal bus), `GameState`, `SaveManager`, `AudioManager`.

## Testing
- `tools/run_tests.sh` imports the project, then runs `tests/test_runner.tscn` headless with `--fixed-fps 60`. That makes the physics deterministic and faster than real time. The exit code is the result.
- Each test builds its own arena of boxes, so tests don't break when the level changes. One test loads the real level to check collision import and climb it.
- `tests/capture.tscn` is a windowed smoke run that logs FPS and saves a screenshot.

## Known limits (see BACKLOG.md)
- There's no automatic step-up for curbs below 0.4 m. Stairs use invisible ramp collision (`-colonly`).
- Vault and Climb place the body directly along a path and don't sweep for collisions. The sensors check that the end point is clear before the move starts.
