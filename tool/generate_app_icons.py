#!/usr/bin/env python3
"""Generate Android, Windows, and Linux launcher icons from branding/ayutam-logo.png.

Requires: pip install pillow
"""

from __future__ import annotations

from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "branding" / "ayutam-logo.png"


def resized(src: Image.Image, size: int) -> Image.Image:
    return src.resize((size, size), Image.Resampling.LANCZOS)


def main() -> None:
    if not SRC.is_file():
        raise SystemExit(f"missing source logo: {SRC}")
    src = Image.open(SRC).convert("RGBA")

    android = {
        "mipmap-mdpi": 48,
        "mipmap-hdpi": 72,
        "mipmap-xhdpi": 96,
        "mipmap-xxhdpi": 144,
        "mipmap-xxxhdpi": 192,
    }
    for folder, size in android.items():
        dest = ROOT / "android" / "app" / "src" / "main" / "res" / folder / "ic_launcher.png"
        dest.parent.mkdir(parents=True, exist_ok=True)
        resized(src, size).save(dest, format="PNG")
        print(f"wrote {dest.relative_to(ROOT)}")

    linux_dir = ROOT / "linux" / "runner" / "resources"
    linux_dir.mkdir(parents=True, exist_ok=True)
    linux_icon = linux_dir / "ayutam.png"
    resized(src, 256).save(linux_icon, format="PNG")
    print(f"wrote {linux_icon.relative_to(ROOT)}")

    ico = ROOT / "windows" / "runner" / "resources" / "app_icon.ico"
    ico.parent.mkdir(parents=True, exist_ok=True)
    sizes = [16, 32, 48, 256]
    images = [resized(src, s) for s in sizes]
    images[0].save(
        ico,
        format="ICO",
        sizes=[(s, s) for s in sizes],
        append_images=images[1:],
    )
    print(f"wrote {ico.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
