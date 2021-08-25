import 'package:flutter/material.dart';
import 'package:quran_hadith/models/surahModel.dart';
import 'package:quran_hadith/utils/sp_util.dart';

class OnFavorite extends ChangeNotifier {

  static bool isFavorite = false;

  void addFavorite(bool isfavorite) {
    isFavorite = isfavorite;
    SpUtil.setFavorite(isfavorite);
    notifyListeners();
  }
  // Future<SurahsList> getFavorite(){
  //   if(isFavorite){
  //     return null;
  //   }
  //   return;
  // }
}
