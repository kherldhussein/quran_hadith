import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:quran_hadith/controller/favorite.dart';
import 'package:quran_hadith/controller/quranAPI.dart';
import 'package:quran_hadith/screens/splash_screen.dart';
import 'package:quran_hadith/theme/theme_state.dart';
import 'package:quran_hadith/utils/shared_p.dart';
import 'package:quran_hadith/utils/sp_util.dart';

import 'controller/hadithAPI.dart';
import 'theme/app_theme.dart';

final quranApi = QuranAPI();
final hadithApi = HadithAPI();
final themed = ThemeState();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        Provider(create: (context) => quranApi),
        Provider(create: (context) => hadithApi),
        ChangeNotifierProvider.value(value: OnFavorite()),
        ChangeNotifierProvider.value(value: themed),
      ],
      child: const QuranHadith(),
    ),
  );
  doWhenWindowReady(() {
    final win = appWindow;
    const initialSize = Size(1051.0, 646.0);
    win.minSize = initialSize;
    win.size = initialSize;
    win.alignment = Alignment.center;
    win.title = "Qur’ān Hadith";
    win.show();
  });
}

// http://api.alquran.cloud/v1/quran/ar.alafasy
// Audio url: https://cdn.alquran.cloud/media/audio/ayah/ar.alafasy/1
class QuranHadith extends StatefulWidget {
  const QuranHadith({super.key});

  static List<String> supportedLocales = ['en', 'ar'];

  @override
  _QuranHadithState createState() => _QuranHadithState();
}

class _QuranHadithState extends State<QuranHadith> {
  Locale localeCallback(locale, supportedLocales) {
    for (var supportedLocale in supportedLocales) {
      if (supportedLocale.languageCode == locale.languageCode &&
          supportedLocale.countryCode == locale.countryCode)
        return supportedLocale;
    }
    return supportedLocales.first;
  }

  @override
  void initState() {
    _initSp();
    super.initState();
  }

  Future _initSp() async {
    await appSP.init();
    bool? dark = SpUtil.getThemed();
    if (dark != null) {
      Provider.of<ThemeState>(context, listen: false).loadTheme(dark);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themes = Provider.of<ThemeState>(context);
    return GetMaterialApp(
      localizationsDelegates: [
        // AppLocale.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      localeResolutionCallback: localeCallback,
      supportedLocales:
          QuranHadith.supportedLocales.map((l) => Locale(l, '')).toList(),
      title: 'Qur’ān Hadith',
      darkTheme: darkTheme,
      themeMode: themes.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      theme: theme,
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
