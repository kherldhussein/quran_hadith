#!/usr/bin/env bash
set -euo pipefail

# Enhanced DEB package builder
# Follows Debian packaging standards with lintian compliance

# Configuration
APP_ID="quran-hadith"
APP_EXEC="quran_hadith"
VERSION="${1:-$(git describe --tags --always | sed 's/^v//')}"
ARCH="${2:-amd64}"
BUILD_DIR="build/linux/x64/release/bundle"

echo "=========================================="
echo "Building DEB package"
echo "Version: ${VERSION}"
echo "Architecture: ${ARCH}"
echo "=========================================="

# Build Flutter application if bundle doesn't exist
if [[ ! -d "$BUILD_DIR" ]]; then
    echo ""
    echo "Bundle directory not found. Building Flutter application..."
    echo ""

    # Install dependencies
    flutter pub get

    # Build for Linux
    flutter build linux --release

    if [[ ! -d "$BUILD_DIR" ]]; then
        echo "ERROR: Flutter build failed - bundle still not found at $BUILD_DIR" >&2
        exit 1
    fi

    echo ""
    echo "Flutter build completed successfully!"
    echo ""
fi

# Create staging directory
STAGING_ROOT="build/deb"
STAGING="$STAGING_ROOT/${APP_ID}_${VERSION}_${ARCH}"
rm -rf "$STAGING"
mkdir -p "$STAGING/DEBIAN"
mkdir -p "$STAGING/usr/bin"
mkdir -p "$STAGING/usr/share/applications"
mkdir -p "$STAGING/usr/share/icons/hicolor/512x512/apps"
mkdir -p "$STAGING/usr/share/doc/${APP_ID}"
mkdir -p "$STAGING/opt/${APP_ID}"

echo ""
echo "Copying application bundle..."
cp -r "$BUILD_DIR"/* "$STAGING/opt/${APP_ID}/"

echo "Creating symlink..."
ln -sf "/opt/${APP_ID}/${APP_EXEC}" "$STAGING/usr/bin/${APP_ID}"

echo "Installing desktop file..."
cp packaging/common/quran-hadith.desktop "$STAGING/usr/share/applications/${APP_ID}.desktop"

echo "Installing icon..."
if [[ -f packaging/common/icons/quran-hadith-512.png ]]; then
    cp packaging/common/icons/quran-hadith-512.png "$STAGING/usr/share/icons/hicolor/512x512/apps/${APP_ID}.png"
else
    echo "WARNING: Icon not found at packaging/common/icons/quran-hadith-512.png" >&2
fi

echo "Installing documentation..."
cp README.md "$STAGING/usr/share/doc/${APP_ID}/"
cp packaging/deb/changelog "$STAGING/usr/share/doc/${APP_ID}/changelog.Debian"
gzip -9 "$STAGING/usr/share/doc/${APP_ID}/changelog.Debian"
cp packaging/deb/copyright "$STAGING/usr/share/doc/${APP_ID}/"

echo ""
echo "Calculating installed size..."
INSTALLED_SIZE=$(du -sk "$STAGING/opt/${APP_ID}" | cut -f1)

echo "Generating control file..."
export VERSION ARCH INSTALLED_SIZE
envsubst < packaging/deb/control.template > "$STAGING/DEBIAN/control"

echo "Installing maintainer scripts..."
cp packaging/deb/postinst "$STAGING/DEBIAN/postinst"
cp packaging/deb/postrm "$STAGING/DEBIAN/postrm"
chmod 0755 "$STAGING/DEBIAN/postinst" "$STAGING/DEBIAN/postrm"

echo "Setting permissions..."
find "$STAGING" -type d -exec chmod 0755 {} \;
find "$STAGING/opt/${APP_ID}" -type f -executable -exec chmod 0755 {} \;

echo ""
echo "Building DEB package..."
dpkg-deb --build --root-owner-group "$STAGING" "${APP_ID}_${VERSION}_${ARCH}.deb"

echo ""
echo "Running lintian checks..."
if command -v lintian >/dev/null 2>&1; then
    lintian --no-tag-display-limit "${APP_ID}_${VERSION}_${ARCH}.deb" || true
else
    echo "WARNING: lintian not found, skipping package validation"
fi

echo ""
echo "=========================================="
echo "DEB package built successfully!"
echo "Output: ${APP_ID}_${VERSION}_${ARCH}.deb"
echo ""
echo "To install:"
echo "  sudo dpkg -i ${APP_ID}_${VERSION}_${ARCH}.deb"
echo "  sudo apt-get install -f  # Install dependencies"
echo ""
echo "To test:"
echo "  dpkg-deb --info ${APP_ID}_${VERSION}_${ARCH}.deb"
echo "  dpkg-deb --contents ${APP_ID}_${VERSION}_${ARCH}.deb"
echo "=========================================="
