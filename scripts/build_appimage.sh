#!/usr/bin/env bash
# ==============================================================================
# NEXORA AppImage Packaging Script
# CONNECT. SHARE. ANYWHERE.
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
DESKTOP_DIR="${ROOT_DIR}/apps/desktop"
BUILD_DIR="${DESKTOP_DIR}/build/linux/x64/release/bundle"
DIST_DIR="${ROOT_DIR}/dist"
APP_DIR="${DIST_DIR}/AppDir"

echo "=== [NEXORA] Building Linux Desktop Release Bundle ==="
cd "${DESKTOP_DIR}"
flutter build linux --release

if [ ! -d "${BUILD_DIR}" ]; then
  echo "Error: Release bundle not found at ${BUILD_DIR}"
  exit 1
fi

echo "=== [NEXORA] Preparing AppDir Structure ==="
rm -rf "${APP_DIR}"
mkdir -p "${APP_DIR}/usr/bin"
mkdir -p "${APP_DIR}/usr/share/applications"
mkdir -p "${APP_DIR}/usr/share/metainfo"
mkdir -p "${APP_DIR}/usr/share/icons/hicolor/scalable/apps"

# Copy binary, lib, and data bundle
cp -r "${BUILD_DIR}/nexora" "${APP_DIR}/usr/bin/"
cp -r "${BUILD_DIR}/lib" "${APP_DIR}/usr/bin/"
cp -r "${BUILD_DIR}/data" "${APP_DIR}/usr/bin/"

# Copy desktop and metadata
cp "${DESKTOP_DIR}/linux/packaging/io.github.codebyarnob.nexora.desktop" "${APP_DIR}/usr/share/applications/"
cp "${DESKTOP_DIR}/linux/packaging/io.github.codebyarnob.nexora.desktop" "${APP_DIR}/io.github.codebyarnob.nexora.desktop"
cp "${DESKTOP_DIR}/linux/packaging/io.github.codebyarnob.nexora.metainfo.xml" "${APP_DIR}/usr/share/metainfo/"
cp "${DESKTOP_DIR}/linux/packaging/icons/io.github.codebyarnob.nexora.svg" "${APP_DIR}/usr/share/icons/hicolor/scalable/apps/"
cp "${DESKTOP_DIR}/linux/packaging/icons/io.github.codebyarnob.nexora.svg" "${APP_DIR}/io.github.codebyarnob.nexora.svg"

# Copy AppRun
cp "${ROOT_DIR}/packaging/appimage/AppRun" "${APP_DIR}/AppRun"
chmod +x "${APP_DIR}/AppRun"
chmod +x "${APP_DIR}/usr/bin/nexora"

# Create standard AppDir symlinks
ln -sf io.github.codebyarnob.nexora.desktop "${APP_DIR}/nexora.desktop"
ln -sf io.github.codebyarnob.nexora.svg "${APP_DIR}/nexora.svg"

echo "=== [NEXORA] AppDir Built Successfully at ${APP_DIR} ==="

if command -v appimagetool >/dev/null 2>&1; then
  echo "=== [NEXORA] Packaging into AppImage ==="
  ARCH=x86_64 appimagetool "${APP_DIR}" "${DIST_DIR}/NEXORA-x86_64.AppImage"
  echo "AppImage created at ${DIST_DIR}/NEXORA-x86_64.AppImage"
else
  echo "Notice: 'appimagetool' not in PATH. Download appimagetool to generate final single-file AppImage."
fi
