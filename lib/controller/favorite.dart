import 'package:flutter/material.dart';
import 'package:quran_hadith/models/surahModel.dart';
import 'package:quran_hadith/utils/sp_util.dart';

class OnFavorite extends ChangeNotifier {
  bool isFavorite = false;

  Future<List<SurahList?>?> addFavorite(SurahList? surah) async {
    try {
      List<String>? favorites = await SpUtil.getFavorites();
      if (favorites == null) {
        favorites = <Surah?>[].cast<String>();
        await SpUtil.setFavorites(favorites);
      }
      final List<SurahList?>? currentFavorites = List.from(favorites);
      currentFavorites!.add(surah!);
      await SpUtil.setFavorites(currentFavorites.cast<String>())
          .then((value) => isFavorite == value);
      return currentFavorites;
    } catch (e) {
      throw Exception("Failed to Get Data");
    }
  }

  Future<List<SurahList?>?> removeFavorite(SurahList? surah) async {
    try {
      List<String>? favorites = await SpUtil.getFavorites();
      final List<SurahList?>? currentFavorites = List.from(favorites as Iterable);
      currentFavorites!.remove(surah!);
      await SpUtil.setFavorites(currentFavorites.cast<String>())
          .then((value) => isFavorite == value);
      return currentFavorites;
    } catch (e) {
      throw Exception("Failed to Get Data");
    }
  }

  Future<List<SurahList?>?> getFavorites() async {
    try {
      List<String>? favorites = await SpUtil.getFavorites();
      if (favorites == null) {
        favorites = SurahList as List<String>?;
        await SpUtil.setFavorites(favorites!);
      }
      final List<SurahList?>? currentFavorites = List.from(favorites);
      return currentFavorites;
    } catch (e) {
      throw Exception("Failed to Get Data");
    }
  }

  void addIsFavorite(bool favorite) {
    isFavorite = favorite;
    SpUtil.setFavorite(favorite);
    notifyListeners();
  }
}
