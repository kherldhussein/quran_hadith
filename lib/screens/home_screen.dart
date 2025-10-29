import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:quran_hadith/layout/adaptive.dart';
import 'package:quran_hadith/screens/about.dart' as about;
import 'package:quran_hadith/screens/favorite.dart';
import 'package:quran_hadith/screens/hPage.dart';
import 'package:quran_hadith/screens/qPage.dart';
import 'package:quran_hadith/screens/bookmarks_screen.dart';
import 'package:quran_hadith/screens/settings.dart';
import 'package:quran_hadith/screens/statistics_screen.dart';
import 'package:quran_hadith/theme/app_theme.dart';
import 'package:quran_hadith/widgets/custom_button.dart';
import 'package:quran_hadith/widgets/app_dialogs.dart';
import 'package:quran_hadith/widgets/headerTitle.dart';
import 'package:quran_hadith/widgets/menu_list_items.dart';
import 'package:quran_hadith/widgets/qh_nav.dart';
import 'package:quran_hadith/widgets/shared_switcher.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:quran_hadith/screens/qPageView.dart';
import 'package:quran_hadith/models/search/ayah.dart' as search_models;
import 'package:quran_hadith/controller/search.dart' as qsearch;
import 'package:quran_hadith/database/database_service.dart';
import 'package:quran_hadith/database/hive_adapters.dart';
import 'package:quran_hadith/models/daily_ayah.dart';
import 'package:quran_hadith/models/reciter_model.dart';
import 'package:quran_hadith/services/daily_ayah_service.dart';
import 'package:quran_hadith/services/notification_service.dart';
import 'package:quran_hadith/services/reciter_service.dart';
import 'package:quran_hadith/utils/shared_p.dart';
import 'package:quran_hadith/utils/sp_util.dart';
import 'dart:math' as math;

import '../controller/quranAPI.dart';
import '../controller/audio_controller.dart';
import '../widgets/live_audio_player.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _NavRailItem {
  final IconData icon;
  final String label;

  const _NavRailItem(this.icon, this.label);
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
 int _selectedIndex = 0;
  late final List<Widget> _contentScreens;
  late ValueNotifier<bool> _isExtended;
  final qsearch.Search _offlineSearch = qsearch.Search();
  bool _searchReady = false;
  DailyAyah? _dailyAyah;
  bool _loadingDailyAyah = false;
  ReadingProgress? _lastReadingProgress;
  ListeningProgress? _lastListeningProgress;
  Map<String, dynamic>? _lastHadithReading;
  bool _dailyAyahReminderEnabled = false;
  bool _fridayReminderEnabled = false;
  late TimeOfDay _dailyAyahTime;
  late TimeOfDay _fridayReminderTime;
  bool _isSchedulingDailyAyah = false;
  bool _isSchedulingFriday = false;
  late String _selectedReciter;
  List<Reciter> _reciters = List<Reciter>.from(Reciter.fallback);
  bool _loadingReciters = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  final DailyAyahService _dailyAyahService = DailyAyahService.instance;
  final QuranAPI _quranApi = QuranAPI();

  static const List<_NavRailItem> _navItems = [
    _NavRailItem(FontAwesomeIcons.house, 'Dashboard'),
    _NavRailItem(FontAwesomeIcons.bookOpen, 'Quran'),
    _NavRailItem(FontAwesomeIcons.bookOpenReader, 'Hadith'),
    _NavRailItem(FontAwesomeIcons.heart, 'Favorites'),
    _NavRailItem(FontAwesomeIcons.bookmark, 'Bookmarks'),
    _NavRailItem(FontAwesomeIcons.chartLine, 'Statistics'),
    _NavRailItem(FontAwesomeIcons.gear, 'Settings'),
  ];

  @override
  void initState() {
    super.initState();

    _contentScreens = [
      const QPage(),
      const HPage(),
      const Favorite(),
      const BookmarksScreen(),
      const StatisticsScreen(),
      const Settings(),
    ];

    _isExtended = ValueNotifier<bool>(true);
    _selectedReciter = SpUtil.getReciter();
    _dailyAyahTime = _minutesToTimeOfDay(SpUtil.getDailyAyahTimeMinutes());
    _fridayReminderTime =
        _minutesToTimeOfDay(SpUtil.getFridayReminderTimeMinutes());
    _dailyAyahReminderEnabled = SpUtil.isDailyAyahNotificationEnabled();
    _fridayReminderEnabled = SpUtil.isFridayReminderEnabled();

    // Animation setup
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );
    _slideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    _loadReciters();

    _offlineSearch.loadSurah().then((_) {
      if (mounted) setState(() => _searchReady = true);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
      _animationController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadReciters({bool forceRefresh = false}) async {
    if (!mounted) return;
    setState(() => _loadingReciters = true);
    try {
      final reciters =
          await ReciterService.instance.getReciters(forceRefresh: forceRefresh);
      if (!mounted) return;
      setState(() {
        _reciters = reciters;
        _loadingReciters = false;
      });
    } catch (e) {
      debugPrint('HomeScreen: Failed to load reciters: $e');
      if (!mounted) return;
      setState(() => _loadingReciters = false);
    }
  }

  @override
  void setState(VoidCallback fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  void _loadInitialData() {
    _loadDailyAyah();
    _loadActivitySummaries();

    if (_dailyAyahReminderEnabled) {
      _scheduleDailyAyahNotification();
    }
    if (_fridayReminderEnabled) {
      _scheduleFridayReminder();
    }
  }

  Future<void> _loadDailyAyah({bool forceRefresh = false}) async {
    if (!mounted) return;
    setState(() {
      _loadingDailyAyah = true;
    });

    try {
      final ayah = await _dailyAyahService.getDailyAyah(
        forceRefresh: forceRefresh,
      );
      if (!mounted) return;
      setState(() {
        _dailyAyah = ayah;
        _loadingDailyAyah = false;
      });
    } catch (e) {
      debugPrint('HomeScreen: Failed to load daily ayah: $e');
      if (!mounted) return;
      setState(() {
        _loadingDailyAyah = false;
      });
    }
  }

  void _loadActivitySummaries() {
    final reading = database.getLastReadingProgress();
    final listening = database.getLastListeningProgress();
    final hadithReading = database.getLastHadithReading();
    if (!mounted) return;
    setState(() {
      _lastReadingProgress = reading;
      _lastListeningProgress = listening;
      _lastHadithReading = hadithReading;
    });
  }

  TimeOfDay _minutesToTimeOfDay(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    return TimeOfDay(hour: hours, minute: mins);
  }

  int _timeOfDayToMinutes(TimeOfDay time) => time.hour * 60 + time.minute;

  String _formatTimeOfDay(BuildContext context, TimeOfDay time) {
    return time.format(context);
  }

  String _formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) {
      return '${diff.inMinutes} min ago';
    }
    if (diff.inHours < 24) {
      return '${diff.inHours} h ago';
    }
    final days = diff.inDays;
    if (days == 1) return 'Yesterday';
    if (days < 7) return '$days days ago';
    final weeks = (days / 7).floor();
    return weeks == 1 ? 'Last week' : '$weeks weeks ago';
  }

  Future<void> _scheduleDailyAyahNotification() async {
    if (!mounted) return;
    setState(() => _isSchedulingDailyAyah = true);
    try {
      await NotificationService.instance.scheduleDailyNotification(
        id: NotificationService.dailyAyahNotificationId,
        time: _dailyAyahTime,
        title: 'Daily Ayah Reminder',
        body: _dailyAyah != null
            ? '${_dailyAyah!.surahName} • ${_dailyAyah!.reference}'
            : 'Take a moment to read today\'s ayah.',
      );
    } catch (e) {
      debugPrint('HomeScreen: Failed to schedule daily reminder: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not schedule the daily reminder.'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSchedulingDailyAyah = false);
      }
    }
  }

  Future<void> _scheduleFridayReminder() async {
    if (!mounted) return;
    setState(() => _isSchedulingFriday = true);
    try {
      await NotificationService.instance.scheduleWeeklyNotification(
        id: NotificationService.fridayReminderNotificationId,
        time: _fridayReminderTime,
        weekday: DateTime.friday,
        title: 'Friday Reminder',
        body: 'Remember to recite Surah Al-Kahf and send salutations.',
      );
    } catch (e) {
      debugPrint('HomeScreen: Failed to schedule Friday reminder: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not schedule the Friday reminder.'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSchedulingFriday = false);
      }
    }
  }

  Future<void> _toggleDailyAyahReminder(bool value) async {
    if (!mounted) return;
    setState(() => _dailyAyahReminderEnabled = value);
    final success = await SpUtil.setDailyAyahNotificationEnabled(value);
    if (!success) {
      if (!mounted) return;
      setState(() => _dailyAyahReminderEnabled = !value);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update daily ayah reminder.')),
      );
      return;
    }

    if (value) {
      await _scheduleDailyAyahNotification();
    } else {
      await NotificationService.instance
          .cancel(NotificationService.dailyAyahNotificationId);
    }
  }

  Future<void> _toggleFridayReminder(bool value) async {
    if (!mounted) return;
    setState(() => _fridayReminderEnabled = value);
    final success = await SpUtil.setFridayReminderEnabled(value);
    if (!success) {
      if (!mounted) return;
      setState(() => _fridayReminderEnabled = !value);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update Friday reminder.')),
      );
      return;
    }

    if (value) {
      await _scheduleFridayReminder();
    } else {
      await NotificationService.instance
          .cancel(NotificationService.fridayReminderNotificationId);
    }
  }

  Future<void> _pickDailyAyahTime() async {
    final selected = await showTimePicker(
      context: context,
      initialTime: _dailyAyahTime,
    );
    if (selected != null) {
      if (!mounted) return;
      setState(() => _dailyAyahTime = selected);
      await SpUtil.setDailyAyahTimeMinutes(_timeOfDayToMinutes(selected));
      if (_dailyAyahReminderEnabled) {
        await _scheduleDailyAyahNotification();
      }
    }
  }

  Future<void> _pickFridayReminderTime() async {
    final selected = await showTimePicker(
      context: context,
      initialTime: _fridayReminderTime,
    );
    if (selected != null) {
      if (!mounted) return;
      setState(() => _fridayReminderTime = selected);
      await SpUtil.setFridayReminderTimeMinutes(
        _timeOfDayToMinutes(selected),
      );
      if (_fridayReminderEnabled) {
        await _scheduleFridayReminder();
      }
    }
  }

  Future<void> _selectReciter(String reciterId) async {
    if (_selectedReciter == reciterId) return;
    final previous = _selectedReciter;
    setState(() => _selectedReciter = reciterId);

    final success = await SpUtil.setReciter(reciterId);
    await appSP.setString('selectedReciter', reciterId);
    ReciterService.instance.setCurrentReciterId(reciterId);
    if (!success) {
      if (!mounted) return;
      setState(() => _selectedReciter = previous);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update reciter.')),
      );
      return;
    }

    if (!mounted) return;
    final reciterName = ReciterService.instance
        .resolveById(reciterId, within: _reciters)
        .displayName;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Reciter set to $reciterName')),
    );
  }

   Widget _buildDashboard(BuildContext context) {
    final audioController = AudioController();

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: Transform.translate(
            offset: Offset(0, _slideAnimation.value),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 48),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeroBanner(context),
                  const SizedBox(height: 24),
                  // Live Audio Player - only shows when playing
                  LiveAudioPlayer(audioController: audioController),
                  const SizedBox(height: 24),
                  _buildDailyAyahCard(context),
                  const SizedBox(height: 24),
                  _buildActivitySection(context),
                ],
              ),
            ),
          ),
        );
      },
    );
  }


  Widget _buildHeroBanner(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primary.withOpacity(0.9),
            colorScheme.primaryContainer.withOpacity(0.8),
            colorScheme.secondary.withOpacity(0.7),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withOpacity(0.4),
            blurRadius: 32,
            spreadRadius: 4,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      padding: const EdgeInsets.all(32),
      child: Stack(
        children: [
          // Background pattern
          Positioned(
            right: -50,
            top: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withOpacity(0.1),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          
          // Content
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  // Logo with glow effect
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withOpacity(0.3),
                          blurRadius: 16,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const ImageIcon(AssetImage('assets/images/Logo.png')),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Peace be upon you',
                          style: textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 24,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Reignite your spiritual connection',
                          style: textTheme.titleMedium?.copyWith(
                            color: Colors.white.withOpacity(0.9),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  _buildQuickActionChip(
                    context,
                    icon: FontAwesomeIcons.bookOpen,
                    label: 'Continue reading',
                    onTap: _openLastRead,
                  ),
                  _buildQuickActionChip(
                    context,
                    icon: FontAwesomeIcons.play,
                    label: 'Resume listening',
                    onTap: _openLastListened,
                  ),
                  _buildQuickActionChip(
                    context,
                    icon: FontAwesomeIcons.rotateRight,
                    label: 'Refresh ayah',
                    onTap: () => _loadDailyAyah(forceRefresh: true),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionChip(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      child: Material(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                FaIcon(icon, size: 14, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDailyAyahCard(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.surface.withOpacity(0.9),
            theme.colorScheme.surfaceVariant.withOpacity(0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.15),
            blurRadius: 32,
            offset: const Offset(0, 16),
          ),
        ],
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.1),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary.withOpacity(0.2),
                      theme.colorScheme.secondary.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: FaIcon(
                  FontAwesomeIcons.star,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Ayah of the Day',
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 22,
                  ),
                ),
              ),
              _buildAnimatedRefreshButton(),
            ],
          ),
          const SizedBox(height: 20),
          if (_loadingDailyAyah && _dailyAyah == null)
            _buildLoadingShimmer()
          else if (_dailyAyah != null)
            _buildDailyAyahContent(context, _dailyAyah!)
          else
            _buildErrorState(textTheme),
        ],
      ),
    );
  }

  Widget _buildAnimatedRefreshButton() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: _loadingDailyAyah
            ? null
            : LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  Theme.of(context).colorScheme.secondary.withOpacity(0.05),
                ],
              ),
      ),
      child: IconButton(
        tooltip: 'Refresh ayah',
        onPressed: _loadingDailyAyah
            ? null
            : () => _loadDailyAyah(forceRefresh: true),
        icon: _loadingDailyAyah
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Theme.of(context).colorScheme.primary,
                ),
              )
            : FaIcon(
                FontAwesomeIcons.rotateRight,
                size: 18,
                color: Theme.of(context).colorScheme.primary.withOpacity(0.8),
              ),
      ),
    );
  }

  Widget _buildLoadingShimmer() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          height: 24,
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.3),
            borderRadius: BorderRadius.circular(8),
          ),
          margin: const EdgeInsets.only(bottom: 12),
        ),
        Container(
          width: double.infinity,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ],
    );
  }

  Widget _buildDailyAyahContent(BuildContext context, DailyAyah ayah) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Arabic Text with beautiful styling
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [
                colorScheme.primary.withOpacity(0.05),
                colorScheme.secondary.withOpacity(0.02),
              ],
            ),
            border: Border.all(
              color: colorScheme.outline.withOpacity(0.1),
            ),
          ),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Text(
              ayah.arabicText,
              style: textTheme.headlineSmall?.copyWith(
                fontFamily: 'Amiri',
                fontSize: 28,
                height: 1.8,
                color: colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        const SizedBox(height: 20),
        
        // Translation
        Text(
          ayah.translation.isNotEmpty
              ? ayah.translation
              : 'Translation unavailable.',
          style: textTheme.bodyLarge?.copyWith(
            fontSize: 16,
            height: 1.6,
            color: colorScheme.onSurface.withOpacity(0.9),
          ),
        ),
        const SizedBox(height: 20),
        
        // Metadata and Actions
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colorScheme.primary.withOpacity(0.1),
                    colorScheme.secondary.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  FaIcon(
                    FontAwesomeIcons.bookQuran,
                    size: 14,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${ayah.surahName} • ${ayah.reference}',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            _buildGradientButton(
              text: 'Open',
              icon: FontAwesomeIcons.arrowUpRightFromSquare,
              onPressed: () => _openDailyAyah(ayah),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGradientButton({
    required String text,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.secondary,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                FaIcon(icon, size: 14, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActivitySection(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cards = [
          _buildLastReadCard(context),
          _buildLastListenedCard(context),
          _buildLastReadHadithCard(context),
        ];
        
        if (constraints.maxWidth < 640) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: cards.asMap().entries.map((entry) {
              return Padding(
                padding: EdgeInsets.only(top: entry.key == 0 ? 0 : 16),
                child: entry.value,
              );
            }).toList(),
          );
        }
        
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: cards.asMap().entries.map((entry) {
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(left: entry.key == 0 ? 0 : 16),
                child: entry.value,
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildActivityCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required String footer,
    String? actionLabel,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      child: Material(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        elevation: 0,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colorScheme.surface,
                  colorScheme.surfaceVariant.withOpacity(0.5),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: theme.shadowColor.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
              border: Border.all(
                color: colorScheme.outline.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon with gradient background
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        colorScheme.primary.withOpacity(0.15),
                        colorScheme.secondary.withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    icon,
                    color: colorScheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(height: 20),
                
                // Title
                Text(
                  title,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 8),
                
                // Subtitle
                Text(
                  subtitle,
                  style: textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.8),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),
                
                // Footer
                Text(
                  footer,
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                
                // Action Button
                if (actionLabel != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: colorScheme.primary.withOpacity(0.3),
                      ),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: onTap,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                actionLabel,
                                style: textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                Icons.arrow_forward_rounded,
                                size: 16,
                                color: colorScheme.primary,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }


  List<Widget> _buildReciterPopover(BuildContext context) {
    final theme = Theme.of(context);

    if (_loadingReciters) {
      return const [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }

    if (_reciters.isEmpty) {
      return [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          child: Text('No reciters available. Try refreshing.'),
        ),
        ListTile(
          leading: const Icon(Icons.refresh),
          title: const Text('Refresh reciters'),
          onTap: () {
            Navigator.of(context).pop();
            _loadReciters(forceRefresh: true);
          },
        ),
      ];
    }

    final tiles = _reciters.map<Widget>((reciter) {
      final isSelected = reciter.id == _selectedReciter;
      return ListTile(
        leading: CircleAvatar(
          radius: 16,
          backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.12),
          child: FaIcon(
            FontAwesomeIcons.headphones,
            color: theme.colorScheme.primary,
            size: 14,
          ),
        ),
        title: Text(reciter.displayName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (reciter.arabicName != null && reciter.arabicName!.isNotEmpty)
              Text(
                reciter.arabicName!,
                style: const TextStyle(fontFamily: 'Amiri', fontSize: 13),
              ),
            Text(
              reciter.styleLabel,
              style: theme.textTheme.labelSmall,
            ),
          ],
        ),
        isThreeLine:
            reciter.arabicName != null && reciter.arabicName!.isNotEmpty,
        trailing: isSelected
            ? Icon(Icons.check, color: theme.colorScheme.primary, size: 18)
            : null,
        onTap: () {
          Navigator.of(context).pop();
          _selectReciter(reciter.id);
        },
      );
    }).toList();

    tiles.add(const Divider());
    tiles.add(
      ListTile(
        leading: _loadingReciters
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.refresh),
        title: const Text('Refresh reciters'),
        onTap: () {
          Navigator.of(context).pop();
          _loadReciters(forceRefresh: true);
        },
      ),
    );

    return tiles;
  }

  List<Widget> _buildNotificationPopover(BuildContext context) {
    return [
      SwitchListTile(
        value: _dailyAyahReminderEnabled,
        title: const Text('Daily Ayah Reminder'),
        subtitle: Text(
          'At ${_formatTimeOfDay(context, _dailyAyahTime)}',
        ),
        onChanged: (value) {
          Navigator.of(context).pop();
          _toggleDailyAyahReminder(value);
        },
      ),
      ListTile(
        enabled: _dailyAyahReminderEnabled,
        leading: const Icon(Icons.schedule),
        title: const Text('Reminder time'),
        subtitle: Text(_formatTimeOfDay(context, _dailyAyahTime)),
        trailing: _isSchedulingDailyAyah && _dailyAyahReminderEnabled
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : null,
        onTap: _dailyAyahReminderEnabled
            ? () {
                Navigator.of(context).pop();
                _pickDailyAyahTime();
              }
            : null,
      ),
      const Divider(),
      SwitchListTile(
        value: _fridayReminderEnabled,
        title: const Text('Friday Reminder'),
        subtitle: Text(
          'At ${_formatTimeOfDay(context, _fridayReminderTime)}',
        ),
        onChanged: (value) {
          Navigator.of(context).pop();
          _toggleFridayReminder(value);
        },
      ),
      ListTile(
        enabled: _fridayReminderEnabled,
        leading: const Icon(Icons.watch_later_outlined),
        title: const Text('Reminder time'),
        subtitle: Text(_formatTimeOfDay(context, _fridayReminderTime)),
        trailing: _isSchedulingFriday && _fridayReminderEnabled
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : null,
        onTap: _fridayReminderEnabled
            ? () {
                Navigator.of(context).pop();
                _pickFridayReminderTime();
              }
            : null,
      ),
      if (!_dailyAyahReminderEnabled && !_fridayReminderEnabled)
        const Padding(
          padding: EdgeInsets.only(top: 12),
          child: Text(
            'Enable reminders to receive gentle nudges to reconnect daily.',
            style: TextStyle(fontSize: 12),
          ),
        ),
    ];
  }

  NavigationRailDestination _buildNavDestination(
      _NavRailItem item, bool isCompact) {
    return NavigationRailDestination(
      icon: FaIcon(item.icon),
      label: Padding(
        padding: EdgeInsets.symmetric(vertical: isCompact ? 0 : 24),
        child: Text(item.label),
      ),
    );
  }

  String _formatAudioPosition(int positionMs) {
    final duration = Duration(milliseconds: positionMs);
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Widget _buildLastReadCard(BuildContext context) {
    final progress = _lastReadingProgress;
    final subtitle = progress != null
        ? 'Surah ${progress.surahNumber} • Ayah ${progress.ayahNumber}'
        : 'No reading activity yet';
    final footer = progress != null
        ? 'Updated ${_formatRelativeTime(progress.lastReadAt)}'
        : 'Start reading to track progress.';
    return _buildActivityCard(
      context: context,
      icon: FontAwesomeIcons.bookOpen,
      title: 'Last Read',
      subtitle: subtitle,
      footer: footer,
      actionLabel: progress != null ? 'Continue reading' : null,
      onTap: progress != null ? _openLastRead : null,
    );
  }

  Widget _buildLastListenedCard(BuildContext context) {
    final progress = _lastListeningProgress;
    final subtitle = progress != null
        ? 'Surah ${progress.surahNumber} • Ayah ${progress.ayahNumber}'
        : 'No listening activity yet';
    final footer = progress != null
        ? 'Position ${_formatAudioPosition(progress.positionMs)} • '
            '${_formatRelativeTime(progress.lastListenedAt)}'
        : 'Play a recitation to track listening progress.';
    return _buildActivityCard(
      context: context,
      icon: FontAwesomeIcons.headphones,
      title: 'Last Listened',
      subtitle: subtitle,
      footer: footer,
      actionLabel: progress != null ? 'Resume listening' : null,
      onTap: progress != null ? _openLastListened : null,
    );
  }

  Widget _buildLastReadHadithCard(BuildContext context) {
    final hadithReading = _lastHadithReading;
    final subtitle = hadithReading != null
        ? '${hadithReading['bookName'] ?? 'Hadith Book'} • Page ${hadithReading['page'] ?? '?'}'
        : 'No hadith reading activity yet';
    final footer = hadithReading != null
        ? 'Updated ${_formatRelativeTime(DateTime.parse(hadithReading['time'] as String? ?? DateTime.now().toIso8601String()))}'
        : 'Start reading hadith to track progress.';
    return _buildActivityCard(
      context: context,
      icon: FontAwesomeIcons.bookOpenReader,
      title: 'Last Read Hadith',
      subtitle: subtitle,
      footer: footer,
      actionLabel: hadithReading != null ? 'Continue reading' : null,
      onTap: hadithReading != null
          ? () => _openLastReadHadith(hadithReading)
          : null,
    );
  }

  Future<void> _openDailyAyah(DailyAyah ayah) async {
    await _openSurahAt(ayah.surahNumber, ayah.ayahNumber);
  }

  Future<void> _openLastRead() async {
    final progress = _lastReadingProgress;
    if (progress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No reading progress yet.')),
      );
      return;
    }
    await _openSurahAt(progress.surahNumber, progress.ayahNumber);
  }

  Future<void> _openLastListened() async {
    final progress = _lastListeningProgress;
    if (progress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No listening progress yet.')),
      );
      return;
    }
    await _openSurahAt(progress.surahNumber, progress.ayahNumber);
  }

  Future<void> _openLastReadHadith(Map<String, dynamic> hadithReading) async {
    try {
      Get.to(() => const HPage());
    } catch (e) {
      debugPrint('HomeScreen: Failed to open hadith page - $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open the hadith page.')),
      );
    }
  }

  Future<void> _openSurahAt(int surahNumber, int ayahNumber) async {
    try {
      final data = await _quranApi.getSuratAudio();
      final surah = data.surahs!.firstWhere(
        (s) => s.number == surahNumber,
        orElse: () => data.surahs!.first,
      );
      final ayahs = surah.ayahs;
      Get.to(() => QPageView(
            suratName: surah.name,
            suratNo: surah.number,
            ayahList: ayahs,
            englishMeaning: surah.englishNameTranslation,
            suratEnglishName: surah.englishName,
          ));
    } catch (e) {
      debugPrint(
          'HomeScreen: Failed to open surah $surahNumber:$ayahNumber - $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to open the selected surah. Please try again.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSmall = isDisplayVerySmallDesktop(context);
    final isCompact = isDisplaySmallDesktop(context);

    final shouldExtendNav = !isSmall;
    if (_isExtended.value != shouldExtendNav) {
      _isExtended.value = shouldExtendNav;
    }

    final searchButton = _buildAnimatedSearchButton(context);

    final Widget selectedContent = _selectedIndex == 0
        ? _buildDashboard(context)
        : _contentScreens[_selectedIndex - 1];

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Scaffold(
          appBar: _buildFuturisticAppBar(context, isSmall, isCompact, searchButton),
          body: Row(
            children: [
              _buildAnimatedNavigationRail(context, isSmall),
              Expanded(
                child: SharedAxisTransitionSwitcher(
                  child: QhNav(
                    child: KeyedSubtree(
                      key: ValueKey(_selectedIndex),
                      child: selectedContent,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAnimatedSearchButton(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary.withOpacity(0.1),
            Theme.of(context).colorScheme.secondary.withOpacity(0.05),
        ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        tooltip: 'Search',
        icon: const FaIcon(FontAwesomeIcons.magnifyingGlass),
        onPressed: () {
          if (_searchReady) {
            showSearch(
              context: context,
              delegate: QuranSearchDelegate(
                offlineSearch: _offlineSearch,
                onSelect: (String surahName, int ayahNo) {
                  _quranApi.getSuratAudio().then((data) {
                    final surah = data.surahs!.firstWhere(
                      (e) => e.name == surahName || e.englishName == surahName,
                      orElse: () => data.surahs!.first,
                    );
                    final ayahs = surah.ayahs;
                    Get.to(() => QPageView(
                          suratName: surah.name,
                          suratNo: surah.number,
                          ayahList: ayahs,
                          englishMeaning: surah.englishNameTranslation,
                          suratEnglishName: surah.englishName,
                        ));
                  });
                },
              ),
            );
          }
        },
      ),
    );
  }

  AppBar _buildFuturisticAppBar(BuildContext context, bool isSmall,
      bool isCompact, Widget searchButton) {
    final theme = Theme.of(context);

    return AppBar(
      backgroundColor: theme.colorScheme.surface.withOpacity(0.95),
      elevation: 0,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.topRight,
            colors: [
              theme.colorScheme.surface.withOpacity(0.98),
              theme.colorScheme.surfaceVariant.withOpacity(0.9),
            ],
          ),
          border: Border(
            bottom: BorderSide(
              color: theme.dividerColor.withOpacity(0.1),
              width: 1,
            ),
          ),
        ),
      ),
      title: HeaderText(size: isCompact ? 20 : 30),
      actions: [
        searchButton,
        _buildAnimatedCustomButton(
          icon: FontAwesomeIcons.headphones,
          popoverHeight: 300,
          popoverWidth: 280,
          children: _buildReciterPopover(context),
        ),
        _buildAnimatedCustomButton(
          icon: FontAwesomeIcons.bell,
          popoverHeight: 340,
          popoverWidth: 280,
          children: _buildNotificationPopover(context),
        ),
        SizedBox(width: isSmall ? 80 : 120),
        if (!isSmall)
          _buildAnimatedCustomButton2(
            icon: FontAwesomeIcons.a,
            children: [
              MItems(
                  text: 'Donate on Patreon',
                  pressed: () {
                    launchUrl(Uri.parse(
                        'https://www.patreon.com/join/kherld/checkout?ru=undefined'));
                    Get.back();
                  }),
              MItems(
                  text: 'Bug Report',
                  pressed: () {
                    launchUrl(Uri.parse(
                        'https://github.com/kherld-hussein/quran_hadith/issues/'));
                    Get.back();
                  }),
              MItems(
                  text: 'Feature Request',
                  pressed: () {
                    launchUrl(Uri.parse(
                        'https://github.com/kherld-hussein/quran_hadith/issues/'));
                    Get.back();
                  }),
              MItems(
                  text: 'About',
                  pressed: () {
                    Get.back();
                    about.showAboutDialog();
                  }),
            ],
          ),
      ],
      leading: Padding(
        padding: const EdgeInsets.only(left: 15.0, top: 5.0),
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.primary,
                theme.colorScheme.secondary,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withOpacity(0.3),
                blurRadius: 12,
                spreadRadius: 2,
              ),
            ],
          ),
          child: CircleAvatar(
            radius: 30,
            backgroundColor: Colors.transparent,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: ImageIcon(
                const AssetImage('assets/images/Logo.png'),
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedNavigationRail(BuildContext context, bool isSmall) {
    return LayoutBuilder(builder: (context, constraints) {
      return SingleChildScrollView(
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: IntrinsicHeight(
            child: ValueListenableBuilder<bool>(
              valueListenable: _isExtended,
              builder: (context, isExtended, child) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  decoration: BoxDecoration(
                    border: Border(
                      right: BorderSide(
                        color: Theme.of(context).dividerColor.withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                  ),
                  child: NavigationRail(
                    extended: isExtended,
                    backgroundColor: Theme.of(context).colorScheme.surface,
                    selectedIconTheme: IconThemeData(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    selectedLabelTextStyle: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                    unselectedIconTheme: IconThemeData(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                    unselectedLabelTextStyle: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                    destinations: _navItems
                        .map((item) => _buildNavDestination(item, isSmall))
                        .toList(),
                    selectedIndex: _selectedIndex,
                    onDestinationSelected: (index) {
                      setState(() => _selectedIndex = index);
                    },
                    labelType: isExtended
                        ? NavigationRailLabelType.none
                        : NavigationRailLabelType.all,
                    trailing: IconButton(
                      tooltip: 'Exit',
                      icon: const FaIcon(FontAwesomeIcons.rightFromBracket),
                      onPressed: () async {
                        SystemSound.play(SystemSoundType.alert);
                        await AppDialogs.handleExit(context);
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );
    });
  }

  Widget _buildAnimatedCustomButton({
    required IconData icon,
    required double popoverHeight,
    required double popoverWidth,
    required List<Widget> children,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary.withOpacity(0.1),
            Theme.of(context).colorScheme.secondary.withOpacity(0.05),
        ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: RoundCustomButton(
        icon: icon,
        popoverHeight: popoverHeight,
        popoverWidth: popoverWidth,
        children: children,
      ),
    );
  }

  Widget _buildAnimatedCustomButton2({
    required IconData icon,
    required List<Widget> children,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary.withOpacity(0.1),
            Theme.of(context).colorScheme.secondary.withOpacity(0.05),
        ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: RoundCustomButton2(
        icon: icon,
        children: children,
      ),
    );
  }

  Widget _buildErrorState(TextTheme textTheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Text(
        'Unable to load the ayah of the day. Please refresh to try again.',
        style: textTheme.bodyMedium,
      ),
    );
  }
}

class QuranSearchDelegate extends SearchDelegate {
  final qsearch.Search offlineSearch;
  final void Function(String surahName, int ayahNo) onSelect;

  QuranSearchDelegate({required this.offlineSearch, required this.onSelect});

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () => query = '',
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, ''),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return FutureBuilder<List<search_models.Aya>>(
      future: offlineSearch.searchByWord(query.trim()),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final results = snapshot.data!;
        if (results.isEmpty) {
          return Center(child: Text('No matches for "$query"'));
        }
        return ListView.builder(
          itemCount: results.length,
          itemBuilder: (context, index) {
            final aya = results[index];
            return ListTile(
              title: Text(aya.text, textAlign: TextAlign.right),
              subtitle: Text('Surah: ${aya.surah ?? ''}  •  Ayah: ${aya.num}'),
              onTap: () {
                close(context, aya.text);
                onSelect(aya.surah ?? '', aya.num);
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.isEmpty) {
      return const Center(child: Text('Search any word'));
    }
    return FutureBuilder<List<search_models.Aya>>(
      future: offlineSearch.searchByWord(query.trim()),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final results = snapshot.data!;
        return ListView.builder(
          itemCount: results.length.clamp(0, 20),
          itemBuilder: (context, index) {
            final aya = results[index];
            return ListTile(
              title: Text(aya.text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right),
              subtitle: Text('Surah: ${aya.surah ?? ''}'),
              onTap: () {
                close(context, null);
                onSelect(aya.surah ?? '', aya.num);
              },
            );
          },
        );
      },
    );
  }
}

extension on _HomeScreenState {
  AppBar _buildFuturisticAppBar(BuildContext context, bool isSmall,
      bool isCompact, Widget searchButton) {
    final theme = Theme.of(context);
    
    return AppBar(
      backgroundColor: theme.colorScheme.surface.withOpacity(0.95),
      elevation: 0,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.topRight,
            colors: [
              theme.colorScheme.surface.withOpacity(0.98),
              theme.colorScheme.surfaceVariant.withOpacity(0.9),
            ],
          ),
          border: Border(
            bottom: BorderSide(
              color: theme.dividerColor.withOpacity(0.1),
              width: 1,
            ),
          ),
        ),
      ),
      title: HeaderText(size: isCompact ? 20 : 30),
      actions: [
        searchButton,
        _buildAnimatedCustomButton(
          icon: FontAwesomeIcons.headphones,
          popoverHeight: 300,
          popoverWidth: 280,
          children: _buildReciterPopover(context),
        ),
        _buildAnimatedCustomButton(
          icon: FontAwesomeIcons.bell,
          popoverHeight: 340,
          popoverWidth: 280,
          children: _buildNotificationPopover(context),
        ),
        SizedBox(width: isSmall ? 80 : 120),
        if (!isSmall)
          _buildAnimatedCustomButton2(
            icon: FontAwesomeIcons.a,
            children: [
              MItems(
                  text: 'Donate on Patreon',
                  pressed: () {
                    launchUrl(Uri.parse(
                        'https://www.patreon.com/join/kherld/checkout?ru=undefined'));
                    Get.back();
                  }),
              MItems(
                  text: 'Bug Report',
                  pressed: () {
                    launchUrl(Uri.parse(
                        'https://github.com/kherld-hussein/quran_hadith/issues/'));
                    Get.back();
                  }),
              MItems(
                  text: 'Feature Request',
                  pressed: () {
                    launchUrl(Uri.parse(
                        'https://github.com/kherld-hussein/quran_hadith/issues/'));
                    Get.back();
                  }),
              MItems(
                  text: 'About',
                  pressed: () {
                    Get.back();
                    about.showAboutDialog();
                  }),
            ],
          ),
      ],
      leading: Padding(
        padding: const EdgeInsets.only(left: 15.0, top: 5.0),
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.primary,
                theme.colorScheme.secondary,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withOpacity(0.3),
                blurRadius: 12,
                spreadRadius: 2,
              ),
            ],
          ),
          child: CircleAvatar(
            radius: 30,
            backgroundColor: Colors.transparent,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: ImageIcon(
                const AssetImage('assets/images/Logo.png'),
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedNavigationRail(BuildContext context, bool isSmall) {
    return LayoutBuilder(builder: (context, constraints) {
      return SingleChildScrollView(
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: IntrinsicHeight(
            child: ValueListenableBuilder<bool>(
              valueListenable: _isExtended,
              builder: (context, isExtended, child) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  decoration: BoxDecoration(
                    border: Border(
                      right: BorderSide(
                        color: Theme.of(context).dividerColor.withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                  ),
                  child: NavigationRail(
                    extended: isExtended,
                    backgroundColor: Theme.of(context).colorScheme.surface,
                    selectedIconTheme: IconThemeData(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    selectedLabelTextStyle: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                    unselectedIconTheme: IconThemeData(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                    unselectedLabelTextStyle: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                    destinations: _HomeScreenState._navItems
                        .map((item) => _buildNavDestination(item, isSmall))
                        .toList(),
                    selectedIndex: _selectedIndex,
                    onDestinationSelected: (index) {
                      setState(() => _selectedIndex = index);
                    },
                    labelType: isExtended
                        ? NavigationRailLabelType.none
                        : NavigationRailLabelType.all,
                    trailing: IconButton(
                      tooltip: 'Exit',
                      icon: const FaIcon(FontAwesomeIcons.rightFromBracket),
                      onPressed: () async {
                        SystemSound.play(SystemSoundType.alert);
                        await AppDialogs.handleExit(context);
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );
    });
  }

  Widget _buildAnimatedCustomButton({
    required IconData icon,
    required double popoverHeight,
    required double popoverWidth,
    required List<Widget> children,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary.withOpacity(0.1),
            Theme.of(context).colorScheme.secondary.withOpacity(0.05),
        ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: RoundCustomButton(
        icon: icon,
        popoverHeight: popoverHeight,
        popoverWidth: popoverWidth,
        children: children,
      ),
    );
  }

  Widget _buildAnimatedCustomButton2({
    required IconData icon,
    required List<Widget> children,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary.withOpacity(0.1),
            Theme.of(context).colorScheme.secondary.withOpacity(0.05),
        ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: RoundCustomButton2(
        icon: icon,
        children: children,
      ),
    );
  }

  Widget _buildErrorState(TextTheme textTheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Text(
        'Unable to load the ayah of the day. Please refresh to try again.',
        style: textTheme.bodyMedium,
      ),
    );
  }
}
