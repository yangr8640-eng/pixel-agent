#!/usr/bin/env python3
from pathlib import Path
from PIL import Image, ImageDraw


FRAME = 128
COLS = 8
ROWS = 5
OUT = Path("Sources/PixelAgent/Resources/Assets/pixel-agent-sprite-atlas.png")


PALETTE = {
    "outline": (20, 18, 24, 255),
    "deep": (9, 10, 14, 255),
    "hair": (24, 23, 27, 255),
    "hair_hi": (48, 44, 50, 255),
    "hood_shadow": (130, 36, 30, 255),
    "hood": (196, 54, 37, 255),
    "shirt_shadow": (188, 80, 28, 255),
    "shirt": (241, 119, 34, 255),
    "shirt_hi": (255, 157, 63, 255),
    "pants": (43, 57, 95, 255),
    "chair": (118, 184, 132, 255),
    "chair_shadow": (77, 130, 94, 255),
    "desk": (173, 126, 73, 255),
    "desk_hi": (215, 168, 102, 255),
    "desk_edge": (91, 45, 42, 255),
    "leg": (104, 123, 130, 255),
    "monitor": (226, 229, 226, 255),
    "monitor_shadow": (146, 151, 154, 255),
    "monitor_dark": (54, 61, 62, 255),
    "screen": (28, 42, 37, 255),
    "screen_dim": (77, 162, 105, 255),
    "screen_bright": (124, 245, 147, 255),
    "screen_blue": (90, 196, 244, 255),
    "screen_yellow": (245, 232, 112, 255),
    "coffee": (102, 58, 43, 255),
    "steam": (255, 255, 255, 180),
    "spark": (255, 238, 128, 255),
    "sleep": (235, 241, 255, 210),
}


def rect(draw, x, y, w, h, fill):
    draw.rectangle([x, y, x + w - 1, y + h - 1], fill=fill)


def dot(draw, x, y, fill, size=2):
    rect(draw, x, y, size, size, fill)


def draw_screen_code(draw, ox, oy, row, frame):
    x = ox + 50
    y = oy + 18
    bright = PALETTE["screen_bright"]
    dim = PALETTE["screen_dim"]
    blue = PALETTE["screen_blue"]
    yellow = PALETTE["screen_yellow"]

    if row == 3:
        # Completed: a tiny happy face.
        dot(draw, x + 6, y + 4, bright)
        dot(draw, x + 20, y + 4, bright)
        rect(draw, x + 9, y + 12, 12, 2, bright)
        dot(draw, x + 7, y + 10, bright)
        dot(draw, x + 21, y + 10, bright)
        return

    if row == 4 and frame >= 4:
        # Idle gaming: tiny Snake/Tetris screens.
        rect(draw, x + 3, y + 3, 24, 15, dim)
        rect(draw, x + 4, y + 4, 22, 13, PALETTE["screen"])
        if frame in (4, 5):
            snake = [
                (8 + frame % 2, 8),
                (11 + frame % 2, 8),
                (14 + frame % 2, 8),
                (14 + frame % 2, 11),
            ]
            for sx, sy in snake:
                rect(draw, x + sx, y + sy, 3, 3, bright)
            dot(draw, x + 22, y + 14, yellow, size=2)
            dot(draw, x + 7, y + 5, blue, size=1)
        else:
            blocks = [
                (7, 12, blue), (10, 12, blue), (13, 12, bright),
                (16, 12, yellow), (16, 9, yellow), (19, 12, yellow),
                (10, 9, bright), (13, 9, bright), (13, 6, bright),
            ]
            if frame == 7:
                blocks.append((19, 6, blue))
                blocks.append((22, 6, blue))
            for bx, by, color in blocks:
                rect(draw, x + bx, y + by, 3, 3, color)
        return

    if row == 4:
        # Sleepy idle: dimmed terminal.
        rect(draw, x + 5, y + 6, 9, 2, dim)
        rect(draw, x + 5, y + 11, 14, 2, dim)
        return

    phase = frame % 4
    rect(draw, x + 4, y + 4, 5 + phase, 2, bright if row == 2 else dim)
    rect(draw, x + 13, y + 4, 4, 2, dim)
    rect(draw, x + 20, y + 4, 6, 2, bright if row == 1 else dim)
    rect(draw, x + 4, y + 9, 9, 2, dim)
    rect(draw, x + 16, y + 9, 10 - phase, 2, bright if row == 2 else dim)
    rect(draw, x + 4, y + 14, 4, 2, blue if row == 2 else dim)
    rect(draw, x + 11, y + 14, 15, 2, bright if row in (1, 2) else dim)

    if row == 2:
        dot(draw, x + 27, y + 3 + phase, PALETTE["spark"], size=1)
        dot(draw, x + 2, y + 15 - phase, PALETTE["spark"], size=1)


def draw_desk(draw, ox, oy):
    rect(draw, ox + 13, oy + 45, 102, 3, PALETTE["desk_hi"])
    rect(draw, ox + 12, oy + 48, 104, 13, PALETTE["desk"])
    rect(draw, ox + 12, oy + 58, 104, 5, PALETTE["desk_edge"])
    rect(draw, ox + 16, oy + 49, 7, 7, (190, 137, 79, 255))
    rect(draw, ox + 105, oy + 49, 7, 7, (190, 137, 79, 255))
    dot(draw, ox + 20, oy + 50, PALETTE["desk_hi"], size=2)
    dot(draw, ox + 107, oy + 50, PALETTE["desk_hi"], size=2)
    rect(draw, ox + 23, oy + 63, 7, 30, PALETTE["leg"])
    rect(draw, ox + 98, oy + 63, 7, 30, PALETTE["leg"])
    rect(draw, ox + 24, oy + 63, 2, 30, (137, 156, 162, 255))
    rect(draw, ox + 99, oy + 63, 2, 30, (137, 156, 162, 255))

    # Keyboard and desk items.
    rect(draw, ox + 47, oy + 61, 34, 5, (42, 43, 48, 255))
    for i in range(6):
        dot(draw, ox + 51 + i * 5, oy + 62, (94, 98, 106, 255), size=1)
    rect(draw, ox + 88, oy + 52, 7, 7, PALETTE["coffee"])
    rect(draw, ox + 89, oy + 53, 5, 2, (149, 93, 63, 255))


def draw_monitor(draw, ox, oy, row, frame):
    glow = row == 2
    if glow:
        rect(draw, ox + 42, oy + 11, 44, 28, (65, 111, 82, 80))

    rect(draw, ox + 42, oy + 10, 44, 33, PALETTE["outline"])
    rect(draw, ox + 44, oy + 8, 40, 34, PALETTE["monitor_shadow"])
    rect(draw, ox + 46, oy + 10, 36, 30, PALETTE["monitor"])
    rect(draw, ox + 49, oy + 14, 30, 20, PALETTE["screen"])
    rect(draw, ox + 47, oy + 37, 34, 4, (205, 211, 212, 255))
    dot(draw, ox + 75, oy + 38, PALETTE["monitor_dark"], size=2)
    dot(draw, ox + 70, oy + 38, (109, 116, 119, 255), size=2)
    rect(draw, ox + 60, oy + 42, 9, 5, PALETTE["monitor_dark"])
    rect(draw, ox + 55, oy + 47, 19, 2, PALETTE["monitor_shadow"])
    draw_screen_code(draw, ox, oy, row, frame)


def draw_agent(draw, ox, oy, row, frame):
    sleepy = row == 4 and frame < 4
    gaming = row == 4 and frame >= 4
    head_bob = 1 if (row == 1 and frame % 2) or (row == 0 and frame in (2, 3, 4)) else 0
    head_drop = 2 if sleepy and frame % 2 else 0
    head_y = head_bob + head_drop
    wave = -11 if row == 3 and frame % 4 in (1, 2) else (-6 if row == 3 and frame % 4 == 3 else 0)
    typing = -2 if row == 1 and frame % 2 == 0 else (2 if row == 1 else 0)
    tool_pulse = frame % 4

    # Chair.
    rect(draw, ox + 39, oy + 101, 50, 17, PALETTE["chair_shadow"])
    rect(draw, ox + 42, oy + 97, 45, 18, PALETTE["chair"])
    rect(draw, ox + 46, oy + 99, 11, 2, (171, 220, 176, 255))
    rect(draw, ox + 72, oy + 99, 9, 2, (171, 220, 176, 255))
    rect(draw, ox + 50, oy + 114, 6, 7, (97, 70, 85, 255))
    rect(draw, ox + 72, oy + 114, 6, 7, (97, 70, 85, 255))

    # Hair/head silhouette, seen from behind.
    rect(draw, ox + 45, oy + 52 + head_y, 38, 9, PALETTE["outline"])
    rect(draw, ox + 42, oy + 60 + head_y, 44, 22, PALETTE["outline"])
    rect(draw, ox + 47, oy + 54 + head_y, 34, 32, PALETTE["hair"])
    rect(draw, ox + 50, oy + 57 + head_y, 8, 4, PALETTE["hair_hi"])
    rect(draw, ox + 63, oy + 55 + head_y, 5, 5, PALETTE["hair_hi"])
    rect(draw, ox + 74, oy + 62 + head_y, 4, 14, (12, 13, 16, 255))
    rect(draw, ox + 48, oy + 80 + head_y, 32, 7, (15, 15, 18, 255))

    # Tiny headset/agent accent.
    rect(draw, ox + 41, oy + 66 + head_y, 4, 8, (55, 69, 84, 255))
    rect(draw, ox + 83, oy + 66 + head_y, 4, 8, (55, 69, 84, 255))
    dot(draw, ox + 84, oy + 70 + head_y, PALETTE["screen_blue"], size=2)

    # Body and clothes.
    rect(draw, ox + 47, oy + 79, 34, 29, PALETTE["outline"])
    rect(draw, ox + 49, oy + 80, 30, 27, PALETTE["shirt_shadow"])
    rect(draw, ox + 53, oy + 79, 22, 28, PALETTE["shirt"])
    rect(draw, ox + 57, oy + 82, 5, 20, PALETTE["shirt_hi"])
    rect(draw, ox + 66, oy + 83, 2, 20, (133, 57, 31, 255))
    dot(draw, ox + 70, oy + 88, PALETTE["screen_bright"], size=2)
    rect(draw, ox + 48, oy + 106, 32, 7, PALETTE["pants"])
    rect(draw, ox + 54, oy + 108, 7, 3, (84, 103, 158, 255))

    # Arms.
    left_y = 81 + wave
    right_y = 81 + (wave // 3)
    if gaming:
        left_y += 3
        right_y += 3
    rect(draw, ox + 35 + typing, oy + left_y, 13, 7, PALETTE["hood_shadow"])
    rect(draw, ox + 38 + typing, oy + left_y + 2, 11, 6, PALETTE["hood"])
    rect(draw, ox + 80 - typing, oy + right_y, 13, 7, PALETTE["hood_shadow"])
    rect(draw, ox + 79 - typing, oy + right_y + 2, 11, 6, PALETTE["hood"])
    if row == 3:
        dot(draw, ox + 37 + typing, oy + left_y - 3, (246, 196, 130, 255), size=3)
    else:
        dot(draw, ox + 43 + typing, oy + left_y + 7, (246, 196, 130, 255), size=2)
        dot(draw, ox + 84 - typing, oy + right_y + 7, (246, 196, 130, 255), size=2)

    if row == 2:
        # Tool/thinking state: orbiting thought pixels around the agent.
        dots = [(34, 55), (92, 57), (35, 90), (94, 88)]
        x, y = dots[tool_pulse]
        dot(draw, ox + x, oy + y, PALETTE["spark"], size=2)
        dot(draw, ox + 99 - x // 2, oy + 48 + tool_pulse * 2, PALETTE["screen_blue"], size=1)

    if row == 3:
        dot(draw, ox + 32, oy + 63 + frame % 2, PALETTE["spark"], size=2)
        dot(draw, ox + 93, oy + 72 - frame % 2, PALETTE["spark"], size=2)
        dot(draw, ox + 36, oy + 74, PALETTE["screen_blue"], size=1)

    if sleepy:
        rect(draw, ox + 86, oy + 66, 5, 2, PALETTE["sleep"])
        rect(draw, ox + 89, oy + 64, 2, 2, PALETTE["sleep"])
        rect(draw, ox + 86, oy + 62, 5, 2, PALETTE["sleep"])
        rect(draw, ox + 95, oy + 58, 8, 2, PALETTE["sleep"])
        rect(draw, ox + 101, oy + 55, 2, 3, PALETTE["sleep"])
        rect(draw, ox + 95, oy + 52, 8, 2, (235, 241, 255, 190))
        rect(draw, ox + 106, oy + 47, 9, 2, (235, 241, 255, 160))
        rect(draw, ox + 113, oy + 44, 2, 3, (235, 241, 255, 160))
        rect(draw, ox + 106, oy + 41, 9, 2, (235, 241, 255, 130))
    elif gaming:
        rect(draw, ox + 43, oy + 90, 13, 5, (45, 49, 60, 255))
        dot(draw, ox + 46, oy + 91, PALETTE["screen_blue"], size=1)
        dot(draw, ox + 52, oy + 91, PALETTE["screen_yellow"], size=1)


def draw_frame(draw, ox, oy, row, frame):
    draw_desk(draw, ox, oy)
    draw_monitor(draw, ox, oy, row, frame)

    # Steam is behind the head, but in front of the desk.
    if row in (0, 4) and frame % 2 == 0:
        rect(draw, ox + 90, oy + 46, 1, 3, PALETTE["steam"])
        rect(draw, ox + 93, oy + 43, 1, 3, (255, 255, 255, 120))

    draw_agent(draw, ox, oy, row, frame)


def main():
    image = Image.new("RGBA", (FRAME * COLS, FRAME * ROWS), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    for row in range(ROWS):
        for frame in range(COLS):
            draw_frame(draw, frame * FRAME, row * FRAME, row, frame)
    OUT.parent.mkdir(parents=True, exist_ok=True)
    image.save(OUT)
    print(OUT)


if __name__ == "__main__":
    main()
