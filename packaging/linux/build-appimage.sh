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

# Check if appimagetool exists or download if in CI
APPIMAGETOOL=""
if command -v appimagetool >/dev/null 2>&1; then
  APPIMAGETOOL="appimagetool"
elif [ -f "$ROOT_DIR/build/appimagetool" ]; then
  APPIMAGETOOL="$ROOT_DIR/build/appimagetool"
fi

if [ -n "$APPIMAGETOOL" ]; then
  echo "==> Generating AppImage with $APPIMAGETOOL..."
  ARCH=x86_64 "$APPIMAGETOOL" "$APPDIR" "$DIST_DIR/Fblocker-linux-x86_64.AppImage"
  chmod +x "$DIST_DIR/Fblocker-linux-x86_64.AppImage"
  echo "==> Successfully created $DIST_DIR/Fblocker-linux-x86_64.AppImage"
else
  echo "Notice: appimagetool not found on host. In GitHub Actions, appimagetool is automatically downloaded to produce Fblocker-linux-x86_64.AppImage."
fi
