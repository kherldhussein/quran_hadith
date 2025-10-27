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
    } catch (_) {}
    final fromSettings =
        appSP.getString('selectedReciter', defaultValue: '').trim();
    final fromLegacy = SpUtil.getReciter();
    final resolved =
        (fromSettings.isNotEmpty ? fromSettings : fromLegacy).trim();
    if (resolved.isNotEmpty && resolved != currentReciterId.value) {
      currentReciterId.value = resolved;
    }
  }

  /// Update the current reciter and notify listeners. Persistence should be
  /// handled by the caller (UI) to avoid coupling storage here.
  void setCurrentReciterId(String id) {
    if (id.isEmpty) return;
    if (id != currentReciterId.value) {
      currentReciterId.value = id;
    }
  }

  Future<List<Reciter>> getReciters({bool forceRefresh = false}) async {
    if (!forceRefresh && _inMemory != null) {
      return _inMemory!;
    }

    final cached = database.getCachedReciters();
    final cachedAt = database.getRecitersCachedAt();

    if (!forceRefresh && cached.isNotEmpty) {
      final isFresh = cachedAt != null &&
          DateTime.now().difference(cachedAt) < _cacheValidity;
      if (isFresh) {
        _inMemory = cached;
        _lastFetched = cachedAt;
        return cached;
      }
    }

    try {
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
        return reciters;
      }
    } catch (e) {
      debugPrint('ReciterService: Failed to fetch reciters: $e');
    }

    if (cached.isNotEmpty) {
      _inMemory = cached;
      _lastFetched = cachedAt;
      return cached;
    }

    _inMemory = Reciter.fallback;
    return Reciter.fallback;
  }

  Reciter resolveById(String id, {List<Reciter>? within}) {
    final searchSpace = within ?? _inMemory ?? database.getCachedReciters();
    try {
      return searchSpace.firstWhere((reciter) => reciter.id == id);
    } catch (_) {
      return Reciter.fallback.firstWhere(
        (reciter) => reciter.id == id,
        orElse: () => Reciter.fallback.first,
      );
    }
  }

  Future<List<Reciter>> refresh() => getReciters(forceRefresh: true);

  DateTime? get lastFetched => _lastFetched;
}
