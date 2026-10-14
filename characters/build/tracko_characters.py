"""Tracko characters: two chibi clay figures built from one recipe, so they always match.

Run with Blender 4.5 LTS (headless):

  blender -b -P tracko_characters.py -- --character female --mode still --view front --out out.png
  blender -b -P tracko_characters.py -- --character male --mode anim --out frames/ --start 1 --end 192

Modes:
  still  one pose: --view front|three_quarter|side|back, --expression neutral|effort|happy|surprised,
         --shot full|face
  anim   the "gym log" clip (walk in, lateral raises, log it on the phone, celebrate), PNG frames
         with a transparent background. The +% pop-up is not rendered; it's drawn by the app at
         the frame in TIMING["popup"], so the number always matches the maths.
  hero   an onboarding diorama: --scene welcome|log|beat|grow, --variant a|b (the same shot with
         the second expression), on a round platform beside a giant phone. Writes the PNG and,
         with --rect-out, where the phone's screen lands in the image, so the app can draw a live
         screen on it.

Everything is made of rounded clay shapes on a shared skeleton of pivots. Character differences
live only in SPECS (colours, hair, build), never in the animation.
"""

import argparse
import math
import sys

import bmesh
import bpy
from mathutils import Vector

FPS = 24

# Frame markers for the gym log clip. The app syncs its overlay to these.
TIMING = {
    "walk_end": 36,
    "turned": 44,
    "dumbbells_in": 52,
    "reps": [(58, 78), (78, 98), (98, 118)],  # (start, end) of each lateral raise
    "dumbbells_out": 118,
    "phone_in": 124,
    "taps": [134, 139, 144],
    "popup": 148,
    "jump_peak": 164,
    "land": 172,
    "end": 192,
}

# ---------------------------------------------------------------------------
# Specs: the only place the two characters differ
# ---------------------------------------------------------------------------

# Brand green, as close to the app's accent (oklch 0.85 0.235 150) as an sRGB texture gets.
BRAND = "17C964"

COMMON = {
    "eye": "15131A",
    "sclera": "FBFAF7",
    "mouth": "5A2E2E",
    "mouth_open": "5B1E2B",
    "tongue": "E8707A",
    "blush": "F49AA6",
    "sneaker": "F4F3EF",
    "sole": "F4F3EF",
    "sock": "F4F3EF",
    "dumbbell": "2A2D33",
    "phone": "15171D",
    "screen": "060807",
    "plinth": "1E1F25",
    "prop_dark": "26292E",
    "bottle": "EDEDEA",
}

# Colour blocking like a vinyl toy: white, black and one brand colour. The two characters mirror
# each other (white top and black bottom, or the reverse), so they read as a pair.
SPECS = {
    "female": {
        "skin": "F6C9A8",
        "skin_shade": "EDB592",
        "hair": "2A2130",
        "top": "F3F2EE",
        "bottom": "1D1E23",
        "accent": BRAND,
        "torso_width": 0.112,
        "hair_style": "bun",
        "shorts": False,
        "cap": None,
    },
    "male": {
        "skin": "C48A62",
        "skin_shade": "B37850",
        "hair": "2A1F1A",
        "top": "1D1E23",
        "bottom": "F0EEE8",
        "accent": BRAND,
        "torso_width": 0.124,
        "hair_style": "quiff",
        "shorts": True,
        "cap": "F3F2EE",
    },
}

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------


def srgb_to_linear(c):
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4


def colour(hex_value):
    h = hex_value.lstrip("#")
    return tuple(srgb_to_linear(int(h[i:i + 2], 16) / 255) for i in (0, 2, 4)) + (1.0,)


_materials = {}


def material(name, hex_value, roughness=0.5, coat=0.08, emission=0.0, sheen=0.25, coat_roughness=0.18, metallic=0.0,
             specular=0.5):
    key = (name, hex_value)
    if key in _materials:
        return _materials[key]
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes["Principled BSDF"]
    bsdf.inputs["Base Color"].default_value = colour(hex_value)
    bsdf.inputs["Roughness"].default_value = roughness
    bsdf.inputs["Coat Weight"].default_value = coat
    bsdf.inputs["Coat Roughness"].default_value = coat_roughness
    bsdf.inputs["Sheen Weight"].default_value = sheen
    bsdf.inputs["Metallic"].default_value = metallic
    bsdf.inputs["Specular IOR Level"].default_value = specular
    if emission:
        bsdf.inputs["Emission Color"].default_value = colour(hex_value)
        bsdf.inputs["Emission Strength"].default_value = emission
    _materials[key] = mat
    return mat


def link(obj):
    bpy.context.scene.collection.objects.link(obj)
    return obj


def empty(name, parent=None, location=(0, 0, 0)):
    obj = link(bpy.data.objects.new(name, None))
    obj.empty_display_size = 0.05
    obj.parent = parent
    obj.location = location
    obj.rotation_mode = "XYZ"
    return obj


def ellipsoid(name, semi, parent, location=(0, 0, 0), mat=None, rotation=(0, 0, 0), segments=48):
    """A smooth clay blob. `semi` is the three semi-axes; `location` is local to the parent."""
    mesh = bpy.data.meshes.new(name)
    bm = bmesh.new()
    bmesh.ops.create_uvsphere(bm, u_segments=segments, v_segments=segments // 2, radius=1.0)
    for v in bm.verts:
        v.co = Vector((v.co.x * semi[0], v.co.y * semi[1], v.co.z * semi[2]))
    bm.to_mesh(mesh)
    bm.free()
    for poly in mesh.polygons:
        poly.use_smooth = True
    obj = link(bpy.data.objects.new(name, mesh))
    obj.parent = parent
    obj.location = location
    obj.rotation_mode = "XYZ"
    obj.rotation_euler = [math.radians(a) for a in rotation]
    if mat:
        obj.data.materials.append(mat)
    return obj


def limb(name, semi, parent, length_offset, mat):
    """An ellipsoid hanging below its parent pivot, so rotating the pivot swings it."""
    return ellipsoid(name, semi, parent, (0, 0, -length_offset), mat)


def arc(name, points, parent, mat, thickness=0.006):
    """A bevelled curve through points (local to parent): mouths, closed eyes."""
    curve = bpy.data.curves.new(name, "CURVE")
    curve.dimensions = "3D"
    curve.bevel_depth = thickness
    curve.bevel_resolution = 4
    curve.use_fill_caps = True
    spline = curve.splines.new("BEZIER")
    spline.bezier_points.add(len(points) - 1)
    for bp, p in zip(spline.bezier_points, points):
        bp.co = p
        bp.handle_left_type = bp.handle_right_type = "AUTO"
    obj = link(bpy.data.objects.new(name, curve))
    obj.parent = parent
    obj.data.materials.append(mat)
    return obj


def rounded_box(name, size, parent, location, mat, bevel=0.012):
    mesh = bpy.data.meshes.new(name)
    bm = bmesh.new()
    bmesh.ops.create_cube(bm, size=1.0)
    for v in bm.verts:
        v.co = Vector((v.co.x * size[0], v.co.y * size[1], v.co.z * size[2]))
    bm.to_mesh(mesh)
    bm.free()
    obj = link(bpy.data.objects.new(name, mesh))
    obj.parent = parent
    obj.location = location
    mod = obj.modifiers.new("Bevel", "BEVEL")
    mod.width = bevel
    mod.segments = 6
    for poly in mesh.polygons:
        poly.use_smooth = True
    obj.data.materials.append(mat)
    return obj


def dome(name, semi, parent, location, mat, rotation=(0, 0, 0), segments=64):
    """The top half of an ellipsoid: a cap crown."""
    mesh = bpy.data.meshes.new(name)
    bm = bmesh.new()
    bmesh.ops.create_uvsphere(bm, u_segments=segments, v_segments=segments // 2, radius=1.0)
    bmesh.ops.bisect_plane(bm, geom=bm.verts[:] + bm.edges[:] + bm.faces[:], plane_co=(0, 0, 0),
                           plane_no=(0, 0, 1), clear_inner=True)
    for v in bm.verts:
        v.co = Vector((v.co.x * semi[0], v.co.y * semi[1], v.co.z * semi[2]))
    bm.to_mesh(mesh)
    bm.free()
    for poly in mesh.polygons:
        poly.use_smooth = True
    obj = link(bpy.data.objects.new(name, mesh))
    obj.parent = parent
    obj.location = location
    obj.rotation_mode = "XYZ"
    obj.rotation_euler = [math.radians(a) for a in rotation]
    solid = obj.modifiers.new("Solidify", "SOLIDIFY")
    solid.thickness = 0.01
    obj.data.materials.append(mat)
    return obj


def slab(name, size, corner, edge, parent, location, mat):
    """A box with rounded corners seen from the front (XZ) and softly rounded edges: phones."""
    mesh = bpy.data.meshes.new(name)
    bm = bmesh.new()
    bmesh.ops.create_cube(bm, size=1.0)
    for v in bm.verts:
        v.co = Vector((v.co.x * size[0], v.co.y * size[1], v.co.z * size[2]))
    depth_edges = [e for e in bm.edges
                   if abs(e.verts[0].co.x - e.verts[1].co.x) < 1e-6 and abs(e.verts[0].co.z - e.verts[1].co.z) < 1e-6]
    bmesh.ops.bevel(bm, geom=depth_edges, offset=corner, segments=16, profile=0.5, affect="EDGES", clamp_overlap=True)
    bm.to_mesh(mesh)
    bm.free()
    obj = link(bpy.data.objects.new(name, mesh))
    obj.parent = parent
    obj.location = location
    obj.rotation_mode = "XYZ"
    if edge:
        mod = obj.modifiers.new("Bevel", "BEVEL")
        mod.width = edge
        mod.segments = 5
        mod.limit_method = "ANGLE"
        mod.angle_limit = math.radians(40)
    for poly in mesh.polygons:
        poly.use_smooth = True
    try:
        mesh.set_sharp_from_angle(angle=math.radians(35))
    except AttributeError:
        pass
    obj.data.materials.append(mat)
    return obj


def cylinder(name, radius, depth, parent, location, mat, rotation=(0, 0, 0), bevel=0.0, segments=96):
    mesh = bpy.data.meshes.new(name)
    bm = bmesh.new()
    bmesh.ops.create_cone(bm, cap_ends=True, segments=segments, radius1=radius, radius2=radius, depth=depth)
    bm.to_mesh(mesh)
    bm.free()
    obj = link(bpy.data.objects.new(name, mesh))
    obj.parent = parent
    obj.location = location
    obj.rotation_mode = "XYZ"
    obj.rotation_euler = [math.radians(a) for a in rotation]
    if bevel:
        mod = obj.modifiers.new("Bevel", "BEVEL")
        mod.width = bevel
        mod.segments = 5
        mod.limit_method = "ANGLE"
    for poly in mesh.polygons:
        poly.use_smooth = True
    try:
        mesh.set_sharp_from_angle(angle=math.radians(40))
    except AttributeError:
        pass
    obj.data.materials.append(mat)
    return obj


def torus(name, major, minor, parent, location, mat, rotation=(0, 0, 0), scale=(1, 1, 1)):
    bpy.ops.mesh.primitive_torus_add(major_radius=major, minor_radius=minor, major_segments=64, minor_segments=24)
    obj = bpy.context.active_object
    obj.name = name
    obj.parent = parent
    obj.location = location
    obj.rotation_mode = "XYZ"
    obj.rotation_euler = [math.radians(a) for a in rotation]
    obj.scale = scale
    for poly in obj.data.polygons:
        poly.use_smooth = True
    obj.data.materials.append(mat)
    return obj


# ---------------------------------------------------------------------------
# The character
# ---------------------------------------------------------------------------


class Rig:
    """Pivots and swappable parts of one character."""


def build_character(kind):
    spec = SPECS[kind]
    c = COMMON
    # Glossy vinyl: a smooth base under a clear coat, like a collectible toy.
    m = {
        "skin": material("skin", spec["skin"], roughness=0.42, coat=0.3, sheen=0.2),
        "skin_shade": material("skin_shade", spec["skin_shade"], roughness=0.42, coat=0.3, sheen=0.2),
        "hair": material("hair", spec["hair"], roughness=0.3, coat=0.6, sheen=0.0, coat_roughness=0.12),
        "top": material("top", spec["top"], roughness=0.5, coat=0.18, sheen=0.3),
        "bottom": material("bottom", spec["bottom"], roughness=0.48, coat=0.2, sheen=0.25),
        "accent": material("accent", spec["accent"], roughness=0.35, coat=0.4, sheen=0.0),
        "eye": material("eye", c["eye"], roughness=0.12, coat=1.0, sheen=0.0),
        "sclera": material("sclera", c["sclera"], roughness=0.25, coat=0.8, sheen=0.0),
        "sock": material("sock", c["sock"], roughness=0.6, coat=0.0, sheen=0.4),
        "cap": material("cap", spec["cap"] or c["sock"], roughness=0.45, coat=0.25, sheen=0.2),
        "sparkle": material("sparkle", "FFFFFF", roughness=0.3, emission=4.0, sheen=0.0),
        "mouth": material("mouth", c["mouth"], roughness=0.5),
        "mouth_open": material("mouth_open", c["mouth_open"], roughness=0.5),
        "tongue": material("tongue", c["tongue"], roughness=0.5),
        "blush": material("blush", c["blush"], roughness=0.7, sheen=0.4),
        "sneaker": material("sneaker", c["sneaker"], roughness=0.38, coat=0.35, sheen=0.0),
        "sole": material("sole", c["sole"], roughness=0.55, coat=0.0, sheen=0.0),
        "dumbbell": material("dumbbell", c["dumbbell"], roughness=0.3, coat=0.5, sheen=0.0),
        "phone": material("phone", c["phone"], roughness=0.3, coat=0.5, sheen=0.0),
        "screen": material("screen", c["screen"], roughness=0.3, emission=2.5, sheen=0.0),
    }

    r = Rig()
    r.kind = kind
    r.root = empty(f"{kind}_root")
    r.body = empty("body", r.root, (0, 0, 0.25))

    tw = spec["torso_width"]

    # Legs swing from the hip joints.
    r.legs = []
    for side in (-1, 1):
        hip = empty(f"hip_{side}", r.root, (side * 0.056, 0, 0.25))
        leg_mat = m["skin"] if spec["shorts"] else m["bottom"]
        limb(f"leg_{side}", (0.047, 0.05, 0.115), hip, 0.105, leg_mat)
        if spec["shorts"]:
            ellipsoid(f"short_leg_{side}", (0.06, 0.062, 0.065), hip, (0, 0, -0.035), m["bottom"])
        if spec["shorts"]:
            ellipsoid(f"sock_{side}", (0.045, 0.047, 0.03), hip, (0, -0.004, -0.168), m["sock"])
        # Chunky sneaker: a rounded upper on a thick sole with a brand-green midsole line.
        ellipsoid(f"shoe_{side}", (0.056, 0.086, 0.044), hip, (0, -0.02, -0.198), m["sneaker"])
        ellipsoid(f"sole_{side}", (0.06, 0.091, 0.02), hip, (0, -0.02, -0.226), m["sole"])
        ellipsoid(f"midsole_{side}", (0.0605, 0.0915, 0.0065), hip, (0, -0.02, -0.219), m["accent"])
        ellipsoid(f"shoe_stripe_{side}", (0.058, 0.036, 0.012), hip, (side * 0.002, -0.004, -0.19), m["accent"], rotation=(0, 0, 0))
        r.legs.append(hip)

    # Torso and hips.
    pelvis_semi = (tw - 0.004, 0.084, 0.072) if spec["shorts"] else (tw - 0.01, 0.08, 0.062)
    ellipsoid("pelvis", pelvis_semi, r.body, (0, 0, 0.02), m["bottom"])
    ellipsoid("torso", (tw + 0.006, 0.094, 0.135), r.body, (0, 0, 0.13), m["top"])
    ellipsoid("badge", (0.021, 0.006, 0.021), r.body, (0.046, -0.083, 0.172), m["accent"], rotation=(-12, 0, 18), segments=32)

    # Arms swing from the shoulders.
    r.arms = []
    r.hands = []
    for side in (-1, 1):
        shoulder = empty(f"shoulder_{side}", r.body, (side * (tw - 0.012), 0, 0.215))
        ellipsoid(f"sleeve_{side}", (0.056, 0.058, 0.055), shoulder, (0, 0, -0.025), m["top"])
        limb(f"arm_{side}", (0.042, 0.044, 0.115), shoulder, 0.105, m["skin"])
        ellipsoid(f"hand_{side}", (0.05, 0.05, 0.05), shoulder, (0, 0, -0.215), m["skin"])
        ellipsoid(f"thumb_{side}", (0.017, 0.019, 0.027), shoulder, (-side * 0.03, -0.03, -0.198), m["skin"], rotation=(18, side * 20, 0))
        hand = empty(f"grip_{side}", shoulder, (0, 0, -0.225))
        r.arms.append(shoulder)
        r.hands.append(hand)

    # Head.
    r.head = empty("head", r.body, (0, 0, 0.255))
    ellipsoid("skull", (0.215, 0.2, 0.2), r.head, (0, 0, 0.2), m["skin"], segments=64)
    for side in (-1, 1):
        ellipsoid(f"ear_{side}", (0.034, 0.024, 0.045), r.head, (side * 0.208, 0.005, 0.185), m["skin_shade"])
    ellipsoid("nose", (0.017, 0.014, 0.014), r.head, (0, -0.199, 0.168), m["skin_shade"])

    # Face parts, each swappable for expressions.
    r.eyes, r.sparkles, r.brows, r.happy_eyes, r.effort_eyes, r.blush = [], [], [], [], [], []
    for side in (-1, 1):
        eye_pivot = empty(f"eye_{side}", r.head, (side * 0.076, -0.186, 0.2))
        ellipsoid(f"sclera_{side}", (0.041, 0.012, 0.049), eye_pivot, (0, 0.002, 0), m["sclera"], segments=32)
        ellipsoid(f"pupil_{side}", (0.033, 0.0155, 0.04), eye_pivot, (side * -0.002, -0.002, -0.004), m["eye"])
        ellipsoid(f"sparkle_{side}", (0.0115, 0.006, 0.0115), eye_pivot, (-0.011, -0.016, 0.014), m["sparkle"], segments=16)
        ellipsoid(f"sparkle_small_{side}", (0.0055, 0.004, 0.0055), eye_pivot, (0.011, -0.0165, -0.017), m["sparkle"], segments=12)
        r.eyes.append(eye_pivot)
        happy = empty(f"happy_eye_{side}", r.head, (side * 0.072, -0.19, 0.2))
        arc(f"happy_arc_{side}", [(-0.026, 0, -0.008), (0, -0.006, 0.016), (0.026, 0, -0.008)], happy, m["eye"], 0.0075)
        happy.scale = (0, 0, 0)
        r.happy_eyes.append(happy)
        squeeze = empty(f"effort_eye_{side}", r.head, (side * 0.072, -0.19, 0.205))
        # Points toward the nose: > on the left of the face, < on the right.
        tip = -side * 0.016
        arc(f"effort_arc_{side}", [(-tip, 0, 0.017), (tip, -0.004, 0), (-tip, 0, -0.017)], squeeze, m["eye"], 0.0075)
        squeeze.scale = (0, 0, 0)
        r.effort_eyes.append(squeeze)
        brow = empty(f"brow_{side}", r.head, (side * 0.074, -0.176, 0.272))
        ellipsoid(f"brow_shape_{side}", (0.026, 0.007, 0.007), brow, (0, 0, 0), m["hair"], segments=24)
        r.brows.append(brow)
        r.blush.append(ellipsoid(f"blush_{side}", (0.033, 0.008, 0.02), r.head, (side * 0.125, -0.155, 0.148), m["blush"], segments=24))

    r.smile = empty("smile", r.head, (0, -0.183, 0.118))
    arc("smile_arc", [(-0.028, 0, 0.008), (0, -0.004, -0.008), (0.028, 0, 0.008)], r.smile, m["mouth"], 0.0055)
    r.open_mouth = empty("open_mouth", r.head, (0, -0.176, 0.112))
    ellipsoid("mouth_hole", (0.036, 0.016, 0.026), r.open_mouth, (0, 0, 0), m["mouth_open"], segments=32)
    ellipsoid("tongue", (0.022, 0.012, 0.011), r.open_mouth, (0, -0.006, -0.012), m["tongue"], segments=24)
    r.open_mouth.scale = (0, 0, 0)

    # Hair.
    if spec["hair_style"] == "bun":
        ellipsoid("hair_cap", (0.228, 0.215, 0.205), r.head, (0, 0.03, 0.235), m["hair"], segments=64)
        # Side-swept fringe: one big sweep and a smaller tuck on the other side.
        ellipsoid("fringe", (0.13, 0.044, 0.056), r.head, (0.035, -0.152, 0.305), m["hair"], rotation=(14, -16, 0))
        ellipsoid("fringe_tuck", (0.072, 0.04, 0.048), r.head, (-0.112, -0.138, 0.315), m["hair"], rotation=(10, 24, 0))
        ellipsoid("bun", (0.088, 0.085, 0.082), r.head, (0, 0.06, 0.43), m["hair"])
        ellipsoid("hair_tie", (0.062, 0.06, 0.018), r.head, (0, 0.055, 0.36), m["accent"])
    else:
        ellipsoid("hair_cap", (0.228, 0.217, 0.19), r.head, (0, 0.035, 0.245), m["hair"], segments=64)
        if not spec["cap"]:
            # A quiff that sweeps up and over to one side.
            for x, y, z, semi, rot in (
                (0.0, -0.12, 0.395, (0.115, 0.072, 0.056), (-22, 0, -8)),
                (0.095, -0.08, 0.38, (0.08, 0.062, 0.05), (-15, -20, 0)),
                (-0.1, -0.085, 0.372, (0.062, 0.052, 0.042), (-15, 18, 0)),
            ):
                ellipsoid("tuft", semi, r.head, (x, y, z), m["hair"], rotation=rot)
        for side in (-1, 1):
            ellipsoid(f"sideburn_{side}", (0.02, 0.03, 0.05), r.head, (side * 0.198, -0.045, 0.205), m["hair"])

    if spec["cap"]:
        # A baseball cap, tipped back a little, with a brand-green badge on the front.
        cap = empty("cap", r.head, (0, 0.0, 0.272))
        cap.rotation_euler = (math.radians(-9), 0, 0)
        dome("crown", (0.238, 0.236, 0.205), cap, (0, 0.008, 0), m["cap"])
        ellipsoid("brim", (0.158, 0.128, 0.013), cap, (0, -0.225, 0.004), m["cap"], rotation=(6, 0, 0))
        ellipsoid("button", (0.022, 0.022, 0.012), cap, (0, 0.008, 0.204), m["cap"], segments=24)
        ellipsoid("cap_badge", (0.052, 0.01, 0.046), cap, (0, -0.212, 0.098), m["accent"], rotation=(-28, 0, 0), segments=32)

    # Props, hidden until used.
    r.dumbbells = []
    for side, hand in zip((-1, 1), r.hands):
        bell = empty(f"dumbbell_{side}", hand, (0, 0, 0))
        ellipsoid("handle", (0.014, 0.085, 0.014), bell, (0, 0, 0), m["dumbbell"], segments=16)
        for y in (-0.072, 0.072):
            ellipsoid("plate", (0.05, 0.028, 0.05), bell, (0, y, 0), m["dumbbell"], segments=32)
        bell.scale = (0, 0, 0)
        r.dumbbells.append(bell)

    r.phone = empty("phone", r.hands[0], (0.0, -0.01, 0.02))
    rounded_box("phone_body", (0.095, 0.016, 0.17), r.phone, (0, 0, 0.055), m["phone"], bevel=0.016)
    rounded_box("phone_screen", (0.082, 0.003, 0.152), r.phone, (0, -0.0085, 0.055), m["screen"], bevel=0.01)
    r.phone.rotation_euler = (math.radians(-90), 0, 0)
    r.phone.scale = (0, 0, 0)

    r.materials = m
    return r


# ---------------------------------------------------------------------------
# Poses and expressions
# ---------------------------------------------------------------------------

REST_ARM_OUT = 8  # degrees, so arms clear the torso


def set_arm(r, side_index, abduct=REST_ARM_OUT, flex=0.0, inward=0.0):
    """abduct: raise sideways (lateral raise). flex: raise forward. inward: swing a raised arm
    toward the midline. Degrees."""
    side = (-1, 1)[side_index]
    r.arms[side_index].rotation_euler = (
        math.radians(-flex),
        math.radians(-side * abduct),
        math.radians(-side * inward),
    )


def set_leg(r, side_index, swing=0.0, splay=0.0):
    """swing > 0 moves the foot forward."""
    side = (-1, 1)[side_index]
    r.legs[side_index].rotation_euler = (math.radians(-swing), math.radians(-side * splay), 0)


EXPRESSIONS = {
    # eyes scale z, brow (tilt, lift), smile, open mouth, happy eyes
    "neutral": {"eye": 1.0, "brow_tilt": 0, "brow_lift": 0.0, "smile": 1, "open": 0, "happy": 0, "squeeze": 0},
    "effort": {"eye": 0, "brow_tilt": 18, "brow_lift": -0.008, "smile": 0, "open": 1, "happy": 0, "squeeze": 1},
    "surprised": {"eye": 1.18, "brow_tilt": -8, "brow_lift": 0.014, "smile": 0, "open": 1, "happy": 0, "squeeze": 0},
    "happy": {"eye": 0, "brow_tilt": -6, "brow_lift": 0.01, "smile": 0, "open": 1, "happy": 1, "squeeze": 0},
}


def set_expression(r, name):
    e = EXPRESSIONS[name]
    for side_index, side in enumerate((-1, 1)):
        r.eyes[side_index].scale = (1, 1, e["eye"]) if e["eye"] else (0, 0, 0)
        r.happy_eyes[side_index].scale = (1, 1, 1) if e["happy"] else (0, 0, 0)
        r.effort_eyes[side_index].scale = (1, 1, 1) if e["squeeze"] else (0, 0, 0)
        r.brows[side_index].rotation_euler = (0, math.radians(side * e["brow_tilt"]), 0)
        r.brows[side_index].location.z = 0.272 + e["brow_lift"]
    r.smile.scale = (1, 1, 1) if e["smile"] else (0, 0, 0)
    small_open = name == "effort"
    if e["open"]:
        r.open_mouth.scale = (0.55, 1, 0.45) if small_open else (1, 1, 1)
    else:
        r.open_mouth.scale = (0, 0, 0)


def face_parts(r):
    return r.eyes + r.happy_eyes + r.effort_eyes + r.brows + [r.smile, r.open_mouth]


# ---------------------------------------------------------------------------
# Keyframing
# ---------------------------------------------------------------------------


def key(obj, path, frame):
    obj.keyframe_insert(data_path=path, frame=frame)


def key_pose(r, frame):
    for obj in [r.root, r.body, r.head] + r.arms + r.legs:
        key(obj, "location", frame)
        key(obj, "rotation_euler", frame)
        key(obj, "scale", frame)


def key_expression(r, name, frame):
    """Expression swaps are instant, like a cut in hand-drawn animation (see snap_expressions)."""
    set_expression(r, name)
    for obj in face_parts(r):
        key(obj, "scale", frame)
        key(obj, "rotation_euler", frame)
        key(obj, "location", frame)


def fcurves_of(obj):
    action = obj.animation_data.action
    try:
        return list(action.fcurves)
    except AttributeError:  # layered actions without the legacy accessor
        bag = action.layers[0].strips[0].channelbag(obj.animation_data.action_slot)
        return list(bag.fcurves)


def snap_expressions(r):
    for obj in face_parts(r):
        for curve in fcurves_of(obj):
            for point in curve.keyframe_points:
                point.interpolation = "CONSTANT"


def key_prop(obj, frame, size):
    obj.scale = (size, size, size)
    key(obj, "scale", frame)


def neutral_pose(r):
    r.root.location = (0, 0, 0)
    r.root.rotation_euler = (0, 0, 0)
    r.root.scale = (1, 1, 1)
    r.body.location = (0, 0, 0.25)
    r.body.rotation_euler = (0, 0, 0)
    r.head.rotation_euler = (0, 0, 0)
    for i in range(2):
        set_arm(r, i)
        set_leg(r, i)


def animate_gym_log(r):
    t = TIMING
    scene = bpy.context.scene
    scene.frame_start = 1
    scene.frame_end = t["end"]

    neutral_pose(r)
    key_expression(r, "neutral", 1)
    for bell in r.dumbbells:
        key_prop(bell, 1, 0)
    key_prop(r.phone, 1, 0)

    # 1. Walk in from the left, facing right. Two steps per 12 frames.
    start_x = -1.2
    walk_end = t["walk_end"]
    r.root.rotation_euler = (0, 0, math.radians(90))
    for f in range(1, walk_end + 1, 3):
        phase = (f - 1) / 12 * 2 * math.pi
        progress = (f - 1) / (walk_end - 1)
        eased = 1 - (1 - progress) ** 1.6  # slows into the stop
        r.root.location = (start_x * (1 - eased), 0, 0)
        stride = 26 * (1 - max(0, progress - 0.75) * 4 * 0.6)
        swing = math.sin(phase) * stride
        set_leg(r, 0, swing)
        set_leg(r, 1, -swing)
        set_arm(r, 0, REST_ARM_OUT, -swing * 0.8)
        set_arm(r, 1, REST_ARM_OUT, swing * 0.8)
        r.body.location.z = 0.25 + abs(math.cos(phase)) * 0.022
        r.body.rotation_euler = (math.radians(-5), 0, 0)
        r.head.rotation_euler = (math.radians(4 * math.sin(phase * 2)), 0, 0)
        key_pose(r, f)

    # 2. Stop and turn to the camera, with a little settle.
    neutral_pose(r)
    r.root.rotation_euler = (0, 0, math.radians(14))
    r.root.scale = (1.04, 1.04, 0.95)
    key_pose(r, t["turned"] - 3)
    r.root.scale = (1, 1, 1)
    key_pose(r, t["turned"])

    # 3. Look at the hands; the dumbbells pop in.
    r.head.rotation_euler = (math.radians(14), 0, 0)
    for i in range(2):
        set_arm(r, i, 12, 18)
    key_pose(r, t["dumbbells_in"] - 2)
    for bell in r.dumbbells:
        key_prop(bell, t["dumbbells_in"], 0)
        key_prop(bell, t["dumbbells_in"] + 4, 1.25)
        key_prop(bell, t["dumbbells_in"] + 7, 1)
    r.head.rotation_euler = (0, 0, 0)
    for i in range(2):
        set_arm(r, i, 10, 0)
    key_pose(r, t["reps"][0][0])

    # 4. Three lateral raises, with effort at the top.
    for start, end in t["reps"]:
        top = (start + end) // 2
        key_expression(r, "effort", start + 3)
        for i in range(2):
            set_arm(r, i, 78, 6)
        r.body.location.z = 0.243
        r.root.scale = (1.01, 1.01, 0.985)
        key_pose(r, top)
        key_expression(r, "neutral", top + 5)
        for i in range(2):
            set_arm(r, i, 10, 0)
        r.body.location.z = 0.25
        r.root.scale = (1, 1, 1)
        key_pose(r, end)

    # 5. Dumbbells away, phone out, tap tap tap.
    for bell in r.dumbbells:
        key_prop(bell, t["dumbbells_out"], 1)
        key_prop(bell, t["dumbbells_out"] + 3, 1.15)
        key_prop(bell, t["dumbbells_out"] + 6, 0)
    key_pose(r, t["dumbbells_out"] + 2)

    key_prop(r.phone, t["phone_in"], 0)
    key_prop(r.phone, t["phone_in"] + 4, 1.2)
    key_prop(r.phone, t["phone_in"] + 7, 1)
    set_arm(r, 0, 4, 84, 32)
    set_arm(r, 1, 6, 40, 26)
    r.head.rotation_euler = (math.radians(20), 0, 0)
    key_pose(r, t["phone_in"] + 6)
    for tap in t["taps"]:
        set_arm(r, 1, 6, 70, 38)
        key_pose(r, tap)
        set_arm(r, 1, 6, 56, 32)
        key_pose(r, tap + 3)

    # 6. The +% pops up: look up, surprised.
    key_expression(r, "surprised", t["popup"])
    r.head.rotation_euler = (math.radians(-12), 0, 0)
    set_arm(r, 1, 10, 8, 0)
    key_pose(r, t["popup"] + 3)

    # 7. Squat, jump, arms up, happy. Land with a squash and bounce.
    key_expression(r, "happy", t["popup"] + 8)
    r.root.scale = (1.06, 1.06, 0.88)
    r.body.location.z = 0.235
    for i in range(2):
        set_leg(r, i, 0, 6)
    set_arm(r, 0, 30, 45, 20)
    set_arm(r, 1, 30, 10)
    key_pose(r, t["jump_peak"] - 8)

    r.root.location.z = 0.17
    r.root.scale = (0.95, 0.95, 1.08)
    r.body.location.z = 0.25
    r.head.rotation_euler = (math.radians(-10), 0, 0)
    for i in range(2):
        set_leg(r, i, 18 * (1 if i == 0 else -0.4), 4)
    set_arm(r, 0, 130, 15)
    set_arm(r, 1, 130, 8)
    key_pose(r, t["jump_peak"])

    r.root.location.z = 0
    r.root.scale = (1.08, 1.08, 0.88)
    for i in range(2):
        set_leg(r, i, 0, 6)
    set_arm(r, 0, 112, 15)
    set_arm(r, 1, 112, 8)
    key_pose(r, t["land"])

    r.root.scale = (1, 1, 1)
    r.head.rotation_euler = (math.radians(-6), 0, 0)
    for i in range(2):
        set_leg(r, i, 0, 0)
    set_arm(r, 0, 122, 18)
    set_arm(r, 1, 122, 8)
    key_pose(r, t["land"] + 6)
    # Happy bounces to the end.
    for n, f in enumerate(range(t["land"] + 6, t["end"] + 1, 5)):
        up = n % 2 == 1
        r.body.location.z = 0.262 if up else 0.25
        set_arm(r, 0, 128 if up else 118, 18)
        set_arm(r, 1, 128 if up else 118, 8)
        key_pose(r, f)

    snap_expressions(r)


# ---------------------------------------------------------------------------
# Scene: lights, camera, render settings
# ---------------------------------------------------------------------------


def area(name, location, energy, size, hex_value="FFFFFF", shadows=True, target=(0, 0, 0.5)):
    light = bpy.data.lights.new(name, "AREA")
    light.energy = energy
    light.size = size
    light.use_shadow = shadows
    light.color = colour(hex_value)[:3]
    obj = link(bpy.data.objects.new(name, light))
    obj.location = location
    obj.rotation_euler = (Vector(target) - Vector(location)).to_track_quat("-Z", "Y").to_euler()
    return obj


def setup_scene(resolution, samples, lighting="studio", height=None):
    scene = bpy.context.scene
    scene.render.engine = "CYCLES"
    scene.cycles.device = "CPU"
    scene.cycles.samples = samples
    scene.cycles.use_adaptive_sampling = True
    scene.cycles.use_denoising = True
    scene.cycles.denoiser = "OPENIMAGEDENOISE"
    scene.cycles.max_bounces = 4
    scene.cycles.diffuse_bounces = 3
    scene.cycles.glossy_bounces = 2
    scene.cycles.transmission_bounces = 0
    scene.cycles.caustics_reflective = False
    scene.cycles.caustics_refractive = False
    scene.render.film_transparent = True
    scene.render.resolution_x = resolution
    scene.render.resolution_y = height or resolution
    scene.render.fps = FPS
    scene.render.image_settings.file_format = "PNG"
    scene.render.image_settings.color_mode = "RGBA"
    scene.view_settings.view_transform = "AgX"
    try:
        scene.view_settings.look = "AgX - Punchy"
    except TypeError:
        pass

    world = bpy.data.worlds.new("world")
    world.use_nodes = True
    world.node_tree.nodes["Background"].inputs["Color"].default_value = colour("8A8F9C")
    world.node_tree.nodes["Background"].inputs["Strength"].default_value = 0.55
    scene.world = world

    if lighting == "hero":
        setup_hero_lights(world)
        return

    area("key", (-2.2, -2.8, 3.2), 420, 3.0, "FFF4E8")
    area("fill", (2.8, -2.4, 1.4), 140, 3.0, "E8F0FF")
    area("rim", (1.2, 3.0, 2.6), 650, 1.6, shadows=False)
    area("rim_left", (-1.8, 2.6, 2.2), 380, 1.6, "E8E4FF", shadows=False)

    ground = bpy.data.meshes.new("ground")
    bm = bmesh.new()
    bmesh.ops.create_grid(bm, x_segments=1, y_segments=1, size=6)
    bm.to_mesh(ground)
    bm.free()
    ground_obj = link(bpy.data.objects.new("ground", ground))
    ground_obj.is_shadow_catcher = True


def setup_camera(shot):
    if shot == "face":
        location, target, lens = (0, -1.55, 0.78), (0, 0, 0.71), 100
    elif shot == "full":
        location, target, lens = (0, -2.7, 0.82), (0, 0, 0.48), 75
    else:  # anim: wide enough to walk in from off screen
        location, target, lens = (0, -3.9, 0.95), (0, 0, 0.5), 85
    cam_data = bpy.data.cameras.new("camera")
    cam_data.lens = lens
    cam = link(bpy.data.objects.new("camera", cam_data))
    cam.location = location
    cam.rotation_euler = (Vector(target) - Vector(location)).to_track_quat("-Z", "Y").to_euler()
    bpy.context.scene.camera = cam
    return cam


# ---------------------------------------------------------------------------
# Onboarding heroes: a diorama on a round platform, like a collectible on its stand
# ---------------------------------------------------------------------------

# Measured from the Any Distance onboarding (design/references/006, screens 04–06), the owner's
# reference for these heroes: the platform spans 82% of the screen width, the phone 32%, centred,
# about twice as tall as it is wide, and the camera looks down only ~5°.
HERO = {
    "size": (1200, 924),        # px; full screen width in the app, @3x on a 400 pt wide phone
    "plinth_radius": 1.18,
    "plinth_height": 0.088,
    "plinth_fraction": 0.818,   # platform width ÷ image width
    "pitch": 4.6,               # degrees the camera looks down
    "lens": 85,
    "bottom_margin": 0.035,     # gap under the platform, as a share of the image height
}
HERO_SIZE = HERO["size"]
PHONE = {"width": 0.924, "depth": 0.075, "height": 1.83, "corner": 0.152, "bezel": 0.041, "y": 0.02}


def setup_hero_lights(world):
    """Dark and moody, like the reference: a warm key, a brand-green glow from above and behind
    (it echoes the glow the app draws at the top of the screen) and cool rims."""
    world.node_tree.nodes["Background"].inputs["Color"].default_value = colour("5A6068")
    world.node_tree.nodes["Background"].inputs["Strength"].default_value = 0.1
    area("key", (-2.6, -3.1, 3.3), 600, 2.4, "FFF1E2", target=(0, 0, 0.55))
    area("fill", (2.8, -2.8, 0.9), 130, 3.0, "E6EEFF", target=(0, 0, 0.55))
    area("warm_side", (3.2, 0.6, 1.2), 260, 2.0, "FFC9A0", shadows=False, target=(0, 0, 0.3))
    area("glow", (0.0, 3.3, 2.6), 560, 3.0, BRAND, shadows=False, target=(0, 0, 0.95))
    area("rim", (2.7, 1.9, 1.7), 320, 1.6, "EAF2FF", shadows=False, target=(0, 0, 0.6))
    area("rim_left", (-2.6, 1.7, 1.5), 220, 1.6, "F2FFF6", shadows=False, target=(0, 0, 0.6))


def keep_light_off(light_name, obj):
    """Light linking: everything but `obj` receives this light."""
    light = bpy.data.objects[light_name]
    collection = bpy.data.collections.new(light_name + "_receivers")
    collection.objects.link(obj)
    light.light_linking.receiver_collection = collection
    # Entries follow collection.objects, which holds only `obj`.
    collection.collection_objects[0].light_linking.link_state = "EXCLUDE"


def build_plinth():
    # Fully matte: seen this close to edge-on, any specular turns the top into a mirror.
    mat = material("plinth", COMMON["plinth"], roughness=0.9, coat=0.0, sheen=0.0, specular=0.0)
    h = HERO["plinth_height"]
    plinth = cylinder("plinth", HERO["plinth_radius"], h, None, (0, 0, -h / 2), mat, bevel=0.012, segments=192)
    keep_light_off("glow", plinth)
    return plinth


def build_phone(location, camera_location):
    """A giant phone standing on the platform, tipped back so its screen faces the camera.
    Returns the screen, whose corners give the rectangle the app draws on."""
    w, d, h = PHONE["width"], PHONE["depth"], PHONE["height"]
    pivot = empty("giant_phone", None, location)
    to_camera = Vector(camera_location) - (Vector(location) + Vector((0, 0, h / 2)))
    pivot.rotation_euler = (-math.atan2(to_camera.z, -to_camera.y), 0, 0)
    # Matte dark grey, like the reference: the frame reads as a soft outline, not a chrome rim.
    frame = material("phone_frame", COMMON["phone"], roughness=0.55, coat=0.0, sheen=0.0, metallic=0.0, specular=0.22)
    glass = material("phone_glass", COMMON["screen"], roughness=0.06, coat=1.0, sheen=0.0)
    slab("phone_body", (w, d, h), PHONE["corner"], 0.014, pivot, (0, 0, h / 2), frame)
    b = PHONE["bezel"]
    screen = slab("phone_screen", (w - 2 * b, 0.004, h - 2 * b), PHONE["corner"] - b, 0.0, pivot,
                  (0, -d / 2 - 0.0016, h / 2), glass)
    # Side buttons catch the rim light.
    for z, length in ((1.25, 0.18), (1.48, 0.11)):
        slab("phone_button", (0.014, 0.036, length), 0.006, 0.0, pivot, (-w / 2 - 0.005, 0, z), frame)
    return screen


def kettlebell(location, turn=0.0):
    mat = material("prop_dark", COMMON["prop_dark"], roughness=0.3, coat=0.5, sheen=0.0)
    p = empty("kettlebell", None, location)
    p.rotation_euler = (0, 0, math.radians(turn))
    ellipsoid("kb_body", (0.13, 0.13, 0.12), p, (0, 0, 0.12), mat)
    ellipsoid("kb_base", (0.085, 0.085, 0.014), p, (0, 0, 0.008), mat, segments=32)
    torus("kb_handle", 0.08, 0.022, p, (0, 0, 0.232), mat, rotation=(90, 0, 0))
    return p


def bumper_plate(location, tilt=(0, 0, 0)):
    disc = material("plate", BRAND, roughness=0.42, coat=0.25, sheen=0.0)
    hub = material("plate_hub", "C9CCD0", roughness=0.22, coat=0.0, sheen=0.0, metallic=0.85)
    p = empty("plate", None, location)
    p.rotation_euler = [math.radians(a) for a in tilt]
    cylinder("plate_disc", 0.22, 0.06, p, (0, 0, 0), disc, rotation=(90, 0, 0), bevel=0.014)
    cylinder("plate_hub", 0.055, 0.072, p, (0, 0, 0), hub, rotation=(90, 0, 0), bevel=0.006, segments=48)
    return p


def water_bottle(location):
    body = material("bottle", COMMON["bottle"], roughness=0.28, coat=0.6, sheen=0.0)
    cap = material("prop_accent", BRAND, roughness=0.32, coat=0.4, sheen=0.0)
    p = empty("bottle", None, location)
    cylinder("bottle_body", 0.062, 0.27, p, (0, 0, 0.135), body, bevel=0.022, segments=64)
    cylinder("bottle_cap", 0.046, 0.055, p, (0, 0, 0.297), cap, bevel=0.012, segments=48)
    ellipsoid("bottle_spout", (0.018, 0.018, 0.024), p, (0, 0, 0.33), cap, segments=24)
    return p


def floor_dumbbell(location, turn=0.0):
    mat = material("dumbbell", COMMON["dumbbell"], roughness=0.3, coat=0.5, sheen=0.0)
    p = empty("floor_dumbbell", None, location)
    p.rotation_euler = (0, 0, math.radians(turn))
    cylinder("db_handle", 0.02, 0.26, p, (0, 0, 0.068), mat, rotation=(0, 90, 0), segments=32)
    for x in (-0.13, 0.13):
        cylinder("db_head", 0.068, 0.075, p, (x, 0, 0.068), mat, rotation=(0, 90, 0), bevel=0.014, segments=6)
    return p


def place(r, location, turn):
    neutral_pose(r)
    r.root.location = location
    r.root.rotation_euler = (0, 0, math.radians(turn))


def wave(r, side_index):
    """A hand raised up and out, clear of the head."""
    set_arm(r, side_index, abduct=124, flex=18)


def arms_up(r, spread=134):
    set_arm(r, 0, abduct=spread, flex=14)
    set_arm(r, 1, abduct=spread, flex=8)


# Each scene: (camera location, camera target, lens), the phone's spot (or None) and a stage function.
def stage_welcome(variant):
    her, him = build_character("female"), build_character("male")
    place(her, (-0.32, -0.12, 0), 16)
    place(him, (0.32, -0.12, 0), -16)
    wave(her, 0)
    wave(him, 1)
    her.head.rotation_euler = (math.radians(-4), math.radians(-7), 0)
    him.head.rotation_euler = (math.radians(-4), math.radians(7), 0)
    set_expression(her, "happy")
    set_expression(him, "happy")
    kettlebell((0.84, 0.02, 0), -20)
    bumper_plate((-0.86, 0.2, 0.215), tilt=(-8, 0, 18))
    water_bottle((-0.58, 0.46, 0))
    return [her, him]


# With a phone, the character stands to its left and props sit to its right, as in the reference.
def stage_log(variant):
    her = build_character("female")
    place(her, (-0.76, -0.2, 0), 32)
    set_arm(her, 1, abduct=30, flex=78, inward=6)
    set_arm(her, 0, abduct=14, flex=-6)
    her.head.rotation_euler = (math.radians(-10), math.radians(-5), math.radians(12))
    set_expression(her, "surprised" if variant == "a" else "happy")
    water_bottle((0.72, -0.24, 0))
    floor_dumbbell((0.84, 0.18, 0), 28)
    return [her]


def stage_beat(variant):
    him = build_character("male")
    place(him, (-0.78, -0.2, 0), 22)
    set_arm(him, 0, abduct=80, flex=6)
    him.dumbbells[0].scale = (1, 1, 1)
    set_arm(him, 1, abduct=12, flex=4)
    him.body.location.z = 0.244
    him.head.rotation_euler = (math.radians(-3), 0, math.radians(10))
    set_expression(him, "effort" if variant == "a" else "happy")
    kettlebell((0.76, -0.18, 0), 15)
    bumper_plate((0.64, 0.3, 0.215), tilt=(-10, 0, -22))
    return [him]


def stage_grow(variant):
    her, him = build_character("female"), build_character("male")
    place(her, (-0.78, -0.2, 0.07), 14)
    place(him, (0.78, -0.2, 0), -14)
    arms_up(her)
    set_leg(her, 0, 14, 4)
    set_leg(her, 1, -6, 4)
    set_arm(him, 1, abduct=128, flex=16)
    set_arm(him, 0, abduct=34, flex=46, inward=24)
    her.head.rotation_euler = (math.radians(-8), 0, 0)
    him.head.rotation_euler = (math.radians(-6), 0, 0)
    set_expression(her, "happy")
    set_expression(him, "happy")
    water_bottle((1.0, 0.3, 0))
    return [her, him]


# Every hero shares one camera and one platform, so the stage holds still while the pages swipe.
HERO_SCENES = {
    "welcome": (stage_welcome, False),
    "log": (stage_log, True),
    "beat": (stage_beat, True),
    "grow": (stage_grow, True),
}


def frame_camera(camera):
    """Product-shot framing, as in the reference: a level camera a few degrees above the platform
    (HERO["pitch"], seen from its centre), at the distance where the platform spans
    HERO["plinth_fraction"] of the width, with lens shift (not tilt) lifting the platform until it
    sits just above the bottom edge. Verticals stay vertical."""
    from bpy_extras.object_utils import world_to_camera_view

    scene = bpy.context.scene
    camera.data.lens = HERO["lens"]
    camera.data.sensor_fit = "HORIZONTAL"
    camera.rotation_euler = (math.radians(90), 0, 0)
    half_width = camera.data.sensor_width / 2 / HERO["lens"]
    distance = HERO["plinth_radius"] / HERO["plinth_fraction"] / half_width
    camera.location = (0, -distance, distance * math.tan(math.radians(HERO["pitch"])))
    bottom = Vector((0, -HERO["plinth_radius"], -HERO["plinth_height"]))
    low, high = -1.0, 1.0
    for _ in range(40):
        camera.data.shift_y = (low + high) / 2
        bpy.context.view_layer.update()
        # Shifting the frame up moves the platform down the image.
        if world_to_camera_view(scene, camera, bottom).y > HERO["bottom_margin"]:
            low = camera.data.shift_y
        else:
            high = camera.data.shift_y


def screen_rect(screen, camera):
    """Where the screen lands in the render: x, y, width, height as fractions, top-left origin,
    plus the corner radius as a fraction of the width."""
    from bpy_extras.object_utils import world_to_camera_view

    bpy.context.view_layer.update()
    scene = bpy.context.scene
    hw = (PHONE["width"] - 2 * PHONE["bezel"]) / 2
    hh = (PHONE["height"] - 2 * PHONE["bezel"]) / 2
    front = -0.002
    corners = [Vector((x, front, z)) for x in (-hw, hw) for z in (-hh, hh)]
    points = [world_to_camera_view(scene, camera, screen.matrix_world @ c) for c in corners]
    xs = [p.x for p in points]
    ys = [1 - p.y for p in points]
    x, y = min(xs), min(ys)
    w, h = max(xs) - x, max(ys) - y
    return {"x": round(x, 5), "y": round(y, 5), "width": round(w, 5), "height": round(h, 5),
            "corner": round((PHONE["corner"] - PHONE["bezel"]) / (2 * hw) * w, 5)}


def render_hero(name, variant, out, rect_out, samples):
    import json

    stage, has_phone = HERO_SCENES[name]
    setup_scene(HERO_SIZE[0], samples, lighting="hero", height=HERO_SIZE[1])
    build_plinth()
    stage(variant)
    camera = link(bpy.data.objects.new("camera", bpy.data.cameras.new("camera")))
    bpy.context.scene.camera = camera
    frame_camera(camera)
    rect = None
    if has_phone:
        screen = build_phone((0, PHONE["y"], 0), tuple(camera.location))
        rect = screen_rect(screen, camera)
    if rect_out:
        with open(rect_out, "w") as f:
            json.dump({"scene": name, "size": HERO_SIZE, "screen": rect}, f, indent=2)
    bpy.context.scene.render.filepath = out
    bpy.ops.render.render(write_still=True)


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

VIEWS = {"front": 0, "three_quarter": 35, "side": 90, "back": 180}


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    parser = argparse.ArgumentParser()
    parser.add_argument("--character", choices=SPECS.keys(), default="female")
    parser.add_argument("--mode", choices=("still", "anim", "hero"), default="still")
    parser.add_argument("--scene", choices=HERO_SCENES.keys(), default="welcome")
    parser.add_argument("--variant", choices=("a", "b"), default="a")
    parser.add_argument("--rect-out", default=None)
    parser.add_argument("--scale", type=float, default=1.0, help="hero resolution scale, for quick tests")
    parser.add_argument("--view", choices=VIEWS.keys(), default="front")
    parser.add_argument("--expression", choices=EXPRESSIONS.keys(), default="neutral")
    parser.add_argument("--shot", choices=("full", "face"), default="full")
    parser.add_argument("--out", required=True)
    parser.add_argument("--res", type=int, default=720)
    parser.add_argument("--samples", type=int, default=48)
    parser.add_argument("--start", type=int, default=1)
    parser.add_argument("--end", type=int, default=TIMING["end"])
    parser.add_argument("--save-blend", default=None)
    args = parser.parse_args(argv)

    bpy.ops.wm.read_factory_settings(use_empty=True)
    if args.mode == "hero":
        global HERO_SIZE
        HERO_SIZE = (round(HERO_SIZE[0] * args.scale), round(HERO_SIZE[1] * args.scale))
        render_hero(args.scene, args.variant, args.out, args.rect_out, args.samples)
        return
    setup_scene(args.res, args.samples)
    rig = build_character(args.character)

    scene = bpy.context.scene
    if args.mode == "still":
        setup_camera(args.shot)
        neutral_pose(rig)
        rig.root.rotation_euler = (0, 0, math.radians(VIEWS[args.view]))
        set_expression(rig, args.expression)
        if args.save_blend:
            bpy.ops.wm.save_as_mainfile(filepath=args.save_blend)
        scene.render.filepath = args.out
        bpy.ops.render.render(write_still=True)
    else:
        setup_camera("anim")
        scene.render.use_persistent_data = True
        animate_gym_log(rig)
        if args.save_blend:
            bpy.ops.wm.save_as_mainfile(filepath=args.save_blend)
        scene.frame_start = args.start
        scene.frame_end = args.end
        scene.render.filepath = args.out.rstrip("/") + "/f####"
        bpy.ops.render.render(animation=True)


main()
