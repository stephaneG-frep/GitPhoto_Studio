#!/usr/bin/env python3
"""Décline l'icône (tool/icon/out/*.png, rendue par render_icon_test.dart)
aux tailles Android et Linux."""
import pathlib
from PIL import Image

ROOT = pathlib.Path(__file__).resolve().parents[2]
OUT = ROOT / "tool" / "icon" / "out"
full = Image.open(OUT / "icon_full.png").convert("RGBA")
fg = Image.open(OUT / "icon_foreground.png").convert("RGBA")

res = ROOT / "android" / "app" / "src" / "main" / "res"
for density, legacy, adaptive in [
    ("mdpi", 48, 108), ("hdpi", 72, 162), ("xhdpi", 96, 216),
    ("xxhdpi", 144, 324), ("xxxhdpi", 192, 432),
]:
    d = res / f"mipmap-{density}"
    d.mkdir(parents=True, exist_ok=True)
    full.resize((legacy, legacy), Image.LANCZOS).save(d / "ic_launcher.png")
    fg.resize((adaptive, adaptive), Image.LANCZOS).save(d / "ic_launcher_foreground.png")

icons = ROOT / "linux" / "packaging" / "icons"
for size in (48, 64, 128, 256, 512):
    d = icons / f"{size}x{size}"
    d.mkdir(parents=True, exist_ok=True)
    full.resize((size, size), Image.LANCZOS).save(d / "gitphoto-studio.png")

print("icônes générées")
