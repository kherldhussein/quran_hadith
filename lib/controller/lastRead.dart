import 'package:quran_hadith/utils/shared_p.dart';

class LastReadQ {
  static const String savedDataKey = 'SAVEDDATAKEY';

  /// Save last read as a two-item list: [ayahNo, surahName]
  static Future<bool> saveLastRead(
      {required String ayahNo, required String surahName}) async {
    try {
      return await appSP.setListString(savedDataKey, [ayahNo, surahName]);
    } catch (e) {
      return false;
    }
  }

  /// Retrieve last read as a list [ayahNo, surahName]. Returns empty list if not set.
  static Future<List<String>> getLastRead() async {
    try {
      final data = appSP.getListString(savedDataKey, defaultValue: const []);
      return data;
    } catch (e) {
      return [];
    }
  }
}
