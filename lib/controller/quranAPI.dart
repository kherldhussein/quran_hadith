import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:quran_hadith/models/juzModel.dart';
import 'package:quran_hadith/models/surahModel.dart';

import 'package:http/http.dart' as http;

/// The Qur’ān contains 6236 verses
class QuranAPI {
  late Response response;
  Dio dio = Dio();

  Future<SurahList> getSuratList() async {
    String url = "http://api.alquran.cloud/v1/quran/quran-uthmani";
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      return SurahList.fromJSON(json.decode(response.body));
    } else {
      throw Exception("Failed to Get Data");
    }
  }

  Future<SurahList> getSurahListAssets(int index) async {
    final response =
        await rootBundle.loadString('assets/surah/surah_$index.json');
    var res = json.decode(response);
    var data = res['$index'];
    return SurahList.fromJSON(data);
  }

  Future<List<SurahList>> getData() async {
    var response = await rootBundle.loadString('assets/surah/');
    Iterable data = json.decode(response);
    return data.map((model) => SurahList.fromJSON(model)).toList();
  }

  Future<JuzModel> getJuzz({required int index}) async {
    String url = "http://api.alquran.cloud/v1/juz/$index/quran-uthmani";
    final response = await dio.get(url);
    if (response.statusCode == 200) {
      return JuzModel.fromJSON(json.decode(response.data));
    } else {
      throw Exception("Failed to Get Data");
    }
  }

  Future<SurahList> getSearch({required String keyWord}) async {
    String url = "http://api.alquran.cloud/v1/search/$keyWord/all/en";
    final response = await dio.get(url);
    if (response.statusCode == 200) {
      return SurahList.fromJSON(json.decode(response.data));
    } else {
      print("Failed to load");
      throw Exception("Failed to Get Data");
    }
  }

  Future<SurahList> getSuratAudio({required String suratNo}) async {
    String url = "http://api.alquran.cloud/v1/surah/$suratNo/en.ahmedali";
    final response = await dio.get(url);
    if (response.statusCode == 200) {
      return SurahList.fromJSON(json.decode(response.data));
    } else {
      throw Exception("Failed to Get Data");
    }
  }

  Future<Ayah> getAyaAudio({required int ayaNo}) async {
    String url = "https://cdn.alquran.cloud/media/audio/ayah/Hani Rifai/$ayaNo";
    final response = await dio.get(url);
    if (response.statusCode == 200) {
      return Ayah.fromJSON(json.decode(response.data));
    } else {
      throw Exception("Failed to Get Data");
    }
  }
}
