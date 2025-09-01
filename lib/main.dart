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
import 'package:quran_hadith/theme/theme_state.dart';
import 'package:quran_hadith/utils/shared_p.dart';
import 'package:quran_hadith/utils/sp_util.dart';
import 'package:quran_hadith/services/notification_service.dart';
import 'package:quran_hadith/services/reciter_service.dart';

import 'controller/hadithAPI.dart';
import 'theme/app_theme.dart';

// Global instances
final quranApi = QuranAPI();
final hadithApi = HadithAPI();
final themeState = ThemeState();

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
      const int LC_NUMERIC = 4; // common value on POSIX systems
      final ptr = 'C'.toNativeUtf8();
      setlocale(LC_NUMERIC, ptr.cast<ffi.Int8>());
      pkgffi.malloc.free(ptr);
    } catch (e) {
      debugPrint('Warning: failed to setlocale(LC_NUMERIC, "C"): $e');
    }
  }

  await _initializeApp();

  runApp(
    MultiProvider(
      providers: [
        Provider<QuranAPI>(create: (_) => quranApi),
        Provider<HadithAPI>(create: (_) => hadithApi),
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
Future<void> _initializeApp() async {
  // Initialize media_kit for audio playback, but don't let it abort app init
  try {
    MediaKit.ensureInitialized();
  } catch (e) {
    debugPrint('media_kit initialization warning: $e');
    // Continue — we'll run without native media support until dependencies are installed
  }

  try {
    await appSP.init();
  } catch (e) {
    debugPrint('Warning: appSP.init() failed: $e');
  }

  try {
    await NotificationService.instance.initialize();
  } catch (e) {
    debugPrint('Warning initializing notifications: $e');
  }

  try {
    await database.initialize();
  } catch (e) {
    debugPrint('Warning: database.initialize() failed: $e');
  }

  try {
    await ReciterService.instance.getReciters();
  } catch (e) {
    debugPrint('Warning preloading reciters failed: $e');
  }

  try {
    final bool isDarkMode = SpUtil.getThemed();
    themeState.loadTheme(isDarkMode);
  } catch (e) {
    debugPrint('Warning loading theme: $e');
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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeTheme();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
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
  static const String appVersion = "1.0.0";
  static const Duration splashDuration = Duration(seconds: 2);
  static const Duration transitionDuration = Duration(milliseconds: 300);

  static const String quranAudioBaseUrl =
      'http://api.alquran.cloud/v1/quran/ar.alafasy';
  static const String audioUrlTemplate =
      'https://cdn.alquran.cloud/media/audio/ayah/ar.alafasy/';
}

/// App lifecycle observer for handling app state changes
class AppLifecycleObserver extends WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        debugPrint('App resumed');
        // Resume any paused services
        break;
      case AppLifecycleState.inactive:
        debugPrint('App inactive');
        // Pause ongoing operations
        break;
      case AppLifecycleState.paused:
        debugPrint('App paused');
        // Save state if needed
        break;
      case AppLifecycleState.detached:
        debugPrint('App detached');
        // Clean up resources
        break;
      case AppLifecycleState.hidden:
        debugPrint('App hidden');
        // Treat hidden similar to paused on desktop
        break;
    }
  }
}
