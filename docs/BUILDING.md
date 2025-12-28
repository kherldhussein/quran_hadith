# Building Quran Hadith from Source

## System Requirements

### All Platforms
- Flutter SDK 3.19 or later
- Dart SDK 3.3 or later
- Git

### Linux
- GTK 3.0 development files
- libmpv development files
- See `packaging/common/dependencies.json` for complete list

## Build Steps

### 1. Clone Repository

```bash
git clone https://github.com/kherld-hussein/quran_hadith.git
cd quran_hadith
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Build

```bash
# Linux
flutter build linux --release

# Windows
flutter build windows --release

# Web
flutter build web --release
```

### 4. Run

```bash
# From build output
./build/linux/x64/release/bundle/quran_hadith

# Or during development
flutter run -d linux
```

## Docker Build (Reproducible)

```bash
# Build in Docker
docker build -t quran-hadith-builder -f packaging/docker/Dockerfile.builder-amd64 .

docker run --rm -v $(pwd):/workspace quran-hadith-builder \
  bash -c "flutter build linux --release"
```

## Troubleshooting

### Missing libmpv
- Ubuntu/Debian: `sudo apt install libmpv-dev`
- Fedora: `sudo dnf install mpv-libs-devel`
- Arch: `sudo pacman -S mpv`

### Audio Not Working
Ensure PulseAudio or PipeWire is running:
```bash
systemctl --user status pulseaudio
```
