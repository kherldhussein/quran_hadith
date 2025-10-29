import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:quran_hadith/services/study_session_service.dart';
import 'package:fl_chart/fl_chart.dart';

/// Widget to display study session timer and statistics
class StudySessionWidget extends StatelessWidget {
  final StudySessionService service;

  const StudySessionWidget({
    super.key,
    required this.service,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: service,
      builder: (context, _) {
        return Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(context),
                const SizedBox(height: 16),
                _buildSessionTimer(context),
                const SizedBox(height: 16),
                _buildDailyProgress(context),
                const SizedBox(height: 16),
                _buildStreakInfo(context),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        FaIcon(
          FontAwesomeIcons.clock,
          color: theme.colorScheme.primary,
          size: 20,
        ),
        const SizedBox(width: 8),
        Text(
          'Study Session',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        const Spacer(),
        IconButton(
          icon: const FaIcon(FontAwesomeIcons.gear, size: 16),
          onPressed: () => _showSettings(context),
        ),
      ],
    );
  }

  Widget _buildSessionTimer(BuildContext context) {
    final theme = Theme.of(context);
    final isActive = service.isSessionActive;
    final currentSeconds = service.currentSessionSeconds;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Current Session',
                style: TextStyle(
                  fontSize: 12,
                  color: theme.textTheme.bodySmall?.color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                service.formatDuration(currentSeconds),
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          _buildSessionControls(context, isActive),
        ],
      ),
    );
  }

  Widget _buildSessionControls(BuildContext context, bool isActive) {
    return Row(
      children: [
        if (!isActive)
          FilledButton.icon(
            onPressed: () => service.startSession(),
            icon: const FaIcon(FontAwesomeIcons.play, size: 14),
            label: const Text('Start'),
          )
        else ...[
          FilledButton.tonalIcon(
            onPressed: () => service.pauseSession(),
            icon: const FaIcon(FontAwesomeIcons.pause, size: 14),
            label: const Text('Pause'),
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            onPressed: () => service.endSession(),
            icon: const FaIcon(FontAwesomeIcons.stop, size: 14),
            label: const Text('End'),
          ),
        ],
      ],
    );
  }

  Widget _buildDailyProgress(BuildContext context) {
    final theme = Theme.of(context);
    final todaySeconds = service.todayReadingSeconds;
    final progress = service.getDailyGoalProgress();
    final goalMet = service.isDailyGoalMet();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Today\'s Reading',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: theme.textTheme.bodyLarge?.color,
              ),
            ),
            Row(
              children: [
                if (goalMet)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FaIcon(
                      FontAwesomeIcons.solidCircleCheck,
                      size: 16,
                      color: Colors.green,
                    ),
                  ),
                Text(
                  service.formatDuration(todaySeconds),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                Text(
                  ' / ${service.dailyGoalMinutes}m',
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.textTheme.bodySmall?.color,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress,
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
          backgroundColor: theme.colorScheme.surfaceContainerHighest,
          valueColor: AlwaysStoppedAnimation<Color>(
            goalMet ? Colors.green : theme.colorScheme.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildStreakInfo(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.secondaryContainer.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                FaIcon(
                  FontAwesomeIcons.fire,
                  color: Colors.orange,
                  size: 24,
                ),
                const SizedBox(height: 4),
                Text(
                  '${service.currentStreak}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Day Streak',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.textTheme.bodySmall?.color,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.tertiaryContainer.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                FaIcon(
                  FontAwesomeIcons.trophy,
                  color: Colors.amber,
                  size: 24,
                ),
                const SizedBox(height: 4),
                Text(
                  '${service.longestStreak}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Best Streak',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.textTheme.bodySmall?.color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => _StudySessionSettings(service: service),
    );
  }
}

/// Settings modal for study session
class _StudySessionSettings extends StatefulWidget {
  final StudySessionService service;

  const _StudySessionSettings({required this.service});

  @override
  State<_StudySessionSettings> createState() => _StudySessionSettingsState();
}

class _StudySessionSettingsState extends State<_StudySessionSettings> {
  late int _dailyGoal;
  late int _breakInterval;
  late bool _breakReminders;

  @override
  void initState() {
    super.initState();
    _dailyGoal = widget.service.dailyGoalMinutes;
    _breakInterval = widget.service.breakReminderInterval;
    _breakReminders = widget.service.showBreakReminders;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Study Session Settings',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 24),

          // Daily goal
          Text(
            'Daily Goal: $_dailyGoal minutes',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          Slider(
            value: _dailyGoal.toDouble(),
            min: 5,
            max: 120,
            divisions: 23,
            label: '$_dailyGoal min',
            onChanged: (value) {
              setState(() => _dailyGoal = value.toInt());
            },
            onChangeEnd: (value) {
              widget.service.setDailyGoal(value.toInt());
            },
          ),
          const SizedBox(height: 16),

          // Break reminders toggle
          SwitchListTile(
            title: const Text('Break Reminders'),
            subtitle: const Text('Get reminders to take breaks'),
            value: _breakReminders,
            onChanged: (value) {
              setState(() => _breakReminders = value);
              widget.service.toggleBreakReminders();
            },
          ),

          if (_breakReminders) ...[
            const SizedBox(height: 8),
            Text(
              'Break Interval: $_breakInterval minutes',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            Slider(
              value: _breakInterval.toDouble(),
              min: 15,
              max: 60,
              divisions: 9,
              label: '$_breakInterval min',
              onChanged: (value) {
                setState(() => _breakInterval = value.toInt());
              },
              onChangeEnd: (value) {
                widget.service.setBreakInterval(value.toInt());
              },
            ),
          ],

          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Done'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Weekly reading chart widget
class WeeklyReadingChart extends StatelessWidget {
  final StudySessionService service;

  const WeeklyReadingChart({
    super.key,
    required this.service,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final weekData = service.getLastWeekData();

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                FaIcon(
                  FontAwesomeIcons.chartColumn,
                  color: theme.colorScheme.primary,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  'This Week',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: _getMaxY(weekData),
                  barGroups: _buildBarGroups(weekData, theme),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= 0 && value.toInt() < weekData.length) {
                            final date = DateTime.parse(weekData[value.toInt()].key);
                            return Text(
                              ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'][date.weekday % 7],
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
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '${value.toInt()}m',
                            style: const TextStyle(fontSize: 11),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 10,
                  ),
                  borderData: FlBorderData(show: false),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _getMaxY(List<MapEntry<String, int>> data) {
    if (data.isEmpty) return 60.0;
    final maxSeconds = data.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    final maxMinutes = (maxSeconds / 60).ceil();
    return (maxMinutes + 10).toDouble(); // Add some padding
  }

  List<BarChartGroupData> _buildBarGroups(List<MapEntry<String, int>> data, ThemeData theme) {
    return List.generate(data.length, (index) {
      final minutes = data[index].value / 60;
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: minutes,
            color: theme.colorScheme.primary,
            width: 16,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ],
      );
    });
  }
}
