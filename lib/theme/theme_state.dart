import 'package:flutter/material.dart';
import 'package:quran_hadith/utils/sp_util.dart';

class ThemeState extends ChangeNotifier {
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  void updateTheme() async {
    _isDarkMode = !_isDarkMode;
    await SpUtil.setThemed(_isDarkMode);
    notifyListeners();
  }

  Future<void> loadTheme(bool dark) async {
    _isDarkMode = SpUtil.getThemed()!;
    _isDarkMode = dark;
    notifyListeners();
  }
}
