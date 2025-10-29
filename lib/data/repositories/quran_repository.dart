import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:quran_hadith/models/surah_model.dart';
import 'package:quran_hadith/database/database_service.dart';
import 'package:quran_hadith/database/hive_adapters.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;

/// Enterprise-grade Quran data repository with multi-layer caching
///
/// Architecture:
/// Layer 1: Memory Cache (fastest - RAM)
/// Layer 2: Disk Cache (fast - Hive/SQLite)
/// Layer 3: Assets Bundle (fast - embedded in app)
/// Layer 4: Network API (slow - requires internet)
///
/// Strategy: Offline-first with background sync
class QuranRepository {
  static final QuranRepository _instance = QuranRepository._internal();
  factory QuranRepository() => _instance;
  QuranRepository._internal();

  final DatabaseService _db = DatabaseService();

  // Layer 1: Memory cache (fastest)
  final Map<int, SurahList> _memoryCacheSurah = {};
  final Map<String, Map<int, String>> _memoryCacheTranslations = {};
  SurahList? _memoryCacheFullQuran;

  // Cache metadata
  DateTime? _lastNetworkCheck;
  bool _isOnline = false;
  bool _isInitialized = false;

  // Configuration
  static const Duration _networkCheckInterval = Duration(minutes: 5);
  static const Duration _cacheExpiry = Duration(days: 7);
  static const int _maxMemoryCacheSize = 50; // Max surahs in memory

  /// Initialize the repository
  Future<void> initialize() async {
    if (_isInitialized) return;

    debugPrint('📦 QuranRepository: Initializing...');

    // Initialize database
    await _db.initialize();

    // Check connectivity
    await _checkConnectivity();

    // Load frequently accessed data into memory
    await _preloadCommonSurahs();

    _isInitialized = true;
    debugPrint('📦 QuranRepository: Initialized successfully');
  }

  /// Preload commonly read surahs into memory
  Future<void> _preloadCommonSurahs() async {
    final commonSurahs = [1, 2, 18, 36, 55, 67, 78]; // Frequently read surahs

    for (final surahNumber in commonSurahs) {
      try {
        await getSurah(surahNumber, preload: true);
      } catch (e) {
        debugPrint('📦 QuranRepository: Failed to preload surah $surahNumber: $e');
      }
    }
  }

  /// Check network connectivity
  Future<void> _checkConnectivity() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      _isOnline = connectivityResult.contains(ConnectivityResult.mobile) ||
          connectivityResult.contains(ConnectivityResult.wifi) ||
          connectivityResult.contains(ConnectivityResult.ethernet);
      _lastNetworkCheck = DateTime.now();
      debugPrint('📦 QuranRepository: Network status = ${_isOnline ? "ONLINE" : "OFFLINE"}');
    } catch (e) {
      _isOnline = false;
      debugPrint('📦 QuranRepository: Connectivity check failed: $e');
    }
  }

  /// Get complete Quran with all surahs and audio URLs
  Future<SurahList> getCompleteQuran({String reciterId = 'ar.alafasy'}) async {
    debugPrint('📦 QuranRepository: Getting complete Quran (reciter: $reciterId)');

    // Layer 1: Check memory cache
    if (_memoryCacheFullQuran != null) {
      debugPrint('📦 QuranRepository: ✓ Returned from memory cache [0ms]');
      return _memoryCacheFullQuran!;
    }

    // Layer 2: Check disk cache (Hive)
    final cachedSurahs = _db.getAllCachedSurahs();
    if (cachedSurahs.length == 114 && _isCacheValid(cachedSurahs.first.cachedAt)) {
      debugPrint('📦 QuranRepository: ✓ Returned from disk cache [${cachedSurahs.length} surahs]');
      final surahList = _buildSurahListFromCache(cachedSurahs);
      _memoryCacheFullQuran = surahList;
      return surahList;
    }

    // Layer 3: Load from assets (ALWAYS available)
    debugPrint('📦 QuranRepository: Loading from assets...');
    final surahList = await _loadQuranFromAssets();
    _memoryCacheFullQuran = surahList;

    // Background sync with network if available
    _backgroundSyncQuran(reciterId);

    return surahList;
  }

  /// Get a specific surah
  Future<SurahList> getSurah(int surahNumber, {bool preload = false}) async {
    if (!preload) {
      debugPrint('📦 QuranRepository: Getting surah $surahNumber');
    }

    // Layer 1: Check memory cache
    if (_memoryCacheSurah.containsKey(surahNumber)) {
      if (!preload) {
        debugPrint('📦 QuranRepository: ✓ Returned from memory cache [0ms]');
      }
      return _memoryCacheSurah[surahNumber]!;
    }

    // Layer 2: Check disk cache
    final cached = _db.getCachedSurah(surahNumber);
    if (cached != null && _isCacheValid(cached.cachedAt)) {
      if (!preload) {
        debugPrint('📦 QuranRepository: ✓ Returned from disk cache');
      }
      final surahList = _convertCachedSurahToSurahList(cached);
      _addToMemoryCache(surahNumber, surahList);
      return surahList;
    }

    // Layer 3: Load from assets
    if (!preload) {
      debugPrint('📦 QuranRepository: Loading from assets...');
    }
    final surahList = await _loadSurahFromAssets(surahNumber);
    _addToMemoryCache(surahNumber, surahList);

    // Background sync with network if available
    if (!preload) {
      _backgroundSyncSurah(surahNumber);
    }

    return surahList;
  }

  /// Get surah with translations
  Future<SurahList> getSurahWithTranslation(
    int surahNumber, {
    String edition = 'en.sahih',
  }) async {
    debugPrint('📦 QuranRepository: Getting surah $surahNumber with translation');

    // Get base surah data
    final surahList = await getSurah(surahNumber);

    // Check translation cache
    final cacheKey = '${surahNumber}_$edition';
    if (_memoryCacheTranslations.containsKey(cacheKey)) {
      debugPrint('📦 QuranRepository: ✓ Translation from memory cache');
      _attachTranslations(surahList, _memoryCacheTranslations[cacheKey]!);
      return surahList;
    }

    // Try loading translation from network/cache
    final translations = await _getTranslations(surahNumber, edition);
    if (translations.isNotEmpty) {
      _memoryCacheTranslations[cacheKey] = translations;
      _attachTranslations(surahList, translations);
    }

    return surahList;
  }

  /// Get audio URL for ayah
  Future<String?> getAyahAudioUrl(
    int surahNumber,
    int ayahNumber, {
    String reciterId = 'ar.alafasy',
  }) async {
    // Check if we need to update connectivity status
    if (_lastNetworkCheck == null ||
        DateTime.now().difference(_lastNetworkCheck!) > _networkCheckInterval) {
      await _checkConnectivity();
    }

    if (!_isOnline) {
      debugPrint('📦 QuranRepository: ⚠ Offline - cannot fetch audio URL');
      return null;
    }

    try {
      final globalIndex = _calculateGlobalAyahIndex(surahNumber, ayahNumber);
      final audioUrl =
          'https://cdn.islamic.network/quran/audio/128/$reciterId/$globalIndex.mp3';

      debugPrint('📦 QuranRepository: Generated audio URL');
      return audioUrl;
    } catch (e) {
      debugPrint('📦 QuranRepository: Error getting audio URL: $e');
      return null;
    }
  }

  /// Background sync from network (non-blocking)
  void _backgroundSyncQuran(String reciterId) async {
    if (!_isOnline) return;

    try {
      debugPrint('📦 QuranRepository: 🔄 Background sync started');

      final url = "https://api.alquran.cloud/v1/quran/$reciterId";
      final response = await http.get(Uri.parse(url)).timeout(
        const Duration(seconds: 30),
      );

      if (response.statusCode == 200) {
        final surahList = SurahList.fromJSON(json.decode(response.body));

        // Cache all surahs
        if (surahList.surahs != null) {
          for (final surah in surahList.surahs!) {
            await _cacheSurahToDisk(surah);
          }
        }

        debugPrint('📦 QuranRepository: ✓ Background sync completed');
      }
    } catch (e) {
      debugPrint('📦 QuranRepository: Background sync failed (non-critical): $e');
    }
  }

  /// Background sync single surah
  void _backgroundSyncSurah(int surahNumber) async {
    if (!_isOnline) return;

    try {
      debugPrint('📦 QuranRepository: 🔄 Background syncing surah $surahNumber');

      final url = "https://api.alquran.cloud/v1/surah/$surahNumber/quran-uthmani";
      final response = await http.get(Uri.parse(url)).timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final surah = Surah.fromJSON(data['data']);
        await _cacheSurahToDisk(surah);

        debugPrint('📦 QuranRepository: ✓ Surah $surahNumber synced');
      }
    } catch (e) {
      debugPrint('📦 QuranRepository: Background sync failed (non-critical): $e');
    }
  }

  /// Load Quran from bundled assets (ALWAYS available)
  Future<SurahList> _loadQuranFromAssets() async {
    try {
      final List<Surah> surahs = [];

      // Load all 114 surahs from assets
      for (int i = 1; i <= 114; i++) {
        try {
          final surahData = await rootBundle.loadString('assets/surah_$i.json');
          final decoded = json.decode(surahData);

          // Parse the surah data
          final surah = _parseSurahFromAsset(decoded, i);
          surahs.add(surah);
        } catch (e) {
          debugPrint('📦 QuranRepository: Error loading surah $i from assets: $e');
        }
      }

      debugPrint('📦 QuranRepository: ✓ Loaded ${surahs.length} surahs from assets');

      return SurahList(
        surahs: surahs,
      );
    } catch (e) {
      debugPrint('📦 QuranRepository: ✗ Failed to load from assets: $e');
      rethrow;
    }
  }

  /// Load single surah from assets
  Future<SurahList> _loadSurahFromAssets(int surahNumber) async {
    try {
      final surahData = await rootBundle.loadString('assets/surah_$surahNumber.json');
      final decoded = json.decode(surahData);
      final surah = _parseSurahFromAsset(decoded, surahNumber);

      return SurahList(
        surahs: [surah],
      );
    } catch (e) {
      debugPrint('📦 QuranRepository: ✗ Failed to load surah $surahNumber from assets: $e');
      rethrow;
    }
  }

  /// Parse surah from asset JSON
  Surah _parseSurahFromAsset(Map<String, dynamic> data, int surahNumber) {
    final List<Ayah> ayahs = [];

    // Parse ayahs
    for (int i = 1; i <= (data['verse_count'] ?? 0); i++) {
      final verseKey = 'verse_$i';
      if (data.containsKey(verseKey)) {
        ayahs.add(Ayah(
          number: i,
          text: data[verseKey],
        ));
      }
    }

    return Surah(
      number: surahNumber,
      name: data['name'] ?? 'Surah $surahNumber',
      englishName: data['english_name'] ?? '',
      englishNameTranslation: data['english_translation'] ?? '',
      revelationType: data['revelation_type'] ?? 'Meccan',
      numberOfAyahs: ayahs.length,
      ayahs: ayahs,
    );
  }

  /// Cache surah to disk
  Future<void> _cacheSurahToDisk(Surah surah) async {
    try {
      final cachedAyahs = surah.ayahs!.asMap().entries.map((entry) {
        final ayah = entry.value;
        return CachedAyah(
          number: ayah.number ?? (entry.key + 1),
          text: ayah.text ?? '',
          numberInSurah: ayah.number ?? (entry.key + 1),
          juz: 1, // Default juz
          audioUrl: null,
        );
      }).toList();

      final cachedSurah = CachedSurah(
        number: surah.number!,
        name: surah.name!,
        englishName: surah.englishName!,
        englishNameTranslation: surah.englishNameTranslation!,
        revelationType: surah.revelationType!,
        numberOfAyahs: surah.numberOfAyahs!,
        ayahs: cachedAyahs,
      );

      await _db.cacheSurah(cachedSurah);
    } catch (e) {
      debugPrint('📦 QuranRepository: Error caching surah to disk: $e');
    }
  }

  /// Get translations from network or cache
  Future<Map<int, String>> _getTranslations(int surahNumber, String edition) async {
    // TODO: Implement translation caching and fetching
    // For now, return empty map
    return {};
  }

  /// Convert cached surah to SurahList
  SurahList _convertCachedSurahToSurahList(CachedSurah cached) {
    final ayahs = cached.ayahs.map((cachedAyah) => Ayah(
      number: cachedAyah.numberInSurah,
      text: cachedAyah.text,
    )).toList();

    final surah = Surah(
      number: cached.number,
      name: cached.name,
      englishName: cached.englishName,
      englishNameTranslation: cached.englishNameTranslation,
      revelationType: cached.revelationType,
      numberOfAyahs: cached.numberOfAyahs,
      ayahs: ayahs,
    );

    return SurahList(
      surahs: [surah],
    );
  }

  /// Build SurahList from multiple cached surahs
  SurahList _buildSurahListFromCache(List<CachedSurah> cachedSurahs) {
    final surahs = cachedSurahs.map((cached) {
      final ayahs = cached.ayahs.map((cachedAyah) => Ayah(
        number: cachedAyah.numberInSurah,
        text: cachedAyah.text,
      )).toList();

      return Surah(
        number: cached.number,
        name: cached.name,
        englishName: cached.englishName,
        englishNameTranslation: cached.englishNameTranslation,
        revelationType: cached.revelationType,
        numberOfAyahs: cached.numberOfAyahs,
        ayahs: ayahs,
      );
    }).toList();

    return SurahList(
      surahs: surahs,
    );
  }

  /// Add to memory cache with LRU eviction
  void _addToMemoryCache(int surahNumber, SurahList surahList) {
    if (_memoryCacheSurah.length >= _maxMemoryCacheSize) {
      // Remove oldest entry (simple FIFO for now)
      final firstKey = _memoryCacheSurah.keys.first;
      _memoryCacheSurah.remove(firstKey);
    }
    _memoryCacheSurah[surahNumber] = surahList;
  }

  /// Attach translations to surah
  void _attachTranslations(SurahList surahList, Map<int, String> translations) {
    if (surahList.surahs == null || surahList.surahs!.isEmpty) return;

    final surah = surahList.surahs!.first;
    if (surah.ayahs == null) return;

    for (final ayah in surah.ayahs!) {
      if (ayah.number != null && translations.containsKey(ayah.number)) {
        // Store translation in ayah (you may need to add a translation field to Ayah model)
        // ayah.translation = translations[ayah.number];
      }
    }
  }

  /// Check if cache is still valid
  bool _isCacheValid(DateTime cachedAt) {
    final age = DateTime.now().difference(cachedAt);
    return age < _cacheExpiry;
  }

  /// Calculate global ayah index
  int _calculateGlobalAyahIndex(int surahNumber, int ayahNumber) {
    // Ayah counts for each surah
    const ayahCounts = [
      7, 286, 200, 176, 120, 165, 206, 75, 129, 109, 123, 111, 43, 52, 99,
      128, 111, 110, 98, 135, 112, 78, 118, 64, 77, 227, 93, 88, 69, 60,
      34, 30, 73, 54, 45, 83, 182, 88, 75, 85, 54, 53, 89, 59, 37, 35,
      38, 29, 18, 45, 60, 49, 62, 55, 78, 96, 29, 22, 24, 13, 14, 11,
      11, 18, 12, 12, 30, 52, 52, 44, 28, 28, 20, 56, 40, 31, 50, 40,
      46, 42, 29, 19, 36, 25, 22, 17, 19, 26, 30, 20, 15, 21, 11, 8,
      8, 19, 5, 8, 8, 11, 11, 8, 3, 9, 5, 4, 7, 3, 6, 3, 5, 4, 5, 6
    ];

    int globalIndex = ayahNumber;
    for (int i = 0; i < surahNumber - 1 && i < ayahCounts.length; i++) {
      globalIndex += ayahCounts[i];
    }
    return globalIndex;
  }

  /// Clear all caches
  Future<void> clearCaches() async {
    _memoryCacheSurah.clear();
    _memoryCacheTranslations.clear();
    _memoryCacheFullQuran = null;
    await _db.clearCachedSurahs();
    debugPrint('📦 QuranRepository: All caches cleared');
  }

  /// Get cache statistics
  Future<Map<String, dynamic>> getCacheStats() async {
    final dbStats = await _db.getStorageStats();
    return {
      ...dbStats,
      'memoryCachedSurahs': _memoryCacheSurah.length,
      'memoryCachedTranslations': _memoryCacheTranslations.length,
      'isOnline': _isOnline,
      'lastNetworkCheck': _lastNetworkCheck?.toIso8601String(),
    };
  }
}
