#!/bin/bash
# Snap Audio Fix - Quick Build Script
# This script rebuilds the snap with the new audio dependencies

set -e

echo "=========================================="
echo "Audio Fix"
echo "=========================================="
echo ""

# Check if snapcraft is installed
if ! command -v snapcraft &> /dev/null; then
    echo "snapcraft is not installed"
    echo "Install with: sudo apt-get install snapcraft"
    exit 1
fi

echo "snapcraft found"
echo ""

# Check if user is in lxd group
if ! groups eternity | grep -q lxd; then
    echo "Warning: You are not in the 'lxd' group"
    echo "Run: sudo usermod -a -G lxd \$USER && newgrp lxd"
    echo ""
fi

echo "=========================================="
echo "Step 1: Cleaning previous builds..."
echo "=========================================="
snapcraft clean || true
echo "Cleaned"
echo ""

echo "=========================================="
echo "Step 2: Building snap with snapcraft pack..."
echo "=========================================="
echo "This may take 10-30 minutes..."
echo ""

# Use the new snapcraft pack command
snapcraft pack

echo ""
echo "=========================================="
echo "Step 3: Build complete!"
echo "=========================================="
echo ""
echo "Next steps:"
echo ""
echo "To test locally:"
echo "  sudo snap install --devmode ./quran-hadith_*.snap"
echo "  quran-hadith"
echo ""
echo "To push to snap store (stable channel):"
echo "  snapcraft upload --release=stable quran-hadith_*.snap"
echo ""
echo "To push to snap store (candidate channel - for testing):"
echo "  snapcraft upload --release=candidate quran-hadith_*.snap"
echo ""
echo "=========================================="
