import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:quran_hadith/models/juzModel.dart';
import 'package:quran_hadith/models/surah_model.dart';
import 'package:http/http.dart' as http;
import 'package:quran_hadith/utils/shared_p.dart';
import 'package:quran_hadith/utils/sp_util.dart';
import 'package:quran_hadith/services/reciter_service.dart';

/// The Qur'an contains 6236 verses
class QuranAPI {
  late Response response;
  Dio dio = Dio();
  final String _cacheDirName = 'cache';
  static const List<int> _ayahCounts = [
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

  int _globalAyahIndex(int surahNumber, int numberInSurah) {
    if (surahNumber < 1 || surahNumber > 114) return numberInSurah;
    int offset = 0;
    for (int i = 0; i < surahNumber - 1; i++) {
      offset += _ayahCounts[i];
    }
    return offset + numberInSurah;
  }

  Future<File> _ensureCacheFile(String filename) async {
    final dir = await getTemporaryDirectorySafe();
    final cacheDir = Directory('${dir.path}/$_cacheDirName');
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }
    return File('${cacheDir.path}/$filename');
  }

  Future<Directory> getTemporaryDirectorySafe() async {
    final envTmp = Platform.environment['TMPDIR'] ??
        Platform.environment['TEMP'] ??
        '/tmp';
    final tempDir = Directory(envTmp);
    if (!await tempDir.exists()) {
      await tempDir.create(recursive: true);
    }
    return tempDir;
  }

  Future<SurahList> getSuratList() async {
    const String url = "https://api.alquran.cloud/v1/quran/quran-uthmani";
    final cacheFile = await _ensureCacheFile('surat_list.json');

    if (await cacheFile.exists()) {
      try {
        final cacheAge =
            DateTime.now().difference(await cacheFile.lastModified());

        if (cacheAge.inDays < 7) {
          debugPrint(
              'QuranAPI: Using cached surah list (age: ${cacheAge.inDays} days)');
          final cached = await cacheFile.readAsString();
          return SurahList.fromJSON(json.decode(cached));
        }
      } catch (e) {
        debugPrint('QuranAPI: Error reading cache: $e');
      }
    }

    try {
      debugPrint('QuranAPI: Fetching surah list from API...');
      final response =
          await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        await cacheFile.writeAsString(response.body);
        debugPrint('QuranAPI: Surah list fetched and cached successfully');
        return SurahList.fromJSON(json.decode(response.body));
      }
    } catch (e) {
      debugPrint('QuranAPI: Network fetch failed: $e');
    }

    if (await cacheFile.exists()) {
      debugPrint('QuranAPI: Using stale cache as fallback');
      final cached = await cacheFile.readAsString();
      return SurahList.fromJSON(json.decode(cached));
    }

    throw Exception("Failed to Get Data: No network and no cache available");
  }

  Future<SurahList> getSurahListAssets(int index) async {
    final response =
        await rootBundle.loadString('assets/surah/surah_$index.json');
    var res = json.decode(response);
    var data = res['$index'];
    return SurahList.fromJSON(data);
  }

  Future<List<SurahList>> getData() async {
    var response = await rootBundle.loadString('assets/surah/');
    Iterable data = json.decode(response);
    return data.map((model) => SurahList.fromJSON(model)).toList();
  }

  Future<JuzModel> getJuzz({required int index}) async {
    final String url = "https://api.alquran.cloud/v1/juz/$index/quran-uthmani";
    final response = await dio.get(url);
    if (response.statusCode == 200) {
      return JuzModel.fromJSON(json.decode(response.data));
    } else {
      throw Exception("Failed to Get Data");
    }
  }

  Future<SurahList> getSearch({required String keyWord}) async {
    final String url = "https://api.alquran.cloud/v1/search/$keyWord/all/en";
    final response = await dio.get(url);
    if (response.statusCode == 200) {
      return SurahList.fromJSON(json.decode(response.data));
    } else {
      print("Failed to load");
      throw Exception("Failed to Get Data");
    }
  }

  Future<SurahList> getSuratAudio() async {
    final selectedReciter = await _resolveReciterId(null);
    final cacheFile =
        await _ensureCacheFile('surat_audio_$selectedReciter.json');

    if (await cacheFile.exists()) {
      try {
        final cacheAge =
            DateTime.now().difference(await cacheFile.lastModified());

        if (cacheAge.inDays < 7) {
          debugPrint(
              'QuranAPI: Using cached surah audio data (age: ${cacheAge.inDays} days)');
          final cached = await cacheFile.readAsString();
          return SurahList.fromJSON(json.decode(cached));
        } else {
          debugPrint('QuranAPI: Cache expired, fetching fresh data...');
        }
      } catch (e) {
        debugPrint('QuranAPI: Error reading cache: $e');
      }
    }

    try {
      debugPrint('QuranAPI: Fetching surah audio data from API...');
      final response = await http
          .get(Uri.parse("https://api.alquran.cloud/v1/quran/$selectedReciter"))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        await cacheFile.writeAsString(response.body);
        debugPrint(
            'QuranAPI: Surah audio data fetched and cached successfully');
        return SurahList.fromJSON(json.decode(response.body));
      }
    } catch (e) {
      debugPrint('QuranAPI: Network fetch failed: $e');
    }

    if (await cacheFile.exists()) {
      debugPrint('QuranAPI: Using stale cache as fallback');
      final cached = await cacheFile.readAsString();
      return SurahList.fromJSON(json.decode(cached));
    }

    throw Exception("Failed to Get Data: No network and no cache available");
  }

  Future<Ayah> getAyaAudio({required int ayaNo}) async {
    String url = "https://cdn.alquran.cloud/media/audio/ayah/Hani Rifai/$ayaNo";
    final response = await dio.get(url);
    if (response.statusCode == 200) {
      return Ayah.fromJSON(json.decode(response.data));
    } else {
      throw Exception("Failed to Get Data");
    }
  }

  /// Get audio URL for the first ayah in a specific surah using the
  /// currently selected reciter. Optionally override the reciter.
  Future<String?> getSurahAudioUrl(int suratNo, {String? reciterId}) async {
    try {
      final selected = await _resolveReciterId(reciterId);
      final response = await dio
          .get("https://api.alquran.cloud/v1/surah/$suratNo/$selected");

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = response.data is String
            ? json.decode(response.data)
            : response.data;

        final data = responseData['data'];
        if (data != null) {
          final ayahs = data['ayahs'] as List<dynamic>?;
          if (ayahs != null && ayahs.isNotEmpty) {
            final firstAyah = ayahs.first as Map<String, dynamic>;
            final audioUrl = firstAyah['audio'] as String?;

            if (audioUrl != null && audioUrl.isNotEmpty) {
              return audioUrl;
            }
          }
        }

        debugPrint("No audio URL found in response for Surah $suratNo");
        return null;
      } else {
        debugPrint("HTTP ${response.statusCode} for Surah $suratNo audio");
        return null;
      }
    } catch (e, stackTrace) {
      debugPrint("Error fetching audio URL for Surah $suratNo: $e");
      debugPrint("Stack trace: $stackTrace");
      return null;
    }
  }

  /// Get audio URL for a specific ayah using the selected reciter. Optionally
  /// override the reciter.
  Future<String?> getAyahAudioUrl(int suratNo, int ayahNo,
      {String? reciterId}) async {
    try {
      String selected = await _resolveReciterId(reciterId);
      // Validate reciter format: "ar.alafasy", "ar.minshawi", etc.
      final validPattern =
          RegExp(r'^[a-z]{2}\.[a-z0-9._-]+$', caseSensitive: false);
      if (!validPattern.hasMatch(selected)) {
        debugPrint(
            '⚠️ QuranAPI: Reciter "$selected" has invalid format; falling back to ar.alafasy');
        selected = 'ar.alafasy';
      }
      final response = await dio
          .get("https://api.alquran.cloud/v1/ayah/$suratNo:$ayahNo/$selected");

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = response.data is String
            ? json.decode(response.data)
            : response.data;

        final data = responseData['data'];
        if (data != null) {
          final audioUrl = data['audio'] as String?;
          if (audioUrl != null && audioUrl.isNotEmpty) {
            debugPrint(
                '✅ QuranAPI: Got audio URL for $suratNo:$ayahNo with reciter "$selected"');
            return audioUrl;
          }
        }
      }
      final globalIndex = _globalAyahIndex(suratNo, ayahNo);
      final fallbackUrl =
          'https://cdn.islamic.network/quran/audio/128/$selected/$globalIndex.mp3';
      debugPrint(
          'QuranAPI: Falling back to CDN URL for $suratNo:$ayahNo -> $fallbackUrl');
      return fallbackUrl;
    } catch (e) {
      debugPrint("Error fetching ayah audio URL for $suratNo:$ayahNo: $e");
      try {
        String selected = await _resolveReciterId(reciterId);
        final validPattern =
            RegExp(r'^[a-z]{2}\.[a-z0-9]+', caseSensitive: false);
        if (!validPattern.hasMatch(selected)) {
          selected = 'ar.alafasy';
        }
        final globalIndex = _globalAyahIndex(suratNo, ayahNo);
        final fallbackUrl =
            'https://cdn.islamic.network/quran/audio/128/$selected/$globalIndex.mp3';
        debugPrint(
            'QuranAPI: Error occurred; returning fallback CDN URL -> $fallbackUrl');
        return fallbackUrl;
      } catch (_) {
        return null;
      }
    }
  }

  /// Get Surah with English translation (cached indefinitely)
  Future<Map<int, String>> getSurahTranslations(int surahNumber,
      {String edition = 'en.sahih'}) async {
    final cacheFile =
        await _ensureCacheFile('translation_${surahNumber}_$edition.json');

    if (await cacheFile.exists()) {
      try {
        debugPrint('QuranAPI: Using cached translation for Surah $surahNumber');
        final cached = await cacheFile.readAsString();
        return _parseTranslations(cached);
      } catch (e) {
        debugPrint("Error reading translation cache: $e");
      }
    }

    try {
      debugPrint(
          'QuranAPI: Fetching translation for Surah $surahNumber from API...');
      final response = await http
          .get(Uri.parse(
              "https://api.alquran.cloud/v1/surah/$surahNumber/editions/quran-uthmani,$edition"))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        await cacheFile.writeAsString(response.body);
        debugPrint('QuranAPI: Translation cached successfully');
        return _parseTranslations(response.body);
      }
    } catch (e) {
      debugPrint("Error fetching translations: $e");
    }

    return {};
  }

  Map<int, String> _parseTranslations(String responseBody) {
    final Map<int, String> translations = {};
    try {
      final decoded = json.decode(responseBody);
      final data = decoded['data'] as List;

      if (data.length >= 2) {
        final translationData = data[1]['ayahs'] as List;
        for (final ayah in translationData) {
          final number = ayah['numberInSurah'] as int;
          final text = ayah['text'] as String;
          translations[number] = text;
        }
      }
    } catch (e) {
      debugPrint("Error parsing translations: $e");
    }
    return translations;
  }

  /// Get single ayah translation
  Future<String?> getAyahTranslation(int surahNumber, int ayahNumber,
      {String edition = 'en.sahih'}) async {
    try {
      final response = await dio.get(
          "https://api.alquran.cloud/v1/ayah/$surahNumber:$ayahNumber/$edition");

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = response.data is String
            ? json.decode(response.data)
            : response.data;

        final data = responseData['data'];
        if (data != null) {
          return data['text'] as String?;
        }
      }
      return null;
    } catch (e) {
      debugPrint(
          "Error fetching ayah translation for $surahNumber:$ayahNumber: $e");
      return null;
    }
  }

  /// Fetch word-by-word timing data for recitation highlighting
  /// Note: al-quran.cloud API does not provide word-level timing data
  /// This method is kept for future integration if such data becomes available
  /// For now, return null to disable word highlighting via API
  Future<SurahList?> fetchWordTimings(int surahNumber,
      {String? reciterId}) async {
    try {
      debugPrint(
          'QuranAPI: Word-level timings not available from al-quran.cloud API');
      return null;
    } catch (e) {
      debugPrint('Error fetching word timings for surah $surahNumber: $e');
      return null;
    }
  }

  /// Resolve the active reciter id following this priority:
  /// 1) Provided [overrideId]
  /// 2) Audio settings (appSP 'selectedReciter')
  /// 3) Legacy SpUtil (RECITER)
  /// 4) In-memory ReciterService notifier
  /// 5) Default 'ar.alafasy'
  Future<String> _resolveReciterId(String? overrideId) async {
    if (overrideId != null && overrideId.trim().isNotEmpty) {
      debugPrint('🔊 QuranAPI: Using override reciter: $overrideId');
      return overrideId.trim();
    }
    try {
      await appSP.init();
    } catch (_) {}
    final fromSettings =
        appSP.getString('selectedReciter', defaultValue: '').trim();
    if (fromSettings.isNotEmpty) {
      debugPrint('🔊 QuranAPI: Using reciter from settings: $fromSettings');
      return fromSettings;
    }

    final legacy = SpUtil.getReciter().trim();
    if (legacy.isNotEmpty) {
      debugPrint('🔊 QuranAPI: Using legacy reciter: $legacy');
      return legacy;
    }

    final inMemory = ReciterService.instance.currentReciterId.value.trim();
    if (inMemory.isNotEmpty) {
      debugPrint('🔊 QuranAPI: Using in-memory reciter: $inMemory');
      return inMemory;
    }

    debugPrint('🔊 QuranAPI: Using default reciter: ar.alafasy');
    return 'ar.alafasy';
  }
}
