import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _plugin.initialize(const InitializationSettings(android: android));
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  static Future<void> show(int id, String title, String body) async {
    const details = AndroidNotificationDetails(
      'studentology_channel',
      'Studentology',
      channelDescription: 'Studentology notifications',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
    );
    await _plugin.show(
        id, title, body, const NotificationDetails(android: details));
  }

  static Future<void> schedule(
      int id, String title, String body, DateTime when) async {
    if (when.isBefore(DateTime.now())) return;
    final diff = when.difference(DateTime.now());
    Future.delayed(diff, () => show(id, title, body));
  }

  static Future<void> cancel(int id) async => await _plugin.cancel(id);
}
