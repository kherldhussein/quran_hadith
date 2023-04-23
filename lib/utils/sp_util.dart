import 'package:quran_hadith/utils/shared_p.dart';

class SpUtil {
  static String isFavorite = 'FAVORITE';
  static String user = 'user';

  static bool? getFavorite() => appSP.getBool(isFavorite);

  static String? getUser() => appSP.getString(user);

  static Future<bool> setFavorite(bool value) =>
      appSP.setBool(isFavorite, value);

  static Future<bool> setUser(bool value) => appSP.setBool(user, value);
}
