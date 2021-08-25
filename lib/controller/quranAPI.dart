import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:quran_hadith/models/juzModel.dart';
import 'package:quran_hadith/models/surahModel.dart';

/// The Qur’ān contains 6236 verses
class QuranAPI  {
  Future<SurahsList> getSuratList() async {
    String url = "http://api.alquran.cloud/v1/quran/quran-uthmani";
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      return SurahsList.fromJSON(json.decode(response.body));
    } else {
      throw Exception("Failed to Get Data");
    }
  }

  Future<JuzModel> getJuzz({required int index}) async {
    String url = "http://api.alquran.cloud/v1/juz/$index/quran-uthmani";
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      return JuzModel.fromJSON(json.decode(response.body));
    } else {
      throw Exception("Failed to Get Data");
    }
  }

  Future<SurahsList> getSearch({required String keyWord}) async {
    String url = "http://api.alquran.cloud/v1/search/$keyWord/all/en";
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      return SurahsList.fromJSON(json.decode(response.body));
    } else {
      print("Failed to load");
      throw Exception("Failed to Get Data");
    }
  }

  Future<SurahsList> getSuratAudio({required String suratNo}) async {
    String url = "http://api.alquran.cloud/v1/surah/$suratNo/en.ahmedali";
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      return SurahsList.fromJSON(json.decode(response.body));
    } else {
      throw Exception("Failed to Get Data");
    }
  }

  Future<Ayah> getAyaAudio({required int ayaNo}) async {
    String url = "https://cdn.alquran.cloud/media/audio/ayah/Hani Rifai/$ayaNo";
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      return Ayah.fromJSON(json.decode(response.body));
    } else {
      throw Exception("Failed to Get Data");
    }
  }
}
