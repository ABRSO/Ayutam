#!/usr/bin/env bash
# Package the Flutter Linux release bundle as an amd64 .deb.
# Usage: tool/package_linux_deb.sh <version> [bundle_dir]
# Example: tool/package_linux_deb.sh 0.4.0 build/linux/x64/release/bundle
set -euo pipefail

VERSION="${1:?version required (e.g. 0.4.0)}"
BUNDLE="${2:-build/linux/x64/release/bundle}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
STAGE="${ROOT}/dist/linux/ayutam_${VERSION}_amd64"
OUT_DIR="${ROOT}/dist/linux"

if [[ ! -d "${BUNDLE}" ]]; then
  echo "error: bundle not found: ${BUNDLE}" >&2
  exit 1
fi
if [[ ! -x "${BUNDLE}/ayutam" ]]; then
  echo "error: missing executable ${BUNDLE}/ayutam" >&2
  exit 1
fi

rm -rf "${STAGE}"
mkdir -p \
  "${STAGE}/DEBIAN" \
  "${STAGE}/usr/bin" \
  "${STAGE}/usr/lib/ayutam" \
  "${STAGE}/usr/share/applications" \
  "${STAGE}/usr/share/doc/ayutam" \
  "${STAGE}/usr/share/icons/hicolor/256x256/apps"

ICON_SRC="${ROOT}/linux/runner/resources/ayutam.png"
if [[ ! -f "${ICON_SRC}" ]]; then
  echo "error: missing application icon ${ICON_SRC}" >&2
  exit 1
fi

# App bundle lives under /usr/lib/ayutam; PATH entry is a tiny wrapper.
cp -a "${BUNDLE}/." "${STAGE}/usr/lib/ayutam/"
cat > "${STAGE}/usr/bin/ayutam" <<'EOF'
#!/bin/sh
exec /usr/lib/ayutam/ayutam "$@"
EOF
chmod 755 "${STAGE}/usr/bin/ayutam"
chmod 755 "${STAGE}/usr/lib/ayutam/ayutam"

cp "${ICON_SRC}" "${STAGE}/usr/share/icons/hicolor/256x256/apps/ayutam.png"

cat > "${STAGE}/usr/share/applications/ayutam.desktop" <<EOF
[Desktop Entry]
Name=Ayutam
Comment=Local-first skill practice tracker
Exec=ayutam
Icon=ayutam
Terminal=false
Type=Application
Categories=Utility;Education;
StartupWMClass=ayutam
EOF

cp "${ROOT}/LICENSE" "${STAGE}/usr/share/doc/ayutam/copyright"
gzip -9 -c > "${STAGE}/usr/share/doc/ayutam/changelog.gz" <<EOF
ayutam (${VERSION}) unstable; urgency=low

  * Packaged from GitHub Release v${VERSION}.

 -- Ayutam maintainers <noreply@users.noreply.github.com>  $(date -Ru)
EOF

# Installed size in KiB for the control file.
SIZE_KB="$(du -sk "${STAGE}" | awk '{print $1}')"

cat > "${STAGE}/DEBIAN/control" <<EOF
Package: ayutam
Version: ${VERSION}
Section: utils
Priority: optional
Architecture: amd64
Maintainer: Ayutam maintainers <noreply@users.noreply.github.com>
Installed-Size: ${SIZE_KB}
Depends: libgtk-3-0, liblzma5, libstdc++6, hicolor-icon-theme
Homepage: https://github.com/ABRSO/Ayutam
Description: Local-first skill practice tracker
 Ayutam tracks deliberate practice with a timer, Learning Log and statistics.
 Data stays on device; no accounts or automatic cloud sync.
EOF

cat > "${STAGE}/DEBIAN/postinst" <<'EOF'
#!/bin/sh
set -e
if command -v gtk-update-icon-cache >/dev/null 2>&1; then
  gtk-update-icon-cache -f -t /usr/share/icons/hicolor >/dev/null 2>&1 || true
fi
EOF
chmod 755 "${STAGE}/DEBIAN/postinst"

cat > "${STAGE}/DEBIAN/postrm" <<'EOF'
#!/bin/sh
set -e
if [ "$1" = "remove" ] || [ "$1" = "purge" ]; then
  if command -v gtk-update-icon-cache >/dev/null 2>&1; then
    gtk-update-icon-cache -f -t /usr/share/icons/hicolor >/dev/null 2>&1 || true
  fi
fi
EOF
chmod 755 "${STAGE}/DEBIAN/postrm"

mkdir -p "${OUT_DIR}"
dpkg-deb --root-owner-group --build "${STAGE}" "${OUT_DIR}/ayutam-v${VERSION}-linux-amd64.deb"
echo "Wrote ${OUT_DIR}/ayutam-v${VERSION}-linux-amd64.deb"
