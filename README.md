# Qur'an & Hadith Desktop Application

A comprehensive, offline-capable Islamic study application for desktop platforms (Linux, Windows, macOS).

![Version](https://img.shields.io/badge/version-1.0.0-blue.svg)
![Flutter](https://img.shields.io/badge/Flutter-3.3+-02569B?logo=flutter)
![Platform](https://img.shields.io/badge/platform-Linux%20%7C%20Windows%20%7C%20macOS-lightgrey)
![License](https://img.shields.io/badge/license-MIT-green)

---

## 🌟 Features

### Core Features
- 📖 **Complete Quran** - All 114 Surahs with Arabic text
- 🎧 **Audio Recitation** - Multiple professional reciters
- 🌐 **Multi-language Translations** - English, Urdu, Turkish, and more
- 💾 **Offline Support** - Full functionality without internet
- 🔖 **Advanced Bookmarks** - With notes, tags, and categories
- 📝 **Study Notes** - Annotations with color-coded highlights
- 📊 **Progress Tracking** - Reading and listening history
- ⚙️ **Customizable Settings** - Fonts, themes, audio preferences

### Desktop Features
- 🔔 **Native Notifications** - Reading reminders and alerts
- 🎯 **System Tray** - Quick access and minimize to tray
- ⌨️ **Keyboard Shortcuts** - Global hotkeys for control
- 🖥️ **Window Management** - Always on top, custom sizing
- 📤 **Data Export/Import** - Backup and restore functionality

### Audio Features
- 🎵 **Playlist Management** - Create custom playlists
- ⏭️ **Continuous Playback** - Auto-play next ayah
- 🎚️ **Speed Control** - 0.5x to 2.0x playback speed
- 🔁 **Repeat Modes** - Off / Repeat One / Repeat All
- 🔀 **Shuffle** - Random playback order
- 💾 **Resume** - Continue from where you left off

---

## 🚀 Quick Start

### Prerequisites

- Flutter SDK (>=3.3.0)
- Dart SDK (>=3.3.0)
- Linux, Windows, or macOS

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/kherld-hussein/quran_hadith.git
   cd quran_hadith
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Generate Hive adapters:**
   ```bash
   flutter packages pub run build_runner build --delete-conflicting-outputs
   ```

4. **Run the app:**
   ```bash
   flutter run -d linux  # For Linux
   flutter run -d windows  # For Windows
   flutter run -d macos  # For macOS
   ```

---

## 🏗️ Building for Production

### Linux
```bash
flutter build linux --release
```

### Windows
```bash
flutter build windows --release
```

### macOS
```bash
flutter build macos --release
```

---

## 📚 Documentation

- **[Implementation Guide](IMPLEMENTATION_GUIDE.md)** - Detailed setup and feature implementation
- **[Enhancements Summary](ENHANCEMENTS_SUMMARY.md)** - Complete list of features and capabilities

---

## 🎮 Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| `Space` | Play/Pause |
| `Ctrl+F` | Search |
| `Ctrl+B` | Toggle Bookmark |
| `Ctrl+N` | Add Note |
| `Left/Right` | Skip 10 seconds |
| `Ctrl+Left/Right` | Previous/Next track |

---

## 🛠️ Technology Stack

- **Flutter** - UI framework
- **Hive** - Local database for offline support
- **Just Audio** - Audio playback
- **Provider** - State management
- **Dio** - HTTP client for API calls

---

## 🐛 Troubleshooting

### Hive Adapter Generation Fails
```bash
flutter clean
flutter pub get
flutter packages pub run build_runner build --delete-conflicting-outputs
```

### Audio Not Playing
- Check internet connection for first-time download
- Verify audio permissions on your system

---

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

---

## 📝 License

This project is licensed under the MIT License.

---

## 🙏 Acknowledgments

- **Al-Quran Cloud API** - Quran data and audio
- **Design inspiration**: [Tanvir Ahassan Anik](https://dribbble.com/shots/14241258-Islamic-Web-App-Concept)
- **Flutter Team** - Amazing framework

---

## 📧 Contact

- **Developer**: Kherld Hussein
- **GitHub**: [@kherld-hussein](https://github.com/kherld-hussein)
- **Repository**: [quran_hadith](https://github.com/kherld-hussein/quran_hadith)

---

<div align="center">

**Made with ❤️ for the Muslim Ummah**

*May Allah accept this effort and make it beneficial for all*

</div>
