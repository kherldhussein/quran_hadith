import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:convert';

/// Service to track study sessions, reading time, and streaks
class StudySessionService extends ChangeNotifier {
  static final StudySessionService _instance = StudySessionService._internal();
  factory StudySessionService() => _instance;
  StudySessionService._internal();

  // Session state
  bool _isSessionActive = false;
  DateTime? _sessionStartTime;
  Timer? _sessionTimer;
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
  Map<String, int> get weeklyReadingTime => Map.unmodifiable(_weeklyReadingTime);
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
    _sessionStartTime = DateTime.now();
    _currentSessionSeconds = 0;

    // Start timer that updates every second
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

    notifyListeners();
    debugPrint('📚 Study session started');
  }

  /// Pause the current study session
  Future<void> pauseSession() async {
    if (!_isSessionActive) return;

    _sessionTimer?.cancel();
    _sessionTimer = null;
    _isSessionActive = false;

    await _saveSessionData();

    notifyListeners();
    debugPrint('📚 Study session paused - Duration: ${_formatDuration(_currentSessionSeconds)}');
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
      _isSessionActive = false;
    }

    await _saveSessionData();
    await _updateStreak();

    final sessionDuration = _currentSessionSeconds;
    _currentSessionSeconds = 0;
    _sessionStartTime = null;

    notifyListeners();
    debugPrint('📚 Study session ended - Total: ${_formatDuration(sessionDuration)}');
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

    // Clean up old weekly data (keep last 30 days)
    _cleanOldWeeklyData();
  }

  /// Update the reading streak
  Future<void> _updateStreak() async {
    final today = _getTodayDateString();
    final yesterday = _getYesterdayDateString();

    if (_lastReadDate == today) {
      // Already counted for today
      return;
    }

    if (_lastReadDate == yesterday || _lastReadDate == null) {
      // Continue or start streak
      _currentStreak++;
    } else {
      // Streak broken
      _currentStreak = 1;
    }

    // Update longest streak
    if (_currentStreak > _longestStreak) {
      _longestStreak = _currentStreak;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_keyLongestStreak, _longestStreak);
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyCurrentStreak, _currentStreak);

    notifyListeners();
  }

  /// Check if we need to reset daily stats
  void _checkDayReset() {
    final today = _getTodayDateString();

    if (_lastReadDate != null && _lastReadDate != today) {
      // New day - check if streak should be broken
      final yesterday = _getYesterdayDateString();

      if (_lastReadDate != yesterday) {
        // Missed a day - break streak
        _currentStreak = 0;
        debugPrint('📚 Streak broken - missed a day');
      }

      // Reset daily reading time
      _todayReadingSeconds = 0;
    }
  }

  /// Clean up old weekly data (keep last 30 days)
  void _cleanOldWeeklyData() {
    final cutoffDate = DateTime.now().subtract(const Duration(days: 30));
    final cutoffString = _formatDateString(cutoffDate);

    _weeklyReadingTime.removeWhere((date, _) => date.compareTo(cutoffString) < 0);
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
    _dailyGoalMinutes = minutes;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyDailyGoal, minutes);
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
    // TODO: Integrate with notification service
    debugPrint('⏰ Break reminder: You\'ve been reading for $_breakReminderInterval minutes');
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

  /// Get today's date as string (YYYY-MM-DD)
  String _getTodayDateString() {
    return _formatDateString(DateTime.now());
  }

  /// Get yesterday's date as string
  String _getYesterdayDateString() {
    return _formatDateString(DateTime.now().subtract(const Duration(days: 1)));
  }

  /// Format date as YYYY-MM-DD
  String _formatDateString(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Get total reading time (all time)
  int getTotalReadingTime() {
    return _weeklyReadingTime.values.fold(0, (sum, seconds) => sum + seconds);
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    super.dispose();
  }
}
