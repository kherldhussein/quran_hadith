import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Comprehensive custom theme system
///
/// Features:
/// - Custom theme builder
/// - Preset themes (Forest, Desert, Ocean, Classic)
/// - Import/export themes
/// - Per-element color customization
/// - Font family selection
/// - Background images/gradients
class ThemeService extends ChangeNotifier {
  static final ThemeService _instance = ThemeService._internal();

  factory ThemeService() => _instance;

  ThemeService._internal();

  // Current theme
  CustomTheme _currentTheme = CustomTheme.classic();
  List<CustomTheme> _savedThemes = [];

  // Getters
  CustomTheme get currentTheme => _currentTheme;

  List<CustomTheme> get savedThemes => _savedThemes;

  // Preferences keys
  static const String _keyCurrentTheme = 'theme_current';
  static const String _keySavedThemes = 'theme_saved_list';

  /// Initialize theme service
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();

    // Load current theme
    final currentThemeJson = prefs.getString(_keyCurrentTheme);
    if (currentThemeJson != null) {
      try {
        _currentTheme = CustomTheme.fromJson(json.decode(currentThemeJson));
      } catch (e) {
        debugPrint('⚠️ ThemeService: Failed to load current theme: $e');
        _currentTheme = CustomTheme.classic();
      }
    }

    // Load saved themes
    final savedThemesJson = prefs.getStringList(_keySavedThemes) ?? [];
    _savedThemes = savedThemesJson
        .map((themeJson) {
          try {
            return CustomTheme.fromJson(json.decode(themeJson));
          } catch (e) {
            debugPrint('⚠️ ThemeService: Failed to load saved theme: $e');
            return null;
          }
        })
        .whereType<CustomTheme>()
        .toList();

    // Add preset themes if none saved
    if (_savedThemes.isEmpty) {
      _savedThemes = [
        CustomTheme.classic(),
        CustomTheme.forest(),
        CustomTheme.desert(),
        CustomTheme.ocean(),
        CustomTheme.night(),
      ];
      await _saveThemesList();
    }

    notifyListeners();
    debugPrint('🎨 ThemeService initialized with theme: ${_currentTheme.name}');
  }

  /// Apply a theme
  Future<void> applyTheme(CustomTheme theme) async {
    _currentTheme = theme;
    await _saveCurrentTheme();
    notifyListeners();
    debugPrint('🎨 ThemeService: Applied theme: ${theme.name}');
  }

  /// Save a custom theme
  Future<void> saveTheme(CustomTheme theme) async {
    // Remove existing theme with same name
    _savedThemes.removeWhere((t) => t.name == theme.name);
    _savedThemes.add(theme);
    await _saveThemesList();
    notifyListeners();
    debugPrint('🎨 ThemeService: Saved theme: ${theme.name}');
  }

  /// Delete a saved theme
  Future<void> deleteTheme(String themeName) async {
    _savedThemes.removeWhere((t) => t.name == themeName);
    await _saveThemesList();
    notifyListeners();
    debugPrint('🎨 ThemeService: Deleted theme: $themeName');
  }

  /// Export theme to JSON string
  String exportTheme(CustomTheme theme) {
    return json.encode(theme.toJson());
  }

  /// Import theme from JSON string
  Future<CustomTheme?> importTheme(String jsonString) async {
    try {
      final theme = CustomTheme.fromJson(json.decode(jsonString));
      await saveTheme(theme);
      return theme;
    } catch (e) {
      debugPrint('⚠️ ThemeService: Failed to import theme: $e');
      return null;
    }
  }

  /// Get ThemeData from CustomTheme
  ThemeData getThemeData(CustomTheme theme) {
    final brightness = theme.isDark ? Brightness.dark : Brightness.light;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme.fromSeed(
        seedColor: theme.primaryColor,
        brightness: brightness,
        primary: theme.primaryColor,
        secondary: theme.accentColor,
        surface: theme.backgroundColor,
        onPrimary: theme.textOnPrimary,
        onSecondary: theme.textOnAccent,
        onSurface: theme.textColor,
      ),
      scaffoldBackgroundColor: theme.backgroundColor,
      appBarTheme: AppBarTheme(
        backgroundColor: theme.appBarColor,
        foregroundColor: theme.textOnPrimary,
        elevation: theme.elevation,
      ),
      cardTheme: CardThemeData(
        color: theme.cardColor,
        elevation: theme.elevation,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(theme.borderRadius),
        ),
      ),
      textTheme: TextTheme(
        bodyLarge: TextStyle(
          fontFamily: theme.bodyFontFamily,
          color: theme.textColor,
        ),
        bodyMedium: TextStyle(
          fontFamily: theme.bodyFontFamily,
          color: theme.textColor,
        ),
        bodySmall: TextStyle(
          fontFamily: theme.bodyFontFamily,
          color: theme.textColor.withOpacity(0.7),
        ),
        headlineLarge: TextStyle(
          fontFamily: theme.headingFontFamily,
          color: theme.textColor,
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: TextStyle(
          fontFamily: theme.headingFontFamily,
          color: theme.textColor,
          fontWeight: FontWeight.bold,
        ),
        headlineSmall: TextStyle(
          fontFamily: theme.headingFontFamily,
          color: theme.textColor,
          fontWeight: FontWeight.bold,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.primaryColor,
          foregroundColor: theme.textOnPrimary,
          elevation: theme.elevation,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(theme.borderRadius),
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: theme.accentColor,
        foregroundColor: theme.textOnAccent,
        elevation: theme.elevation,
      ),
    );
  }

  /// Save current theme
  Future<void> _saveCurrentTheme() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _keyCurrentTheme, json.encode(_currentTheme.toJson()));
  }

  /// Save themes list
  Future<void> _saveThemesList() async {
    final prefs = await SharedPreferences.getInstance();
    final themesJson =
        _savedThemes.map((t) => json.encode(t.toJson())).toList();
    await prefs.setStringList(_keySavedThemes, themesJson);
  }
}

/// Custom theme model
class CustomTheme {
  final String name;
  final String description;
  final bool isDark;

  // Colors
  final Color primaryColor;
  final Color accentColor;
  final Color backgroundColor;
  final Color cardColor;
  final Color appBarColor;
  final Color textColor;
  final Color textOnPrimary;
  final Color textOnAccent;
  final Color dividerColor;

  // Arabic text specific
  final Color arabicTextColor;
  final String arabicFontFamily;
  final double arabicFontSize;

  // Typography
  final String bodyFontFamily;
  final String headingFontFamily;

  // Layout
  final double borderRadius;
  final double elevation;

  // Background
  final BackgroundStyle backgroundStyle;
  final String? backgroundImagePath;
  final List<Color>? gradientColors;

  const CustomTheme({
    required this.name,
    this.description = '',
    this.isDark = false,
    required this.primaryColor,
    required this.accentColor,
    required this.backgroundColor,
    required this.cardColor,
    required this.appBarColor,
    required this.textColor,
    required this.textOnPrimary,
    required this.textOnAccent,
    required this.dividerColor,
    this.arabicTextColor = const Color(0xFF000000),
    this.arabicFontFamily = 'Amiri',
    this.arabicFontSize = 24.0,
    this.bodyFontFamily = 'Roboto',
    this.headingFontFamily = 'Roboto',
    this.borderRadius = 12.0,
    this.elevation = 2.0,
    this.backgroundStyle = BackgroundStyle.solid,
    this.backgroundImagePath,
    this.gradientColors,
  });

  /// Classic theme (light)
  factory CustomTheme.classic() {
    return const CustomTheme(
      name: 'Classic',
      description: 'Clean and traditional light theme',
      isDark: false,
      primaryColor: Color(0xFF1976D2),
      accentColor: Color(0xFFFFC107),
      backgroundColor: Color(0xFFFAFAFA),
      cardColor: Color(0xFFFFFFFF),
      appBarColor: Color(0xFF1976D2),
      textColor: Color(0xFF212121),
      textOnPrimary: Color(0xFFFFFFFF),
      textOnAccent: Color(0xFF000000),
      dividerColor: Color(0xFFE0E0E0),
      arabicTextColor: Color(0xFF000000),
    );
  }

  /// Forest theme (green)
  factory CustomTheme.forest() {
    return const CustomTheme(
      name: 'Forest',
      description: 'Calm green theme inspired by nature',
      isDark: false,
      primaryColor: Color(0xFF2E7D32),
      accentColor: Color(0xFF66BB6A),
      backgroundColor: Color(0xFFF1F8E9),
      cardColor: Color(0xFFFFFFFF),
      appBarColor: Color(0xFF2E7D32),
      textColor: Color(0xFF1B5E20),
      textOnPrimary: Color(0xFFFFFFFF),
      textOnAccent: Color(0xFFFFFFFF),
      dividerColor: Color(0xFFC5E1A5),
      arabicTextColor: Color(0xFF1B5E20),
      backgroundStyle: BackgroundStyle.gradient,
      gradientColors: [Color(0xFFF1F8E9), Color(0xFFDCEDC8)],
    );
  }

  /// Desert theme (warm)
  factory CustomTheme.desert() {
    return const CustomTheme(
      name: 'Desert',
      description: 'Warm sandy theme',
      isDark: false,
      primaryColor: Color(0xFFD84315),
      accentColor: Color(0xFFFFB74D),
      backgroundColor: Color(0xFFFFF3E0),
      cardColor: Color(0xFFFFFAF0),
      appBarColor: Color(0xFFD84315),
      textColor: Color(0xFFBF360C),
      textOnPrimary: Color(0xFFFFFFFF),
      textOnAccent: Color(0xFF000000),
      dividerColor: Color(0xFFFFCCBC),
      arabicTextColor: Color(0xFFBF360C),
      backgroundStyle: BackgroundStyle.gradient,
      gradientColors: [Color(0xFFFFF3E0), Color(0xFFFFE0B2)],
    );
  }

  /// Ocean theme (blue)
  factory CustomTheme.ocean() {
    return const CustomTheme(
      name: 'Ocean',
      description: 'Cool blue theme like the sea',
      isDark: false,
      primaryColor: Color(0xFF0277BD),
      accentColor: Color(0xFF00BCD4),
      backgroundColor: Color(0xFFE1F5FE),
      cardColor: Color(0xFFFFFFFF),
      appBarColor: Color(0xFF0277BD),
      textColor: Color(0xFF01579B),
      textOnPrimary: Color(0xFFFFFFFF),
      textOnAccent: Color(0xFFFFFFFF),
      dividerColor: Color(0xFFB3E5FC),
      arabicTextColor: Color(0xFF01579B),
      backgroundStyle: BackgroundStyle.gradient,
      gradientColors: [Color(0xFFE1F5FE), Color(0xFFB3E5FC)],
    );
  }

  /// Night theme (dark)
  factory CustomTheme.night() {
    return const CustomTheme(
      name: 'Night',
      description: 'Dark theme for low-light reading',
      isDark: true,
      primaryColor: Color(0xFF1E88E5),
      accentColor: Color(0xFF64B5F6),
      backgroundColor: Color(0xFF121212),
      cardColor: Color(0xFF1E1E1E),
      appBarColor: Color(0xFF1E1E1E),
      textColor: Color(0xFFE0E0E0),
      textOnPrimary: Color(0xFFFFFFFF),
      textOnAccent: Color(0xFF000000),
      dividerColor: Color(0xFF424242),
      arabicTextColor: Color(0xFFE0E0E0),
    );
  }

  /// Copy with modifications
  CustomTheme copyWith({
    String? name,
    String? description,
    bool? isDark,
    Color? primaryColor,
    Color? accentColor,
    Color? backgroundColor,
    Color? cardColor,
    Color? appBarColor,
    Color? textColor,
    Color? textOnPrimary,
    Color? textOnAccent,
    Color? dividerColor,
    Color? arabicTextColor,
    String? arabicFontFamily,
    double? arabicFontSize,
    String? bodyFontFamily,
    String? headingFontFamily,
    double? borderRadius,
    double? elevation,
    BackgroundStyle? backgroundStyle,
    String? backgroundImagePath,
    List<Color>? gradientColors,
  }) {
    return CustomTheme(
      name: name ?? this.name,
      description: description ?? this.description,
      isDark: isDark ?? this.isDark,
      primaryColor: primaryColor ?? this.primaryColor,
      accentColor: accentColor ?? this.accentColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      cardColor: cardColor ?? this.cardColor,
      appBarColor: appBarColor ?? this.appBarColor,
      textColor: textColor ?? this.textColor,
      textOnPrimary: textOnPrimary ?? this.textOnPrimary,
      textOnAccent: textOnAccent ?? this.textOnAccent,
      dividerColor: dividerColor ?? this.dividerColor,
      arabicTextColor: arabicTextColor ?? this.arabicTextColor,
      arabicFontFamily: arabicFontFamily ?? this.arabicFontFamily,
      arabicFontSize: arabicFontSize ?? this.arabicFontSize,
      bodyFontFamily: bodyFontFamily ?? this.bodyFontFamily,
      headingFontFamily: headingFontFamily ?? this.headingFontFamily,
      borderRadius: borderRadius ?? this.borderRadius,
      elevation: elevation ?? this.elevation,
      backgroundStyle: backgroundStyle ?? this.backgroundStyle,
      backgroundImagePath: backgroundImagePath ?? this.backgroundImagePath,
      gradientColors: gradientColors ?? this.gradientColors,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'isDark': isDark,
      'primaryColor': primaryColor.value,
      'accentColor': accentColor.value,
      'backgroundColor': backgroundColor.value,
      'cardColor': cardColor.value,
      'appBarColor': appBarColor.value,
      'textColor': textColor.value,
      'textOnPrimary': textOnPrimary.value,
      'textOnAccent': textOnAccent.value,
      'dividerColor': dividerColor.value,
      'arabicTextColor': arabicTextColor.value,
      'arabicFontFamily': arabicFontFamily,
      'arabicFontSize': arabicFontSize,
      'bodyFontFamily': bodyFontFamily,
      'headingFontFamily': headingFontFamily,
      'borderRadius': borderRadius,
      'elevation': elevation,
      'backgroundStyle': backgroundStyle.name,
      'backgroundImagePath': backgroundImagePath,
      'gradientColors': gradientColors?.map((c) => c.value).toList(),
    };
  }

  /// Create from JSON
  factory CustomTheme.fromJson(Map<String, dynamic> json) {
    return CustomTheme(
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      isDark: json['isDark'] as bool? ?? false,
      primaryColor: Color(json['primaryColor'] as int),
      accentColor: Color(json['accentColor'] as int),
      backgroundColor: Color(json['backgroundColor'] as int),
      cardColor: Color(json['cardColor'] as int),
      appBarColor: Color(json['appBarColor'] as int),
      textColor: Color(json['textColor'] as int),
      textOnPrimary: Color(json['textOnPrimary'] as int),
      textOnAccent: Color(json['textOnAccent'] as int),
      dividerColor: Color(json['dividerColor'] as int),
      arabicTextColor: Color(json['arabicTextColor'] as int? ?? 0xFF000000),
      arabicFontFamily: json['arabicFontFamily'] as String? ?? 'Amiri',
      arabicFontSize: (json['arabicFontSize'] as num?)?.toDouble() ?? 24.0,
      bodyFontFamily: json['bodyFontFamily'] as String? ?? 'Roboto',
      headingFontFamily: json['headingFontFamily'] as String? ?? 'Roboto',
      borderRadius: (json['borderRadius'] as num?)?.toDouble() ?? 12.0,
      elevation: (json['elevation'] as num?)?.toDouble() ?? 2.0,
      backgroundStyle: BackgroundStyle.values.firstWhere(
        (e) => e.name == json['backgroundStyle'],
        orElse: () => BackgroundStyle.solid,
      ),
      backgroundImagePath: json['backgroundImagePath'] as String?,
      gradientColors: (json['gradientColors'] as List<dynamic>?)
          ?.map((c) => Color(c as int))
          .toList(),
    );
  }
}

/// Background style options
enum BackgroundStyle {
  solid,
  gradient,
  image,
}

/// Global theme service instance
final themeService = ThemeService();
