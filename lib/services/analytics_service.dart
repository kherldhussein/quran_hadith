import 'package:flutter/foundation.dart';
import 'package:quran_hadith/utils/shared_p.dart';
import 'package:quran_hadith/services/error_service.dart';

/// Production-ready analytics service for tracking app usage and behavior
class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  static AnalyticsService get instance => _instance;

  // Analytics keys
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

      // Track consecutive days
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

      // Track specific transition patterns
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

      // Track per-reciter usage
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

      // Track individual surah reads
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

      // Track per-book reads
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

      // Track by type
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

      // Track search query length for UX insights
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
          // Consecutive day
          final consecutive =
              appSP.getInt(_keyConsecutiveDays, defaultValue: 0);
          appSP.setInt(_keyConsecutiveDays, consecutive + 1);
        } else if (daysDiff > 1) {
          // Streak broken
          appSP.setInt(_keyConsecutiveDays, 1);
        }
      } else {
        // First session
        appSP.setInt(_keyConsecutiveDays, 1);
      }

      // Track total unique days
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

      // Calculate engagement score based on multiple factors
      int score = 0;

      // Factor 1: Consecutive days (max 30 points)
      final consecutiveDays = summary['consecutiveDays'] as int? ?? 0;
      score += (consecutiveDays * 3).clamp(0, 30);

      // Factor 2: Total sessions (max 20 points)
      final totalSessions = summary['totalSessions'] as int? ?? 0;
      score += (totalSessions ~/ 5).clamp(0, 20);

      // Factor 3: Content interaction (max 30 points)
      final surahsRead = summary['surahsRead'] as int? ?? 0;
      final hadithsRead = summary['hadithsRead'] as int? ?? 0;
      final contentScore = ((surahsRead + hadithsRead) ~/ 10).clamp(0, 30);
      score += contentScore;

      // Factor 4: Feature usage (max 20 points)
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
}

/// Global analytics service instance
final analyticsService = AnalyticsService.instance;
