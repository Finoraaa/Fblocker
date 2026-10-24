#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
BUNDLE_DIR="$ROOT_DIR/build/linux/x64/release/bundle"
APPDIR="$ROOT_DIR/build/AppDir"
DIST_DIR="$ROOT_DIR/dist"

echo "==> Preparing AppDir for Finora Fblocker..."

if [ ! -d "$BUNDLE_DIR" ]; then
  echo "Error: Flutter release bundle not found at $BUNDLE_DIR"
  echo "Run: flutter build linux --release"
  exit 1
fi

rm -rf "$APPDIR"
mkdir -p "$APPDIR/usr/bin"
mkdir -p "$APPDIR/usr/lib"
mkdir -p "$APPDIR/usr/share/icons/hicolor/256x256/apps"
mkdir -p "$DIST_DIR"

# Copy Flutter application bundle
cp -r "$BUNDLE_DIR"/* "$APPDIR/usr/bin/"

# Top-level desktop entry & icon
cp "$ROOT_DIR/packaging/linux/finora-fblocker.desktop" "$APPDIR/fblocker.desktop"
if [ -f "$ROOT_DIR/packaging/linux/fblocker.png" ]; then
  cp "$ROOT_DIR/packaging/linux/fblocker.png" "$APPDIR/fblocker.png"
  cp "$ROOT_DIR/packaging/linux/fblocker.png" "$APPDIR/.DirIcon"
fi

# AppRun script
cat << 'EOF' > "$APPDIR/AppRun"
#!/bin/sh
SELF=$(readlink -f "$0")
HERE=${SELF%/*}
export PATH="${HERE}/usr/bin:${PATH}"
export LD_LIBRARY_PATH="${HERE}/usr/lib:${HERE}/usr/bin/lib:${LD_LIBRARY_PATH}"
cd "${HERE}/usr/bin"
exec "${HERE}/usr/bin/fblocker" "$@"
EOF
chmod +x "$APPDIR/AppRun"

echo "==> AppDir successfully prepared at $APPDIR"

# Locate or download appimagetool
TOOL_CMD=""
if [ -f "$ROOT_DIR/build/squashfs-root/AppRun" ]; then
  TOOL_CMD="$ROOT_DIR/build/squashfs-root/AppRun"
elif command -v appimagetool >/dev/null 2>&1; then
  TOOL_CMD="appimagetool"
else
  echo "==> Downloading appimagetool..."
  mkdir -p "$ROOT_DIR/build"
  curl -sSL "https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage" -o "$ROOT_DIR/build/appimagetool"
  chmod +x "$ROOT_DIR/build/appimagetool"
  (cd "$ROOT_DIR/build" && ./appimagetool --appimage-extract >/dev/null 2>&1)
  TOOL_CMD="$ROOT_DIR/build/squashfs-root/AppRun"
fi

echo "==> Generating AppImage with $TOOL_CMD..."
ARCH=x86_64 "$TOOL_CMD" "$APPDIR" "$DIST_DIR/Fblocker-linux-x86_64.AppImage"
chmod +x "$DIST_DIR/Fblocker-linux-x86_64.AppImage"
echo "==> Successfully created $DIST_DIR/Fblocker-linux-x86_64.AppImage"
