#!/usr/bin/env python3
# This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
"""
Sanctum icon generator — deterministic.

Renders every binary icon the branding needs (window/taskbar PNGs, .ico files,
about-page logos, Windows tile art) from pure geometry, so the repository can
stay 100% text. The build pipeline (scripts/02-apply-overlay.ps1) runs this
automatically when the PNGs are absent.

Requires Pillow:  pip install pillow
Run:              python branding/sanctum/generate-icons.py
"""
import math
import os
import sys

try:
    from PIL import Image, ImageDraw
except ImportError:
    sys.exit("Pillow is required. Install it with:  pip install pillow")

SS = 4  # supersample for crisp anti-aliasing

HERE = os.path.dirname(os.path.abspath(__file__))          # branding/sanctum
CONTENT = os.path.join(HERE, "content")
REPO_ROOT = os.path.abspath(os.path.join(HERE, "..", ".."))
ASSETS = os.path.join(REPO_ROOT, "assets")

TOP = (79, 70, 229)    # #4F46E5 indigo
MID = (124, 58, 237)   # #7C3AED violet
BOT = (147, 51, 234)   # #9333EA purple
KEY = (245, 243, 255)  # #F5F3FF


def lerp(a, b, t):
    return tuple(int(round(a[i] + (b[i] - a[i]) * t)) for i in range(len(a)))


def shield_mask(S):
    m = Image.new("L", (S, S), 0)
    d = ImageDraw.Draw(m)
    pad = S * 0.10
    w = S - 2 * pad
    left, right = pad, S - pad
    top = pad * 0.9
    shoulder = top + w * 0.55
    bottom = S - pad * 0.7
    midx = S / 2
    corner = w * 0.20
    pts = []
    for a in range(180, 271):
        pts.append((left + corner + corner * math.cos(math.radians(a)),
                    top + corner + corner * math.sin(math.radians(a))))
    for a in range(270, 361):
        pts.append((right - corner + corner * math.cos(math.radians(a)),
                    top + corner + corner * math.sin(math.radians(a))))
    pts.append((right, shoulder))
    for i in range(51):
        t = i / 50
        p0, p1, p2 = (right, shoulder), (right, bottom * 0.86), (midx, bottom)
        pts.append(((1 - t) ** 2 * p0[0] + 2 * (1 - t) * t * p1[0] + t * t * p2[0],
                    (1 - t) ** 2 * p0[1] + 2 * (1 - t) * t * p1[1] + t * t * p2[1]))
    for i in range(51):
        t = i / 50
        p0, p1, p2 = (midx, bottom), (left, bottom * 0.86), (left, shoulder)
        pts.append(((1 - t) ** 2 * p0[0] + 2 * (1 - t) * t * p1[0] + t * t * p2[0],
                    (1 - t) ** 2 * p0[1] + 2 * (1 - t) * t * p1[1] + t * t * p2[1]))
    d.polygon(pts, fill=255)
    return m


def keyhole_mask(S):
    m = Image.new("L", (S, S), 0)
    d = ImageDraw.Draw(m)
    midx = S / 2
    cy = S * 0.42
    r = S * 0.115
    d.ellipse([midx - r, cy - r, midx + r, cy + r], fill=255)
    sw_top, sw_bot = r * 0.55, r * 1.05
    d.polygon([(midx - sw_top, cy + r * 0.2), (midx + sw_top, cy + r * 0.2),
               (midx + sw_bot, S * 0.70), (midx - sw_bot, S * 0.70)], fill=255)
    return m


def make_logo(size):
    S = size * SS
    grad = Image.new("RGB", (S, S))
    gp = grad.load()
    for y in range(S):
        t = y / (S - 1)
        gp_row = lerp(TOP, MID, t / 0.5) if t < 0.5 else lerp(MID, BOT, (t - 0.5) / 0.5)
        for x in range(S):
            gp[x, y] = gp_row
    sm = shield_mask(S)
    img = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    img.paste(grad, (0, 0), sm)
    hl = Image.new("L", (S, S), 0)
    ImageDraw.Draw(hl).ellipse([S * 0.12, -S * 0.30, S * 0.88, S * 0.55], fill=46)
    hlmask = Image.composite(hl, Image.new("L", (S, S), 0), sm)
    img = Image.alpha_composite(
        img, Image.composite(Image.new("RGBA", (S, S), (255, 255, 255, 255)),
                             Image.new("RGBA", (S, S), (0, 0, 0, 0)), hlmask))
    km = Image.composite(keyhole_mask(S), Image.new("L", (S, S), 0), sm)
    img = Image.alpha_composite(
        img, Image.composite(Image.new("RGBA", (S, S), KEY + (255,)),
                             Image.new("RGBA", (S, S), (0, 0, 0, 0)), km))
    return img.resize((size, size), Image.LANCZOS)


def main():
    os.makedirs(CONTENT, exist_ok=True)
    os.makedirs(ASSETS, exist_ok=True)
    cache = {s: make_logo(s) for s in (16, 22, 24, 32, 48, 64, 70, 128, 150, 256, 512)}

    for s in (16, 22, 24, 32, 48, 64, 128, 256):
        cache[s].save(os.path.join(HERE, f"default{s}.png"))

    cache[64].save(os.path.join(CONTENT, "icon64.png"))
    cache[128].save(os.path.join(CONTENT, "about-logo.png"))
    cache[256].save(os.path.join(CONTENT, "about-logo@2x.png"))
    cache[512].save(os.path.join(CONTENT, "firefox.png"))
    cache[70].save(os.path.join(CONTENT, "VisualElements_70.png"))
    cache[150].save(os.path.join(CONTENT, "VisualElements_150.png"))

    ico = [(16, 16), (24, 24), (32, 32), (48, 48), (64, 64), (128, 128), (256, 256)]
    cache[256].save(os.path.join(HERE, "firefox.ico"), sizes=ico)
    cache[256].save(os.path.join(HERE, "document.ico"), sizes=ico)

    cache[512].save(os.path.join(ASSETS, "sanctum-logo.png"))
    print("Generated all Sanctum icons (PNG + ICO).")


if __name__ == "__main__":
    main()
