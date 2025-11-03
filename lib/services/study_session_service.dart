import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:convert';
import 'package:quran_hadith/services/notification_service.dart';

/// Service to track study sessions, reading time, and streaks
class StudySessionService extends ChangeNotifier {
  static final StudySessionService _instance = StudySessionService._internal();
  factory StudySessionService() => _instance;
  StudySessionService._internal();

  // Session state
  bool _isSessionActive = false;
  Timer? _sessionTimer;
  Timer? _autoSaveTimer; // Auto-save session data every 30 seconds
  int _currentSessionSeconds = 0;

  // Statistics
  int _todayReadingSeconds = 0;
  int _currentStreak = 0;
  int _longestStreak = 0;
  Map<String, int> _weeklyReadingTime = {}; // date -> seconds
  String? _lastReadDate;

  // Goals
  int _dailyGoalMinutes = 15;
  bool _showBreakReminders = true;
  int _breakReminderInterval = 30; // minutes

  // Getters
  bool get isSessionActive => _isSessionActive;
  int get currentSessionSeconds => _currentSessionSeconds;
  int get todayReadingSeconds => _todayReadingSeconds;
  int get currentStreak => _currentStreak;
  int get longestStreak => _longestStreak;
  Map<String, int> get weeklyReadingTime =>
      Map.unmodifiable(_weeklyReadingTime);
  int get dailyGoalMinutes => _dailyGoalMinutes;
  bool get showBreakReminders => _showBreakReminders;
  int get breakReminderInterval => _breakReminderInterval;

  // Preferences keys
  static const String _keyTodaySeconds = 'study_today_seconds';
  static const String _keyCurrentStreak = 'study_current_streak';
  static const String _keyLongestStreak = 'study_longest_streak';
  static const String _keyWeeklyTime = 'study_weekly_time';
  static const String _keyLastReadDate = 'study_last_read_date';
  static const String _keyDailyGoal = 'study_daily_goal_minutes';
  static const String _keyBreakReminders = 'study_break_reminders';
  static const String _keyBreakInterval = 'study_break_interval';
  static const String _keyLastCleanupDate = 'study_last_cleanup_date';

  /// Initialize the study session service
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();

    _todayReadingSeconds = prefs.getInt(_keyTodaySeconds) ?? 0;
    _currentStreak = prefs.getInt(_keyCurrentStreak) ?? 0;
    _longestStreak = prefs.getInt(_keyLongestStreak) ?? 0;
    _lastReadDate = prefs.getString(_keyLastReadDate);
    _dailyGoalMinutes = prefs.getInt(_keyDailyGoal) ?? 15;
    _showBreakReminders = prefs.getBool(_keyBreakReminders) ?? true;
    _breakReminderInterval = prefs.getInt(_keyBreakInterval) ?? 30;

    final weeklyJson = prefs.getString(_keyWeeklyTime);
    if (weeklyJson != null) {
      _weeklyReadingTime = Map<String, int>.from(json.decode(weeklyJson));
    }

    // Check if we need to reset daily stats
    _checkDayReset();

    notifyListeners();
    debugPrint('📚 Study Session Service initialized');
  }

  /// Start a new study session
  Future<void> startSession() async {
    if (_isSessionActive) return;

    _isSessionActive = true;
    _currentSessionSeconds = 0;

    // Start timer that updates every second
    // NOTE: This timer continues even if app goes to background!
    // MUST be paused by AppLifecycleObserver when app pauses
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _currentSessionSeconds++;
      _todayReadingSeconds++;

      // Check for break reminder
      if (_showBreakReminders &&
          _currentSessionSeconds % (_breakReminderInterval * 60) == 0) {
        _triggerBreakReminder();
      }

      notifyListeners();
    });

    // Auto-save session data every 30 seconds to prevent data loss
    _autoSaveTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _saveSessionData();
    });

    notifyListeners();
    debugPrint('📚 Study session started');
  }

  /// Pause the current study session
  Future<void> pauseSession() async {
    if (!_isSessionActive) return;

    _sessionTimer?.cancel();
    _sessionTimer = null;
    _autoSaveTimer?.cancel();
    _autoSaveTimer = null;
    _isSessionActive = false;

    await _saveSessionData();

    notifyListeners();
    debugPrint(
        '📚 Study session paused - Duration: ${_formatDuration(_currentSessionSeconds)}');
  }

  /// Resume the study session
  Future<void> resumeSession() async {
    if (_isSessionActive) return;

    await startSession();
    debugPrint('📚 Study session resumed');
  }

  /// End the current study session
  Future<void> endSession() async {
    if (_isSessionActive) {
      _sessionTimer?.cancel();
      _sessionTimer = null;
      _autoSaveTimer?.cancel();
      _autoSaveTimer = null;
      _isSessionActive = false;
    }

    await _saveSessionData();
    await _updateStreak();

    final sessionDuration = _currentSessionSeconds;
    _currentSessionSeconds = 0;

    notifyListeners();
    debugPrint(
        '📚 Study session ended - Total: ${_formatDuration(sessionDuration)}');
  }

  /// Save current session data
  Future<void> _saveSessionData() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _getTodayDateString();

    // Update today's reading time
    await prefs.setInt(_keyTodaySeconds, _todayReadingSeconds);

    // Update weekly reading time
    _weeklyReadingTime[today] = _todayReadingSeconds;
    await prefs.setString(_keyWeeklyTime, json.encode(_weeklyReadingTime));

    // Update last read date
    await prefs.setString(_keyLastReadDate, today);
    _lastReadDate = today;

    // Clean up old weekly data (keep last 30 days) - only once per day
    _cleanOldWeeklyDataOncePerDay(prefs);
  }

  /// Clean up old weekly data, but only once per calendar day (performance optimization)
  Future<void> _cleanOldWeeklyDataOncePerDay(SharedPreferences prefs) async {
    final today = _getTodayDateString();
    final lastCleanup = prefs.getString(_keyLastCleanupDate);

    if (lastCleanup != today) {
      // First save of the day - run cleanup
      _cleanOldWeeklyData();
      await prefs.setString(_keyLastCleanupDate, today);
    }
  }

  /// Clean up old weekly data (keep last 30 days)
  void _cleanOldWeeklyData() {
    final cutoffDate =
        DateTime.now().toUtc().subtract(const Duration(days: 30));
    final cutoffString = _formatDateString(cutoffDate);

    final beforeCount = _weeklyReadingTime.length;
    _weeklyReadingTime
        .removeWhere((date, _) => date.compareTo(cutoffString) < 0);
    final afterCount = _weeklyReadingTime.length;

    if (beforeCount != afterCount) {
      debugPrint('📚 Cleaned ${beforeCount - afterCount} old daily records');
    }
  }

  /// Get reading time for a specific date
  int getReadingTimeForDate(DateTime date) {
    final dateString = _formatDateString(date);
    return _weeklyReadingTime[dateString] ?? 0;
  }

  /// Get last 7 days reading data
  List<MapEntry<String, int>> getLastWeekData() {
    final List<MapEntry<String, int>> weekData = [];

    for (int i = 6; i >= 0; i--) {
      final date = DateTime.now().subtract(Duration(days: i));
      final dateString = _formatDateString(date);
      final seconds = _weeklyReadingTime[dateString] ?? 0;
      weekData.add(MapEntry(dateString, seconds));
    }

    return weekData;
  }

  /// Check if daily goal is met
  bool isDailyGoalMet() {
    final goalSeconds = _dailyGoalMinutes * 60;
    return _todayReadingSeconds >= goalSeconds;
  }

  /// Get progress towards daily goal (0.0 to 1.0)
  double getDailyGoalProgress() {
    final goalSeconds = _dailyGoalMinutes * 60;
    if (goalSeconds == 0) return 0.0;
    return (_todayReadingSeconds / goalSeconds).clamp(0.0, 1.0);
  }

  /// Set daily goal in minutes
  Future<void> setDailyGoal(int minutes) async {
    // Ensure minimum 1 minute and maximum 480 minutes (8 hours)
    final validMinutes = minutes.clamp(1, 480);
    _dailyGoalMinutes = validMinutes;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyDailyGoal, validMinutes);
    notifyListeners();
  }

  /// Toggle break reminders
  Future<void> toggleBreakReminders() async {
    _showBreakReminders = !_showBreakReminders;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyBreakReminders, _showBreakReminders);
    notifyListeners();
  }

  /// Set break reminder interval
  Future<void> setBreakInterval(int minutes) async {
    _breakReminderInterval = minutes;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyBreakInterval, minutes);
    notifyListeners();
  }

  /// Trigger a break reminder notification
  void _triggerBreakReminder() {
    debugPrint(
        '⏰ Break reminder: You\'ve been reading for $_breakReminderInterval minutes');

    try {
      NotificationService.instance
          .showNotification(
        id: 1003, // Dedicated break reminder notification ID
        title: '⏰ Time for a Break!',
        body:
            'You\'ve been reading for $_breakReminderInterval minutes. Take a 5-minute break to rest your eyes.',
        payload: 'break_reminder',
      )
          .catchError((e) {
        debugPrint('⚠️ Error showing break reminder: $e');
      });
    } catch (e) {
      debugPrint('⚠️ Exception in break reminder: $e');
    }
  }

  /// Format duration in seconds to readable string
  String formatDuration(int seconds) {
    return _formatDuration(seconds);
  }

  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m ${secs}s';
    } else if (minutes > 0) {
      return '${minutes}m ${secs}s';
    } else {
      return '${secs}s';
    }
  }

  /// Get today's date as string (YYYY-MM-DD) in UTC
  /// Using UTC prevents issues with timezone changes and day boundary edge cases
  String _getTodayDateString() {
    return _formatDateString(DateTime.now().toUtc());
  }

  /// Get yesterday's date as string in UTC
  String _getYesterdayDateString() {
    return _formatDateString(
        DateTime.now().toUtc().subtract(const Duration(days: 1)));
  }

  /// Format date as YYYY-MM-DD using UTC
  /// UTC ensures consistent date strings across timezones
  String _formatDateString(DateTime date) {
    final utcDate = date.toUtc();
    return '${utcDate.year}-${utcDate.month.toString().padLeft(2, '0')}-${utcDate.day.toString().padLeft(2, '0')}';
  }

  /// Check if the day has reset and update daily stats accordingly
  void _checkDayReset() {
    final today = _getTodayDateString();
    if (_lastReadDate != null && _lastReadDate != today) {
      // Day has changed - reset today's reading time
      _todayReadingSeconds = 0;
      debugPrint('📚 Day reset detected - clearing today\'s reading time');
    }
  }

  /// Update streak information based on last read date
  Future<void> _updateStreak() async {
    final today = _getTodayDateString();
    final yesterday = _getYesterdayDateString();
    final prefs = await SharedPreferences.getInstance();

    if (_lastReadDate == today) {
      // User read today - maintain streak
      if (_currentStreak == 0) {
        _currentStreak = 1;
      }
    } else if (_lastReadDate == yesterday) {
      // User read yesterday - increment streak
      _currentStreak++;
      if (_currentStreak > _longestStreak) {
        _longestStreak = _currentStreak;
        await prefs.setInt(_keyLongestStreak, _longestStreak);
      }
    } else {
      // Streak broken - reset to 1 if read today
      if (_lastReadDate == today) {
        _currentStreak = 1;
      } else {
        _currentStreak = 0;
      }
    }

    await prefs.setInt(_keyCurrentStreak, _currentStreak);
    notifyListeners();
  }

  /// Get total reading time (all time)
  int getTotalReadingTime() {
    return _weeklyReadingTime.values.fold(0, (sum, seconds) => sum + seconds);
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    _autoSaveTimer?.cancel();
    super.dispose();
  }
}
