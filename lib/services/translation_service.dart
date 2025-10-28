import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:quran_hadith/database/database_service.dart';
import 'package:quran_hadith/database/hive_adapters.dart';

/// Translation service for managing multiple Quran translations
class TranslationService extends ChangeNotifier {
  static final TranslationService _instance = TranslationService._internal();
  factory TranslationService() => _instance;
  TranslationService._internal();

  final Dio _dio = Dio();

  static const Map<String, TranslationInfo> availableTranslations = {
    'en.sahih': TranslationInfo(
      identifier: 'en.sahih',
      language: 'English',
      name: 'Sahih International',
      translator: 'Saheeh International',
    ),
    'en.pickthall': TranslationInfo(
      identifier: 'en.pickthall',
      language: 'English',
      name: 'Pickthall',
      translator: 'Mohammed Marmaduke William Pickthall',
    ),
    'en.yusufali': TranslationInfo(
      identifier: 'en.yusufali',
      language: 'English',
      name: 'Yusuf Ali',
      translator: 'Abdullah Yusuf Ali',
    ),
    'en.transliteration': TranslationInfo(
      identifier: 'en.transliteration',
      language: 'English',
      name: 'Transliteration',
      translator: 'English Transliteration',
    ),
    'ur.jalandhry': TranslationInfo(
      identifier: 'ur.jalandhry',
      language: 'Urdu',
      name: 'Fateh Muhammad Jalandhry',
      translator: 'Maulana Fateh Muhammad Jalandhry',
    ),
    'ur.qadri': TranslationInfo(
      identifier: 'ur.qadri',
      language: 'Urdu',
      name: 'Tahir ul Qadri',
      translator: 'Dr. Tahir-ul-Qadri',
    ),
    'tr.yuksel': TranslationInfo(
      identifier: 'tr.yuksel',
      language: 'Turkish',
      name: 'Edip Yuksel',
      translator: 'Edip Yuksel',
    ),
    'tr.diyanet': TranslationInfo(
      identifier: 'tr.diyanet',
      language: 'Turkish',
      name: 'Diyanet İşleri',
      translator: 'Diyanet İşleri',
    ),
    'fr.hamidullah': TranslationInfo(
      identifier: 'fr.hamidullah',
      language: 'French',
      name: 'Muhammad Hamidullah',
      translator: 'Muhammad Hamidullah',
    ),
    'id.indonesian': TranslationInfo(
      identifier: 'id.indonesian',
      language: 'Indonesian',
      name: 'Indonesian Ministry of Religious Affairs',
      translator: 'Indonesian Ministry of Religious Affairs',
    ),
    'bn.bengali': TranslationInfo(
      identifier: 'bn.bengali',
      language: 'Bengali',
      name: 'Muhiuddin Khan',
      translator: 'Muhiuddin Khan',
    ),
    'de.bubenheim': TranslationInfo(
      identifier: 'de.bubenheim',
      language: 'German',
      name: 'Bubenheim & Elyas',
      translator: 'A. S. F. Bubenheim and N. Elyas',
    ),
    'es.cortes': TranslationInfo(
      identifier: 'es.cortes',
      language: 'Spanish',
      name: 'Julio Cortes',
      translator: 'Julio Cortes',
    ),
  };

  List<String> _enabledTranslations = ['en.sahih'];
  bool _isLoading = false;
  String? _error;
  final Map<String, double> _downloadProgress = {};

  List<String> get enabledTranslations =>
      List.unmodifiable(_enabledTranslations);
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, double> get downloadProgress =>
      Map.unmodifiable(_downloadProgress);

  /// Initialize translation service
  Future<void> initialize() async {
    try {
      final prefs = database.getPreferences();
      _enabledTranslations = prefs.enabledTranslations;
      notifyListeners();
    } catch (e) {
      debugPrint('Error initializing translation service: $e');
    }
  }

  /// Fetch and cache a translation
  Future<bool> fetchTranslation(String identifier) async {
    if (!availableTranslations.containsKey(identifier)) {
      _error = 'Translation not found: $identifier';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    _downloadProgress[identifier] = 0.0;
    notifyListeners();

    try {
      final response = await _dio.get(
        'https://api.alquran.cloud/v1/quran/$identifier',
        onReceiveProgress: (received, total) {
          if (total != -1) {
            _downloadProgress[identifier] = received / total;
            notifyListeners();
          }
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        await _cacheTranslation(identifier, data);

        _downloadProgress.remove(identifier);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        throw Exception('Failed to fetch translation: ${response.statusCode}');
      }
    } catch (e) {
      _error = 'Error fetching translation: $e';
      _downloadProgress.remove(identifier);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Cache translation data
  Future<void> _cacheTranslation(String identifier, dynamic data) async {
    try {
      final translationInfo = availableTranslations[identifier]!;
      final ayahTranslations = <String, String>{};

      final surahs = data['data']['surahs'] as List;
      for (final surah in surahs) {
        final surahNumber = surah['number'];
        final ayahs = surah['ayahs'] as List;

        for (final ayah in ayahs) {
          final ayahNumber = ayah['numberInSurah'];
          final text = ayah['text'] as String;
          final key = '$surahNumber:$ayahNumber';
          ayahTranslations[key] = text;
        }
      }

      final translationData = TranslationData(
        identifier: identifier,
        language: translationInfo.language,
        name: translationInfo.name,
        translator: translationInfo.translator,
        ayahTranslations: ayahTranslations,
      );

      await database.cacheTranslation(translationData);
      debugPrint(
          'Translation cached: $identifier (${ayahTranslations.length} ayahs)');
    } catch (e) {
      debugPrint('Error caching translation: $e');
      rethrow;
    }
  }

  /// Get translation for specific ayah
  String? getAyahTranslation({
    required int surahNumber,
    required int ayahNumber,
    required String identifier,
  }) {
    try {
      final translation = database.getCachedTranslation(identifier);
      if (translation == null) return null;

      final key = '$surahNumber:$ayahNumber';
      return translation.ayahTranslations[key];
    } catch (e) {
      debugPrint('Error getting ayah translation: $e');
      return null;
    }
  }

  /// Get multiple translations for an ayah
  Map<String, String> getAyahTranslations({
    required int surahNumber,
    required int ayahNumber,
  }) {
    final translations = <String, String>{};

    for (final identifier in _enabledTranslations) {
      final translation = getAyahTranslation(
        surahNumber: surahNumber,
        ayahNumber: ayahNumber,
        identifier: identifier,
      );

      if (translation != null) {
        final info = availableTranslations[identifier];
        translations[info?.name ?? identifier] = translation;
      }
    }

    return translations;
  }

  /// Check if translation is cached
  bool isTranslationCached(String identifier) {
    return database.getCachedTranslation(identifier) != null;
  }

  /// Enable a translation
  Future<void> enableTranslation(String identifier) async {
    if (!_enabledTranslations.contains(identifier)) {
      _enabledTranslations.add(identifier);

      if (!isTranslationCached(identifier)) {
        await fetchTranslation(identifier);
      }

      await _saveEnabledTranslations();
      notifyListeners();
    }
  }

  /// Disable a translation
  Future<void> disableTranslation(String identifier) async {
    _enabledTranslations.remove(identifier);
    await _saveEnabledTranslations();
    notifyListeners();
  }

  /// Toggle translation
  Future<void> toggleTranslation(String identifier) async {
    if (_enabledTranslations.contains(identifier)) {
      await disableTranslation(identifier);
    } else {
      await enableTranslation(identifier);
    }
  }

  /// Save enabled translations to preferences
  Future<void> _saveEnabledTranslations() async {
    try {
      final prefs = database.getPreferences();
      prefs.enabledTranslations = _enabledTranslations;
      await database.savePreferences(prefs);
    } catch (e) {
      debugPrint('Error saving enabled translations: $e');
    }
  }

  /// Get cached translations
  List<String> getCachedTranslations() {
    return database
        .getAllCachedTranslations()
        .map((t) => t.identifier)
        .toList();
  }

  /// Delete a translation
  Future<void> deleteTranslation(String identifier) async {
    try {
      final translation = database.getCachedTranslation(identifier);
      if (translation != null) {
        await disableTranslation(identifier);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error deleting translation: $e');
    }
  }

  /// Get translation statistics
  Map<String, dynamic> getTranslationStats(String identifier) {
    final translation = database.getCachedTranslation(identifier);
    if (translation == null) {
      return {
        'cached': false,
        'ayahCount': 0,
        'size': 0,
      };
    }

    final size = translation.ayahTranslations.values.fold<int>(
      0,
      (sum, text) => sum + text.length,
    );

    return {
      'cached': true,
      'ayahCount': translation.ayahTranslations.length,
      'size': size,
      'sizeKB': (size / 1024).toStringAsFixed(2),
      'cachedAt': translation.cachedAt,
    };
  }

  /// Get available languages
  Set<String> getAvailableLanguages() {
    return availableTranslations.values.map((t) => t.language).toSet();
  }

  /// Get translations by language
  List<TranslationInfo> getTranslationsByLanguage(String language) {
    return availableTranslations.values
        .where((t) => t.language == language)
        .toList();
  }

  /// Download all enabled translations
  Future<void> downloadAllEnabledTranslations() async {
    for (final identifier in _enabledTranslations) {
      if (!isTranslationCached(identifier)) {
        await fetchTranslation(identifier);
      }
    }
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}

/// Translation information
class TranslationInfo {
  final String identifier;
  final String language;
  final String name;
  final String translator;

  const TranslationInfo({
    required this.identifier,
    required this.language,
    required this.name,
    required this.translator,
  });
}

/// Global translation service instance
final translationService = TranslationService();
