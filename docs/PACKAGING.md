# Packaging Guide for Quran Hadith

This guide explains how to build packages for Quran Hadith across different formats and architectures.

## Prerequisites

- Docker with BuildKit support
- Git
- For local builds: Flutter SDK 3.19+

## Quick Start

### Build All Packages (Docker)

```bash
# Build for current architecture
docker run --rm -v $(pwd):/workspace -w /workspace \
  ghcr.io/kherldhussein/quran-hadith-builder:linux-amd64 \
  bash -c "flutter build linux --release"
```

### Build Specific Format

```bash
# DEB package
./packaging/deb/build-deb.sh <version> <arch>

# RPM package
./packaging/rpm/build-rpm.sh <version> <arch>

# AppImage
./packaging/appimage/build-appimage.sh <version> <arch>

# Flatpak
./packaging/flatpak/build-flatpak.sh <version> <arch>
```

## CI/CD

Packages are automatically built on:
- Git tags (releases): `git tag v2.0.7 && git push --tags`
- Manual workflow dispatch

See `.github/workflows/packaging.yml` for details.

## Dependency Management

All package dependencies are defined in `packaging/common/dependencies.json`.

Format-specific mappings:
- `packaging/rpm/dependencies.txt` (DEB → RPM)
- `packaging/flatpak/com.kherld.quran_hadith.yml` (Flatpak modules)

## Versioning

Version extraction priority:
1. Git tags: `v2.0.7` → `2.0.7`
2. `pubspec.yaml`: `version: 2.0.7+1` → `2.0.7`
3. Git describe: `v2.0.7-5-gabcd123` (dev builds)

## Multi-Architecture

Supported architectures:
- **x86_64/amd64**: Full support (all formats)
- **ARM64/aarch64**: Full support (DEB, RPM, Flatpak, Snap)
- **ARMv7**: Partial support (DEB, RPM)
