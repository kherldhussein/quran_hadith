import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:window_manager/window_manager.dart';
import 'package:quran_hadith/database/database_service.dart';

/// Native desktop features service
class NativeDesktopService with WindowListener {
  static final NativeDesktopService _instance =
      NativeDesktopService._internal();
  factory NativeDesktopService() => _instance;
  NativeDesktopService._internal();

  // Services
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  // final AppWindow _appWindow = AppWindow();

  bool _isInitialized = false;
  bool _systemTrayEnabled = false;
  bool _notificationsEnabled = false;
  bool _hotkeysEnabled = false;

  // Callbacks
  VoidCallback? _onPlayPauseCallback;
  VoidCallback? _onNextCallback;
  VoidCallback? _onPreviousCallback;
  VoidCallback? _onSearchCallback;

  /// Initialize native desktop features
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Load preferences
      final prefs = database.getPreferences();

      // Initialize window manager
      await windowManager.ensureInitialized();
      windowManager.addListener(this);

      // Initialize notifications if enabled
      if (prefs.enableNotifications) {
        await _initializeNotifications();
      }

      // Initialize system tray if enabled
      // Note: On Linux, this requires ayatana-appindicator3 library
      if (prefs.enableSystemTray) {
        await _initializeSystemTray();
      } else if (Platform.isLinux) {
        debugPrint(
            'System tray disabled. To enable, install: sudo apt-get install ayatana-appindicator3-0.1');
      }

      // Initialize hotkeys if enabled
      if (prefs.enableGlobalShortcuts) {
        await _initializeHotkeys();
      }

      _isInitialized = true;
      debugPrint('NativeDesktopService initialized successfully');
    } catch (e) {
      debugPrint('Error initializing NativeDesktopService: $e');
    }
  }

  // ============ NOTIFICATIONS ============

  Future<void> _initializeNotifications() async {
    try {
      // Android settings
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      // macOS settings
      const DarwinInitializationSettings macOSSettings =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      // Linux settings
      const LinuxInitializationSettings linuxSettings =
          LinuxInitializationSettings(
        defaultActionName: 'Open notification',
      );

      // Initialize
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
      // Implementation depends on your notification scheduling needs
      debugPrint('Scheduled reminder for $hour:$minute');
    } catch (e) {
      debugPrint('Error scheduling reminder: $e');
    }
  }

  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
    // Handle notification tap
  }

  // ============ SYSTEM TRAY ============
  // System tray functionality removed due to Linux dependency issues

  Future<void> _initializeSystemTray() async {
    // System tray disabled - not available on all platforms
    _systemTrayEnabled = false;
    debugPrint('System tray disabled on this platform');
  }

  // ============ HOTKEYS ============

  Future<void> _initializeHotkeys() async {
    try {
      debugPrint('Hotkeys initialized');
      await hotKeyManager.unregisterAll();

      // Play/Pause: Space
      await hotKeyManager.register(
        HotKey(
          key: PhysicalKeyboardKey.space,
          scope: HotKeyScope.inapp,
        ),
        keyDownHandler: (hotKey) => _onPlayPauseCallback?.call(),
      );

      // Search: Ctrl+F
      await hotKeyManager.register(
        HotKey(
          key: PhysicalKeyboardKey.keyF,
          modifiers: [HotKeyModifier.control],
          scope: HotKeyScope.inapp,
        ),
        keyDownHandler: (hotKey) => _onSearchCallback?.call(),
      );

      // Next: Right Arrow / Ctrl+Right
      await hotKeyManager.register(
        HotKey(
          key: PhysicalKeyboardKey.arrowRight,
          modifiers: [HotKeyModifier.control],
          scope: HotKeyScope.inapp,
        ),
        keyDownHandler: (hotKey) => _onNextCallback?.call(),
      );

      // Previous: Left Arrow / Ctrl+Left
      await hotKeyManager.register(
        HotKey(
          key: PhysicalKeyboardKey.arrowLeft,
          modifiers: [HotKeyModifier.control],
          scope: HotKeyScope.inapp,
        ),
        keyDownHandler: (hotKey) => _onPreviousCallback?.call(),
      );

      _hotkeysEnabled = true;
      debugPrint('Hotkeys initialized');
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
  }) {
    _onPlayPauseCallback = onPlayPause;
    _onNextCallback = onNext;
    _onPreviousCallback = onPrevious;
    _onSearchCallback = onSearch;
  }

  // ============ WINDOW MANAGEMENT ============

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

  // Window listener callbacks
  @override
  void onWindowClose() async {
    final prefs = database.getPreferences();

    // Only minimize to tray if both enabled AND successfully initialized
    if (prefs.enableSystemTray && _systemTrayEnabled) {
      // Minimize to tray instead of closing - audio continues playing
      debugPrint('Minimizing to tray - audio playback continues in background');
      await _hideWindow();
    } else {
      // User preference: exit app completely, or system tray not available
      if (prefs.enableSystemTray && !_systemTrayEnabled) {
        debugPrint(
            'System tray requested but not available - exiting normally');
      }
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

  // ============ FEATURE TOGGLES ============

  Future<void> enableSystemTray(bool enable) async {
    // System tray functionality is disabled
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

  // ============ CLEANUP ============

  Future<void> dispose() async {
    try {
      windowManager.removeListener(this);

      if (_hotkeysEnabled) {
        await hotKeyManager.unregisterAll();
      }

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
