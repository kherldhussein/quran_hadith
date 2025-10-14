#!/bin/bash

echo "==============================================="
echo "Quran & Hadith App - Audio Dependencies Setup"
echo "==============================================="
echo ""
echo "This script will install the required audio dependencies"
echo "for the Quran & Hadith application on Linux."
echo ""

# Detect Linux distribution
if [ -f /etc/fedora-release ]; then
    echo "Detected: Fedora/RHEL-based system"
    echo "Installing audio packages..."
    sudo dnf install -y \
        alsa-lib-devel \
        pulseaudio-libs-devel \
        gstreamer1-devel \
        gstreamer1-plugins-base-devel \
        gstreamer1-plugins-good \
        gstreamer1-plugins-bad-free \
        gstreamer1-plugins-ugly-free \
        gstreamer1-libav

elif [ -f /etc/debian_version ]; then
    echo "Detected: Debian/Ubuntu-based system"
    echo "Installing audio packages..."
    sudo apt-get update
    sudo apt-get install -y \
        libasound2-dev \
        libpulse-dev \
        libgstreamer1.0-dev \
        libgstreamer-plugins-base1.0-dev \
        gstreamer1.0-plugins-good \
        gstreamer1.0-plugins-bad \
        gstreamer1.0-plugins-ugly \
        gstreamer1.0-libav

elif [ -f /etc/arch-release ]; then
    echo "Detected: Arch-based system"
    echo "Installing GStreamer packages..."
    sudo pacman -S --noconfirm \
        gstreamer \
        gst-plugins-base \
        gst-plugins-good \
        gst-plugins-bad \
        gst-plugins-ugly \
        gst-libav

else
    echo "Unknown Linux distribution."
    echo "Please install GStreamer 1.0 development packages manually."
    echo ""
    echo "Required packages (names may vary):"
    echo "  - gstreamer1-devel / libgstreamer1.0-dev"
    echo "  - gstreamer1-plugins-base-devel / libgstreamer-plugins-base1.0-dev"
    echo "  - gstreamer1-plugins-good"
    echo "  - gstreamer1-plugins-bad"
    echo "  - gstreamer1-plugins-ugly"
    exit 1
fi

echo ""
echo "==============================================="
echo "Installation complete!"
echo "==============================================="
echo ""
echo "You can now build the application with:"
echo "  flutter build linux --release"
echo ""
