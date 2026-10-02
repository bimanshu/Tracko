#!/usr/bin/env python3
"""Render the Tracko characters and build everything in characters/.

  python3 characters/build/render_all.py stills   # turnarounds + expressions -> <character>/sheet.png, cast.png
  python3 characters/build/render_all.py anim     # gym log frames (slow: ~20 min per character on 4 cores)
  python3 characters/build/render_all.py post     # frames -> preview .mp4 + transparent .webm, timing.json

Needs Blender 4.5 LTS (set BLENDER=/path/to/blender), Pillow and ffmpeg with libx264 and libvpx-vp9.
Rendered frames go to characters/build/out/ (git-ignored); only finished files are committed.
"""
import glob
import json
import os
import subprocess
import sys

from PIL import Image, ImageDraw, ImageFilter, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
CHARACTERS = os.path.dirname(HERE)
OUT = os.path.join(HERE, "out")
BLENDER = os.environ.get("BLENDER", "/opt/blender/blender-4.5.14-linux-x64/blender")
SCRIPT = os.path.join(HERE, "tracko_characters.py")
CAST = ("female", "male")
VIEWS = ("front", "three_quarter", "side", "back")
EXPRESSIONS = ("neutral", "effort", "surprised", "happy")

INK = (0x16, 0x17, 0x1B)
SHEET_BG = (0xCA, 0xC8, 0xD9)
GAIN = (0x3D, 0xBA, 0x6E)
FONT_SCORE = os.path.join(HERE, "fonts", "BarlowCondensed-Black.ttf")
FONT_LABEL = os.path.join(HERE, "fonts", "Inter-Medium.ttf")
FONT_TITLE = os.path.join(HERE, "fonts", "Inter-Bold.ttf")


def blender(*args):
    command = [BLENDER, "-b", "-P", SCRIPT, "--", *args]
    result = subprocess.run(command, capture_output=True, text=True)
    if result.returncode != 0 or "Traceback" in result.stdout + result.stderr:
        sys.exit(f"Blender failed: {' '.join(args)}\n{result.stdout[-2000:]}\n{result.stderr[-2000:]}")


def timing():
    """Reads TIMING from the Blender script without importing bpy."""
    source = open(SCRIPT).read()
    start = source.index("TIMING = {")
    end = source.index("}\n", start) + 1
    namespace = {}
    exec(source[start:end], namespace)
    return namespace["TIMING"], int(source.split("FPS = ")[1].split("\n")[0])


def crop_to_content(image, pad):
    """Crops to the character itself, ignoring the faint shadow-catcher haze around it."""
    solid = image.getchannel("A").point(lambda a: 255 if a > 160 else 0)
    left, top, right, bottom = solid.getbbox()
    return image.crop((max(left - pad, 0), max(top - pad, 0), min(right + pad, image.width), min(bottom + pad, image.height)))


# --------------------------------------------------------------------------- stills

def stills():
    for character in CAST:
        folder = os.path.join(OUT, character)
        os.makedirs(folder, exist_ok=True)
        for view in VIEWS:
            blender("--character", character, "--mode", "still", "--view", view, "--shot", "full",
                    "--res", "900", "--samples", "64", "--out", os.path.join(folder, f"view_{view}.png"))
        for expression in EXPRESSIONS:
            blender("--character", character, "--mode", "still", "--view", "front", "--shot", "face",
                    "--expression", expression, "--res", "600", "--samples", "64",
                    "--out", os.path.join(folder, f"face_{expression}.png"))
        sheet(character)
    cast()


def sheet(character):
    folder = os.path.join(OUT, character)
    title_font = ImageFont.truetype(FONT_TITLE, 44)
    label_font = ImageFont.truetype(FONT_LABEL, 26)
    width, height = 2400, 1500
    canvas = Image.new("RGBA", (width, height), SHEET_BG + (255,))
    draw = ImageDraw.Draw(canvas)
    draw.text((70, 50), f"Tracko · {character}", font=title_font, fill=(0x2B, 0x2A, 0x38))

    # Turnaround: four views, same scale, standing on one line.
    views = [Image.open(os.path.join(folder, f"view_{v}.png")) for v in VIEWS]
    for i, (view, image) in enumerate(zip(VIEWS, views)):
        x = 60 + i * 570
        canvas.alpha_composite(image.resize((600, 600)), (x - 15, 110))
        label = view.replace("_", " ")
        w = draw.textlength(label, font=label_font)
        draw.text((x + 285 - w / 2, 720), label, font=label_font, fill=(0x55, 0x54, 0x66))

    # Expressions in a panel.
    panel = (60, 790, width - 60, height - 60)
    draw.rounded_rectangle(panel, radius=40, fill=(0xB9, 0xB6, 0xCC))
    for i, expression in enumerate(EXPRESSIONS):
        image = Image.open(os.path.join(folder, f"face_{expression}.png")).resize((480, 480))
        x = 120 + i * 560
        canvas.alpha_composite(image, (x, 810))
        w = draw.textlength(expression, font=label_font)
        draw.text((x + 240 - w / 2, 1300), expression, font=label_font, fill=(0x55, 0x54, 0x66))
    os.makedirs(os.path.join(CHARACTERS, character), exist_ok=True)
    canvas.convert("RGB").save(os.path.join(CHARACTERS, character, "sheet.png"), optimize=True)


def cast():
    images = [crop_to_content(Image.open(os.path.join(OUT, c, "view_three_quarter.png")), 40) for c in CAST]
    height = max(i.height for i in images)
    width = sum(i.width for i in images) + 160
    canvas = Image.new("RGBA", (width, height + 80), INK + (255,))
    x = 60
    for image in images:
        canvas.alpha_composite(image, (x, 40 + height - image.height))
        x += image.width + 40
    canvas.convert("RGB").save(os.path.join(CHARACTERS, "cast.png"), optimize=True)


# --------------------------------------------------------------------------- animation

def anim():
    for character in CAST:
        frames = os.path.join(OUT, character, "frames")
        os.makedirs(frames, exist_ok=True)
        blender("--character", character, "--mode", "anim", "--res", "640", "--samples", "28",
                "--out", frames, "--save-blend", os.path.join(OUT, character, "gym-log.blend"))


def popup_layer(size, frame, popup_frame, text):
    """The +% pop-up, as the app will draw it: gain green, score font, springs in and floats."""
    layer = Image.new("RGBA", size, (0, 0, 0, 0))
    age = frame - popup_frame
    if age < 0:
        return layer
    # Spring: 0 -> 1.18 over 4 frames, settle to 1 by 8.
    if age <= 4:
        scale = 1.18 * age / 4
    elif age <= 8:
        scale = 1.18 - 0.18 * (age - 4) / 4
    else:
        scale = 1.0
    if scale <= 0:
        return layer
    font = ImageFont.truetype(FONT_SCORE, max(1, int(118 * scale)))
    draw = ImageDraw.Draw(layer)
    cx, cy = int(size[0] * 0.8), int(size[1] * 0.15 - min(age, 40) * 0.4)
    w = draw.textlength(text, font=font)
    glow = Image.new("RGBA", size, (0, 0, 0, 0))
    ImageDraw.Draw(glow).text((cx - w / 2, cy - 60 * scale), text, font=font, fill=GAIN + (90,))
    layer.alpha_composite(glow.filter(ImageFilter.GaussianBlur(14)))
    draw.text((cx - w / 2, cy - 60 * scale), text, font=font, fill=GAIN + (255,))
    return layer


def post():
    marks, fps = timing()
    for character in CAST:
        frames = sorted(glob.glob(os.path.join(OUT, character, "frames", "f*.png")))
        if not frames:
            sys.exit(f"No frames for {character}; run `anim` first.")
        preview = os.path.join(OUT, character, "preview")
        os.makedirs(preview, exist_ok=True)
        for path in frames:
            frame = int(os.path.basename(path)[1:5])
            image = Image.open(path)
            canvas = Image.new("RGBA", image.size, INK + (255,))
            canvas.alpha_composite(image)
            canvas.alpha_composite(popup_layer(image.size, frame, marks["popup"], "+7%"))
            canvas.convert("RGB").save(os.path.join(preview, os.path.basename(path)))
        destination = os.path.join(CHARACTERS, character)
        os.makedirs(destination, exist_ok=True)
        subprocess.run(["ffmpeg", "-v", "error", "-y", "-framerate", str(fps), "-i", os.path.join(preview, "f%04d.png"),
                        "-c:v", "libx264", "-pix_fmt", "yuv420p", "-crf", "18", "-movflags", "+faststart",
                        os.path.join(destination, "gym-log-preview.mp4")], check=True)
        subprocess.run(["ffmpeg", "-v", "error", "-y", "-framerate", str(fps),
                        "-i", os.path.join(OUT, character, "frames", "f%04d.png"),
                        "-c:v", "libvpx-vp9", "-pix_fmt", "yuva420p", "-b:v", "0", "-crf", "28", "-row-mt", "1",
                        os.path.join(destination, "gym-log.webm")], check=True)
    def to_seconds(value):
        if isinstance(value, (list, tuple)):
            return [to_seconds(v) for v in value]
        return round(value / fps, 3)

    seconds = {name: to_seconds(value) for name, value in marks.items()}
    json.dump({"fps": fps, "frames": marks, "seconds": seconds, "popup_text": "+7%",
               "note": "The app draws the +% pop-up at frames.popup; the transparent clip doesn't include it."},
              open(os.path.join(CHARACTERS, "gym-log-timing.json"), "w"), indent=2)


if __name__ == "__main__":
    steps = {"stills": stills, "anim": anim, "post": post}
    if len(sys.argv) != 2 or sys.argv[1] not in steps:
        sys.exit(__doc__)
    steps[sys.argv[1]]()
