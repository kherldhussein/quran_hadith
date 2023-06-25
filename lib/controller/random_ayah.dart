import 'dart:math';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class RandomVerseManager {
  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

  RandomVerseManager() {
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    final initLinux =
        LinuxInitializationSettings(defaultActionName: 'Notification');
    final initSettings = InitializationSettings(linux: initLinux);
    await flutterLocalNotificationsPlugin.initialize(initSettings);
  }

  Future<String> getRandomVerse() async {
    String url = "http://api.alquran.cloud/v1/quran/quran-uthmani";
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final verses = data['data']['surahs'][1]['ayahs'];
      final random = Random();
      final randomVerse = verses[random.nextInt(verses.length)];
      print(">>>>>>>>>>>>>>>>>>>>>>>.${randomVerse['text']}");
      return randomVerse['text'];
    } else {
      throw Exception("Failed to retrieve data from the API.");
    }
  }

  Future<void> displayDesktopNotification(String verse) async {
    final channelSpecs = LinuxNotificationDetails(
      urgency: LinuxNotificationUrgency.critical,
      category: LinuxNotificationCategory.presence,
    );

    final platformChannelSpecifics = NotificationDetails(linux: channelSpecs);

    await flutterLocalNotificationsPlugin.show(
      0,
      'Ayah of the Day',
      verse,
      platformChannelSpecifics,
    );
  }
}
