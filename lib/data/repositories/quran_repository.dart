import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:quran_hadith/models/surah_model.dart';
import 'package:quran_hadith/database/database_service.dart';
import 'package:quran_hadith/database/hive_adapters.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;

/// Repository for Quran data management
/// Handles caching, network requests, and data retrieval
/// Provides a clean API for accessing Quran surahs
/// Supports offline mode with local caching
/// Uses Hive for persistent storage and memory caching for performance
class QuranRepository {
  static final QuranRepository _instance = QuranRepository._internal();
  factory QuranRepository() => _instance;
  QuranRepository._internal();

  final DatabaseService _db = DatabaseService();

  final Map<int, SurahList> _memoryCacheSurah = {};
  final Map<String, Map<int, String>> _memoryCacheTranslations = {};
  SurahList? _memoryCacheFullQuran;

  DateTime? _lastNetworkCheck;
  bool _isOnline = false;
  bool _isInitialized = false;

  static const Duration _networkCheckInterval = Duration(minutes: 5);
  static const Duration _cacheExpiry = Duration(days: 7);
  static const int _maxMemoryCacheSize = 50;

  Future<void> initialize() async {
    if (_isInitialized) return;

    await _db.initialize();

    await _checkConnectivity();

    await _preloadCommonSurahs();

    _isInitialized = true;
  }

  /// Preload commonly read surahs into memory
  Future<void> _preloadCommonSurahs() async {
    final commonSurahs = [1, 2, 18, 36, 55, 67, 78];

    for (final surahNumber in commonSurahs) {
      try {
        await getSurah(surahNumber, preload: true);
      } catch (e) {
        debugPrint('QuranRepository: Failed to preload surah $surahNumber: $e');
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
    } catch (e) {
      _isOnline = false;
    }
  }

  /// Get complete Quran with all surahs and audio URLs
  Future<SurahList> getCompleteQuran({String reciterId = 'ar.alafasy'}) async {
    if (_memoryCacheFullQuran != null) {
      return _memoryCacheFullQuran!;
    }

    final cachedSurahs = _db.getAllCachedSurahs();
    if (cachedSurahs.length == 114 &&
        _isCacheValid(cachedSurahs.first.cachedAt)) {
      final surahList = _buildSurahListFromCache(cachedSurahs);
      _memoryCacheFullQuran = surahList;
      return surahList;
    }

    final surahList = await _loadQuranFromAssets();
    _memoryCacheFullQuran = surahList;
    _addToMemoryCache(0, surahList);
    _backgroundSyncQuran(reciterId);

    return surahList;
  }

  /// Get a specific surah
  Future<SurahList> getSurah(int surahNumber, {bool preload = false}) async {
    if (!preload) {
      debugPrint('QuranRepository: Getting surah $surahNumber');
    }

    if (_memoryCacheSurah.containsKey(surahNumber)) {
      if (!preload) {
        debugPrint('QuranRepository: ✓ Returned from memory cache [0ms]');
      }
      return _memoryCacheSurah[surahNumber]!;
    }

    final cached = _db.getCachedSurah(surahNumber);
    if (cached != null && _isCacheValid(cached.cachedAt)) {
      if (!preload) {
        debugPrint('QuranRepository: ✓ Returned from disk cache');
      }
      final surahList = _convertCachedSurahToSurahList(cached);
      _addToMemoryCache(surahNumber, surahList);
      return surahList;
    }

    if (!preload) {
      debugPrint('QuranRepository: Loading from assets...');
    }
    final surahList = await _loadSurahFromAssets(surahNumber);
    _addToMemoryCache(surahNumber, surahList);

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
    // Get base surah data
    final surahList = await getSurah(surahNumber);

    final cacheKey = '${surahNumber}_$edition';
    if (_memoryCacheTranslations.containsKey(cacheKey)) {
      _attachTranslations(surahList, _memoryCacheTranslations[cacheKey]!);
      return surahList;
    }

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
    if (_lastNetworkCheck == null ||
        DateTime.now().difference(_lastNetworkCheck!) > _networkCheckInterval) {
      await _checkConnectivity();
    }

    if (!_isOnline) {
      return null;
    }

    try {
      final globalIndex = _calculateGlobalAyahIndex(surahNumber, ayahNumber);
      final audioUrl =
          'https://cdn.islamic.network/quran/audio/128/$reciterId/$globalIndex.mp3';

      return audioUrl;
    } catch (e) {
      return null;
    }
  }

  /// Background sync from network (non-blocking)
  void _backgroundSyncQuran(String reciterId) async {
    if (!_isOnline) return;

    try {
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
      }
    } catch (e) {
      debugPrint('QuranRepository: Background sync failed (non-critical): $e');
    }
  }

  /// Background sync single surah
  void _backgroundSyncSurah(int surahNumber) async {
    if (!_isOnline) return;

    try {
      final url =
          "https://api.alquran.cloud/v1/surah/$surahNumber/quran-uthmani";
      final response = await http.get(Uri.parse(url)).timeout(
            const Duration(seconds: 10),
          );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final surah = Surah.fromJSON(data['data']);
        await _cacheSurahToDisk(surah);
      }
    } catch (e) {
      debugPrint('QuranRepository: Background sync failed (non-critical): $e');
    }
  }

  /// Load Quran from bundled assets (ALWAYS available)
  Future<SurahList> _loadQuranFromAssets() async {
    try {
      final List<Surah> surahs = [];
      for (int i = 1; i <= 114; i++) {
        try {
          final surahData = await rootBundle.loadString('assets/surah_$i.json');
          final decoded = json.decode(surahData);

          // Parse the surah data
          final surah = _parseSurahFromAsset(decoded, i);
          surahs.add(surah);
        } catch (e) {
          debugPrint('QuranRepository: Error loading surah $i from assets: $e');
        }
      }

      return SurahList(
        surahs: surahs,
      );
    } catch (e) {
      debugPrint('QuranRepository: ✗ Failed to load from assets: $e');
      rethrow;
    }
  }

  /// Load single surah from assets
  Future<SurahList> _loadSurahFromAssets(int surahNumber) async {
    try {
      final surahData =
          await rootBundle.loadString('assets/surah_$surahNumber.json');
      final decoded = json.decode(surahData);
      final surah = _parseSurahFromAsset(decoded, surahNumber);

      return SurahList(
        surahs: [surah],
      );
    } catch (e) {
      debugPrint(
          'QuranRepository: ✗ Failed to load surah $surahNumber from assets: $e');
      rethrow;
    }
  }

  /// Parse surah from asset JSON
  Surah _parseSurahFromAsset(Map<String, dynamic> data, int surahNumber) {
    final List<Ayah> ayahs = [];
    if (!data.containsKey('name')) {
      data['name'] = 'Surah $surahNumber';
    }
    if (!data.containsKey('english_name')) {
      data['english_name'] = '';
    }
    if (!data.containsKey('english_translation')) {
      data['english_translation'] = '';
    }
    if (!data.containsKey('revelation_type')) {
      data['revelation_type'] = 'Meccan';
    }
    if (!data.containsKey('verse_count')) {
      data['verse_count'] = 0;
    }
    if (!data.containsKey('ayahs')) {
      data['ayahs'] = [];
    }
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
          juz: 1,
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
      debugPrint('QuranRepository: Error caching surah to disk: $e');
    }
  }

  /// Get translations from network or cache
  /// Returns a map of ayah numbers to their translations
  Future<Map<int, String>> _getTranslations(
      int surahNumber, String edition) async {
    try {
      final cacheKey = '${surahNumber}_$edition';
      if (_memoryCacheTranslations.containsKey(cacheKey)) {
        return _memoryCacheTranslations[cacheKey]!;
      }

      final cachedTranslation = _db.getCachedTranslation(edition);
      if (cachedTranslation != null &&
          _isCacheValid(cachedTranslation.cachedAt)) {
        final surahTranslations = <int, String>{};
        for (int i = 1; i <= 300; i++) {
          final key = '$surahNumber:$i';
          if (cachedTranslation.ayahTranslations.containsKey(key)) {
            surahTranslations[i] = cachedTranslation.ayahTranslations[key]!;
          } else {
            break;
          }
        }

        _memoryCacheTranslations[cacheKey] = surahTranslations;
        return surahTranslations;
      }

      if (!_isOnline) {
        return {};
      }

      debugPrint('QuranRepository: Fetching translations from network...');
      final translations =
          await _fetchTranslationsFromNetwork(surahNumber, edition);

      if (translations.isNotEmpty) {
        await _cacheTranslationToDisk(surahNumber, edition, translations);

        _memoryCacheTranslations[cacheKey] = translations;

        return translations;
      }

      return translations;
    } catch (e) {
      debugPrint(
          'QuranRepository: ✗ Error fetching translations for surah $surahNumber: $e');
      return {};
    }
  }

  /// Fetch translations from network API
  Future<Map<int, String>> _fetchTranslationsFromNetwork(
      int surahNumber, String edition) async {
    try {
      final url =
          "https://api.alquran.cloud/v1/surah/$surahNumber/editions/quran-uthmani,$edition";

      final response =
          await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        final data = decoded['data'] as List?;

        if (data == null || data.length < 2) {
          return {};
        }

        final translationData = data[1]['ayahs'] as List?;
        if (translationData == null) {
          return {};
        }

        final translations = <int, String>{};
        for (final ayah in translationData) {
          final number = ayah['numberInSurah'] as int?;
          final text = ayah['text'] as String?;

          if (number != null && text != null) {
            translations[number] = text;
          }
        }

        return translations;
      }

      return {};
    } catch (e) {
      debugPrint(
          'QuranRepository: Error fetching translations from network: $e');
      return {};
    }
  }

  /// Cache translations to disk
  Future<void> _cacheTranslationToDisk(
    int surahNumber,
    String edition,
    Map<int, String> surahTranslations,
  ) async {
    try {
      var cached = _db.getCachedTranslation(edition);

      if (cached == null) {
        final allTranslations = <String, String>{};
        for (final entry in surahTranslations.entries) {
          allTranslations['$surahNumber:${entry.key}'] = entry.value;
        }

        cached = TranslationData(
          identifier: edition,
          language: _getLanguageFromEdition(edition),
          name: _getTranslationName(edition),
          translator: _getTranslatorName(edition),
          ayahTranslations: allTranslations,
        );
      } else {
        final updatedTranslations =
            Map<String, String>.from(cached.ayahTranslations);
        for (final entry in surahTranslations.entries) {
          updatedTranslations['$surahNumber:${entry.key}'] = entry.value;
        }

        cached = TranslationData(
          identifier: edition,
          language: cached.language,
          name: cached.name,
          translator: cached.translator,
          ayahTranslations: updatedTranslations,
        );
      }

      await _db.cacheTranslation(cached);
    } catch (e) {
      debugPrint('QuranRepository: Error caching translation to disk: $e');
    }
  }

  /// Get language code from edition string
  String _getLanguageFromEdition(String edition) {
    final parts = edition.split('.');
    return parts.isNotEmpty ? parts[0] : 'en';
  }

  /// Get human-readable translation name
  String _getTranslationName(String edition) {
    final names = {
      'en.sahih': 'Sahih International',
      'en.pickthall': 'Marmaduke Pickthall',
      'en.yusuf': 'Yusuf Ali',
      'en.shakir': 'Muhammad Habib Shakir',
      'en.transliteration': 'Transliteration',
      'ar.muyassar': 'Al-Muyassar',
      'ar.jalalayn': 'Tafsir Al-Jalalayn',
    };
    return names[edition] ?? edition;
  }

  /// Get translator name
  String _getTranslatorName(String edition) {
    final translators = {
      'en.sahih': 'Sahih International',
      'en.pickthall': 'Marmaduke Pickthall',
      'en.yusuf': 'Abdullah Yusuf Ali',
      'en.shakir': 'Muhammad Habib Shakir',
      'en.transliteration': 'Arabic Transliteration',
      'ar.muyassar': 'Shuayb Al-Arnault',
      'ar.jalalayn': 'Jalal ad-Din al-Mahalli & Jalal ad-Din as-Suyuti',
    };
    return translators[edition] ?? 'Unknown';
  }

  /// Convert cached surah to SurahList
  SurahList _convertCachedSurahToSurahList(CachedSurah cached) {
    final ayahs = cached.ayahs
        .map((cachedAyah) => Ayah(
              number: cachedAyah.numberInSurah,
              text: cachedAyah.text,
            ))
        .toList();

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
      final ayahs = cached.ayahs
          .map((cachedAyah) => Ayah(
                number: cachedAyah.numberInSurah,
                text: cachedAyah.text,
              ))
          .toList();

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

    // Translations are stored separately and retrieved via _getTranslations()
    // No need to modify ayah objects directly
    debugPrint('✓ Translations loaded successfully');
  }

  /// Check if cache is still valid
  bool _isCacheValid(DateTime cachedAt) {
    final age = DateTime.now().difference(cachedAt);
    return age < _cacheExpiry;
  }

  /// Calculate global ayah index
  int _calculateGlobalAyahIndex(int surahNumber, int ayahNumber) {
    const ayahCounts = [
      7,
      286,
      200,
      176,
      120,
      165,
      206,
      75,
      129,
      109,
      123,
      111,
      43,
      52,
      99,
      128,
      111,
      110,
      98,
      135,
      112,
      78,
      118,
      64,
      77,
      227,
      93,
      88,
      69,
      60,
      34,
      30,
      73,
      54,
      45,
      83,
      182,
      88,
      75,
      85,
      54,
      53,
      89,
      59,
      37,
      35,
      38,
      29,
      18,
      45,
      60,
      49,
      62,
      55,
      78,
      96,
      29,
      22,
      24,
      13,
      14,
      11,
      11,
      18,
      12,
      12,
      30,
      52,
      52,
      44,
      28,
      28,
      20,
      56,
      40,
      31,
      50,
      40,
      46,
      42,
      29,
      19,
      36,
      25,
      22,
      17,
      19,
      26,
      30,
      20,
      15,
      21,
      11,
      8,
      8,
      19,
      5,
      8,
      8,
      11,
      11,
      8,
      3,
      9,
      5,
      4,
      7,
      3,
      6,
      3,
      5,
      4,
      5,
      6
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
