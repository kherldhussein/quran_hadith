# Audio Setup Guide for Quran & Hadith App on Linux

## Overview

The Quran & Hadith application uses **just_audio** with **GStreamer** backend for audio playback on Linux. This provides excellent compatibility and performance.

## Prerequisites

### Required: GStreamer 1.0

GStreamer is required for audio playback on Linux. You need to install GStreamer development libraries before building the application.

## Quick Installation

### Option 1: Automated Installation (Recommended)

Run the provided installation script:

```bash
chmod +x install_audio_dependencies.sh
./install_audio_dependencies.sh
```

The script will automatically detect your Linux distribution and install the required packages.

### Option 2: Manual Installation

#### **Fedora / RHEL / CentOS**

```bash
sudo dnf install -y \
    gstreamer1-devel \
    gstreamer1-plugins-base-devel \
    gstreamer1-plugins-good \
    gstreamer1-plugins-bad-free \
    gstreamer1-plugins-ugly-free \
    gstreamer1-libav
```

#### **Ubuntu / Debian**

```bash
sudo apt-get update
sudo apt-get install -y \
    libgstreamer1.0-dev \
    libgstreamer-plugins-base1.0-dev \
    gstreamer1.0-plugins-good \
    gstreamer1.0-plugins-bad \
    gstreamer1.0-plugins-ugly \
    gstreamer1.0-libav
```

#### **Arch Linux**

```bash
sudo pacman -S --noconfirm \
    gstreamer \
    gst-plugins-base \
    gst-plugins-good \
    gst-plugins-bad \
    gst-plugins-ugly \
    gst-libav
```

## Verify Installation

After installing GStreamer, verify it's correctly installed:

```bash
pkg-config --modversion gstreamer-1.0
```

You should see a version number (e.g., `1.22.0`).

## Building the Application

Once GStreamer is installed, you can build the application:

```bash
# Clean previous builds (optional)
flutter clean

# Get dependencies
flutter pub get

# Build for Linux
flutter build linux --release
```

## Running the Application

### From Build Directory

```bash
./build/linux/x64/release/bundle/quran_hadith
```

### In Debug Mode

```bash
flutter run -d linux
```

## Audio Features

The audio controller provides the following features:

- ✅ **Local Caching**: Audio files are downloaded once and cached locally
- ✅ **Offline Playback**: Cached audio works without internet connection
- ✅ **Progress Tracking**: Real-time playback position and buffering status
- ✅ **Fallback Support**: Automatic fallback to direct URL streaming if caching fails

### Cache Location

Audio files are cached at:
```
/tmp/audio_cache/
```

## Troubleshooting

### Issue: "Package 'gstreamer-1.0' not found"

**Solution**: Install GStreamer development packages (see installation steps above)

### Issue: Audio playback fails or no sound

**Possible causes:**

1. **GStreamer plugins not installed**
   ```bash
   # Install additional codecs
   sudo dnf install gstreamer1-plugins-ugly-free gstreamer1-libav
   ```

2. **PulseAudio/PipeWire not running**
   ```bash
   # Check audio server status
   systemctl --user status pipewire
   # OR
   systemctl --user status pulseaudio
   ```

3. **Audio cache directory permissions**
   ```bash
   # Ensure /tmp is writable
   ls -la /tmp
   ```

### Issue: Build fails with CMake errors

**Solution**: Ensure all development packages are installed:
```bash
pkg-config --list-all | grep gstreamer
```

You should see multiple GStreamer packages listed.

## Technical Details

- **Audio Backend**: just_audio with GStreamer
- **Supported Formats**: MP3, AAC, OGG, WAV, FLAC (via GStreamer)
- **Caching Strategy**: Download-first for better compatibility
- **Network Timeout**: 30 seconds for audio downloads

## Migration from just_audio_mpv

Previous versions used `just_audio_mpv`, which had compatibility issues with MPV on Linux. The new implementation:

- ✅ Uses GStreamer instead of MPV (better compatibility)
- ✅ Downloads audio files first (avoids streaming issues)
- ✅ Caches files for offline use
- ✅ More reliable playback with better error handling

## Support

For issues or questions:
- Check the GitHub Issues page
- Review the logs in debug mode: `flutter run -d linux`
- Ensure GStreamer is properly installed: `gst-inspect-1.0 --version`

---

**Note**: GStreamer is a widely-used multimedia framework and is likely already installed on your system. If not, it's available in all major Linux distribution repositories.
