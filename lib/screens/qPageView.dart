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
import 'package:quran_hadith/services/offline_audio_service.dart';

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
  VoidCallback? _reciterListener;
  bool _isOfflineDownloaded = false;

  @override
  void initState() {
    super.initState();
    _scrollController = AutoScrollController();
    _audioController = AudioController();
    _sessionStartTime = DateTime.now();
    _initializeData();
    _startProgressTracking();
    _loadTranslations();
    _setupAudioCompletionListener();
    _setupReciterChangeListener();
    _checkOfflineStatus();
  }

  /// Setup listener for audio completion to enable continuous playback
  void _setupAudioCompletionListener() {
    // Listen to button state changes to detect when audio completes
    _audioController.buttonNotifier.addListener(_onAudioStateChanged);
  }

  /// Listen to reciter changes and restart current ayah with the new voice
  void _setupReciterChangeListener() {
    _reciterListener = () {
      if (!mounted) return;
      if (_currentlyPlayingAyah != null && !_isAudioLoading) {
        final ayahNo = _currentlyPlayingAyah!;
        final match = widget.ayahList!
            .firstWhere((a) => a.number == ayahNo, orElse: () => Ayah());
        if (match.number != null) {
          // Restart playback of the same ayah using the new reciter
          _playAyahAudio(match);
        }
      }
    };
    ReciterService.instance.currentReciterId.addListener(_reciterListener!);
  }

  void _onAudioStateChanged() {
    // Check if audio just finished
    if (_audioController.buttonNotifier.value == ButtonState.paused &&
        !_isAudioLoading) {
      final repeatMode = SpUtil.getRepeatMode();
      final autoPlayNext = SpUtil.getAutoPlayNextAyah();

      // Handle repeat mode for single ayah
      if (repeatMode == 'ayah' && _currentlyPlayingAyah != null) {
        final match = widget.ayahList!.firstWhere(
            (a) => a.number == _currentlyPlayingAyah,
            orElse: () => Ayah());
        if (match.number != null) {
          Future.delayed(const Duration(milliseconds: 500), () {
            if (!mounted) return;
            _playAyahAudio(match);
          });
          return;
        }
      }

      // Check if we're in surah playback mode or auto-play is enabled
      if ((_isSurahPlaybackMode || autoPlayNext) &&
          _currentlyPlayingAyah != null) {
        final currentIndex = widget.ayahList!
            .indexWhere((a) => a.number == _currentlyPlayingAyah);

        if (currentIndex != -1 && currentIndex < widget.ayahList!.length - 1) {
          // Play next ayah after a short delay
          Future.delayed(const Duration(milliseconds: 500), () {
            if (!mounted) return;
            _playAyahAudio(widget.ayahList![currentIndex + 1]);
          });
        } else if (repeatMode == 'surah' &&
            currentIndex == widget.ayahList!.length - 1) {
          // Restart surah from the beginning
          Future.delayed(const Duration(milliseconds: 500), () {
            if (!mounted) return;
            _playAyahAudio(widget.ayahList![0]);
          });
        } else if (_isSurahPlaybackMode) {
          // Finished playing entire surah
          _isSurahPlaybackMode = false;
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
        }
      }
    }
  }

  void _initializeData() async {
    _loadFavoriteStates();
    _loadLastReadPosition();
    // Audio will be loaded on-demand when user clicks play
  }

  /// Check if this surah is downloaded for offline playback
  Future<void> _checkOfflineStatus() async {
    if (widget.suratNo == null || widget.ayahList == null) return;
    final reciterId = ReciterService.instance.currentReciterId.value;
    final downloaded = await OfflineAudioService.instance.isSurahDownloaded(
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
      debugPrint('Error loading translations: $e');
      if (!mounted) return;
      setState(() => _isLoadingTranslations = false);
    }
  }

  /// Start tracking reading progress
  void _startProgressTracking() {
    _progressTrackingTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _saveReadingProgress();
    });
  }

  /// Load last read position for this surah
  Future<void> _loadLastReadPosition() async {
    try {
      final lastProgress = database.getLastReadingProgress();
      if (lastProgress != null &&
          lastProgress.surahNumber == widget.suratNo &&
          lastProgress.ayahNumber > 0) {
        // Scroll to last read ayah after a short delay
        Future.delayed(const Duration(milliseconds: 500), () {
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

      // Also save to SharedPreferences for backward compatibility
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

      // Prefer local offline file if available
      final reciterId = ReciterService.instance.currentReciterId.value;
      final localFile = await OfflineAudioService.instance.getLocalAyahFile(
        reciterId: reciterId,
        surahNumber: widget.suratNo!,
        ayahNumber: ayah.number!,
      );

      if (localFile != null) {
        await _audioController.setLocalSource(localFile.path);
        await _audioController.setSpeed(SpUtil.getAudioSpeed());
        _audioController.play();
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

          // Show error to user
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
      }

      // Save listening progress to database
      await _saveListeningProgress(ayah.number!, 0);

      // Also save to SharedPreferences for backward compatibility
      SpUtil.setLastListen(
        surah: widget.suratNo!,
        ayah: ayah.number!,
        positionMs: 0,
      );
    } catch (e) {
      debugPrint("Error playing audio for ayah ${ayah.number}: $e");

      // Provide more specific error messages
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

    // Show confirmation dialog with options
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

    // Enable surah playback mode
    setState(() {
      _isSurahPlaybackMode = true;
    });

    // Start playing from the first ayah
    await _playAyahAudio(widget.ayahList!.first);

    // Show snackbar with playback info
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
    final index =
        widget.ayahList!.indexWhere((ayah) => ayah.number == ayahNumber);
    if (index != -1) {
      _scrollController.scrollToIndex(
        index,
        duration: const Duration(milliseconds: 500),
        preferPosition: AutoScrollPosition.middle,
      );
      _lastVisibleAyah = ayahNumber; // Track visible ayah
    }
  }

  /// Save listening progress to database
  Future<void> _saveListeningProgress(int ayahNumber, int positionMs) async {
    if (widget.suratNo == null) return;

    try {
      final currentProgress = database.getListeningProgress(
        widget.suratNo!,
        ayahNumber,
      );

      final listenTime = currentProgress?.totalListenTimeSeconds ?? 0;

      final progress = ListeningProgress(
        surahNumber: widget.suratNo!,
        ayahNumber: ayahNumber,
        positionMs: positionMs,
        lastListenedAt: DateTime.now(),
        totalListenTimeSeconds: listenTime + 5,
        completed: false,
        reciter: ReciterService.instance.currentReciterId.value,
        playbackSpeed: SpUtil.getAudioSpeed(),
      );

      await database.saveListeningProgress(progress);
      debugPrint(
          'Saved listening progress: Surah ${widget.suratNo}, Ayah $ayahNumber');
    } catch (e) {
      debugPrint('Error saving listening progress: $e');
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
    final theme = Theme.of(context);
    final isDesktop = isDisplayDesktop(context);

    return ChangeNotifierProvider.value(
      value: _audioController, // Provide the AudioController instance
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        body: Column(
          children: [
            // Custom App Bar
            _buildAppBar(theme, isDesktop),

            // Content Area
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sidebar - Only on desktop
                  if (isDesktop) _buildSidebar(theme),

                  // Main Content - Verses
                  Expanded(
                    child: _buildVersesList(theme),
                  ),
                ],
              ),
            ),
          ],
        ),

        // Floating Action Button for Quick Actions
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
          // Back Button
          IconButton(
            icon: const Icon(FontAwesomeIcons.arrowLeft),
            onPressed: () => Get.back(),
            splashRadius: 20,
          ),

          const SizedBox(width: 16),

          // Surah Info
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

          // Offline Download Badge
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

          // Play Surah Button
          IconButton(
            icon: Icon(
              FontAwesomeIcons.circlePlay,
              color: theme.colorScheme.primary,
            ),
            onPressed: _playSurah,
            tooltip: 'Play Entire Surah',
            splashRadius: 20,
          ),

          // Settings Menu
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
          // Quick Navigation
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
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Bookmarks
          Consumer<FavoriteManager>(
            builder: (context, favManager, child) {
              return FutureBuilder<List<String>>(
                future: favManager
                    .getFavorites()
                    .then((list) => list.map((f) => f.id).toList()),
                builder: (context, snapshot) {
                  final favorites = snapshot.data ?? [];
                  final ayahFavorites = favorites
                      .where((id) => id.startsWith('${widget.suratNo}:'))
                      .toList();

                  if (ayahFavorites.isEmpty) {
                    return Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'No bookmarks yet',
                          style: TextStyle(
                            color: theme.colorScheme.onSurface.withOpacity(0.5),
                          ),
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
                          Text(
                            'Bookmarks',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...ayahFavorites.take(5).map((id) {
                            final ayahNum = int.parse(id.split(':')[1]);
                            return ListTile(
                              dense: true,
                              leading: CircleAvatar(
                                radius: 12,
                                backgroundColor: theme.colorScheme.primary,
                                child: Text(
                                  ayahNum.toString(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text('Ayah $ayahNum'),
                              onTap: () => _scrollToAyah(ayahNum),
                            );
                          }),
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
          // Track which ayah is currently visible
          if (scrollNotification is ScrollUpdateNotification) {
            final visibleIndex = (_scrollController.offset / 100).round();
            if (visibleIndex >= 0 && visibleIndex < widget.ayahList!.length) {
              _lastVisibleAyah = widget.ayahList![visibleIndex].number;
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
              // Ayah Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Ayah Number
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

                  // Favorite Button
                  IconButton(
                    icon: Icon(
                      _favoriteStates[ayah.number!] ?? false
                          ? FontAwesomeIcons.solidHeart
                          : FontAwesomeIcons.heart,
                      color: _favoriteStates[ayah.number!] ?? false
                          ? theme.colorScheme.secondary
                          : theme.colorScheme.onSurface.withOpacity(0.5),
                      size: 18,
                    ),
                    onPressed: () => _toggleFavorite(ayah.number!),
                    splashRadius: 16,
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Arabic Text
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

              const SizedBox(height: 16),

              // Translation (Conditional)
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

              // Action Buttons
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
        // Play Button
        _buildAudioControl(ayah, theme),

        // Share Button
        IconButton(
          icon: const Icon(FontAwesomeIcons.shareNodes, size: 18),
          onPressed: () => share.showShareDialog(
            context: context,
            text: ayah.text!,
          ),
          tooltip: 'Share',
        ),

        // Copy Button
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

        // Bookmark Button
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
    // Use local audioController instance directly
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
                setState(() => _currentlyPlayingAyah = null);
              },
              tooltip: 'Pause',
            );
          default:
            // Default case for when audio is paused or not relevant to this ayah
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
                  // TODO: Implement study mode
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
    return FloatingActionButton(
      onPressed: () => _scrollToAyah(1),
      backgroundColor: theme.colorScheme.primary,
      tooltip: 'Scroll to top',
      child: Icon(FontAwesomeIcons.arrowUp, color: theme.colorScheme.onPrimary),
    );
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

  Future<void> _promptDownloadSurah() async {
    if (widget.suratNo == null || widget.ayahList == null) return;
    final reciterId = ReciterService.instance.currentReciterId.value;
    final ayahCount = widget.ayahList!.length;

    final already = await OfflineAudioService.instance.isSurahDownloaded(
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
                await OfflineAudioService.instance.removeSurah(
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

    final cancelToken = CancelToken();
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

    await OfflineAudioService.instance.downloadSurah(
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

                  // Playback Speed
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
                      // Apply speed to currently playing audio
                      if (_currentlyPlayingAyah != null) {
                        _audioController.setSpeed(v);
                      }
                    },
                  ),

                  const Divider(),

                  // Auto-play next ayah
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

                  // Repeat Mode
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
    // Remove audio completion listener
    _audioController.buttonNotifier.removeListener(_onAudioStateChanged);
    if (_reciterListener != null) {
      ReciterService.instance.currentReciterId
          .removeListener(_reciterListener!);
    }
    // Save one last time before disposing, but avoid setState calls inside
    // _saveReadingProgress that could run after dispose. We call it and ignore
    // any setState inside (the method checks mounted before setState).
    _saveReadingProgress();
    _scrollController.dispose();
    _audioController.dispose(); // Still dispose the local instance
    super.dispose();
  }
}
