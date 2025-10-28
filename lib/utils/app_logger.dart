/// Centralized logging utility for consistent error/info/debug messages
library app_logger;

import 'package:flutter/foundation.dart';

/// Standardized logging with emoji prefixes for better visibility
class AppLogger {
  /// Log successful operations
  /// Example: ✅ Configuration loaded successfully
  static void success(String message) {
    if (kDebugMode) {
      debugPrint('✅ $message');
    }
  }

  /// Log informational messages
  /// Example: ℹ️ Starting audio playback for Ayah 5
  static void info(String message) {
    if (kDebugMode) {
      debugPrint('ℹ️ $message');
    }
  }

  /// Log warning messages (potential issues)
  /// Example: ⚠️ Audio state change already being processed, skipping...
  static void warning(String message) {
    if (kDebugMode) {
      debugPrint('⚠️ $message');
    }
  }

  /// Log error messages (something went wrong)
  /// Example: ❌ Error loading translations: Network timeout
  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      if (error != null) {
        debugPrint('❌ $message: $error');
      } else {
        debugPrint('❌ $message');
      }
      if (stackTrace != null) {
        debugPrintStack(stackTrace: stackTrace);
      }
    }
  }

  /// Log debug/technical information
  /// Example: 🔧 Initialized AudioController with reciter: Abd-Samad
  static void debug(String message) {
    if (kDebugMode) {
      debugPrint('🔧 $message');
    }
  }

  /// Log scroll/navigation events
  /// Example: 📜 Auto scrolled to Ayah 42
  static void scroll(String message) {
    if (kDebugMode) {
      debugPrint('📜 $message');
    }
  }

  /// Log playback/audio events
  /// Example: 🎵 Playing Surah Al-Baqarah - 286 ayahs
  static void audio(String message) {
    if (kDebugMode) {
      debugPrint('🎵 $message');
    }
  }

  /// Log database operations
  /// Example: 💾 Saved reading progress: Surah 2, Ayah 45
  static void database(String message) {
    if (kDebugMode) {
      debugPrint('💾 $message');
    }
  }

  /// Log UI/State changes
  /// Example: 🎨 Theme changed to Dark mode
  static void ui(String message) {
    if (kDebugMode) {
      debugPrint('🎨 $message');
    }
  }

  /// Log API/Network operations
  /// Example: 🌐 Fetching Hadith books...
  static void network(String message) {
    if (kDebugMode) {
      debugPrint('🌐 $message');
    }
  }

  /// Log preferences/settings operations
  /// Example: ⚙️ Font size changed to 20.0
  static void settings(String message) {
    if (kDebugMode) {
      debugPrint('⚙️ $message');
    }
  }

  /// Log cache operations
  /// Example: 💿 Loaded Surah from cache (expires in 1 hour)
  static void cache(String message) {
    if (kDebugMode) {
      debugPrint('💿 $message');
    }
  }
}
