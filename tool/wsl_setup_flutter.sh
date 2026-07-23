#!/usr/bin/env bash
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive
# Requires a sudo-capable WSL user (password prompted if needed).
sudo apt-get update -qq
sudo apt-get install -y -qq \
  curl git unzip xz-utils zip libglu1-mesa \
  clang cmake ninja-build pkg-config \
  libgtk-3-dev liblzma-dev libstdc++-12-dev \
  mesa-utils
if [ ! -x "$HOME/flutter/bin/flutter" ]; then
  echo "Cloning Flutter stable into ~/flutter ..."
  git clone https://github.com/flutter/flutter.git -b stable --depth 1 "$HOME/flutter"
fi
export PATH="$HOME/flutter/bin:$PATH"
export DISPLAY="${DISPLAY:-:0}"
export WAYLAND_DISPLAY="${WAYLAND_DISPLAY:-wayland-0}"
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/mnt/wslg/runtime-dir}"
flutter --version
flutter config --enable-linux-desktop
flutter doctor || true
echo WSL_FLUTTER_SETUP_DONE
