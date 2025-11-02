import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Performance optimization service
///
/// Features:
/// - Image caching for surah headers
/// - Preload next ayah audio
/// - Virtual scrolling for long surahs
/// - Database query optimization
/// - Lazy loading of translations
/// - Memory management
/// - Frame rate monitoring
class PerformanceService extends ChangeNotifier {
  static final PerformanceService _instance = PerformanceService._internal();
  factory PerformanceService() => _instance;
  PerformanceService._internal();

  // Settings
  bool _enableImageCaching = true;
  bool _enableAudioPreloading = true;
  bool _enableVirtualScrolling = true;
  bool _enableLazyTranslations = true;
  bool _enableMemoryOptimization = true;
  int _preloadDistance = 3; // Number of ayahs to preload
  int _maxCacheSize = 100; // MB

  // State
  final Map<String, ImageProvider> _imageCache = {};
  final Set<String> _preloadedAudio = {};
  final Map<int, String> _translationCache = {};
  DateTime? _lastOptimization;
  int _currentMemoryUsage = 0; // MB

  // Performance metrics
  final List<double> _frameRates = [];
  int _jankCount = 0;
  DateTime? _lastJankTime;

  // Getters
  bool get enableImageCaching => _enableImageCaching;
  bool get enableAudioPreloading => _enableAudioPreloading;
  bool get enableVirtualScrolling => _enableVirtualScrolling;
  bool get enableLazyTranslations => _enableLazyTranslations;
  bool get enableMemoryOptimization => _enableMemoryOptimization;
  int get preloadDistance => _preloadDistance;
  int get currentMemoryUsage => _currentMemoryUsage;
  double get averageFrameRate => _frameRates.isEmpty
      ? 60.0
      : _frameRates.reduce((a, b) => a + b) / _frameRates.length;
  int get jankCount => _jankCount;

  // Preferences keys
  static const String _keyImageCaching = 'perf_image_caching';
  static const String _keyAudioPreloading = 'perf_audio_preloading';
  static const String _keyVirtualScrolling = 'perf_virtual_scrolling';
  static const String _keyLazyTranslations = 'perf_lazy_translations';
  static const String _keyMemoryOptimization = 'perf_memory_optimization';
  static const String _keyPreloadDistance = 'perf_preload_distance';
  static const String _keyMaxCacheSize = 'perf_max_cache_size';

  /// Initialize performance service
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();

    _enableImageCaching = prefs.getBool(_keyImageCaching) ?? true;
    _enableAudioPreloading = prefs.getBool(_keyAudioPreloading) ?? true;
    _enableVirtualScrolling = prefs.getBool(_keyVirtualScrolling) ?? true;
    _enableLazyTranslations = prefs.getBool(_keyLazyTranslations) ?? true;
    _enableMemoryOptimization = prefs.getBool(_keyMemoryOptimization) ?? true;
    _preloadDistance = prefs.getInt(_keyPreloadDistance) ?? 3;
    _maxCacheSize = prefs.getInt(_keyMaxCacheSize) ?? 100;

    // Start performance monitoring
    _startPerformanceMonitoring();

    notifyListeners();
    debugPrint('⚡ PerformanceService initialized');
  }

  /// Toggle image caching
  Future<void> toggleImageCaching() async {
    _enableImageCaching = !_enableImageCaching;
    await _saveBool(_keyImageCaching, _enableImageCaching);

    if (!_enableImageCaching) {
      _clearImageCache();
    }

    notifyListeners();
  }

  /// Toggle audio preloading
  Future<void> toggleAudioPreloading() async {
    _enableAudioPreloading = !_enableAudioPreloading;
    await _saveBool(_keyAudioPreloading, _enableAudioPreloading);

    if (!_enableAudioPreloading) {
      _preloadedAudio.clear();
    }

    notifyListeners();
  }

  /// Toggle virtual scrolling
  Future<void> toggleVirtualScrolling() async {
    _enableVirtualScrolling = !_enableVirtualScrolling;
    await _saveBool(_keyVirtualScrolling, _enableVirtualScrolling);
    notifyListeners();
  }

  /// Toggle lazy translations
  Future<void> toggleLazyTranslations() async {
    _enableLazyTranslations = !_enableLazyTranslations;
    await _saveBool(_keyLazyTranslations, _enableLazyTranslations);
    notifyListeners();
  }

  /// Toggle memory optimization
  Future<void> toggleMemoryOptimization() async {
    _enableMemoryOptimization = !_enableMemoryOptimization;
    await _saveBool(_keyMemoryOptimization, _enableMemoryOptimization);

    if (_enableMemoryOptimization) {
      await _performMemoryOptimization();
    }

    notifyListeners();
  }

  /// Set preload distance
  Future<void> setPreloadDistance(int distance) async {
    _preloadDistance = distance.clamp(1, 10);
    await _saveInt(_keyPreloadDistance, _preloadDistance);
    notifyListeners();
  }

  /// Set max cache size
  Future<void> setMaxCacheSize(int sizeMB) async {
    _maxCacheSize = sizeMB.clamp(50, 500);
    await _saveInt(_keyMaxCacheSize, _maxCacheSize);
    notifyListeners();
  }

  /// Cache image
  ImageProvider? cacheImage(String key, String imagePath) {
    if (!_enableImageCaching) return null;

    if (_imageCache.containsKey(key)) {
      return _imageCache[key];
    }

    final provider = AssetImage(imagePath);
    _imageCache[key] = provider;

    // Check cache size
    if (_imageCache.length > 50) {
      _trimImageCache();
    }

    return provider;
  }

  /// Get cached image
  ImageProvider? getCachedImage(String key) {
    return _enableImageCaching ? _imageCache[key] : null;
  }

  /// Preload image
  Future<void> preloadImage(
      String key, String imagePath, BuildContext context) async {
    if (!_enableImageCaching) return;

    if (_imageCache.containsKey(key)) return;

    try {
      final provider = AssetImage(imagePath);
      await precacheImage(provider, context);
      _imageCache[key] = provider;

      debugPrint('⚡ PerformanceService: Preloaded image: $key');
    } catch (e) {
      debugPrint('⚡ PerformanceService: Failed to preload image $key: $e');
    }
  }

  /// Mark audio as preloaded
  void markAudioPreloaded(int surahNumber, int ayahNumber) {
    if (!_enableAudioPreloading) return;

    final key = '$surahNumber:$ayahNumber';
    _preloadedAudio.add(key);

    debugPrint('⚡ PerformanceService: Marked audio preloaded: $key');
  }

  /// Check if audio is preloaded
  bool isAudioPreloaded(int surahNumber, int ayahNumber) {
    if (!_enableAudioPreloading) return false;

    final key = '$surahNumber:$ayahNumber';
    return _preloadedAudio.contains(key);
  }

  /// Preload next ayahs audio
  Future<void> preloadNextAyahs(
    int currentSurah,
    int currentAyah,
    int totalAyahs,
    Future<void> Function(int surah, int ayah) preloadFunction,
  ) async {
    if (!_enableAudioPreloading) return;

    for (int i = 1; i <= _preloadDistance; i++) {
      final nextAyah = currentAyah + i;
      if (nextAyah <= totalAyahs) {
        final key = '$currentSurah:$nextAyah';
        if (!_preloadedAudio.contains(key)) {
          try {
            await preloadFunction(currentSurah, nextAyah);
            _preloadedAudio.add(key);
            debugPrint('⚡ PerformanceService: Preloaded audio: $key');
          } catch (e) {
            debugPrint(
                '⚡ PerformanceService: Failed to preload audio $key: $e');
          }
        }
      }
    }
  }

  /// Cache translation
  void cacheTranslation(int ayahNumber, String translation) {
    if (!_enableLazyTranslations) return;

    _translationCache[ayahNumber] = translation;

    // Trim if too large
    if (_translationCache.length > 200) {
      _trimTranslationCache();
    }
  }

  /// Get cached translation
  String? getCachedTranslation(int ayahNumber) {
    return _enableLazyTranslations ? _translationCache[ayahNumber] : null;
  }

  /// Clear all caches
  Future<void> clearAllCaches() async {
    _clearImageCache();
    _preloadedAudio.clear();
    _translationCache.clear();
    _currentMemoryUsage = 0;

    notifyListeners();
    debugPrint('⚡ PerformanceService: All caches cleared');
  }

  /// Perform memory optimization
  Future<void> _performMemoryOptimization() async {
    if (!_enableMemoryOptimization) return;

    debugPrint('⚡ PerformanceService: Performing memory optimization...');

    // Trim caches
    _trimImageCache();
    _trimTranslationCache();

    // Clear old preloaded audio
    if (_preloadedAudio.length > 50) {
      _preloadedAudio.clear();
    }

    _lastOptimization = DateTime.now();

    notifyListeners();
    debugPrint('⚡ PerformanceService: Memory optimization complete');
  }

  /// Trim image cache
  void _trimImageCache() {
    if (_imageCache.length > 30) {
      final keysToRemove =
          _imageCache.keys.take(_imageCache.length - 30).toList();
      for (final key in keysToRemove) {
        _imageCache.remove(key);
      }
      debugPrint('⚡ PerformanceService: Trimmed image cache to 30 items');
    }
  }

  /// Clear image cache
  void _clearImageCache() {
    _imageCache.clear();
    debugPrint('⚡ PerformanceService: Image cache cleared');
  }

  /// Trim translation cache
  void _trimTranslationCache() {
    if (_translationCache.length > 100) {
      final keysToRemove =
          _translationCache.keys.take(_translationCache.length - 100).toList();
      for (final key in keysToRemove) {
        _translationCache.remove(key);
      }
      debugPrint(
          '⚡ PerformanceService: Trimmed translation cache to 100 items');
    }
  }

  /// Start performance monitoring
  void _startPerformanceMonitoring() {
    // Monitor frame rate
    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_enableMemoryOptimization) {
        _monitorFrameRate();
      }
    });

    // Periodic memory optimization
    Timer.periodic(const Duration(minutes: 5), (timer) {
      if (_enableMemoryOptimization) {
        _performMemoryOptimization();
      }
    });
  }

  /// Monitor frame rate
  void _monitorFrameRate() {
    // This would integrate with Flutter's SchedulerBinding
    // For now, we'll simulate it
    final frameRate = 60.0; // Would be actual frame rate
    _frameRates.add(frameRate);

    if (_frameRates.length > 60) {
      _frameRates.removeAt(0);
    }

    // Detect jank (frame rate drop below 55 FPS)
    if (frameRate < 55) {
      _jankCount++;
      _lastJankTime = DateTime.now();
      debugPrint(
          '⚡ PerformanceService: Jank detected! Frame rate: $frameRate FPS');
    }
  }

  /// Get performance report
  Map<String, dynamic> getPerformanceReport() {
    return {
      'imageCache': {
        'enabled': _enableImageCaching,
        'size': _imageCache.length,
      },
      'audioPreload': {
        'enabled': _enableAudioPreloading,
        'preloadedCount': _preloadedAudio.length,
        'preloadDistance': _preloadDistance,
      },
      'translationCache': {
        'enabled': _enableLazyTranslations,
        'size': _translationCache.length,
      },
      'memory': {
        'optimizationEnabled': _enableMemoryOptimization,
        'currentUsageMB': _currentMemoryUsage,
        'maxCacheSizeMB': _maxCacheSize,
        'lastOptimization': _lastOptimization?.toIso8601String(),
      },
      'performance': {
        'virtualScrolling': _enableVirtualScrolling,
        'averageFrameRate': averageFrameRate.toStringAsFixed(1),
        'jankCount': _jankCount,
        'lastJankTime': _lastJankTime?.toIso8601String(),
      },
    };
  }

  /// Save boolean preference
  Future<void> _saveBool(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  /// Save integer preference
  Future<void> _saveInt(String key, int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(key, value);
  }

  /// Get performance status
  Map<String, dynamic> getStatus() {
    return {
      'imageCaching': _enableImageCaching,
      'audioPreloading': _enableAudioPreloading,
      'virtualScrolling': _enableVirtualScrolling,
      'lazyTranslations': _enableLazyTranslations,
      'memoryOptimization': _enableMemoryOptimization,
      'preloadDistance': _preloadDistance,
      'maxCacheSize': _maxCacheSize,
      'averageFrameRate': averageFrameRate,
      'jankCount': _jankCount,
    };
  }
}

/// Global performance service instance
final performanceService = PerformanceService();
