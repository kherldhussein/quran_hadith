import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:quran_hadith/models/hadithModel.dart';
//
class HadithAPI {
  String url = "https://api.sunnah.com/v1/hadiths";
  static const headers = {
    'x-api-key': "SqD712P3E82xnwOAEOkGd5JZH8s9wRR24TqNFzjk",
  };

  Future<HadithList>getHadithList() async {
    final response = await http.get(url,headers: headers);
    if (response.statusCode == 200) {
      HadithList.fromJson(json.decode(response.body));
    }else{
      throw Exception("Failed  to Load Data");
    }
  }
}
