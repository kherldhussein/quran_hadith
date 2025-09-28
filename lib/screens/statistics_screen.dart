import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:quran_hadith/database/database_service.dart';
import 'package:quran_hadith/database/hive_adapters.dart';
import 'package:fl_chart/fl_chart.dart';

/// Statistics and analytics dashboard
class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({Key? key}) : super(key: key);

  @override
  _StatisticsScreenState createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _stats = {};
  String _timeRange = '7days'; // 7days, 30days, all

  @override
  void initState() {
    super.initState();
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

      // Calculate statistics
      _stats = {
        'totalReadingSessions': readingHistory.length,
        'totalListeningSessions': listeningHistory.length,
        'totalBookmarks': bookmarks.length,
        'totalNotes': studyNotes.length,
        'totalReadingTime': _calculateTotalTime(readingHistory),
        'totalListeningTime': _calculateTotalTime(listeningHistory, isListening: true),
        'uniqueSurahsRead': _calculateUniqueSurahs(readingHistory),
        'uniqueSurahsListened': _calculateUniqueSurahs(listeningHistory, isListening: true),
        'averageSessionDuration': _calculateAverageSessionDuration(readingHistory),
        'readingStreak': _calculateStreak(readingHistory),
        'favoriteReciter': _calculateFavoriteReciter(listeningHistory),
        'mostReadSurah': _calculateMostReadSurah(readingHistory),
        'weeklyActivity': _calculateWeeklyActivity(readingHistory, listeningHistory),
        'progressByJuz': _calculateProgressByJuz(readingHistory),
        'lastRead': lastRead,
        'lastListened': lastListened,
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

  int _calculateUniqueSurahs(List<dynamic> history, {bool isListening = false}) {
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
    final total = history.fold<int>(0, (sum, item) => sum + item.totalTimeSpentSeconds);
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

  List<Map<String, dynamic>> _calculateWeeklyActivity(
    List<ReadingProgress> readingHistory,
    List<ListeningProgress> listeningHistory,
  ) {
    final now = DateTime.now();
    final weeklyData = List.generate(7, (index) {
      final date = now.subtract(Duration(days: 6 - index));
      return {
        'date': date,
        'day': _getDayName(date.weekday),
        'reading': 0,
        'listening': 0,
      };
    });

    for (final item in readingHistory) {
      final dayIndex = 6 - now.difference(item.lastReadAt).inDays;
      if (dayIndex >= 0 && dayIndex < 7) {
        weeklyData[dayIndex]['reading'] = (weeklyData[dayIndex]['reading'] as int) + (item.totalTimeSpentSeconds ~/ 60);
      }
    }

    for (final item in listeningHistory) {
      final dayIndex = 6 - now.difference(item.lastListenedAt).inDays;
      if (dayIndex >= 0 && dayIndex < 7) {
        weeklyData[dayIndex]['listening'] = (weeklyData[dayIndex]['listening'] as int) + (item.totalListenTimeSeconds ~/ 60);
      }
    }

    return weeklyData;
  }

  Map<int, int> _calculateProgressByJuz(List<ReadingProgress> history) {
    final juzProgress = <int, int>{};
    for (var i = 1; i <= 30; i++) {
      juzProgress[i] = 0;
    }

    // Simplified: Would need actual surah-to-juz mapping
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
          _buildOverviewCards(theme),
          const SizedBox(height: 24),
          _buildLastActivityCards(theme),
          const SizedBox(height: 24),
          _buildWeeklyActivityChart(theme),
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
                FaIcon(FontAwesomeIcons.chartLine, color: theme.colorScheme.primary),
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
        DropdownButton<String>(
          value: _timeRange,
          items: const [
            DropdownMenuItem(value: '7days', child: Text('Last 7 days')),
            DropdownMenuItem(value: '30days', child: Text('Last 30 days')),
            DropdownMenuItem(value: 'all', child: Text('All time')),
          ],
          onChanged: (value) {
            setState(() => _timeRange = value!);
            _loadStatistics();
          },
        ),
      ],
    );
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      FaIcon(FontAwesomeIcons.bookOpen, color: Colors.blue, size: 20),
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      FaIcon(FontAwesomeIcons.headphones, color: Colors.green, size: 20),
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
    // Convert reciter code to readable name
    final reciterNames = {
      'ar.alafasy': 'Mishary Al-Afasy',
      'ar.abdulbasit': 'Abdul Basit',
      'ar.minshawi': 'Mohamed Siddiq El-Minshawi',
      'ar.husary': 'Mahmoud Khalil Al-Hussary',
    };
    return reciterNames[reciter] ?? reciter;
  }

  Widget _buildWeeklyActivityChart(ThemeData theme) {
    final weeklyActivity = _stats['weeklyActivity'] as List<Map<String, dynamic>>? ?? [];

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
                        style: TextStyle(color: theme.textTheme.bodySmall?.color),
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
                                if (value.toInt() >= 0 && value.toInt() < weeklyActivity.length) {
                                  return Text(
                                    weeklyActivity[value.toInt()]['day'],
                                    style: const TextStyle(fontSize: 12),
                                  );
                                }
                                return const Text('');
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 40,
                            ),
                          ),
                          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        borderData: FlBorderData(show: false),
                        barGroups: weeklyActivity.asMap().entries.map((entry) {
                          return BarChartGroupData(
                            x: entry.key,
                            barRods: [
                              BarChartRodData(
                                toY: (entry.value['reading'] + entry.value['listening']).toDouble(),
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

  Widget _buildDetailedStats(ThemeData theme) {
    final mostRead = _stats['mostReadSurah'] as Map<String, int>? ?? {'number': 0, 'count': 0};

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
            _buildStatRow('Unique Surahs Read', '${_stats['uniqueSurahsRead'] ?? 0}/114', theme),
            _buildStatRow('Unique Surahs Listened', '${_stats['uniqueSurahsListened'] ?? 0}/114', theme),
            _buildStatRow('Most Read Surah', 'Surah ${mostRead['number']} (${mostRead['count']} times)', theme),
            _buildStatRow('Favorite Reciter', _stats['favoriteReciter'] ?? 'N/A', theme),
            _buildStatRow('Total Study Notes', '${_stats['totalNotes'] ?? 0}', theme),
            _buildStatRow('Average Session', _formatDuration(_stats['averageSessionDuration'] ?? 0), theme),
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
          Text(label, style: TextStyle(color: theme.textTheme.bodyMedium?.color)),
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
