import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:quran_hadith/models/juzModel.dart';
import 'package:quran_hadith/models/surah_model.dart';
import 'package:http/http.dart' as http;

/// The Qur'an contains 6236 verses
class QuranAPI {
  late Response response;
  Dio dio = Dio();
  final String _cacheDirName = 'cache';

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

    // Check cache first
    if (await cacheFile.exists()) {
      try {
        final cacheAge = DateTime.now().difference(
          await cacheFile.lastModified()
        );

        // Use cache if less than 7 days old
        if (cacheAge.inDays < 7) {
          debugPrint('QuranAPI: Using cached surah list (age: ${cacheAge.inDays} days)');
          final cached = await cacheFile.readAsString();
          return SurahList.fromJSON(json.decode(cached));
        }
      } catch (e) {
        debugPrint('QuranAPI: Error reading cache: $e');
      }
    }

    // Fetch from network
    try {
      debugPrint('QuranAPI: Fetching surah list from API...');
      final response = await http.get(Uri.parse(url))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        await cacheFile.writeAsString(response.body);
        debugPrint('QuranAPI: Surah list fetched and cached successfully');
        return SurahList.fromJSON(json.decode(response.body));
      }
    } catch (e) {
      debugPrint('QuranAPI: Network fetch failed: $e');
    }

    // Fallback to cache
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
    final cacheFile = await _ensureCacheFile('surat_audio.json');

    // Check cache first
    if (await cacheFile.exists()) {
      try {
        final cacheAge = DateTime.now().difference(
          await cacheFile.lastModified()
        );

        // Use cache if less than 7 days old
        if (cacheAge.inDays < 7) {
          debugPrint('QuranAPI: Using cached surah audio data (age: ${cacheAge.inDays} days)');
          final cached = await cacheFile.readAsString();
          return SurahList.fromJSON(json.decode(cached));
        } else {
          debugPrint('QuranAPI: Cache expired, fetching fresh data...');
        }
      } catch (e) {
        debugPrint('QuranAPI: Error reading cache: $e');
      }
    }

    // Fetch from network if cache doesn't exist or is expired
    try {
      debugPrint('QuranAPI: Fetching surah audio data from API...');
      final response = await http
          .get(Uri.parse("https://api.alquran.cloud/v1/quran/ar.alafasy"))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        await cacheFile.writeAsString(response.body);
        debugPrint('QuranAPI: Surah audio data fetched and cached successfully');
        return SurahList.fromJSON(json.decode(response.body));
      }
    } catch (e) {
      debugPrint('QuranAPI: Network fetch failed: $e');
      // Fall through to use cache if available
    }

    // Final fallback to cache even if expired
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

  /// FIXED: Get audio URL for a specific surah
  Future<String?> getSurahAudioUrl(int suratNo) async {
    try {
      final response = await dio.get("https://api.alquran.cloud/v1/surah/$suratNo/ar.alafasy");

      if (response.statusCode == 200) {
        // Parse the response correctly
        final Map<String, dynamic> responseData = response.data is String
            ? json.decode(response.data)
            : response.data;

        // Navigate through the response structure
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

  /// ALTERNATIVE: Get audio URL for specific ayah
  Future<String?> getAyahAudioUrl(int suratNo, int ayahNo) async {
    try {
      final response = await dio.get("https://api.alquran.cloud/v1/ayah/$suratNo:$ayahNo/ar.alafasy");

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = response.data is String
            ? json.decode(response.data)
            : response.data;

        final data = responseData['data'];
        if (data != null) {
          final audioUrl = data['audio'] as String?;
          return audioUrl;
        }
      }
      return null;
    } catch (e) {
      debugPrint("Error fetching ayah audio URL for $suratNo:$ayahNo: $e");
      return null;
    }
  }

  /// Get Surah with English translation (cached indefinitely)
  Future<Map<int, String>> getSurahTranslations(int surahNumber, {String edition = 'en.sahih'}) async {
    final cacheFile = await _ensureCacheFile('translation_${surahNumber}_$edition.json');

    // Check cache first - translations don't change, so cache indefinitely
    if (await cacheFile.exists()) {
      try {
        debugPrint('QuranAPI: Using cached translation for Surah $surahNumber');
        final cached = await cacheFile.readAsString();
        return _parseTranslations(cached);
      } catch (e) {
        debugPrint("Error reading translation cache: $e");
      }
    }

    // Fetch from network only if cache doesn't exist
    try {
      debugPrint('QuranAPI: Fetching translation for Surah $surahNumber from API...');
      final response = await http.get(
        Uri.parse("https://api.alquran.cloud/v1/surah/$surahNumber/editions/quran-uthmani,$edition")
      ).timeout(const Duration(seconds: 10));

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

      // data[0] is Arabic, data[1] is translation
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
  Future<String?> getAyahTranslation(int surahNumber, int ayahNumber, {String edition = 'en.sahih'}) async {
    try {
      final response = await dio.get("https://api.alquran.cloud/v1/ayah/$surahNumber:$ayahNumber/$edition");

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
      debugPrint("Error fetching ayah translation for $surahNumber:$ayahNumber: $e");
      return null;
    }
  }
}