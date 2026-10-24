#!/usr/bin/env bash
set -euo pipefail

VERSION="${1:-1.0.0}"
ARCH="amd64"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
BUNDLE_DIR="$ROOT_DIR/build/linux/x64/release/bundle"
DIST_DIR="$ROOT_DIR/dist"
PKG_DIR="$ROOT_DIR/build/deb_pkg/fblocker_${VERSION}_${ARCH}"

echo "==> Building Debian Package for Finora Fblocker v${VERSION} (${ARCH})..."

if [ ! -d "$BUNDLE_DIR" ]; then
  echo "Error: Flutter release bundle not found at $BUNDLE_DIR"
  echo "Run: flutter build linux --release"
  exit 1
fi

rm -rf "$PKG_DIR"
mkdir -p "$PKG_DIR/DEBIAN"
mkdir -p "$PKG_DIR/opt/finora-fblocker"
mkdir -p "$PKG_DIR/usr/bin"
mkdir -p "$PKG_DIR/usr/share/applications"
mkdir -p "$PKG_DIR/usr/share/icons/hicolor/256x256/apps"
mkdir -p "$DIST_DIR"

# Copy binary bundle
cp -r "$BUNDLE_DIR"/* "$PKG_DIR/opt/finora-fblocker/"

# Wrapper executable in /usr/bin/fblocker
cat << 'EOF' > "$PKG_DIR/usr/bin/fblocker"
#!/bin/sh
exec /opt/finora-fblocker/fblocker "$@"
EOF
chmod +x "$PKG_DIR/usr/bin/fblocker"

# Desktop file
cp "$ROOT_DIR/packaging/linux/finora-fblocker.desktop" "$PKG_DIR/usr/share/applications/fblocker.desktop"

# Icon
if [ -f "$ROOT_DIR/packaging/linux/fblocker.png" ]; then
  cp "$ROOT_DIR/packaging/linux/fblocker.png" "$PKG_DIR/usr/share/icons/hicolor/256x256/apps/fblocker.png"
fi

# Debian Control file
cat << EOF > "$PKG_DIR/DEBIAN/control"
Package: fblocker
Version: ${VERSION}
Section: net
Priority: optional
Architecture: ${ARCH}
Maintainer: Finora <support@finora.network>
Installed-Size: $(du -sk "$PKG_DIR" | cut -f1)
Depends: libc6, libgtk-3-0, libglib2.0-0
Homepage: https://github.com/Finoraaa/Fblocker
Description: Finora Fblocker - Cyber Ad & Tracker Blocker
 High-performance cross-platform ad and tracker blocker designed by Finora.
 Features DNS-level filtering, real-time cyber protection and telemetry shielding.
EOF

# Build DEB
dpkg-deb --build --root-owner-group "$PKG_DIR" "$DIST_DIR/fblocker-linux-amd64.deb"

echo "==> Successfully created $DIST_DIR/fblocker-linux-amd64.deb"
