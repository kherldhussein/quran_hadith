import 'package:quran_hadith/utils/shared_p.dart';

class SpUtil {
  static String isFavorite = 'IS_FAVORITE';
  static String favorite = 'FAVORITE';
  static String user = 'user';
  static String isDarkMode = 'isDarkMode';

  static bool? getFavorite() => appSP.getBool(isFavorite);

  static bool? getThemed() => appSP.getBool(isDarkMode);

  static List<String>? getFavorites() => appSP.getListString(favorite);

  static String? getUser() => appSP.getString(user);

  static Future<bool> setFavorite(bool value) =>
      appSP.setBool(isFavorite, value);

  static Future<bool> setThemed(bool value) => appSP.setBool(isDarkMode, value);

  static Future<bool> setFavorites(List<String> value) =>
      appSP.setListString(favorite, value);

  static Future<bool> setUser(String value) => appSP.setString(user, value);
}
