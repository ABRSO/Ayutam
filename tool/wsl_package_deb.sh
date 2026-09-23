#!/usr/bin/env bash
# Build the release Linux bundle, .deb and tarball from this Windows checkout
# inside WSL. Sources are copied to the Linux filesystem first so WSL's
# `flutter pub get` never rewrites the Windows checkout's .dart_tool.
#
# Usage (Windows PowerShell, repo root):  wsl bash tool/wsl_package_deb.sh
# Output: dist/linux/ayutam-v<version>-linux-amd64.deb (+ -linux-x64.tar.gz)
set -euo pipefail
export PATH="$HOME/flutter/bin:$PATH"

SRC="$(cd "$(dirname "$0")/.." && pwd)"
WORK="${AYUTAM_WSL_WORKDIR:-$HOME/ayutam-build}"
VERSION="$(sed -n 's/^version: *\([0-9.]*\).*/\1/p' "$SRC/pubspec.yaml")"

for cmd in flutter rsync dpkg-deb pkg-config; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "error: $cmd not found; run tool/wsl_setup_flutter.sh first" >&2
    exit 1
  fi
done
if ! pkg-config --exists ayatana-appindicator3-0.1 &&
  ! pkg-config --exists appindicator3-0.1; then
  echo "error: sudo apt install libayatana-appindicator3-dev" >&2
  exit 1
fi

mkdir -p "$WORK"
rsync -a --delete \
  --exclude build --exclude .dart_tool --exclude dist --exclude .git \
  --exclude 'android/.gradle' --exclude 'android/app/build' \
  "$SRC/" "$WORK/"
cd "$WORK"
flutter pub get
flutter build linux --release
tool/package_linux_deb.sh "$VERSION" build/linux/x64/release/bundle

mkdir -p "$SRC/dist/linux"
cp "dist/linux/ayutam-v${VERSION}-linux-amd64.deb" "$SRC/dist/linux/"
tar -czf "$SRC/dist/linux/ayutam-v${VERSION}-linux-x64.tar.gz" \
  -C build/linux/x64/release/bundle .
echo "Wrote $SRC/dist/linux/ayutam-v${VERSION}-linux-amd64.deb"
echo "Wrote $SRC/dist/linux/ayutam-v${VERSION}-linux-x64.tar.gz"
