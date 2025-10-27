# Qur'an & Hadith Desktop Application

A desktop app for reading the Qur'an and browsing Hadith collections on Linux, Windows, and macOS. It supports offline use, audio recitation, search, and bookmarks.

![Version](https://img.shields.io/badge/version-2.0.0-blue.svg)
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

## Quick Start

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

## Contributing

Contributions are welcome via pull requests.

## License

MIT License. See the LICENSE file for details.

## Contact

- Developer: Khalid Hussein
- GitHub: https://github.com/kherldhussein
- Repository: https://github.com/kherldhussein/quran_hadith
