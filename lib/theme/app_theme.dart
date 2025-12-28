import 'package:bubble_tab_indicator/bubble_tab_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Application theme - Material 3 Design System
/// Color Palette - Clean & Spiritual Aesthetic

// Primary Colors - Emerald Green Accent
const kEmeraldGreen = Color(0xff00B37A);
const kEmeraldGreenLight = Color(0xff33C594);
const kEmeraldGreenDark = Color(0xff009361);

// Background Colors - Clean White & Comfortable Dark
const kBackgroundLight = Color(0xffffffff);
const kBackgroundDark = Color(0xFF121212); // Soft dark, not pure black (eye comfort)
const kSurfaceLight = Color(0xFFFDFDFD);
const kSurfaceDark = Color(0xFF1E1E1E); // Subtle elevation from background

// Container Colors - Material 3 Surfaces
const kContainerLight = Color(0xFFF5F5F5);
const kContainerDark = Color(0xFF2A2A2A); // Moderate elevation
const kContainerHighlight = Color(0xFFE8F5F1); // Light emerald tint
const kContainerHighlightDark = Color(0xFF1A3830); // Desaturated emerald for dark mode

// Text Colors - Clear Hierarchy
const kTextPrimary = Color(0xFF1A1A1A);
const kTextSecondary = Color(0xFF666666);
const kTextTertiary = Color(0xFF999999);
const kTextLight = Color(0xFFE6E6E6); // High contrast on dark (meets 4.5:1 ratio)
const kTextLighter = Color(0xFFFBFBFB);
const kTextSecondaryDark = Color(0xFFB0B0B0); // Desaturated for secondary text in dark mode

// Divider & Border Colors
const kDividerLight = Color(0xFFE0E0E0);
const kDividerDark = Color(0xFF3A3A3A); // Subtle, not too bright
const kBorderLight = Color(0xFFE8E8E8);
const kBorderDark = Color(0xFF404040); // Softer borders for dark mode

// Legacy Color Mappings (for compatibility)
const kLightSecondaryColor = kContainerLight;
const kDarkSecondaryColor = Color(0xff013f2f);
const kLightPrimaryColor = kContainerLight;
const kDarkPrimaryColor = Color(0xFF1B1B1B);
const kAccentColor = kEmeraldGreen;
const kTextDarker = kTextPrimary;
const kTextDark = kTextSecondary;
const kDarkColor = Color(0xFF000000);
const kIconDark = kTextSecondary;
const kOrange = Color(0xff021a13);
const kLight = kSurfaceLight;
const kDark = Color(0xff021a13);
const kLinkC = kEmeraldGreen;

const circularIndicator = CircularProgressIndicator(
  valueColor: AlwaysStoppedAnimation<Color>(kDarkSecondaryColor),
);

ThemeData get darkTheme {
  final base = ThemeData.dark(useMaterial3: true);
  return base.copyWith(
    cardColor: kDividerDark,
    brightness: Brightness.dark,
    primaryColorDark: kTextDarker,
    platform: TargetPlatform.linux,
    canvasColor: kDarkPrimaryColor,
    primaryColorLight: kAccentColor,
    primaryColor: kDarkPrimaryColor,
    scaffoldBackgroundColor: kBackgroundDark,
    dividerColor: kDividerLight.withValues(alpha: 0.5),
    iconTheme: base.iconTheme.copyWith(color: kAccentColor),
    primaryIconTheme: base.iconTheme.copyWith(color: kIconDark),
    dividerTheme:
        base.dividerTheme.copyWith(color: kLightPrimaryColor.withValues(alpha: 0.5)),
    buttonTheme: base.buttonTheme.copyWith(buttonColor: kDarkSecondaryColor),
    textTheme: _buildTextTheme(base.textTheme, kTextLight, kTextLighter),
    primaryTextTheme:
        _buildTextTheme(base.primaryTextTheme, kTextLight, kTextLighter),
    tooltipTheme: base.tooltipTheme.copyWith(
      textStyle: const TextStyle(color: kLightPrimaryColor),
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(14)),
        color: kIconDark,
      ),
    ),
    cardTheme: base.cardTheme.copyWith(
      clipBehavior: Clip.antiAlias,
      elevation: 1, // Subtle elevation in dark mode
      shadowColor: Colors.black.withValues(alpha: 0.4), // 40% opacity for dark mode shadows
      surfaceTintColor: Color(0xFF00B37A).withValues(alpha: 0.05), // Subtle tint for elevation
      color: kSurfaceDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    tabBarTheme: base.tabBarTheme.copyWith(
      indicator: const BubbleTabIndicator(
        tabBarIndicatorSize: TabBarIndicatorSize.tab,
        indicatorColor: kIconDark,
        indicatorHeight: 25.0,
      ),
      unselectedLabelColor: kTextDark,
      labelColor: kDividerLight,
    ),
    navigationRailTheme: base.navigationRailTheme.copyWith(
      selectedIconTheme: base.iconTheme.copyWith(color: kDarkSecondaryColor),
      unselectedIconTheme: base.iconTheme.copyWith(color: kLight),
      labelType: NavigationRailLabelType.all,
      indicatorColor: Colors.transparent,
      backgroundColor: kDividerDark,
      selectedLabelTextStyle:
          base.textTheme.bodyMedium!.copyWith(color: kAccentColor),
    ),
    snackBarTheme: base.snackBarTheme.copyWith(
      contentTextStyle: base.textTheme.bodyLarge!.copyWith(
        fontWeight: FontWeight.w500,
        color: kTextLight,
        fontSize: 15,
      ),
      backgroundColor: kDarkPrimaryColor,
    ),
    appBarTheme: base.appBarTheme.copyWith(
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      backgroundColor: kDividerDark,
      elevation: .0,
    ),
    dialogTheme: base.dialogTheme.copyWith(
      contentTextStyle: const TextStyle(color: kDarkColor),
      backgroundColor: kDarkPrimaryColor,
    ),
    colorScheme: const ColorScheme(
      brightness: Brightness.dark,
      // Primary - Slightly desaturated emerald for dark mode
      primary: Color(0xFF00E09D), // Brighter, more visible in dark mode
      onPrimary: Color(0xFF002116), // Dark green for contrast
      primaryContainer: Color(0xFF003828), // Desaturated container
      onPrimaryContainer: Color(0xFF7FFBD2), // Light mint for readability
      // Secondary - Muted teal-gray
      secondary: Color(0xFFA1C9C1), // Desaturated for subtlety
      onSecondary: Color(0xFF14211E),
      secondaryContainer: kContainerDark,
      onSecondaryContainer: kTextLight,
      // Tertiary - Accent variation
      tertiary: Color(0xFF66D9B3), // Softer emerald variant
      onTertiary: Color(0xFF00332A),
      // Surfaces - Proper elevation hierarchy
      surface: kSurfaceDark, // Base surface (#1E1E1E)
      onSurface: kTextLight, // High contrast (#E6E6E6)
      surfaceContainerHighest: kContainerDark, // Highest elevation (#2A2A2A)
      surfaceContainerHigh: Color(0xFF252525), // High elevation
      surfaceContainer: Color(0xFF222222), // Medium elevation
      surfaceContainerLow: Color(0xFF1B1B1B), // Low elevation
      surfaceContainerLowest: kBackgroundDark, // Background (#121212)
      onSurfaceVariant: kTextSecondaryDark, // Secondary text (#B0B0B0)
      // Error colors
      error: Color(0xFFFF6B6B), // Softer red for dark mode
      onError: Color(0xFF1A0000),
      // Outlines
      outline: kDividerDark, // Subtle dividers (#3A3A3A)
      outlineVariant: kBorderDark, // Borders (#404040)
      // Inverse colors
      inversePrimary: kEmeraldGreenDark,
      inverseSurface: kSurfaceLight,
      // Overlays
      scrim: Color(0xE6000000), // 90% opacity for dialogs
      shadow: Color(0x66000000), // 40% opacity for subtle shadows
    ),
  );
}

ThemeData get theme {
  final base = ThemeData.light(useMaterial3: true);
  return base.copyWith(
    cardColor: kLight,
    brightness: Brightness.light,
    primaryColorDark: kTextDarker,
    platform: TargetPlatform.linux,
    canvasColor: kLightPrimaryColor,
    primaryColorLight: kLightPrimaryColor,
    scaffoldBackgroundColor: kBackgroundLight,
    dividerColor: kLightPrimaryColor.withValues(alpha: 0.5),
    iconTheme: base.iconTheme.copyWith(color: kAccentColor),
    primaryIconTheme: base.iconTheme.copyWith(color: kIconDark),
    buttonTheme: base.buttonTheme.copyWith(buttonColor: kAccentColor),
    dividerTheme: base.dividerTheme.copyWith(color: kIconDark.withValues(alpha: 0.5)),
    primaryTextTheme:
        _buildTextTheme(base.primaryTextTheme, kTextDark, kTextDarker),
    textTheme: _buildTextTheme(base.textTheme, kTextDark, kTextDark),
    tooltipTheme: base.tooltipTheme.copyWith(
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(14)),
        color: kIconDark,
      ),
      textStyle: const TextStyle(color: kDark),
    ),
    tabBarTheme: base.tabBarTheme.copyWith(
      indicator: const BubbleTabIndicator(
        indicatorHeight: 25.0,
        indicatorColor: kIconDark,
        tabBarIndicatorSize: TabBarIndicatorSize.tab,
      ),
      unselectedLabelColor: kDarkColor,
      labelColor: kDividerLight,
    ),
    navigationRailTheme: base.navigationRailTheme.copyWith(
      selectedIconTheme: base.iconTheme.copyWith(color: kAccentColor),
      unselectedIconTheme: base.iconTheme.copyWith(color: kDarkColor),
      labelType: NavigationRailLabelType.all,
      indicatorColor: Colors.transparent,
      backgroundColor: kBackgroundLight,
      selectedLabelTextStyle:
          base.textTheme.bodyMedium!.copyWith(color: kAccentColor),
    ),
    cardTheme: base.cardTheme.copyWith(
      clipBehavior: Clip.antiAlias,
      color: Colors.white,
      elevation: 2, // Slightly higher elevation for light mode
      shadowColor: Colors.black.withValues(alpha: 0.08), // 8% opacity for light mode
      surfaceTintColor: Color(0xFF00B37A).withValues(alpha: 0.02), // Very subtle tint
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    dialogTheme: base.dialogTheme.copyWith(
      contentTextStyle: const TextStyle(color: kDarkColor),
    ),
    appBarTheme: base.appBarTheme.copyWith(
      systemOverlayStyle: SystemUiOverlayStyle.light,
      backgroundColor: kBackgroundLight,
      elevation: .0,
    ),
    snackBarTheme: base.snackBarTheme.copyWith(
      contentTextStyle: base.textTheme.bodyLarge!.copyWith(
        fontWeight: FontWeight.w500,
        color: kTextDark,
        fontSize: 15,
      ),
      backgroundColor: kLight,
    ),
    colorScheme: const ColorScheme(
      brightness: Brightness.light,
      primary: kEmeraldGreen,
      onPrimary: Colors.white,
      primaryContainer: kContainerHighlight,
      onPrimaryContainer: kTextPrimary,
      secondary: kEmeraldGreenLight,
      onSecondary: Colors.white,
      secondaryContainer: kContainerLight,
      onSecondaryContainer: kTextPrimary,
      tertiary: kEmeraldGreenDark,
      onTertiary: Colors.white,
      surface: Colors.white,
      onSurface: kTextPrimary,
      surfaceContainerHighest: kContainerLight,
      surfaceContainerHigh: kSurfaceLight,
      surfaceContainer: Colors.white,
      onSurfaceVariant: kTextSecondary,
      error: Colors.red,
      onError: Colors.white,
      outline: kDividerLight,
      outlineVariant: kBorderLight,
      inversePrimary: kEmeraldGreenDark,
      inverseSurface: kTextPrimary,
      scrim: Colors.black38,
      shadow: Colors.black12,
    ),
  );
}

TextTheme _buildTextTheme(TextTheme base, Color displayColor, Color bodyColor) {
  return base
      .copyWith(
        // Display styles - Large headings
        displayLarge: base.displayLarge!.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: -0.5,
          fontSize: 32,
        ),
        displayMedium: base.displayMedium!.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
          fontSize: 28,
        ),
        displaySmall: base.displaySmall!.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
          fontSize: 24,
        ),

        // Headline styles - Section headers
        headlineLarge: base.headlineLarge!.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
          fontSize: 22,
        ),
        headlineMedium: base.headlineMedium!.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
          fontSize: 20,
        ),
        headlineSmall: base.headlineSmall!.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
          fontSize: 18,
        ),

        // Title styles - Card titles, list items
        titleLarge: base.titleLarge!.copyWith(
          fontWeight: FontWeight.w500,
          letterSpacing: 0,
          fontSize: 18,
        ),
        titleMedium: base.titleMedium!.copyWith(
          fontWeight: FontWeight.w500,
          letterSpacing: 0.15,
          fontSize: 16,
        ),
        titleSmall: base.titleSmall!.copyWith(
          fontWeight: FontWeight.w500,
          letterSpacing: 0.1,
          fontSize: 14,
        ),

        // Body styles - Main content
        bodyLarge: base.bodyLarge!.copyWith(
          fontWeight: FontWeight.w400,
          letterSpacing: 0.5,
          fontSize: 16,
        ),
        bodyMedium: base.bodyMedium!.copyWith(
          fontWeight: FontWeight.w400,
          letterSpacing: 0.25,
          fontSize: 14,
        ),
        bodySmall: base.bodySmall!.copyWith(
          fontWeight: FontWeight.w400,
          letterSpacing: 0.4,
          fontSize: 12,
        ),

        // Label styles - Buttons, chips
        labelLarge: base.labelLarge!.copyWith(
          fontWeight: FontWeight.w500,
          letterSpacing: 0.1,
          fontSize: 14,
        ),
        labelMedium: base.labelMedium!.copyWith(
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
          fontSize: 12,
        ),
        labelSmall: base.labelSmall!.copyWith(
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
          fontSize: 11,
        ),
      )
      .apply(
        fontFamily: 'Poppins',
        displayColor: displayColor,
        bodyColor: bodyColor,
      );
}
