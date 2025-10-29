import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:window_manager/window_manager.dart';
import 'package:quran_hadith/database/database_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tray_manager/tray_manager.dart';

/// System Tray Manager
class SystemTrayManager with TrayListener {
  static final SystemTrayManager _instance = SystemTrayManager._internal();
  factory SystemTrayManager() => _instance;
  SystemTrayManager._internal();

  bool _isInitialized = false;
  VoidCallback? _onShowWindow;
  VoidCallback? _onQuit;
  VoidCallback? _onPlayPause;
  VoidCallback? _onNextAyah;
  VoidCallback? _onPreviousAyah;

  Future<void> initialize({
    required VoidCallback onShowWindow,
    required VoidCallback onQuit,
    required VoidCallback onPlayPause,
    VoidCallback? onNextAyah,
    VoidCallback? onPreviousAyah,
  }) async {
    if (_isInitialized) return;

    try {
      if (!Platform.isLinux && !Platform.isWindows && !Platform.isMacOS) {
        debugPrint('System tray not supported on this platform');
        return;
      }

      _onShowWindow = onShowWindow;
      _onQuit = onQuit;
      _onPlayPause = onPlayPause;
      _onNextAyah = onNextAyah;
      _onPreviousAyah = onPreviousAyah;

      // Add tray listener
      trayManager.addListener(this);

      // Set tray icon
      await trayManager.setIcon(
        Platform.isWindows
            ? 'assets/images/Logo.png'
            : 'assets/images/Logo.png',
      );

      // Set tray tooltip
      await trayManager.setToolTip('Quran & Hadith');

      // Build and set context menu
      await _updateContextMenu(isPlaying: false);

      _isInitialized = true;
      debugPrint(
          'SystemTrayManager initialized for ${Platform.operatingSystem}');
    } catch (e) {
      debugPrint('Error initializing system tray: $e');
      _isInitialized = false;
    }
  }

  Future<void> _updateContextMenu({required bool isPlaying}) async {
    try {
      final Menu menu = Menu(
        items: [
          MenuItem(
            key: 'show_window',
            label: 'Show Window',
          ),
          MenuItem.separator(),
          MenuItem(
            key: 'play_pause',
            label: isPlaying ? 'Pause' : 'Play',
          ),
          MenuItem(
            key: 'next',
            label: 'Next Ayah',
          ),
          MenuItem(
            key: 'previous',
            label: 'Previous Ayah',
          ),
          MenuItem.separator(),
          MenuItem(
            key: 'quit',
            label: 'Quit',
          ),
        ],
      );

      await trayManager.setContextMenu(menu);
    } catch (e) {
      debugPrint('Error updating context menu: $e');
    }
  }

  @override
  void onTrayIconMouseDown() {
    debugPrint('Tray icon clicked');
    _onShowWindow?.call();
  }

  @override
  void onTrayIconRightMouseDown() {
    debugPrint('Tray icon right-clicked');
    trayManager.popUpContextMenu();
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    debugPrint('Tray menu item clicked: ${menuItem.key}');
    switch (menuItem.key) {
      case 'show_window':
        _onShowWindow?.call();
        break;
      case 'play_pause':
        _onPlayPause?.call();
        break;
      case 'next':
        _onNextAyah?.call();
        break;
      case 'previous':
        _onPreviousAyah?.call();
        break;
      case 'quit':
        _onQuit?.call();
        break;
    }
  }

  Future<void> updatePlaybackState({required bool isPlaying}) async {
    if (!_isInitialized) return;
    await _updateContextMenu(isPlaying: isPlaying);
  }

  Future<void> showTrayMessage({
    required String title,
    required String message,
  }) async {
    if (!_isInitialized) return;

    try {
      await trayManager.setToolTip('$title\n$message');
      debugPrint('Tray message: $title - $message');
    } catch (e) {
      debugPrint('Error showing tray message: $e');
    }
  }

  Future<void> updateTrayIcon({required String status}) async {
    if (!_isInitialized) return;

    try {
      await trayManager.setToolTip('Quran & Hadith - $status');
      debugPrint('Tray icon updated: $status');
    } catch (e) {
      debugPrint('Error updating tray icon: $e');
    }
  }

  void triggerShowWindow() => _onShowWindow?.call();
  void triggerQuit() => _onQuit?.call();
  void triggerPlayPause() => _onPlayPause?.call();

  Future<void> dispose() async {
    if (_isInitialized) {
      try {
        trayManager.removeListener(this);
        await trayManager.destroy();
      } catch (e) {
        debugPrint('Error disposing tray manager: $e');
      }
    }
    _isInitialized = false;
  }
}

/// Window State Manager - Handles persistence of window geometry
class WindowStateManager {
  static final WindowStateManager _instance = WindowStateManager._internal();
  factory WindowStateManager() => _instance;
  WindowStateManager._internal();

  static const String _prefixWindowState = 'window_state_';
  static const String _keyX = '${_prefixWindowState}x';
  static const String _keyY = '${_prefixWindowState}y';
  static const String _keyWidth = '${_prefixWindowState}width';
  static const String _keyHeight = '${_prefixWindowState}height';
  static const String _keyMaximized = '${_prefixWindowState}maximized';
  static const String _keyAlwaysOnTop = '${_prefixWindowState}always_on_top';

  late SharedPreferences _prefs;
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _prefs = await SharedPreferences.getInstance();
      _isInitialized = true;
      debugPrint('WindowStateManager initialized');
    } catch (e) {
      debugPrint('Error initializing WindowStateManager: $e');
    }
  }

  /// Restore window state from preferences
  Future<void> restoreWindowState({
    Size? defaultSize,
    Offset? defaultPosition,
  }) async {
    if (!_isInitialized) await initialize();

    try {
      final double? x = _prefs.getDouble(_keyX);
      final double? y = _prefs.getDouble(_keyY);
      final double? width = _prefs.getDouble(_keyWidth);
      final double? height = _prefs.getDouble(_keyHeight);
      final bool isMaximized = _prefs.getBool(_keyMaximized) ?? false;
      final bool alwaysOnTop = _prefs.getBool(_keyAlwaysOnTop) ?? false;

      // Restore position if available
      if (x != null && y != null) {
        try {
          await windowManager.setPosition(Offset(x, y));
          debugPrint('Window position restored: ($x, $y)');
        } catch (e) {
          debugPrint('Could not restore position: $e');
        }
      }

      // Restore size if available
      if (width != null && height != null) {
        try {
          await windowManager.setSize(Size(width, height));
          debugPrint('Window size restored: ($width, $height)');
        } catch (e) {
          debugPrint('Could not restore size: $e');
        }
      } else if (defaultSize != null) {
        try {
          await windowManager.setSize(defaultSize);
        } catch (e) {
          debugPrint('Could not set default size: $e');
        }
      }

      // Restore maximized state
      if (isMaximized) {
        try {
          await windowManager.maximize();
          debugPrint('Window restored to maximized state');
        } catch (e) {
          debugPrint('Could not restore maximized state: $e');
        }
      }

      // Restore always-on-top
      if (alwaysOnTop) {
        try {
          await windowManager.setAlwaysOnTop(true);
          debugPrint('Always-on-top restored');
        } catch (e) {
          debugPrint('Could not restore always-on-top: $e');
        }
      }
    } catch (e) {
      debugPrint('Error restoring window state: $e');
    }
  }

  /// Save current window state
  Future<void> saveWindowState() async {
    if (!_isInitialized) return;

    try {
      final Offset position = await windowManager.getPosition();
      final Size size = await windowManager.getSize();
      final bool isMaximized = await windowManager.isMaximized();
      final bool alwaysOnTop = await windowManager.isAlwaysOnTop();

      await _prefs.setDouble(_keyX, position.dx);
      await _prefs.setDouble(_keyY, position.dy);
      await _prefs.setDouble(_keyWidth, size.width);
      await _prefs.setDouble(_keyHeight, size.height);
      await _prefs.setBool(_keyMaximized, isMaximized);
      await _prefs.setBool(_keyAlwaysOnTop, alwaysOnTop);

      debugPrint(
          'Window state saved: pos($position), size($size), max($isMaximized), top($alwaysOnTop)');
    } catch (e) {
      debugPrint('Error saving window state: $e');
    }
  }

  /// Clear saved window state
  Future<void> clearWindowState() async {
    if (!_isInitialized) return;

    try {
      await _prefs.remove(_keyX);
      await _prefs.remove(_keyY);
      await _prefs.remove(_keyWidth);
      await _prefs.remove(_keyHeight);
      await _prefs.remove(_keyMaximized);
      await _prefs.remove(_keyAlwaysOnTop);
      debugPrint('Window state cleared');
    } catch (e) {
      debugPrint('Error clearing window state: $e');
    }
  }
}

/// Media Controls Manager - Handles OS-level media control integration
class MediaControlsManager {
  static final MediaControlsManager _instance =
      MediaControlsManager._internal();
  factory MediaControlsManager() => _instance;
  MediaControlsManager._internal();

  bool _isInitialized = false;

  // Note: SMTC implementation is temporarily disabled due to API compatibility issues
  // dynamic _smtc; // Windows SMTC placeholder

  // Callbacks for media control button presses
  VoidCallback? _onPlayCallback;
  VoidCallback? _onPauseCallback;
  VoidCallback? _onNextCallback;
  VoidCallback? _onPreviousCallback;
  VoidCallback? _onStopCallback;

  Future<void> initialize({
    VoidCallback? onPlay,
    VoidCallback? onPause,
    VoidCallback? onNext,
    VoidCallback? onPrevious,
    VoidCallback? onStop,
  }) async {
    if (_isInitialized) return;

    try {
      _onPlayCallback = onPlay;
      _onPauseCallback = onPause;
      _onNextCallback = onNext;
      _onPreviousCallback = onPrevious;
      _onStopCallback = onStop;

      // Initialize platform-specific media controls
      if (Platform.isLinux) {
        await _initializeLinuxMediaControls();
      } else if (Platform.isWindows) {
        await _initializeWindowsMediaControls();
      } else if (Platform.isMacOS) {
        await _initializeMacOSMediaControls();
      }

      _isInitialized = true;
      debugPrint('MediaControlsManager initialized');
    } catch (e) {
      debugPrint('Error initializing media controls: $e');
    }
  }

  Future<void> _initializeLinuxMediaControls() async {
    try {
      // MPRIS (Media Player Remote Interfacing Specification) support
      // This allows integration with system media controls on Linux
      // Note: This would require a separate MPRIS implementation package
      // For now, we're using debug prints as placeholders
      debugPrint('MPRIS media controls for Linux - placeholder implementation');
      debugPrint(
          'To fully implement: Consider using dbus package or audio_service');
    } catch (e) {
      debugPrint('Error initializing Linux media controls: $e');
    }
  }

  Future<void> _initializeWindowsMediaControls() async {
    try {
      // SMTC (System Media Transport Controls) support for Windows
      // Note: Full implementation temporarily disabled due to API compatibility
      // The smtc_windows package is available in pubspec.yaml for future implementation
      debugPrint('SMTC media controls for Windows - placeholder implementation');
      debugPrint('To fully implement: Verify smtc_windows package API compatibility');

      // TODO: Implement SMTC when package API is verified
      // Example usage pattern (needs API verification):
      // _smtc = SMTCWindows(...);
      // _smtc?.buttonPressStream.listen(...);
    } catch (e) {
      debugPrint('Error initializing Windows media controls: $e');
    }
  }

  Future<void> _initializeMacOSMediaControls() async {
    try {
      // macOS native media controls
      // Would require MPNowPlayingInfoCenter integration
      debugPrint('macOS media controls - placeholder implementation');
      debugPrint('To fully implement: Use audio_service or platform channels');
    } catch (e) {
      debugPrint('Error initializing macOS media controls: $e');
    }
  }

  /// Update media metadata (current track info)
  Future<void> updateMediaMetadata({
    required String surah,
    required int ayah,
    required String reciter,
    String? imageUrl,
  }) async {
    if (!_isInitialized) return;

    try {
      // TODO: Update Windows SMTC metadata when implementation is complete
      debugPrint('Media metadata updated: $surah - Ayah $ayah ($reciter)');
    } catch (e) {
      debugPrint('Error updating media metadata: $e');
    }
  }

  /// Update playback state
  Future<void> updatePlaybackState({
    required bool isPlaying,
    required Duration position,
    required Duration duration,
  }) async {
    if (!_isInitialized) return;

    try {
      // TODO: Update Windows SMTC playback status when implementation is complete
      debugPrint(
          'Playback state: ${isPlaying ? 'Playing' : 'Paused'} - $position / $duration');
    } catch (e) {
      debugPrint('Error updating playback state: $e');
    }
  }

  Future<void> dispose() async {
    try {
      // TODO: Dispose SMTC when implementation is complete
    } catch (e) {
      debugPrint('Error disposing media controls: $e');
    }
    _isInitialized = false;
  }
}

/// Native desktop features service
class NativeDesktopService with WindowListener {
  static final NativeDesktopService _instance =
      NativeDesktopService._internal();
  factory NativeDesktopService() => _instance;
  NativeDesktopService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  final SystemTrayManager _systemTray = SystemTrayManager();
  final WindowStateManager _windowState = WindowStateManager();
  final MediaControlsManager _mediaControls = MediaControlsManager();

  bool _isInitialized = false;
  bool _systemTrayEnabled = false;
  bool _notificationsEnabled = false;
  bool _hotkeysEnabled = false;

  VoidCallback? _onPlayPauseCallback;
  VoidCallback? _onNextCallback;
  VoidCallback? _onPreviousCallback;
  VoidCallback? _onSearchCallback;
  VoidCallback? _onShowWindowCallback;
  VoidCallback? _onQuitCallback;
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final prefs = database.getPreferences();

      await windowManager.ensureInitialized();
      windowManager.addListener(this);

      // Initialize window state persistence
      await _windowState.initialize();
      await _windowState.restoreWindowState(
        defaultSize: const Size(1200, 750),
        defaultPosition: const Offset(100, 100),
      );

      // Initialize media controls with callbacks
      await _mediaControls.initialize(
        onPlay: _onPlayPauseCallback,
        onPause: _onPlayPauseCallback,
        onNext: _onNextCallback,
        onPrevious: _onPreviousCallback,
        onStop: _onPlayPauseCallback,
      );

      if (prefs.enableNotifications) {
        await _initializeNotifications();
      }

      if (prefs.enableSystemTray) {
        await _initializeSystemTray();
      } else if (Platform.isLinux) {
        debugPrint(
            'System tray disabled. To enable, install: sudo apt-get install ayatana-appindicator3-0.1');
      }

      if (prefs.enableGlobalShortcuts) {
        await _initializeHotkeys();
      }

      _isInitialized = true;
      debugPrint('NativeDesktopService initialized successfully');
    } catch (e) {
      debugPrint('Error initializing NativeDesktopService: $e');
    }
  }

  Future<void> _initializeNotifications() async {
    try {
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings macOSSettings =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const LinuxInitializationSettings linuxSettings =
          LinuxInitializationSettings(
        defaultActionName: 'Open notification',
      );

      const InitializationSettings settings = InitializationSettings(
        android: androidSettings,
        macOS: macOSSettings,
        linux: linuxSettings,
      );

      await _notifications.initialize(
        settings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      _notificationsEnabled = true;
      debugPrint('Notifications initialized');
    } catch (e) {
      debugPrint('Error initializing notifications: $e');
    }
  }

  /// Show notification
  Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_notificationsEnabled) return;

    try {
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        'quran_app_channel',
        'Quran App',
        channelDescription: 'Quran reading and listening notifications',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );

      const DarwinNotificationDetails macOSDetails =
          DarwinNotificationDetails();

      const LinuxNotificationDetails linuxDetails = LinuxNotificationDetails();

      const NotificationDetails details = NotificationDetails(
        android: androidDetails,
        macOS: macOSDetails,
        linux: linuxDetails,
      );

      await _notifications.show(
        DateTime.now().millisecond,
        title,
        body,
        details,
        payload: payload,
      );
    } catch (e) {
      debugPrint('Error showing notification: $e');
    }
  }

  /// Schedule daily reminder notification
  Future<void> scheduleDailyReminder({
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {
    if (!_notificationsEnabled) return;

    try {
      debugPrint('Scheduled reminder for $hour:$minute');
    } catch (e) {
      debugPrint('Error scheduling reminder: $e');
    }
  }

  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
  }

  Future<void> _initializeSystemTray() async {
    try {
      await _systemTray.initialize(
        onShowWindow: _onShowWindowCallback ?? () => windowManager.show(),
        onQuit: _onQuitCallback ?? () => _exitApp(),
        onPlayPause: _onPlayPauseCallback ?? () {},
        onNextAyah: _onNextCallback,
        onPreviousAyah: _onPreviousCallback,
      );
      _systemTrayEnabled = true;
      debugPrint('System tray initialized');
    } catch (e) {
      _systemTrayEnabled = false;
      debugPrint('Failed to initialize system tray: $e');
    }
  }

  Future<void> _initializeHotkeys() async {
    try {
      debugPrint('Initializing hotkeys');
      await hotKeyManager.unregisterAll();

      await hotKeyManager.register(
        HotKey(
          key: PhysicalKeyboardKey.space,
          scope: HotKeyScope.inapp,
        ),
        keyDownHandler: (hotKey) => _onPlayPauseCallback?.call(),
      );

      await hotKeyManager.register(
        HotKey(
          key: PhysicalKeyboardKey.keyF,
          modifiers: [HotKeyModifier.control],
          scope: HotKeyScope.inapp,
        ),
        keyDownHandler: (hotKey) => _onSearchCallback?.call(),
      );

      await hotKeyManager.register(
        HotKey(
          key: PhysicalKeyboardKey.arrowRight,
          modifiers: [HotKeyModifier.control],
          scope: HotKeyScope.inapp,
        ),
        keyDownHandler: (hotKey) => _onNextCallback?.call(),
      );

      await hotKeyManager.register(
        HotKey(
          key: PhysicalKeyboardKey.arrowLeft,
          modifiers: [HotKeyModifier.control],
          scope: HotKeyScope.inapp,
        ),
        keyDownHandler: (hotKey) => _onPreviousCallback?.call(),
      );

      _hotkeysEnabled = true;
      debugPrint('Hotkeys initialized successfully');
    } catch (e) {
      debugPrint('Error initializing hotkeys: $e');
    }
  }

  /// Register hotkey callbacks
  void registerCallbacks({
    VoidCallback? onPlayPause,
    VoidCallback? onNext,
    VoidCallback? onPrevious,
    VoidCallback? onSearch,
    VoidCallback? onShowWindow,
    VoidCallback? onQuit,
  }) {
    _onPlayPauseCallback = onPlayPause;
    _onNextCallback = onNext;
    _onPreviousCallback = onPrevious;
    _onSearchCallback = onSearch;
    _onShowWindowCallback = onShowWindow;
    _onQuitCallback = onQuit;
  }

  /// Update media metadata
  Future<void> updateMediaMetadata({
    required String surah,
    required int ayah,
    required String reciter,
    String? imageUrl,
  }) async {
    await _mediaControls.updateMediaMetadata(
      surah: surah,
      ayah: ayah,
      reciter: reciter,
      imageUrl: imageUrl,
    );
  }

  /// Update playback state
  Future<void> updatePlaybackState({
    required bool isPlaying,
    required Duration position,
    required Duration duration,
  }) async {
    await _mediaControls.updatePlaybackState(
      isPlaying: isPlaying,
      position: position,
      duration: duration,
    );
  }

  /// Update playback info (combines metadata and state updates)
  Future<void> updatePlaybackInfo({
    required String surah,
    required int ayah,
    required String reciter,
    required bool isPlaying,
    required Duration position,
    required Duration duration,
    String? imageUrl,
  }) async {
    await updateMediaMetadata(
      surah: surah,
      ayah: ayah,
      reciter: reciter,
      imageUrl: imageUrl,
    );
    await updatePlaybackState(
      isPlaying: isPlaying,
      position: position,
      duration: duration,
    );

    // Update tray playback state
    if (_systemTrayEnabled) {
      await _systemTray.updatePlaybackState(isPlaying: isPlaying);
      await _systemTray.updateTrayIcon(
        status: isPlaying ? 'Playing: $surah - Ayah $ayah' : 'Paused',
      );
    }
  }

  /// Show tray message
  Future<void> showTrayMessage({
    required String title,
    required String message,
  }) async {
    await _systemTray.showTrayMessage(title: title, message: message);
  }

  Future<void> _hideWindow() async {
    await windowManager.hide();
  }

  Future<void> minimizeToTray() async {
    if (_systemTrayEnabled) {
      await _hideWindow();
    } else {
      await windowManager.minimize();
    }
  }

  @override
  Future<void> onWindowClose() async {
    try {
      final prefs = database.getPreferences();

      // Save window state before closing
      await _windowState.saveWindowState();

      if (prefs.enableSystemTray && _systemTrayEnabled) {
        debugPrint(
            'Minimizing to tray - audio playback continues in background');
        await _hideWindow();
      } else {
        if (prefs.enableSystemTray && !_systemTrayEnabled) {
          debugPrint(
              'System tray requested but not available - exiting normally');
        }
        await _exitApp();
      }
    } catch (e) {
      debugPrint('Error in onWindowClose: $e');
      await _exitApp();
    }
  }

  @override
  void onWindowMinimize() {
    debugPrint('Window minimized - audio playback continues');
  }

  @override
  void onWindowRestore() {
    debugPrint('Window restored');
  }

  @override
  void onWindowFocus() {
    debugPrint('Window focused');
  }

  @override
  void onWindowBlur() {
    debugPrint('Window blurred');
  }

  Future<void> _exitApp() async {
    await windowManager.destroy();
  }

  Future<void> enableSystemTray(bool enable) async {
    debugPrint('System tray is not available on this platform');
  }

  Future<void> enableNotifications(bool enable) async {
    if (enable && !_notificationsEnabled) {
      await _initializeNotifications();
    }
    _notificationsEnabled = enable;
  }

  Future<void> enableHotkeys(bool enable) async {
    if (enable && !_hotkeysEnabled) {
      await _initializeHotkeys();
    } else if (!enable && _hotkeysEnabled) {
      await hotKeyManager.unregisterAll();
      _hotkeysEnabled = false;
    }
  }

  Future<void> dispose() async {
    try {
      // Save window state on exit
      await _windowState.saveWindowState();

      windowManager.removeListener(this);

      if (_hotkeysEnabled) {
        await hotKeyManager.unregisterAll();
      }

      await _systemTray.dispose();
      await _mediaControls.dispose();

      _isInitialized = false;
      debugPrint('NativeDesktopService disposed');
    } catch (e) {
      debugPrint('Error disposing NativeDesktopService: $e');
    }
  }
}

/// App window helper
class AppWindow {
  /// Set always on top
  Future<void> setAlwaysOnTop(bool alwaysOnTop) async {
    await windowManager.setAlwaysOnTop(alwaysOnTop);
  }

  /// Set window size
  Future<void> setSize(Size size) async {
    await windowManager.setSize(size);
  }

  /// Set minimum size
  Future<void> setMinimumSize(Size size) async {
    await windowManager.setMinimumSize(size);
  }

  /// Set maximum size
  Future<void> setMaximumSize(Size size) async {
    await windowManager.setMaximumSize(size);
  }

  /// Set resizable
  Future<void> setResizable(bool resizable) async {
    await windowManager.setResizable(resizable);
  }

  /// Center window
  Future<void> center() async {
    await windowManager.center();
  }

  /// Set title
  Future<void> setTitle(String title) async {
    await windowManager.setTitle(title);
  }

  /// Maximize
  Future<void> maximize() async {
    await windowManager.maximize();
  }

  /// Unmaximize
  Future<void> unmaximize() async {
    await windowManager.unmaximize();
  }

  /// Toggle maximize
  Future<void> toggleMaximize() async {
    if (await windowManager.isMaximized()) {
      await unmaximize();
    } else {
      await maximize();
    }
  }
}

/// Global instance
final nativeDesktop = NativeDesktopService();
