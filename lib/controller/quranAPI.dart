import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:quran_hadith/models/juzModel.dart';
import 'package:quran_hadith/models/surahModel.dart';

class QuranAPI {
  Future<SurahsList> getSuratList() async {
    String url = "http://api.alquran.cloud/v1/quran/quran-uthmani";
    final response = await http.get(url);
    if (response.statusCode == 200) {
      return SurahsList.fromJSON(json.decode(response.body));
    } else {
      throw Exception("Failed to Get Data");
    }
  }

  Future<JuzModel> getJuzz({int? index}) async {
    String url = "http://api.alquran.cloud/v1/juz/$index/quran-uthmani";
    final response = await http.get(url);
    if (response.statusCode == 200) {
      return JuzModel.fromJSON(json.decode(response.body));
    } else {
      throw Exception("Failed to Get Data");
    }
  }

  Future<SurahsList> getSearch({String? keyWord}) async {
    String url = "http://api.alquran.cloud/v1/search/$keyWord/all/en";
    final response = await http.get(url);
    if (response.statusCode == 200) {
      return SurahsList.fromJSON(json.decode(response.body));
    } else {
      print("Failed to load");
      throw Exception("Failed to Get Data");
    }
  }

  Future<SurahsList> getSuratAudio({String? suratNo}) async {
    String url = "http://api.alquran.cloud/v1/surah/$suratNo/en.ahmedali";
    final response = await http.get(url);
    if (response.statusCode == 200) {
      return SurahsList.fromJSON(json.decode(response.body));
    } else {
      throw Exception("Failed to Get Data");
    }
  }

  // TODO: find out > cdn.alquran.cloud/media/audio
  Future<Ayah> getAyaAudio({int? ayaNo}) async {
    String url = "https://cdn.alquran.cloud/media/audio/$ayaNo/ar.alafasy/1";
    final response = await http.get(url);
    if (response.statusCode == 200) {
      return Ayah.fromJSON(json.decode(response.body));
    } else {
      throw Exception("Failed to Get Data");
    }
  }
}
