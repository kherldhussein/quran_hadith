import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:quran_hadith/controller/quranAPI.dart';
import 'package:quran_hadith/database/database_service.dart';
import 'package:quran_hadith/database/hive_adapters.dart';
import 'package:quran_hadith/layout/adaptive.dart';
import 'package:quran_hadith/models/surah_model.dart';
import 'package:quran_hadith/widgets/social_share.dart' as share;
import 'package:scroll_to_index/scroll_to_index.dart';
import 'dart:async';

import '../controller/audio_controller.dart';
import '../controller/favorite.dart';
import '../utils/sp_util.dart';
import 'package:quran_hadith/services/reciter_service.dart';
import 'package:quran_hadith/services/offline_audio_service.dart' as offline;
import 'package:quran_hadith/services/native_desktop_service.dart';
import 'package:quran_hadith/services/playback_state_service.dart';
import 'package:quran_hadith/widgets/quick_jump_dialog.dart';
import 'package:quran_hadith/widgets/reading_mode_sheet.dart';
import 'package:quran_hadith/widgets/split_view_pane.dart';
import 'qpage_view_constants.dart';

class QPageView extends StatefulWidget {
  final List<Ayah>? ayahList;
  final String? suratName;
  final String? suratEnglishName;
  final String? englishMeaning;
  final int? suratNo;
  final bool? isFavorite;

  const QPageView({
    super.key,
    this.ayahList,
    this.suratName,
    this.suratEnglishName,
    this.englishMeaning,
    this.suratNo,
    this.isFavorite,
  });

  @override
  _QPageViewState createState() => _QPageViewState();
}

class _QPageViewState extends State<QPageView>
    with AutomaticKeepAliveClientMixin {
  late final AutoScrollController _scrollController;
  late final AudioController _audioController;
  final Map<int, bool> _favoriteStates = {};
  final Map<int, String> _translations = {};
  bool _isLoadingTranslations = false;
  int? _currentlyPlayingAyah;
  int? _lastVisibleAyah;
  bool _showTranslation = true;
  double _fontSize = 24.0;
  bool _isAudioLoading = false;
  String? _audioError;
  bool _isSurahPlaybackMode = false;
  DateTime? _sessionStartTime;
  Timer? _progressTrackingTimer;
  Timer? _listeningProgressTimer;
  VoidCallback? _reciterListener;
  bool _isOfflineDownloaded = false;
  bool _isProcessingAudioStateChange = false;
  DateTime? _currentAyahPlaybackStart;
  bool _isSplitViewEnabled = false;
  late final AutoScrollController _scrollControllerRight; // For split view right pane
  bool _isScrollingSyncInProgress = false; // Prevent infinite scroll loop

  @override
  void initState() {
    super.initState();
    _scrollController = AutoScrollController();
    _scrollControllerRight = AutoScrollController();
    _setupSynchronizedScrolling();
    _audioController = AudioController();
    _sessionStartTime = DateTime.now();
    _initializeData();
    _startProgressTracking();
    _loadTranslations();
    _setupAudioCompletionListener();
    _setupReciterChangeListener();
    _setupKeyboardShortcuts();
    _checkOfflineStatus();
  }

  /// Setup listener for audio completion to enable continuous playback
  void _setupAudioCompletionListener() {
    _audioController.buttonNotifier.addListener(_onAudioStateChanged);
  }

  /// Listen to reciter changes and restart current ayah with the new voice
  void _setupReciterChangeListener() {
    _reciterListener = () async {
      if (!mounted) return;

      if (_currentlyPlayingAyah == null) return;
      if (_isAudioLoading) {
        return; // Avoid race condition: skip if already loading
      }

      try {
        final ayahNo = _currentlyPlayingAyah!;
        final match = widget.ayahList?.firstWhere(
          (a) => a.number == ayahNo,
          orElse: () => Ayah(),
        );

        if (match == null || match.number == null) return;

        debugPrint(
          '🔄 Reciter changed. Restarting playback of Ayah ${match.number} '
          'with new reciter: ${ReciterService.instance.currentReciterId.value}',
        );

        _audioController.pause();
        _stopListeningProgressTracking();
        await Future.delayed(const Duration(
            milliseconds: 300)); // Brief pause for smooth transition

        if (!mounted || _currentlyPlayingAyah != ayahNo) return;

        await _checkOfflineStatus();

        await _playAyahAudio(match);
      } catch (e) {
        debugPrint('⚠️ Error handling reciter change: $e');
      }
    };
    ReciterService.instance.currentReciterId.addListener(_reciterListener!);
  }

  /// Register keyboard shortcuts for playback control
  void _setupKeyboardShortcuts() {
    try {
      final nativeDesktop = NativeDesktopService();
      nativeDesktop.registerCallbacks(
        onPlayPause: _handlePlayPauseShortcut,
        onNext: _handleNextAyahShortcut,
        onPrevious: _handlePreviousAyahShortcut,
      );
      debugPrint(
          '✅ Keyboard shortcuts registered (Play/Pause, Next, Previous, Jump)');
    } catch (e) {
      debugPrint('⚠️ Error registering keyboard shortcuts: $e');
    }
  }

  /// Show the Quick Jump Dialog for navigating to a specific ayah
  void _showQuickJumpDialog() {
    if (widget.ayahList == null || widget.ayahList!.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) => QuickJumpDialog(
        maxAyahNumber: widget.ayahList!.length,
        onJumpToAyah: (ayahNumber) {
          _scrollToAyah(ayahNumber);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Jumped to Ayah $ayahNumber'),
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        },
        currentAyah: _lastVisibleAyah,
      ),
    );
  }

  /// Handle play/pause keyboard shortcut (Space key)
  void _handlePlayPauseShortcut() {
    if (!mounted || _currentlyPlayingAyah == null) return;

    if (_audioController.buttonNotifier.value == ButtonState.playing) {
      _audioController.pause();
      _stopListeningProgressTracking();
      debugPrint('⏸️ Pause: Keyboard shortcut (Space)');
    } else {
      final currentAyah = widget.ayahList?.firstWhere(
        (a) => a.number == _currentlyPlayingAyah,
        orElse: () => Ayah(),
      );
      if (currentAyah != null && currentAyah.number != null) {
        _playAyahAudio(currentAyah);
        debugPrint('▶️ Play: Keyboard shortcut (Space)');
      }
    }
  }

  /// Handle next ayah keyboard shortcut (Ctrl+Right)
  void _handleNextAyahShortcut() {
    if (!mounted || _currentlyPlayingAyah == null || widget.ayahList == null) {
      return;
    }

    final currentIndex =
        widget.ayahList!.indexWhere((a) => a.number == _currentlyPlayingAyah);

    if (currentIndex != -1 && currentIndex < widget.ayahList!.length - 1) {
      final nextAyah = widget.ayahList![currentIndex + 1];
      _playAyahAudio(nextAyah);
      debugPrint('⏭️ Next Ayah: Keyboard shortcut (Ctrl+Right)');
    }
  }

  /// Handle previous ayah keyboard shortcut (Ctrl+Left)
  void _handlePreviousAyahShortcut() {
    if (!mounted || _currentlyPlayingAyah == null || widget.ayahList == null) {
      return;
    }

    final currentIndex =
        widget.ayahList!.indexWhere((a) => a.number == _currentlyPlayingAyah);

    if (currentIndex > 0) {
      final previousAyah = widget.ayahList![currentIndex - 1];
      _playAyahAudio(previousAyah);
      debugPrint('⏮️ Previous Ayah: Keyboard shortcut (Ctrl+Left)');
    }
  }

  /// Setup synchronized scrolling between left and right panes in split view
  void _setupSynchronizedScrolling() {
    // Listen to left controller (Arabic pane) and sync to right
    _scrollController.addListener(() {
      if (_isScrollingSyncInProgress || !_isSplitViewEnabled) return;
      if (!_scrollController.hasClients || !_scrollControllerRight.hasClients) return;

      _isScrollingSyncInProgress = true;

      // Calculate the visible item index based on scroll offset
      final leftOffset = _scrollController.offset;

      // Sync right controller to match left's position
      if (_scrollControllerRight.hasClients &&
          _scrollControllerRight.offset != leftOffset) {
        _scrollControllerRight.jumpTo(
          leftOffset.clamp(
            _scrollControllerRight.position.minScrollExtent,
            _scrollControllerRight.position.maxScrollExtent,
          ),
        );
      }

      _isScrollingSyncInProgress = false;
    });

    // Listen to right controller (translation pane) and sync to left
    _scrollControllerRight.addListener(() {
      if (_isScrollingSyncInProgress || !_isSplitViewEnabled) return;
      if (!_scrollController.hasClients || !_scrollControllerRight.hasClients) return;

      _isScrollingSyncInProgress = true;

      // Calculate the visible item index based on scroll offset
      final rightOffset = _scrollControllerRight.offset;

      // Sync left controller to match right's position
      if (_scrollController.hasClients &&
          _scrollController.offset != rightOffset) {
        _scrollController.jumpTo(
          rightOffset.clamp(
            _scrollController.position.minScrollExtent,
            _scrollController.position.maxScrollExtent,
          ),
        );
      }

      _isScrollingSyncInProgress = false;
    });

    debugPrint('✅ Synchronized scrolling setup for split view');
  }

  void _onAudioStateChanged() {
    if (_isProcessingAudioStateChange) {
      debugPrint('⚠️ Audio state change already being processed, skipping...');
      return;
    }

    if (_audioController.buttonNotifier.value == ButtonState.paused &&
        !_isAudioLoading) {
      _isProcessingAudioStateChange = true;

      final repeatMode = SpUtil.getRepeatMode();
      final autoPlayNext = SpUtil.getAutoPlayNextAyah();

      if (repeatMode == 'ayah' && _currentlyPlayingAyah != null) {
        final match = widget.ayahList?.firstWhere(
            (a) => a.number == _currentlyPlayingAyah,
            orElse: () => Ayah());
        if (match != null && match.number != null) {
          Future.delayed(AnimationTimings.autoScrollDelay, () {
            if (!mounted) return;
            _isProcessingAudioStateChange = false;
            _playAyahAudio(match);
          });
          return;
        }
      }

      if ((_isSurahPlaybackMode || autoPlayNext) &&
          _currentlyPlayingAyah != null) {
        final currentIndex = widget.ayahList!
            .indexWhere((a) => a.number == _currentlyPlayingAyah);

        if (currentIndex != -1 && currentIndex < widget.ayahList!.length - 1) {
          Future.delayed(AnimationTimings.autoScrollDelay, () {
            if (!mounted) return;
            _isProcessingAudioStateChange = false;
            _playAyahAudio(widget.ayahList![currentIndex + 1]);
          });
        } else if (repeatMode == 'surah' &&
            currentIndex == widget.ayahList!.length - 1) {
          Future.delayed(AnimationTimings.autoScrollDelay, () {
            if (!mounted) return;
            _isProcessingAudioStateChange = false;
            _playAyahAudio(widget.ayahList![0]);
          });
        } else if (_isSurahPlaybackMode) {
          _isSurahPlaybackMode = false;
          _isProcessingAudioStateChange = false;
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Finished playing ${widget.suratEnglishName}',
                ),
                backgroundColor: Theme.of(context).colorScheme.secondary,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        } else {
          _isProcessingAudioStateChange = false;
        }
      } else {
        _isProcessingAudioStateChange = false;
      }
    }
  }

  void _initializeData() async {
    _loadFavoriteStates();
    _loadLastReadPosition();
  }

  /// Check if this surah is downloaded for offline playback
  Future<void> _checkOfflineStatus() async {
    if (widget.suratNo == null || widget.ayahList == null) return;
    final reciterId = ReciterService.instance.currentReciterId.value;
    final downloaded =
        await offline.OfflineAudioService.instance.isSurahDownloaded(
      reciterId: reciterId,
      surahNumber: widget.suratNo!,
      ayahCount: widget.ayahList!.length,
    );
    if (mounted) {
      setState(() => _isOfflineDownloaded = downloaded);
    }
  }

  /// Load translations for this surah
  Future<void> _loadTranslations() async {
    if (widget.suratNo == null) return;

    if (!mounted) return;
    setState(() => _isLoadingTranslations = true);

    try {
      final quranAPI = Provider.of<QuranAPI>(context, listen: false);
      final translations = await quranAPI.getSurahTranslations(
        widget.suratNo!,
        edition: 'en.sahih', // Sahih International translation
      );

      if (!mounted) return;
      setState(() {
        _translations.addAll(translations);
        _isLoadingTranslations = false;
      });
      debugPrint(
          'Loaded ${translations.length} translations for Surah ${widget.suratNo}');
    } catch (e) {
      debugPrint('❌ Error loading translations: $e');
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Failed to load translations. Using Arabic text only.',
            maxLines: 2,
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
          duration: AnimationTimings.translationErrorSnackBarDuration,
          action: SnackBarAction(
            label: 'Retry',
            textColor: Colors.white,
            onPressed: () {
              _loadTranslations();
            },
          ),
        ),
      );

      setState(() => _isLoadingTranslations = false);
    }
  }

  /// Start tracking reading progress
  void _startProgressTracking() {
    _progressTrackingTimer =
        Timer.periodic(AnimationTimings.progressTrackingInterval, (_) {
      _saveReadingProgress();
    });
  }

  /// Start tracking listening progress during audio playback
  void _startListeningProgressTracking() {
    _listeningProgressTimer?.cancel();
    _currentAyahPlaybackStart = DateTime.now();

    _listeningProgressTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (_currentlyPlayingAyah != null &&
          _audioController.buttonNotifier.value == ButtonState.playing) {
        final currentPosition = _audioController.progressNotifier.value.current;
        _saveListeningProgress(_currentlyPlayingAyah!, currentPosition.inMilliseconds);
      }
    });
  }

  /// Stop tracking listening progress
  void _stopListeningProgressTracking() {
    _listeningProgressTimer?.cancel();
    _listeningProgressTimer = null;

    // Save final progress when stopping
    if (_currentlyPlayingAyah != null) {
      final currentPosition = _audioController.progressNotifier.value.current;
      _saveListeningProgress(_currentlyPlayingAyah!, currentPosition.inMilliseconds);
    }
    _currentAyahPlaybackStart = null;
  }

  /// Load last read position for this surah
  Future<void> _loadLastReadPosition() async {
    try {
      final lastProgress = database.getLastReadingProgress();
      if (lastProgress != null &&
          lastProgress.surahNumber == widget.suratNo &&
          lastProgress.ayahNumber > 0) {
        Future.delayed(AnimationTimings.autoScrollDelay, () {
          _scrollToAyah(lastProgress.ayahNumber);
        });
      }
    } catch (e) {
      debugPrint('Error loading last read position: $e');
    }
  }

  /// Save reading progress to database
  Future<void> _saveReadingProgress() async {
    if (_lastVisibleAyah == null || widget.suratNo == null) return;

    try {
      final currentProgress = database.getReadingProgress(
        widget.suratNo!,
        _lastVisibleAyah!,
      );

      final timeSpent = currentProgress?.totalTimeSpentSeconds ?? 0;
      final sessionTime = DateTime.now()
          .difference(_sessionStartTime ?? DateTime.now())
          .inSeconds;

      final progress = ReadingProgress(
        surahNumber: widget.suratNo!,
        ayahNumber: _lastVisibleAyah!,
        lastReadAt: DateTime.now(),
        totalTimeSpentSeconds: timeSpent + sessionTime,
        scrollPosition: 0.0,
      );

      await database.saveReadingProgress(progress);
      _sessionStartTime = DateTime.now(); // Reset session timer

      SpUtil.setLastRead(
        surah: widget.suratNo!,
        ayah: _lastVisibleAyah!,
      );

      debugPrint(
          'Saved reading progress: Surah ${widget.suratNo}, Ayah $_lastVisibleAyah');
    } catch (e) {
      debugPrint('Error saving reading progress: $e');
    }
  }

  Future<void> _loadFavoriteStates() async {
    final favManager = Provider.of<FavoriteManager>(context, listen: false);
    final favorites = await favManager.getFavorites();
    if (widget.ayahList == null) return;

    for (final ayah in widget.ayahList!) {
      if (!mounted) break;
      final isFav =
          favorites.any((fav) => fav.id == '${widget.suratNo}:${ayah.number}');
      _favoriteStates[ayah.number!] = isFav;
    }
    if (!mounted) return;
    setState(() {});
  }

  /// Load and play audio for a specific ayah
  Future<void> _playAyahAudio(Ayah ayah) async {
    if (_isAudioLoading) return;

    setState(() {
      _isAudioLoading = true;
      _audioError = null;
      _currentlyPlayingAyah = ayah.number;
    });

    try {
      final quranAPI = Provider.of<QuranAPI>(context, listen: false);

      final reciterId = ReciterService.instance.currentReciterId.value;
      final localFile =
          await offline.OfflineAudioService.instance.getLocalAyahFile(
        reciterId: reciterId,
        surahNumber: widget.suratNo!,
        ayahNumber: ayah.number!,
      );

      if (localFile != null) {
        await _audioController.setLocalSource(localFile.path);
        await _audioController.setSpeed(SpUtil.getAudioSpeed());
        _audioController.play();

        // Update global playback state
        PlaybackStateService().updatePlayback(
          surahName: widget.suratName ?? '',
          surahEnglishName: widget.suratEnglishName ?? '',
          surahNumber: widget.suratNo ?? 0,
          ayahNumber: ayah.number ?? 0,
          reciter: ReciterService.instance.currentReciterId.value,
        );

        // Update native desktop media controls
        nativeDesktop.updatePlaybackInfo(
          surah: widget.suratEnglishName ?? widget.suratName ?? 'Surah',
          ayah: ayah.number ?? 0,
          reciter: ReciterService.instance.currentReciterId.value,
          isPlaying: true,
          position: Duration.zero,
          duration: const Duration(seconds: 60),
        );
      } else {
        final audioUrl = await quranAPI.getAyahAudioUrl(
          widget.suratNo!,
          ayah.number!,
        );

        if (audioUrl == null || audioUrl.isEmpty) {
          setState(() {
            _audioError = 'Audio not available for this ayah';
            _currentlyPlayingAyah = null;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_audioError!),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }

        await _audioController.setAudioSource(audioUrl);
        await _audioController.setSpeed(SpUtil.getAudioSpeed());
        _audioController.play();

        // Update global playback state
        PlaybackStateService().updatePlayback(
          surahName: widget.suratName ?? '',
          surahEnglishName: widget.suratEnglishName ?? '',
          surahNumber: widget.suratNo ?? 0,
          ayahNumber: ayah.number ?? 0,
          reciter: ReciterService.instance.currentReciterId.value,
        );

        // Update native desktop media controls
        nativeDesktop.updatePlaybackInfo(
          surah: widget.suratEnglishName ?? widget.suratName ?? 'Surah',
          ayah: ayah.number ?? 0,
          reciter: ReciterService.instance.currentReciterId.value,
          isPlaying: true,
          position: Duration.zero,
          duration: const Duration(seconds: 60),
        );
      }

      // Start periodic listening progress tracking
      _startListeningProgressTracking();

      await _saveListeningProgress(ayah.number!, 0);

      SpUtil.setLastListen(
        surah: widget.suratNo!,
        ayah: ayah.number!,
        positionMs: 0,
      );

      if (mounted) {
        Future.delayed(AnimationTimings.autoScrollDelay, () {
          if (mounted) {
            _scrollToAyah(ayah.number!);
          }
        });
      }
    } catch (e) {
      debugPrint("Error playing audio for ayah ${ayah.number}: $e");

      String errorMessage = 'Failed to load audio';
      if (e.toString().contains('invalid parameter')) {
        errorMessage =
            'Audio format not supported. Please try a different reciter in settings.';
      } else if (e.toString().contains('network')) {
        errorMessage = 'Network error. Please check your internet connection.';
      } else if (e.toString().contains('timeout')) {
        errorMessage = 'Connection timeout. Please try again.';
      }

      setState(() {
        _audioError = errorMessage;
        _currentlyPlayingAyah = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_audioError!),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Theme.of(context).colorScheme.onPrimary,
              onPressed: () => _playAyahAudio(ayah),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAudioLoading = false;
        });
      }
    }
  }

  /// Fetch word-by-word timing data for highlighting during recitation
  /// Word-level highlighting disabled: al-quran.cloud API does not provide word-timing data
  /// To implement word highlighting in the future, we would need:
  /// 1. An API that provides word-level timing data (startTime, duration for each word)
  /// 2. Or manually created timing data for each reciter's audio
  /// For now, we show plain text without word-level highlighting

  /// Build Arabic text (plain, without word highlighting)
  Widget _buildArabicTextWithHighlighting(Ayah ayah, ThemeData theme) {
    return Text(
      ayah.text ?? '',
      textAlign: TextAlign.right,
      style: TextStyle(
        fontSize: _fontSize,
        height: 1.8,
        fontFamily: 'Amiri',
        color: theme.colorScheme.onSurface,
      ),
    );
  }

  /// Play the entire surah from the first ayah
  Future<void> _playSurah() async {
    if (widget.ayahList == null || widget.ayahList!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('No ayahs available to play'),
          backgroundColor: Theme.of(context).colorScheme.tertiary,
        ),
      );
      return;
    }

    final shouldPlay = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              FontAwesomeIcons.circlePlay,
              color: Theme.of(context).colorScheme.primary,
              size: 24,
            ),
            const SizedBox(width: 12),
            const Text('Play Surah'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Play entire ${widget.suratEnglishName ?? 'Surah'}?',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'This will play all ${widget.ayahList!.length} ayahs continuously.',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(FontAwesomeIcons.play, size: 16),
            label: const Text('Play'),
          ),
        ],
      ),
    );

    if (shouldPlay != true) return;

    setState(() {
      _isSurahPlaybackMode = true;
    });

    await _playAyahAudio(widget.ayahList!.first);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Playing ${widget.suratEnglishName} - ${widget.ayahList!.length} ayahs',
          ),
          backgroundColor: Theme.of(context).colorScheme.primary,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: 'Stop',
            textColor: Theme.of(context).colorScheme.onPrimary,
            onPressed: () {
              setState(() => _isSurahPlaybackMode = false);
              _audioController.pause();
              _stopListeningProgressTracking();
            },
          ),
        ),
      );
    }
  }

  Future<void> _toggleFavorite(int ayahNumber) async {
    final favManager = Provider.of<FavoriteManager>(context, listen: false);
    final ayahId = '${widget.suratNo}:$ayahNumber';

    setState(() {
      _favoriteStates[ayahNumber] = !(_favoriteStates[ayahNumber] ?? false);
    });

    await favManager.toggleFavorite(
      id: ayahId,
      name: '${widget.suratEnglishName} - Ayah $ayahNumber',
      type: 'ayah',
      metadata: {
        'surah': widget.suratNo,
        'ayah': ayahNumber,
        'surahName': widget.suratName,
      },
    );
  }

  void _scrollToAyah(int ayahNumber) {
    if (!database.getPreferences().autoScroll) {
      debugPrint('⏸️ Auto scroll disabled by user');
      return;
    }

    final index =
        widget.ayahList!.indexWhere((ayah) => ayah.number == ayahNumber);
    if (index != -1) {
      _scrollController.scrollToIndex(
        index,
        duration: AnimationTimings.scrollAnimationDuration,
        preferPosition: AutoScrollPosition.middle,
      );
      _lastVisibleAyah = ayahNumber; // Track visible ayah
      debugPrint('📜 Auto scrolled to Ayah $ayahNumber');
    }
  }

  /// Save listening progress to database with realistic time calculation
  Future<void> _saveListeningProgress(int ayahNumber, int positionMs) async {
    if (widget.suratNo == null) return;

    try {
      final currentProgress = database.getListeningProgress(
        widget.suratNo!,
        ayahNumber,
      );

      int addedListenTime = 0;

      // Calculate time elapsed since playback started for this ayah
      if (_currentAyahPlaybackStart != null) {
        final elapsed = DateTime.now().difference(_currentAyahPlaybackStart!).inSeconds;
        // Add elapsed time, but cap it at a reasonable limit
        addedListenTime = elapsed.clamp(0, 300);

        // Reset the start time for next interval
        _currentAyahPlaybackStart = DateTime.now();
      } else if (currentProgress != null) {
        // Fallback: use position difference
        final previousPosition = currentProgress.positionMs;
        addedListenTime = ((positionMs - previousPosition) ~/ 1000).abs();
        addedListenTime = addedListenTime.clamp(0, 300);
      } else {
        // First time tracking this ayah
        addedListenTime = 5; // Default 5 seconds for initial save
      }

      final previousTotal = currentProgress?.totalListenTimeSeconds ?? 0;
      final newTotalListenTime = previousTotal + addedListenTime;

      final progress = ListeningProgress(
        surahNumber: widget.suratNo!,
        ayahNumber: ayahNumber,
        positionMs: positionMs,
        lastListenedAt: DateTime.now(),
        totalListenTimeSeconds: newTotalListenTime,
        completed: false,
        reciter: ReciterService.instance.currentReciterId.value,
        playbackSpeed: SpUtil.getAudioSpeed(),
      );

      await database.saveListeningProgress(progress);
      debugPrint(
          '⏱️ Listening: Surah ${widget.suratNo}, Ayah $ayahNumber - Added ${addedListenTime}s (Total: ${newTotalListenTime}s)');
    } catch (e) {
      debugPrint('❌ Error saving listening progress: $e');
    }
  }

  void _showAyahOptions(BuildContext context, Ayah ayah) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildAyahOptionsSheet(context, ayah),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (widget.ayahList == null || widget.ayahList!.isEmpty) {
      final theme = Theme.of(context);
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text(widget.suratName ?? 'Surah'),
          backgroundColor: theme.colorScheme.surface,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                FontAwesomeIcons.bookOpen,
                size: 64,
                color: theme.colorScheme.primary.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'No ayahs available',
                style: TextStyle(
                  fontSize: 18,
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final theme = Theme.of(context);
    final isDesktop = isDisplayDesktop(context);

    return ChangeNotifierProvider.value(
      value: _audioController, // Provide the AudioController instance
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        body: Column(
          children: [
            _buildAppBar(theme, isDesktop),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isDesktop) _buildSidebar(theme),
                  Expanded(
                    child: _buildVersesList(theme),
                  ),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: _buildFloatingActionButton(theme),
      ),
    );
  }

  Widget _buildAppBar(ThemeData theme, bool isDesktop) {
    return Container(
      decoration: BoxDecoration(
        color: theme.appBarTheme.backgroundColor,
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.onSurface.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 40 : 20,
        vertical: 16,
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(FontAwesomeIcons.arrowLeft),
            onPressed: () => Get.back(),
            splashRadius: 20,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.suratName ?? '',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                    fontFamily: 'Amiri',
                  ),
                ),
                Text(
                  '${widget.suratEnglishName} • ${widget.englishMeaning}',
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (_isOfflineDownloaded)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Tooltip(
                message: 'Available offline',
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: theme.colorScheme.secondary, width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(FontAwesomeIcons.download,
                          size: 12, color: theme.colorScheme.secondary),
                      const SizedBox(width: 4),
                      Text(
                        'Offline',
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.secondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          IconButton(
            icon: Icon(
              FontAwesomeIcons.circlePlay,
              color: theme.colorScheme.primary,
            ),
            onPressed: _playSurah,
            tooltip: 'Play Entire Surah',
            splashRadius: 20,
          ),
          if (isDesktop)
            IconButton(
              icon: Icon(
                _isSplitViewEnabled
                    ? FontAwesomeIcons.rectangleXmark
                    : FontAwesomeIcons.tableColumns,
                color: theme.colorScheme.primary,
              ),
              onPressed: () {
                setState(() => _isSplitViewEnabled = !_isSplitViewEnabled);
                if (_isSplitViewEnabled) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Split view enabled'),
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              },
              tooltip: _isSplitViewEnabled ? 'Exit Split View' : 'Enable Split View',
              splashRadius: 20,
            ),
          PopupMenuButton<String>(
            icon: Icon(FontAwesomeIcons.gear, color: theme.colorScheme.primary),
            onSelected: (value) => _handleSettingsSelection(value),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'translation',
                child: Row(
                  children: [
                    Icon(
                      _showTranslation
                          ? Icons.visibility
                          : Icons.visibility_off,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    const Text('Translation'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'download_surah',
                child: Row(
                  children: [
                    Icon(FontAwesomeIcons.download, size: 18),
                    SizedBox(width: 12),
                    Text('Download Surah for Offline'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'audio_settings',
                child: Row(
                  children: [
                    Icon(FontAwesomeIcons.sliders, size: 18),
                    SizedBox(width: 12),
                    Text('Audio Settings'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'reading_mode',
                child: Row(
                  children: [
                    Icon(FontAwesomeIcons.bookOpen, size: 18),
                    SizedBox(width: 12),
                    Text('Reading Modes'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'font_small',
                child: Text('Small Font'),
              ),
              const PopupMenuItem(
                value: 'font_medium',
                child: Text('Medium Font'),
              ),
              const PopupMenuItem(
                value: 'font_large',
                child: Text('Large Font'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(ThemeData theme) {
    return Container(
      width: 300,
      margin: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quick Navigation',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildNavigationChip('First', 1, theme),
                      _buildNavigationChip(
                          'Last', widget.ayahList!.length, theme),
                      _buildNavigationChip(
                          'Middle', widget.ayahList!.length ~/ 2, theme),
                      ActionChip(
                        avatar: Icon(FontAwesomeIcons.locationArrow, size: 14, color: theme.colorScheme.secondary),
                        label: const Text('Jump to Ayah'),
                        onPressed: _showQuickJumpDialog,
                        backgroundColor: theme.colorScheme.secondary.withOpacity(0.1),
                        labelStyle: TextStyle(color: theme.colorScheme.secondary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Consumer<FavoriteManager>(
            builder: (context, favManager, child) {
              return FutureBuilder<List<String>>(
                future: favManager
                    .getFavorites()
                    .then((list) => list.map((f) => f.id).toList()),
                builder: (context, snapshot) {
                  final favorites = snapshot.data ?? [];
                  final pinnedAyahs = favorites
                      .where((id) => id.startsWith('${widget.suratNo}:'))
                      .toList();

                  if (pinnedAyahs.isEmpty) {
                    return Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  FontAwesomeIcons.mapPin,
                                  size: 16,
                                  color: theme.colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Pinned Ayahs',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Pin important verses to easily find them later',
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.colorScheme.onSurface
                                    .withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                FontAwesomeIcons.mapPin,
                                size: 16,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Pinned Ayahs',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '${pinnedAyahs.length}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ...pinnedAyahs.take(5).map((id) {
                            final ayahNum = int.parse(id.split(':')[1]);
                            return ListTile(
                              dense: true,
                              leading: Icon(
                                FontAwesomeIcons.mapPin,
                                size: 14,
                                color: theme.colorScheme.primary,
                              ),
                              title: Text('Ayah $ayahNum'),
                              trailing: Icon(
                                FontAwesomeIcons.chevronRight,
                                size: 12,
                                color: theme.colorScheme.onSurface
                                    .withOpacity(0.3),
                              ),
                              onTap: () => _scrollToAyah(ayahNum),
                            );
                          }),
                          if (pinnedAyahs.length > 5) ...[
                            const SizedBox(height: 8),
                            Center(
                              child: TextButton(
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Total pinned: ${pinnedAyahs.length} ayahs',
                                      ),
                                    ),
                                  );
                                },
                                child: Text(
                                  'View all (${pinnedAyahs.length} total)',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationChip(String label, int ayahNumber, ThemeData theme) {
    return ActionChip(
      label: Text(label),
      onPressed: () => _scrollToAyah(ayahNumber),
      backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
      labelStyle: TextStyle(color: theme.colorScheme.primary),
    );
  }

  Widget _buildVersesList(ThemeData theme) {
    // Check if split view is enabled
    if (_isSplitViewEnabled) {
      return Container(
        margin: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.onSurface.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: SplitViewPane(
          leftChild: _buildArabicOnlyList(theme),
          rightChild: _buildTranslationOnlyList(theme),
          initialRatio: 0.5,
        ),
      );
    }

    // Regular single-pane view
    return Container(
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.onSurface.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: NotificationListener<ScrollNotification>(
        onNotification: (scrollNotification) {
          if (scrollNotification is ScrollUpdateNotification &&
              scrollNotification.metrics.axis == Axis.vertical) {
            final approximateIndex = (_scrollController.offset / 100)
                .round()
                .clamp(0, widget.ayahList!.length - 1);
            if (approximateIndex >= 0 &&
                approximateIndex < widget.ayahList!.length) {
              _lastVisibleAyah = widget.ayahList![approximateIndex].number;
            }
          }
          return true;
        },
        child: ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(0),
          itemCount: widget.ayahList!.length,
          itemBuilder: (context, index) {
            return AutoScrollTag(
              key: ValueKey(index),
              controller: _scrollController,
              index: index,
              child: _buildAyahCard(widget.ayahList![index], theme, index),
            );
          },
        ),
      ),
    );
  }

  // Build Arabic-only list for split view (left pane)
  Widget _buildArabicOnlyList(ThemeData theme) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: widget.ayahList!.length,
      itemBuilder: (context, index) {
        final ayah = widget.ayahList![index];
        return AutoScrollTag(
          key: ValueKey('arabic_$index'),
          controller: _scrollController,
          index: index,
          child: Card(
            elevation: 0,
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    _formatAyahNumber(ayah.number ?? 0),
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    ayah.text ?? '',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: _fontSize,
                      height: 1.8,
                      fontFamily: 'Amiri',
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Build translation-only list for split view (right pane)
  Widget _buildTranslationOnlyList(ThemeData theme) {
    return ListView.builder(
      controller: _scrollControllerRight,
      padding: const EdgeInsets.all(16),
      itemCount: widget.ayahList!.length,
      itemBuilder: (context, index) {
        final ayah = widget.ayahList![index];
        return AutoScrollTag(
          key: ValueKey('translation_$index'),
          controller: _scrollControllerRight,
          index: index,
          child: Card(
            elevation: 0,
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Ayah ${ayah.number}',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _isLoadingTranslations
                      ? const Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : Text(
                          _translations[ayah.number] ??
                              'Translation not available',
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.6,
                            color: theme.colorScheme.onSurface.withOpacity(0.8),
                          ),
                        ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAyahCard(Ayah ayah, ThemeData theme, int index) {
    final isPlaying = _currentlyPlayingAyah == ayah.number;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isPlaying
              ? theme.colorScheme.primary
              : theme.dividerColor.withOpacity(0.1),
          width: isPlaying ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: () => _showAyahOptions(context, ayah),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _formatAyahNumber(ayah.number ?? 0),
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        fontFamily: 'Amiri',
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      _favoriteStates[ayah.number!] ?? false
                          ? FontAwesomeIcons.solidStar
                          : FontAwesomeIcons.star,
                      color: _favoriteStates[ayah.number!] ?? false
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface.withOpacity(0.5),
                      size: 16,
                    ),
                    tooltip: _favoriteStates[ayah.number!] ?? false
                        ? 'Important ayah'
                        : 'Mark as important',
                    onPressed: () => _toggleFavorite(ayah.number!),
                    splashRadius: 16,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildArabicTextWithHighlighting(ayah, theme),
              const SizedBox(height: 16),
              if (_showTranslation) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest
                        .withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _isLoadingTranslations
                      ? const Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : Text(
                          _translations[ayah.number] ??
                              'Translation not available',
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.6,
                            color: theme.colorScheme.onSurface.withOpacity(0.8),
                          ),
                        ),
                ),
                const SizedBox(height: 16),
              ],
              _buildAyahActions(ayah, theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAyahActions(Ayah ayah, ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildAudioControl(ayah, theme),
        IconButton(
          icon: const Icon(FontAwesomeIcons.shareNodes, size: 18),
          onPressed: () => share.showShareDialog(
            context: context,
            text: ayah.text!,
          ),
          tooltip: 'Share',
        ),
        IconButton(
          icon: const Icon(FontAwesomeIcons.copy, size: 18),
          onPressed: () {
            Clipboard.setData(ClipboardData(text: ayah.text!));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Ayah copied to clipboard'),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            );
          },
          tooltip: 'Copy',
        ),
        IconButton(
          icon: Icon(
            _favoriteStates[ayah.number!] ?? false
                ? FontAwesomeIcons.bookmark
                : FontAwesomeIcons.solidBookmark,
            size: 18,
          ),
          onPressed: () => _toggleFavorite(ayah.number!),
          tooltip: 'Bookmark',
        ),
      ],
    );
  }

  Widget _buildAudioControl(Ayah ayah, ThemeData theme) {
    return ValueListenableBuilder<ButtonState>(
      valueListenable: _audioController.buttonNotifier,
      builder: (_, value, __) {
        final isThisAyahPlaying = _currentlyPlayingAyah == ayah.number;

        switch (value) {
          case ButtonState.loading when isThisAyahPlaying:
            return SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
              ),
            );
          case ButtonState.paused:
            return IconButton(
              icon: const Icon(FontAwesomeIcons.play, size: 18),
              color: theme.colorScheme.primary,
              onPressed: () => _playAyahAudio(ayah),
              tooltip: 'Play',
            );
          case ButtonState.playing when isThisAyahPlaying:
            return IconButton(
              icon: const Icon(FontAwesomeIcons.pause, size: 18),
              color: theme.colorScheme.primary,
              onPressed: () {
                _audioController.pause();
                _stopListeningProgressTracking();
                setState(() => _currentlyPlayingAyah = null);
              },
              tooltip: 'Pause',
            );
          default:
            return IconButton(
              icon: const Icon(FontAwesomeIcons.play, size: 18),
              color: theme.colorScheme.onSurface.withOpacity(0.5),
              onPressed: () => _playAyahAudio(ayah),
              tooltip: 'Play',
            );
        }
      },
    );
  }

  Widget _buildAyahOptionsSheet(BuildContext context, Ayah ayah) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Theme.of(context).dividerColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Ayah ${ayah.number}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildOptionChip(
                icon: FontAwesomeIcons.heart,
                label: 'Favorite',
                onTap: () => _toggleFavorite(ayah.number!),
                color: Theme.of(context).colorScheme.secondary,
              ),
              _buildOptionChip(
                icon: FontAwesomeIcons.shareNodes,
                label: 'Share',
                onTap: () =>
                    share.showShareDialog(context: context, text: ayah.text!),
                color: Theme.of(context).colorScheme.primary,
              ),
              _buildOptionChip(
                icon: FontAwesomeIcons.copy,
                label: 'Copy',
                onTap: () {
                  Clipboard.setData(ClipboardData(text: ayah.text!));
                  Get.back();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Copied to clipboard')),
                  );
                },
                color: Theme.of(context).colorScheme.secondary,
              ),
              _buildOptionChip(
                icon: FontAwesomeIcons.bookOpen,
                label: 'Study',
                onTap: () {
                  Get.back();
                },
                color: Theme.of(context).colorScheme.tertiary,
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildOptionChip({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
  }) {
    return ActionChip(
      avatar: Icon(icon, size: 16, color: color),
      label: Text(label),
      onPressed: onTap,
      backgroundColor: color.withOpacity(0.1),
      labelStyle: TextStyle(color: color),
    );
  }

  Widget _buildFloatingActionButton(ThemeData theme) {
    final isDesktop = isDisplayDesktop(context);

    // On desktop, show scroll to top button
    // On mobile, show quick jump button for better accessibility
    if (isDesktop) {
      return FloatingActionButton(
        onPressed: () => _scrollToAyah(1),
        backgroundColor: theme.colorScheme.primary,
        tooltip: 'Scroll to top',
        child: Icon(FontAwesomeIcons.arrowUp, color: theme.colorScheme.onPrimary),
      );
    } else {
      return FloatingActionButton.extended(
        onPressed: _showQuickJumpDialog,
        backgroundColor: theme.colorScheme.secondary,
        icon: const Icon(FontAwesomeIcons.locationArrow),
        label: const Text('Jump'),
        tooltip: 'Jump to Ayah',
      );
    }
  }

  void _handleSettingsSelection(String value) {
    switch (value) {
      case 'translation':
        setState(() => _showTranslation = !_showTranslation);
        break;
      case 'download_surah':
        _promptDownloadSurah();
        break;
      case 'audio_settings':
        _showAudioSettingsBottomSheet();
        break;
      case 'reading_mode':
        _showReadingModeBottomSheet();
        break;
      case 'font_small':
        setState(() => _fontSize = 20.0);
        break;
      case 'font_medium':
        setState(() => _fontSize = 24.0);
        break;
      case 'font_large':
        setState(() => _fontSize = 28.0);
        break;
    }
  }

  void _showReadingModeBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const ReadingModeSheet(),
    );
  }

  Future<void> _promptDownloadSurah() async {
    if (widget.suratNo == null || widget.ayahList == null) return;
    final reciterId = ReciterService.instance.currentReciterId.value;
    final ayahCount = widget.ayahList!.length;

    final already =
        await offline.OfflineAudioService.instance.isSurahDownloaded(
      reciterId: reciterId,
      surahNumber: widget.suratNo!,
      ayahCount: ayahCount,
    );

    final action = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Offline Audio'),
        content: Text(
          already
              ? 'Offline audio is already available for ${widget.suratEnglishName} with $reciterId.'
              : 'Download ${widget.suratEnglishName} ($ayahCount ayahs) for offline playback with $reciterId?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'cancel'),
            child: const Text('Close'),
          ),
          if (already)
            TextButton(
              onPressed: () async {
                await offline.OfflineAudioService.instance.removeSurah(
                  reciterId: reciterId,
                  surahNumber: widget.suratNo!,
                );
                if (mounted) Navigator.pop(context, 'removed');
              },
              child: const Text('Remove'),
            ),
          FilledButton(
            onPressed: () => Navigator.pop(context, 'download'),
            child: Text(already ? 'Re-download' : 'Download'),
          ),
        ],
      ),
    );

    if (action == 'removed') {
      if (!mounted) return;
      await _checkOfflineStatus(); // Refresh offline status
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Removed offline audio for ${widget.suratEnglishName}'),
        ),
      );
      return;
    }
    if (action != 'download') return;

    final cancelToken = offline.CancelToken();
    final downloadedVN = ValueNotifier<int>(0);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ValueListenableBuilder<int>(
        valueListenable: downloadedVN,
        builder: (context, downloaded, _) {
          final progress = ayahCount == 0 ? 0.0 : downloaded / ayahCount;
          return AlertDialog(
            title: const Text('Downloading Surah'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                LinearProgressIndicator(value: progress.clamp(0.0, 1.0)),
                const SizedBox(height: 12),
                Text('Downloaded $downloaded / $ayahCount ayahs'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  cancelToken.cancel();
                  Navigator.pop(context);
                },
                child: const Text('Cancel'),
              ),
            ],
          );
        },
      ),
    );

    await offline.OfflineAudioService.instance.downloadSurah(
      reciterId: reciterId,
      surahNumber: widget.suratNo!,
      ayahCount: ayahCount,
      onProgress: (d, t) => downloadedVN.value = d,
      cancelToken: cancelToken,
    );

    if (mounted) {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      await _checkOfflineStatus(); // Refresh offline status
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Downloaded ${widget.suratEnglishName} for offline'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _showAudioSettingsBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        double speed = SpUtil.getAudioSpeed();
        bool autoPlayNext = SpUtil.getAutoPlayNextAyah();
        String repeatMode = SpUtil.getRepeatMode();

        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(FontAwesomeIcons.sliders),
                      SizedBox(width: 8),
                      Text('Audio Settings',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text('Playback speed: ${speed.toStringAsFixed(2)}x'),
                  Slider(
                    value: speed,
                    min: 0.5,
                    max: 2.0,
                    divisions: 15,
                    label: '${speed.toStringAsFixed(2)}x',
                    onChanged: (v) {
                      setState(() => speed = v);
                      SpUtil.setAudioSpeed(v);
                      if (_currentlyPlayingAyah != null) {
                        _audioController.setSpeed(v);
                      }
                    },
                  ),
                  const Divider(),
                  SwitchListTile(
                    title: const Text('Auto-play next ayah'),
                    subtitle: const Text(
                        'Automatically play next ayah after current finishes'),
                    value: autoPlayNext,
                    onChanged: (v) {
                      setState(() => autoPlayNext = v);
                      SpUtil.setAutoPlayNextAyah(v);
                    },
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 8),
                  const Text('Repeat Mode',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('None'),
                        selected: repeatMode == 'none',
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => repeatMode = 'none');
                            SpUtil.setRepeatMode('none');
                          }
                        },
                      ),
                      ChoiceChip(
                        label: const Text('Repeat Ayah'),
                        selected: repeatMode == 'ayah',
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => repeatMode = 'ayah');
                            SpUtil.setRepeatMode('ayah');
                          }
                        },
                      ),
                      ChoiceChip(
                        label: const Text('Repeat Surah'),
                        selected: repeatMode == 'surah',
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => repeatMode = 'surah');
                            SpUtil.setRepeatMode('surah');
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () {
                          setState(() {
                            speed = 1.0;
                            autoPlayNext = false;
                            repeatMode = 'none';
                          });
                          SpUtil.setAudioSpeed(1.0);
                          SpUtil.setAutoPlayNextAyah(false);
                          SpUtil.setRepeatMode('none');
                          if (_currentlyPlayingAyah != null) {
                            _audioController.setSpeed(1.0);
                          }
                        },
                        child: const Text('Reset All'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Done'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _formatAyahNumber(int number) {
    const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const arabic = ['۰', '۱', '۲', '۳', '٤', '٥', '٦', '۷', '۸', '۹'];
    String input = number.toString();
    for (int i = 0; i < english.length; i++) {
      input = input.replaceAll(english[i], arabic[i]);
    }
    return input;
  }

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _progressTrackingTimer?.cancel();
    _listeningProgressTimer?.cancel();
    _audioController.buttonNotifier.removeListener(_onAudioStateChanged);
    if (_reciterListener != null) {
      ReciterService.instance.currentReciterId
          .removeListener(_reciterListener!);
    }
    _saveReadingProgress();
    _stopListeningProgressTracking();
    _scrollController.dispose();
    _scrollControllerRight.dispose();
    // Don't dispose the singleton AudioController - it persists across navigation
    super.dispose();
  }
}
