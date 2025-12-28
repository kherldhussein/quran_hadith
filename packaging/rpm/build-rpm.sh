#!/bin/bash
set -euo pipefail

# RPM build script
# Requires: rpmbuild, Flutter SDK

VERSION="${1:-$(git describe --tags --always | sed 's/^v//')}"
ARCH="${2:-x86_64}"

echo "=========================================="
echo "Building RPM package"
echo "Version: ${VERSION}"
echo "Architecture: ${ARCH}"
echo "=========================================="

# Check for rpmbuild
if ! command -v rpmbuild &> /dev/null; then
    echo "ERROR: rpmbuild not found" >&2
    echo "Install with: sudo dnf install rpm-build" >&2
    exit 1
fi

# Check for Flutter
if ! command -v flutter &> /dev/null; then
    echo "ERROR: Flutter SDK not found" >&2
    echo "Please install Flutter: https://flutter.dev/docs/get-started/install" >&2
    exit 1
fi

# Setup RPM build tree
echo ""
echo "Setting up RPM build tree..."
mkdir -p ~/rpmbuild/{BUILD,RPMS,SOURCES,SPECS,SRPMS}

# Build Flutter application
echo ""
echo "Building Flutter Linux application..."
flutter build linux --release

# Create source tarball
echo ""
echo "Creating source tarball..."
TARBALL_DIR="quran-hadith-${VERSION}"
TARBALL_NAME="${TARBALL_DIR}.tar.gz"

mkdir -p "/tmp/${TARBALL_DIR}"
cp -r build/linux/x64/release/bundle "/tmp/${TARBALL_DIR}/"
cp -r packaging "/tmp/${TARBALL_DIR}/"
cp -r assets "/tmp/${TARBALL_DIR}/"
cp LICENSE README.md "/tmp/${TARBALL_DIR}/"

tar czf ~/rpmbuild/SOURCES/${TARBALL_NAME} -C /tmp ${TARBALL_DIR}
rm -rf "/tmp/${TARBALL_DIR}"

# Copy spec file
echo "Copying spec file..."
cp packaging/rpm/quran-hadith.spec ~/rpmbuild/SPECS/

# Build RPM
echo ""
echo "Building RPM..."
rpmbuild -ba \
    --define "_version ${VERSION}" \
    --target ${ARCH} \
    ~/rpmbuild/SPECS/quran-hadith.spec

# Copy output
echo ""
echo "Copying RPM to current directory..."
find ~/rpmbuild/RPMS/${ARCH}/ -name "quran-hadith-${VERSION}-*.${ARCH}.rpm" \
    -exec cp {} . \;

# Optional: Also copy SRPM
find ~/rpmbuild/SRPMS/ -name "quran-hadith-${VERSION}-*.src.rpm" \
    -exec cp {} . \; || true

echo ""
echo "=========================================="
echo "RPM built successfully!"
echo "Output: quran-hadith-${VERSION}-1.*.${ARCH}.rpm"
echo ""
echo "To install:"
echo "  sudo dnf install quran-hadith-${VERSION}-1.*.${ARCH}.rpm"
echo ""
echo "To test with rpmlint:"
echo "  rpmlint quran-hadith-${VERSION}-1.*.${ARCH}.rpm"
echo "=========================================="
