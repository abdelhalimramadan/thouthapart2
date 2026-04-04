import 'dart:developer';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:thoutha_mobile_app/core/helpers/constants.dart';
import 'package:thoutha_mobile_app/core/helpers/shared_pref_helper.dart';
import 'package:thoutha_mobile_app/core/routing/routes.dart';
import 'package:thoutha_mobile_app/core/routing/navigator_service.dart';
import 'package:thoutha_mobile_app/features/notifications/data/models/notification_payload_model.dart';
import 'package:thoutha_mobile_app/features/notifications/data/repos/notification_repo.dart';

/// Firebase Cloud Messaging service for handling push notifications.
///
/// Responsibilities:
/// - Initialize Firebase Messaging and local notifications
/// - Retrieve and manage FCM tokens
/// - Handle incoming messages (foreground, background, tap)
/// - Display local notifications
/// - Register device token with Java backend on login
/// - Route users based on notification types
class FirebaseMessagingService {
  static final FirebaseMessagingService _instance =
      FirebaseMessagingService._internal();

  factory FirebaseMessagingService() {
    return _instance;
  }

  FirebaseMessagingService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  late INotificationRepo _notificationRepo;

  /// Initialize Firebase Messaging and local notifications.
  /// Must be called during app startup after dependency injection is set up.
  Future<void> initialize(INotificationRepo notificationRepo) async {
    _notificationRepo = notificationRepo;

    try {
      log('🔔 Initializing Firebase Cloud Messaging Service...');

      // Request notification permissions (required for iOS)
      await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: true,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      // Initialize local notifications
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings iosSettings =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _localNotifications.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: _handleLocalNotificationTap,
      );

      // Create notification channel for Android
      await _createNotificationChannel();

      // Get initial FCM token
      await _getAndStoreFcmToken();

      // Listen for token refresh
      _listenForTokenRefresh();

      // Set up message handlers
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

      // Handle initial message if app is launched from notification
      final initialMessage = await _firebaseMessaging.getInitialMessage();
      if (initialMessage != null) {
        await _handleInitialMessage(initialMessage);
      }

      log('✅ Firebase Messaging Service initialized successfully');
    } catch (e) {
      log('❌ Error initializing Firebase Messaging Service: $e');
    }
  }

  /// Get current FCM token and save it locally
  Future<String?> _getAndStoreFcmToken() async {
    try {
      final token = await _firebaseMessaging.getToken();
      if (token != null && token.isNotEmpty) {
        await SharedPrefHelper.setData(SharedPrefKeys.fcmToken, token);
        log('✅ FCM Token obtained and stored: ${token.substring(0, 20)}...');
        return token;
      }
    } catch (e) {
      log('❌ Error getting FCM token: $e');
    }
    return null;
  }

  /// Listen for FCM token refresh and update local storage
  void _listenForTokenRefresh() {
    _firebaseMessaging.onTokenRefresh.listen((newToken) async {
      log('🔄 FCM Token refreshed: ${newToken.substring(0, 20)}...');
      await SharedPrefHelper.setData(SharedPrefKeys.fcmToken, newToken);
    });
  }

  /// Create Android notification channel
  Future<void> _createNotificationChannel() async {
    try {
      final androidPlugin =
          _localNotifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()!;

      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          'high_importance_channel',
          'High Importance Notifications',
          description: 'Channel for high priority notifications',
          importance: Importance.max,
          enableVibration: true,
          playSound: true,
          showBadge: true,
        ),
      );

      log('✅ Notification channel created');
    } catch (e) {
      log('⚠️ Error creating notification channel: $e');
    }
  }

  /// Handle messages received while app is in foreground
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    log('📬 Handling foreground message: ${message.messageId}');
    log('Data: ${message.data}');

    // Display local notification
    await _showLocalNotification(message);
  }

  /// Handle message when app is opened from notification
  Future<void> _handleMessageOpenedApp(RemoteMessage message) async {
    log('📱 App opened from notification: ${message.messageId}');

    final payload =
        NotificationPayloadModel.fromRemoteMessageData(message.data);
    await _routeFromNotification(payload);
  }

  /// Handle initial message when app is launched from notification
  Future<void> _handleInitialMessage(RemoteMessage message) async {
    log('🚀 Initial message on app launch: ${message.messageId}');

    final payload =
        NotificationPayloadModel.fromRemoteMessageData(message.data);
    await _routeFromNotification(payload);
  }

  /// Handle local notification tap
  static void _handleLocalNotificationTap(
      NotificationResponse notificationResponse) {
    try {
      final payload = notificationResponse.payload;
      log('👆 Local notification tapped: $payload');

      if (payload != null && payload.isNotEmpty) {
        final notificationPayload =
            NotificationPayloadModel.fromEncodedString(payload);

        // Route to appropriate screen
        NavigatorService.navigatorKey.currentState?.pushNamed(
          Routes.notificationsScreen,
          arguments: notificationPayload.toMap(),
        );
      }
    } catch (e) {
      log('❌ Error handling notification tap: $e');
    }
  }

  /// Display local notification for foreground messages
  Future<void> _showLocalNotification(RemoteMessage message) async {
    try {
      final notification = message.notification;
      if (notification == null) return;

      final title = notification.title ?? 'إشعار جديد';
      final body = notification.body ?? 'لديك إشعار جديد';
      final payload = _encodePayload(message.data);

      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        'high_importance_channel',
        'High Importance Notifications',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        playSound: true,
        ticker: 'ticker',
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

      await _localNotifications.show(
        id: message.hashCode.abs(),
        title: title,
        body: body,
        notificationDetails: platformDetails,
        payload: payload,
      );

      log('📲 Local notification displayed: $title');
    } catch (e) {
      log('❌ Error showing local notification: $e');
    }
  }

  /// Encode notification data as query string with null safety
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
      log('⚠️ Error encoding payload: $e');
      return '';
    }
  }

  /// Route to appropriate screen based on notification type and payload
  Future<void> _routeFromNotification(NotificationPayloadModel payload) async {
    try {
      if (!payload.hasValidData) {
        log('⚠️ Notification has no valid routing data, navigating to notifications');
        NavigatorService.navigatorKey.currentState?.pushNamed(
          Routes.notificationsScreen,
        );
        return;
      }

      final navigator = NavigatorService.navigatorKey.currentState;
      if (navigator == null) {
        log('⚠️ Navigator not available for routing');
        return;
      }

      String? targetRoute;
      Map<String, dynamic>? arguments;

      // Route based on notification type
      if (payload.isAppointmentNotification && payload.appointmentId != null) {
        targetRoute = Routes.appointmentsScreen;
        arguments = {'appointmentId': payload.appointmentId};
        log('🗓️ Routing to appointments: ${payload.appointmentId}');
      } else if (payload.isTreatmentPlanNotification &&
          payload.treatmentPlanId != null) {
        // TODO: Add treatment plan screen route when available
        targetRoute = Routes.notificationsScreen;
        arguments = payload.toMap();
        log('💊 Treatment plan notification: ${payload.treatmentPlanId}');
      } else if (payload.requestId != null) {
        targetRoute = Routes.doctorHomeScreen;
        arguments = {'requestId': payload.requestId};
        log('📋 Routing to requests: ${payload.requestId}');
      }

      // Default fallback
      targetRoute ??= Routes.notificationsScreen;
      arguments ??= payload.toMap();

      navigator.pushNamed(targetRoute, arguments: arguments);
    } catch (e) {
      log('❌ Error routing from notification: $e');
      // Fallback to notifications screen
      NavigatorService.navigatorKey.currentState?.pushNamed(
        Routes.notificationsScreen,
      );
    }
  }

  /// Register device token with Java backend
  /// Called after successful authentication
  /// Request includes: fcmToken, deviceType (ANDROID/IOS), deviceModel, osVersion
  Future<bool> registerTokenWithBackend() async {
    try {
      final token = await SharedPrefHelper.getString(SharedPrefKeys.fcmToken);

      if (token.isEmpty) {
        log('⚠️ No FCM token available for registration');
        return false;
      }

      log('📤 Registering FCM token with Java backend...');

      final success = await _notificationRepo.registerDeviceToken(
        fcmToken: token,
        deviceType: Platform.isAndroid ? 'ANDROID' : 'IOS',
        deviceModel: _getDeviceModel(),
        osVersion: Platform.operatingSystemVersion,
      );

      if (success) {
        log('✅ Device token registered successfully');
      } else {
        log('❌ Failed to register device token');
      }

      return success;
    } catch (e) {
      log('❌ Error registering token with backend: $e');
      return false;
    }
  }

  /// Get device model name
  String _getDeviceModel() {
    try {
      if (Platform.isAndroid) {
        return 'Android Device';
      } else if (Platform.isIOS) {
        return 'iOS Device';
      }
    } catch (_) {}
    return 'Unknown Device';
  }
}
