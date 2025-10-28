
part of 'hive_adapters.dart';


class CachedSurahAdapter extends TypeAdapter<CachedSurah> {
  @override
  final int typeId = 0;

  @override
  CachedSurah read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CachedSurah(
      number: fields[0] as int,
      name: fields[1] as String,
      englishName: fields[2] as String,
      englishNameTranslation: fields[3] as String,
      revelationType: fields[4] as String,
      numberOfAyahs: fields[5] as int,
      ayahs: (fields[6] as List).cast<CachedAyah>(),
      cachedAt: fields[7] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, CachedSurah obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.number)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.englishName)
      ..writeByte(3)
      ..write(obj.englishNameTranslation)
      ..writeByte(4)
      ..write(obj.revelationType)
      ..writeByte(5)
      ..write(obj.numberOfAyahs)
      ..writeByte(6)
      ..write(obj.ayahs)
      ..writeByte(7)
      ..write(obj.cachedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CachedSurahAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class CachedAyahAdapter extends TypeAdapter<CachedAyah> {
  @override
  final int typeId = 1;

  @override
  CachedAyah read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CachedAyah(
      number: fields[0] as int,
      text: fields[1] as String,
      numberInSurah: fields[2] as int,
      juz: fields[3] as int,
      audioUrl: fields[4] as String?,
      translation: fields[5] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, CachedAyah obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.number)
      ..writeByte(1)
      ..write(obj.text)
      ..writeByte(2)
      ..write(obj.numberInSurah)
      ..writeByte(3)
      ..write(obj.juz)
      ..writeByte(4)
      ..write(obj.audioUrl)
      ..writeByte(5)
      ..write(obj.translation);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CachedAyahAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class BookmarkAdapter extends TypeAdapter<Bookmark> {
  @override
  final int typeId = 2;

  @override
  Bookmark read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Bookmark(
      id: fields[0] as String?,
      title: fields[1] as String,
      type: fields[2] as String,
      surahNumber: fields[3] as int,
      ayahNumber: fields[4] as int?,
      notes: fields[5] as String?,
      tags: (fields[6] as List?)?.cast<String>(),
      category: fields[7] as String?,
      createdAt: fields[8] as DateTime?,
      updatedAt: fields[9] as DateTime?,
      color: fields[10] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Bookmark obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.surahNumber)
      ..writeByte(4)
      ..write(obj.ayahNumber)
      ..writeByte(5)
      ..write(obj.notes)
      ..writeByte(6)
      ..write(obj.tags)
      ..writeByte(7)
      ..write(obj.category)
      ..writeByte(8)
      ..write(obj.createdAt)
      ..writeByte(9)
      ..write(obj.updatedAt)
      ..writeByte(10)
      ..write(obj.color);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BookmarkAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ReadingProgressAdapter extends TypeAdapter<ReadingProgress> {
  @override
  final int typeId = 3;

  @override
  ReadingProgress read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ReadingProgress(
      surahNumber: fields[0] as int,
      ayahNumber: fields[1] as int,
      lastReadAt: fields[2] as DateTime?,
      totalTimeSpentSeconds: fields[3] as int,
      scrollPosition: fields[4] as double,
    );
  }

  @override
  void write(BinaryWriter writer, ReadingProgress obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.surahNumber)
      ..writeByte(1)
      ..write(obj.ayahNumber)
      ..writeByte(2)
      ..write(obj.lastReadAt)
      ..writeByte(3)
      ..write(obj.totalTimeSpentSeconds)
      ..writeByte(4)
      ..write(obj.scrollPosition);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReadingProgressAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ListeningProgressAdapter extends TypeAdapter<ListeningProgress> {
  @override
  final int typeId = 4;

  @override
  ListeningProgress read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ListeningProgress(
      surahNumber: fields[0] as int,
      ayahNumber: fields[1] as int,
      positionMs: fields[2] as int,
      lastListenedAt: fields[3] as DateTime?,
      totalListenTimeSeconds: fields[4] as int,
      completed: fields[5] as bool,
      reciter: fields[6] as String,
      playbackSpeed: fields[7] as double,
    );
  }

  @override
  void write(BinaryWriter writer, ListeningProgress obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.surahNumber)
      ..writeByte(1)
      ..write(obj.ayahNumber)
      ..writeByte(2)
      ..write(obj.positionMs)
      ..writeByte(3)
      ..write(obj.lastListenedAt)
      ..writeByte(4)
      ..write(obj.totalListenTimeSeconds)
      ..writeByte(5)
      ..write(obj.completed)
      ..writeByte(6)
      ..write(obj.reciter)
      ..writeByte(7)
      ..write(obj.playbackSpeed);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ListeningProgressAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class StudyNoteAdapter extends TypeAdapter<StudyNote> {
  @override
  final int typeId = 5;

  @override
  StudyNote read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return StudyNote(
      id: fields[0] as String?,
      surahNumber: fields[1] as int,
      ayahNumber: fields[2] as int,
      note: fields[3] as String,
      highlightText: fields[4] as String?,
      highlightColor: fields[5] as String,
      createdAt: fields[6] as DateTime?,
      updatedAt: fields[7] as DateTime?,
      tags: (fields[8] as List?)?.cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, StudyNote obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.surahNumber)
      ..writeByte(2)
      ..write(obj.ayahNumber)
      ..writeByte(3)
      ..write(obj.note)
      ..writeByte(4)
      ..write(obj.highlightText)
      ..writeByte(5)
      ..write(obj.highlightColor)
      ..writeByte(6)
      ..write(obj.createdAt)
      ..writeByte(7)
      ..write(obj.updatedAt)
      ..writeByte(8)
      ..write(obj.tags);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StudyNoteAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class TranslationDataAdapter extends TypeAdapter<TranslationData> {
  @override
  final int typeId = 6;

  @override
  TranslationData read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TranslationData(
      identifier: fields[0] as String,
      language: fields[1] as String,
      name: fields[2] as String,
      translator: fields[3] as String,
      ayahTranslations: (fields[4] as Map).cast<String, String>(),
      cachedAt: fields[5] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, TranslationData obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.identifier)
      ..writeByte(1)
      ..write(obj.language)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.translator)
      ..writeByte(4)
      ..write(obj.ayahTranslations)
      ..writeByte(5)
      ..write(obj.cachedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TranslationDataAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class UserPreferencesAdapter extends TypeAdapter<UserPreferences> {
  @override
  final int typeId = 7;

  @override
  UserPreferences read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserPreferences(
      userName: fields[0] as String,
      isDarkMode: fields[1] as bool,
      fontSize: fields[2] as double,
      fontFamily: fields[3] as String,
      language: fields[4] as String,
      reciter: fields[5] as String,
      playbackSpeed: fields[6] as double,
      autoScroll: fields[7] as bool,
      showTranslation: fields[8] as bool,
      enabledTranslations: (fields[9] as List?)?.cast<String>(),
      enableNotifications: fields[10] as bool,
      enableSystemTray: fields[11] as bool,
      theme: fields[12] as String,
      enableGlobalShortcuts: fields[13] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, UserPreferences obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.userName)
      ..writeByte(1)
      ..write(obj.isDarkMode)
      ..writeByte(2)
      ..write(obj.fontSize)
      ..writeByte(3)
      ..write(obj.fontFamily)
      ..writeByte(4)
      ..write(obj.language)
      ..writeByte(5)
      ..write(obj.reciter)
      ..writeByte(6)
      ..write(obj.playbackSpeed)
      ..writeByte(7)
      ..write(obj.autoScroll)
      ..writeByte(8)
      ..write(obj.showTranslation)
      ..writeByte(9)
      ..write(obj.enabledTranslations)
      ..writeByte(10)
      ..write(obj.enableNotifications)
      ..writeByte(11)
      ..write(obj.enableSystemTray)
      ..writeByte(12)
      ..write(obj.theme)
      ..writeByte(13)
      ..write(obj.enableGlobalShortcuts);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserPreferencesAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ReadingGoalAdapter extends TypeAdapter<ReadingGoal> {
  @override
  final int typeId = 8;

  @override
  ReadingGoal read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ReadingGoal(
      dailyAyahTarget: fields[0] as int,
      dailyMinutesTarget: fields[1] as int,
      dailyProgress: (fields[2] as Map?)?.cast<String, int>(),
      createdAt: fields[3] as DateTime?,
      enabled: fields[4] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, ReadingGoal obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.dailyAyahTarget)
      ..writeByte(1)
      ..write(obj.dailyMinutesTarget)
      ..writeByte(2)
      ..write(obj.dailyProgress)
      ..writeByte(3)
      ..write(obj.createdAt)
      ..writeByte(4)
      ..write(obj.enabled);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReadingGoalAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
