import 'package:flutter/material.dart';
import 'package:quran_hadith/services/analytics_service.dart';

/// Analytics dashboard widget showing user engagement metrics
class AnalyticsDashboard extends StatelessWidget {
  const AnalyticsDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final summary = analyticsService.getAnalyticsSummary();
    final engagementScore = analyticsService.getUserEngagementScore();

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.analytics, size: 28),
                const SizedBox(width: 12),
                Text(
                  'Your Statistics',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const Divider(height: 24),

            _buildEngagementScore(context, engagementScore),
            const SizedBox(height: 20),

            _buildMetricsGrid(context, summary),
          ],
        ),
      ),
    );
  }

  Widget _buildEngagementScore(BuildContext context, int score) {
    Color scoreColor;
    String scoreLabel;

    if (score >= 80) {
      scoreColor = Colors.green;
      scoreLabel = 'Excellent';
    } else if (score >= 60) {
      scoreColor = Colors.blue;
      scoreLabel = 'Great';
    } else if (score >= 40) {
      scoreColor = Colors.orange;
      scoreLabel = 'Good';
    } else if (score >= 20) {
      scoreColor = Colors.amber;
      scoreLabel = 'Fair';
    } else {
      scoreColor = Colors.grey;
      scoreLabel = 'Getting Started';
    }

    return Column(
      children: [
        Text(
          'Engagement Level',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 12),
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 120,
              height: 120,
              child: CircularProgressIndicator(
                value: score / 100,
                strokeWidth: 12,
                backgroundColor:
                    Theme.of(context).colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$score',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: scoreColor,
                      ),
                ),
                Text(
                  scoreLabel,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scoreColor,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricsGrid(BuildContext context, Map<String, dynamic> summary) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                context,
                icon: Icons.event,
                label: 'Sessions',
                value: '${summary['totalSessions'] ?? 0}',
                color: Colors.purple,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                context,
                icon: Icons.schedule,
                label: 'Minutes',
                value: '${summary['totalSessionMinutes'] ?? 0}',
                color: Colors.blue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                context,
                icon: Icons.book,
                label: 'Surahs',
                value: '${summary['surahsRead'] ?? 0}',
                color: Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                context,
                icon: Icons.menu_book,
                label: 'Hadiths',
                value: '${summary['hadithsRead'] ?? 0}',
                color: Colors.teal,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                context,
                icon: Icons.bookmark,
                label: 'Bookmarks',
                value: '${summary['bookmarksCreated'] ?? 0}',
                color: Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                context,
                icon: Icons.local_fire_department,
                label: 'Day Streak',
                value: '${summary['consecutiveDays'] ?? 0}',
                color: Colors.deepOrange,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
          ),
        ],
      ),
    );
  }
}

/// Compact analytics widget for drawer or app bar
class CompactAnalytics extends StatelessWidget {
  const CompactAnalytics({super.key});

  @override
  Widget build(BuildContext context) {
    final summary = analyticsService.getAnalyticsSummary();
    final streak = summary['consecutiveDays'] ?? 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.local_fire_department,
            color: streak > 0 ? Colors.deepOrange : Colors.grey,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            '$streak day${streak != 1 ? 's' : ''} streak',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

/// Full analytics screen with detailed breakdown
class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showAnalyticsInfo(context),
            tooltip: 'About Analytics',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const AnalyticsDashboard(),
            const SizedBox(height: 16),
            _buildDetailedBreakdown(context),
            const SizedBox(height: 16),
            _buildResetButton(context),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedBreakdown(BuildContext context) {
    final summary = analyticsService.getAnalyticsSummary();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Detailed Breakdown',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const Divider(height: 24),
            _buildDetailRow(
              context,
              icon: Icons.play_arrow,
              label: 'Audio Plays',
              value: '${summary['audioPlayCount'] ?? 0}',
            ),
            _buildDetailRow(
              context,
              icon: Icons.pause,
              label: 'Audio Pauses',
              value: '${summary['audioPauseCount'] ?? 0}',
            ),
            _buildDetailRow(
              context,
              icon: Icons.search,
              label: 'Searches',
              value: '${summary['searchCount'] ?? 0}',
            ),
            _buildDetailRow(
              context,
              icon: Icons.star,
              label: 'Favorites',
              value: '${summary['favoritesAdded'] ?? 0}',
            ),
            _buildDetailRow(
              context,
              icon: Icons.calendar_today,
              label: 'Total Days Used',
              value: '${summary['totalDaysUsed'] ?? 0}',
            ),
            _buildDetailRow(
              context,
              icon: Icons.sync,
              label: 'Lifecycle Transitions',
              value: '${summary['lifecycleTransitions'] ?? 0}',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildResetButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: OutlinedButton.icon(
        onPressed: () => _confirmReset(context),
        icon: const Icon(Icons.refresh),
        label: const Text('Reset Analytics'),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.red,
          side: const BorderSide(color: Colors.red),
          minimumSize: const Size(double.infinity, 48),
        ),
      ),
    );
  }

  void _confirmReset(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Analytics?'),
        content: const Text(
          'This will permanently delete all your analytics data. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await analyticsService.resetAnalytics();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Analytics reset successfully'),
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  void _showAnalyticsInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About Analytics'),
        content: const SingleChildScrollView(
          child: Text(
            'Your analytics data is stored locally on your device and never transmitted to external servers.\n\n'
            'We track:\n'
            '• Session information\n'
            '• Content engagement (surahs, hadiths read)\n'
            '• Feature usage (bookmarks, favorites, searches)\n'
            '• Audio playback statistics\n\n'
            'This data helps you understand your engagement with the app and track your learning progress.\n\n'
            'You can reset your analytics at any time.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}
