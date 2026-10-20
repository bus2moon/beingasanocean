# Asset Production Guide

## Units and axes
- 1 Blender unit = 1 metre. Apply scale before export.
- Blender is Z-up; the glTF exporter converts to Godot's Y-up. Characters face **-Y in Blender**, which becomes **-Z in Godot**.
- Interchange format is **GLB** (glTF 2.0), stored in Git LFS.

## Naming
| Prefix | Meaning |
|---|---|
| `SM_` | static mesh data |
| `SK_` | skinned mesh |
| `ANIM_` | animation action (snake_case verb: `ANIM_vault_low`) |
| `M_` | material |

Godot import hints go on **object** names:
- `Name-col`: mesh plus static trimesh collision
- `Name-colonly`: collision only, nothing visible
- `Name-convcol`: convex collision, for props

## Traversal metrics (build levels to these)
These come from `scripts/player/traversal_metrics.gd`.

| Feature | Size |
|---|---|
| Free step (no input) | under 0.35 m. Anything taller and blocking needs ramp collision (see Known limits). |
| Vault over (thin, under 1.2 m deep) | 0.4 – 1.15 m high |
| Step-up vault (deep top) | 0.4 – 1.15 m |
| Standing climb | up to 2.3 m |
| Running jump plus air grab | about 2.6 m (1.2 m jump + 1.4 m grab) |
| Jump height | 1.2 m (held), about 0.5 m (tapped) |
| Gap, same height | jog about 3 m, sprint about 4.5 m |
| Hard landing | a drop of about 2.4 m or more |
| Character | 1.75 m tall, 0.3 m radius |

## Colour language (graybox)
- Yellow: vaultable
- Blue: climbable
- Red: out of reach on purpose
- Brown: roofs
- Grey: props and ground

The final art replaces these with signals that belong in the world (see GDD.md).

## Colour values in generators
Pick colours in sRGB and convert to linear (`c ** 2.2`) before assigning them to a Principled BSDF. Otherwise they come out washed out in Godot.

## Generators
`tools/blender/*.py` run with `Blender --background --factory-startup --python <script> -- <out.glb>`. The script is the source of truth. Don't hand-edit generated GLBs.
