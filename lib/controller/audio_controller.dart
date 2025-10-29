import 'dart:io';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

/// AudioController now performs lazy initialization of the media Player.
/// This prevents any media_kit API from being called before the platform
/// backend is available (for example when libmpv is not installed on Linux).

class AudioController extends ChangeNotifier {
  // Singleton pattern
  static final AudioController _instance = AudioController._internal();
  factory AudioController() => _instance;
  AudioController._internal();

  late final progressNotifier = ValueNotifier<ProgressBarState>(
    ProgressBarState(
      current: Duration.zero,
      buffered: Duration.zero,
      total: Duration.zero,
    ),
  );
  final buttonNotifier = ValueNotifier<ButtonState>(ButtonState.paused);

  Player? _player;
  bool _isDisposed = false;
  bool _playerInitAttempted = false;
  bool _playerAvailable = false;

  Future<void> _init() async {
    if (_playerInitAttempted) return;
    _playerInitAttempted = true;

    try {
      _player = Player();
      _playerAvailable = true;

      _player!.stream.playing.listen((bool playing) {
        if (_isDisposed) return;
        if (playing) {
          buttonNotifier.value = ButtonState.playing;
        } else {
          buttonNotifier.value = ButtonState.paused;
        }
      });

      _player!.stream.buffering.listen((bool buffering) {
        if (_isDisposed) return;
        if (buffering) {
          buttonNotifier.value = ButtonState.loading;
        }
      });

      _player!.stream.position.listen((Duration position) {
        if (_isDisposed) return;
        final oldState = progressNotifier.value;
        progressNotifier.value = ProgressBarState(
          current: position,
          buffered: oldState.buffered,
          total: oldState.total,
        );
      });

      _player!.stream.buffer.listen((Duration buffer) {
        if (_isDisposed) return;
        final oldState = progressNotifier.value;
        progressNotifier.value = ProgressBarState(
          current: oldState.current,
          buffered: buffer,
          total: oldState.total,
        );
      });

      _player!.stream.duration.listen((Duration duration) {
        if (_isDisposed) return;
        final oldState = progressNotifier.value;
        progressNotifier.value = ProgressBarState(
          current: oldState.current,
          buffered: oldState.buffered,
          total: duration,
        );
      });

      _player!.stream.completed.listen((bool completed) {
        if (_isDisposed) return;
        if (completed) {
          _player!.seek(Duration.zero);
          _player!.pause();
          buttonNotifier.value = ButtonState.paused;
        }
      });
    } catch (e) {
      debugPrint('AudioController: Player init failed: $e');
      _playerAvailable = false;
    }
  }

  /// Helper to get or create audio cache directory
  Future<Directory> _getAudioCacheDir() async {
    final tempDir = await getTemporaryDirectory();
    final cacheDir = Directory('${tempDir.path}/audio_cache');
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }
    return cacheDir;
  }

  /// Helper to get cached audio file name from URL
  String _getCacheFileName(String url) {
    final uri = Uri.parse(url);
    final fileName = uri.pathSegments.last;
    return fileName;
  }

  /// Download audio file and cache it locally
  Future<File> _downloadAndCacheAudio(String url) async {
    final cacheDir = await _getAudioCacheDir();
    final fileName = _getCacheFileName(url);
    final cachedFile = File('${cacheDir.path}/$fileName');

    if (await cachedFile.exists()) {
      final fileSize = await cachedFile.length();
      if (fileSize > 1000) {
        debugPrint(
            "AudioController: Using cached audio file: ${cachedFile.path}");
        return cachedFile;
      }
    }

    debugPrint("AudioController: Downloading audio from: $url");
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'User-Agent': 'QuranHadithApp/1.0',
      },
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      await cachedFile.writeAsBytes(response.bodyBytes);
      debugPrint(
          "AudioController: Audio downloaded and cached: ${cachedFile.path} (${response.bodyBytes.length} bytes)");
      return cachedFile;
    } else {
      throw Exception("Failed to download audio: HTTP ${response.statusCode}");
    }
  }

  /// Set audio source and prepare for playback (remote URL with temp cache)
  Future<void> setAudioSource(String url) async {
    if (_isDisposed) return;
    if (url.isEmpty) {
      debugPrint("AudioController: Attempted to set empty audio URL.");
      return;
    }
    await _init();

    if (!_playerAvailable || _player == null) {
      debugPrint(
          'AudioController: Player not available. Skipping setAudioSource.');
      throw Exception(
          'Audio backend is not available on this platform (libmpv missing?).');
    }

    try {
      buttonNotifier.value = ButtonState.loading;
      debugPrint("AudioController: Setting audio source: $url");

      try {
        await _player!.stop();
      } catch (e) {
        debugPrint("Error stopping player: $e");
      }

      final audioFile = await _downloadAndCacheAudio(url);

      await _player!.open(Media(audioFile.path));

      debugPrint(
          "AudioController: Audio source set from local file: ${audioFile.path}");
      buttonNotifier.value = ButtonState.paused;
    } catch (e, stackTrace) {
      debugPrint("Error setting audio source: $e");
      debugPrint("Stack trace: $stackTrace");

      try {
        debugPrint(
            "AudioController: Fallback - trying to play from URL directly...");
        await _player!.open(Media(url));
        debugPrint("AudioController: Audio source set from URL");
        buttonNotifier.value = ButtonState.paused;
      } catch (e2) {
        debugPrint("Error with URL source: $e2");
        buttonNotifier.value = ButtonState.paused;
        rethrow;
      }
    }
  }

  /// Set local audio source directly (no network/caching)
  Future<void> setLocalSource(String filePath) async {
    if (_isDisposed) return;
    await _init();
    if (!_playerAvailable || _player == null) {
      throw Exception(
          'Audio backend is not available on this platform (libmpv missing?).');
    }
    try {
      buttonNotifier.value = ButtonState.loading;
      try {
        await _player!.stop();
      } catch (_) {}
      await _player!.open(Media(filePath));
      buttonNotifier.value = ButtonState.paused;
      debugPrint('AudioController: Local source set: $filePath');
    } catch (e) {
      debugPrint('AudioController: Failed to set local source: $e');
      rethrow;
    }
  }

  void play() async {
    if (_isDisposed) return;
    if (!_playerAvailable || _player == null) {
      debugPrint('AudioController: play() called but player unavailable.');
      return;
    }

    try {
      await _player!.play();
    } catch (e) {
      debugPrint("Error playing audio: $e");
    }
  }

  void pause() async {
    if (_isDisposed) return;
    if (!_playerAvailable || _player == null) {
      debugPrint('AudioController: pause() called but player unavailable.');
      return;
    }

    try {
      await _player!.pause();
    } catch (e) {
      debugPrint("Error pausing audio: $e");
    }
  }

  void seek(Duration position) async {
    if (_isDisposed) return;
    if (!_playerAvailable || _player == null) {
      debugPrint('AudioController: seek() called but player unavailable.');
      return;
    }

    try {
      await _player!.seek(position);
    } catch (e) {
      debugPrint("Error seeking audio: $e");
    }
  }

  /// Set playback speed (rate). 1.0 = normal, 0.5 = half-speed, 2.0 = double-speed.
  Future<void> setSpeed(double speed) async {
    if (_isDisposed) return;
    await _init();
    if (!_playerAvailable || _player == null) {
      debugPrint('AudioController: setSpeed() called but player unavailable.');
      return;
    }
    try {
      await _player!.setRate(speed);
      debugPrint('AudioController: Playback speed set to $speed');
    } catch (e) {
      debugPrint('AudioController: Failed to set speed: $e');
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    try {
      _player?.dispose();
    } catch (e) {
      debugPrint('Error disposing player: $e');
    }
    progressNotifier.dispose();
    buttonNotifier.dispose();
    super.dispose();
    debugPrint('AudioController disposed');
  }
}

class ProgressBarState {
  ProgressBarState({
    required this.current,
    required this.buffered,
    required this.total,
  });

  final Duration current;
  final Duration buffered;
  final Duration total;
}

enum ButtonState { paused, playing, loading }
