import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeState extends GetxController {
  static ThemeState get to => Get.find();

  late SharedPreferences prefs;
  ThemeMode? _themeMode;

  ThemeMode? get themeMode => _themeMode;

  Future<void> updateTheme(ThemeMode themeMode) async {
    Get.changeThemeMode(themeMode);
    _themeMode = themeMode;
    update();
    prefs = await SharedPreferences.getInstance();
    String themeTextString = themeMode.toString().split('.')[1];
    setStatusBarBrightness(themeTextString);
    await prefs.setString('theme', themeTextString);
  }

  getThemeModeFromPreferences() async {
    ThemeMode themeMode;
    prefs = await SharedPreferences.getInstance();
    String themeTextString = prefs.getString('theme') ?? 'system';
    setStatusBarBrightness(themeTextString);
    if (themeTextString == "dark") {
      themeMode = ThemeMode.dark;
    } else if (themeTextString == "light") {
      themeMode = ThemeMode.light;
    } else {
      themeMode = ThemeMode.light;
    }
    updateTheme(themeMode);
  }

  setStatusBarBrightness(themeTextString) {
    if (themeTextString == "dark") {
      SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarBrightness: Brightness.dark,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.black,
        systemNavigationBarIconBrightness: Brightness.light,
      ));
    } else if (themeTextString == "light") {
      SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarBrightness: Brightness.light,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Color(0xFFFFFFFF),
        systemNavigationBarIconBrightness: Brightness.dark,
      ));
    } else {
      SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarBrightness: Brightness.dark,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.black,
        systemNavigationBarIconBrightness: Brightness.light,
      ));
    }
  }
}
