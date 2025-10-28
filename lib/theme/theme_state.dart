import 'package:flutter/material.dart';
import 'package:quran_hadith/utils/sp_util.dart';

class ThemeState extends ChangeNotifier {
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  /// Update theme (toggle) - instantly notifies all listeners
  void updateTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
    SpUtil.setThemed(_isDarkMode).catchError((e) {
      debugPrint('❌ Failed to save theme preference: $e');
      return false;
    });
  }

  /// Set theme to a specific mode (not toggle) - instantly notifies all listeners
  void setTheme(bool isDark) {
    if (_isDarkMode == isDark) return; // No change needed
    _isDarkMode = isDark;
    notifyListeners();
    SpUtil.setThemed(_isDarkMode).catchError((e) {
      debugPrint('❌ Failed to save theme preference: $e');
      return false;
    });
  }

  /// Load theme at startup (synchronous for initial state)
  Future<void> loadTheme(bool dark) async {
    _isDarkMode = dark;
    notifyListeners();
  }
}
