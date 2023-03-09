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

final circularIndicator = CircularProgressIndicator(
  valueColor: AlwaysStoppedAnimation<Color>(kDarkSecondaryColor),
);

double height =
    MediaQueryData.fromWindow(WidgetsBinding.instance.window).size.height;
double width =
    MediaQueryData.fromWindow(WidgetsBinding.instance.window).size.width;

ThemeData get darkTheme {
  final base = ThemeData.dark();
  return base.copyWith(
    brightness: Brightness.dark,
    canvasColor: kDarkPrimaryColor,
    primaryColor: kDarkPrimaryColor,
    primaryColorLight: kAccentColor,
    primaryColorDark: kTextDarker,
    cardColor: kBackgroundDark,
    dividerColor: kDividerLight,
    platform: TargetPlatform.linux,
    scaffoldBackgroundColor: kBackgroundDark,
    primaryIconTheme: base.iconTheme.copyWith(color: kIconDark),
    buttonTheme: base.buttonTheme.copyWith(buttonColor: kDarkSecondaryColor),
    cardTheme: base.cardTheme.copyWith(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    tabBarTheme: TabBarTheme(
      labelColor: kDividerLight,
      unselectedLabelColor: kTextDark,
      indicator: BubbleTabIndicator(
        indicatorHeight: 25.0,
        indicatorColor: kIconDark,
        tabBarIndicatorSize: TabBarIndicatorSize.tab,
      ),
    ),
    navigationRailTheme: NavigationRailThemeData(
        backgroundColor: kDividerDark,
        selectedIconTheme: IconThemeData(color: kAccentColor),
        unselectedIconTheme: IconThemeData(color: kLight),
        labelType: NavigationRailLabelType.all,
        selectedLabelTextStyle:
            base.textTheme.bodyMedium!.copyWith(color: kAccentColor)),
    textTheme: _buildTextTheme(base.textTheme, kTextLight, kTextLighter),
    primaryTextTheme:
        _buildTextTheme(base.primaryTextTheme, kTextLight, kTextLighter),
    snackBarTheme: base.snackBarTheme.copyWith(
      backgroundColor: kDarkPrimaryColor,
      contentTextStyle: base.textTheme.bodyLarge!.copyWith(
        fontWeight: FontWeight.w500,
        fontSize: 15,
        color: kTextLight,
      ),
    ),
    appBarTheme: base.appBarTheme.copyWith(
        color: kDividerDark,
        elevation: 0.0,
        systemOverlayStyle: SystemUiOverlayStyle.light),
    iconTheme: base.iconTheme.copyWith(color: kAccentColor),
    dialogTheme: base.dialogTheme.copyWith(
      contentTextStyle: TextStyle(color: kDarkColor),
      backgroundColor: kDarkPrimaryColor,
    ),
  );
}

ThemeData get theme {
  final base = ThemeData.light();
  return base.copyWith(
    brightness: Brightness.light,
    buttonTheme: base.buttonTheme.copyWith(buttonColor: kAccentColor),
    canvasColor: kLightPrimaryColor,
    cardColor: kDividerLight,
    primaryColorLight: kLightPrimaryColor,
    platform: TargetPlatform.linux,
    primaryColorDark: kTextDarker,
    scaffoldBackgroundColor: kBackgroundLight,
    primaryIconTheme: base.iconTheme.copyWith(color: kIconDark),
    tabBarTheme: TabBarTheme(
      labelColor: kDividerLight,
      unselectedLabelColor: kDarkColor,
      indicator: BubbleTabIndicator(
        indicatorHeight: 25.0,
        indicatorColor: kIconDark,
        tabBarIndicatorSize: TabBarIndicatorSize.tab,
      ),
    ),
    navigationRailTheme: NavigationRailThemeData(
        selectedIconTheme: IconThemeData(color: kAccentColor),
        labelType: NavigationRailLabelType.all,
        unselectedIconTheme: IconThemeData(color: kDarkColor),
        backgroundColor: kBackgroundLight,
        selectedLabelTextStyle:
            base.textTheme.bodyMedium!.copyWith(color: kAccentColor)),
    cardTheme: base.cardTheme.copyWith(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    dialogTheme: base.dialogTheme.copyWith(
      contentTextStyle: TextStyle(color: kDarkColor),
    ),
    appBarTheme: base.appBarTheme.copyWith(
        color: kBackgroundLight,
        elevation: 0.0,
        systemOverlayStyle: SystemUiOverlayStyle.dark),
    iconTheme: base.iconTheme.copyWith(color: kAccentColor),
    primaryTextTheme:
        _buildTextTheme(base.primaryTextTheme, kTextDark, kTextDarker),
    textTheme: _buildTextTheme(base.textTheme, kTextDark, kTextDark),
    snackBarTheme: base.snackBarTheme.copyWith(
      backgroundColor: kLight,
      contentTextStyle: base.textTheme.bodyLarge!.copyWith(
        fontWeight: FontWeight.w500,
        fontSize: 15,
        color: kTextDark,
      ),
    ),
    colorScheme: ColorScheme.fromSwatch().copyWith(secondary: kAccentColor),
  );
}

TextTheme _buildTextTheme(TextTheme base, Color displayColor, Color bodyColor) {
  return base
      .copyWith(
        headlineSmall: base.headlineSmall!.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
          fontSize: 20,
        ),
        titleLarge: base.titleLarge!.copyWith(
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
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
          fontFamily: 'Amiri',
          displayColor: displayColor,
          bodyColor: bodyColor);
}
