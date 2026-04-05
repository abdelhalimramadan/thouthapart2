import 'dart:developer';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  log('Handling a background message: ${message.messageId}');

  // Ensure Firebase is initialized before using its services in the background.
  await Firebase.initializeApp();

  // If the message contains a notification payload, Android/iOS will automatically
  // show it in the system tray. We don't want to show a duplicate local notification.
  if (message.notification != null) {
    log('Message has a notification payload. OS will handle it.');
    return;
  }

  // If it's a data-only payload, we construct and show a local notification manually.
  final title = message.data['title'] ?? 'إشعار جديد';
  final body = message.data['body'] ?? 'لديك إشعار جديد';

  // We must re-initialize local notifications because this runs in an isolated background thread.
  final FlutterLocalNotificationsPlugin localNotifications =
      FlutterLocalNotificationsPlugin();

  const AndroidInitializationSettings androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const DarwinInitializationSettings iosSettings =
      DarwinInitializationSettings();

  const InitializationSettings initSettings = InitializationSettings(
    android: androidSettings,
    iOS: iosSettings,
  );

  await localNotifications.initialize(settings: initSettings);

  const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    'high_importance_channel',
    'High Importance Notifications',
    importance: Importance.max,
    priority: Priority.high,
    showWhen: true,
    enableVibration: true,
    playSound: true,
  );

  const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
    presentSound: true,
    presentAlert: true,
    presentBadge: true,
  );

  const NotificationDetails platformDetails = NotificationDetails(
    android: androidDetails,
    iOS: iosDetails,
  );

  // Encode the data payload so it can be handled when tapped (requires handling in UI)
  String encodedPayload = _encodePayload(message.data);

  await localNotifications.show(
    id: message.hashCode.abs(),
    title: title,
    body: body,
    notificationDetails: platformDetails,
    payload: encodedPayload,
  );
}

/// Helper method to safely encode the map data to a uniform query string similar to the main service
String _encodePayload(Map<String, dynamic> data) {
  try {
    final entries = <String>[];
    data.forEach((key, value) {
      if (key.isNotEmpty && value != null) {
        final safeValue = value.toString();
        if (safeValue.isNotEmpty) {
          entries.add('$key=$safeValue');
        }
      }
    });
    return entries.join('&');
  } catch (e) {
    log('⚠️ Error encoding background payload: $e');
    return '';
  }
}
