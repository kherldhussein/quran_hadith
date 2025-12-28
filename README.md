# Qur'an & Hadith Desktop Application

A desktop app for reading the Qur'an and browsing Hadith collections on Linux, Windows, and macOS. It supports offline use, audio recitation, search, and bookmarks.

![Version](https://img.shields.io/badge/version-2.0.7-blue.svg)
![Flutter](https://img.shields.io/badge/Flutter-3.3+-02569B?logo=flutter)
![Platform](https://img.shields.io/badge/platform-Linux%20%7C%20Windows%20%7C%20macOS-lightgrey)
![License](https://img.shields.io/badge/license-MIT-green)

## Features

- Quran: 114 surahs with Arabic text and translations
- Hadith: book browsing with pagination and in-book search
- Audio: multiple reciters, speed control, repeat, and auto-play next
- Offline support and favorites/bookmarks
- Desktop integration: system tray, notifications, and basic shortcuts
- Customizable settings (themes, fonts, playback)

## Installation

### Quick Install (Recommended)

**Snap (Linux):**
```bash
sudo snap install quran-hadith --classic
```

**Flatpak (Linux):**
```bash
flatpak install flathub com.kherld.quran_hadith
```

**AppImage (Linux - Portable):**
Download from [Releases](https://github.com/kherld-hussein/quran_hadith/releases), make executable, and run:
```bash
chmod +x quran-hadith-*.AppImage
./quran-hadith-*.AppImage
```

### Package Managers

**Ubuntu/Debian:**
```bash
wget https://github.com/kherld-hussein/quran_hadith/releases/download/v2.0.7/quran-hadith_2.0.7_amd64.deb
sudo dpkg -i quran-hadith_2.0.7_amd64.deb
sudo apt-get install -f  # Install dependencies
```

**Fedora/RHEL:**
```bash
wget https://github.com/kherld-hussein/quran_hadith/releases/download/v2.0.7/quran-hadith-2.0.7-1.fc39.x86_64.rpm
sudo dnf install quran-hadith-2.0.7-1.fc39.x86_64.rpm
```

**Docker (Web Version):**
```bash
docker run -p 8080:8080 ghcr.io/kherld-hussein/quran-hadith:latest
# Visit http://localhost:8080
```

See [docs/DISTRIBUTION.md](docs/DISTRIBUTION.md) for all installation options and platform-specific instructions.

## Quick Start (Development)

Prerequisites: Flutter >= 3.3, Dart >= 3.3

1) Clone and install dependencies
```bash
git clone https://github.com/kherldhussein/quran_hadith.git
cd quran_hadith
flutter pub get
```

2) Generate code (if applicable)
```bash
flutter packages pub run build_runner build --delete-conflicting-outputs
```

3) Run the app
```bash
flutter run -d linux    # or -d windows / -d macos
```

## Build (release)

```bash
flutter build linux --release
flutter build windows --release
flutter build macos --release
```

## Documentation

- [Installation Guide](docs/DISTRIBUTION.md) - All installation methods
- [Building from Source](docs/BUILDING.md) - Developer build instructions
- [Packaging Guide](docs/PACKAGING.md) - Creating packages
- [CI/CD Setup](docs/CI_SETUP.md) - GitHub Actions configuration
- [Testing Checklist](docs/TESTING_CHECKLIST.md) - Package validation

## Contributing

Contributions are welcome via pull requests.

For packaging improvements or bug reports, please check the [packaging documentation](docs/PACKAGING.md) first.

## License

MIT License. See the LICENSE file for details.

## Contact

- Developer: Khalid Hussein
- GitHub: https://github.com/kherldhussein
- Repository: https://github.com/kherldhussein/quran_hadith
