# Distribution Channels

Quran Hadith is available through multiple distribution channels.

## Official Channels

### 1. GitHub Releases
**Formats:** DEB, RPM, AppImage, Flatpak, Snap

```bash
# Download from releases page
wget https://github.com/kherld-hussein/quran_hadith/releases/download/v2.0.7/quran-hadith_2.0.7_amd64.deb
```

### 2. Snap Store
**Architectures:** amd64, arm64

```bash
sudo snap install quran-hadith --classic
```

### 3. Flathub
**Architectures:** x86_64, aarch64

```bash
flatpak install flathub com.kherld.quran_hadith
flatpak run com.kherld.quran_hadith
```

### 4. AppImage
**Portable, no installation**

```bash
chmod +x quran-hadith-2.0.7-x86_64.AppImage
./quran-hadith-2.0.7-x86_64.AppImage
```

### 5. Docker (Web)
```bash
docker run -p 8080:8080 ghcr.io/kherldhussein/quran-hadith:latest
```

## Distribution-Specific

### Ubuntu/Debian
```bash
sudo dpkg -i quran-hadith_2.0.7_amd64.deb
sudo apt-get install -f
```

### Fedora/RHEL
```bash
sudo dnf install quran-hadith-2.0.7-1.fc39.x86_64.rpm
```

## Update Strategy

- **Snap**: Automatic via snapd
- **Flatpak**: `flatpak update`
- **AppImage**: AppImageUpdate support
- **DEB/RPM**: Download new version

## Support Matrix

| Distribution | DEB | RPM | Flatpak | Snap | AppImage |
|---|---|---|---|---|---|
| Ubuntu 22.04+ | ✅ | - | ✅ | ✅ | ✅ |
| Debian 11+ | ✅ | - | ✅ | ✅ | ✅ |
| Fedora 38+ | - | ✅ | ✅ | ✅ | ✅ |
| Arch Linux | - | - | ✅ | ✅ | ✅ |
