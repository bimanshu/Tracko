#!/usr/bin/env python3
"""Tracko's colour tokens in OKLCH, checked the way the app renders them.

  python3 design/tools/palette.py

For every token: the Display P3 and sRGB values, whether it fits each gamut (iPhones show P3;
anything outside sRGB needs P3 to look as intended), and WCAG contrast for every text pair
the app uses. Keep TOKENS identical to `Theme` in Tracko/DesignSystem/Theme.swift.
"""
import math

# (L, C, h) — keep in sync with Theme.swift.
TOKENS = {
    # Neutrals, with a hint of the brand hue. The canvas is near-black, as in the reference
    # (design/references/006), so the hero platform's dark side still reads against it.
    "canvas":         (0.090, 0.004, 160),
    "surface":        (0.170, 0.008, 160),
    "surfaceRaised":  (0.225, 0.010, 160),
    "border":         (0.290, 0.012, 160),
    "indicator":      (0.480, 0.012, 160),
    "textTertiary":   (0.640, 0.012, 160),
    "textSecondary":  (0.800, 0.010, 160),
    "textPrimary":    (0.975, 0.005, 160),
    # Brand green: growth.
    "accentMuted":    (0.330, 0.085, 152),
    "glow":           (0.500, 0.170, 152),
    "accent":         (0.850, 0.235, 152),
}

# (foreground, background, required ratio): every text or graphic pair on screen.
PAIRS = [
    ("textPrimary", "canvas", 4.5),
    ("textSecondary", "canvas", 4.5),
    ("textTertiary", "canvas", 4.5),
    ("textPrimary", "surface", 4.5),
    ("textSecondary", "surface", 4.5),
    ("textTertiary", "surface", 4.5),
    ("canvas", "textPrimary", 4.5),      # label on the primary button
    ("accent", "canvas", 3.0),           # large score numbers
    ("accent", "surface", 3.0),
    ("textPrimary", "glow", 3.0),        # the logo mark, at the brightest part of the glow
    ("indicator", "canvas", 3.0),        # inactive page dots
    ("textPrimary", "indicator", 3.0),   # active dot beside inactive ones
    ("border", "canvas", 1.0),           # decorative divider, reported for reference
]


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


def hex_of(rgb):
    return "#" + "".join(f"{round(min(max(encode(c), 0), 1) * 255):02X}" for c in rgb)


def main():
    linear = {name: oklch_to_linear_srgb(*lch) for name, lch in TOKENS.items()}
    print(f"{'token':15} {'oklch':24} {'P3 (r, g, b)':26} {'in P3':6} {'in sRGB':8} sRGB hex")
    for name, lch in TOKENS.items():
        srgb = linear[name]
        p3 = linear_srgb_to_linear_p3(srgb)
        p3_encoded = ", ".join(f"{encode(c):.3f}" for c in p3)
        print(f"{name:15} oklch({lch[0]:.3f} {lch[1]:.3f} {lch[2]:>3}) {p3_encoded:26} {'yes' if in_gamut(p3) else 'NO':6} "
              f"{'yes' if in_gamut(srgb) else 'no':8} {hex_of(srgb)}")
    print()
    print(f"{'pair':34} {'ratio':>6}  needs")
    for fg, bg, need in PAIRS:
        ratio = contrast(linear[fg], linear[bg])
        verdict = "ok" if ratio >= need else "FAIL"
        print(f"{fg + ' on ' + bg:34} {ratio:6.2f}  {need:>4}  {verdict}")


if __name__ == "__main__":
    main()
