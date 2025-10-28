import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:quran_hadith/database/database_service.dart';
import 'package:quran_hadith/database/hive_adapters.dart';
import 'package:quran_hadith/services/analytics_service.dart';
import 'package:fl_chart/fl_chart.dart';

/// Statistics and analytics dashboard
class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  _StatisticsScreenState createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _stats = {};
  String _timeRange = '7days'; // 7days, 30days, all
  late DateTime _customStartDate;
  late DateTime _customEndDate;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _customEndDate = now;
    _customStartDate = now.subtract(const Duration(days: 7));
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    setState(() => _isLoading = true);

    try {
      final readingHistory = database.getReadingHistory();
      final listeningHistory = database.getListeningHistory();
      final bookmarks = database.getAllBookmarks();
      final studyNotes = database.getAllStudyNotes();
      final lastRead = database.getLastReadingProgress();
      final lastListened = database.getLastListeningProgress();

      _stats = {
        'totalReadingSessions': readingHistory.length,
        'totalListeningSessions': listeningHistory.length,
        'totalBookmarks': bookmarks.length,
        'totalNotes': studyNotes.length,
        'totalReadingTime': _calculateTotalTime(readingHistory),
        'totalListeningTime':
            _calculateTotalTime(listeningHistory, isListening: true),
        'uniqueSurahsRead': _calculateUniqueSurahs(readingHistory),
        'uniqueSurahsListened':
            _calculateUniqueSurahs(listeningHistory, isListening: true),
        'averageSessionDuration':
            _calculateAverageSessionDuration(readingHistory),
        'readingStreak': _calculateStreak(readingHistory),
        'favoriteReciter': _calculateFavoriteReciter(listeningHistory),
        'mostReadSurah': _calculateMostReadSurah(readingHistory),
        'weeklyActivity':
            _calculateWeeklyActivity(readingHistory, listeningHistory),
        'progressByJuz': _calculateProgressByJuz(readingHistory),
        'lastRead': lastRead,
        'lastListened': lastListened,
        'listeningTimeByReciter':
            _calculateListeningTimeByReciter(listeningHistory),
        'mostListenedSurah': _calculateMostListenedSurah(listeningHistory),
      };
    } catch (e) {
      debugPrint('Error loading statistics: $e');
    }

    setState(() => _isLoading = false);
  }

  int _calculateTotalTime(List<dynamic> history, {bool isListening = false}) {
    return history.fold<int>(0, (sum, item) {
      if (isListening) {
        return sum + (item as ListeningProgress).totalListenTimeSeconds;
      } else {
        return sum + (item as ReadingProgress).totalTimeSpentSeconds;
      }
    });
  }

  int _calculateUniqueSurahs(List<dynamic> history,
      {bool isListening = false}) {
    final surahs = history.map((item) {
      if (isListening) {
        return (item as ListeningProgress).surahNumber;
      } else {
        return (item as ReadingProgress).surahNumber;
      }
    }).toSet();
    return surahs.length;
  }

  int _calculateAverageSessionDuration(List<ReadingProgress> history) {
    if (history.isEmpty) return 0;
    final total =
        history.fold<int>(0, (sum, item) => sum + item.totalTimeSpentSeconds);
    return total ~/ history.length;
  }

  int _calculateStreak(List<ReadingProgress> history) {
    if (history.isEmpty) return 0;

    final sortedHistory = List<ReadingProgress>.from(history)
      ..sort((a, b) => b.lastReadAt.compareTo(a.lastReadAt));

    int streak = 0;
    DateTime? lastDate;

    for (final item in sortedHistory) {
      final date = DateTime(
        item.lastReadAt.year,
        item.lastReadAt.month,
        item.lastReadAt.day,
      );

      if (lastDate == null) {
        streak = 1;
        lastDate = date;
      } else {
        final difference = lastDate.difference(date).inDays;
        if (difference == 1) {
          streak++;
          lastDate = date;
        } else if (difference > 1) {
          break;
        }
      }
    }

    return streak;
  }

  String _calculateFavoriteReciter(List<ListeningProgress> history) {
    if (history.isEmpty) return 'N/A';

    final reciterCounts = <String, int>{};
    for (final item in history) {
      reciterCounts[item.reciter] = (reciterCounts[item.reciter] ?? 0) + 1;
    }

    var maxCount = 0;
    var favoriteReciter = 'N/A';
    reciterCounts.forEach((reciter, count) {
      if (count > maxCount) {
        maxCount = count;
        favoriteReciter = reciter;
      }
    });

    return favoriteReciter;
  }

  Map<String, int> _calculateMostReadSurah(List<ReadingProgress> history) {
    if (history.isEmpty) return {'number': 0, 'count': 0};

    final surahCounts = <int, int>{};
    for (final item in history) {
      surahCounts[item.surahNumber] = (surahCounts[item.surahNumber] ?? 0) + 1;
    }

    var maxCount = 0;
    var mostReadSurah = 0;
    surahCounts.forEach((surah, count) {
      if (count > maxCount) {
        maxCount = count;
        mostReadSurah = surah;
      }
    });

    return {'number': mostReadSurah, 'count': maxCount};
  }

  /// C1 Enhancement: Calculate listening time breakdown by reciter
  Map<String, int> _calculateListeningTimeByReciter(
    List<ListeningProgress> history,
  ) {
    if (history.isEmpty) return {};

    final reciterTime = <String, int>{};
    for (final item in history) {
      reciterTime[item.reciter] =
          (reciterTime[item.reciter] ?? 0) + item.totalListenTimeSeconds;
    }

    return reciterTime;
  }

  /// C1 Enhancement: Calculate most listened surah
  Map<String, dynamic> _calculateMostListenedSurah(
    List<ListeningProgress> history,
  ) {
    if (history.isEmpty) return {'number': 0, 'count': 0, 'time': 0};

    final surahCounts = <int, int>{};
    final surahTime = <int, int>{};

    for (final item in history) {
      surahCounts[item.surahNumber] = (surahCounts[item.surahNumber] ?? 0) + 1;
      surahTime[item.surahNumber] =
          (surahTime[item.surahNumber] ?? 0) + item.totalListenTimeSeconds;
    }

    var maxCount = 0;
    var mostListenedSurah = 0;
    surahCounts.forEach((surah, count) {
      if (count > maxCount) {
        maxCount = count;
        mostListenedSurah = surah;
      }
    });

    return {
      'number': mostListenedSurah,
      'count': maxCount,
      'time': surahTime[mostListenedSurah] ?? 0,
    };
  }

  List<Map<String, dynamic>> _calculateWeeklyActivity(
    List<ReadingProgress> readingHistory,
    List<ListeningProgress> listeningHistory,
  ) {
    final now = DateTime.now();
    final weeklyData = List.generate(7, (index) {
      final date = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: 6 - index));

      return {
        'date': date,
        'day': _getDayName(date.weekday),
        'dayShort': _getDayShort(date),
        'reading': 0,
        'listening': 0,
      };
    });

    for (final item in readingHistory) {
      final itemDate = DateTime(
        item.lastReadAt.year,
        item.lastReadAt.month,
        item.lastReadAt.day,
      );

      for (int i = 0; i < weeklyData.length; i++) {
        final weekDate = weeklyData[i]['date'] as DateTime;
        if (itemDate.year == weekDate.year &&
            itemDate.month == weekDate.month &&
            itemDate.day == weekDate.day) {
          weeklyData[i]['reading'] = (weeklyData[i]['reading'] as int) +
              (item.totalTimeSpentSeconds ~/ 60);
          break;
        }
      }
    }

    for (final item in listeningHistory) {
      final itemDate = DateTime(
        item.lastListenedAt.year,
        item.lastListenedAt.month,
        item.lastListenedAt.day,
      );

      for (int i = 0; i < weeklyData.length; i++) {
        final weekDate = weeklyData[i]['date'] as DateTime;
        if (itemDate.year == weekDate.year &&
            itemDate.month == weekDate.month &&
            itemDate.day == weekDate.day) {
          weeklyData[i]['listening'] = (weeklyData[i]['listening'] as int) +
              (item.totalListenTimeSeconds ~/ 60);
          break;
        }
      }
    }

    debugPrint('📊 Weekly Activity Data:');
    for (final day in weeklyData) {
      debugPrint(
        '  ${day['dayShort']}: Reading ${day['reading']}min, Listening ${day['listening']}min',
      );
    }

    return weeklyData;
  }

  Map<int, int> _calculateProgressByJuz(List<ReadingProgress> history) {
    final juzProgress = <int, int>{};
    for (var i = 1; i <= 30; i++) {
      juzProgress[i] = 0;
    }

    for (final item in history) {
      final juz = ((item.surahNumber - 1) ~/ 4) + 1; // Rough approximation
      juzProgress[juz] = (juzProgress[juz] ?? 0) + 1;
    }

    return juzProgress;
  }

  String _getDayName(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }

  String _getDayShort(DateTime date) {
    final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return dayNames[date.weekday - 1];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: theme.appBarTheme.backgroundColor,
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _buildHeader(theme),
          const SizedBox(height: 24),
          _buildGamificationDashboard(theme),
          const SizedBox(height: 24),
          _buildOverviewCards(theme),
          const SizedBox(height: 24),
          _buildCompletionProgress(theme),
          const SizedBox(height: 24),
          _buildPlaybackSpeedStats(theme),
          const SizedBox(height: 24),
          _buildLastActivityCards(theme),
          const SizedBox(height: 24),
          _buildWeeklyActivityChart(theme),
          const SizedBox(height: 24),
          _buildListeningTimeBreakdown(theme),
          const SizedBox(height: 24),
          _buildMostListenedSurah(theme),
          const SizedBox(height: 24),
          _buildDetailedStats(theme),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                FaIcon(FontAwesomeIcons.chartLine,
                    color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Text(
                  'Statistics',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Your Quran reading journey',
              style: TextStyle(
                color: theme.textTheme.bodySmall?.color,
              ),
            ),
          ],
        ),
        PopupMenuButton<String>(
          onSelected: (value) {
            setState(() => _timeRange = value);
            if (value != 'custom') {
              _loadStatistics();
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: '7days', child: Text('Last 7 days')),
            const PopupMenuItem(value: '30days', child: Text('Last 30 days')),
            const PopupMenuItem(value: 'all', child: Text('All time')),
            const PopupMenuDivider(),
            const PopupMenuItem(value: 'custom', child: Text('Custom Range')),
          ],
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(color: theme.dividerColor),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                FaIcon(
                  FontAwesomeIcons.calendar,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  _timeRange == 'custom'
                      ? '${_customStartDate.toString().split(' ')[0]} to ${_customEndDate.toString().split(' ')[0]}'
                      : _getTimeRangeLabel(),
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_timeRange == 'custom') ...[
          const SizedBox(width: 12),
          TextButton.icon(
            icon: const FaIcon(FontAwesomeIcons.penToSquare, size: 14),
            label: const Text('Edit Range'),
            onPressed: () => _showDateRangePicker(context, theme),
          ),
        ],
      ],
    );
  }

  String _getTimeRangeLabel() {
    switch (_timeRange) {
      case '7days':
        return 'Last 7 days';
      case '30days':
        return 'Last 30 days';
      case 'all':
        return 'All time';
      default:
        return 'Custom Range';
    }
  }

  Widget _buildGamificationDashboard(ThemeData theme) {
    final level = analyticsService.getUserLevel();
    final xp = analyticsService.getExperiencePoints();
    final xpForNext = analyticsService.getExperienceForNextLevel(level);
    final achievements = analyticsService.getUnlockedAchievements();

    return Card(
      elevation: 2,
      color: theme.colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Level and XP Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Level',
                      style: TextStyle(
                        fontSize: 14,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        FaIcon(
                          FontAwesomeIcons.star,
                          size: 24,
                          color: Colors.amber,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Level $level',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Experience Points',
                      style: TextStyle(
                        fontSize: 14,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$xp / $xpForNext XP',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            // XP Progress Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: (xp / xpForNext).clamp(0.0, 1.0),
                minHeight: 12,
                backgroundColor: theme.colorScheme.surfaceVariant,
                valueColor: AlwaysStoppedAnimation<Color>(
                  theme.colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Achievements Section
            Text(
              'Achievements (${achievements.length})',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            if (achievements.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'Keep reading and listening to unlock achievements!',
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              )
            else
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: achievements.entries.map((entry) {
                  final title = (entry.value as Map)['title'] ?? '';
                  final emoji =
                      title.replaceAll(RegExp(r'[^🎯📚🎵🔥📖]'), '').isNotEmpty
                          ? title.replaceAll(RegExp(r'[^🎯📚🎵🔥📖]'), '')
                          : '✨';
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: theme.colorScheme.primary.withOpacity(0.5),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          emoji,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            title
                                .replaceAll(RegExp(r'[🎯📚🎵🔥📖]'), '')
                                .trim(),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDateRangePicker(
      BuildContext context, ThemeData theme) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(
        start: _customStartDate,
        end: _customEndDate,
      ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: theme.colorScheme.primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _customStartDate = picked.start;
        _customEndDate = picked.end;
        _timeRange = 'custom';
      });
      _loadStatistics();
    }
  }

  Widget _buildOverviewCards(ThemeData theme) {
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          title: 'Reading Time',
          value: _formatDuration(_stats['totalReadingTime'] ?? 0),
          icon: FontAwesomeIcons.clock,
          color: Colors.blue,
          theme: theme,
        ),
        _buildStatCard(
          title: 'Listening Time',
          value: _formatDuration(_stats['totalListeningTime'] ?? 0),
          icon: FontAwesomeIcons.headphones,
          color: Colors.green,
          theme: theme,
        ),
        _buildStatCard(
          title: 'Current Streak',
          value: '${_stats['readingStreak'] ?? 0} days',
          icon: FontAwesomeIcons.fire,
          color: Colors.orange,
          theme: theme,
        ),
        _buildStatCard(
          title: 'Bookmarks',
          value: '${_stats['totalBookmarks'] ?? 0}',
          icon: FontAwesomeIcons.bookmark,
          color: Colors.purple,
          theme: theme,
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required ThemeData theme,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                FaIcon(icon, color: color, size: 20),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: FaIcon(icon, color: color, size: 16),
                ),
              ],
            ),
            const Spacer(),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: theme.textTheme.bodySmall?.color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLastActivityCards(ThemeData theme) {
    final lastRead = _stats['lastRead'] as ReadingProgress?;
    final lastListened = _stats['lastListened'] as ListeningProgress?;

    return Row(
      children: [
        Expanded(
          child: Card(
            elevation: 2,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const FaIcon(FontAwesomeIcons.bookOpen,
                          color: Colors.blue, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        'Last Read',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (lastRead != null) ...[
                    Text(
                      'Surah ${lastRead.surahNumber}, Ayah ${lastRead.ayahNumber}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formatTimeAgo(lastRead.lastReadAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.textTheme.bodySmall?.color,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Total time: ${_formatDuration(lastRead.totalTimeSpentSeconds)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.textTheme.bodySmall?.color,
                      ),
                    ),
                  ] else ...[
                    Text(
                      'No reading history yet',
                      style: TextStyle(
                        color: theme.textTheme.bodySmall?.color,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Card(
            elevation: 2,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const FaIcon(FontAwesomeIcons.headphones,
                          color: Colors.green, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        'Last Listened',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (lastListened != null) ...[
                    Text(
                      'Surah ${lastListened.surahNumber}, Ayah ${lastListened.ayahNumber}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formatTimeAgo(lastListened.lastListenedAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.textTheme.bodySmall?.color,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Reciter: ${_formatReciterName(lastListened.reciter)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.textTheme.bodySmall?.color,
                      ),
                    ),
                  ] else ...[
                    Text(
                      'No listening history yet',
                      style: TextStyle(
                        color: theme.textTheme.bodySmall?.color,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }

  String _formatReciterName(String reciter) {
    final reciterNames = {
      'ar.alafasy': 'Mishary Al-Afasy',
      'ar.abdulbasit': 'Abdul Basit',
      'ar.minshawi': 'Mohamed Siddiq El-Minshawi',
      'ar.husary': 'Mahmoud Khalil Al-Hussary',
    };
    return reciterNames[reciter] ?? reciter;
  }

  Widget _buildWeeklyActivityChart(ThemeData theme) {
    final weeklyActivity =
        _stats['weeklyActivity'] as List<Map<String, dynamic>>? ?? [];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Weekly Activity',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: weeklyActivity.isEmpty
                  ? Center(
                      child: Text(
                        'No activity data available',
                        style:
                            TextStyle(color: theme.textTheme.bodySmall?.color),
                      ),
                    )
                  : BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: _getMaxActivityValue(weeklyActivity).toDouble(),
                        barTouchData: BarTouchData(enabled: true),
                        titlesData: FlTitlesData(
                          show: true,
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                if (value.toInt() >= 0 &&
                                    value.toInt() < weeklyActivity.length) {
                                  return Text(
                                    weeklyActivity[value.toInt()]['day'],
                                    style: const TextStyle(fontSize: 12),
                                  );
                                }
                                return const Text('');
                              },
                            ),
                          ),
                          leftTitles: const AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 40,
                            ),
                          ),
                          topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                        ),
                        borderData: FlBorderData(show: false),
                        barGroups: weeklyActivity.asMap().entries.map((entry) {
                          return BarChartGroupData(
                            x: entry.key,
                            barRods: [
                              BarChartRodData(
                                toY: (entry.value['reading'] +
                                        entry.value['listening'])
                                    .toDouble(),
                                color: theme.colorScheme.primary,
                                width: 16,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  /// C1 Enhancement: Build listening time breakdown by reciter
  Widget _buildListeningTimeBreakdown(ThemeData theme) {
    final listeningByReciter =
        _stats['listeningTimeByReciter'] as Map<String, int>? ?? {};

    if (listeningByReciter.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                FaIcon(
                  FontAwesomeIcons.headphones,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  'Listening Time by Reciter',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...listeningByReciter.entries.map((entry) {
              final reciterName = _formatReciterName(entry.key);
              final duration = _formatDuration(entry.value);
              final totalTime = _stats['totalListeningTime'] as int? ?? 1;
              final percentage =
                  ((entry.value / totalTime) * 100).toStringAsFixed(1);

              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          reciterName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '$duration ($percentage%)',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: entry.value / totalTime,
                        minHeight: 8,
                        backgroundColor: theme
                            .colorScheme.surfaceContainerHighest
                            .withOpacity(0.3),
                        valueColor: AlwaysStoppedAnimation(
                          theme.colorScheme.primary.withOpacity(0.8),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  /// C1 Enhancement: Build most listened surah card
  Widget _buildMostListenedSurah(ThemeData theme) {
    final mostListened = _stats['mostListenedSurah'] as Map<String, dynamic>? ??
        {'number': 0, 'count': 0, 'time': 0};
    final surahNumber = mostListened['number'] as int? ?? 0;

    if (surahNumber == 0) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              FaIcon(
                FontAwesomeIcons.play,
                color: theme.colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Most Listened Surah',
                    style: TextStyle(
                      fontSize: 14,
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'No listening history yet',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    final count = mostListened['count'] as int? ?? 0;
    final time = mostListened['time'] as int? ?? 0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Most Listened Surah',
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Surah $surahNumber',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$count times • ${_formatDuration(time)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
            FaIcon(
              FontAwesomeIcons.play,
              color: theme.colorScheme.primary.withOpacity(0.3),
              size: 60,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletionProgress(ThemeData theme) {
    final readSurahs = _stats['uniqueSurahsRead'] as int? ?? 0;
    final listenedSurahs = _stats['uniqueSurahsListened'] as int? ?? 0;
    const totalSurahs = 114;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                FaIcon(
                  FontAwesomeIcons.bookmark,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  'Completion Progress',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'Reading Progress',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: readSurahs / totalSurahs,
                minHeight: 12,
                backgroundColor:
                    theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                valueColor:
                    AlwaysStoppedAnimation(Colors.blue.withOpacity(0.8)),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Read $readSurahs / $totalSurahs Surahs (${(readSurahs / totalSurahs * 100).toStringAsFixed(1)}%)',
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Listening Progress',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: listenedSurahs / totalSurahs,
                minHeight: 12,
                backgroundColor:
                    theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                valueColor:
                    AlwaysStoppedAnimation(Colors.green.withOpacity(0.8)),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Listened $listenedSurahs / $totalSurahs Surahs (${(listenedSurahs / totalSurahs * 100).toStringAsFixed(1)}%)',
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaybackSpeedStats(ThemeData theme) {
    final listeningHistory = database.getListeningHistory();

    if (listeningHistory.isEmpty) {
      return const SizedBox.shrink();
    }

    final speeds = listeningHistory.map((h) => h.playbackSpeed).toList();
    final avgSpeed = speeds.reduce((a, b) => a + b) / speeds.length;
    final maxSpeed = speeds.reduce((a, b) => a > b ? a : b);
    final minSpeed = speeds.reduce((a, b) => a < b ? a : b);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                FaIcon(
                  FontAwesomeIcons.faucetDrip,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  'Playback Speed Statistics',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Average',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    Text(
                      '${avgSpeed.toStringAsFixed(2)}x',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Fastest',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    Text(
                      '${maxSpeed.toStringAsFixed(2)}x',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Slowest',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    Text(
                      '${minSpeed.toStringAsFixed(2)}x',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedStats(ThemeData theme) {
    final mostRead = _stats['mostReadSurah'] as Map<String, int>? ??
        {'number': 0, 'count': 0};

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Detailed Statistics',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            _buildStatRow('Unique Surahs Read',
                '${_stats['uniqueSurahsRead'] ?? 0}/114', theme),
            _buildStatRow('Unique Surahs Listened',
                '${_stats['uniqueSurahsListened'] ?? 0}/114', theme),
            _buildStatRow(
                'Most Read Surah',
                'Surah ${mostRead['number']} (${mostRead['count']} times)',
                theme),
            _buildStatRow(
                'Favorite Reciter', _stats['favoriteReciter'] ?? 'N/A', theme),
            _buildStatRow(
                'Total Study Notes', '${_stats['totalNotes'] ?? 0}', theme),
            _buildStatRow('Average Session',
                _formatDuration(_stats['averageSessionDuration'] ?? 0), theme),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(color: theme.textTheme.bodyMedium?.color)),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  int _getMaxActivityValue(List<Map<String, dynamic>> weeklyActivity) {
    var max = 0;
    for (final day in weeklyActivity) {
      final total = (day['reading'] as int) + (day['listening'] as int);
      if (total > max) max = total;
    }
    return max == 0 ? 10 : max;
  }

  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }
}
