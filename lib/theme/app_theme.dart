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
    useMaterial3: true,
    cardColor: kDividerDark,
    brightness: Brightness.dark,
    primaryColorDark: kTextDarker,
    platform: TargetPlatform.linux,
    canvasColor: kDarkPrimaryColor,
    primaryColorLight: kAccentColor,
    primaryColor: kDarkPrimaryColor,
    scaffoldBackgroundColor: kBackgroundDark,
    dialogBackgroundColor: Colors.transparent,
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
      textStyle: TextStyle(color: kLightPrimaryColor),
      decoration: BoxDecoration(
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
      indicator: BubbleTabIndicator(
        tabBarIndicatorSize: TabBarIndicatorSize.tab,
        indicatorColor: kIconDark,
        indicatorHeight: 25.0,
      ),
      unselectedLabelColor: kTextDark,
      labelColor: kDividerLight,
    ),
    navigationRailTheme: base.navigationRailTheme.copyWith(
      selectedIconTheme: base.iconTheme.copyWith(color: kAccentColor),
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
      color: kDividerDark,
      elevation: .0,
    ),
    dialogTheme: base.dialogTheme.copyWith(
      contentTextStyle: TextStyle(color: kDarkColor),
      backgroundColor: kDarkPrimaryColor,
    ),
    colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.green)
        .copyWith(secondary: kAccentColor),
  );
}

ThemeData get theme {
  final base = ThemeData.light();
  return base.copyWith(
    cardColor: kLight,
    useMaterial3: true,
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
      decoration: BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(14)),
        color: kIconDark,
      ),
      textStyle: TextStyle(color: kDark),
    ),
    tabBarTheme: base.tabBarTheme.copyWith(
      indicator: BubbleTabIndicator(
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
      contentTextStyle: TextStyle(color: kDarkColor),
    ),
    appBarTheme: base.appBarTheme.copyWith(
      systemOverlayStyle: SystemUiOverlayStyle.light,
      color: kBackgroundLight,
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
    colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.green)
        .copyWith(secondary: kAccentColor),
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
