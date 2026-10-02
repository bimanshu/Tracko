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

COMMON = {
    "eye": "141217",
    "mouth": "5A2E2E",
    "mouth_open": "5B1E2B",
    "tongue": "E8707A",
    "blush": "F49AA6",
    "sneaker": "F3F1EC",
    "sole": "D6D8DE",
    "dumbbell": "3A3F4A",
    "phone": "22252C",
    "screen": "FFF6D6",
}

SPECS = {
    "female": {
        "skin": "F6C9A8",
        "skin_shade": "EDB592",
        "hair": "3B2D40",
        "top": "C6B3F2",
        "bottom": "3E3A6E",
        "accent": "9F86E0",
        "torso_width": 0.112,
        "hair_style": "bun",
        "shorts": False,
    },
    "male": {
        "skin": "C48A62",
        "skin_shade": "B37850",
        "hair": "3A2A22",
        "top": "8CCBB8",
        "bottom": "343A46",
        "accent": "5FAE98",
        "torso_width": 0.124,
        "hair_style": "quiff",
        "shorts": True,
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


def material(name, hex_value, roughness=0.5, coat=0.08, emission=0.0, sheen=0.25):
    key = (name, hex_value)
    if key in _materials:
        return _materials[key]
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes["Principled BSDF"]
    bsdf.inputs["Base Color"].default_value = colour(hex_value)
    bsdf.inputs["Roughness"].default_value = roughness
    bsdf.inputs["Coat Weight"].default_value = coat
    bsdf.inputs["Sheen Weight"].default_value = sheen
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


# ---------------------------------------------------------------------------
# The character
# ---------------------------------------------------------------------------


class Rig:
    """Pivots and swappable parts of one character."""


def build_character(kind):
    spec = SPECS[kind]
    c = COMMON
    m = {
        "skin": material("skin", spec["skin"], roughness=0.55, coat=0.05, sheen=0.35),
        "skin_shade": material("skin_shade", spec["skin_shade"], roughness=0.55, coat=0.05, sheen=0.35),
        "hair": material("hair", spec["hair"], roughness=0.45, coat=0.15),
        "top": material("top", spec["top"], roughness=0.65, coat=0.0, sheen=0.5),
        "bottom": material("bottom", spec["bottom"], roughness=0.6, coat=0.0, sheen=0.4),
        "accent": material("accent", spec["accent"], roughness=0.5),
        "eye": material("eye", c["eye"], roughness=0.12, coat=1.0, sheen=0.0),
        "sparkle": material("sparkle", "FFFFFF", roughness=0.3, emission=4.0, sheen=0.0),
        "mouth": material("mouth", c["mouth"], roughness=0.5),
        "mouth_open": material("mouth_open", c["mouth_open"], roughness=0.5),
        "tongue": material("tongue", c["tongue"], roughness=0.5),
        "blush": material("blush", c["blush"], roughness=0.7, sheen=0.4),
        "sneaker": material("sneaker", c["sneaker"], roughness=0.5),
        "sole": material("sole", c["sole"], roughness=0.6),
        "dumbbell": material("dumbbell", c["dumbbell"], roughness=0.35, coat=0.3, sheen=0.0),
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
        ellipsoid(f"shoe_{side}", (0.052, 0.078, 0.038), hip, (0, -0.018, -0.205), m["sneaker"])
        ellipsoid(f"sole_{side}", (0.055, 0.081, 0.014), hip, (0, -0.018, -0.232), m["sole"])
        ellipsoid(f"shoe_stripe_{side}", (0.054, 0.04, 0.012), hip, (side * 0.004, -0.005, -0.198), m["accent"])
        r.legs.append(hip)

    # Torso and hips.
    pelvis_semi = (tw - 0.004, 0.084, 0.072) if spec["shorts"] else (tw - 0.01, 0.08, 0.062)
    ellipsoid("pelvis", pelvis_semi, r.body, (0, 0, 0.02), m["bottom"])
    ellipsoid("torso", (tw + 0.006, 0.094, 0.135), r.body, (0, 0, 0.13), m["top"])

    # Arms swing from the shoulders.
    r.arms = []
    r.hands = []
    for side in (-1, 1):
        shoulder = empty(f"shoulder_{side}", r.body, (side * (tw - 0.012), 0, 0.215))
        ellipsoid(f"sleeve_{side}", (0.056, 0.058, 0.055), shoulder, (0, 0, -0.025), m["top"])
        limb(f"arm_{side}", (0.042, 0.044, 0.115), shoulder, 0.105, m["skin"])
        ellipsoid(f"hand_{side}", (0.05, 0.05, 0.05), shoulder, (0, 0, -0.215), m["skin"])
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
        eye_pivot = empty(f"eye_{side}", r.head, (side * 0.072, -0.188, 0.205))
        ellipsoid(f"pupil_{side}", (0.03, 0.014, 0.038), eye_pivot, (0, 0, 0), m["eye"])
        ellipsoid(f"sparkle_{side}", (0.009, 0.006, 0.009), eye_pivot, (-0.009, -0.012, 0.016), m["sparkle"], segments=16)
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
        # A quiff that sweeps up and over to one side.
        for x, y, z, semi, rot in (
            (0.0, -0.12, 0.395, (0.115, 0.072, 0.056), (-22, 0, -8)),
            (0.095, -0.08, 0.38, (0.08, 0.062, 0.05), (-15, -20, 0)),
            (-0.1, -0.085, 0.372, (0.062, 0.052, 0.042), (-15, 18, 0)),
        ):
            ellipsoid("tuft", semi, r.head, (x, y, z), m["hair"], rotation=rot)
        for side in (-1, 1):
            ellipsoid(f"sideburn_{side}", (0.02, 0.03, 0.05), r.head, (side * 0.198, -0.045, 0.205), m["hair"])

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


def setup_scene(resolution, samples):
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
    scene.render.resolution_y = resolution
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

    def area(name, location, energy, size, hex_value="FFFFFF", shadows=True):
        light = bpy.data.lights.new(name, "AREA")
        light.energy = energy
        light.size = size
        light.use_shadow = shadows
        light.color = colour(hex_value)[:3]
        obj = link(bpy.data.objects.new(name, light))
        obj.location = location
        target = Vector((0, 0, 0.5))
        obj.rotation_euler = (target - Vector(location)).to_track_quat("-Z", "Y").to_euler()
        return obj

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
# Entry point
# ---------------------------------------------------------------------------

VIEWS = {"front": 0, "three_quarter": 35, "side": 90, "back": 180}


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    parser = argparse.ArgumentParser()
    parser.add_argument("--character", choices=SPECS.keys(), required=True)
    parser.add_argument("--mode", choices=("still", "anim"), default="still")
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
