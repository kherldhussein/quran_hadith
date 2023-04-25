import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:quran_hadith/models/juzModel.dart';
import 'package:quran_hadith/models/surahModel.dart';

import 'package:dio_http_cache/dio_http_cache.dart';

/// The Qur’ān contains 6236 verses
class QuranAPI {
  late Response response;
  Dio dio = Dio();

  Future<SurahsList> getSuratList() async {
    String url = "http://api.alquran.cloud/v1/quran/quran-uthmani";
    response = await dio.get(
      url,
      options:
          buildCacheOptions(Duration(days: 7), maxStale: Duration(days: 10)),
    );
    if (response.statusCode == 200) {
      return SurahsList.fromJSON(json.decode(response.data));
    } else {
      throw Exception("Failed to Get Data");
    }
  }

  Future<SurahsList> getSurahListAssets(int index) async {
    final response =
        await rootBundle.loadString('assets/surah/surah_$index.json');
    var res = json.decode(response);
    var data = res['$index'];
    return SurahsList.fromJSON(data);
  }

  Future<List<SurahsList>> getData() async {
    var response = await rootBundle.loadString('assets/surah/');
    Iterable data = json.decode(response);
    return data.map((model) => SurahsList.fromJSON(model)).toList();
  }

  Future<JuzModel> getJuzz({required int index}) async {
    String url = "http://api.alquran.cloud/v1/juz/$index/quran-uthmani";
    response = await dio.get(url);
    if (response.statusCode == 200) {
      return JuzModel.fromJSON(json.decode(response.data));
    } else {
      throw Exception("Failed to Get Data");
    }
  }

  Future<SurahsList> getSearch({required String keyWord}) async {
    String url = "http://api.alquran.cloud/v1/search/$keyWord/all/en";
    response = await dio.get(url);
    if (response.statusCode == 200) {
      return SurahsList.fromJSON(json.decode(response.data));
    } else {
      print("Failed to load");
      throw Exception("Failed to Get Data");
    }
  }

  Future<SurahsList> getSuratAudio({required String suratNo}) async {
    String url = "http://api.alquran.cloud/v1/surah/$suratNo/en.ahmedali";
    response = await dio.get(url);
    if (response.statusCode == 200) {
      return SurahsList.fromJSON(json.decode(response.data));
    } else {
      throw Exception("Failed to Get Data");
    }
  }

  Future<Ayah> getAyaAudio({required int ayaNo}) async {
    String url = "https://cdn.alquran.cloud/media/audio/ayah/Hani Rifai/$ayaNo";
    response = await dio.get(url);
    if (response.statusCode == 200) {
      return Ayah.fromJSON(json.decode(response.data));
    } else {
      throw Exception("Failed to Get Data");
    }
  }
}
