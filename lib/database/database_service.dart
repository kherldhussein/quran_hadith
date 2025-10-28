import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:quran_hadith/models/reciter_model.dart';

import 'hive_adapters.dart';

/// Comprehensive database service for offline data management
class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static const String _cachedSurahsBox = 'cached_surahs';
  static const String _bookmarksBox = 'bookmarks';
  static const String _readingProgressBox = 'reading_progress';
  static const String _listeningProgressBox = 'listening_progress';
  static const String _studyNotesBox = 'study_notes';
  static const String _translationsBox = 'translations';
  static const String _preferencesBox = 'preferences';
  static const String _readingGoalsBox = 'reading_goals';
  static const String _metaBox = 'app_meta';

  bool _isInitialized = false;

  /// Initialize Hive database
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await Hive.initFlutter();

      Hive.registerAdapter(CachedSurahAdapter());
      Hive.registerAdapter(CachedAyahAdapter());
      Hive.registerAdapter(BookmarkAdapter());
      Hive.registerAdapter(ReadingProgressAdapter());
      Hive.registerAdapter(ListeningProgressAdapter());
      Hive.registerAdapter(StudyNoteAdapter());
      Hive.registerAdapter(TranslationDataAdapter());
      Hive.registerAdapter(UserPreferencesAdapter());
      Hive.registerAdapter(ReadingGoalAdapter());

      await Future.wait([
        Hive.openBox(_cachedSurahsBox),
        Hive.openBox(_bookmarksBox),
        Hive.openBox(_readingProgressBox),
        Hive.openBox(_listeningProgressBox),
        Hive.openBox(_studyNotesBox),
        Hive.openBox(_translationsBox),
        Hive.openBox(_preferencesBox),
        Hive.openBox(_readingGoalsBox),
        Hive.openBox(_metaBox),
      ]);

      _isInitialized = true;
      debugPrint('DatabaseService initialized successfully');
    } catch (e) {
      debugPrint('Error initializing DatabaseService: $e');
      rethrow;
    }
  }

  /// Cache a surah for offline access
  Future<void> cacheSurah(CachedSurah surah) async {
    final box = Hive.box(_cachedSurahsBox);
    await box.put(surah.number, surah);
  }

  /// Get cached surah
  CachedSurah? getCachedSurah(int surahNumber) {
    final box = Hive.box(_cachedSurahsBox);
    return box.get(surahNumber);
  }

  /// Get all cached surahs
  List<CachedSurah> getAllCachedSurahs() {
    final box = Hive.box(_cachedSurahsBox);
    return box.values.cast<CachedSurah>().toList();
  }

  /// Check if surah is cached
  bool isSurahCached(int surahNumber) {
    final box = Hive.box(_cachedSurahsBox);
    return box.containsKey(surahNumber);
  }

  /// Clear cached surahs
  Future<void> clearCachedSurahs() async {
    final box = Hive.box(_cachedSurahsBox);
    await box.clear();
  }

  /// Get cache size in MB
  Future<double> getCacheSize() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final hiveDir = Directory('${dir.path}/hive');
      if (await hiveDir.exists()) {
        int totalSize = 0;
        await for (final file in hiveDir.list(recursive: true)) {
          if (file is File) {
            totalSize += await file.length();
          }
        }
        return totalSize / (1024 * 1024); // Convert to MB
      }
      return 0;
    } catch (e) {
      debugPrint('Error calculating cache size: $e');
      return 0;
    }
  }

  /// Add bookmark
  Future<void> addBookmark(Bookmark bookmark) async {
    final box = Hive.box(_bookmarksBox);
    await box.put(bookmark.id, bookmark);
  }

  /// Remove bookmark
  Future<void> removeBookmark(String id) async {
    final box = Hive.box(_bookmarksBox);
    await box.delete(id);
  }

  /// Get bookmark
  Bookmark? getBookmark(String id) {
    final box = Hive.box(_bookmarksBox);
    return box.get(id);
  }

  /// Get all bookmarks
  List<Bookmark> getAllBookmarks() {
    final box = Hive.box(_bookmarksBox);
    return box.values.cast<Bookmark>().toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  /// Get bookmarks by category
  List<Bookmark> getBookmarksByCategory(String category) {
    return getAllBookmarks().where((b) => b.category == category).toList();
  }

  /// Get bookmarks by surah
  List<Bookmark> getBookmarksBySurah(int surahNumber) {
    return getAllBookmarks()
        .where((b) => b.surahNumber == surahNumber)
        .toList();
  }

  /// Search bookmarks
  List<Bookmark> searchBookmarks(String query) {
    final lowerQuery = query.toLowerCase();
    return getAllBookmarks().where((b) {
      return b.title.toLowerCase().contains(lowerQuery) ||
          (b.notes?.toLowerCase().contains(lowerQuery) ?? false) ||
          b.tags.any((tag) => tag.toLowerCase().contains(lowerQuery));
    }).toList();
  }

  /// Clear all bookmarks
  Future<void> clearBookmarks() async {
    final box = Hive.box(_bookmarksBox);
    await box.clear();
  }

  /// Save reading progress
  Future<void> saveReadingProgress(ReadingProgress progress) async {
    final box = Hive.box(_readingProgressBox);
    final key = '${progress.surahNumber}:${progress.ayahNumber}';
    await box.put(key, progress);
  }

  /// Get reading progress
  ReadingProgress? getReadingProgress(int surahNumber, int ayahNumber) {
    final box = Hive.box(_readingProgressBox);
    return box.get('$surahNumber:$ayahNumber');
  }

  /// Get last reading progress
  ReadingProgress? getLastReadingProgress() {
    final box = Hive.box(_readingProgressBox);
    if (box.isEmpty) return null;

    final progresses = box.values.cast<ReadingProgress>().toList();
    progresses.sort((a, b) => b.lastReadAt.compareTo(a.lastReadAt));
    return progresses.first;
  }

  /// Get reading history
  List<ReadingProgress> getReadingHistory({int limit = 50}) {
    final box = Hive.box(_readingProgressBox);
    final progresses = box.values.cast<ReadingProgress>().toList();
    progresses.sort((a, b) => b.lastReadAt.compareTo(a.lastReadAt));
    return progresses.take(limit).toList();
  }

  /// Clear reading progress
  Future<void> clearReadingProgress() async {
    final box = Hive.box(_readingProgressBox);
    await box.clear();
  }

  /// Save listening progress
  Future<void> saveListeningProgress(ListeningProgress progress) async {
    final box = Hive.box(_listeningProgressBox);
    final key = '${progress.surahNumber}:${progress.ayahNumber}';
    await box.put(key, progress);
  }

  /// Get listening progress
  ListeningProgress? getListeningProgress(int surahNumber, int ayahNumber) {
    final box = Hive.box(_listeningProgressBox);
    return box.get('$surahNumber:$ayahNumber');
  }

  /// Get last listening progress
  ListeningProgress? getLastListeningProgress() {
    final box = Hive.box(_listeningProgressBox);
    if (box.isEmpty) return null;

    final progresses = box.values.cast<ListeningProgress>().toList();
    progresses.sort((a, b) => b.lastListenedAt.compareTo(a.lastListenedAt));
    return progresses.first;
  }

  /// Get listening history
  List<ListeningProgress> getListeningHistory({int limit = 50}) {
    final box = Hive.box(_listeningProgressBox);
    final progresses = box.values.cast<ListeningProgress>().toList();
    progresses.sort((a, b) => b.lastListenedAt.compareTo(a.lastListenedAt));
    return progresses.take(limit).toList();
  }

  /// Clear listening progress
  Future<void> clearListeningProgress() async {
    final box = Hive.box(_listeningProgressBox);
    await box.clear();
  }

  /// Add study note
  Future<void> addStudyNote(StudyNote note) async {
    final box = Hive.box(_studyNotesBox);
    await box.put(note.id, note);
  }

  /// Remove study note
  Future<void> removeStudyNote(String id) async {
    final box = Hive.box(_studyNotesBox);
    await box.delete(id);
  }

  /// Get study notes for ayah
  List<StudyNote> getStudyNotesForAyah(int surahNumber, int ayahNumber) {
    final box = Hive.box(_studyNotesBox);
    return box.values
        .cast<StudyNote>()
        .where((note) =>
            note.surahNumber == surahNumber && note.ayahNumber == ayahNumber)
        .toList();
  }

  /// Get all study notes
  List<StudyNote> getAllStudyNotes() {
    final box = Hive.box(_studyNotesBox);
    return box.values.cast<StudyNote>().toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  /// Search study notes
  List<StudyNote> searchStudyNotes(String query) {
    final lowerQuery = query.toLowerCase();
    return getAllStudyNotes().where((note) {
      return note.note.toLowerCase().contains(lowerQuery) ||
          note.tags.any((tag) => tag.toLowerCase().contains(lowerQuery));
    }).toList();
  }

  /// Clear study notes
  Future<void> clearStudyNotes() async {
    final box = Hive.box(_studyNotesBox);
    await box.clear();
  }

  /// Cache translation
  Future<void> cacheTranslation(TranslationData translation) async {
    final box = Hive.box(_translationsBox);
    await box.put(translation.identifier, translation);
  }

  /// Get cached translation
  TranslationData? getCachedTranslation(String identifier) {
    final box = Hive.box(_translationsBox);
    return box.get(identifier);
  }

  /// Get all cached translations
  List<TranslationData> getAllCachedTranslations() {
    final box = Hive.box(_translationsBox);
    return box.values.cast<TranslationData>().toList();
  }

  /// Clear translations
  Future<void> clearTranslations() async {
    final box = Hive.box(_translationsBox);
    await box.clear();
  }

  /// Save user preferences
  Future<void> savePreferences(UserPreferences preferences) async {
    final box = Hive.box(_preferencesBox);
    await box.put('user_preferences', preferences);
  }

  /// Get user preferences
  UserPreferences getPreferences() {
    final box = Hive.box(_preferencesBox);
    return box.get('user_preferences', defaultValue: UserPreferences());
  }

  /// Save reading goal
  Future<void> saveReadingGoal(ReadingGoal goal) async {
    final box = Hive.box(_readingGoalsBox);
    await box.put('current_goal', goal);
  }

  /// Get reading goal
  ReadingGoal? getReadingGoal() {
    final box = Hive.box(_readingGoalsBox);
    return box.get('current_goal');
  }

  /// Export all data as JSON
  Future<Map<String, dynamic>> exportData() async {
    return {
      'bookmarks': getAllBookmarks()
          .map((b) => {
                'id': b.id,
                'title': b.title,
                'type': b.type,
                'surahNumber': b.surahNumber,
                'ayahNumber': b.ayahNumber,
                'notes': b.notes,
                'tags': b.tags,
                'category': b.category,
                'color': b.color,
                'createdAt': b.createdAt.toIso8601String(),
                'updatedAt': b.updatedAt.toIso8601String(),
              })
          .toList(),
      'studyNotes': getAllStudyNotes()
          .map((n) => {
                'id': n.id,
                'surahNumber': n.surahNumber,
                'ayahNumber': n.ayahNumber,
                'note': n.note,
                'highlightText': n.highlightText,
                'highlightColor': n.highlightColor,
                'tags': n.tags,
                'createdAt': n.createdAt.toIso8601String(),
                'updatedAt': n.updatedAt.toIso8601String(),
              })
          .toList(),
      'readingHistory': getReadingHistory()
          .map((r) => {
                'surahNumber': r.surahNumber,
                'ayahNumber': r.ayahNumber,
                'lastReadAt': r.lastReadAt.toIso8601String(),
                'totalTimeSpentSeconds': r.totalTimeSpentSeconds,
              })
          .toList(),
      'listeningHistory': getListeningHistory()
          .map((l) => {
                'surahNumber': l.surahNumber,
                'ayahNumber': l.ayahNumber,
                'lastListenedAt': l.lastListenedAt.toIso8601String(),
                'totalListenTimeSeconds': l.totalListenTimeSeconds,
                'reciter': l.reciter,
                'playbackSpeed': l.playbackSpeed,
              })
          .toList(),
      'preferences': {
        'userName': getPreferences().userName,
        'isDarkMode': getPreferences().isDarkMode,
        'fontSize': getPreferences().fontSize,
        'language': getPreferences().language,
        'reciter': getPreferences().reciter,
        'playbackSpeed': getPreferences().playbackSpeed,
        'showTranslation': getPreferences().showTranslation,
        'enabledTranslations': getPreferences().enabledTranslations,
      },
      'exportedAt': DateTime.now().toIso8601String(),
      'version': '1.0.0',
    };
  }

  /// Import data from JSON
  Future<void> importData(Map<String, dynamic> data) async {
    try {
      if (data['bookmarks'] != null) {
        for (final bookmarkData in data['bookmarks']) {
          final bookmark = Bookmark(
            id: bookmarkData['id'],
            title: bookmarkData['title'],
            type: bookmarkData['type'],
            surahNumber: bookmarkData['surahNumber'],
            ayahNumber: bookmarkData['ayahNumber'],
            notes: bookmarkData['notes'],
            tags: List<String>.from(bookmarkData['tags'] ?? []),
            category: bookmarkData['category'],
            color: bookmarkData['color'],
            createdAt: DateTime.parse(bookmarkData['createdAt']),
            updatedAt: DateTime.parse(bookmarkData['updatedAt']),
          );
          await addBookmark(bookmark);
        }
      }

      if (data['studyNotes'] != null) {
        for (final noteData in data['studyNotes']) {
          final note = StudyNote(
            id: noteData['id'],
            surahNumber: noteData['surahNumber'],
            ayahNumber: noteData['ayahNumber'],
            note: noteData['note'],
            highlightText: noteData['highlightText'],
            highlightColor: noteData['highlightColor'],
            tags: List<String>.from(noteData['tags'] ?? []),
            createdAt: DateTime.parse(noteData['createdAt']),
            updatedAt: DateTime.parse(noteData['updatedAt']),
          );
          await addStudyNote(note);
        }
      }

      debugPrint('Data imported successfully');
    } catch (e) {
      debugPrint('Error importing data: $e');
      rethrow;
    }
  }

  /// Clear all data
  Future<void> clearAllData() async {
    await Future.wait([
      clearCachedSurahs(),
      clearBookmarks(),
      clearReadingProgress(),
      clearListeningProgress(),
      clearStudyNotes(),
      clearTranslations(),
    ]);
  }

  /// Get storage statistics
  Future<Map<String, dynamic>> getStorageStats() async {
    return {
      'cachedSurahs': getAllCachedSurahs().length,
      'bookmarks': getAllBookmarks().length,
      'studyNotes': getAllStudyNotes().length,
      'readingHistory': getReadingHistory().length,
      'listeningHistory': getListeningHistory().length,
      'translations': getAllCachedTranslations().length,
      'cacheSize': await getCacheSize(),
    };
  }

  /// Close all boxes
  Future<void> close() async {
    await Hive.close();
    _isInitialized = false;
  }

  Future<void> cacheReciters(List<Reciter> reciters) async {
    final box = Hive.box(_metaBox);
    await box.put(
      'reciters',
      reciters.map((reciter) => reciter.toJson()).toList(),
    );
    await box.put('reciters_cached_at', DateTime.now().toIso8601String());
  }

  List<Reciter> getCachedReciters() {
    final box = Hive.box(_metaBox);
    final raw = box.get('reciters');
    if (raw is List) {
      final result = <Reciter>[];
      for (final entry in raw) {
        if (entry is Map<String, dynamic>) {
          result.add(Reciter.fromJson(entry));
        } else if (entry is Map) {
          result.add(Reciter.fromJson(entry.cast<String, dynamic>()));
        }
      }
      return result;
    }
    return const [];
  }

  DateTime? getRecitersCachedAt() {
    final box = Hive.box(_metaBox);
    final value = box.get('reciters_cached_at');
    if (value is DateTime) return value;
    if (value is String) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  Future<void> cacheHadithBooks(
      String languageCode, List<Map<String, dynamic>> books) async {
    final box = Hive.box(_metaBox);
    await box.put('hadith_books_$languageCode', books);
    await box.put('hadith_books_${languageCode}_cached_at',
        DateTime.now().toIso8601String());
  }

  List<Map<String, dynamic>>? getCachedHadithBooksRaw(String languageCode) {
    final box = Hive.box(_metaBox);
    final raw = box.get('hadith_books_$languageCode');
    if (raw is List) {
      return raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    return null;
  }

  DateTime? getHadithBooksCachedAt(String languageCode) {
    final box = Hive.box(_metaBox);
    final value = box.get('hadith_books_${languageCode}_cached_at');
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  Future<void> cacheHadithPage({
    required String book,
    required int page,
    required Map<String, dynamic> payload,
  }) async {
    final box = Hive.box(_metaBox);
    final key = 'hadith_page_${book}_$page';
    await box.put(key, payload);
    await box.put('${key}_cached_at', DateTime.now().toIso8601String());
  }

  Map<String, dynamic>? getCachedHadithPageRaw(
      {required String book, required int page}) {
    final box = Hive.box(_metaBox);
    final key = 'hadith_page_${book}_$page';
    final raw = box.get(key);
    if (raw is Map) {
      return Map<String, dynamic>.from(raw);
    }
    return null;
  }

  DateTime? getHadithPageCachedAt({required String book, required int page}) {
    final box = Hive.box(_metaBox);
    final baseKey = 'hadith_page_${book}_$page';
    final value = box.get('${baseKey}_cached_at');
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  /// Track hadith book reading progress
  Future<void> trackHadithReading({
    required String bookSlug,
    required String bookName,
    required int page,
  }) async {
    final box = Hive.box(_bookmarksBox);
    try {
      await box.put('last_hadith_read_book', bookSlug);
      await box.put('last_hadith_read_book_name', bookName);
      await box.put('last_hadith_read_page', page);
      await box.put('last_hadith_read_time', DateTime.now().toString());
    } catch (e) {
      debugPrint('Error tracking hadith reading: $e');
    }
  }

  /// Get last hadith reading progress
  Map<String, dynamic>? getLastHadithReading() {
    final box = Hive.box(_bookmarksBox);
    try {
      final bookSlug = box.get('last_hadith_read_book');
      final bookName = box.get('last_hadith_read_book_name');
      final page = box.get('last_hadith_read_page');
      final time = box.get('last_hadith_read_time');

      if (bookSlug == null || page == null) return null;

      return {
        'bookSlug': bookSlug,
        'bookName': bookName ?? bookSlug,
        'page': page,
        'time': time,
      };
    } catch (e) {
      debugPrint('Error getting last hadith reading: $e');
      return null;
    }
  }

  /// Clear hadith reading progress
  Future<void> clearHadithReading() async {
    final box = Hive.box(_bookmarksBox);
    try {
      await box.delete('last_hadith_read_book');
      await box.delete('last_hadith_read_book_name');
      await box.delete('last_hadith_read_page');
      await box.delete('last_hadith_read_time');
    } catch (e) {
      debugPrint('Error clearing hadith reading: $e');
    }
  }

  Box get bookmarksBox => Hive.box(_bookmarksBox);
}

/// Global database instance
final DatabaseService database = DatabaseService();
