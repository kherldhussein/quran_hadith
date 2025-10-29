import 'package:flutter/foundation.dart';

/// Service to track current playback state globally
class PlaybackStateService {
  static final PlaybackStateService _instance =
      PlaybackStateService._internal();
  factory PlaybackStateService() => _instance;
  PlaybackStateService._internal();

  final ValueNotifier<PlaybackInfo?> currentPlayback =
      ValueNotifier<PlaybackInfo?>(null);

  void updatePlayback({
    required String surahName,
    required String surahEnglishName,
    required int surahNumber,
    required int ayahNumber,
    required String reciter,
  }) {
    currentPlayback.value = PlaybackInfo(
      surahName: surahName,
      surahEnglishName: surahEnglishName,
      surahNumber: surahNumber,
      ayahNumber: ayahNumber,
      reciter: reciter,
      timestamp: DateTime.now(),
    );
  }

  void clearPlayback() {
    currentPlayback.value = null;
  }
}

class PlaybackInfo {
  final String surahName;
  final String surahEnglishName;
  final int surahNumber;
  final int ayahNumber;
  final String reciter;
  final DateTime timestamp;

  PlaybackInfo({
    required this.surahName,
    required this.surahEnglishName,
    required this.surahNumber,
    required this.ayahNumber,
    required this.reciter,
    required this.timestamp,
  });

  String get displayText => '$surahEnglishName - Ayah $ayahNumber';
  String get fullDisplayText => '$surahName ($surahEnglishName) - Ayah $ayahNumber';
}
