import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LastReadQ {
  static String savedDataKey = "SAVEDDATAKEY";
  static Future saveLastRead(
      {@required String ayahNo, @required String surahName}) async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    pref.setStringList(savedDataKey, [ayahNo, surahName]);
  }

  static Future getLastRead() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String ayahNo = await pref.getString('savedDataKey');
    String surahName = await pref.getString('savedDataKey');
    pref.getStringList(savedDataKey);
  }
}
