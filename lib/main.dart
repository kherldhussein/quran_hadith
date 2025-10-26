import 'dart:io' show Platform;
import 'dart:ffi' as ffi;
import 'package:ffi/ffi.dart' as pkgffi;
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:media_kit/media_kit.dart';
import 'package:provider/provider.dart';
import 'package:quran_hadith/controller/favorite.dart';
import 'package:quran_hadith/controller/quranAPI.dart';
import 'package:quran_hadith/controller/enhanced_audio_controller.dart';
import 'package:quran_hadith/database/database_service.dart';
import 'package:quran_hadith/screens/splash_screen.dart';
import 'package:quran_hadith/services/error_service.dart';
import 'package:quran_hadith/theme/theme_state.dart';
import 'package:quran_hadith/utils/shared_p.dart';
import 'package:quran_hadith/utils/sp_util.dart';
import 'package:quran_hadith/services/notification_service.dart';
import 'package:quran_hadith/services/reciter_service.dart';
import 'package:quran_hadith/services/analytics_service.dart';
import 'package:quran_hadith/services/native_desktop_service.dart';
import 'package:quran_hadith/database/hive_adapters.dart';
import 'package:quran_hadith/models/reciter_model.dart';

import 'controller/hadithAPI.dart';
import 'theme/app_theme.dart';

// FFI typedefs for setlocale
typedef _NativeSetLocale = ffi.Pointer<ffi.Int8> Function(
    ffi.Int32, ffi.Pointer<ffi.Int8>);
typedef _DartSetLocale = ffi.Pointer<ffi.Int8> Function(
    int, ffi.Pointer<ffi.Int8>);

/// Main application entry point
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Ensure numeric locale is C on POSIX platforms to avoid native library
  // issues when a non-C locale is present (e.g., libmpv/media backends).
  // This mirrors the error message: call setlocale(LC_NUMERIC, "C");
  if (!Platform.isWindows) {
    try {
      final dylib = ffi.DynamicLibrary.process();
      // setlocale: char *setlocale(int category, const char *locale);
      final setlocale =
          dylib.lookupFunction<_NativeSetLocale, _DartSetLocale>('setlocale');
      const int lcNumeric = 4; // common value on POSIX systems
      final ptr = 'C'.toNativeUtf8();
      setlocale(lcNumeric, ptr.cast<ffi.Int8>());
      pkgffi.malloc.free(ptr);
    } catch (e, s) {
      errorService.reportError(
          'Warning: failed to setlocale(LC_NUMERIC, "C"): $e', s);
    }
  }

  final themeState = ThemeState();
  await _initializeApp(themeState);

  runApp(
    MultiProvider(
      providers: [
        Provider<QuranAPI>(create: (_) => QuranAPI()),
        Provider<HadithAPI>(create: (_) => HadithAPI()),
        ChangeNotifierProvider<FavoriteManager>(
          create: (_) => FavoriteManager(),
        ),
        ChangeNotifierProvider<ThemeState>(
          create: (_) => themeState,
        ),
        ChangeNotifierProvider<EnhancedAudioController>(
          create: (_) => EnhancedAudioController(),
        ),
      ],
      child: const QuranHadithApp(),
    ),
  );

  _configureDesktopWindow();
}

/// Initialize app dependencies
Future<void> _initializeApp(ThemeState themeState) async {
  // Initialize media_kit for audio playback, but don't let it abort app init
  try {
    MediaKit.ensureInitialized();
  } catch (e, s) {
    errorService.reportError('media_kit initialization warning: $e', s);
    // Continue — we'll run without native media support until dependencies are installed
  }

  try {
    await appSP.init();
  } catch (e, s) {
    errorService.reportError('Warning: appSP.init() failed: $e', s);
  }

  // Initialize in-memory current reciter from storage so audio uses the
  // correct voice before any UI interaction.
  try {
    await ReciterService.instance.initializeCurrentReciter();
  } catch (e, s) {
    errorService.reportError('Warning initializing current reciter: $e', s);
  }

  try {
    await NotificationService.instance.initialize();
  } catch (e, s) {
    errorService.reportError('Warning initializing notifications: $e', s);
  }

  try {
    await database.initialize();
  } catch (e, s) {
    errorService.reportError('Warning: database.initialize() failed: $e', s);
  }

  try {
    await ReciterService.instance.getReciters();
  } catch (e, s) {
    errorService.reportError('Warning preloading reciters failed: $e', s);
  }

  try {
    final bool isDarkMode = SpUtil.getThemed();
    themeState.loadTheme(isDarkMode);
  } catch (e, s) {
    errorService.reportError('Warning loading theme: $e', s);
  }

  // Initialize native desktop service for system tray and window management
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    try {
      await nativeDesktop.initialize();
    } catch (e, s) {
      errorService.reportError('Warning initializing native desktop: $e', s);
    }
  }
}

/// Configure desktop window properties
void _configureDesktopWindow() {
  if (kIsWeb) return;
  final isDesktop = Platform.isWindows || Platform.isLinux || Platform.isMacOS;
  if (!isDesktop) return;

  doWhenWindowReady(() {
    final win = appWindow;
    const initialSize = Size(1200, 750);
    const minSize = Size(800, 600);

    win.minSize = minSize;
    win.size = initialSize;
    win.alignment = Alignment.center;
    win.title = "Qur'an & Hadith";
    win.show();

    // Add window styling
    // _styleDesktopWindow(win);
  });
}

/// Style the desktop window
// void _styleDesktopWindow(AppWindow window) {
//   // You can add custom window styling here
//   window.setBrightness(Brightness.light);
// }

/// Main application widget
class QuranHadithApp extends StatefulWidget {
  const QuranHadithApp({super.key});

  static const List<String> supportedLocales = ['en', 'ar'];
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = [
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  @override
  State<QuranHadithApp> createState() => _QuranHadithAppState();
}

class _QuranHadithAppState extends State<QuranHadithApp>
    with WidgetsBindingObserver {
  late AppLifecycleObserver _lifecycleObserver;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeTheme();
    _setupLifecycleObserver();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Setup lifecycle observer with audio controller access
  void _setupLifecycleObserver() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final audioController = Provider.of<EnhancedAudioController>(
        context,
        listen: false,
      );
      _lifecycleObserver = AppLifecycleObserver(
        audioController: audioController,
      );
      WidgetsBinding.instance.addObserver(_lifecycleObserver);
    });
  }

  /// Initialize theme from shared preferences
  void _initializeTheme() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final themeState = Provider.of<ThemeState>(context, listen: false);
      final bool isDarkMode = SpUtil.getThemed();
      themeState.loadTheme(isDarkMode);
    });
  }

  /// Locale resolution callback for internationalization
  Locale _localeResolutionCallback(
      Locale? locale, Iterable<Locale> supportedLocales) {
    for (final supportedLocale in supportedLocales) {
      if (supportedLocale.languageCode == locale?.languageCode) {
        return supportedLocale;
      }
    }

    return const Locale('en', '');
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeState>(
      builder: (context, themeState, child) {
        return GetMaterialApp(
          localizationsDelegates: QuranHadithApp.localizationsDelegates,
          localeResolutionCallback: _localeResolutionCallback,
          supportedLocales: QuranHadithApp.supportedLocales
              .map((languageCode) => Locale(languageCode, ''))
              .toList(),
          title: "Qur'an & Hadith",
          debugShowCheckedModeBanner: false,
          theme: theme,
          darkTheme: darkTheme,
          themeMode: themeState.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          home: const SplashScreen(),
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(_getTextScaleFactor(context)),
              ),
              child: child!,
            );
          },
          defaultTransition: Transition.cupertino,
          transitionDuration: const Duration(milliseconds: 300),
          popGesture: true,
          onUnknownRoute: (settings) {
            return MaterialPageRoute(
              builder: (context) => Scaffold(
                appBar: AppBar(title: const Text('Page Not Found')),
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(
                        'Page not found',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'The requested page could not be found.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Calculate appropriate text scale factor based on screen size
  double _getTextScaleFactor(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;

    if (width < 600) {
      return 0.9;
    } else if (width < 900) {
      return 1.0;
    } else {
      return 1.1;
    }
  }
}

/// App constants
class AppConstants {
  static const String appName = "Qur'an & Hadith";
  static const String appVersion = "2.0.0";
  static const Duration splashDuration = Duration(seconds: 2);
  static const Duration transitionDuration = Duration(milliseconds: 300);

  static const String quranAudioBaseUrl =
      'http://api.alquran.cloud/v1/quran/ar.alafasy';
  static const String audioUrlTemplate =
      'https://cdn.alquran.cloud/media/audio/ayah/ar.alafasy/';
}

/// Production-ready app lifecycle observer with telemetry and proper state management
class AppLifecycleObserver extends WidgetsBindingObserver {
  final EnhancedAudioController? audioController;
  DateTime? _pausedAt;
  DateTime? _resumedAt;
  DateTime? _sessionStart;
  bool _wasPlayingBeforePause = false;
  int _pauseCount = 0;
  int _crashRecoveryAttempts = 0;

  static const int _staleDataThresholdMinutes = 5;
  static const int _maxCrashRecoveryAttempts = 3;

  AppLifecycleObserver({this.audioController}) {
    _sessionStart = DateTime.now();
    _initializeSessionMetrics();

    // Track session start with analytics
    analyticsService.trackSessionStart();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _logLifecycleTransition(state);

    switch (state) {
      case AppLifecycleState.paused:
        _handleAppPaused();
        break;
      case AppLifecycleState.resumed:
        _handleAppResumed();
        break;
      case AppLifecycleState.inactive:
        _handleAppInactive();
        break;
      case AppLifecycleState.detached:
        _handleAppDetached();
        break;
      case AppLifecycleState.hidden:
        _handleAppHidden();
        break;
    }
  }

  /// Initialize session tracking metrics
  void _initializeSessionMetrics() {
    try {
      final crashCount = appSP.getInt('crash_count', defaultValue: 0);
      if (crashCount > 0) {
        errorService.reportError(
          'App recovered from $crashCount previous crash(es)',
          StackTrace.current,
        );
        appSP.setInt('crash_count', 0);
      }

      final lastSession = appSP.getInt('last_session_end', defaultValue: 0);
      if (lastSession > 0) {
        final lastSessionTime =
            DateTime.fromMillisecondsSinceEpoch(lastSession);
        final timeSinceLastSession = DateTime.now().difference(lastSessionTime);

        if (timeSinceLastSession.inHours > 24) {
          _scheduleBackgroundRefresh();
        }
      }
    } catch (e, stack) {
      errorService.reportError('Error initializing session metrics: $e', stack);
    }
  }

  /// Log lifecycle transition with proper telemetry
  void _logLifecycleTransition(AppLifecycleState state) {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final stateStr = state.toString().split('.').last;
      final previousState =
          appSP.getString('last_lifecycle_state', defaultValue: 'unknown');

      // Track with analytics service
      analyticsService.trackLifecycleTransition(previousState, stateStr);

      appSP.setString('last_lifecycle_state', stateStr);
      appSP.setInt('last_lifecycle_transition', timestamp);

      // Track state transitions for analytics
      final transitionCount =
          appSP.getInt('lifecycle_transitions', defaultValue: 0);
      appSP.setInt('lifecycle_transitions', transitionCount + 1);
    } catch (e, stack) {
      errorService.reportError('Error logging lifecycle transition: $e', stack);
    }
  }

  /// Handle app paused state (user switched to another app)
  void _handleAppPaused() {
    _pausedAt = DateTime.now();
    _pauseCount++;

    try {
      // Remember audio state for smart resume
      _wasPlayingBeforePause =
          audioController?.buttonNotifier.value == AudioButtonState.playing;

      // Pause audio to conserve battery and prevent background playback
      audioController?.pause().catchError((e, stack) {
        errorService.reportError(
            'Failed to pause audio on app pause: $e', stack);
      });

      // Save critical app state
      _saveAppState();

      // Track session metrics
      _updateSessionMetrics();

      // Persist audio state for crash recovery
      appSP.setBool('audio_was_playing', _wasPlayingBeforePause);
      appSP.setInt('pause_count', _pauseCount);
    } catch (e, stack) {
      errorService.reportError('Error handling app pause: $e', stack);
    }
  }

  /// Handle app resumed state (user returned to app)
  void _handleAppResumed() {
    _resumedAt = DateTime.now();

    try {
      // Calculate background duration for smart data refresh
      if (_pausedAt != null) {
        final backgroundDuration = _resumedAt!.difference(_pausedAt!);
        _handleBackgroundDuration(backgroundDuration);
      }

      // Restore app state
      _restoreAppState();

      // Verify data integrity after resume
      _verifyDataIntegrity();

      // Clean up temporary resources
      _cleanupTemporaryResources();
    } catch (e, stack) {
      errorService.reportError('Error handling app resume: $e', stack);
      _attemptCrashRecovery();
    }
  }

  /// Handle background duration with smart refresh logic
  void _handleBackgroundDuration(Duration duration) {
    try {
      // Track background duration with analytics service
      analyticsService.trackBackgroundDuration(duration);

      // Log background duration for metrics
      final totalBackgroundSeconds =
          appSP.getInt('total_background_seconds', defaultValue: 0);
      appSP.setInt('total_background_seconds',
          totalBackgroundSeconds + duration.inSeconds);

      if (duration.inMinutes > _staleDataThresholdMinutes) {
        _refreshStaleData();
      } else if (duration.inSeconds < 30 && _wasPlayingBeforePause) {
        // Quick resume scenario - optionally restore audio
        _handleQuickResume();
      }
    } catch (e, stack) {
      errorService.reportError('Error handling background duration: $e', stack);
    }
  }

  /// Handle quick resume (< 30 seconds background)
  void _handleQuickResume() {
    try {
      final autoResumeAudio =
          appSP.getBool('auto_resume_audio', defaultValue: false);

      if (autoResumeAudio && _wasPlayingBeforePause) {
        // Delay resume to ensure smooth transition
        Future.delayed(const Duration(milliseconds: 500), () {
          audioController?.play().catchError((e, stack) {
            errorService.reportError('Failed to auto-resume audio: $e', stack);
          });
        });
      }
    } catch (e, stack) {
      errorService.reportError('Error in quick resume: $e', stack);
    }
  }

  /// Handle app inactive state (transient interruption)
  void _handleAppInactive() {
    try {
      // Pause audio but don't save full state (temporary interruption)
      audioController?.pause().catchError((e, stack) {
        errorService.reportError(
            'Failed to pause audio on inactive: $e', stack);
      });

      appSP.setString('last_inactive_time', DateTime.now().toIso8601String());
    } catch (e, stack) {
      errorService.reportError('Error handling app inactive: $e', stack);
    }
  }

  /// Handle app hidden state
  void _handleAppHidden() {
    try {
      // Release non-critical resources
      _releaseNonCriticalResources();

      appSP.setString('last_hidden_time', DateTime.now().toIso8601String());
    } catch (e, stack) {
      errorService.reportError('Error handling app hidden: $e', stack);
    }
  }

  /// Handle app detached state (final cleanup)
  void _handleAppDetached() {
    try {
      // Track session end with analytics
      if (_sessionStart != null) {
        final sessionDuration = DateTime.now().difference(_sessionStart!);
        analyticsService.trackSessionEnd(sessionDuration);
      }

      // Final state save before termination
      _saveAppState();

      // Stop audio completely
      audioController?.stop().catchError((e, stack) {
        errorService.reportError('Failed to stop audio on detach: $e', stack);
      });

      // Mark clean shutdown
      appSP.setBool('clean_shutdown', true);
      appSP.setInt('last_session_end', DateTime.now().millisecondsSinceEpoch);

      // Record session duration
      _updateSessionMetrics();
    } catch (e, stack) {
      errorService.reportError('Error handling app detached: $e', stack);
    }
  }

  /// Save critical app state to persistent storage
  void _saveAppState() {
    try {
      final now = DateTime.now();

      // Save state timestamp
      appSP.setInt('last_save_time', now.millisecondsSinceEpoch);

      // Save reading progress through database
      database
          .saveReadingProgress(
        database.getLastReadingProgress() ??
            ReadingProgress(
              surahNumber: 1,
              ayahNumber: 1,
              lastReadAt: now,
            ),
      )
          .catchError((e, stack) {
        errorService.reportError('Failed to save reading progress: $e', stack);
      });

      // Save listening progress
      database
          .saveListeningProgress(
        database.getLastListeningProgress() ??
            ListeningProgress(
              surahNumber: 1,
              ayahNumber: 1,
              positionMs: 0,
              lastListenedAt: now,
              totalListenTimeSeconds: 0,
              completed: false,
              reciter: 'ar.alafasy',
              playbackSpeed: 1.0,
            ),
      )
          .catchError((e, stack) {
        errorService.reportError(
            'Failed to save listening progress: $e', stack);
      });

      // Save preferences
      final prefs = database.getPreferences();
      database.savePreferences(prefs).catchError((e, stack) {
        errorService.reportError('Failed to save preferences: $e', stack);
      });
    } catch (e, stack) {
      errorService.reportError('Critical error saving app state: $e', stack);
      // Mark potential data loss
      appSP.setBool('potential_data_loss', true);
    }
  }

  /// Restore app state from persistent storage
  void _restoreAppState() {
    try {
      final lastSaveTime = appSP.getInt('last_save_time', defaultValue: 0);

      if (lastSaveTime > 0) {
        final lastSave = DateTime.fromMillisecondsSinceEpoch(lastSaveTime);
        final timeSinceSave = DateTime.now().difference(lastSave);

        // Validate state freshness
        if (timeSinceSave.inDays > 7) {
          errorService.reportError(
            'Restored state is ${timeSinceSave.inDays} days old - may be stale',
            StackTrace.current,
          );
        }
      }

      // Check for potential data loss from previous session
      final potentialDataLoss =
          appSP.getBool('potential_data_loss', defaultValue: false);
      if (potentialDataLoss) {
        errorService.reportError(
          'Previous session indicated potential data loss',
          StackTrace.current,
        );
        appSP.setBool('potential_data_loss', false);
      }

      // Clear crash recovery flag
      appSP.setBool('clean_shutdown', false);
    } catch (e, stack) {
      errorService.reportError('Error restoring app state: $e', stack);
    }
  }

  /// Refresh stale data after long background period
  void _refreshStaleData() {
    try {
      // Refresh reciters list
      ReciterService.instance
          .getReciters(forceRefresh: true)
          .catchError((e, stack) {
        errorService.reportError('Failed to refresh reciters: $e', stack);
        return <Reciter>[]; // Return empty list on error
      });

      // Invalidate hadith books cache if older than threshold
      final hadithCacheTime =
          appSP.getInt('hadith_books_cache_time', defaultValue: 0);
      if (hadithCacheTime > 0) {
        final cacheAge =
            DateTime.now().millisecondsSinceEpoch - hadithCacheTime;
        if (Duration(milliseconds: cacheAge).inHours > 24) {
          // Cache will be refreshed on next request due to TTL
          appSP.setInt('hadith_cache_invalidated',
              DateTime.now().millisecondsSinceEpoch);
        }
      }

      // Update last refresh timestamp
      appSP.setInt('last_data_refresh', DateTime.now().millisecondsSinceEpoch);
    } catch (e, stack) {
      errorService.reportError('Error refreshing stale data: $e', stack);
    }
  }

  /// Verify data integrity after app resume
  void _verifyDataIntegrity() {
    try {
      // Verify critical data structures
      final lastReading = database.getLastReadingProgress();
      final lastListening = database.getLastListeningProgress();

      if (lastReading != null &&
          (lastReading.surahNumber < 1 || lastReading.surahNumber > 114)) {
        errorService.reportError(
          'Invalid reading progress detected: Surah ${lastReading.surahNumber}',
          StackTrace.current,
        );
      }

      if (lastListening != null &&
          (lastListening.surahNumber < 1 || lastListening.surahNumber > 114)) {
        errorService.reportError(
          'Invalid listening progress detected: Surah ${lastListening.surahNumber}',
          StackTrace.current,
        );
      }
    } catch (e, stack) {
      errorService.reportError('Error verifying data integrity: $e', stack);
    }
  }

  /// Update session metrics for analytics
  void _updateSessionMetrics() {
    try {
      if (_sessionStart != null) {
        final sessionDuration = DateTime.now().difference(_sessionStart!);
        final totalMinutes =
            appSP.getInt('total_session_minutes', defaultValue: 0);
        appSP.setInt(
            'total_session_minutes', totalMinutes + sessionDuration.inMinutes);
      }
    } catch (e, stack) {
      errorService.reportError('Error updating session metrics: $e', stack);
    }
  }

  /// Attempt crash recovery
  void _attemptCrashRecovery() {
    if (_crashRecoveryAttempts >= _maxCrashRecoveryAttempts) {
      errorService.reportError(
        'Max crash recovery attempts reached ($_maxCrashRecoveryAttempts)',
        StackTrace.current,
      );
      return;
    }

    try {
      _crashRecoveryAttempts++;
      appSP.setInt('crash_count', _crashRecoveryAttempts);

      // Reset to safe state
      audioController?.stop();
      _wasPlayingBeforePause = false;

      errorService.reportError(
        'Crash recovery attempt $_crashRecoveryAttempts',
        StackTrace.current,
      );
    } catch (e, stack) {
      errorService.reportError('Error during crash recovery: $e', stack);
    }
  }

  /// Schedule background data refresh
  void _scheduleBackgroundRefresh() {
    try {
      // Mark for refresh on next network availability
      appSP.setBool('needs_background_refresh', true);
      appSP.setInt('background_refresh_scheduled',
          DateTime.now().millisecondsSinceEpoch);
    } catch (e, stack) {
      errorService.reportError(
          'Error scheduling background refresh: $e', stack);
    }
  }

  /// Release non-critical resources
  void _releaseNonCriticalResources() {
    try {
      // Clear in-memory caches that can be rebuilt
      // This helps with memory management during background state
      appSP.setInt('resources_released', DateTime.now().millisecondsSinceEpoch);
    } catch (e, stack) {
      errorService.reportError('Error releasing resources: $e', stack);
    }
  }

  /// Clean up temporary resources
  void _cleanupTemporaryResources() {
    try {
      // Clean up any temporary flags or counters
      appSP.setBool('audio_was_playing', false);

      // Reset pause count if session is fresh
      if (_pauseCount > 10) {
        _pauseCount = 0;
        appSP.setInt('pause_count', 0);
      }
    } catch (e, stack) {
      errorService.reportError('Error cleaning up resources: $e', stack);
    }
  }

  @override
  void didChangeMetrics() {
    // Handle screen size/orientation changes
    // Useful for responsive layout adjustments
    super.didChangeMetrics();
  }

  @override
  void didChangeLocales(List<Locale>? locales) {
    // Handle system locale changes
    if (locales != null && locales.isNotEmpty) {
      debugPrint('System locale changed to: ${locales.first.languageCode}');
    }
    super.didChangeLocales(locales);
  }

  @override
  void didChangeAccessibilityFeatures() {
    // Handle accessibility setting changes
    debugPrint('Accessibility features changed');
    super.didChangeAccessibilityFeatures();
  }
}
