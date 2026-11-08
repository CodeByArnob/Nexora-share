#!/usr/bin/env bash
# ==============================================================================
# NEXORA Debian (.deb) Packaging Script
# CONNECT. SHARE. ANYWHERE.
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
DESKTOP_DIR="${ROOT_DIR}/apps/desktop"
BUILD_DIR="${DESKTOP_DIR}/build/linux/x64/release/bundle"
DIST_DIR="${ROOT_DIR}/dist"
PKG_VERSION="1.1.0"
DEB_DIR="${DIST_DIR}/nexora_${PKG_VERSION}_amd64"

echo "=== [NEXORA] Building Linux Desktop Release Bundle ==="
cd "${DESKTOP_DIR}"
flutter build linux --release

if [ ! -d "${BUILD_DIR}" ]; then
  echo "Error: Release bundle not found at ${BUILD_DIR}"
  exit 1
fi

echo "=== [NEXORA] Staging Debian Package Files ==="
rm -rf "${DEB_DIR}"
mkdir -p "${DEB_DIR}/DEBIAN"
mkdir -p "${DEB_DIR}/opt/nexora"
mkdir -p "${DEB_DIR}/usr/bin"
mkdir -p "${DEB_DIR}/usr/share/applications"
mkdir -p "${DEB_DIR}/usr/share/metainfo"
mkdir -p "${DEB_DIR}/usr/share/icons/hicolor/scalable/apps"

# Copy binary & bundle to /opt/nexora
cp -r "${BUILD_DIR}/"* "${DEB_DIR}/opt/nexora/"

# Create symlink launcher in /usr/bin
cat << 'EOF' > "${DEB_DIR}/usr/bin/nexora"
#!/bin/sh
exec /opt/nexora/nexora "$@"
EOF
chmod +x "${DEB_DIR}/usr/bin/nexora"

# Copy integration assets
cp "${DESKTOP_DIR}/linux/packaging/io.github.codebyarnob.nexora.desktop" "${DEB_DIR}/usr/share/applications/"
cp "${DESKTOP_DIR}/linux/packaging/io.github.codebyarnob.nexora.metainfo.xml" "${DEB_DIR}/usr/share/metainfo/"
cp "${DESKTOP_DIR}/linux/packaging/icons/io.github.codebyarnob.nexora.svg" "${DEB_DIR}/usr/share/icons/hicolor/scalable/apps/"

# Create control file
cat << EOF > "${DEB_DIR}/DEBIAN/control"
Package: nexora
Version: ${PKG_VERSION}
Section: net
Priority: optional
Architecture: amd64
Maintainer: Arnob <codebyarnob@users.noreply.github.com>
Depends: libc6, libgtk-3-0, liblzma5
Description: NEXORA - Private Peer-to-Peer File Sharing Platform
 Fast, private, cross-platform file sharing without cloud reliance.
 Connects Android, Windows, and Linux devices over local area networks.
EOF

echo "=== [NEXORA] Building .deb Package ==="
dpkg-deb --build --root-owner-group "${DEB_DIR}" "${DIST_DIR}/nexora_${PKG_VERSION}_amd64.deb"
echo "Debian package created at ${DIST_DIR}/nexora_${PKG_VERSION}_amd64.deb"
