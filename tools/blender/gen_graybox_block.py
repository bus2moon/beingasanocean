"""Generate the Graybox Block test level and export it as GLB.

Run (Blender 4.5 LTS):
    /Applications/Blender.app/Contents/MacOS/Blender --background --factory-startup \
        --python tools/blender/gen_graybox_block.py -- assets/levels/graybox_block.glb

Layout is authored in Godot coordinates (Y up, -Z forward from spawn) and
converted to Blender's Z-up on creation, so numbers here match what you see in
the engine and docs/ASSET_GUIDE.md. Every height comes from TraversalMetrics.

Godot import hints used:  "-col"     -> mesh + static trimesh collision
                           "-colonly" -> collision only (invisible)
"""

import sys

import bpy

# sRGB values (what you'd pick in a colour picker); converted to linear below.
COLORS = {
    "ground": (0.42, 0.43, 0.45),
    "vault": (0.95, 0.78, 0.2),
    "climb": (0.25, 0.5, 0.85),
    "too_tall": (0.8, 0.22, 0.2),
    "platform": (0.55, 0.55, 0.5),
    "roof": (0.62, 0.36, 0.28),
    "crate": (0.6, 0.45, 0.25),
    "prop": (0.4, 0.42, 0.45),
}


def material(key):
    name = f"M_{key}"
    mat = bpy.data.materials.get(name)
    if mat is None:
        mat = bpy.data.materials.new(name)
        mat.use_nodes = True
        bsdf = mat.node_tree.nodes["Principled BSDF"]
        linear = [c ** 2.2 for c in COLORS[key]]
        bsdf.inputs["Base Color"].default_value = (*linear, 1.0)
        bsdf.inputs["Roughness"].default_value = 0.9
    return mat


def box(name, x, z, w, h, d, color, y=0.0, hint="-col"):
    """Axis-aligned box in Godot space. (x, z) = footprint centre, y = bottom,
    w = size on X, h = height, d = size on Z."""
    bpy.ops.mesh.primitive_cube_add(size=1.0)
    obj = bpy.context.active_object
    obj.name = f"{name}{hint}"
    obj.data.name = f"SM_{name}"
    # Godot (x, y, z) -> Blender (x, -z, y)
    obj.location = (x, -z, y + h / 2.0)
    obj.scale = (w, d, h)
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    obj.data.materials.append(material(color))
    return obj


def ramp(name, x, z_start, z_end, w, rise, color, y=0.0, hint="-col"):
    """Wedge rising from y at z_start to y+rise at z_end (Godot space)."""
    bz0, bz1 = -z_start, -z_end
    hw = w / 2.0
    verts = [
        (x - hw, bz0, y), (x + hw, bz0, y), (x + hw, bz1, y), (x - hw, bz1, y),
        (x - hw, bz1, y + rise), (x + hw, bz1, y + rise),
    ]
    faces = [(0, 1, 2, 3), (3, 2, 5, 4), (0, 4, 5, 1), (0, 3, 4), (1, 5, 2)]
    mesh = bpy.data.meshes.new(f"SM_{name}")
    mesh.from_pydata(verts, [], faces)
    mesh.update()
    mesh.validate()
    obj = bpy.data.objects.new(f"{name}{hint}", mesh)
    bpy.context.collection.objects.link(obj)
    mesh.materials.append(material(color))
    # Make normals point out regardless of winding above.
    bpy.context.view_layer.objects.active = obj
    obj.select_set(True)
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.mesh.normals_make_consistent(inside=False)
    bpy.ops.object.mode_set(mode="OBJECT")
    obj.select_set(False)
    return obj


def build():
    bpy.ops.wm.read_factory_settings(use_empty=True)

    box("Ground", 0, -20, 160, 1, 160, "ground", y=-1)

    # Lane A (x=-12): vault walls 3 m wide, 0.3 m deep.
    for i, h in enumerate((0.5, 0.8, 1.1)):
        box(f"VaultWall_{int(h * 100):03d}", -12, -8 - i * 8, 3, h, 0.3, "vault")

    # Lane B (x=-6): deep blocks for step-up / climb, last one is out of reach.
    for i, h in enumerate((1.0, 1.5, 2.0, 2.3, 2.8)):
        color = "too_tall" if h > 2.3 else "climb"
        box(f"ClimbBlock_{int(h * 100):03d}", -6, -8 - i * 7, 3, h, 3, color)

    # Lane C (x=0): gap course at 1.5 m, gaps 1..5 m, reached by a ramp.
    ramp("GapRamp", 0, -2, -8, 3, 1.5, "platform")
    z = -8.0
    for gap in (1, 2, 3, 4, 5):
        box(f"GapPlatform_{gap}m_before", 0, z - 1.5, 3, 1.5, 3, "platform")
        z -= 3 + gap
    box("GapPlatform_end", 0, z - 1.5, 3, 1.5, 3, "platform")

    # Lane D (x=9): stairs (visual steps, ramp collision) to a 2 m deck,
    # then 2 m climbs to a 6 m tower for hard-landing tests.
    for s in range(10):
        box(f"Stair_{s:02d}", 9, -4 - s * 0.3 - 0.15, 3, 0.2 * (s + 1), 0.3, "prop", hint="")
    ramp("StairRamp", 9, -4, -7, 3, 2.0, "prop", hint="-colonly")
    box("StairDeck", 9, -8.5, 3, 2.0, 3, "prop")
    box("Tower_4m", 9, -11.5, 3, 4.0, 3, "climb")
    box("Tower_6m", 9, -14.5, 3, 6.0, 3, "climb")
    ramp("SlopeRamp", 14, -2, -14, 3, 3.2, "platform")  # ~15 degrees

    # Lane E (x=24): rooftop row. Crate stack up to the first roof.
    box("Crate_1m", 24, -3.5, 3, 1.0, 3, "crate")
    box("Crate_2m", 24, -6.5, 3, 2.0, 3, "crate")
    box("Crate_3m", 24, -9.5, 3, 3.0, 3, "crate")
    roofs = [(4.0, 10, 2.5), (4.5, 10, 3.0), (4.0, 10, 3.5), (5.0, 12, 0)]
    z = -11.0
    for i, (h, length, gap) in enumerate(roofs):
        box(f"Roof_{i + 1}", 24, z - length / 2, 8, h, length, "roof")
        if i == 2:
            box("RoofVent", 24, z - length / 2, 4, 0.8, 0.3, "vault", y=h)
            box("RoofAC", 21.5, z - 2.5, 1.5, 1.0, 1.5, "prop", y=h)
        z -= length + gap


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    out = argv[0] if argv else "graybox_block.glb"
    build()
    bpy.ops.export_scene.gltf(
        filepath=out,
        export_format="GLB",
        export_yup=True,
        export_apply=True,
        export_extras=False,
    )
    print(f"exported {out}")


main()
