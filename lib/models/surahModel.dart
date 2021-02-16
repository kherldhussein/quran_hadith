import 'package:flutter/material.dart';

class SurahsList extends ChangeNotifier {
  final List<Surah> surahs;

  SurahsList({this.surahs});

  factory SurahsList.fromJSON(Map<String, dynamic> json) {
    Iterable surahlist = json['data']['surahs'];
    List<Surah> surahsList = surahlist.map((i) => Surah.fromJSON(i)).toList();

    return SurahsList(surahs: surahsList);
  }

  Surah get currentSurah =>
      surahs.firstWhere((surah) => surah.number == _selectedSurahNo);

  Set<int> starredSurat = {};

  bool isSuratStarred(int number) => surahs
      .any((surah) => surah.number == number && starredSurat.contains(number));

  bool get isCurrentSurahStarred => starredSurat.contains(currentSurah.number);

  int _selectedSurahNo = -1;

  int get selectedSurahNumber => _selectedSurahNo;

  set selectedSurahNo(int value) {
    _selectedSurahNo = value;
    notifyListeners();
  }

  starSurah(int number) {
    starredSurat.add(number);
    notifyListeners();
  }
}

class Surah {
  Surah(
      {this.name,
      this.ayahs,
      this.number,
      this.englishName,
      this.revelationType,
      this.readVerseCount = 0,
      this.englishNameTranslation});

  final int number;
  final String name;
  int readVerseCount;
  final List<Ayah> ayahs;
  final String englishName;
  final String revelationType;
  final String englishNameTranslation;

  factory Surah.fromJSON(Map<String, dynamic> json) {
    Iterable ayahs = json['ayahs'];
    List<Ayah> ayahsList = ayahs.map((x) => Ayah.fromJSON((x))).toList();

    return Surah(
      ayahs: ayahsList,
      name: json['name'],
      number: json['number'],
      englishName: json['englishName'],
      revelationType: json['revelationType'],
      englishNameTranslation: json['englishNameTranslation'],
    );
  }
}

class Ayah {
  Ayah({this.text, this.number});

  final String text;
  final int number;

  factory Ayah.fromJSON(Map<String, dynamic> json) {
    return Ayah(text: json['text'], number: json['numberInSurah']);
  }
}

class Audio {
  Audio({this.number, this.url});

  final String url;
  final Ayah number;

  factory Audio.fromJson(Map<String, dynamic> json) {
    return Audio(number: json[''], url: json['']);
  }
}
