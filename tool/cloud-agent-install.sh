#!/usr/bin/env bash
# Idempotent Cloud Agent bootstrap for Ayutam (Linux).
# Pins Flutter to the same version as .github/workflows/validate.yml.
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

FLUTTER_VERSION="3.44.7"
FLUTTER_HOME="${FLUTTER_HOME:-$HOME/flutter}"
FLUTTER_ARCHIVE="flutter_linux_${FLUTTER_VERSION}-stable.tar.xz"
FLUTTER_URL="https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/${FLUTTER_ARCHIVE}"

sudo apt-get update -qq
sudo apt-get install -y --no-install-recommends \
  curl git unzip xz-utils zip libglu1-mesa \
  clang cmake ninja-build pkg-config \
  libgtk-3-dev liblzma-dev libstdc++-12-dev

installed_version=""
if [ -x "$FLUTTER_HOME/bin/flutter" ]; then
  installed_version="$("$FLUTTER_HOME/bin/flutter" --version 2>/dev/null | awk '/^Flutter / { print $2; exit }' || true)"
fi

if [ "$installed_version" != "$FLUTTER_VERSION" ]; then
  echo "Installing Flutter ${FLUTTER_VERSION} into ${FLUTTER_HOME} ..."
  rm -rf "$FLUTTER_HOME"
  tmpdir="$(mktemp -d)"
  trap 'rm -rf "$tmpdir"' EXIT
  curl -fL --retry 3 --retry-delay 5 -o "$tmpdir/$FLUTTER_ARCHIVE" "$FLUTTER_URL"
  tar -xJf "$tmpdir/$FLUTTER_ARCHIVE" -C "$(dirname "$FLUTTER_HOME")"
  rm -rf "$tmpdir"
  trap - EXIT
fi

export PATH="$FLUTTER_HOME/bin:$PATH"

# Non-login Cloud Agent shells still see /usr/local/bin.
sudo ln -sfn "$FLUTTER_HOME/bin/flutter" /usr/local/bin/flutter
sudo ln -sfn "$FLUTTER_HOME/bin/dart" /usr/local/bin/dart
printf 'export PATH="%s/bin:$PATH"\n' "$FLUTTER_HOME" | sudo tee /etc/profile.d/ayutam-flutter.sh >/dev/null
sudo chmod 644 /etc/profile.d/ayutam-flutter.sh

hash -r

flutter config --no-analytics --enable-linux-desktop >/dev/null
flutter --version
flutter pub get
dart run build_runner build --delete-conflicting-outputs
