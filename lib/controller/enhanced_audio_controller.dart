import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:rxdart/rxdart.dart' as rx;
import 'package:quran_hadith/models/surah_model.dart';
import 'package:quran_hadith/database/database_service.dart';
import 'package:quran_hadith/database/hive_adapters.dart';

/// Enhanced audio controller with advanced features
class EnhancedAudioController extends ChangeNotifier {
  bool _isDisposed = false;
  AudioPlayer? _audioPlayer;
  bool _playerInitAttempted = false;
  bool _playerAvailable = false;

  // Per-surah ayah counts (1..114)
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

  void _safeNotify() {
    if (!_isDisposed) notifyListeners();
  }

  // State notifiers
  final progressNotifier = ValueNotifier<ProgressBarState>(
    ProgressBarState(
      current: Duration.zero,
      buffered: Duration.zero,
      total: Duration.zero,
    ),
  );
  final buttonNotifier =
      ValueNotifier<AudioButtonState>(AudioButtonState.paused);
  final repeatModeNotifier = ValueNotifier<RepeatMode>(RepeatMode.off);
  final shuffleNotifier = ValueNotifier<bool>(false);
  final speedNotifier = ValueNotifier<double>(1.0);

  // Playlist management
  List<PlaylistItem> _playlist = [];
  int _currentIndex = 0;

  // Configuration
  bool _continuousPlayback = true;
  String _reciter = 'ar.alafasy';

  // Getters
  List<PlaylistItem> get playlist => List.unmodifiable(_playlist);
  int get currentIndex => _currentIndex;
  PlaylistItem? get currentTrack =>
      _playlist.isNotEmpty && _currentIndex < _playlist.length
          ? _playlist[_currentIndex]
          : null;
  bool get continuousPlayback => _continuousPlayback;
  String get reciter => _reciter;

  EnhancedAudioController() {
    // Start player init in background but don't crash if it fails.
    _init();
  }

  Future<void> _init() async {
    if (_playerInitAttempted) return;
    _playerInitAttempted = true;

    try {
      _audioPlayer = AudioPlayer();
      _playerAvailable = true;

      // Load saved settings
      await _loadSettings();

      // Player state listener
      _audioPlayer!.playerStateStream.listen((playerState) {
        _handlePlayerStateChange(playerState);
      });

      // Position listener
      _audioPlayer!.positionStream.listen((position) {
        final oldState = progressNotifier.value;
        progressNotifier.value = ProgressBarState(
          current: position,
          buffered: oldState.buffered,
          total: oldState.total,
        );

        // Save progress periodically
        _saveListeningProgress();
      });

      // Buffered position listener
      _audioPlayer!.bufferedPositionStream.listen((bufferedPosition) {
        final oldState = progressNotifier.value;
        progressNotifier.value = ProgressBarState(
          current: oldState.current,
          buffered: bufferedPosition,
          total: oldState.total,
        );
      });

      // Duration listener
      _audioPlayer!.durationStream.listen((totalDuration) {
        final oldState = progressNotifier.value;
        progressNotifier.value = ProgressBarState(
          current: oldState.current,
          buffered: oldState.buffered,
          total: totalDuration ?? Duration.zero,
        );
      });

      // Playback event listener for completion
      _audioPlayer!.playbackEventStream.listen((event) {
        if (event.processingState == ProcessingState.completed) {
          _handleTrackCompletion();
        }
      });
    } catch (e) {
      _playerAvailable = false;
      debugPrint('EnhancedAudioController: AudioPlayer init failed: $e');
    }
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = database.getPreferences();
      _reciter = prefs.reciter;
      await setSpeed(prefs.playbackSpeed);
    } catch (e) {
      debugPrint('Error loading audio settings: $e');
    }
  }

  void _handlePlayerStateChange(PlayerState playerState) {
    final isPlaying = playerState.playing;
    final processingState = playerState.processingState;

    if (processingState == ProcessingState.loading ||
        processingState == ProcessingState.buffering) {
      buttonNotifier.value = AudioButtonState.loading;
    } else if (!isPlaying) {
      buttonNotifier.value = AudioButtonState.paused;
    } else if (processingState != ProcessingState.completed) {
      buttonNotifier.value = AudioButtonState.playing;
    }

    notifyListeners();
  }

  void _handleTrackCompletion() {
    if (_continuousPlayback) {
      // Handle repeat mode
      switch (repeatModeNotifier.value) {
        case RepeatMode.off:
          if (hasNext()) {
            next();
          } else {
            pause();
          }
          break;
        case RepeatMode.one:
          seek(Duration.zero);
          play();
          break;
        case RepeatMode.all:
          if (hasNext()) {
            next();
          } else {
            // Restart playlist
            _currentIndex = 0;
            _loadAndPlayCurrent();
          }
          break;
      }
    } else {
      pause();
    }
  }

  // ============ PLAYLIST MANAGEMENT ============

  /// Set playlist from ayah list
  Future<void> setPlaylistFromAyahs({
    required List<Ayah> ayahs,
    required int surahNumber,
    required String surahName,
    int startIndex = 0,
  }) async {
    _playlist = ayahs.asMap().entries.map((entry) {
      final ayah = entry.value;
      return PlaylistItem(
        surahNumber: surahNumber,
        surahName: surahName,
        ayahNumber: ayah.number ?? (entry.key + 1),
        ayahText: ayah.text ?? '',
        audioUrl: '', // Will be constructed in _loadAndPlayCurrent
      );
    }).toList();

    _currentIndex = startIndex;
    await _loadAndPlayCurrent();
  }

  /// Play entire surah from beginning
  Future<void> playSurah({
    required List<Ayah> ayahs,
    required int surahNumber,
    required String surahName,
  }) async {
    // Enable continuous playback for surah mode
    _continuousPlayback = true;

    // Set repeat mode to all by default for surah playback
    if (repeatModeNotifier.value == RepeatMode.off) {
      setRepeatMode(RepeatMode.all);
    }

    // Create playlist from all ayahs
    await setPlaylistFromAyahs(
      ayahs: ayahs,
      surahNumber: surahNumber,
      surahName: surahName,
      startIndex: 0,
    );
  }

  /// Add single ayah to playlist
  void addToPlaylist(PlaylistItem item) {
    _playlist.add(item);
    notifyListeners();
  }

  /// Remove from playlist
  void removeFromPlaylist(int index) {
    if (index >= 0 && index < _playlist.length) {
      _playlist.removeAt(index);
      if (_currentIndex >= _playlist.length && _playlist.isNotEmpty) {
        _currentIndex = _playlist.length - 1;
      }
      notifyListeners();
    }
  }

  /// Clear playlist
  void clearPlaylist() {
    _playlist.clear();
    _currentIndex = 0;
    stop();
    notifyListeners();
  }

  /// Reorder playlist
  void reorderPlaylist(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = _playlist.removeAt(oldIndex);
    _playlist.insert(newIndex, item);

    // Update current index if needed
    if (oldIndex == _currentIndex) {
      _currentIndex = newIndex;
    } else if (oldIndex < _currentIndex && newIndex >= _currentIndex) {
      _currentIndex--;
    } else if (oldIndex > _currentIndex && newIndex <= _currentIndex) {
      _currentIndex++;
    }

    notifyListeners();
  }

  // ============ PLAYBACK CONTROL ============

  /// Load and play current track
  Future<void> _loadAndPlayCurrent() async {
    if (_isDisposed) return;
    if (_playlist.isEmpty || _currentIndex >= _playlist.length) return;

    final track = _playlist[_currentIndex];

    try {
      buttonNotifier.value = AudioButtonState.loading;

      // Build audio URL if not provided
      String audioUrl = track.audioUrl;
      if (audioUrl.isEmpty) {
        // Compute global ayah index required by CDN
        final globalIndex =
            _globalAyahIndex(track.surahNumber, track.ayahNumber);
        // High-quality 128 kbps stream; ensure .mp3 extension
        audioUrl =
            'https://cdn.islamic.network/quran/audio/128/$_reciter/$globalIndex.mp3';
      }

      debugPrint(
          'Loading track S${track.surahNumber}:A${track.ayahNumber} -> $audioUrl');

      final ok = await _ensurePlayerAvailable();
      if (!ok) {
        debugPrint('Audio player not available, cannot load track');
        buttonNotifier.value = AudioButtonState.paused;
        _safeNotify();
        return;
      }

      try {
        await _audioPlayer!.setUrl(audioUrl);
      } catch (err) {
        // Retry with AudioSource.uri as a fallback
        debugPrint('setUrl failed, retrying with AudioSource.uri: $err');
        await _audioPlayer!
            .setAudioSource(AudioSource.uri(Uri.parse(audioUrl)));
      }

      await play();

      _safeNotify();
    } catch (e) {
      debugPrint('Error loading track: $e');
      buttonNotifier.value = AudioButtonState.paused;
      _safeNotify();
    }
  }

  /// Play current track
  Future<void> play() async {
    try {
      if (!await _ensurePlayerAvailable()) return;
      await _audioPlayer!.play();
      buttonNotifier.value = AudioButtonState.playing;
    } catch (e) {
      debugPrint('Error playing: $e');
    }
  }

  /// Pause playback
  Future<void> pause() async {
    try {
      if (!await _ensurePlayerAvailable()) return;
      await _audioPlayer!.pause();
      buttonNotifier.value = AudioButtonState.paused;
      _saveListeningProgress();
    } catch (e) {
      debugPrint('Error pausing: $e');
    }
  }

  /// Stop playback
  Future<void> stop() async {
    try {
      if (!await _ensurePlayerAvailable()) return;
      await _audioPlayer!.stop();
      buttonNotifier.value = AudioButtonState.paused;
      progressNotifier.value = ProgressBarState(
        current: Duration.zero,
        buffered: Duration.zero,
        total: Duration.zero,
      );
    } catch (e) {
      debugPrint('Error stopping: $e');
    }
  }

  /// Toggle play/pause
  Future<void> togglePlayPause() async {
    if (buttonNotifier.value == AudioButtonState.playing) {
      await pause();
    } else {
      await play();
    }
  }

  /// Seek to position
  Future<void> seek(Duration position) async {
    try {
      if (!await _ensurePlayerAvailable()) return;
      await _audioPlayer!.seek(position);
    } catch (e) {
      debugPrint('Error seeking: $e');
    }
  }

  /// Skip forward by duration
  Future<void> skipForward(
      [Duration duration = const Duration(seconds: 10)]) async {
    final newPosition = progressNotifier.value.current + duration;
    final maxPosition = progressNotifier.value.total;
    await seek(newPosition > maxPosition ? maxPosition : newPosition);
  }

  /// Skip backward by duration
  Future<void> skipBackward(
      [Duration duration = const Duration(seconds: 10)]) async {
    final newPosition = progressNotifier.value.current - duration;
    await seek(newPosition < Duration.zero ? Duration.zero : newPosition);
  }

  // ============ PLAYLIST NAVIGATION ============

  /// Play next track
  Future<void> next() async {
    if (shuffleNotifier.value) {
      _currentIndex = _getRandomIndex();
    } else {
      _currentIndex++;
      if (_currentIndex >= _playlist.length) {
        _currentIndex = 0;
      }
    }
    await _loadAndPlayCurrent();
  }

  /// Play previous track
  Future<void> previous() async {
    if (progressNotifier.value.current.inSeconds > 3) {
      // If more than 3 seconds into track, restart it
      await seek(Duration.zero);
    } else {
      _currentIndex--;
      if (_currentIndex < 0) {
        _currentIndex = _playlist.length - 1;
      }
      await _loadAndPlayCurrent();
    }
  }

  /// Jump to specific index
  Future<void> jumpToIndex(int index) async {
    if (index >= 0 && index < _playlist.length) {
      _currentIndex = index;
      await _loadAndPlayCurrent();
    }
  }

  /// Check if has next track
  bool hasNext() {
    return _currentIndex < _playlist.length - 1;
  }

  /// Check if has previous track
  bool hasPrevious() {
    return _currentIndex > 0;
  }

  int _getRandomIndex() {
    if (_playlist.length <= 1) return 0;
    int newIndex;
    do {
      newIndex = (DateTime.now().millisecondsSinceEpoch % _playlist.length);
    } while (newIndex == _currentIndex);
    return newIndex;
  }

  // ============ PLAYBACK OPTIONS ============

  /// Set playback speed
  Future<void> setSpeed(double speed) async {
    if (speed < 0.5 || speed > 2.0) return;

    try {
      if (!await _ensurePlayerAvailable()) return;
      await _audioPlayer!.setSpeed(speed);
      speedNotifier.value = speed;

      // Save preference
      final prefs = database.getPreferences();
      prefs.playbackSpeed = speed;
      await database.savePreferences(prefs);

      notifyListeners();
    } catch (e) {
      debugPrint('Error setting speed: $e');
    }
  }

  /// Set repeat mode
  void setRepeatMode(RepeatMode mode) {
    repeatModeNotifier.value = mode;
    notifyListeners();
  }

  /// Toggle repeat mode
  void toggleRepeatMode() {
    final modes = RepeatMode.values;
    final currentIndex = modes.indexOf(repeatModeNotifier.value);
    final nextIndex = (currentIndex + 1) % modes.length;
    setRepeatMode(modes[nextIndex]);
  }

  /// Set shuffle
  void setShuffle(bool shuffle) {
    shuffleNotifier.value = shuffle;
    notifyListeners();
  }

  /// Toggle shuffle
  void toggleShuffle() {
    setShuffle(!shuffleNotifier.value);
  }

  /// Set continuous playback
  void setContinuousPlayback(bool continuous) {
    _continuousPlayback = continuous;
    notifyListeners();
  }

  /// Set reciter
  Future<void> setReciter(String reciter) async {
    _reciter = reciter;

    // Save preference
    final prefs = database.getPreferences();
    prefs.reciter = reciter;
    await database.savePreferences(prefs);

    // Reload current track if playing
    if (buttonNotifier.value == AudioButtonState.playing) {
      final currentPosition = progressNotifier.value.current;
      await _loadAndPlayCurrent();
      await seek(currentPosition);
    }

    notifyListeners();
  }

  // ============ PROGRESS TRACKING ============

  Future<void> _saveListeningProgress() async {
    if (currentTrack == null) return;

    final track = currentTrack!;
    final progress = ListeningProgress(
      surahNumber: track.surahNumber,
      ayahNumber: track.ayahNumber,
      positionMs: progressNotifier.value.current.inMilliseconds,
      lastListenedAt: DateTime.now(),
      reciter: _reciter,
      playbackSpeed: speedNotifier.value,
      completed: progressNotifier.value.current >= progressNotifier.value.total,
    );

    try {
      await database.saveListeningProgress(progress);
    } catch (e) {
      debugPrint('Error saving listening progress: $e');
    }
  }

  /// Resume from saved progress
  Future<void> resumeFromProgress() async {
    try {
      final lastProgress = database.getLastListeningProgress();
      if (lastProgress != null) {
        // Find and load the ayah
        // This would require fetching the surah data
        // Implementation depends on your data structure
        debugPrint(
            'Resuming from ${lastProgress.surahNumber}:${lastProgress.ayahNumber}');
      }
    } catch (e) {
      debugPrint('Error resuming: $e');
    }
  }

  // ============ AUDIO EFFECTS ============

  /// Set volume
  Future<void> setVolume(double volume) async {
    if (volume < 0.0 || volume > 1.0) return;

    try {
      if (!await _ensurePlayerAvailable()) return;
      await _audioPlayer!.setVolume(volume);
      notifyListeners();
    } catch (e) {
      debugPrint('Error setting volume: $e');
    }
  }

  /// Get volume
  double get volume => _audioPlayer?.volume ?? 1.0;

  // ============ STREAM GETTERS ============

  /// Combined duration state stream
  Stream<DurationState> get durationState =>
      rx.Rx.combineLatest2<Duration, PlaybackEvent, DurationState>(
        _audioPlayer?.positionStream ?? Stream.value(Duration.zero),
        _audioPlayer?.playbackEventStream ??
            Stream.value(PlaybackEvent(
                duration: Duration.zero,
                processingState: ProcessingState.idle,
                updatePosition: Duration.zero,
                bufferedPosition: Duration.zero)),
        (position, playbackEvent) => DurationState(
          progress: position,
          buffered: playbackEvent.bufferedPosition,
          total: playbackEvent.duration ?? Duration.zero,
        ),
      );

  @override
  void dispose() {
    _isDisposed = true;
    _audioPlayer?.dispose();
    progressNotifier.dispose();
    buttonNotifier.dispose();
    repeatModeNotifier.dispose();
    shuffleNotifier.dispose();
    speedNotifier.dispose();
    super.dispose();
    // Reduced log noise
    debugPrint('AudioController disposed');
  }

  /// Ensure the player is initialized and available. Returns true if available.
  Future<bool> _ensurePlayerAvailable() async {
    if (_playerAvailable) return true;
    if (_playerInitAttempted && !_playerAvailable) return false;
    await _init();
    return _playerAvailable;
  }
}

// ============ DATA CLASSES ============

class PlaylistItem {
  final int surahNumber;
  final String surahName;
  final int ayahNumber;
  final String ayahText;
  final String audioUrl;

  PlaylistItem({
    required this.surahNumber,
    required this.surahName,
    required this.ayahNumber,
    required this.ayahText,
    this.audioUrl = '',
  });

  String get title => '$surahName - Ayah $ayahNumber';
}

class ProgressBarState {
  final Duration current;
  final Duration buffered;
  final Duration total;

  ProgressBarState({
    required this.current,
    required this.buffered,
    required this.total,
  });

  double get progress {
    if (total.inMilliseconds == 0) return 0.0;
    return current.inMilliseconds / total.inMilliseconds;
  }

  double get bufferedProgress {
    if (total.inMilliseconds == 0) return 0.0;
    return buffered.inMilliseconds / total.inMilliseconds;
  }
}

class DurationState {
  final Duration progress;
  final Duration buffered;
  final Duration total;

  const DurationState({
    required this.progress,
    required this.buffered,
    required this.total,
  });
}

enum AudioButtonState { paused, playing, loading }

enum RepeatMode { off, one, all }
