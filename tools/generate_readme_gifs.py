#!/usr/bin/env python3
import json
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[1]
ASSET_DIR = ROOT / "Sources/PixelAgent/Resources/Assets"
ATLAS_PATH = ASSET_DIR / "pixel-agent-sprite-atlas.png"
ANIMATIONS_PATH = ASSET_DIR / "animations.json"
OUT_DIR = ROOT / "docs/media"

SCALE = 2
CANVAS_SIZE = (160, 156)
SPRITE_ORIGIN = (16, 26)
BACKGROUND = (250, 246, 238, 255)

PREVIEWS = [
    ("idle", "pixel-agent-idle.gif", None),
    ("working", "pixel-agent-working.gif", "工作中勿扰..."),
    ("toolActive", "pixel-agent-tool-active.gif", None),
    ("completed", "pixel-agent-completed.gif", None),
    ("idleSleepy", "pixel-agent-sleepy.gif", "瞌睡..."),
    ("idleGaming", "pixel-agent-gaming.gif", None),
]


def nearest_resample():
    return getattr(Image, "Resampling", Image).NEAREST


def load_font(size):
    candidates = [
        "/System/Library/Fonts/STHeiti Medium.ttc",
        "/System/Library/Fonts/STHeiti Light.ttc",
        "/Library/Fonts/Arial Unicode.ttf",
    ]
    for candidate in candidates:
        path = Path(candidate)
        if path.exists():
            return ImageFont.truetype(str(path), size)
    return ImageFont.load_default()


def crop_frame(atlas, spec, frame_index, frame_width, frame_height):
    left = frame_index * frame_width
    top = spec["row"] * frame_height
    return atlas.crop((left, top, left + frame_width, top + frame_height))


def draw_bubble(draw, text):
    if not text:
        return

    font = load_font(11 if len(text) > 6 else 13)
    text_box = draw.textbbox((0, 0), text, font=font)
    text_width = text_box[2] - text_box[0]
    text_height = text_box[3] - text_box[1]
    width = text_width + 18
    height = text_height + 12
    x = (CANVAS_SIZE[0] - width) // 2
    y = 5

    outline = (25, 22, 24, 255)
    fill = (255, 253, 239, 255)
    shadow = (204, 178, 126, 255)
    text_color = (35, 29, 31, 255)

    draw.rectangle((x + 2, y + 2, x + width + 1, y + height + 1), fill=shadow)
    draw.rectangle((x, y, x + width - 1, y + height - 1), fill=outline)
    draw.rectangle((x + 2, y + 2, x + width - 3, y + height - 3), fill=fill)
    draw.rectangle((x + width // 2 - 4, y + height - 1, x + width // 2 + 3, y + height + 5), fill=outline)
    draw.rectangle((x + width // 2 - 2, y + height - 1, x + width // 2 + 1, y + height + 2), fill=fill)
    draw.text(
        (x + 9, y + 5 - text_box[1]),
        text,
        font=font,
        fill=text_color,
    )


def compose_preview_frame(sprite, bubble_text):
    canvas = Image.new("RGBA", CANVAS_SIZE, BACKGROUND)
    canvas.alpha_composite(sprite, SPRITE_ORIGIN)
    draw = ImageDraw.Draw(canvas)
    draw_bubble(draw, bubble_text)
    size = (CANVAS_SIZE[0] * SCALE, CANVAS_SIZE[1] * SCALE)
    return canvas.resize(size, nearest_resample()).convert("P", palette=Image.ADAPTIVE)


def main():
    atlas = Image.open(ATLAS_PATH).convert("RGBA")
    with ANIMATIONS_PATH.open("r", encoding="utf-8") as file:
        data = json.load(file)

    frame_width = data["frameWidth"]
    frame_height = data["frameHeight"]
    OUT_DIR.mkdir(parents=True, exist_ok=True)

    for animation_key, filename, bubble_text in PREVIEWS:
        spec = data["animations"][animation_key]
        frames = [
            compose_preview_frame(
                crop_frame(atlas, spec, frame_index, frame_width, frame_height),
                bubble_text,
            )
            for frame_index in spec["frames"]
        ]
        duration = max(40, round(1000 / spec["fps"]))
        out_path = OUT_DIR / filename
        frames[0].save(
            out_path,
            save_all=True,
            append_images=frames[1:],
            duration=duration,
            loop=0,
            disposal=2,
            optimize=False,
        )
        print(out_path.relative_to(ROOT))


if __name__ == "__main__":
    main()
