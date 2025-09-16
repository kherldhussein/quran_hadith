import 'package:hive/hive.dart';

part 'hive_adapters.g.dart';

/// Cached Surah data for offline access
@HiveType(typeId: 0)
class CachedSurah extends HiveObject {
  @HiveField(0)
  final int number;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String englishName;

  @HiveField(3)
  final String englishNameTranslation;

  @HiveField(4)
  final String revelationType;

  @HiveField(5)
  final int numberOfAyahs;

  @HiveField(6)
  final List<CachedAyah> ayahs;

  @HiveField(7)
  final DateTime cachedAt;

  CachedSurah({
    required this.number,
    required this.name,
    required this.englishName,
    required this.englishNameTranslation,
    required this.revelationType,
    required this.numberOfAyahs,
    required this.ayahs,
    DateTime? cachedAt,
  }) : cachedAt = cachedAt ?? DateTime.now();
}

/// Cached Ayah data
@HiveType(typeId: 1)
class CachedAyah {
  @HiveField(0)
  final int number;

  @HiveField(1)
  final String text;

  @HiveField(2)
  final int numberInSurah;

  @HiveField(3)
  final int juz;

  @HiveField(4)
  final String? audioUrl;

  @HiveField(5)
  final String? translation;

  CachedAyah({
    required this.number,
    required this.text,
    required this.numberInSurah,
    required this.juz,
    this.audioUrl,
    this.translation,
  });
}

/// Bookmark with enhanced features
@HiveType(typeId: 2)
class Bookmark extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String title;

  @HiveField(2)
  late String type; // 'surah', 'ayah', 'page'

  @HiveField(3)
  late int surahNumber;

  @HiveField(4)
  late int? ayahNumber;

  @HiveField(5)
  late String? notes;

  @HiveField(6)
  late List<String> tags;

  @HiveField(7)
  late String? category;

  @HiveField(8)
  late DateTime createdAt;

  @HiveField(9)
  late DateTime updatedAt;

  @HiveField(10)
  late String? color;

  Bookmark({
    String? id,
    required this.title,
    this.type = 'ayah',
    required this.surahNumber,
    this.ayahNumber,
    this.notes,
    List<String>? tags,
    this.category,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.color,
  })  : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        tags = tags ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();
}

/// Reading progress tracker
@HiveType(typeId: 3)
class ReadingProgress extends HiveObject {
  @HiveField(0)
  late int surahNumber;

  @HiveField(1)
  late int ayahNumber;

  @HiveField(2)
  late DateTime lastReadAt;

  @HiveField(3)
  late int totalTimeSpentSeconds;

  @HiveField(4)
  late double scrollPosition;

  ReadingProgress({
    required this.surahNumber,
    required this.ayahNumber,
    DateTime? lastReadAt,
    this.totalTimeSpentSeconds = 0,
    this.scrollPosition = 0.0,
  }) : lastReadAt = lastReadAt ?? DateTime.now();
}

/// Listening progress tracker
@HiveType(typeId: 4)
class ListeningProgress extends HiveObject {
  @HiveField(0)
  late int surahNumber;

  @HiveField(1)
  late int ayahNumber;

  @HiveField(2)
  late int positionMs;

  @HiveField(3)
  late DateTime lastListenedAt;

  @HiveField(4)
  late int totalListenTimeSeconds;

  @HiveField(5)
  late bool completed;

  @HiveField(6)
  late String reciter;

  @HiveField(7)
  late double playbackSpeed;

  ListeningProgress({
    required this.surahNumber,
    required this.ayahNumber,
    this.positionMs = 0,
    DateTime? lastListenedAt,
    this.totalListenTimeSeconds = 0,
    this.completed = false,
    this.reciter = 'ar.alafasy',
    this.playbackSpeed = 1.0,
  }) : lastListenedAt = lastListenedAt ?? DateTime.now();
}

/// Study note with highlighting and annotations
@HiveType(typeId: 5)
class StudyNote extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late int surahNumber;

  @HiveField(2)
  late int ayahNumber;

  @HiveField(3)
  late String note;

  @HiveField(4)
  late String? highlightText;

  @HiveField(5)
  late String highlightColor;

  @HiveField(6)
  late DateTime createdAt;

  @HiveField(7)
  late DateTime updatedAt;

  @HiveField(8)
  late List<String> tags;

  StudyNote({
    String? id,
    required this.surahNumber,
    required this.ayahNumber,
    required this.note,
    this.highlightText,
    this.highlightColor = '#FFEB3B',
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? tags,
  })  : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now(),
        tags = tags ?? [];
}

/// Translation data
@HiveType(typeId: 6)
class TranslationData extends HiveObject {
  @HiveField(0)
  final String identifier; // e.g., 'en.sahih', 'en.pickthall'

  @HiveField(1)
  final String language;

  @HiveField(2)
  final String name;

  @HiveField(3)
  final String translator;

  @HiveField(4)
  final Map<String, String> ayahTranslations; // key: surah:ayah, value: translation

  @HiveField(5)
  final DateTime cachedAt;

  TranslationData({
    required this.identifier,
    required this.language,
    required this.name,
    required this.translator,
    required this.ayahTranslations,
    DateTime? cachedAt,
  }) : cachedAt = cachedAt ?? DateTime.now();
}

/// User preferences
@HiveType(typeId: 7)
class UserPreferences extends HiveObject {
  @HiveField(0)
  late String userName;

  @HiveField(1)
  late bool isDarkMode;

  @HiveField(2)
  late double fontSize;

  @HiveField(3)
  late String fontFamily;

  @HiveField(4)
  late String language;

  @HiveField(5)
  late String reciter;

  @HiveField(6)
  late double playbackSpeed;

  @HiveField(7)
  late bool autoScroll;

  @HiveField(8)
  late bool showTranslation;

  @HiveField(9)
  late List<String> enabledTranslations;

  @HiveField(10)
  late bool enableNotifications;

  @HiveField(11)
  late bool enableSystemTray;

  @HiveField(12)
  late String theme; // 'light', 'dark', 'auto'

  @HiveField(13)
  late bool enableGlobalShortcuts;

  UserPreferences({
    this.userName = 'Guest',
    this.isDarkMode = false,
    this.fontSize = 24.0,
    this.fontFamily = 'Amiri',
    this.language = 'en',
    this.reciter = 'ar.alafasy',
    this.playbackSpeed = 1.0,
    this.autoScroll = false,
    this.showTranslation = true,
    List<String>? enabledTranslations,
    this.enableNotifications = true,
    this.enableSystemTray = true,
    this.theme = 'auto',
    this.enableGlobalShortcuts = false,
  }) : enabledTranslations = enabledTranslations ?? ['en.sahih'];
}

/// Daily reading goal
@HiveType(typeId: 8)
class ReadingGoal extends HiveObject {
  @HiveField(0)
  late int dailyAyahTarget;

  @HiveField(1)
  late int dailyMinutesTarget;

  @HiveField(2)
  late Map<String, int> dailyProgress; // date -> ayahsRead

  @HiveField(3)
  late DateTime createdAt;

  @HiveField(4)
  late bool enabled;

  ReadingGoal({
    this.dailyAyahTarget = 10,
    this.dailyMinutesTarget = 15,
    Map<String, int>? dailyProgress,
    DateTime? createdAt,
    this.enabled = false,
  })  : dailyProgress = dailyProgress ?? {},
        createdAt = createdAt ?? DateTime.now();
}
