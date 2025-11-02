import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:quran_hadith/controller/audio_controller.dart';
import 'package:quran_hadith/controller/quranAPI.dart';
import 'package:quran_hadith/database/database_service.dart';
import 'package:quran_hadith/database/hive_adapters.dart';
import 'package:quran_hadith/services/native_desktop_service.dart';
import 'package:quran_hadith/services/offline_audio_service.dart' as offline;
import 'package:quran_hadith/services/playback_state_service.dart';
import 'package:quran_hadith/services/reciter_service.dart';
import 'package:quran_hadith/utils/sp_util.dart';

/// Global audio service that wraps [AudioController] and exposes
/// app-wide playback state, regardless of the active UI.
class GlobalAudioService extends ChangeNotifier {
  GlobalAudioService._internal() {
    _loadPreferences();
    _wireController();
    debugPrint('✅ GlobalAudioService initialized');
  }

  static final GlobalAudioService _instance = GlobalAudioService._internal();
  factory GlobalAudioService() => _instance;

  final AudioController _audioController = AudioController();
  AudioController get audioController => _audioController;
  final PlaybackStateService _playbackState = PlaybackStateService();
  final NativeDesktopService _nativeDesktop = NativeDesktopService();

  // Exposed state
  final ValueNotifier<AyahPlaybackContext?> currentContextNotifier =
      ValueNotifier<AyahPlaybackContext?>(null);
  final ValueNotifier<bool> isSurahModeNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<ButtonState> _buttonStateNotifier =
      ValueNotifier<ButtonState>(ButtonState.paused);
  final ValueNotifier<ProgressBarState> _progressNotifier =
      ValueNotifier<ProgressBarState>(
    ProgressBarState(
      current: Duration.zero,
      buffered: Duration.zero,
      total: Duration.zero,
    ),
  );

  // Playback configuration
  bool _isSurahPlaybackMode = false;
  String _repeatMode = 'none';
  bool _autoPlayNext = false;

  // Context of the currently playing ayah (if any)
  AyahPlaybackContext? _currentContext;

  // Timers
  Timer? _listeningProgressTimer;
  DateTime? _currentAyahPlaybackStart;

  // Navigation callbacks (provided by UI layer)
  Function(int ayahNumber)? _onNextAyahRequested;
  Function(int ayahNumber)? _onPreviousAyahRequested;

  /// Public accessors -------------------------------------------------------

  ValueListenable<ButtonState> get buttonStateListenable =>
      _buttonStateNotifier;
  ValueListenable<ProgressBarState> get progressListenable => _progressNotifier;

  ButtonState get buttonState => _buttonStateNotifier.value;
  ProgressBarState get progress => _progressNotifier.value;
  AyahPlaybackContext? get currentContext => _currentContext;
  bool get isPlaying => buttonState == ButtonState.playing;
  bool get isSurahMode => _isSurahPlaybackMode;

  Duration get position => _progressNotifier.value.current;
  Duration get duration => _progressNotifier.value.total;

  /// Audio control API ------------------------------------------------------

  Future<void> playAyah({
    required int surahNumber,
    required int ayahNumber,
    required String surahName,
    required String surahEnglishName,
    String? arabicText,
    String? audioUrl,
    String? localFilePath,
    List<int>? allAyahsInSurah,
  }) async {
    try {
      debugPrint(
        '🎵 GlobalAudioService.playAyah: Playing Ayah $surahNumber:$ayahNumber | allAyahsInSurah=${allAyahsInSurah?.length ?? 0} ayahs',
      );

      _currentContext = AyahPlaybackContext(
        surahNumber: surahNumber,
        ayahNumber: ayahNumber,
        surahName: surahName,
        surahEnglishName: surahEnglishName,
        arabicText: arabicText,
        audioUrl: audioUrl,
        localFilePath: localFilePath,
        allAyahsInSurah: allAyahsInSurah,
      );
      currentContextNotifier.value = _currentContext;

      final reciterId = ReciterService.instance.currentReciterId.value;
      String? effectivePath = localFilePath;

      if (effectivePath == null) {
        final localFile =
            await offline.OfflineAudioService.instance.getLocalAyahFile(
          reciterId: reciterId,
          surahNumber: surahNumber,
          ayahNumber: ayahNumber,
        );
        effectivePath = localFile?.path;
      }

      if (effectivePath != null) {
        await _audioController.setLocalSource(effectivePath);
      } else if (audioUrl != null && audioUrl.isNotEmpty) {
        await _audioController.setAudioSource(audioUrl);
      } else {
        throw Exception('No audio source available for ayah $ayahNumber');
      }

      await _audioController.setSpeed(SpUtil.getAudioSpeed());

      _audioController.play();
      _buttonStateNotifier.value = ButtonState.playing;

      _playbackState.updatePlayback(
        surahName: surahName,
        surahEnglishName: surahEnglishName,
        surahNumber: surahNumber,
        ayahNumber: ayahNumber,
        reciter: reciterId,
      );

      _nativeDesktop.updatePlaybackInfo(
        surah: surahEnglishName,
        ayah: ayahNumber,
        reciter: reciterId,
        isPlaying: true,
        position: Duration.zero,
        duration: Duration.zero,
      );

      _startListeningProgressTracking();
      await _saveListeningProgress(surahNumber, ayahNumber, 0);
      SpUtil.setLastListen(surah: surahNumber, ayah: ayahNumber, positionMs: 0);

      notifyListeners();
    } catch (error, stackTrace) {
      debugPrint('❌ GlobalAudioService: Error playing ayah: $error');
      _currentContext = null;
      currentContextNotifier.value = null;
      _buttonStateNotifier.value = ButtonState.paused;
      _playbackState.clearPlayback();
      _nativeDesktop.updatePlaybackState(
        isPlaying: false,
        position: Duration.zero,
        duration: Duration.zero,
      );
      notifyListeners();
      Error.safeToString(
        stackTrace,
      ); // keeps analyzer quiet for unused stackTrace
      rethrow;
    }
  }

  void pause() {
    _audioController.pause();
    _buttonStateNotifier.value = ButtonState.paused;
    _stopListeningProgressTracking();
    notifyListeners();
  }

  void resume() {
    if (_currentContext == null) return;
    _audioController.play();
    _buttonStateNotifier.value = ButtonState.playing;
    _startListeningProgressTracking();
    notifyListeners();
  }

  void togglePlayPause() {
    if (isPlaying) {
      pause();
    } else {
      resume();
    }
  }

  void stop() {
    _audioController.pause();
    _buttonStateNotifier.value = ButtonState.paused;
    _stopListeningProgressTracking();
    _currentContext = null;
    currentContextNotifier.value = null;
    _playbackState.clearPlayback();
    notifyListeners();
  }

  Future<void> playNext() async {
    debugPrint(
        '📞 [GlobalAudioService.playNext] Called | _currentContext=${_currentContext?.surahNumber}:${_currentContext?.ayahNumber}');

    if (_currentContext == null ||
        _currentContext!.allAyahsInSurah == null ||
        _currentContext!.allAyahsInSurah!.isEmpty) {
      debugPrint(
          '⚠️ [GlobalAudioService.playNext] Cannot play next - missing context or ayahs list');
      return;
    }

    final ayahs = _currentContext!.allAyahsInSurah!;
    final currentIndex = ayahs.indexOf(_currentContext!.ayahNumber);
    debugPrint(
        '📊 [GlobalAudioService.playNext] currentIndex=$currentIndex | totalAyahs=${ayahs.length} | currentAyah=${_currentContext!.ayahNumber}');

    if (currentIndex == -1) {
      debugPrint(
          '⚠️ [GlobalAudioService.playNext] Current ayah not found in list');
      return;
    }

    int? nextAyahNumber;
    if (currentIndex < ayahs.length - 1) {
      nextAyahNumber = ayahs[currentIndex + 1];
      debugPrint(
          '✅ [GlobalAudioService.playNext] Next ayah found: $nextAyahNumber');
    } else if (_repeatMode == 'surah') {
      nextAyahNumber = ayahs.first;
      debugPrint(
          '🔄 [GlobalAudioService.playNext] Repeat mode=surah, looping to first ayah: $nextAyahNumber');
    } else {
      debugPrint(
          'ℹ️ [GlobalAudioService.playNext] At end of surah and no repeat mode');
    }

    if (nextAyahNumber != null) {
      if (_onNextAyahRequested != null) {
        debugPrint(
            '🎯 [GlobalAudioService.playNext] Invoking callback with nextAyahNumber=$nextAyahNumber');
        _onNextAyahRequested!(nextAyahNumber);
      } else {
        // Callback not registered (user navigated away from QPageView)
        // Play the next ayah directly from the service
        debugPrint(
            '⚠️ [GlobalAudioService.playNext] Callback is NULL - playing directly from service');
        await _playNextAyahDirectly(nextAyahNumber);
      }
    }
  }

  /// Play the next ayah directly without relying on UI callbacks
  /// This allows audio to continue playing even when user navigates away from QPageView
  Future<void> _playNextAyahDirectly(int nextAyahNumber) async {
    try {
      debugPrint(
          '🔊 [GlobalAudioService._playNextAyahDirectly] Playing ayah $nextAyahNumber directly');

      // Get the cached surah to fetch ayah details
      var cachedSurah = database.getCachedSurah(_currentContext!.surahNumber);

      // If not cached, fetch from API and cache it
      if (cachedSurah == null) {
        debugPrint(
            '📥 [GlobalAudioService._playNextAyahDirectly] Surah ${_currentContext!.surahNumber} not cached, fetching from API...');

        cachedSurah = await _fetchAndCacheSurah(_currentContext!.surahNumber);
        if (cachedSurah == null) {
          return;
        }
      }

      // Find the ayah in the cached data
      final nextAyah = cachedSurah.ayahs.firstWhere(
        (a) => a.number == nextAyahNumber,
        orElse: () => throw Exception('Ayah $nextAyahNumber not found'),
      );

      debugPrint(
          '✅ [GlobalAudioService._playNextAyahDirectly] Ayah $nextAyahNumber found in cache');

      // Try to get the local file path for offline playback
      String? localFilePath;
      final reciterId = ReciterService.instance.currentReciterId.value;
      try {
        final localFile =
            await offline.OfflineAudioService.instance.getLocalAyahFile(
          reciterId: reciterId,
          surahNumber: _currentContext!.surahNumber,
          ayahNumber: nextAyahNumber,
        );
        localFilePath = localFile?.path;
      } catch (e) {
        debugPrint(
            '⚠️ [GlobalAudioService._playNextAyahDirectly] Could not get local file: $e');
      }

      // Try to get fresh audio URL if not in cache
      String? audioUrl = nextAyah.audioUrl;
      if (audioUrl == null || audioUrl.isEmpty) {
        debugPrint(
            '⚠️ [GlobalAudioService._playNextAyahDirectly] Audio URL not in cache, fetching...');
        try {
          audioUrl = await QuranAPI()
              .getAyahAudioUrl(_currentContext!.surahNumber, nextAyahNumber);
          if (audioUrl != null && audioUrl.isNotEmpty) {
            debugPrint(
                '✅ [GlobalAudioService._playNextAyahDirectly] Fresh audio URL fetched');
          }
        } catch (e) {
          debugPrint(
              '⚠️ [GlobalAudioService._playNextAyahDirectly] Could not fetch audio URL: $e');
        }
      }

      // Play the ayah using the existing playAyah method
      await playAyah(
        surahNumber: _currentContext!.surahNumber,
        ayahNumber: nextAyahNumber,
        surahName: _currentContext!.surahName,
        surahEnglishName: _currentContext!.surahEnglishName,
        arabicText: nextAyah.text,
        audioUrl: audioUrl,
        localFilePath: localFilePath,
        allAyahsInSurah: _currentContext!.allAyahsInSurah,
      );

      debugPrint(
          '🎵 [GlobalAudioService._playNextAyahDirectly] Successfully playing next ayah');
    } catch (e) {
      debugPrint('❌ [GlobalAudioService._playNextAyahDirectly] Error: $e');
    }
  }

  /// Fetch surah from API and cache it with audio URLs
  Future<CachedSurah?> _fetchAndCacheSurah(int surahNumber) async {
    try {
      final quranAPI = QuranAPI();
      final surahListData = await quranAPI.getSuratList();
      final surah = surahListData.surahs?.firstWhere(
        (s) => s.number == surahNumber,
        orElse: () => throw Exception('Surah not found in list'),
      );

      if (surah == null) {
        throw Exception('Surah $surahNumber not found');
      }

      // Convert Surah model to CachedAyah with audio URLs
      // We fetch audio URLs in parallel for performance
      final ayahsFutures = (surah.ayahs ?? []).map((ayah) async {
        String? audioUrl;
        try {
          audioUrl =
              await quranAPI.getAyahAudioUrl(surahNumber, ayah.number ?? 0);
        } catch (e) {
          debugPrint(
              '⚠️ [_fetchAndCacheSurah] Could not fetch audio URL for $surahNumber:${ayah.number}: $e');
        }
        return CachedAyah(
          number: ayah.number ?? 0,
          text: ayah.text ?? '',
          numberInSurah: ayah.number ?? 0,
          juz: 0,
          audioUrl: audioUrl,
        );
      });

      final cachedAyahs = await Future.wait(ayahsFutures);

      final cachedSurah = CachedSurah(
        number: surah.number ?? surahNumber,
        name: surah.name ?? '',
        englishName: surah.englishName ?? '',
        englishNameTranslation: surah.englishNameTranslation ?? '',
        revelationType: surah.revelationType ?? '',
        numberOfAyahs: surah.numberOfAyahs ?? 0,
        ayahs: cachedAyahs,
      );

      // Cache it for future use
      await database.cacheSurah(cachedSurah);
      debugPrint(
          '✅ [_fetchAndCacheSurah] Surah $surahNumber cached with audio URLs');
      return cachedSurah;
    } catch (e) {
      debugPrint('❌ [_fetchAndCacheSurah] Failed to fetch surah: $e');
      return null;
    }
  }

  Future<void> playPrevious() async {
    if (_currentContext == null ||
        _currentContext!.allAyahsInSurah == null ||
        _currentContext!.allAyahsInSurah!.isEmpty) {
      return;
    }

    final ayahs = _currentContext!.allAyahsInSurah!;
    final currentIndex = ayahs.indexOf(_currentContext!.ayahNumber);
    if (currentIndex == -1) return;

    if (currentIndex > 0) {
      final previousAyahNumber = ayahs[currentIndex - 1];
      if (_onPreviousAyahRequested != null) {
        _onPreviousAyahRequested?.call(previousAyahNumber);
      } else {
        // Callback not registered - play directly from service
        await _playPreviousAyahDirectly(previousAyahNumber);
      }
    }
  }

  /// Play the previous ayah directly without relying on UI callbacks
  Future<void> _playPreviousAyahDirectly(int previousAyahNumber) async {
    try {
      debugPrint(
          '🔊 [GlobalAudioService._playPreviousAyahDirectly] Playing ayah $previousAyahNumber directly');

      // Get the cached surah to fetch ayah details
      var cachedSurah = database.getCachedSurah(_currentContext!.surahNumber);

      // If not cached, fetch from API and cache it
      if (cachedSurah == null) {
        debugPrint(
            '📥 [GlobalAudioService._playPreviousAyahDirectly] Surah ${_currentContext!.surahNumber} not cached, fetching from API...');

        cachedSurah = await _fetchAndCacheSurah(_currentContext!.surahNumber);
        if (cachedSurah == null) {
          return;
        }
      }

      // Find the ayah in the cached data
      final previousAyah = cachedSurah.ayahs.firstWhere(
        (a) => a.number == previousAyahNumber,
        orElse: () => throw Exception('Ayah $previousAyahNumber not found'),
      );

      debugPrint(
          '✅ [GlobalAudioService._playPreviousAyahDirectly] Ayah $previousAyahNumber found in cache');

      // Try to get the local file path for offline playback
      String? localFilePath;
      final reciterId = ReciterService.instance.currentReciterId.value;
      try {
        final localFile =
            await offline.OfflineAudioService.instance.getLocalAyahFile(
          reciterId: reciterId,
          surahNumber: _currentContext!.surahNumber,
          ayahNumber: previousAyahNumber,
        );
        localFilePath = localFile?.path;
      } catch (e) {
        debugPrint(
            '⚠️ [GlobalAudioService._playPreviousAyahDirectly] Could not get local file: $e');
      }

      // Try to get fresh audio URL if not in cache
      String? audioUrl = previousAyah.audioUrl;
      if (audioUrl == null || audioUrl.isEmpty) {
        debugPrint(
            '⚠️ [GlobalAudioService._playPreviousAyahDirectly] Audio URL not in cache, fetching...');
        try {
          audioUrl = await QuranAPI().getAyahAudioUrl(
              _currentContext!.surahNumber, previousAyahNumber);
          if (audioUrl != null && audioUrl.isNotEmpty) {
            debugPrint(
                '✅ [GlobalAudioService._playPreviousAyahDirectly] Fresh audio URL fetched');
          }
        } catch (e) {
          debugPrint(
              '⚠️ [GlobalAudioService._playPreviousAyahDirectly] Could not fetch audio URL: $e');
        }
      }

      // Play the ayah using the existing playAyah method
      await playAyah(
        surahNumber: _currentContext!.surahNumber,
        ayahNumber: previousAyahNumber,
        surahName: _currentContext!.surahName,
        surahEnglishName: _currentContext!.surahEnglishName,
        arabicText: previousAyah.text,
        audioUrl: audioUrl,
        localFilePath: localFilePath,
        allAyahsInSurah: _currentContext!.allAyahsInSurah,
      );

      debugPrint(
          '🎵 [GlobalAudioService._playPreviousAyahDirectly] Successfully playing previous ayah');
    } catch (e) {
      debugPrint('❌ [GlobalAudioService._playPreviousAyahDirectly] Error: $e');
    }
  }

  void seek(Duration position) {
    _audioController.seek(position);
  }

  Future<void> setSpeed(double speed) async {
    await _audioController.setSpeed(speed);
    SpUtil.setAudioSpeed(speed);
  }

  Future<void> setVolume(double volume) async {
    await _audioController.setVolume(volume);
    notifyListeners();
  }

  void setSurahMode(bool enabled) {
    _isSurahPlaybackMode = enabled;
    isSurahModeNotifier.value = enabled;
    notifyListeners();
  }

  void setRepeatMode(String mode) {
    _repeatMode = mode;
    SpUtil.setRepeatMode(mode);
    notifyListeners();
  }

  void setAutoPlayNext(bool enabled) {
    _autoPlayNext = enabled;
    SpUtil.setAutoPlayNextAyah(enabled);
    notifyListeners();
  }

  void setNavigationCallbacks({
    Function(int ayahNumber)? onNextAyahRequested,
    Function(int ayahNumber)? onPreviousAyahRequested,
  }) {
    _onNextAyahRequested = onNextAyahRequested;
    _onPreviousAyahRequested = onPreviousAyahRequested;
  }

  void clearNavigationCallbacks() {
    _onNextAyahRequested = null;
    _onPreviousAyahRequested = null;
  }

  /// Lifecycle --------------------------------------------------------------

  void disposeService() {
    _stopListeningProgressTracking();
    _audioController.buttonNotifier.removeListener(_handleControllerButton);
    _audioController.progressNotifier.removeListener(_handleControllerProgress);
    currentContextNotifier.dispose();
    isSurahModeNotifier.dispose();
    _buttonStateNotifier.dispose();
    _progressNotifier.dispose();
  }

  /// Internal helpers -------------------------------------------------------

  void _loadPreferences() {
    _repeatMode = SpUtil.getRepeatMode();
    _autoPlayNext = SpUtil.getAutoPlayNextAyah();
  }

  void _wireController() {
    _audioController.buttonNotifier.addListener(_handleControllerButton);
    _audioController.progressNotifier.addListener(_handleControllerProgress);
  }

  void _handleControllerButton() {
    final state = _audioController.buttonNotifier.value;
    _buttonStateNotifier.value = state;

    if (state == ButtonState.paused && _currentContext != null) {
      // When audio completes, buttonNotifier changes to PAUSED,
      // but _completedFlag might not be set yet due to async stream listener.
      // Check it with a small delay to ensure flag has propagated.
      Future.delayed(const Duration(milliseconds: 10), () {
        final completed = _audioController.hasRecentlyCompleted;
        debugPrint(
            '🔴 [GlobalAudioService._handleControllerButton] PAUSED | completed=$completed | ayah=${_currentContext?.ayahNumber}');

        if (completed && _currentContext != null) {
          _audioController.clearCompletedFlag();

          // Re-read runtime settings each time to reflect user changes
          _autoPlayNext = SpUtil.getAutoPlayNextAyah();
          _repeatMode = SpUtil.getRepeatMode();
          debugPrint(
              '🎵 [GlobalAudioService._handleControllerButton] COMPLETED | _autoPlayNext=$_autoPlayNext | _repeatMode=$_repeatMode');

          if (_repeatMode == 'ayah') {
            debugPrint(
                '🔁 [GlobalAudioService._handleControllerButton] Repeating ayah');
            Future.delayed(const Duration(milliseconds: 200), resume);
            return;
          }

          if (_autoPlayNext || _isSurahPlaybackMode) {
            debugPrint(
                '⏭️ [GlobalAudioService._handleControllerButton] Calling playNext() after 250ms');
            Future.delayed(const Duration(milliseconds: 250), playNext);
            return;
          }
        }

        _stopListeningProgressTracking();
        notifyListeners();
      });
      return;
    } else if (state == ButtonState.playing) {
      _startListeningProgressTracking();
    }

    notifyListeners();
  }

  void _handleControllerProgress() {
    _progressNotifier.value = _audioController.progressNotifier.value;
    notifyListeners();
  }

  void _startListeningProgressTracking() {
    _listeningProgressTimer?.cancel();
    _currentAyahPlaybackStart = DateTime.now();

    _listeningProgressTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (_currentContext == null) return;
      if (_audioController.buttonNotifier.value != ButtonState.playing) {
        return;
      }

      final currentPosition =
          _audioController.progressNotifier.value.current.inMilliseconds;
      _saveListeningProgress(
        _currentContext!.surahNumber,
        _currentContext!.ayahNumber,
        currentPosition,
      );
    });
  }

  void _stopListeningProgressTracking() {
    _listeningProgressTimer?.cancel();
    _listeningProgressTimer = null;

    if (_currentContext != null) {
      final currentPosition =
          _audioController.progressNotifier.value.current.inMilliseconds;
      _saveListeningProgress(
        _currentContext!.surahNumber,
        _currentContext!.ayahNumber,
        currentPosition,
      );
    }
    _currentAyahPlaybackStart = null;
  }

  Future<void> _saveListeningProgress(
    int surahNumber,
    int ayahNumber,
    int positionMs,
  ) async {
    try {
      final currentProgress = database.getListeningProgress(
        surahNumber,
        ayahNumber,
      );

      int addedListenTime = 0;

      if (_currentAyahPlaybackStart != null) {
        final elapsed =
            DateTime.now().difference(_currentAyahPlaybackStart!).inSeconds;
        addedListenTime = elapsed.clamp(0, 300);
        _currentAyahPlaybackStart = DateTime.now();
      } else if (currentProgress != null) {
        final previousPosition = currentProgress.positionMs;
        addedListenTime = ((positionMs - previousPosition) ~/ 1000).abs();
        addedListenTime = addedListenTime.clamp(0, 300);
      } else {
        addedListenTime = 5;
      }

      final previousTotal = currentProgress?.totalListenTimeSeconds ?? 0;
      final newTotal = previousTotal + addedListenTime;

      final progress = ListeningProgress(
        surahNumber: surahNumber,
        ayahNumber: ayahNumber,
        positionMs: positionMs,
        lastListenedAt: DateTime.now(),
        totalListenTimeSeconds: newTotal,
        completed: false,
        reciter: ReciterService.instance.currentReciterId.value,
        playbackSpeed: SpUtil.getAudioSpeed(),
      );

      await database.saveListeningProgress(progress);
    } catch (error) {
      debugPrint(
        '❌ GlobalAudioService: Failed to save listening progress: $error',
      );
    }
  }
}

/// Context information for currently playing ayah.
class AyahPlaybackContext {
  AyahPlaybackContext({
    required this.surahNumber,
    required this.ayahNumber,
    required this.surahName,
    required this.surahEnglishName,
    this.arabicText,
    this.audioUrl,
    this.localFilePath,
    this.allAyahsInSurah,
  });

  final int surahNumber;
  final int ayahNumber;
  final String surahName;
  final String surahEnglishName;
  final String? arabicText;
  final String? audioUrl;
  final String? localFilePath;
  final List<int>? allAyahsInSurah;

  String get displayText => '$surahEnglishName - Ayah $ayahNumber';
  String get fullDisplayText =>
      '$surahName ($surahEnglishName) - Ayah $ayahNumber';
}
