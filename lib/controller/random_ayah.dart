import 'dart:math';
import 'dart:convert';
import 'package:http/http.dart' as http;

class RandomVerseManager {

  RandomVerseManager() {
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {}

  Future getRandomVerse() async {
    const String url = "http://api.alquran.cloud/v1/quran/quran-uthmani";
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final val = Random().nextInt(114);
        final verses = data['data']['surahs'][val]['ayahs'];
        final random = Random().nextInt(verses.length);
        final randomVerse = verses[random];
        return randomVerse['text'];
      } else {
        throw Exception("Failed to retrieve data from the API.");
      }
    } catch (e) {
      throw Exception("Failed to retrieve data from the API: $e");
    }
  }

  Future<void> displayDesktopNotification(String verse) async {}

}
