from PIL import Image, ImageDraw
import math
import os

root = r'D:\android stdio works\games\cook_sense\assets'
src = Image.open(os.path.join(root, 'splash', 'splash_logo_original.png')).convert('RGBA')
w, h = src.size
px = src.load()

# Estimate circle from terracotta pixels
xs, ys = [], []
for y in range(h):
    for x in range(w):
        r, g, b, a = px[x, y]
        if a < 20:
            continue
        if 120 < r < 230 and 40 < g < 150 and 20 < b < 110 and r > g + 20 and r > b + 30:
            xs.append(x)
            ys.append(y)

cx = (min(xs) + max(xs)) / 2
cy = (min(ys) + max(ys)) / 2
radius = min(max(xs) - min(xs), max(ys) - min(ys)) / 2
print(f'circle center=({cx:.1f},{cy:.1f}) radius={radius:.1f}')

# Extract cream monogram ONLY inside inner safe radius (exclude rim ring)
inner_limit = radius * 0.82
mono = Image.new('RGBA', (w, h), (0, 0, 0, 0))
mp = mono.load()
kept = 0
for y in range(h):
    for x in range(w):
        r, g, b, a = px[x, y]
        if a < 20:
            continue
        dist = math.hypot(x - cx, y - cy)
        if dist > inner_limit:
            continue
        # cream / off-white strokes
        if r > 205 and g > 190 and b > 170 and (r + g + b) > 600:
            mp[x, y] = (255, 255, 255, 255)
            kept += 1

bbox = mono.getbbox()
print('kept', kept, 'bbox', bbox)
cropped = mono.crop(bbox)
cw, ch = cropped.size

out = 1024
cream = (249, 246, 242, 255)
terra = (168, 92, 65, 255)  # #A85C41

# --- Standard splash (pre Android 12): cream bg + circle + padded mark ---
splash = Image.new('RGBA', (out, out), cream)
draw = ImageDraw.Draw(splash)
# Circle with ~12% outer margin
circle_pad = int(out * 0.12)
draw.ellipse((circle_pad, circle_pad, out - circle_pad, out - circle_pad), fill=terra)

# Subtle inner ring, kept away from the monogram
ring_pad = int(out * 0.16)
draw.ellipse(
    (ring_pad, ring_pad, out - ring_pad, out - ring_pad),
    outline=cream,
    width=max(3, out // 220),
)

# Monogram at ~48% of canvas => clear gap from circle/ring
target = int(out * 0.48)
scale = target / max(cw, ch)
nw, nh = max(1, int(cw * scale)), max(1, int(ch * scale))
mark = cropped.resize((nw, nh), Image.Resampling.LANCZOS)
# tint mark to cream
tinted = Image.new('RGBA', mark.size, (0, 0, 0, 0))
tp, mp2 = tinted.load(), mark.load()
for y in range(nh):
    for x in range(nw):
        if mp2[x, y][3] > 20:
            tp[x, y] = (249, 246, 242, 255)
splash.alpha_composite(tinted, ((out - nw) // 2, (out - nh) // 2))
splash_path = os.path.join(root, 'splash', 'splash_logo.png')
splash.save(splash_path)
print('wrote', splash_path)

# --- Android 12 adaptive splash icon ---
# Transparent bg + white mark only; terracotta comes from icon_background_color
a12 = Image.new('RGBA', (out, out), (0, 0, 0, 0))
# Android 12 safe zone is center ~66%; keep mark ~42% for breathing room
target12 = int(out * 0.42)
scale12 = target12 / max(cw, ch)
nw12, nh12 = max(1, int(cw * scale12)), max(1, int(ch * scale12))
mark12 = cropped.resize((nw12, nh12), Image.Resampling.LANCZOS)
white = Image.new('RGBA', mark12.size, (0, 0, 0, 0))
wp, m12 = white.load(), mark12.load()
for y in range(nh12):
    for x in range(nw12):
        if m12[x, y][3] > 20:
            wp[x, y] = (255, 255, 255, 255)
a12.alpha_composite(white, ((out - nw12) // 2, (out - nh12) // 2))
a12_path = os.path.join(root, 'splash', 'splash_android12.png')
a12.save(a12_path)
print('wrote', a12_path)
print('done')
