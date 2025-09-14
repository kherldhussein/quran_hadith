class DailyAyah {
  final int surahNumber;
  final int ayahNumber;
  final String surahName;
  final String arabicText;
  final String translation;
  final String edition;

  const DailyAyah({
    required this.surahNumber,
    required this.ayahNumber,
    required this.surahName,
    required this.arabicText,
    required this.translation,
    this.edition = 'en.sahih',
  });

  String get reference => 'Surah $surahNumber:$ayahNumber';

  Map<String, dynamic> toJson() {
    return {
      'surahNumber': surahNumber,
      'ayahNumber': ayahNumber,
      'surahName': surahName,
      'arabicText': arabicText,
      'translation': translation,
      'edition': edition,
    };
  }

  factory DailyAyah.fromJson(Map<String, dynamic> json) {
    return DailyAyah(
      surahNumber: json['surahNumber'] as int,
      ayahNumber: json['ayahNumber'] as int,
      surahName: json['surahName'] as String? ?? 'Surah ${json['surahNumber']}',
      arabicText: json['arabicText'] as String? ?? '',
      translation: json['translation'] as String? ?? '',
      edition: json['edition'] as String? ?? 'en.sahih',
    );
  }
}
