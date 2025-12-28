#!/bin/bash
set -euo pipefail

# AppImage build script
# Requires: appimage-builder, Flutter SDK

VERSION="${1:-$(git describe --tags --always | sed 's/^v//')}"
ARCH="${2:-x86_64}"

echo "=========================================="
echo "Building AppImage"
echo "Version: ${VERSION}"
echo "Architecture: ${ARCH}"
echo "=========================================="

# Check for appimage-builder
if ! command -v appimage-builder &> /dev/null; then
    echo "ERROR: appimage-builder not found" >&2
    echo "Install with: pip3 install appimage-builder" >&2
    exit 1
fi

# Check for Flutter
if ! command -v flutter &> /dev/null; then
    echo "ERROR: Flutter SDK not found" >&2
    echo "Please install Flutter: https://flutter.dev/docs/get-started/install" >&2
    exit 1
fi

# Build Flutter application
echo ""
echo "Building Flutter Linux application..."
flutter build linux --release

# Create AppDir structure
echo ""
echo "Creating AppDir structure..."
rm -rf AppDir
mkdir -p AppDir/usr/{bin,lib,share/applications,share/icons/hicolor/512x512/apps}

# Copy Flutter bundle
echo "Copying Flutter bundle..."
cp -r build/linux/x64/release/bundle/* AppDir/usr/

# Create symlink for executable
ln -sf ../quran_hadith AppDir/usr/bin/quran_hadith

# Copy desktop file
echo "Installing desktop file..."
cp packaging/common/quran-hadith.desktop AppDir/usr/share/applications/

# Copy icon
echo "Installing icon..."
cp packaging/common/icons/quran-hadith-512.png AppDir/usr/share/icons/hicolor/512x512/apps/quran-hadith.png

# Copy AppRun launcher
echo "Installing AppRun launcher..."
cp packaging/appimage/AppRun AppDir/
chmod +x AppDir/AppRun

# Build AppImage
echo ""
echo "Building AppImage with appimage-builder..."
export VERSION="${VERSION}"
export ARCH="${ARCH}"

# Change to packaging/appimage directory for build
cd packaging/appimage
appimage-builder --recipe AppImageBuilder.yml --skip-test

# Move back and rename output
cd ../..
if [ -f packaging/appimage/*.AppImage ]; then
    mv packaging/appimage/*.AppImage "quran-hadith-${VERSION}-${ARCH}.AppImage"
else
    echo "WARNING: AppImage not found in expected location"
    find packaging/appimage -name "*.AppImage" -exec mv {} "quran-hadith-${VERSION}-${ARCH}.AppImage" \;
fi

# Make executable
chmod +x "quran-hadith-${VERSION}-${ARCH}.AppImage"

echo ""
echo "=========================================="
echo "AppImage built successfully!"
echo "Output: quran-hadith-${VERSION}-${ARCH}.AppImage"
echo ""
echo "To run:"
echo "  ./quran-hadith-${VERSION}-${ARCH}.AppImage"
echo "=========================================="
