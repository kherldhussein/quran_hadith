import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:quran_hadith/controller/quranAPI.dart';

/// Manages offline audio downloads & lookups.
/// Files are stored under: <app_support>/audio/<reciterId>/<surahNumber>/<ayah>.mp3
class OfflineAudioService {
  OfflineAudioService._();
  static final OfflineAudioService instance = OfflineAudioService._();

  static const _indexFileName = 'downloads_index.json';

  Future<Directory> _rootDir() async {
    final dir = await getApplicationSupportDirectory();
    final audio = Directory(p.join(dir.path, 'audio'));
    if (!await audio.exists()) await audio.create(recursive: true);
    return audio;
  }

  Future<File> _indexFile() async {
    final root = await _rootDir();
    return File(p.join(root.path, _indexFileName));
  }

  Future<Map<String, dynamic>> _loadIndex() async {
    try {
      final f = await _indexFile();
      if (!await f.exists()) return {};
      final txt = await f.readAsString();
      return json.decode(txt) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  Future<void> _saveIndex(Map<String, dynamic> idx) async {
    final f = await _indexFile();
    await f.writeAsString(json.encode(idx));
  }

  String _key(String reciterId, int surahNumber) => '$reciterId:$surahNumber';

  Future<String> _surahDirPath(String reciterId, int surahNumber) async {
    final root = await _rootDir();
    return p.join(root.path, reciterId, surahNumber.toString());
  }

  /// Return the local file if present, else null.
  Future<File?> getLocalAyahFile({
    required String reciterId,
    required int surahNumber,
    required int ayahNumber,
  }) async {
    final dirPath = await _surahDirPath(reciterId, surahNumber);
    final f = File(p.join(dirPath, '$ayahNumber.mp3'));
    if (await f.exists()) return f;
    return null;
  }

  Future<bool> isSurahDownloaded({
    required String reciterId,
    required int surahNumber,
    required int ayahCount,
  }) async {
    final dirPath = await _surahDirPath(reciterId, surahNumber);
    final dir = Directory(dirPath);
    if (!await dir.exists()) return false;
    final files = await dir
        .list()
        .where((e) => e is File && e.path.endsWith('.mp3'))
        .toList();
    return files.length >= ayahCount;
  }

  Future<void> removeSurah({
    required String reciterId,
    required int surahNumber,
  }) async {
    final dirPath = await _surahDirPath(reciterId, surahNumber);
    final dir = Directory(dirPath);
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
    final idx = await _loadIndex();
    idx.remove(_key(reciterId, surahNumber));
    await _saveIndex(idx);
  }

  /// Download an entire surah for a reciter.
  /// onProgress is called with (downloaded, total)
  Future<void> downloadSurah({
    required String reciterId,
    required int surahNumber,
    required int ayahCount,
    void Function(int downloaded, int total)? onProgress,
    CancelToken? cancelToken,
  }) async {
    final dirPath = await _surahDirPath(reciterId, surahNumber);
    final dir = Directory(dirPath);
    if (!await dir.exists()) await dir.create(recursive: true);

    int completed = 0;
    onProgress?.call(completed, ayahCount);

    final api = QuranAPI();
    for (int n = 1; n <= ayahCount; n++) {
      if (cancelToken?.isCancelled == true) break;
      final localFile = File(p.join(dirPath, '$n.mp3'));
      if (await localFile.exists() && await localFile.length() > 1000) {
        completed++;
        onProgress?.call(completed, ayahCount);
        continue;
      }

      // Resolve remote URL via API (reciter-aware)
      final url =
          await api.getAyahAudioUrl(surahNumber, n, reciterId: reciterId);
      if (url == null || url.isEmpty) {
        debugPrint('OfflineAudioService: Missing URL for $surahNumber:$n');
        continue;
      }

      try {
        final resp = await http.get(Uri.parse(url),
            headers: {'Accept': '*/*'}).timeout(const Duration(seconds: 30));
        if (resp.statusCode == 200) {
          await localFile.writeAsBytes(resp.bodyBytes);
        } else {
          debugPrint('OfflineAudioService: HTTP ${resp.statusCode} for $url');
        }
      } catch (e) {
        debugPrint('OfflineAudioService: Download error for $url: $e');
      }

      completed++;
      onProgress?.call(completed, ayahCount);
    }

    // Update index
    final idx = await _loadIndex();
    idx[_key(reciterId, surahNumber)] = {
      'reciter': reciterId,
      'surah': surahNumber,
      'ayahCount': ayahCount,
      'path': dirPath,
      'updatedAt': DateTime.now().toIso8601String(),
    };
    await _saveIndex(idx);
  }
}

/// Simple cancellation token.
class CancelToken {
  bool _cancelled = false;
  bool get isCancelled => _cancelled;
  void cancel() => _cancelled = true;
}
