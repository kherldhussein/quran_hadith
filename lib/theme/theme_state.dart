import 'package:flutter/material.dart';

class ThemeState extends ChangeNotifier {
  static bool isDarkMode = false;

  void updateTheme(bool isdarkmode) {
    isDarkMode = isdarkmode;
    notifyListeners();
  }
}
