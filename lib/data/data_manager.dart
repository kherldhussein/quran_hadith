import 'package:flutter/foundation.dart';
import 'package:quran_hadith/data/repositories/quran_repository.dart';
import 'package:quran_hadith/services/sync_service.dart';
import 'package:quran_hadith/database/database_service.dart';

/// Central data manager - Single source of truth for all data operations
class DataManager {
  static final DataManager _instance = DataManager._internal();
  factory DataManager() => _instance;
  DataManager._internal();

  final QuranRepository _repository = QuranRepository();
  final SyncService _syncService = SyncService();
  final DatabaseService _database = DatabaseService();

  bool _isInitialized = false;

  /// Initialize the entire data system
  Future<void> initialize() async {
    if (_isInitialized) {
      return;
    }
    try {
      await _database.initialize();
      await _repository.initialize();
      await _syncService.initialize();
      _isInitialized = true;

      _printStats();
    } catch (e) {
      debugPrint('DataManager: ✗ Initialization failed: $e');
      rethrow;
    }
  }

  /// Get complete Quran (instant - from cache/assets)
  Future<dynamic> getCompleteQuran({String reciterId = 'ar.alafasy'}) async {
    _ensureInitialized();
    return await _repository.getCompleteQuran(reciterId: reciterId);
  }

  /// Get single surah (instant - from cache/assets)
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
      debugPrint('DataManager: ----------------------------------------');
      debugPrint('DataManager: System Statistics:');
      debugPrint(
          'DataManager: - Memory Cached Surahs: ${stats['memoryCachedSurahs']}');
      debugPrint('DataManager: - Disk Cached Surahs: ${stats['cachedSurahs']}');
      debugPrint('DataManager: - Bookmarks: ${stats['bookmarks']}');
      debugPrint('DataManager: - Online Status: ${stats['isOnline']}');
      debugPrint('DataManager: - Is Syncing: ${stats['sync']['isSyncing']}');
      debugPrint('DataManager: ----------------------------------------');
    } catch (e) {
      debugPrint('DataManager: Error printing stats: $e');
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
  }
}

/// Global instance for easy access
final dataManager = DataManager();
