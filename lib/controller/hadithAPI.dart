import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:quran_hadith/models/hadithModel.dart';

class HadithAPI {
  String url =
      "https://hadithapi.com/api/books?apiKey=\$2y\$10\$NL5GJQPyjth6YgMURtIruNq2QCpmXPk97PgxkZCVNKhUweep2";

  Future<List<HadithBooks>> getHadithList() async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      final hadiths = data
          .map(
            (json) => HadithBooks(
              bookId: json['id'],
              writerName: json['writerName'],
              hadithCount: json['hadithCount'],
              bookName: json['bookName'],
            ),
          )
          .toList();
      return hadiths;
    } else {
      return throw Exception("Failed  to Load Data");
    }
  }
}
