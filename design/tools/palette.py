#!/usr/bin/env python3
"""Tracko's colour tokens in OKLCH, checked the way the app renders them.

  python3 design/tools/palette.py

For every primitive: the Display P3 and sRGB values and whether it fits each gamut (iPhones show
P3; anything outside sRGB needs P3 to look as intended). For every pair the app draws, in both
the standard and the Increase Contrast appearance: WCAG 2 contrast (the legal bar) and APCA Lc
(the perceptual one). Keep TOKENS and ROLES identical to Tracko/DesignSystem/Theme.swift.
"""
import math

# (L, C, h) — keep in sync with Theme.swift.
# Primitives (Palette in Theme.swift): (L, C, h).
TOKENS = {
    # Neutral ramp, with a hint of the brand hue. The page is near-black, as in the reference
    # (design/references/006), so the hero platform's dark side still reads against it. Steps sit
    # closer at the light end, where text lives. Lightness set so every pair passes APCA.
    "neutral950": (0.090, 0.004, 160),
    "neutral850": (0.225, 0.010, 160),
    "neutral800": (0.290, 0.012, 160),
    "neutral600": (0.570, 0.012, 160),
    "neutral400": (0.770, 0.012, 160),
    "neutral300": (0.850, 0.010, 160),
    "neutral100": (0.920, 0.008, 160),
    "neutral50":  (0.975, 0.005, 160),
    # Green ramp: the brand, and growth.
    "green600":   (0.500, 0.170, 152),
    "green300":   (0.850, 0.235, 152),
}

# Semantic roles (Theme in Theme.swift): role -> (standard primitive, Increase Contrast primitive).
# Increase Contrast moves each muted role at least 15 points of lightness further from the page.
ROLES = {
    "bgPage": ("neutral950", "neutral950"),
    "bgRaised": ("neutral850", "neutral850"),
    "bgInverse": ("neutral50", "neutral50"),
    "border": ("neutral800", "neutral600"),
    "textPrimary": ("neutral50", "neutral50"),
    "textSecondary": ("neutral300", "neutral50"),
    "textTertiary": ("neutral400", "neutral100"),
    "textInverse": ("neutral950", "neutral950"),
    "fillSubtle": ("neutral600", "neutral400"),
    "fillStrong": ("neutral300", "neutral50"),
    "accent": ("green300", "green300"),
    "glow": ("green600", "green600"),
    "spotlight": ("green600", "green600"),
}

# (foreground, background, kind) for every pair on screen. Kinds set the thresholds below.
PAIRS = [
    ("textPrimary", "bgPage", "body"),         # headlines, wordmark
    ("textSecondary", "bgPage", "body"),       # sublines
    ("textTertiary", "bgPage", "label"),       # phone screen labels (the screen is bgPage)
    ("textInverse", "bgInverse", "label"),     # the button label
    ("textInverse", "accent", "label"),        # a beaten set's tile
    ("textPrimary", "bgRaised", "label"),      # set tiles
    ("accent", "bgPage", "large"),             # the +% score
    ("textPrimary", "glow", "large"),          # the logo at the brightest part of a glow (the spotlight is fainter)
    ("fillSubtle", "bgPage", "ui"),            # inactive page dots
    ("fillStrong", "bgRaised", "ui"),          # a progress bar on its track
    ("accent", "bgRaised", "ui"),              # a beaten bar on its track
]
# kind -> (WCAG 2 minimum, APCA |Lc| minimum)
THRESHOLDS = {"body": (4.5, 75), "label": (4.5, 60), "large": (3.0, 45), "ui": (3.0, 30)}


def oklab_to_linear_srgb(L, a, b):
    l_ = L + 0.3963377774 * a + 0.2158037573 * b
    m_ = L - 0.1055613458 * a - 0.0638541728 * b
    s_ = L - 0.0894841775 * a - 1.2914855480 * b
    l, m, s = l_ ** 3, m_ ** 3, s_ ** 3
    return (
        4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s,
        -1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s,
        -0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s,
    )


def oklch_to_linear_srgb(L, C, h):
    return oklab_to_linear_srgb(L, C * math.cos(math.radians(h)), C * math.sin(math.radians(h)))


SRGB_TO_XYZ = ((0.4123908, 0.3575843, 0.1804808), (0.2126390, 0.7151687, 0.0721923), (0.0193308, 0.1191948, 0.9505322))
XYZ_TO_P3 = ((2.4934969, -0.9313836, -0.4027108), (-0.8294890, 1.7626641, 0.0236247), (0.0358458, -0.0761724, 0.9568845))


def mul(m, v):
    return tuple(sum(m[i][j] * v[j] for j in range(3)) for i in range(3))


def linear_srgb_to_linear_p3(rgb):
    return mul(XYZ_TO_P3, mul(SRGB_TO_XYZ, rgb))


def encode(c):
    sign = -1 if c < 0 else 1
    c = abs(c)
    return sign * (12.92 * c if c <= 0.0031308 else 1.055 * c ** (1 / 2.4) - 0.055)


def in_gamut(rgb, eps=1e-4):
    return all(-eps <= c <= 1 + eps for c in rgb)


def luminance(lin_srgb):
    return sum(SRGB_TO_XYZ[1][i] * lin_srgb[i] for i in range(3))


def contrast(a, b):
    ya, yb = sorted((luminance(a), luminance(b)), reverse=True)
    return (ya + 0.05) / (yb + 0.05)


def apca(text_lin, bg_lin):
    """APCA-W3 0.0.98G-4g lightness contrast, Lc. Negative means light text on a dark background.
    Uses the sRGB-encoded values (clipped), as the APCA reference does."""
    def y(lin):
        encoded = [min(max(encode(c), 0), 1) for c in lin]
        value = sum(k * c ** 2.4 for k, c in zip((0.2126729, 0.7151522, 0.0721750), encoded))
        return value if value > 0.022 else value + (0.022 - value) ** 1.414
    yt, yb = y(text_lin), y(bg_lin)
    if abs(yb - yt) < 0.0005:
        return 0.0
    if yb > yt:
        sapc = (yb ** 0.56 - yt ** 0.57) * 1.14
        return 0.0 if sapc < 0.1 else (sapc - 0.027) * 100
    sapc = (yb ** 0.65 - yt ** 0.62) * 1.14
    return 0.0 if sapc > -0.1 else (sapc + 0.027) * 100


def hex_of(rgb):
    return "#" + "".join(f"{round(min(max(encode(c), 0), 1) * 255):02X}" for c in rgb)


def main():
    linear = {name: oklch_to_linear_srgb(*lch) for name, lch in TOKENS.items()}
    print(f"{'primitive':12} {'oklch':24} {'P3 (r, g, b)':22} {'in P3':6} {'in sRGB':8} sRGB hex")
    for name, lch in TOKENS.items():
        srgb = linear[name]
        p3 = linear_srgb_to_linear_p3(srgb)
        p3_encoded = ", ".join(f"{encode(c):.3f}" for c in p3)
        print(f"{name:12} oklch({lch[0]:.3f} {lch[1]:.3f} {lch[2]:>3}) {p3_encoded:22} {'yes' if in_gamut(p3) else 'NO':6} "
              f"{'yes' if in_gamut(srgb) else 'no':8} {hex_of(srgb)}")
    failures = 0
    for appearance, index in (("standard", 0), ("Increase Contrast", 1)):
        print(f"\n{appearance}")
        print(f"{'pair':30} {'kind':6} {'WCAG':>6} {'APCA Lc':>8}  result")
        for fg, bg, kind in PAIRS:
            f, b = linear[ROLES[fg][index]], linear[ROLES[bg][index]]
            ratio, lc = contrast(f, b), apca(f, b)
            wcag_min, apca_min = THRESHOLDS[kind]
            ok = ratio >= wcag_min and abs(lc) >= apca_min
            failures += not ok
            print(f"{fg + ' on ' + bg:30} {kind:6} {ratio:6.2f} {lc:8.1f}  {'ok' if ok else 'FAIL'}")
    return failures


if __name__ == "__main__":
    raise SystemExit(main())
