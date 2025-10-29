import 'package:flutter/material.dart';
import 'package:quran_hadith/controller/enhanced_audio_controller.dart';
import 'package:quran_hadith/services/native_desktop_service.dart';
import 'package:quran_hadith/services/error_service.dart'; // Import the error service

/// Bridge between EnhancedAudioController and NativeDesktopService
/// Handles media control callbacks and state synchronization
class AudioNativeDesktopBridge {
  static final AudioNativeDesktopBridge _instance =
      AudioNativeDesktopBridge._internal();

  factory AudioNativeDesktopBridge() => _instance;
  AudioNativeDesktopBridge._internal();

  bool _isInitialized = false;
  EnhancedAudioController? _audioController;
  final _nativeDesktop = NativeDesktopService();

  /// Initialize the bridge with audio controller
  Future<void> initialize(EnhancedAudioController audioController) async {
    if (_isInitialized) return;

    try {
      _audioController = audioController;

      // Register callbacks with native desktop service
      _nativeDesktop.registerCallbacks(
        onPlayPause: _handlePlayPause,
        onNext: _handleNextAyah,
        onPrevious: _handlePreviousAyah,
        onShowWindow: _handleShowWindow,
        onQuit: _handleQuit,
        onSearch: _handleSearch,
      );

      // Listen to audio controller state changes
      _audioController?.addListener(_onAudioStateChanged);

      _isInitialized = true;
      debugPrint('✅ AudioNativeDesktopBridge initialized');
    } catch (e, s) {
      errorService.reportError('Error initializing AudioNativeDesktopBridge: $e', s);
    }
  }

  /// Handle play/pause from system tray or media keys
  void _handlePlayPause() {
    try {
      final isPlaying = _audioController?.isPlaying ?? false;
      if (isPlaying) {
        _audioController?.pause().catchError((e, s) {
          errorService.reportError('Error pausing audio: $e', s);
        });
      } else {
        _audioController?.play().catchError((e, s) {
          errorService.reportError('Error playing audio: $e', s);
        });
      }
      debugPrint('▶️ Play/Pause triggered via system controls');
    } catch (e, s) {
      errorService.reportError('Error handling play/pause: $e', s);
    }
  }

  /// Handle next ayah from system controls
  void _handleNextAyah() {
    try {
      _audioController?.nextAyah();
      debugPrint('⏭️ Next Ayah triggered via system controls');
    } catch (e, s) {
      errorService.reportError('Error handling next ayah: $e', s);
    }
  }

  /// Handle previous ayah from system controls
  void _handlePreviousAyah() {
    try {
      _audioController?.previousAyah();
      debugPrint('⏮️ Previous Ayah triggered via system controls');
    } catch (e, s) {
      errorService.reportError('Error handling previous ayah: $e', s);
    }
  }

  /// Handle show window request
  void _handleShowWindow() {
    debugPrint('🪟 Show window requested via system tray');
    // This is handled by the system tray manager
  }

  /// Handle quit request
  void _handleQuit() {
    debugPrint('❌ Quit requested via system tray');
    // This is handled by the system tray manager
  }

  /// Handle search request
  void _handleSearch() {
    debugPrint('🔍 Search requested via hotkey');
    // This would need to be wired to the search UI
  }

  /// Listen to audio controller state changes and update native controls
  void _onAudioStateChanged() {
    try {
      if (_audioController == null) return;

      // Update media metadata when playing
      if (_audioController!.isPlaying) {
        _updateMediaMetadata();
      }

      // Update playback state
      _updatePlaybackState();

      // Update system tray context menu
      _updateSystemTrayMenu();
    } catch (e, s) {
      errorService.reportError('Error updating native desktop from audio state: $e', s);
    }
  }

  /// Update media metadata in system controls
  void _updateMediaMetadata() {
    try {
      final currentSurah = _audioController?.currentSurah;
      final currentAyah = _audioController?.currentAyah ?? 0;
      final reciterName = _audioController?.currentReciterName ?? 'Unknown';

      if (currentSurah != null) {
        _nativeDesktop.updateMediaMetadata(
          surah: currentSurah.englishName ?? currentSurah.name!,
          ayah: currentAyah,
          reciter: reciterName,
          imageUrl: null,
        );
        debugPrint(
          '🎵 Media metadata updated: ${currentSurah.englishName} - Ayah $currentAyah',
        );
      }
    } catch (e, s) {
      errorService.reportError('Error updating media metadata: $e', s);
    }
  }

  /// Update playback state in system controls
  void _updatePlaybackState() {
    try {
      final isPlaying = _audioController?.isPlaying ?? false;
      final duration = _audioController?.duration ?? Duration.zero;
      final position = _audioController?.position ?? Duration.zero;

      _nativeDesktop.updatePlaybackState(
        isPlaying: isPlaying,
        position: position,
        duration: duration,
      );

      debugPrint(
        '⏱️ Playback state updated: ${isPlaying ? "Playing" : "Paused"} - $position / $duration',
      );
    } catch (e, s) {
      errorService.reportError('Error updating playback state: $e', s);
    }
  }

  /// Update system tray context menu based on playback state
  void _updateSystemTrayMenu() {
    try {
      final isPlaying = _audioController?.isPlaying ?? false;
      // System tray menu will be updated automatically based on playback state
      debugPrint(
        '📋 System tray menu context: ${isPlaying ? "Now Playing" : "Paused"}',
      );
    } catch (e, s) {
      errorService.reportError('Error updating system tray menu: $e', s);
    }
  }

  /// Dispose the bridge
  void dispose() {
    try {
      _audioController?.removeListener(_onAudioStateChanged);
      _isInitialized = false;
      debugPrint('AudioNativeDesktopBridge disposed');
    } catch (e, s) {
      errorService.reportError('Error disposing AudioNativeDesktopBridge: $e', s);
    }
  }
}
