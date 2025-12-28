%global debug_package %{nil}
%global _build_id_links none

Name:           quran-hadith
Version:        %{_version}
Release:        1%{?dist}
Summary:        Quran and Hadith desktop application

License:        MIT
URL:            https://github.com/kherld-hussein/quran_hadith
Source0:        %{name}-%{version}.tar.gz

BuildRequires:  gcc-c++
BuildRequires:  cmake
BuildRequires:  ninja-build
BuildRequires:  gtk3-devel
BuildRequires:  xz-devel
BuildRequires:  keybinder3-devel
BuildRequires:  libappindicator-gtk3-devel
BuildRequires:  mpv-libs-devel
BuildRequires:  desktop-file-utils

Requires:       gtk3
Requires:       libappindicator-gtk3
Requires:       xz-libs
Requires:       keybinder3
Requires:       mpv-libs
# Audio codecs - these may need RPM Fusion on Fedora
Requires:       ffmpeg-libs
# Audio output
Requires:       pulseaudio-libs
Requires:       alsa-lib
Requires:       openssl-libs

%description
Quran & Hadith is a desktop application for reading the Quran and
browsing Hadith collections. Built with Flutter for a modern,
responsive experience.

Features:
 * Complete Quran with Arabic text and translations
 * Hadith collections with search and navigation
 * Audio recitation with multiple reciters
 * Offline support and bookmarks
 * Desktop integration with system tray and notifications
 * Customizable themes and fonts

%prep
%setup -q

%build
# Flutter build happens in CI before packaging
# This spec packages pre-built binaries

%install
rm -rf %{buildroot}

# Install application
mkdir -p %{buildroot}%{_libdir}/%{name}
cp -r bundle/* %{buildroot}%{_libdir}/%{name}/

# Install launcher script
mkdir -p %{buildroot}%{_bindir}
cat > %{buildroot}%{_bindir}/%{name} << 'EOF'
#!/bin/bash
exec %{_libdir}/%{name}/quran_hadith "$@"
EOF
chmod +x %{buildroot}%{_bindir}/%{name}

# Install desktop file
mkdir -p %{buildroot}%{_datadir}/applications
cp packaging/common/quran-hadith.desktop %{buildroot}%{_datadir}/applications/

# Install icon
mkdir -p %{buildroot}%{_datadir}/icons/hicolor/512x512/apps
cp packaging/common/icons/quran-hadith-512.png %{buildroot}%{_datadir}/icons/hicolor/512x512/apps/%{name}.png

# Validate desktop file
desktop-file-validate %{buildroot}%{_datadir}/applications/quran-hadith.desktop

%post
/usr/bin/update-desktop-database &> /dev/null || :
/bin/touch --no-create %{_datadir}/icons/hicolor &> /dev/null || :

%postun
/usr/bin/update-desktop-database &> /dev/null || :
if [ $1 -eq 0 ] ; then
    /bin/touch --no-create %{_datadir}/icons/hicolor &> /dev/null || :
    /usr/bin/gtk-update-icon-cache %{_datadir}/icons/hicolor &> /dev/null || :
fi

%posttrans
/usr/bin/gtk-update-icon-cache %{_datadir}/icons/hicolor &> /dev/null || :

%files
%license LICENSE
%doc README.md
%{_bindir}/%{name}
%{_libdir}/%{name}/
%{_datadir}/applications/quran-hadith.desktop
%{_datadir}/icons/hicolor/512x512/apps/%{name}.png

%changelog
* Sat Dec 28 2024 Khalid Hussein <kherld.hussein@gmail.com> - 2.0.7-1
- Fix audio playback in Snap packages with libmpv bundling
- Enhanced desktop integration
- Performance optimizations

* Tue Nov 05 2024 Khalid Hussein <kherld.hussein@gmail.com> - 2.0.6-1
- Bug fixes and stability improvements

* Mon Oct 01 2024 Khalid Hussein <kherld.hussein@gmail.com> - 2.0.0-1
- Initial RPM release
