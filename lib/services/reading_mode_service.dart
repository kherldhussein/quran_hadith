import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service to manage various reading modes for enhanced reading experience
class ReadingModeService extends ChangeNotifier {
  static final ReadingModeService _instance = ReadingModeService._internal();
  factory ReadingModeService() => _instance;
  ReadingModeService._internal();

  // Reading mode states
  bool _focusMode = false;
  bool _nightMode = false;
  bool _dyslexiaMode = false;
  bool _autoNightMode = true;
  double _blueLight = 0.0; // 0.0 = no filter, 1.0 = maximum filter

  // Getters
  bool get focusMode => _focusMode;
  bool get nightMode => _nightMode;
  bool get dyslexiaMode => _dyslexiaMode;
  bool get autoNightMode => _autoNightMode;
  double get blueLight => _blueLight;

  // Preferences keys
  static const String _keyFocusMode = 'reading_focus_mode';
  static const String _keyNightMode = 'reading_night_mode';
  static const String _keyDyslexiaMode = 'reading_dyslexia_mode';
  static const String _keyAutoNightMode = 'reading_auto_night_mode';
  static const String _keyBlueLight = 'reading_blue_light';

  /// Initialize reading mode service and load saved preferences
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();

    _focusMode = prefs.getBool(_keyFocusMode) ?? false;
    _nightMode = prefs.getBool(_keyNightMode) ?? false;
    _dyslexiaMode = prefs.getBool(_keyDyslexiaMode) ?? false;
    _autoNightMode = prefs.getBool(_keyAutoNightMode) ?? true;
    _blueLight = prefs.getDouble(_keyBlueLight) ?? 0.0;

    // Check if auto night mode should be enabled based on time
    if (_autoNightMode) {
      _checkAutoNightMode();
    }

    notifyListeners();
    debugPrint('📖 Reading Mode Service initialized');
  }

  /// Toggle focus mode (hide UI, show only ayah text)
  Future<void> toggleFocusMode() async {
    _focusMode = !_focusMode;
    await _saveBool(_keyFocusMode, _focusMode);
    notifyListeners();
    debugPrint('📖 Focus mode: ${_focusMode ? "ON" : "OFF"}');
  }

  /// Toggle night mode (OLED-black background)
  Future<void> toggleNightMode() async {
    _nightMode = !_nightMode;
    await _saveBool(_keyNightMode, _nightMode);
    notifyListeners();
    debugPrint('🌙 Night mode: ${_nightMode ? "ON" : "OFF"}');
  }

  /// Toggle dyslexia-friendly mode
  Future<void> toggleDyslexiaMode() async {
    _dyslexiaMode = !_dyslexiaMode;
    await _saveBool(_keyDyslexiaMode, _dyslexiaMode);
    notifyListeners();
    debugPrint('📖 Dyslexia mode: ${_dyslexiaMode ? "ON" : "OFF"}');
  }

  /// Toggle auto night mode based on system time
  Future<void> toggleAutoNightMode() async {
    _autoNightMode = !_autoNightMode;
    await _saveBool(_keyAutoNightMode, _autoNightMode);

    if (_autoNightMode) {
      _checkAutoNightMode();
    }

    notifyListeners();
    debugPrint('🌙 Auto night mode: ${_autoNightMode ? "ON" : "OFF"}');
  }

  /// Set blue light filter intensity (0.0 to 1.0)
  Future<void> setBlueLight(double value) async {
    _blueLight = value.clamp(0.0, 1.0);
    await _saveDouble(_keyBlueLight, _blueLight);
    notifyListeners();
    debugPrint('💡 Blue light filter: ${(_blueLight * 100).toStringAsFixed(0)}%');
  }

  /// Check if night mode should be auto-enabled based on time
  /// Night mode: 8 PM (20:00) to 6 AM (6:00)
  void _checkAutoNightMode() {
    if (!_autoNightMode) return;

    final now = DateTime.now();
    final hour = now.hour;

    // Night time: 8 PM to 6 AM
    final shouldBeNightMode = hour >= 20 || hour < 6;

    if (shouldBeNightMode != _nightMode) {
      _nightMode = shouldBeNightMode;
      _saveBool(_keyNightMode, _nightMode);
      notifyListeners();
      debugPrint('🌙 Auto night mode ${_nightMode ? "enabled" : "disabled"} at $hour:00');
    }
  }

  /// Get the appropriate font family based on dyslexia mode
  String getFontFamily({bool isArabic = false}) {
    if (isArabic) {
      return 'Amiri'; // Always use Amiri for Arabic text
    }

    if (_dyslexiaMode) {
      // TODO: Add OpenDyslexic font to assets
      return 'OpenDyslexic';
    }

    return 'Poppins';
  }

  /// Get text style modifications for dyslexia mode
  TextStyle applyDyslexiaModifications(TextStyle baseStyle) {
    if (!_dyslexiaMode) return baseStyle;

    return baseStyle.copyWith(
      letterSpacing: (baseStyle.letterSpacing ?? 0.0) + 1.2,
      wordSpacing: (baseStyle.wordSpacing ?? 0.0) + 2.0,
      height: (baseStyle.height ?? 1.0) * 1.5,
    );
  }

  /// Get background color based on night mode
  Color getBackgroundColor(Color defaultColor) {
    if (_nightMode) {
      return Colors.black; // OLED-black
    }
    return defaultColor;
  }

  /// Get surface color based on night mode
  Color getSurfaceColor(Color defaultColor) {
    if (_nightMode) {
      return const Color(0xFF0A0A0A); // Near-black for cards
    }
    return defaultColor;
  }

  /// Get text color based on night mode
  Color getTextColor(Color defaultColor) {
    if (_nightMode) {
      return const Color(0xFFE0E0E0); // Soft white
    }
    return defaultColor;
  }

  /// Apply blue light filter to a color
  Color applyBlueLight(Color color) {
    if (_blueLight == 0.0) return color;

    // Reduce blue channel based on filter intensity
    final r = color.red;
    final g = color.green;
    final b = (color.blue * (1.0 - _blueLight * 0.7)).round();

    // Slightly increase red/orange tones for warmth
    final rWarm = (r + (255 - r) * _blueLight * 0.1).round();
    final gWarm = (g + (200 - g) * _blueLight * 0.05).round();

    return Color.fromARGB(color.alpha, rWarm, gWarm, b);
  }

  /// Save boolean preference
  Future<void> _saveBool(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  /// Save double preference
  Future<void> _saveDouble(String key, double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(key, value);
  }

  /// Periodic check for auto night mode (call every hour)
  void checkAutoNightModeScheduled() {
    if (_autoNightMode) {
      _checkAutoNightMode();
    }
  }
}
