import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _local = FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );
    await _local.initialize(settings);
    await FirebaseMessaging.instance.requestPermission(alert: true, badge: true, sound: true);
    FirebaseMessaging.onMessage.listen(_showIncomingCallNotification);
  }

  static Future<void> _showIncomingCallNotification(RemoteMessage message) async {
    final callId = message.data['callId'];
    if (callId == null) return;
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'incoming_calls',
        'Incoming calls',
        channelDescription: 'Notifications for incoming Svinobook calls',
        importance: Importance.max,
        priority: Priority.high,
        category: AndroidNotificationCategory.call,
      ),
      iOS: DarwinNotificationDetails(),
    );
    await _local.show(
      callId.hashCode,
      message.data['callerName'] ?? 'Incoming call',
      message.data['type'] == 'audio' ? 'Audio call' : 'Video call',
      details,
      payload: callId.toString(),
    );
  }
}
