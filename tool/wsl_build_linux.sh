#!/usr/bin/env bash
set -euo pipefail
export PATH="$HOME/flutter/bin:$PATH"
export DISPLAY="${DISPLAY:-:0}"
export WAYLAND_DISPLAY="${WAYLAND_DISPLAY:-wayland-0}"
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/mnt/wslg/runtime-dir}"
cd /mnt/c/Project/Ayutam
flutter pub get
flutter build linux --debug
echo "LINUX_BUILD_EXIT=$?"
# Brief GUI smoke: launch and kill after a few seconds if binary exists
BIN="build/linux/x64/debug/bundle/ayutam"
if [ -x "$BIN" ]; then
  "$BIN" > /tmp/ayutam-linux-run.log 2>&1 &
  PID=$!
  sleep 5
  if kill -0 "$PID" 2>/dev/null; then
    echo "LINUX_SMOKE_RUNNING pid=$PID"
    kill "$PID" 2>/dev/null || true
    wait "$PID" 2>/dev/null || true
    echo "LINUX_SMOKE_OK"
  else
    echo "LINUX_SMOKE_EXITED_EARLY"
    cat /tmp/ayutam-linux-run.log || true
  fi
else
  echo "LINUX_BINARY_MISSING"
fi
