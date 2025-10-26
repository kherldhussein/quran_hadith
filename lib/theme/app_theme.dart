import 'package:bubble_tab_indicator/bubble_tab_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Application theme
// 013f2f
// #209f6f
// #021a13
// #06291d
const kLightSecondaryColor = Color(0xffdae1e7);
const kDarkSecondaryColor = Color(0xff013f2f);
const kLightPrimaryColor = Color(0xffdae1e7);
const kDarkPrimaryColor = Color(0xFF1B1B1B);
const kBackgroundLight = Color(0xffffffff);
const kBackgroundDark = Color(0xFF2A2A2A);
const kDividerLight = Color(0xFFFFFFFF);
const kDividerDark = Color(0xFF3D3D3D);
const kAccentColor = Color(0xff209f6f);
const kTextLighter = Color(0xFFFBFBFB);
const kTextDarker = Color(0xFF17262A);
const kTextDark = Color(0xFF3D3D3D);
const kTextLight = Color(0xFFEEEEEE);
const kDarkColor = Color(0xFF000000);
const kIconDark = Color(0xFF666666);
const kOrange = Color(0xff021a13);
const kLight = Color(0xFFFDFDFD);
const kDark = Color(0xff021a13);
const kLinkC = Color(0xFF249ffd);

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
    dividerColor: kDividerLight.withOpacity(.5),
    iconTheme: base.iconTheme.copyWith(color: kAccentColor),
    primaryIconTheme: base.iconTheme.copyWith(color: kIconDark),
    dividerTheme:
        base.dividerTheme.copyWith(color: kLightPrimaryColor.withOpacity(.5)),
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
      elevation: 0,
      color: kDividerDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
      primary: kAccentColor,
      onPrimary: kTextLight,
      secondary: kLinkC,
      onSecondary: kTextLight,
      tertiary: kLightSecondaryColor,
      onTertiary: kTextLight,
      surface: kDividerDark,
      onSurface: kTextLight,
      surfaceContainerHighest: kDarkPrimaryColor,
      onSurfaceVariant: kTextLight,
      error: Colors.red,
      onError: kTextLight,
      outline: kIconDark,
      outlineVariant: kDividerDark,
      inversePrimary: kAccentColor,
      inverseSurface: kLight,
      scrim: kDarkColor,
      shadow: kDarkColor,
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
    dividerColor: kLightPrimaryColor.withOpacity(.5),
    iconTheme: base.iconTheme.copyWith(color: kAccentColor),
    primaryIconTheme: base.iconTheme.copyWith(color: kIconDark),
    buttonTheme: base.buttonTheme.copyWith(buttonColor: kAccentColor),
    dividerTheme: base.dividerTheme.copyWith(color: kIconDark.withOpacity(.5)),
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
      color: kLight,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
    colorScheme: ColorScheme(
      brightness: Brightness.light,
      primary: kAccentColor,
      onPrimary: kTextLighter,
      secondary: kLinkC,
      onSecondary: kTextLighter,
      tertiary: kDarkSecondaryColor,
      onTertiary: kTextLighter,
      surface: kLight,
      onSurface: kTextDark,
      surfaceVariant: kLightPrimaryColor,
      onSurfaceVariant: kTextDark,
      background: kBackgroundLight,
      onBackground: kTextDarker,
      error: Colors.red,
      onError: kTextLighter,
      outline: kIconDark,
      outlineVariant: kDividerLight,
      inversePrimary: kAccentColor,
      inverseSurface: kDarkPrimaryColor,
      scrim: kDarkColor,
      shadow: kDarkColor,
    ),
  );
}

TextTheme _buildTextTheme(TextTheme base, Color displayColor, Color bodyColor) {
  return base
      .copyWith(
        headlineSmall: base.headlineSmall!.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: .5,
          fontSize: 20,
        ),
        titleLarge: base.titleLarge!.copyWith(
          fontWeight: FontWeight.w500,
          letterSpacing: .5,
          fontSize: 20,
        ),
        bodyLarge: base.bodyLarge!.copyWith(
          fontWeight: FontWeight.w500,
          fontSize: 16.0,
        ),
        titleMedium: base.titleMedium!.copyWith(
          fontWeight: FontWeight.w500,
          fontSize: 16.0,
        ),
      )
      .apply(
        fontFamily: 'Poppins',
        displayColor: displayColor,
        bodyColor: bodyColor,
      );
}
