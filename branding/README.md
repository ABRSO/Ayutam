# Branding

Canonical application artwork lives here.

| File | Role |
|---|---|
| `ayutam-logo.png` | Source launcher icon (square PNG). Used to generate Android mipmaps, the Windows `.ico`, and the Linux 256×256 PNG. |

Regenerate platform icons after replacing the source logo:

```bash
python -m pip install pillow
python tool/generate_app_icons.py
```

Do not put the Flutter default `ic_launcher` / `app_icon.ico` back. Keep generated outputs in git so CI and local builds do not need Pillow.
