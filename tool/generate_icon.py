"""
Generates the Viba Music app icon assets (black & gold luxury identity).

Outputs (into assets/icon/):
  - icon.png             1024x1024 full-bleed icon (bg + glyph) - iOS/web/general
  - icon_background.png  1024x1024 gradient background only - Android adaptive icon
  - icon_foreground.png  1024x1024 transparent bg, glyph inset in safe zone - Android adaptive icon
  - icon_monochrome.png  1024x1024 transparent bg, solid-white glyph - Android 13+ monochrome/themed icon

Run with:  python tool/generate_icon.py
"""

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

SIZE = 1024
OUT_DIR = "assets/icon"

# Brand palette - true near-black with a warm metallic gold glyph and a
# ruby accent, the classic "black card" luxury pairing.
BLACK_1 = (10, 10, 11)  # #0A0A0B
BLACK_2 = (23, 21, 20)  # #171514
GOLD_LIGHT = (247, 206, 104)  # #F7CE68
GOLD_DEEP = (200, 144, 31)  # #C8901F
RUBY = (230, 57, 80)  # #E63950
WHITE = (255, 255, 255)


def lerp(a, b, t):
    return a + (b - a) * t


def make_gradient_bg(size, c1, c2):
    """Diagonal linear gradient from top-left (c1) to bottom-right (c2)."""
    x = np.linspace(0.0, 1.0, size, dtype=np.float32)
    y = np.linspace(0.0, 1.0, size, dtype=np.float32)
    xx, yy = np.meshgrid(x, y)
    t = np.clip((xx + yy) / 2.0, 0.0, 1.0)

    r = lerp(c1[0], c2[0], t).astype(np.uint8)
    g = lerp(c1[1], c2[1], t).astype(np.uint8)
    b = lerp(c1[2], c2[2], t).astype(np.uint8)
    arr = np.stack([r, g, b], axis=-1)
    return Image.fromarray(arr, "RGB")


def add_glossy_highlight(bg, size):
    """Soft radial white highlight near the top-left for a premium glassy sheen."""
    overlay = Image.new("L", (size, size), 0)
    draw = ImageDraw.Draw(overlay)
    cx, cy, r = size * 0.34, cy_top(size), size * 0.62
    draw.ellipse([cx - r, cy - r, cx + r, cy + r], fill=90)
    overlay = overlay.filter(ImageFilter.GaussianBlur(size * 0.16))
    white_layer = Image.new("RGB", (size, size), WHITE)
    return Image.composite(white_layer, bg, overlay)


def cy_top(size):
    return size * 0.26


def add_vignette(bg, size):
    """Subtle dark vignette toward the edges for depth."""
    overlay = Image.new("L", (size, size), 0)
    draw = ImageDraw.Draw(overlay)
    cx, cy, r = size * 0.5, size * 0.55, size * 0.72
    draw.ellipse([cx - r, cy - r, cx + r, cy + r], fill=0)
    overlay = overlay.filter(ImageFilter.GaussianBlur(size * 0.05))
    inv = Image.eval(overlay, lambda v: 255 - v)
    inv = inv.point(lambda v: int(v * 0.35))
    black_layer = Image.new("RGB", (size, size), (0, 0, 0))
    return Image.composite(black_layer, bg, inv)


def draw_gold_glow(canvas, size, cx, cy):
    """Soft gold glow behind the glyph group - reads like a warm spotlight
    on the near-black background."""
    glow = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(glow)
    r = size * 0.28
    draw.ellipse([cx - r, cy - r, cx + r, cy + r], fill=GOLD_LIGHT + (60,))
    glow = glow.filter(ImageFilter.GaussianBlur(size * 0.12))
    canvas.alpha_composite(glow)


def draw_gold_ring(canvas, size, cx, cy):
    """Thin gold medallion ring for a premium 'seal' feel."""
    ring = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(ring)
    r = size * 0.40
    draw.ellipse(
        [cx - r, cy - r, cx + r, cy + r],
        outline=GOLD_LIGHT + (200,),
        width=int(size * 0.010),
    )
    canvas.alpha_composite(ring)


def rounded_triangle_path(cx, cy, half_w, half_h, corner_r, steps=32):
    """Return a list of (x, y) points approximating a right-pointing
    play triangle with well-rounded corners, centered at (cx, cy)."""
    # Sharp triangle vertices (pointing right), slightly optically shifted.
    p_top = (cx - half_w, cy - half_h)
    p_bottom = (cx - half_w, cy + half_h)
    p_right = (cx + half_w * 1.2, cy)

    pts = [p_top, p_bottom, p_right]
    path = []
    n = len(pts)
    for i in range(n):
        p_prev = pts[(i - 1) % n]
        p_cur = pts[i]
        p_next = pts[(i + 1) % n]

        v1 = np.array(p_prev, dtype=np.float64) - np.array(p_cur, dtype=np.float64)
        v2 = np.array(p_next, dtype=np.float64) - np.array(p_cur, dtype=np.float64)
        len1 = np.linalg.norm(v1)
        len2 = np.linalg.norm(v2)
        v1n = v1 / len1
        v2n = v2 / len2

        r = min(corner_r, len1 * 0.42, len2 * 0.42)
        start = np.array(p_cur, dtype=np.float64) + v1n * r
        end = np.array(p_cur, dtype=np.float64) + v2n * r

        # Arc between start and end around p_cur, approximated by quadratic
        # bezier-esque interpolation (good enough for icon rendering).
        for s in range(steps + 1):
            t = s / steps
            # quadratic bezier: start -> p_cur -> end
            x = (1 - t) ** 2 * start[0] + 2 * (1 - t) * t * p_cur[0] + t**2 * end[0]
            y = (1 - t) ** 2 * start[1] + 2 * (1 - t) * t * p_cur[1] + t**2 * end[1]
            path.append((x, y))
    return path


def draw_play_glyph(canvas, size, cx, cy, scale=1.0, solid_color=None, shadow=True):
    """Draws the play triangle. By default it's filled with a light-gold ->
    deep-bronze diagonal gradient (the 'gold blend' look); pass
    solid_color for flat-color variants (e.g. monochrome icon)."""
    half_w = size * 0.145 * scale
    half_h = size * 0.175 * scale
    corner_r = size * 0.06 * scale

    if shadow:
        shadow_layer = Image.new("RGBA", (size, size), (0, 0, 0, 0))
        sdraw = ImageDraw.Draw(shadow_layer)
        pts = rounded_triangle_path(
            cx + size * 0.010, cy + size * 0.014, half_w, half_h, corner_r
        )
        sdraw.polygon(pts, fill=(0, 0, 0, 90))
        shadow_layer = shadow_layer.filter(ImageFilter.GaussianBlur(size * 0.025))
        canvas.alpha_composite(shadow_layer)

    mask = Image.new("L", (size, size), 0)
    mdraw = ImageDraw.Draw(mask)
    pts = rounded_triangle_path(cx, cy, half_w, half_h, corner_r)
    mdraw.polygon(pts, fill=255)

    if solid_color is None:
        fill = make_gradient_bg(size, GOLD_LIGHT, GOLD_DEEP).convert("RGBA")
    else:
        fill = Image.new("RGBA", (size, size), solid_color + (255,))

    glyph_layer = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    glyph_layer.paste(fill, (0, 0), mask)
    canvas.alpha_composite(glyph_layer)


def draw_soundwave_bars(canvas, size, cx, cy, color=RUBY, scale=1.0):
    """Three small equalizer bars to the left of the play glyph, reinforcing
    the 'music' identity."""
    bar_w = size * 0.032 * scale
    gap = size * 0.028 * scale
    heights = [0.11, 0.19, 0.135]
    base_x = cx - size * 0.315 * scale
    layer = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    for i, h in enumerate(heights):
        bh = size * h * scale
        x0 = base_x + i * (bar_w + gap)
        x1 = x0 + bar_w
        y0 = cy - bh / 2
        y1 = cy + bh / 2
        radius = bar_w / 2
        draw.rounded_rectangle([x0, y0, x1, y1], radius=radius, fill=color + (235,))
    canvas.alpha_composite(layer)


def build_background(size):
    bg = make_gradient_bg(size, BLACK_1, BLACK_2)
    bg = add_glossy_highlight(bg, size)
    bg = add_vignette(bg, size)
    return bg.convert("RGBA")


def build_full_icon(size):
    canvas = build_background(size)
    cx, cy = size * 0.5, size * 0.5
    draw_gold_glow(canvas, size, cx, cy)
    draw_gold_ring(canvas, size, cx, cy)
    draw_soundwave_bars(canvas, size, cx, cy)
    draw_play_glyph(canvas, size, cx + size * 0.045, cy)
    return canvas.convert("RGB")


def build_adaptive_background(size):
    return build_background(size).convert("RGB")


def build_adaptive_foreground(size):
    """Transparent canvas with the glyph inset within Android's ~66% safe
    zone for adaptive icons."""
    canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    cx, cy = size * 0.5, size * 0.5
    draw_soundwave_bars(canvas, size, cx, cy, scale=0.72)
    draw_play_glyph(canvas, size, cx + size * 0.032, cy, scale=0.72)
    return canvas


def build_monochrome(size):
    """Solid white glyph on transparent bg, for Android 13+ themed icons."""
    canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    cx, cy = size * 0.5, size * 0.5
    draw_soundwave_bars(canvas, size, cx, cy, color=WHITE, scale=0.72)
    draw_play_glyph(
        canvas, size, cx + size * 0.032, cy, scale=0.72, solid_color=WHITE, shadow=False
    )
    return canvas


def main():
    import os

    os.makedirs(OUT_DIR, exist_ok=True)

    full = build_full_icon(SIZE)
    full.save(f"{OUT_DIR}/icon.png")

    bg_only = build_adaptive_background(SIZE)
    bg_only.save(f"{OUT_DIR}/icon_background.png")

    fg = build_adaptive_foreground(SIZE)
    fg.save(f"{OUT_DIR}/icon_foreground.png")

    mono = build_monochrome(SIZE)
    mono.save(f"{OUT_DIR}/icon_monochrome.png")

    print("Icon assets written to", OUT_DIR)


if __name__ == "__main__":
    main()
