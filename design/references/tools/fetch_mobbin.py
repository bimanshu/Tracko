#!/usr/bin/env python3
"""Download a Mobbin flow into the reference library.

Usage: python3 design/references/tools/fetch_mobbin.py <mobbin flow url> <NNN>

Saves, next to the library README:
  NNN-<app>-<flow>-<i>.jpg   every screen, in order, at the largest size offered
  NNN-<app>-<flow>-sheet.jpg overview of all screens
  NNN-<app>-<flow>.mp4       the flow recording, when Mobbin has one
  NNN-<app>-<flow>-timeline.jpg  frames from the recording (needs ffmpeg)
and prints the app, flow, platform and canonical URL for the README entry.
Needs Pillow; the session's network must allow mobbin.com.
"""
import glob
import io
import json
import os
import re
import subprocess
import sys
import tempfile
import urllib.request

from PIL import Image, ImageDraw

LIBRARY = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
AGENT = "Mozilla/5.0 (Macintosh; Intel Mac OS X 14_0) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15"


def get(url):
    request = urllib.request.Request(url, headers={"User-Agent": AGENT})
    with urllib.request.urlopen(request) as response:
        return response.read(), response.geturl()


def flow_data(html):
    chunks = re.findall(r'self\.__next_f\.push\(\[1,"(.*?)"\]\)', html, re.S)
    payload = "".join(json.loads(f'"{chunk}"') for chunk in chunks)
    start = payload.find('"flow":{')
    if start < 0:
        sys.exit("No flow data on the page (is the link a Mobbin flow?)")
    decoder = json.JSONDecoder()
    flow, _ = decoder.raw_decode(payload, payload.find("{", start))
    return flow


def slug(text):
    return re.sub(r"[^a-z0-9]+", "-", text.lower()).strip("-")


def sheet(images, width, columns, labels=None):
    gap, label = 12, 14 if labels else 0
    scaled = [im.resize((width, round(im.height * width / im.width))) for im in images]
    height = max(im.height for im in scaled)
    rows = (len(scaled) + columns - 1) // columns
    out = Image.new("RGB", (columns * (width + gap) + gap, rows * (height + gap + label) + gap), (60, 60, 64))
    draw = ImageDraw.Draw(out)
    for i, im in enumerate(scaled):
        x = gap + (i % columns) * (width + gap)
        y = gap + (i // columns) * (height + gap + label)
        out.paste(im, (x, y + label))
        if labels:
            draw.text((x + 2, y), labels[i], fill=(255, 255, 255))
    return out


def main():
    if len(sys.argv) != 3:
        sys.exit(__doc__)
    url, number = sys.argv[1], sys.argv[2].zfill(3)
    html, final_url = get(url)
    flow = flow_data(html.decode("utf-8", "replace"))
    base = f"{number}-{slug(flow['appName'])}-{slug(flow['name'])}"

    screens = sorted(flow["screens"], key=lambda s: s["order"])
    images = []
    for index, screen in enumerate(screens, start=1):
        sources = screen["screenCdnImgSources"]["srcSet"]
        best = max(sources, key=lambda s: int(s["descriptor"].rstrip("w")))
        data, _ = get(best.get("url") or best.get("src"))
        image = Image.open(io.BytesIO(data)).convert("RGB")
        image.save(os.path.join(LIBRARY, f"{base}-{index:02d}.jpg"), quality=88)
        images.append(image)
    sheet(images, 400, min(5, len(images))).save(os.path.join(LIBRARY, f"{base}-sheet.jpg"), quality=85)

    video = (flow.get("videoCdnVideoSources") or {}).get("source", {}).get("url")
    if video:
        data, _ = get(video)
        video_path = os.path.join(LIBRARY, f"{base}.mp4")
        open(video_path, "wb").write(data)
        with tempfile.TemporaryDirectory() as frames:
            subprocess.run(["ffmpeg", "-v", "error", "-i", video_path, "-vf", "fps=1.5,scale=180:-1",
                            os.path.join(frames, "f%03d.png")], check=True)
            files = sorted(glob.glob(os.path.join(frames, "f*.png")))
            labels = [f"{i / 1.5:.1f}s" for i in range(len(files))]
            frames_images = [Image.open(f).convert("RGB") for f in files]
            sheet(frames_images, 180, 16, labels).save(os.path.join(LIBRARY, f"{base}-timeline.jpg"), quality=80)

    print(json.dumps({
        "base": base,
        "app": flow["appName"],
        "flow": flow["name"],
        "platform": flow.get("platform"),
        "screens": len(images),
        "video": bool(video),
        "url": final_url.split("?")[0],
    }, indent=1))


if __name__ == "__main__":
    main()
