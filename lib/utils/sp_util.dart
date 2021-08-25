import 'package:quran_hadith/utils/shared_p.dart';
class SpUtil {
  static String isFavorite = 'FAVORITE';
  static bool? getFavorite() => appSP.getBool(isFavorite);
  static Future<bool> setFavorite(bool value) => appSP.setBool(isFavorite, value);
}
