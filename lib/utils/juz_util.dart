/// Utility class for handling Qur'anic Juz/Para (Parts) calculations
/// The Quran is divided into 30 Juz (parts), where each Juz contains
/// approximately equal portions of the Qur'anic text
class JuzUtil {
  /// Mapping of Juz numbers (1-30) to starting and ending surah numbers
  /// This is the official division of the Quran into 30 equal parts
  static const List<JuzRange> juzRanges = [
    JuzRange(1, 1, 1), // Juz 1: Surah 1, Ayah 1 to Surah 1, Ayah 141
    JuzRange(2, 1, 141), // Juz 2: Surah 1, Ayah 141 onwards
    JuzRange(3, 2, 141), // Juz 3: Surah 2, Ayah 141 onwards
    JuzRange(4, 2, 252), // Juz 4: Surah 2, Ayah 252 onwards
    JuzRange(5, 3, 91), // Juz 5: Surah 3, Ayah 91 onwards
    JuzRange(6, 3, 200), // Juz 6: Surah 3, Ayah 200 onwards
    JuzRange(7, 4, 24), // Juz 7: Surah 4, Ayah 24 onwards
    JuzRange(8, 4, 147), // Juz 8: Surah 4, Ayah 147 onwards
    JuzRange(9, 5, 82), // Juz 9: Surah 5, Ayah 82 onwards
    JuzRange(10, 6, 111), // Juz 10: Surah 6, Ayah 111 onwards
    JuzRange(11, 7, 87), // Juz 11: Surah 7, Ayah 87 onwards
    JuzRange(12, 8, 40), // Juz 12: Surah 8, Ayah 40 onwards
    JuzRange(13, 9, 92), // Juz 13: Surah 9, Ayah 92 onwards
    JuzRange(14, 11, 5), // Juz 14: Surah 11, Ayah 5 onwards
    JuzRange(15, 12, 53), // Juz 15: Surah 12, Ayah 53 onwards
    JuzRange(16, 14, 1), // Juz 16: Surah 14, Ayah 1 onwards
    JuzRange(17, 16, 1), // Juz 17: Surah 16, Ayah 1 onwards
    JuzRange(18, 18, 74), // Juz 18: Surah 18, Ayah 74 onwards
    JuzRange(19, 21, 1), // Juz 19: Surah 21, Ayah 1 onwards
    JuzRange(20, 23, 118), // Juz 20: Surah 23, Ayah 118 onwards
    JuzRange(21, 25, 20), // Juz 21: Surah 25, Ayah 20 onwards
    JuzRange(22, 27, 55), // Juz 22: Surah 27, Ayah 55 onwards
    JuzRange(23, 29, 45), // Juz 23: Surah 29, Ayah 45 onwards
    JuzRange(24, 33, 30), // Juz 24: Surah 33, Ayah 30 onwards
    JuzRange(25, 36, 27), // Juz 25: Surah 36, Ayah 27 onwards
    JuzRange(26, 39, 31), // Juz 26: Surah 39, Ayah 31 onwards
    JuzRange(27, 46, 1), // Juz 27: Surah 46, Ayah 1 onwards
    JuzRange(28, 51, 30), // Juz 28: Surah 51, Ayah 30 onwards
    JuzRange(29, 58, 1), // Juz 29: Surah 58, Ayah 1 onwards
    JuzRange(30, 67, 1), // Juz 30: Surah 67, Ayah 1 onwards (Amma)
  ];

  /// Get the Juz (Part) number for a given Surah number
  /// Returns 1-30 representing which Juz the surah belongs to
  static int getJuzForSurah(int surahNumber) {
    if (surahNumber < 1 || surahNumber > 114) {
      return 1; // Default to first juz for invalid surah numbers
    }

    for (int i = 0; i < juzRanges.length; i++) {
      final currentJuz = juzRanges[i];
      final nextJuz = i < juzRanges.length - 1 ? juzRanges[i + 1] : null;

      if (surahNumber >= currentJuz.startSurah) {
        if (nextJuz == null || surahNumber < nextJuz.startSurah) {
          return currentJuz.juzNumber;
        }
      }
    }

    return 30; // Default to last juz
  }

  /// Get all surahs in a specific Juz
  static List<int> getSurahsInJuz(int juzNumber) {
    if (juzNumber < 1 || juzNumber > 30) {
      return [];
    }

    final startJuz = juzRanges[juzNumber - 1];
    final endSurah = juzNumber < 30 ? juzRanges[juzNumber].startSurah - 1 : 114;

    final result = <int>[];
    for (int i = startJuz.startSurah; i <= endSurah && i <= 114; i++) {
      result.add(i);
    }
    return result;
  }

  /// Get Juz name/label (e.g., "Juz 15" or special names for Juz 30)
  static String getJuzName(int juzNumber) {
    if (juzNumber == 30) {
      return 'Juz 30 (Amma)'; // Last Juz is called "Amma" (the last)
    } else if (juzNumber < 1 || juzNumber > 30) {
      return 'Invalid Juz';
    }
    return 'Juz $juzNumber';
  }

  /// Check if a surah number is valid
  static bool isValidSurah(int surahNumber) {
    return surahNumber >= 1 && surahNumber <= 114;
  }

  /// Check if a juz number is valid
  static bool isValidJuz(int juzNumber) {
    return juzNumber >= 1 && juzNumber <= 30;
  }
}

/// Helper class representing a Juz range in the Quran
class JuzRange {
  final int juzNumber; // 1-30
  final int startSurah; // Starting surah number
  final int startAyah; // Starting ayah number in that surah

  const JuzRange(this.juzNumber, this.startSurah, this.startAyah);
}
