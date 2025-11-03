import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:quran_hadith/database/database_service.dart';
import 'package:quran_hadith/models/reciter_model.dart';
import 'package:quran_hadith/utils/shared_p.dart';
import 'package:quran_hadith/utils/sp_util.dart';

class ReciterService {
  ReciterService._();

  static final ReciterService instance = ReciterService._();

  final Dio _client = Dio(
    BaseOptions(
      baseUrl: 'https://api.qurancdn.com/api/qdc/audio',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );

  static const Duration _cacheValidity = Duration(days: 7);

  List<Reciter>? _inMemory;
  DateTime? _lastFetched;

  /// Notifies listeners when the current reciter changes across the app.
  /// Defaults to 'ar.alafasy'.
  final ValueNotifier<String> currentReciterId =
      ValueNotifier<String>('ar.alafasy');

  /// Initialize the current reciter from storage, preferring the new
  /// audio settings key and falling back to legacy SpUtil.
  /// Safe to call multiple times.
  Future<void> initializeCurrentReciter() async {
    try {
      await appSP.init();
    } catch (e) {
      debugPrint(
          '⚠️ ReciterService: Failed to initialize SharedPreferences: $e');
    }
    final fromSettings =
        appSP.getString('selectedReciter', defaultValue: '').trim();
    final fromLegacy = SpUtil.getReciter();
    var resolved = (fromSettings.isNotEmpty ? fromSettings : fromLegacy).trim();

    // Validate reciter ID format - if it's just a number, it's invalid
    if (resolved.isNotEmpty && !_isValidReciterId(resolved)) {
      debugPrint(
          '⚠️ ReciterService: Invalid reciter ID format "$resolved", resetting to default');
      resolved = 'ar.alafasy'; // Reset to default
      // Clear the invalid stored value to prevent re-loading bad data
      try {
        await appSP.remove('selectedReciter');
        await SpUtil.setReciter(resolved);
      } catch (e) {
        debugPrint(
            '⚠️ ReciterService: Failed to clear invalid reciter from storage: $e');
      }
    }

    if (resolved.isNotEmpty && resolved != currentReciterId.value) {
      currentReciterId.value = resolved;
    }
  }

  /// Validate reciter ID format - should be in pattern like "ar.alafasy"
  bool _isValidReciterId(String id) {
    final validPattern =
        RegExp(r'^[a-z]{2}\.[a-z0-9._-]+$', caseSensitive: false);
    return validPattern.hasMatch(id);
  }

  /// Check if a reciter ID exists in the available reciters list
  bool isReciterAvailable(String id, {List<Reciter>? within}) {
    final searchSpace = within ?? _inMemory ?? database.getCachedReciters();
    try {
      return searchSpace.any((reciter) => reciter.id == id);
    } catch (e) {
      debugPrint(
          '⚠️ ReciterService: Error checking reciter availability for $id: $e');
      return false;
    }
  }

  /// Update the current reciter and notify listeners. Persistence should be
  /// handled by the caller (UI) to avoid coupling storage here.
  /// Returns true if the reciter was successfully set, false if validation failed.
  bool setCurrentReciterId(String id) {
    if (id.isEmpty) return false;

    // Validate reciter ID format
    if (!_isValidReciterId(id)) {
      debugPrint(
          '⚠️ ReciterService: Invalid reciter ID format "$id", ignoring');
      return false;
    }

    // Check if reciter exists in available reciters (using current cache)
    if (!isReciterAvailable(id)) {
      debugPrint(
          '⚠️ ReciterService: Reciter "$id" not found in available reciters list');
      // Don't reject - might be loaded later, just warn
    }

    if (id != currentReciterId.value) {
      currentReciterId.value = id;
      debugPrint('✅ ReciterService: Reciter updated to $id');
    }
    return true;
  }

  Future<List<Reciter>> getReciters({bool forceRefresh = false}) async {
    // Layer 1: In-memory cache (fastest)
    if (!forceRefresh && _inMemory != null) {
      debugPrint(
          '✅ ReciterService: Returning ${_inMemory!.length} reciters from memory cache');
      return _inMemory!;
    }

    // Layer 2: Disk cache from Hive
    final cached = database.getCachedReciters();
    final cachedAt = database.getRecitersCachedAt();

    if (!forceRefresh && cached.isNotEmpty) {
      final isFresh = cachedAt != null &&
          DateTime.now().difference(cachedAt) < _cacheValidity;
      if (isFresh) {
        debugPrint(
            '✅ ReciterService: Returning ${cached.length} reciters from disk cache (age: ${DateTime.now().difference(cachedAt).inHours}h)');
        _inMemory = cached;
        _lastFetched = cachedAt;
        return cached;
      } else if (cached.isNotEmpty && cachedAt != null) {
        debugPrint(
            '⚠️ ReciterService: Disk cache exists but stale (age: ${DateTime.now().difference(cachedAt).inDays}d), will try API refresh');
      }
    }

    // Layer 3: Fetch from API
    try {
      debugPrint('🔄 ReciterService: Fetching reciters from API...');
      final response = await _client.get<Map<String, dynamic>>(
        '/reciters',
        queryParameters: {
          'per_page': 120,
        },
      );

      final payload = response.data;
      List<dynamic> rawList = const [];
      if (payload == null) {
        rawList = const [];
      } else if (payload['reciters'] is List) {
        rawList = payload['reciters'] as List;
      } else if (payload['data'] is List) {
        rawList = payload['data'] as List;
      }

      final reciters = <Reciter>[];
      for (final entry in rawList) {
        if (entry is Map<String, dynamic>) {
          reciters.add(Reciter.fromJson(entry));
        } else if (entry is Map) {
          reciters.add(Reciter.fromJson(entry.cast<String, dynamic>()));
        }
      }

      if (reciters.isNotEmpty) {
        _inMemory = reciters;
        _lastFetched = DateTime.now();
        await database.cacheReciters(reciters);
        debugPrint(
            '✅ ReciterService: Fetched ${reciters.length} reciters from API and cached');
        return reciters;
      }
    } catch (e) {
      debugPrint('⚠️ ReciterService: Failed to fetch reciters from API: $e');
    }

    // Layer 4: Fallback to stale cache if available
    if (cached.isNotEmpty) {
      debugPrint(
          '⚠️ ReciterService: Using stale disk cache with ${cached.length} reciters');
      _inMemory = cached;
      _lastFetched = cachedAt;
      return cached;
    }

    // Layer 5: Last resort - hardcoded fallback
    debugPrint(
        '⚠️ ReciterService: Using hardcoded fallback with ${Reciter.fallback.length} reciters');
    _inMemory = Reciter.fallback;
    return Reciter.fallback;
  }

  Reciter resolveById(String id, {List<Reciter>? within}) {
    final searchSpace = within ?? _inMemory ?? database.getCachedReciters();
    try {
      return searchSpace.firstWhere((reciter) => reciter.id == id);
    } catch (e) {
      debugPrint(
          '⚠️ ReciterService: Reciter $id not found in search space: $e');
      return Reciter.fallback.firstWhere(
        (reciter) => reciter.id == id,
        orElse: () => Reciter.fallback.first,
      );
    }
  }

  Future<List<Reciter>> refresh() => getReciters(forceRefresh: true);

  DateTime? get lastFetched => _lastFetched;
}
