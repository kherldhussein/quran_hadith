import 'dart:math';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class RandomVerseManager {
  late FlutterLocalNotificationsPlugin notifier;

  RandomVerseManager() {
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    notifier = FlutterLocalNotificationsPlugin();
    final initLinux = LinuxInitializationSettings(
      defaultActionName: 'Notification',
      // onActionCallback: _onNotificationAction,
      defaultIcon: AssetsLinuxIcon('assets/images/Logo.png'),
    );
    final initSettings = InitializationSettings(linux: initLinux);
    await notifier.initialize(initSettings);
  }

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
        // todo: Modify to return whole Ayah details
        return randomVerse['text'];
      } else {
        throw Exception("Failed to retrieve data from the API.");
      }
    } catch (e) {
      throw Exception("Failed to retrieve data from the API: $e");
    }
  }

  Future<void> displayDesktopNotification(String verse) async {
    final channelSpecs = LinuxNotificationDetails(
      category: LinuxNotificationCategory.presence,
      urgency: LinuxNotificationUrgency.critical,
      actions: [
        LinuxNotificationAction(key: 'Notification', label: 'Notification')
      ],
    );

    final platformChannelSpecifics = NotificationDetails(linux: channelSpecs);

    await notifier.show(
      0,
      'Ayah of the Day',
      verse,
      platformChannelSpecifics,
    );
  }

// Future<void> _onNotificationAction(String? actionKey, String? payload) async {
//   if (actionKey == 'action_key') {
//     if (payload == 'action_payload') {
//       // Perform action specific to the payload
//       print('Performing action for payload: $payload');
//
//       // Example: Open a specific screen or perform a task
//       if (payload == 'open_screen_a') {
//         // Open Screen A
//       } else if (payload == 'open_screen_b') {
//         // Open Screen B
//       } else {
//         // Unknown payload value
//         print('Unknown payload: $payload');
//       }
//     } else {
//       // Handle other payload values
//       print('Unknown payload: $payload');
//     }
//   } else if (actionKey == 'other_action_key') {
//     // Handle other actions
//     print('Performing action for other action key: $actionKey');
//     // Perform the desired action for this action key
//   } else {
//     // Unknown action key
//     print('Unknown action key: $actionKey');
//   }
// }
}
