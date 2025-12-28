#!/bin/bash
set -euo pipefail

# Flatpak build script for local development
# For CI/CD, use flatpak-github-actions

VERSION="${1:-$(git describe --tags --always | sed 's/^v//')}"
ARCH="${2:-$(uname -m)}"

echo "=========================================="
echo "Building Flatpak package"
echo "Version: ${VERSION}"
echo "Architecture: ${ARCH}"
echo "=========================================="

# Check for flatpak-builder
if ! command -v flatpak-builder &> /dev/null; then
    echo "ERROR: flatpak-builder not found" >&2
    echo "Install with: sudo apt install flatpak-builder" >&2
    exit 1
fi

# Check for required runtime
if ! flatpak list --runtime | grep -q "org.freedesktop.Platform.*23.08"; then
    echo "Installing Freedesktop Platform 23.08..."
    flatpak install -y flathub org.freedesktop.Platform//23.08 org.freedesktop.Sdk//23.08
fi

# Build directory
BUILD_DIR="build/flatpak"
REPO_DIR="${BUILD_DIR}/repo"
APP_ID="com.kherld.quran_hadith"

mkdir -p "${BUILD_DIR}" "${REPO_DIR}"

echo ""
echo "Building Flatpak..."
flatpak-builder \
    --force-clean \
    --repo="${REPO_DIR}" \
    --arch="${ARCH}" \
    --install-deps-from=flathub \
    --ccache \
    --verbose \
    "${BUILD_DIR}/build" \
    packaging/flatpak/${APP_ID}.yml

echo ""
echo "Creating bundle..."
flatpak build-bundle \
    "${REPO_DIR}" \
    "quran-hadith-${VERSION}-${ARCH}.flatpak" \
    "${APP_ID}"

echo ""
echo "=========================================="
echo "Flatpak built successfully!"
echo "Output: quran-hadith-${VERSION}-${ARCH}.flatpak"
echo ""
echo "To install locally:"
echo "  flatpak install quran-hadith-${VERSION}-${ARCH}.flatpak"
echo ""
echo "To run:"
echo "  flatpak run ${APP_ID}"
echo "=========================================="
