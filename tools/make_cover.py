"""Draws the mod cover: a blurred panel of the mod behind, a white Bruk Sans Bold title with a black outline and a
dark tile with a shield, the same layout as the Quality Calculator cover.
Writes portal/avatar-288.png, portal/avatar-144.png and src/ups-guard/thumbnail.png (144x144, read by the game and the portal).
Run: python -X utf8 tools/make_cover.py"""
import pathlib
from PIL import Image, ImageDraw, ImageFont, ImageFilter

ROOT = pathlib.Path(__file__).resolve().parent.parent
SHOT = ROOT / "portal" / "images" / "IMG-01-settings.png"
FONT = ROOT / "fonts" / "BrukSans-Bold.ttf"
W = 288
BLUR = 2.5
OUTLINE = 7


def background():
    shot = Image.open(SHOT).convert("RGB")
    shot = shot.crop((100, 30, 100 + 384, 30 + 384)).resize((W, W), Image.LANCZOS).filter(ImageFilter.GaussianBlur(BLUR))
    return shot.point(lambda v: int(v * 0.8))


def ink_box(text, f):
    img = Image.new("L", (900, 300), 0)
    ImageDraw.Draw(img).text((50, 50), text, font=f, fill=255)
    return img.getbbox()


def fit_width(text, width):
    """Largest font whose drawn ink (not the font box) of `text` is at most `width` wide."""
    best = None
    for size in range(20, 300):
        f = ImageFont.truetype(str(FONT), size)
        l, _, r, _ = ink_box(text, f)
        if r - l > width:
            break
        best = f
    return best


def title_mask():
    """Same sizes and positions as the Quality Calculator cover: a big first line (font 49) and a smaller second line (font 32)."""
    mask = Image.new("L", (W, W), 0)
    d = ImageDraw.Draw(mask)
    for text, size, yc in (("UPS", 49, 42), ("GUARD", 32, 92)):
        f = ImageFont.truetype(str(FONT), size)
        l, t, r, b = ink_box(text, f)
        d.text(((W - (r - l)) / 2 - (l - 50), yc - ((t + b) / 2 - 50)), text, font=f, fill=255)
    return mask


def shield_tile(size):
    s = size * 4
    img = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    pad = s * 0.06
    d.rounded_rectangle([pad, pad, s - pad, s - pad], radius=s * 0.16, fill=(38, 38, 42, 255),
                        outline=(160, 160, 165, 255), width=max(1, int(s * 0.03)))
    cx = s / 2

    def shield(scale, fill):
        w, h = s * 0.50 * scale, s * 0.60 * scale
        top = s * 0.20 + (1 - scale) * s * 0.30
        pts = [(cx - w / 2, top), (cx, top - h * 0.07), (cx + w / 2, top), (cx + w / 2, top + h * 0.50),
               (cx + w * 0.30, top + h * 0.80), (cx, top + h), (cx - w * 0.30, top + h * 0.80), (cx - w / 2, top + h * 0.50)]
        d.polygon(pts, fill=fill)

    shield(1.0, (20, 20, 22, 255))
    shield(0.90, (245, 160, 25, 255))
    shield(0.72, (205, 120, 10, 255))
    # check mark
    w = s * 0.075
    d.line([(cx - s * 0.12, s * 0.46), (cx - s * 0.03, s * 0.56), (cx + s * 0.14, s * 0.35)], fill=(255, 255, 255, 255),
           width=int(w), joint="curve")
    return img.resize((size, size), Image.LANCZOS)


def main():
    img = background()
    mask = title_mask()
    outline = mask.filter(ImageFilter.MaxFilter(OUTLINE)).filter(ImageFilter.GaussianBlur(0.8))
    img.paste((0, 0, 0), (0, 0), outline)
    img.paste((255, 255, 255), (0, 0), mask)
    size = 106
    tile = shield_tile(size)
    pos = ((W - size) // 2, 149)
    ring_src = Image.new("L", (W, W), 0)
    ring_src.paste(tile.getchannel("A"), pos)
    ring = ring_src.point(lambda v: 255 if v > 127 else 0).filter(ImageFilter.MaxFilter(OUTLINE)).filter(ImageFilter.GaussianBlur(0.8))
    img.paste((0, 0, 0), (0, 0), ring)
    img.paste(tile.convert("RGB"), pos, tile.getchannel("A"))
    img.save(ROOT / "portal" / "avatar-288.png")
    small = img.resize((144, 144), Image.LANCZOS)
    small.save(ROOT / "portal" / "avatar-144.png")
    small.save(ROOT / "src" / "ups-guard" / "thumbnail.png")
    print("saved", img.size, small.size)


if __name__ == "__main__":
    main()
