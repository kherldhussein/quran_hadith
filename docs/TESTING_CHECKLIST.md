# Package Testing Checklist

## Installation Tests

- [ ] Package installs without errors
- [ ] All dependencies resolved automatically
- [ ] Desktop file appears in application menu
- [ ] Icon displays correctly in menu
- [ ] Launcher executable found in PATH

## Functionality Tests

- [ ] Application launches successfully
- [ ] Audio playback works (test Quran recitation)
- [ ] Network requests succeed (fetch Quran/Hadith data)
- [ ] Data persists across app restarts
- [ ] System tray integration functional
- [ ] Notifications display properly
- [ ] Window state persists (size, position)

## Desktop Integration

- [ ] Desktop file associations work
- [ ] MIME types registered (if applicable)
- [ ] Media controls (MPRIS) functional
- [ ] Hotkeys work (Play/Pause, etc.)
- [ ] Always-on-top works

## Audio Verification

- [ ] Audio playback starts without errors
- [ ] Volume control works
- [ ] Playback speed adjustment works
- [ ] Audio continues in background
- [ ] PulseAudio/PipeWire integration

## Uninstallation Tests

- [ ] Package removes cleanly
- [ ] Config files handled correctly
- [ ] No orphaned files in system directories
- [ ] Desktop integration cleaned up
- [ ] Icon cache updated

## Platform-Specific Tests

### DEB (Ubuntu/Debian)
- [ ] `dpkg -i` succeeds
- [ ] `apt-get install -f` resolves deps
- [ ] `lintian` reports minimal warnings

### RPM (Fedora)
- [ ] `dnf install` succeeds
- [ ] `rpmlint` passes
- [ ] Dependencies from RPM Fusion resolve

### Flatpak
- [ ] Sandbox permissions work
- [ ] Audio portal functional
- [ ] File access within sandbox

### AppImage
- [ ] Runs on Ubuntu 20.04+
- [ ] Runs on Fedora 38+
- [ ] Runs on Arch Linux
- [ ] FUSE works or fallback succeeds

### Snap
- [ ] Classic confinement allows file access
- [ ] Audio works without additional setup
- [ ] Auto-updates work
