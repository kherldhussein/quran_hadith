import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import 'package:quran_hadith/anim/particle_canvas.dart';
import 'package:quran_hadith/controller/quranAPI.dart';
import 'package:quran_hadith/theme/app_theme.dart';
import 'package:quran_hadith/utils/sp_util.dart';
import 'package:quran_hadith/widgets/suratTile.dart';
import 'package:quran_hadith/widgets/modern_search_dialog.dart';
// rxdart removed: no longer used in this file
import 'package:quran_hadith/database/database_service.dart';
import 'package:quran_hadith/database/hive_adapters.dart';

import '../controller/favorite.dart';
import '../controller/random_ayah.dart';
import '../models/surah_model.dart';

class QPage extends StatefulWidget {
  const QPage({super.key});

  @override
  _QPageState createState() => _QPageState();
}

class _QPageState extends State<QPage> with AutomaticKeepAliveClientMixin {
  // State variables
  late AudioPlayer _audioPlayer;
  late final RandomVerseManager _verseManager;

  // UI state
  String _userName = 'Ahmad';
  String _verseText = 'Loading Ayah of the Day...';
  bool _isLoadingVerse = false;
  String _sortBy = 'Order';
  List<Surah> _allSurahs = [];

  // Real-time data
  ReadingProgress? _lastRead;
  ListeningProgress? _lastListened;
  bool _loadingProgress = true;

  // (was) Streams: removed unused _durationState to avoid keeping streams alive

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    // Defer data initialization to after first frame to avoid lifecycle races
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _initializeData();
    });
  }

  void _initializeControllers() {
    _verseManager = RandomVerseManager();
    _audioPlayer = AudioPlayer();
  }

  void _initializeData() {
    _loadUserData();
    _loadProgressData();
    _fetchRandomVerse();
  }

  Future<void> _loadUserData() async {
    final userName = SpUtil.getUser();
    if (!mounted) return;
    setState(() {
      _userName = userName;
    });
  }

  Future<void> _loadProgressData() async {
    try {
      final lastRead = await database.getLastReadingProgress();
      final lastListened = await database.getLastListeningProgress();

      if (!mounted) return;
      setState(() {
        _lastRead = lastRead;
        _lastListened = lastListened;
        _loadingProgress = false;
      });
    } catch (e) {
      debugPrint('Error loading progress data: $e');
      if (!mounted) return;
      setState(() {
        _loadingProgress = false;
      });
    }
  }

  Future<void> _fetchRandomVerse() async {
    if (_isLoadingVerse) return;
    if (!mounted) return;

    setState(() {
      _isLoadingVerse = true;
    });

    try {
      final verse = await _verseManager.getRandomVerse();
      if (!mounted) return;
      setState(() {
        _verseText = verse;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _verseText = 'Failed to load verse. Tap to retry.';
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoadingVerse = false;
      });
    }
  }

  void _showVerseDialog() {
    final theme = Theme.of(context);
    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 40,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.primary.withOpacity(0.8),
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        FontAwesomeIcons.solidStar,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'AYAH OF THE DAY',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.95),
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Daily inspiration from the Quran',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Get.back(),
                      tooltip: 'Close',
                    ),
                  ],
                ),
              ),

              // Content
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Arabic Text Container
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            theme.colorScheme.surfaceContainerHighest
                                .withOpacity(0.5),
                            theme.colorScheme.surfaceContainerHighest
                                .withOpacity(0.2),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: theme.dividerColor.withOpacity(0.2),
                        ),
                      ),
                      child: _isLoadingVerse
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(20),
                                child: CircularProgressIndicator(),
                              ),
                            )
                          : Text(
                              _verseText,
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                fontSize: 20,
                                height: 1.8,
                                fontFamily: 'Amiri',
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                    ),

                    const SizedBox(height: 24),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: _isLoadingVerse
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                : const Icon(FontAwesomeIcons.arrowsRotate,
                                    size: 16),
                            label: const Text('New Verse'),
                            onPressed:
                                _isLoadingVerse ? null : _fetchRandomVerse,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton.icon(
                            icon: const Icon(FontAwesomeIcons.check, size: 16),
                            label: const Text('Done'),
                            onPressed: () => Get.back(),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width >= 768;

    return Scaffold(
      backgroundColor: theme.appBarTheme.backgroundColor,
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: _buildMainContent(theme, isDesktop),
            ),

            // Sidebar (Right Side) - Fixed width
            Container(
              width: 320,
              decoration: BoxDecoration(
                  color: theme.appBarTheme.backgroundColor,
                  border: Border(
                    left: BorderSide(
                      color: theme.dividerColor.withOpacity(0.1),
                    ),
                  )),
              child: _buildSidebar(theme),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent(ThemeData theme, bool isDesktop) {
    return Container(
      decoration: BoxDecoration(
        gradient: theme.brightness == Brightness.dark
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  kDarkPrimaryColor,
                  kDarkPrimaryColor.withOpacity(0.9),
                ],
              )
            : LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xffeef2f5),
                  const Color(0xffe8f4f8),
                ],
              ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Header with Search and Sort
          _buildHeader(theme),

          // Quran Grid
          Expanded(
            child: Consumer<QuranAPI>(
              builder: (context, quranAPI, child) {
                return FutureBuilder<SurahList>(
                  future: quranAPI.getSuratAudio(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return _buildLoadingState();
                    }

                    if (snapshot.hasError) {
                      return _buildErrorState(snapshot.error.toString());
                    }

                    final surahs = snapshot.data?.surahs ?? [];
                    final filteredSurahs = _filterAndSortSurahs(surahs);

                    return _buildSurahGrid(filteredSurahs, isDesktop);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
          color: theme.colorScheme.surface.withOpacity(0.8),
          border: Border(
            bottom: BorderSide(
              color: theme.dividerColor.withOpacity(0.1),
            ),
          )),
      child: Row(
        children: [
          // Search Button
          Expanded(
            child: InkWell(
              onTap: _showSearchDialog,
              child: Container(
                height: 45,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: theme.dividerColor.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 12),
                    Icon(
                      FontAwesomeIcons.magnifyingGlass,
                      size: 16,
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Search Surahs...',
                      style: TextStyle(
                        fontSize: 14,
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Sort Dropdown
          Container(
            height: 45,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.dividerColor.withOpacity(0.3)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _sortBy,
                items: ['Order', 'Alphabet'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(
                      'Sort by $value',
                      style: TextStyle(
                        fontSize: 14,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _sortBy = newValue!;
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSearchDialog() async {
    if (_allSurahs.isEmpty) {
      // Fetch surahs if not already loaded
      final quranAPI = Provider.of<QuranAPI>(context, listen: false);
      final surahList = await quranAPI.getSuratAudio();
      _allSurahs = surahList.surahs ?? [];
    }

    if (_allSurahs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('No surahs available'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      return;
    }

    final searchItems = _allSurahs.map((surah) {
      return SearchableItem(
        title: surah.englishName ?? '',
        subtitle: surah.name ?? '',
        description:
            '${surah.englishNameTranslation ?? ''} • ${surah.ayahs?.length ?? 0} Ayahs • ${surah.revelationType ?? ''}',
        badge: '${surah.number}',
        data: surah,
      );
    }).toList();

    await showModernSearchDialog(
      context: context,
      items: searchItems,
      title: 'Search Surahs',
      hintText: 'Search by name, translation, or number...',
      onItemSelected: (item) {
        final surah = item.data as Surah;
        Get.toNamed('/qPageView', arguments: {
          'suratNo': surah.number,
          'ayahNo': 1,
        });
      },
    );
  }

  Widget _buildSurahGrid(List<Surah> surahs, bool isDesktop) {
    // Adaptive grid based on screen width
    final screenWidth = MediaQuery.of(context).size.width;
    final int crossAxisCount;

    if (screenWidth < 600) {
      crossAxisCount = 1; // Mobile
    } else if (screenWidth < 900) {
      crossAxisCount = 2; // Small tablet
    } else if (screenWidth < 1200) {
      crossAxisCount = 3; // Large tablet / Small desktop
    } else if (screenWidth < 1600) {
      crossAxisCount = 3; // Medium desktop
    } else if (screenWidth < 2000) {
      crossAxisCount = 4; // Large desktop
    } else {
      crossAxisCount = 5; // Ultra-wide display
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 20,
          mainAxisSpacing: 20,
          childAspectRatio: 1.6,
        ),
        itemCount: surahs.length,
        itemBuilder: (context, index) {
          final surah = surahs[index];
          return Consumer<FavoriteManager>(
            builder: (context, favManager, child) {
              return SuratTile(
                itemCount: surahs.length,
                isFavorite: favManager.isFavorited(surah.name!),
                onFavorite: () => favManager.toggleFavorite(
                  id: surah.name!,
                  name: surah.englishName!,
                ),
                colorI:
                    _getSurahColor(index, theme.brightness == Brightness.dark),
                radius: 12,
                ayahList: surah.ayahs,
                suratNo: surah.number,
                icon: FontAwesomeIcons.heart,
                revelationType: surah.revelationType,
                englishTrans: surah.englishNameTranslation,
                englishName: surah.englishName,
                name: surah.name,
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildSidebar(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Salam,',
            style: TextStyle(
              fontSize: 14,
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          Text(
            _userName,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 32),

          // Last Read Section
          _buildLastReadSection(theme),
          const SizedBox(height: 24),

          // Last Listened Section
          _buildLastListenedSection(theme),
          const SizedBox(height: 32),

          // Divider
          Container(
            height: 1,
            color: theme.dividerColor.withOpacity(0.2),
          ),
          const SizedBox(height: 32),

          // Ayah of the Day
          _buildAyahOfTheDay(theme),
        ],
      ),
    );
  }

  Widget _buildLastReadSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'LAST READ',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.primary,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        _loadingProgress
            ? _buildLoadingSidebarCard(theme)
            : _lastRead != null
                ? _buildSidebarCard(
                    theme: theme,
                    icon: FontAwesomeIcons.book,
                    surahName: _getSurahName(_lastRead!.surahNumber),
                    subtitle: 'Ayah ${_lastRead!.ayahNumber}',
                    timeAgo: _formatTimeAgo(_lastRead!.lastReadAt),
                    onTap: () => _navigateToLastRead(),
                  )
                : _buildEmptySidebarCard(
                    theme: theme,
                    icon: FontAwesomeIcons.book,
                    message: 'No reading history yet',
                  ),
      ],
    );
  }

  Widget _buildLastListenedSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'LAST LISTENED',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.primary,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        _loadingProgress
            ? _buildLoadingSidebarCard(theme)
            : _lastListened != null
                ? _buildSidebarCard(
                    theme: theme,
                    icon: FontAwesomeIcons.headphones,
                    surahName: _getSurahName(_lastListened!.surahNumber),
                    subtitle: 'Ayah ${_lastListened!.ayahNumber}',
                    timeAgo: _formatTimeAgo(_lastListened!.lastListenedAt),
                    onTap: () => _navigateToLastListened(),
                  )
                : _buildEmptySidebarCard(
                    theme: theme,
                    icon: FontAwesomeIcons.headphones,
                    message: 'No listening history yet',
                  ),
      ],
    );
  }

  Widget _buildSidebarCard({
    required ThemeData theme,
    required IconData icon,
    required String surahName,
    required String subtitle,
    required String timeAgo,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 16,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    surahName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    timeAgo,
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.colorScheme.primary.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              FontAwesomeIcons.chevronRight,
              size: 14,
              color: theme.colorScheme.onSurface.withOpacity(0.3),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingSidebarCard(ThemeData theme) {
    return Container(
      height: 80,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: double.infinity,
                  height: 14,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 100,
                  height: 12,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptySidebarCard({
    required ThemeData theme,
    required IconData icon,
    required String message,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.dividerColor.withOpacity(0.3),
          style: BorderStyle.solid,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 16,
              color: theme.colorScheme.onSurface.withOpacity(0.3),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 13,
                color: theme.colorScheme.onSurface.withOpacity(0.5),
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getSurahName(int surahNumber) {
    // Map of surah numbers to names
    final surahNames = {
      1: 'Al-Fatihah',
      2: 'Al-Baqarah',
      3: 'Ali \'Imran',
      4: 'An-Nisa',
      5: 'Al-Ma\'idah',
      6: 'Al-An\'am',
      7: 'Al-A\'raf',
      8: 'Al-Anfal',
      9: 'At-Tawbah',
      10: 'Yunus',
      11: 'Hud',
      12: 'Yusuf',
      13: 'Ar-Ra\'d',
      14: 'Ibrahim',
      15: 'Al-Hijr',
      16: 'An-Nahl',
      17: 'Al-Isra',
      18: 'Al-Kahf',
      19: 'Maryam',
      20: 'Ta-Ha',
      21: 'Al-Anbiya',
      22: 'Al-Hajj',
      23: 'Al-Mu\'minun',
      24: 'An-Nur',
      25: 'Al-Furqan',
      26: 'Ash-Shu\'ara',
      27: 'An-Naml',
      28: 'Al-Qasas',
      29: 'Al-\'Ankabut',
      30: 'Ar-Rum',
      31: 'Luqman',
      32: 'As-Sajdah',
      33: 'Al-Ahzab',
      34: 'Saba',
      35: 'Fatir',
      36: 'Ya-Sin',
      37: 'As-Saffat',
      38: 'Sad',
      39: 'Az-Zumar',
      40: 'Ghafir',
      41: 'Fussilat',
      42: 'Ash-Shuraa',
      43: 'Az-Zukhruf',
      44: 'Ad-Dukhan',
      45: 'Al-Jathiyah',
      46: 'Al-Ahqaf',
      47: 'Muhammad',
      48: 'Al-Fath',
      49: 'Al-Hujurat',
      50: 'Qaf',
      51: 'Adh-Dhariyat',
      52: 'At-Tur',
      53: 'An-Najm',
      54: 'Al-Qamar',
      55: 'Ar-Rahman',
      56: 'Al-Waqi\'ah',
      57: 'Al-Hadid',
      58: 'Al-Mujadila',
      59: 'Al-Hashr',
      60: 'Al-Mumtahanah',
      61: 'As-Saff',
      62: 'Al-Jumu\'ah',
      63: 'Al-Munafiqun',
      64: 'At-Taghabun',
      65: 'At-Talaq',
      66: 'At-Tahrim',
      67: 'Al-Mulk',
      68: 'Al-Qalam',
      69: 'Al-Haqqah',
      70: 'Al-Ma\'arij',
      71: 'Nuh',
      72: 'Al-Jinn',
      73: 'Al-Muzzammil',
      74: 'Al-Muddaththir',
      75: 'Al-Qiyamah',
      76: 'Al-Insan',
      77: 'Al-Mursalat',
      78: 'An-Naba',
      79: 'An-Nazi\'at',
      80: '\'Abasa',
      81: 'At-Takwir',
      82: 'Al-Infitar',
      83: 'Al-Mutaffifin',
      84: 'Al-Inshiqaq',
      85: 'Al-Buruj',
      86: 'At-Tariq',
      87: 'Al-A\'la',
      88: 'Al-Ghashiyah',
      89: 'Al-Fajr',
      90: 'Al-Balad',
      91: 'Ash-Shams',
      92: 'Al-Layl',
      93: 'Ad-Duhaa',
      94: 'Ash-Sharh',
      95: 'At-Tin',
      96: 'Al-\'Alaq',
      97: 'Al-Qadr',
      98: 'Al-Bayyinah',
      99: 'Az-Zalzalah',
      100: 'Al-\'Adiyat',
      101: 'Al-Qari\'ah',
      102: 'At-Takathur',
      103: 'Al-\'Asr',
      104: 'Al-Humazah',
      105: 'Al-Fil',
      106: 'Quraysh',
      107: 'Al-Ma\'un',
      108: 'Al-Kawthar',
      109: 'Al-Kafirun',
      110: 'An-Nasr',
      111: 'Al-Masad',
      112: 'Al-Ikhlas',
      113: 'Al-Falaq',
      114: 'An-Nas',
    };
    return surahNames[surahNumber] ?? 'Surah $surahNumber';
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${(difference.inDays / 7).floor()}w ago';
    }
  }

  void _navigateToLastRead() {
    if (_lastRead != null) {
      // Navigate to the surah and ayah
      Get.toNamed('/qPageView', arguments: {
        'suratNo': _lastRead!.surahNumber,
        'ayahNo': _lastRead!.ayahNumber,
      });
    }
  }

  void _navigateToLastListened() {
    if (_lastListened != null) {
      // Navigate to the surah and ayah
      Get.toNamed('/qPageView', arguments: {
        'suratNo': _lastListened!.surahNumber,
        'ayahNo': _lastListened!.ayahNumber,
      });
    }
  }

  Widget _buildAyahOfTheDay(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(FontAwesomeIcons.solidStar, color: Colors.white, size: 14),
              const SizedBox(width: 8),
              Text(
                'AYAH OF THE DAY',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.95),
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _verseText,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: Colors.white,
              fontFamily: 'Amiri',
              fontSize: 14,
              height: 1.6,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: _showVerseDialog,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Read now',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.arrow_forward, color: Colors.white, size: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Surah> _filterAndSortSurahs(List<Surah> surahs) {
    List<Surah> filtered = List.from(surahs);

    // Apply sorting
    if (_sortBy == 'Alphabet') {
      filtered.sort((a, b) => a.englishName!.compareTo(b.englishName!));
    } else {
      // Default order (by surah number)
      filtered.sort((a, b) => a.number!.compareTo(b.number!));
    }

    return filtered;
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ParticleCanvas(
            MediaQuery.of(context).size.height * 0.3,
            MediaQuery.of(context).size.width * 0.6,
          ),
          const SizedBox(height: 20),
          Text(
            'Loading Quran...',
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(FontAwesomeIcons.exclamationTriangle,
                size: 64, color: Colors.orange),
            const SizedBox(height: 20),
            Text(
              'Unable to Load Quran',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please check your connection and try again',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getSurahColor(int index, bool isDark) {
    final colors = isDark
        ? [
            const Color(0xff2D5A72),
            const Color(0xff4A766E),
            const Color(0xff6B5B7A),
            const Color(0xff8F5B5B),
          ]
        : [
            const Color(0xffE0F5F0),
            const Color(0xffF0E8F5),
            const Color(0xffF5F0E8),
            const Color(0xffE8F0F5),
          ];
    return colors[index % colors.length];
  }

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
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
