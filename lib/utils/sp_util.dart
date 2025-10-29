import 'dart:convert';

import 'package:quran_hadith/models/daily_ayah.dart';
import 'package:quran_hadith/utils/shared_p.dart';

/// Keys for shared preferences storage
class StorageKeys {
  static const String isFavorite = 'IS_FAVORITE';
  static const String favorites = 'FAVORITES';
  static const String user = 'USER';
  static const String isDarkMode = 'IS_DARK_MODE';
  static const String lastReadSurah = 'LAST_READ_SURAH';
  static const String lastReadAyah = 'LAST_READ_AYAH';
  static const String lastListenSurah = 'LAST_LISTEN_SURAH';
  static const String lastListenAyah = 'LAST_LISTEN_AYAH';
  static const String lastListenPosMs = 'LAST_LISTEN_POS_MS';
  static const String appLanguage = 'APP_LANGUAGE';
  static const String fontSize = 'FONT_SIZE';
  static const String audioSpeed = 'AUDIO_SPEED';
  static const String reciter = 'RECITER';
  static const String firstLaunch = 'FIRST_LAUNCH';
  static const String dailyAyahDate = 'DAILY_AYAH_DATE';
  static const String dailyAyahData = 'DAILY_AYAH_DATA';
  static const String dailyAyahEnabled = 'DAILY_AYAH_ENABLED';
  static const String dailyAyahTimeMinutes = 'DAILY_AYAH_TIME_MINUTES';
  static const String fridayReminderEnabled = 'FRIDAY_REMINDER_ENABLED';
  static const String fridayReminderTimeMinutes =
      'FRIDAY_REMINDER_TIME_MINUTES';
  static const String autoPlayNextAyah = 'AUTO_PLAY_NEXT_AYAH';
  static const String repeatMode = 'REPEAT_MODE';
  static const String autoScroll = 'AUTO_SCROLL';
}

/// Enhanced utility class for managing app preferences with better error handling and type safety
class SpUtil {
  SpUtil._();

  /// Checks if this is the first app launch
  static bool isFirstLaunch() {
    return appSP.getBool(StorageKeys.firstLaunch, defaultValue: true);
  }

  /// Marks the app as launched
  static Future<bool> setAppLaunched() {
    return appSP.setBool(StorageKeys.firstLaunch, false);
  }

  static bool getFavorite() => appSP.getBool(StorageKeys.isFavorite);

  static Future<bool> setFavorite(bool value) {
    return appSP.setBool(StorageKeys.isFavorite, value);
  }

  static List<String> getFavorites() =>
      appSP.getListString(StorageKeys.favorites);

  static Future<bool> setFavorites(List<String> favorites) {
    return appSP.setListString(StorageKeys.favorites, favorites);
  }

  /// Adds a single favorite item
  static Future<bool> addFavoriteItem(String item) async {
    try {
      final favorites = getFavorites();
      if (!favorites.contains(item)) {
        favorites.add(item);
        return await setFavorites(favorites);
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Removes a single favorite item
  static Future<bool> removeFavoriteItem(String item) async {
    try {
      final favorites = getFavorites();
      favorites.remove(item);
      return await setFavorites(favorites);
    } catch (e) {
      return false;
    }
  }

  /// Checks if an item is favorited
  static bool isItemFavorited(String item) {
    return getFavorites().contains(item);
  }

  static bool getThemed() =>
      appSP.getBool(StorageKeys.isDarkMode, defaultValue: false);

  static Future<bool> setThemed(bool value) {
    return appSP.setBool(StorageKeys.isDarkMode, value);
  }

  static String getUser() =>
      appSP.getString(StorageKeys.user, defaultValue: 'Guest');

  static Future<bool> setUser(String value) {
    if (value.trim().isEmpty) return Future.value(false);
    return appSP.setString(StorageKeys.user, value.trim());
  }

  static int getLastReadSurah() =>
      appSP.getInt(StorageKeys.lastReadSurah, defaultValue: 1);
  static int getLastReadAyah() =>
      appSP.getInt(StorageKeys.lastReadAyah, defaultValue: 1);

  static Future<bool> setLastRead({
    required int surah,
    required int ayah,
  }) async {
    if (surah < 1 || surah > 114 || ayah < 1) {
      throw ArgumentError('Invalid surah or ayah number');
    }

    try {
      final results = await Future.wait([
        appSP.setInt(StorageKeys.lastReadSurah, surah),
        appSP.setInt(StorageKeys.lastReadAyah, ayah),
      ]);
      return results.every((result) => result);
    } catch (e) {
      return false;
    }
  }

  static int getLastListenSurah() =>
      appSP.getInt(StorageKeys.lastListenSurah, defaultValue: 1);
  static int getLastListenAyah() =>
      appSP.getInt(StorageKeys.lastListenAyah, defaultValue: 1);
  static int getLastListenPosMs() =>
      appSP.getInt(StorageKeys.lastListenPosMs, defaultValue: 0);

  static Future<bool> setLastListen({
    required int surah,
    required int ayah,
    required int positionMs,
  }) async {
    if (surah < 1 || surah > 114 || ayah < 1 || positionMs < 0) {
      throw ArgumentError('Invalid listen data');
    }

    try {
      final results = await Future.wait([
        appSP.setInt(StorageKeys.lastListenSurah, surah),
        appSP.setInt(StorageKeys.lastListenAyah, ayah),
        appSP.setInt(StorageKeys.lastListenPosMs, positionMs),
      ]);
      return results.every((result) => result);
    } catch (e) {
      return false;
    }
  }

  static String getAppLanguage() =>
      appSP.getString(StorageKeys.appLanguage, defaultValue: 'en');
  static Future<bool> setAppLanguage(String language) =>
      appSP.setString(StorageKeys.appLanguage, language);

  static double getFontSize() =>
      appSP.getDouble(StorageKeys.fontSize, defaultValue: 16.0);
  static Future<bool> setFontSize(double size) =>
      appSP.setDouble(StorageKeys.fontSize, size);

  static double getAudioSpeed() =>
      appSP.getDouble(StorageKeys.audioSpeed, defaultValue: 1.0);
  static Future<bool> setAudioSpeed(double speed) =>
      appSP.setDouble(StorageKeys.audioSpeed, speed);

  static String getReciter() =>
      appSP.getString(StorageKeys.reciter, defaultValue: 'ar.alafasy');
  static Future<bool> setReciter(String reciter) =>
      appSP.setString(StorageKeys.reciter, reciter);


  /// Clears all user data (logout functionality)
  static Future<void> clearUserData() async {
    await Future.wait([
      appSP.remove(StorageKeys.user),
      appSP.remove(StorageKeys.favorites),
      appSP.remove(StorageKeys.lastReadSurah),
      appSP.remove(StorageKeys.lastReadAyah),
      appSP.remove(StorageKeys.lastListenSurah),
      appSP.remove(StorageKeys.lastListenAyah),
      appSP.remove(StorageKeys.lastListenPosMs),
    ]);
  }

  /// Resets all preferences to default values
  static Future<void> resetToDefaults() async {
    await Future.wait([
      setFavorites([]),
      setFavorite(false),
      setUser('Guest'),
      setLastRead(surah: 1, ayah: 1),
      setLastListen(surah: 1, ayah: 1, positionMs: 0),
      setFontSize(16.0),
      setAudioSpeed(1.0),
    ]);
  }

  /// Export all settings as a Map (for backup/debugging)
  static Map<String, dynamic> exportSettings() {
    return {
      'user': getUser(),
      'isDarkMode': getThemed(),
      'favorites': getFavorites(),
      'lastRead': {
        'surah': getLastReadSurah(),
        'ayah': getLastReadAyah(),
      },
      'lastListen': {
        'surah': getLastListenSurah(),
        'ayah': getLastListenAyah(),
        'positionMs': getLastListenPosMs(),
      },
      'settings': {
        'language': getAppLanguage(),
        'fontSize': getFontSize(),
        'audioSpeed': getAudioSpeed(),
        'reciter': getReciter(),
      },
    };
  }


  static String? getDailyAyahDate() {
    final value = appSP.getString(StorageKeys.dailyAyahDate);
    return value.isEmpty ? null : value;
  }

  static DailyAyah? getCachedDailyAyah() {
    final raw = appSP.getString(StorageKeys.dailyAyahData);
    if (raw.isEmpty) return null;
    try {
      final decoded = json.decode(raw) as Map<String, dynamic>;
      return DailyAyah.fromJson(decoded);
    } catch (e) {
      return null;
    }
  }

  static Future<void> cacheDailyAyah({
    required String cacheDate,
    required DailyAyah ayah,
  }) async {
    await appSP.setString(StorageKeys.dailyAyahDate, cacheDate);
    await appSP.setString(
      StorageKeys.dailyAyahData,
      json.encode(ayah.toJson()),
    );
  }

  static Future<void> clearDailyAyahCache() async {
    await Future.wait([
      appSP.remove(StorageKeys.dailyAyahDate),
      appSP.remove(StorageKeys.dailyAyahData),
    ]);
  }


  static bool isDailyAyahNotificationEnabled() {
    return appSP.getBool(StorageKeys.dailyAyahEnabled);
  }

  static Future<bool> setDailyAyahNotificationEnabled(bool value) {
    return appSP.setBool(StorageKeys.dailyAyahEnabled, value);
  }

  static int getDailyAyahTimeMinutes() {
    return appSP.getInt(StorageKeys.dailyAyahTimeMinutes, defaultValue: 9 * 60);
  }

  static Future<bool> setDailyAyahTimeMinutes(int minutes) {
    return appSP.setInt(StorageKeys.dailyAyahTimeMinutes, minutes);
  }

  static bool isFridayReminderEnabled() {
    return appSP.getBool(StorageKeys.fridayReminderEnabled);
  }

  static Future<bool> setFridayReminderEnabled(bool value) {
    return appSP.setBool(StorageKeys.fridayReminderEnabled, value);
  }

  static int getFridayReminderTimeMinutes() {
    return appSP.getInt(StorageKeys.fridayReminderTimeMinutes,
        defaultValue: 12 * 60);
  }

  static Future<bool> setFridayReminderTimeMinutes(int minutes) {
    return appSP.setInt(StorageKeys.fridayReminderTimeMinutes, minutes);
  }


  /// Get auto-play next ayah setting
  static bool getAutoPlayNextAyah() {
    return appSP.getBool(StorageKeys.autoPlayNextAyah, defaultValue: false);
  }

  /// Set auto-play next ayah
  static Future<bool> setAutoPlayNextAyah(bool value) {
    return appSP.setBool(StorageKeys.autoPlayNextAyah, value);
  }

  /// Get repeat mode: 'none', 'ayah', 'surah'
  static String getRepeatMode() {
    return appSP.getString(StorageKeys.repeatMode, defaultValue: 'none');
  }

  /// Set repeat mode
  static Future<bool> setRepeatMode(String mode) {
    return appSP.setString(StorageKeys.repeatMode, mode);
  }

  /// Get auto scroll setting
  static bool getAutoScroll() {
    return appSP.getBool(StorageKeys.autoScroll, defaultValue: false);
  }

  /// Set auto scroll
  static Future<bool> setAutoScroll(bool value) {
    return appSP.setBool(StorageKeys.autoScroll, value);
  }
}
