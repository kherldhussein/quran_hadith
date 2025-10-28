import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:quran_hadith/models/daily_ayah.dart';
import 'package:quran_hadith/utils/sp_util.dart';
import 'package:quran_hadith/utils/shared_p.dart';
import 'package:quran_hadith/services/reciter_service.dart';

/// Service responsible for retrieving and caching the daily ayah.
class DailyAyahService {
  DailyAyahService._();

  static final DailyAyahService instance = DailyAyahService._();

  static const String _translationEdition = 'en.sahih';

  Future<String> _buildEndpoint() async {
    try {
      await appSP.init();
    } catch (_) {}
    final fromSettings =
        appSP.getString('selectedReciter', defaultValue: '').trim();
    final legacy = SpUtil.getReciter().trim();
    final inMemory = ReciterService.instance.currentReciterId.value.trim();
    final reciter = fromSettings.isNotEmpty
        ? fromSettings
        : (legacy.isNotEmpty
            ? legacy
            : (inMemory.isNotEmpty ? inMemory : 'ar.alafasy'));
    return 'https://api.alquran.cloud/v1/ayah/random/$reciter,$_translationEdition';
  }

  /// Fetch the ayah of the day. Cached locally to avoid multiple network calls per day.
  Future<DailyAyah?> getDailyAyah({bool forceRefresh = false}) async {
    final today = DateTime.now();
    final cacheDate = SpUtil.getDailyAyahDate();

    if (!forceRefresh && cacheDate == _formatDate(today)) {
      final cached = SpUtil.getCachedDailyAyah();
      if (cached != null) {
        return cached;
      }
    }

    try {
      final endpoint = await _buildEndpoint();
      final response = await http
          .get(Uri.parse(endpoint))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body) as Map<String, dynamic>;
        final data = decoded['data'] as Map<String, dynamic>?;
        if (data == null) return null;

        final surah = data['surah'] as Map<String, dynamic>?;
        final edition = data['edition'] as Map<String, dynamic>?;

        final ayah = DailyAyah(
          surahNumber: (surah?['number'] as num?)?.toInt() ?? 0,
          ayahNumber: data['numberInSurah'] as int? ?? 0,
          surahName: surah?['englishName'] as String? ??
              surah?['name'] as String? ??
              'Surah',
          arabicText: data['text'] as String? ?? '',
          translation: data['translations'] is List &&
                  (data['translations'] as List).isNotEmpty
              ? ((data['translations'] as List).first
                      as Map<String, dynamic>)['text'] as String? ??
                  ''
              : data['edition'] is Map<String, dynamic>
                  ? (data['edition']['type'] == 'translation'
                      ? data['text'] as String? ?? ''
                      : '')
                  : '',
          edition: edition?['identifier'] as String? ?? 'en.sahih',
        );

        await SpUtil.cacheDailyAyah(cacheDate: _formatDate(today), ayah: ayah);
        return ayah;
      }
    } catch (e) {
      debugPrint('DailyAyahService: Failed to fetch daily ayah: $e');
    }

    return SpUtil.getCachedDailyAyah();
  }

  Future<DailyAyah?> refreshDailyAyah() async {
    return getDailyAyah(forceRefresh: true);
  }

  String _formatDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
