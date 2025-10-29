import 'package:flutter/foundation.dart';
import 'package:quran_hadith/data/repositories/quran_repository.dart';
import 'package:quran_hadith/services/sync_service.dart';
import 'package:quran_hadith/database/database_service.dart';

/// Central data manager - Single source of truth for all data operations
///
/// This is the ONLY class the UI should interact with for data.
/// It orchestrates between repository, sync service, and database.
///
/// Benefits:
/// - Single entry point (easier to maintain)
/// - Automatic caching and sync
/// - Offline-first by default
/// - Zero user-visible loading delays
class DataManager {
  static final DataManager _instance = DataManager._internal();
  factory DataManager() => _instance;
  DataManager._internal();

  final QuranRepository _repository = QuranRepository();
  final SyncService _syncService = SyncService();
  final DatabaseService _database = DatabaseService();

  bool _isInitialized = false;

  /// Initialize the entire data system
  ///
  /// Call this ONCE at app startup (in main.dart)
  Future<void> initialize() async {
    if (_isInitialized) {
      debugPrint('💾 DataManager: Already initialized, skipping...');
      return;
    }

    debugPrint('💾 DataManager: ========================================');
    debugPrint('💾 DataManager: Initializing Data System...');
    debugPrint('💾 DataManager: ========================================');

    try {
      // Step 1: Initialize database (required first)
      await _database.initialize();
      debugPrint('💾 DataManager: ✓ Database initialized');

      // Step 2: Initialize repository (loads assets + memory cache)
      await _repository.initialize();
      debugPrint('💾 DataManager: ✓ Repository initialized');

      // Step 3: Initialize background sync (non-blocking)
      await _syncService.initialize();
      debugPrint('💾 DataManager: ✓ Sync service initialized');

      _isInitialized = true;

      debugPrint('💾 DataManager: ========================================');
      debugPrint('💾 DataManager: ✓ Data System Ready!');
      debugPrint('💾 DataManager: ========================================');

      // Print initial stats
      _printStats();
    } catch (e) {
      debugPrint('💾 DataManager: ✗ Initialization failed: $e');
      rethrow;
    }
  }

  /// Get complete Quran (instant - from cache/assets)
  ///
  /// This will NEVER wait for network. Always returns immediately.
  /// Background sync happens automatically.
  Future<dynamic> getCompleteQuran({String reciterId = 'ar.alafasy'}) async {
    _ensureInitialized();
    return await _repository.getCompleteQuran(reciterId: reciterId);
  }

  /// Get single surah (instant - from cache/assets)
  ///
  /// This will NEVER wait for network. Always returns immediately.
  /// Background sync happens automatically.
  Future<dynamic> getSurah(int surahNumber) async {
    _ensureInitialized();
    return await _repository.getSurah(surahNumber);
  }

  /// Get surah with translation (instant - from cache/assets)
  Future<dynamic> getSurahWithTranslation(
    int surahNumber, {
    String edition = 'en.sahih',
  }) async {
    _ensureInitialized();
    return await _repository.getSurahWithTranslation(
      surahNumber,
      edition: edition,
    );
  }

  /// Get ayah audio URL (requires network)
  Future<String?> getAyahAudioUrl(
    int surahNumber,
    int ayahNumber, {
    String reciterId = 'ar.alafasy',
  }) async {
    _ensureInitialized();
    return await _repository.getAyahAudioUrl(
      surahNumber,
      ayahNumber,
      reciterId: reciterId,
    );
  }

  /// Force sync now (user-initiated)
  Future<void> syncNow() async {
    _ensureInitialized();
    await _syncService.forceSyncNow();
  }

  /// Pause background sync (e.g., user on metered connection)
  void pauseSync() {
    _syncService.pauseSync();
  }

  /// Resume background sync
  Future<void> resumeSync() async {
    await _syncService.resumeSync();
  }

  /// Clear all caches (user-initiated from settings)
  Future<void> clearAllCaches() async {
    _ensureInitialized();
    await _repository.clearCaches();
    debugPrint('💾 DataManager: All caches cleared');
  }

  /// Get system statistics
  Future<Map<String, dynamic>> getStats() async {
    _ensureInitialized();

    final cacheStats = await _repository.getCacheStats();
    final syncStatus = _syncService.getSyncStatus();
    final dbStats = await _database.getStorageStats();

    return {
      ...cacheStats,
      'sync': syncStatus,
      'database': dbStats,
      'isInitialized': _isInitialized,
    };
  }

  /// Print system statistics (debugging)
  void _printStats() async {
    try {
      final stats = await getStats();
      debugPrint('💾 DataManager: ----------------------------------------');
      debugPrint('💾 DataManager: System Statistics:');
      debugPrint('💾 DataManager: - Memory Cached Surahs: ${stats['memoryCachedSurahs']}');
      debugPrint('💾 DataManager: - Disk Cached Surahs: ${stats['cachedSurahs']}');
      debugPrint('💾 DataManager: - Bookmarks: ${stats['bookmarks']}');
      debugPrint('💾 DataManager: - Online Status: ${stats['isOnline']}');
      debugPrint('💾 DataManager: - Is Syncing: ${stats['sync']['isSyncing']}');
      debugPrint('💾 DataManager: ----------------------------------------');
    } catch (e) {
      debugPrint('💾 DataManager: Error printing stats: $e');
    }
  }

  /// Ensure system is initialized
  void _ensureInitialized() {
    if (!_isInitialized) {
      throw StateError(
        'DataManager not initialized! Call DataManager().initialize() in main.dart',
      );
    }
  }

  /// Get initialization status
  bool get isInitialized => _isInitialized;

  /// Dispose resources (call on app termination)
  void dispose() {
    _syncService.dispose();
    debugPrint('💾 DataManager: Disposed');
  }
}

/// Global instance for easy access
final dataManager = DataManager();
