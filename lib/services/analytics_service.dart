import 'package:flutter/foundation.dart';
import 'package:quran_hadith/utils/shared_p.dart';
import 'package:quran_hadith/services/error_service.dart';
import 'package:quran_hadith/database/database_service.dart';

/// Production-ready analytics service for tracking app usage and behavior
class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  static AnalyticsService get instance => _instance;

  static const String _keyTotalSessions = 'analytics_total_sessions';
  static const String _keyTotalSessionMinutes =
      'analytics_total_session_minutes';
  static const String _keyTotalBackgroundSeconds =
      'analytics_total_background_seconds';
  static const String _keyLifecycleTransitions =
      'analytics_lifecycle_transitions';
  static const String _keyAudioPlayCount = 'analytics_audio_play_count';
  static const String _keyAudioPauseCount = 'analytics_audio_pause_count';
  static const String _keySurahsRead = 'analytics_surahs_read';
  static const String _keyHadithsRead = 'analytics_hadiths_read';
  static const String _keyBookmarksCreated = 'analytics_bookmarks_created';
  static const String _keyFavoritesAdded = 'analytics_favorites_added';
  static const String _keySearchCount = 'analytics_search_count';
  static const String _keyLastSessionDate = 'analytics_last_session_date';
  static const String _keyConsecutiveDays = 'analytics_consecutive_days';
  static const String _keyTotalDaysUsed = 'analytics_total_days_used';

  /// Track app session start
  void trackSessionStart() {
    try {
      final totalSessions = appSP.getInt(_keyTotalSessions, defaultValue: 0);
      appSP.setInt(_keyTotalSessions, totalSessions + 1);

      _updateConsecutiveDays();
    } catch (e, stack) {
      errorService.reportError('Error tracking session start: $e', stack);
    }
  }

  /// Track app session end with duration
  void trackSessionEnd(Duration duration) {
    try {
      final totalMinutes =
          appSP.getInt(_keyTotalSessionMinutes, defaultValue: 0);
      appSP.setInt(_keyTotalSessionMinutes, totalMinutes + duration.inMinutes);

      appSP.setString(_keyLastSessionDate, DateTime.now().toIso8601String());
    } catch (e, stack) {
      errorService.reportError('Error tracking session end: $e', stack);
    }
  }

  /// Track background duration
  void trackBackgroundDuration(Duration duration) {
    try {
      final totalSeconds =
          appSP.getInt(_keyTotalBackgroundSeconds, defaultValue: 0);
      appSP.setInt(
          _keyTotalBackgroundSeconds, totalSeconds + duration.inSeconds);
    } catch (e, stack) {
      errorService.reportError('Error tracking background duration: $e', stack);
    }
  }

  /// Track lifecycle transition
  void trackLifecycleTransition(String fromState, String toState) {
    try {
      final transitions =
          appSP.getInt(_keyLifecycleTransitions, defaultValue: 0);
      appSP.setInt(_keyLifecycleTransitions, transitions + 1);

      final key = 'analytics_transition_${fromState}_to_$toState';
      final count = appSP.getInt(key, defaultValue: 0);
      appSP.setInt(key, count + 1);
    } catch (e, stack) {
      errorService.reportError(
          'Error tracking lifecycle transition: $e', stack);
    }
  }

  /// Track audio playback
  void trackAudioPlay({
    required int surahNumber,
    required int ayahNumber,
    required String reciter,
  }) {
    try {
      final playCount = appSP.getInt(_keyAudioPlayCount, defaultValue: 0);
      appSP.setInt(_keyAudioPlayCount, playCount + 1);

      final reciterKey = 'analytics_reciter_$reciter';
      final reciterCount = appSP.getInt(reciterKey, defaultValue: 0);
      appSP.setInt(reciterKey, reciterCount + 1);
    } catch (e, stack) {
      errorService.reportError('Error tracking audio play: $e', stack);
    }
  }

  /// Track audio pause
  void trackAudioPause() {
    try {
      final pauseCount = appSP.getInt(_keyAudioPauseCount, defaultValue: 0);
      appSP.setInt(_keyAudioPauseCount, pauseCount + 1);
    } catch (e, stack) {
      errorService.reportError('Error tracking audio pause: $e', stack);
    }
  }

  /// Track Surah reading
  void trackSurahRead(int surahNumber) {
    try {
      final surahs = appSP.getInt(_keySurahsRead, defaultValue: 0);
      appSP.setInt(_keySurahsRead, surahs + 1);

      final surahKey = 'analytics_surah_${surahNumber}_reads';
      final reads = appSP.getInt(surahKey, defaultValue: 0);
      appSP.setInt(surahKey, reads + 1);
    } catch (e, stack) {
      errorService.reportError('Error tracking surah read: $e', stack);
    }
  }

  /// Track Hadith reading
  void trackHadithRead(String bookSlug) {
    try {
      final hadiths = appSP.getInt(_keyHadithsRead, defaultValue: 0);
      appSP.setInt(_keyHadithsRead, hadiths + 1);

      final bookKey = 'analytics_hadith_book_${bookSlug}_reads';
      final reads = appSP.getInt(bookKey, defaultValue: 0);
      appSP.setInt(bookKey, reads + 1);
    } catch (e, stack) {
      errorService.reportError('Error tracking hadith read: $e', stack);
    }
  }

  /// Track bookmark creation
  void trackBookmarkCreated() {
    try {
      final bookmarks = appSP.getInt(_keyBookmarksCreated, defaultValue: 0);
      appSP.setInt(_keyBookmarksCreated, bookmarks + 1);
    } catch (e, stack) {
      errorService.reportError('Error tracking bookmark: $e', stack);
    }
  }

  /// Track favorite addition
  void trackFavoriteAdded(String type) {
    try {
      final favorites = appSP.getInt(_keyFavoritesAdded, defaultValue: 0);
      appSP.setInt(_keyFavoritesAdded, favorites + 1);

      final typeKey = 'analytics_favorites_type_$type';
      final typeCount = appSP.getInt(typeKey, defaultValue: 0);
      appSP.setInt(typeKey, typeCount + 1);
    } catch (e, stack) {
      errorService.reportError('Error tracking favorite: $e', stack);
    }
  }

  /// Track search usage
  void trackSearch(String query) {
    try {
      final searches = appSP.getInt(_keySearchCount, defaultValue: 0);
      appSP.setInt(_keySearchCount, searches + 1);

      final lengthKey = 'analytics_search_length_${query.length ~/ 5 * 5}';
      final lengthCount = appSP.getInt(lengthKey, defaultValue: 0);
      appSP.setInt(lengthKey, lengthCount + 1);
    } catch (e, stack) {
      errorService.reportError('Error tracking search: $e', stack);
    }
  }

  /// Update consecutive days usage
  void _updateConsecutiveDays() {
    try {
      final lastSessionStr =
          appSP.getString(_keyLastSessionDate, defaultValue: '');
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      if (lastSessionStr.isNotEmpty) {
        final lastSession = DateTime.parse(lastSessionStr);
        final lastDay = DateTime(
          lastSession.year,
          lastSession.month,
          lastSession.day,
        );

        final daysDiff = today.difference(lastDay).inDays;

        if (daysDiff == 1) {
          final consecutive =
              appSP.getInt(_keyConsecutiveDays, defaultValue: 0);
          appSP.setInt(_keyConsecutiveDays, consecutive + 1);
        } else if (daysDiff > 1) {
          appSP.setInt(_keyConsecutiveDays, 1);
        }
      } else {
        appSP.setInt(_keyConsecutiveDays, 1);
      }

      final totalDays = appSP.getInt(_keyTotalDaysUsed, defaultValue: 0);
      appSP.setInt(_keyTotalDaysUsed, totalDays + 1);
    } catch (e, stack) {
      errorService.reportError('Error updating consecutive days: $e', stack);
    }
  }

  /// Get analytics summary
  Map<String, dynamic> getAnalyticsSummary() {
    try {
      return {
        'totalSessions': appSP.getInt(_keyTotalSessions, defaultValue: 0),
        'totalSessionMinutes':
            appSP.getInt(_keyTotalSessionMinutes, defaultValue: 0),
        'totalBackgroundSeconds':
            appSP.getInt(_keyTotalBackgroundSeconds, defaultValue: 0),
        'lifecycleTransitions':
            appSP.getInt(_keyLifecycleTransitions, defaultValue: 0),
        'audioPlayCount': appSP.getInt(_keyAudioPlayCount, defaultValue: 0),
        'audioPauseCount': appSP.getInt(_keyAudioPauseCount, defaultValue: 0),
        'surahsRead': appSP.getInt(_keySurahsRead, defaultValue: 0),
        'hadithsRead': appSP.getInt(_keyHadithsRead, defaultValue: 0),
        'bookmarksCreated': appSP.getInt(_keyBookmarksCreated, defaultValue: 0),
        'favoritesAdded': appSP.getInt(_keyFavoritesAdded, defaultValue: 0),
        'searchCount': appSP.getInt(_keySearchCount, defaultValue: 0),
        'consecutiveDays': appSP.getInt(_keyConsecutiveDays, defaultValue: 0),
        'totalDaysUsed': appSP.getInt(_keyTotalDaysUsed, defaultValue: 0),
        'lastSessionDate': appSP.getString(_keyLastSessionDate),
      };
    } catch (e, stack) {
      errorService.reportError('Error getting analytics summary: $e', stack);
      return {};
    }
  }

  /// Get user engagement score (0-100)
  int getUserEngagementScore() {
    try {
      final summary = getAnalyticsSummary();

      int score = 0;

      final consecutiveDays = summary['consecutiveDays'] as int? ?? 0;
      score += (consecutiveDays * 3).clamp(0, 30);

      final totalSessions = summary['totalSessions'] as int? ?? 0;
      score += (totalSessions ~/ 5).clamp(0, 20);

      final surahsRead = summary['surahsRead'] as int? ?? 0;
      final hadithsRead = summary['hadithsRead'] as int? ?? 0;
      final contentScore = ((surahsRead + hadithsRead) ~/ 10).clamp(0, 30);
      score += contentScore;

      final bookmarks = summary['bookmarksCreated'] as int? ?? 0;
      final favorites = summary['favoritesAdded'] as int? ?? 0;
      final searches = summary['searchCount'] as int? ?? 0;
      final featureScore =
          ((bookmarks + favorites + searches) ~/ 5).clamp(0, 20);
      score += featureScore;

      return score.clamp(0, 100);
    } catch (e, stack) {
      errorService.reportError('Error calculating engagement score: $e', stack);
      return 0;
    }
  }

  /// Reset analytics (for testing or user request)
  Future<void> resetAnalytics() async {
    try {
      final keys = [
        _keyTotalSessions,
        _keyTotalSessionMinutes,
        _keyTotalBackgroundSeconds,
        _keyLifecycleTransitions,
        _keyAudioPlayCount,
        _keyAudioPauseCount,
        _keySurahsRead,
        _keyHadithsRead,
        _keyBookmarksCreated,
        _keyFavoritesAdded,
        _keySearchCount,
        _keyLastSessionDate,
        _keyConsecutiveDays,
        _keyTotalDaysUsed,
      ];

      for (final key in keys) {
        await appSP.remove(key);
      }

      if (kDebugMode) {
        debugPrint('Analytics reset successfully');
      }
    } catch (e, stack) {
      errorService.reportError('Error resetting analytics: $e', stack);
    }
  }

  /// Get human-readable analytics report
  String getAnalyticsReport() {
    try {
      final summary = getAnalyticsSummary();
      final engagementScore = getUserEngagementScore();

      final buffer = StringBuffer();
      buffer.writeln('📊 App Analytics Report');
      buffer.writeln('═' * 50);
      buffer.writeln();

      buffer.writeln('📱 Session Stats:');
      buffer.writeln('  • Total Sessions: ${summary['totalSessions']}');
      buffer
          .writeln('  • Total Time: ${summary['totalSessionMinutes']} minutes');
      buffer.writeln(
          '  • Background Time: ${summary['totalBackgroundSeconds']} seconds');
      buffer.writeln();

      buffer.writeln('🔄 Lifecycle:');
      buffer.writeln('  • Transitions: ${summary['lifecycleTransitions']}');
      buffer.writeln();

      buffer.writeln('🎵 Audio Usage:');
      buffer.writeln('  • Plays: ${summary['audioPlayCount']}');
      buffer.writeln('  • Pauses: ${summary['audioPauseCount']}');
      buffer.writeln();

      buffer.writeln('📖 Content:');
      buffer.writeln('  • Surahs Read: ${summary['surahsRead']}');
      buffer.writeln('  • Hadiths Read: ${summary['hadithsRead']}');
      buffer.writeln();

      buffer.writeln('⭐ Engagement:');
      buffer.writeln('  • Bookmarks: ${summary['bookmarksCreated']}');
      buffer.writeln('  • Favorites: ${summary['favoritesAdded']}');
      buffer.writeln('  • Searches: ${summary['searchCount']}');
      buffer.writeln();

      buffer.writeln('📅 Consistency:');
      buffer.writeln('  • Consecutive Days: ${summary['consecutiveDays']}');
      buffer.writeln('  • Total Days Used: ${summary['totalDaysUsed']}');
      buffer.writeln();

      buffer.writeln('🎯 Engagement Score: $engagementScore/100');
      buffer.writeln();

      final lastSession = summary['lastSessionDate'] as String?;
      if (lastSession != null) {
        buffer.writeln('🕐 Last Session: $lastSession');
      }

      return buffer.toString();
    } catch (e, stack) {
      errorService.reportError('Error generating analytics report: $e', stack);
      return 'Error generating report';
    }
  }

  /// Goal tracking - Daily reading goal
  void setDailyReadingGoal(int minutes) {
    try {
      appSP.setInt('goal_daily_reading_minutes', minutes);
    } catch (e, stack) {
      errorService.reportError('Error setting daily reading goal: $e', stack);
    }
  }

  /// Get daily reading goal
  int getDailyReadingGoal() {
    try {
      return appSP.getInt('goal_daily_reading_minutes', defaultValue: 30);
    } catch (e, stack) {
      errorService.reportError('Error getting daily reading goal: $e', stack);
      return 30;
    }
  }

  /// Check if today's reading goal is met
  bool isDailyReadingGoalMet() {
    try {
      final history = database.getReadingHistory();
      final today = DateTime.now();

      final todaysReading = history.where((session) {
        final sessionDate = DateTime.fromMillisecondsSinceEpoch(
          session.lastReadAt.millisecondsSinceEpoch,
        );
        return sessionDate.year == today.year &&
            sessionDate.month == today.month &&
            sessionDate.day == today.day;
      }).fold<int>(0, (sum, session) => sum + session.totalTimeSpentSeconds);

      final goalMinutes = getDailyReadingGoal();
      return todaysReading ~/ 60 >= goalMinutes;
    } catch (e, stack) {
      errorService.reportError('Error checking daily reading goal: $e', stack);
      return false;
    }
  }

  /// Goal tracking - Monthly listening goal
  void setMonthlyListeningGoal(int hours) {
    try {
      appSP.setInt('goal_monthly_listening_hours', hours);
    } catch (e, stack) {
      errorService.reportError(
          'Error setting monthly listening goal: $e', stack);
    }
  }

  /// Get monthly listening goal
  int getMonthlyListeningGoal() {
    try {
      return appSP.getInt('goal_monthly_listening_hours', defaultValue: 10);
    } catch (e, stack) {
      errorService.reportError(
          'Error getting monthly listening goal: $e', stack);
      return 10;
    }
  }

  /// Achievement unlock system
  void unlockAchievement(
      String achievementId, String title, String description) {
    try {
      final key = 'achievement_$achievementId';
      if (appSP.getBool(key, defaultValue: false)) {
        return;
      }

      appSP.setBool(key, true);
      appSP.setString('achievement_${achievementId}_title', title);
      appSP.setString('achievement_${achievementId}_desc', description);
      appSP.setString('achievement_${achievementId}_date',
          DateTime.now().toIso8601String());

      if (kDebugMode) {
        debugPrint('🏆 Achievement Unlocked: $title');
      }
    } catch (e, stack) {
      errorService.reportError('Error unlocking achievement: $e', stack);
    }
  }

  /// Get all unlocked achievements
  Map<String, dynamic> getUnlockedAchievements() {
    try {
      final achievements = <String, dynamic>{};

      final readingFifty =
          appSP.getBool('achievement_read_50_surahs', defaultValue: false);
      if (readingFifty) {
        achievements['read_50_surahs'] = {
          'title': 'Half Way There 📚',
          'description': 'Read 50 Surahs',
          'unlockedAt': appSP.getString('achievement_read_50_surahs_date',
              defaultValue: ''),
        };
      }

      final listeningAll =
          appSP.getBool('achievement_listen_all_surahs', defaultValue: false);
      if (listeningAll) {
        achievements['listen_all_surahs'] = {
          'title': 'Complete Listener 🎵',
          'description': 'Listen to all 114 Surahs',
          'unlockedAt': appSP.getString('achievement_listen_all_surahs_date',
              defaultValue: ''),
        };
      }

      final streak7 =
          appSP.getBool('achievement_streak_7_days', defaultValue: false);
      if (streak7) {
        achievements['streak_7_days'] = {
          'title': 'Week Warrior 🔥',
          'description': '7 day reading streak',
          'unlockedAt': appSP.getString('achievement_streak_7_days_date',
              defaultValue: ''),
        };
      }

      final streak30 =
          appSP.getBool('achievement_streak_30_days', defaultValue: false);
      if (streak30) {
        achievements['streak_30_days'] = {
          'title': 'Monthly Master 📖',
          'description': '30 day reading streak',
          'unlockedAt': appSP.getString('achievement_streak_30_days_date',
              defaultValue: ''),
        };
      }

      return achievements;
    } catch (e, stack) {
      errorService.reportError('Error getting achievements: $e', stack);
      return {};
    }
  }

  /// Check and unlock achievement based on progress
  void checkAndUnlockAchievements() {
    try {
      final summary = getAnalyticsSummary();

      final uniqueSurahs = (summary['surahsRead'] as int?) ?? 0;
      if (uniqueSurahs >= 50 &&
          !appSP.getBool('achievement_read_50_surahs', defaultValue: false)) {
        unlockAchievement(
            'read_50_surahs', 'Half Way There 📚', 'Read 50 Surahs');
      }

      final consecutiveDays = (summary['consecutiveDays'] as int?) ?? 0;
      if (consecutiveDays >= 7 &&
          !appSP.getBool('achievement_streak_7_days', defaultValue: false)) {
        unlockAchievement(
            'streak_7_days', 'Week Warrior 🔥', '7 day reading streak');
      }

      if (consecutiveDays >= 30 &&
          !appSP.getBool('achievement_streak_30_days', defaultValue: false)) {
        unlockAchievement(
            'streak_30_days', 'Monthly Master 📖', '30 day reading streak');
      }
    } catch (e, stack) {
      errorService.reportError('Error checking achievements: $e', stack);
    }
  }

  /// Get user level based on engagement score
  int getUserLevel() {
    try {
      final score = getUserEngagementScore();
      return (score ~/ 10) + 1;
    } catch (e, stack) {
      errorService.reportError('Error calculating user level: $e', stack);
      return 1;
    }
  }

  /// Get experience points (same as engagement score)
  int getExperiencePoints() => getUserEngagementScore();

  /// Get experience points needed for next level
  int getExperienceForNextLevel(int currentLevel) {
    return (currentLevel * 15).clamp(0, 100);
  }

  /// Track orientation change
  void trackOrientationChange(String orientation) {
    try {
      appSP.setString('last_orientation', orientation);
      appSP.setInt('orientation_changes',
          (appSP.getInt('orientation_changes', defaultValue: 0)) + 1);
    } catch (e, stack) {
      errorService.reportError('Error tracking orientation change: $e', stack);
    }
  }

  /// Track screen size category change
  void trackScreenSizeChange(String previousCategory, String newCategory) {
    try {
      appSP.setString('previous_screen_category', previousCategory);
      appSP.setString('current_screen_category', newCategory);
      appSP.setInt('screen_size_changes',
          (appSP.getInt('screen_size_changes', defaultValue: 0)) + 1);
    } catch (e, stack) {
      errorService.reportError('Error tracking screen size change: $e', stack);
    }
  }
}

/// Global analytics service instance
final analyticsService = AnalyticsService.instance;
