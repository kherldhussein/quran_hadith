import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

@HiveType(typeId: 0)
class SurahList extends ChangeNotifier {
  @HiveField(0)
  final List<Surah>? surahs;

  SurahList({this.surahs});

  SurahList copyWith({List<Surah>? surahs}) {
    return SurahList(surahs: surahs ?? this.surahs);
  }

  factory SurahList.fromJSON(Map<String, dynamic> json) {
    Iterable surahlist = json['data']['surahs'];
    List<Surah> surahsList = surahlist.map((i) => Surah.fromJSON(i)).toList();

    return SurahList(surahs: surahsList);
  }
}

@HiveType(typeId: 1)
class Surah {
  Surah({
    this.name,
    this.ayahs,
    this.audio,
    this.number,
    this.englishName,
    this.revelationType,
    this.readVerseCount = 0,
    this.englishNameTranslation,
    this.numberOfAyahs, // Add numberOfAyahs to the constructor
  });

  @HiveField(0)
  final int? number;
  @HiveField(1)
  final String? name;
  final String? audio;
  @HiveField(2)
  int? readVerseCount;
  @HiveField(3)
  final List<Ayah>? ayahs;
  @HiveField(4)
  final String? englishName;
  @HiveField(5)
  final String? revelationType;
  @HiveField(6)
  final String? englishNameTranslation;
  @HiveField(7)
  final int? numberOfAyahs; // Add numberOfAyahs field

  Surah copyWith({
    int? number,
    String? name,
    int? readVerseCount,
    List<Ayah>? ayahs,
    String? audio,
    String? englishName,
    String? revelationType,
    String? englishNameTranslation,
    int? numberOfAyahs, // Add numberOfAyahs to copyWith
  }) {
    return Surah(
      ayahs: ayahs ?? this.ayahs,
      name: name ?? this.name,
      audio: audio ?? this.audio,
      number: number ?? this.number,
      englishName: englishName ?? this.englishName,
      revelationType: revelationType ?? this.revelationType,
      englishNameTranslation:
          englishNameTranslation ?? this.englishNameTranslation,
      numberOfAyahs:
          numberOfAyahs ?? this.numberOfAyahs, // Update numberOfAyahs
    );
  }

  factory Surah.fromJSON(Map<String, dynamic> json) {
    Iterable ayahs = json['ayahs'];
    List<Ayah> ayahsList = ayahs.map((x) => Ayah.fromJSON((x))).toList();

    return Surah(
      ayahs: ayahsList,
      name: json['name'],
      audio: json['audio'],
      number: json['number'],
      englishName: json['englishName'],
      revelationType: json['revelationType'],
      englishNameTranslation: json['englishNameTranslation'],
      numberOfAyahs: json[
          'numberOfAyahs'], // Assuming 'numberOfAyahs' might come from JSON as well
    );
  }
}

@HiveType(typeId: 2)
class Ayah {
  Ayah({
    this.text,
    this.number,
    this.words,
  });

  final String? text;
  final int? number;
  final List<Word>? words; // Word-level timing information for highlighting

  Ayah copyWith({int? number, String? text, List<Word>? words}) {
    return Ayah(
      number: number ?? this.number,
      text: text ?? this.text,
      words: words ?? this.words,
    );
  }

  factory Ayah.fromJSON(Map<String, dynamic> json) {
    final words = json['words'] != null
        ? (json['words'] as List).map((w) => Word.fromJSON(w)).toList()
        : null;

    return Ayah(
      text: json['text'],
      number: json['numberInSurah'],
      words: words,
    );
  }
}

/// Represents a word in the Quran with timing information for highlighting
@HiveType(typeId: 7)
class Word {
  Word({
    this.text,
    this.position,
    this.duration,
    this.startTime,
  });

  @HiveField(0)
  final String? text; // The actual word

  @HiveField(1)
  final int? position; // Position in milliseconds from start of ayah

  @HiveField(2)
  final int? duration; // Duration in milliseconds

  @HiveField(3)
  final int? startTime; // Start time in milliseconds (absolute)

  factory Word.fromJSON(Map<String, dynamic> json) {
    return Word(
      text: json['text'],
      position: json['position'],
      duration: json['duration'],
      startTime: json['startTime'],
    );
  }
}

class Audio {
  Audio({this.number, this.url});

  final String? url;
  final Ayah? number;

  factory Audio.fromJson(Map<String, dynamic> json) {
    return Audio(number: json[''], url: json['']);
  }
}

class Sura {
  Sura({this.index, this.count, this.juz, this.name, this.verse});

  final String? index;
  final String? name;
  final Map<String, String>? verse;
  final int? count;
  final List? juz;

  factory Sura.fromData(Map<String, dynamic> data) => Sura(
        index: data['index'],
        name: data['name'],
        count: data[1],
        verse: Map.from(data['verse']).map(
          (key, value) => MapEntry<String, String>(key, value),
        ),
      );
}
