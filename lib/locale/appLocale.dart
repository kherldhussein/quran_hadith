import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quran_hadith/main.dart';

class AppLocale {
  final Locale locale;
  static Map<dynamic, dynamic>? _localisedValues;

  AppLocale(this.locale) {
    _localisedValues = {};
  }

  static AppLocale? of(BuildContext context) {
    return Localizations.of<AppLocale>(context, AppLocale);
  }

  static const LocalizationsDelegate<AppLocale> delegate = _AppLocaleDelegate();

  static Future<AppLocale> load(Locale locale) async {
    final appTranslations = AppLocale(locale);
    String jsonContent = await rootBundle
        .loadString('assets/locale/${locale.languageCode}.json');
    _localisedValues = json.decode(jsonContent);
    return appTranslations;
  }

  String text(String key) => _localisedValues![key] ?? '';
}

class _AppLocaleDelegate extends LocalizationsDelegate<AppLocale> {
  final Locale? newLocale;

  const _AppLocaleDelegate({this.newLocale});

  @override
  bool isSupported(Locale locale) =>
      QuranHadith.supportedLocales.contains(locale.languageCode);

  @override
  Future<AppLocale> load(Locale locale) => AppLocale.load(newLocale ?? locale);

  @override
  bool shouldReload(LocalizationsDelegate<AppLocale> old) => true;
}
