import 'dart:developer';

import 'package:thoutha_mobile_app/core/networking/api_constants.dart';
import 'package:thoutha_mobile_app/core/networking/api_service.dart';
import 'package:thoutha_mobile_app/features/notifications/data/models/device_token_request.dart';
import 'package:thoutha_mobile_app/features/notifications/data/models/notification_log_model.dart';

/// Abstract interface for notification repository operations
abstract class INotificationRepo {
  /// Register FCM token with Java backend for device identification
  /// Endpoint: POST /api/v1/device-tokens/register (on main backend port 8080)
  Future<bool> registerDeviceToken({
    required String fcmToken,
    required String deviceType,
    int? userId,
    String? deviceModel,
    String? osVersion,
  });

  /// Fetch all notifications for the current user
  /// Endpoint: GET /api/v1/notifications
  Future<List<NotificationLogModel>> getNotifications();

  /// Mark a notification as read
  /// Endpoint: PATCH /api/v1/notifications/{id}/read
  Future<bool> markNotificationAsRead(int notificationId);

  /// Mark all notifications as read
  /// Endpoint: PATCH /api/v1/notifications/read-all
  Future<bool> markAllNotificationsAsRead();

  /// Delete a specific notification
  /// Endpoint: DELETE /api/v1/notifications/{id}
  Future<bool> deleteNotification(int notificationId);

  /// Delete all notifications
  /// Endpoint: DELETE /api/v1/notifications
  Future<bool> deleteAllNotifications();

  /// Fetch patient temporary token
  /// Endpoint: GET /api/v1/patient/token
  Future<String?> getPatientToken({String? phone, int? appointmentId});

  /// Fetch notifications for a patient using temporary token
  /// Endpoint: GET /api/v1/patient/notifications/{token}
  Future<List<NotificationLogModel>> getPatientNotifications(String token);

  /// Validate patient temporary token
  /// Endpoint: POST /api/v1/patient/token-validate
  Future<bool> validatePatientToken(String token);
}

/// Implementation of notification repository
/// Communicates with both Java backend and Notification microservice
class NotificationRepo implements INotificationRepo {
  final ApiService _apiService;

  NotificationRepo(this._apiService);

  @override
  Future<bool> registerDeviceToken({
    required String fcmToken,
    required String deviceType,
    int? userId,
    String? deviceModel,
    String? osVersion,
  }) async {
    try {
      log('📱 Registering device token with Java backend...');

      final request = DeviceTokenRequest(
        userId: userId,
        fcmToken: fcmToken,
        deviceType: deviceType,
        deviceModel: deviceModel,
        osVersion: osVersion,
      );

      final response = await _apiService.post(
        ApiConstants.registerDeviceToken,
        data: request.toJson(),
      );

      log('✅ Device token registration response: $response');

      // Check if registration was successful
      final success = response['success'] == true;
      if (success) {
        log('✅ Device token registered successfully with ID: ${response['deviceTokenId']}');
      } else {
        log('❌ Device token registration failed: ${response['message']}');
      }
      return success;
    } on Exception catch (e, stackTrace) {
      log('❌ Error registering device token: $e\n$stackTrace');

      // Return false on error - let the app continue without token registration
      // The app will still function, just without push notifications
      return false;
    }
  }

  @override
  Future<List<NotificationLogModel>> getNotifications() async {
    try {
      log('📨 Fetching notifications from API...');

      final response = await _apiService.get(
        ApiConstants.getNotifications,
      );

      if (response['success'] == true) {
        final data = response['data'];

        // Handle both list and wrapped responses
        List? rawList = data is List
            ? data
            : (data is Map
                ? (data['notifications'] ??
                    data['content'] ??
                    data['items'] ??
                    data['data']) as List?
                : null);

        if (rawList == null) {
          log('⚠️ No notifications found or unexpected format');
          return [];
        }

        final notifications = <NotificationLogModel>[];
        for (final item in rawList) {
          try {
            final map = Map<String, dynamic>.from(item as Map);
            notifications.add(NotificationLogModel.fromJson(map));
          } catch (e) {
            log('⚠️ Failed to parse notification item: $e\nItem: $item');
          }
        }

        log('✅ Fetched ${notifications.length} notifications');
        return notifications;
      } else {
        log('❌ Failed to fetch notifications: ${response['error']}');
        return [];
      }
    } catch (e, stackTrace) {
      log('❌ Error fetching notifications: $e\n$stackTrace');
      return [];
    }
  }

  @override
  Future<bool> markNotificationAsRead(int notificationId) async {
    try {
      log('📍 Marking notification $notificationId as read...');

      final response = await _apiService.put(
        ApiConstants.markNotificationAsRead
            .replaceFirst('{id}', '$notificationId'),
      );

      final success = response['success'] == true;
      if (success) {
        log('✅ Notification $notificationId marked as read');
      } else {
        log('❌ Failed to mark notification as read: ${response['error']}');
      }
      return success;
    } catch (e, stackTrace) {
      log('❌ Error marking notification as read: $e\n$stackTrace');
      return false;
    }
  }

  @override
  Future<bool> markAllNotificationsAsRead() async {
    try {
      log('📍 Marking all notifications as read...');

      final response = await _apiService.put(
        ApiConstants.markAllNotificationsAsRead,
      );

      final success = response['success'] == true;
      if (success) {
        log('✅ All notifications marked as read');
      } else {
        log('❌ Failed to mark all notifications as read: ${response['error']}');
      }
      return success;
    } catch (e, stackTrace) {
      log('❌ Error marking all notifications as read: $e\n$stackTrace');
      return false;
    }
  }

  @override
  Future<bool> deleteNotification(int notificationId) async {
    try {
      log('🗑️ Deleting notification $notificationId...');

      final response = await _apiService.delete(
        ApiConstants.deleteNotification.replaceFirst('{id}', '$notificationId'),
      );

      final success = response['success'] == true;
      if (success) {
        log('✅ Notification $notificationId deleted');
      } else {
        log('❌ Failed to delete notification: ${response['error']}');
      }
      return success;
    } catch (e, stackTrace) {
      log('❌ Error deleting notification: $e\n$stackTrace');
      return false;
    }
  }

  @override
  Future<bool> deleteAllNotifications() async {
    try {
      log('🗑️ Deleting all notifications...');

      final response = await _apiService.delete(
        ApiConstants.deleteAllNotifications,
      );

      final success = response['success'] == true;
      if (success) {
        log('✅ All notifications deleted');
      } else {
        log('❌ Failed to delete all notifications: ${response['error']}');
      }
      return success;
    } catch (e, stackTrace) {
      log('❌ Error deleting all notifications: $e\n$stackTrace');
      return false;
    }
  }

  @override
  Future<String?> getPatientToken({String? phone, int? appointmentId}) async {
    try {
      log('🎫 Fetching patient temporary token...');
      final Map<String, dynamic> query = {};
      if (phone != null) query['phone'] = phone;
      if (appointmentId != null) query['appointment_id'] = appointmentId;

      final response = await _apiService.get(ApiConstants.getPatientToken, query: query);
      if (response['success'] == true && response['data'] != null) {
        return response['data']['token'];
      }
      return null;
    } catch (e) {
      log('❌ Error fetching patient token: $e');
      return null;
    }
  }

  @override
  Future<List<NotificationLogModel>> getPatientNotifications(String token) async {
    try {
      log('📨 Fetching patient notifications...');
      final response = await _apiService.get(
        ApiConstants.getPatientNotifications.replaceFirst('{token}', token),
      );

      if (response['success'] == true) {
        final data = response['data'];
        List? rawList = data is List ? data : (data is Map ? data['notifications'] as List? : null);
        
        if (rawList == null) return [];

        return rawList.map((item) => NotificationLogModel.fromJson(Map<String, dynamic>.from(item))).toList();
      }
      return [];
    } catch (e) {
      log('❌ Error fetching patient notifications: $e');
      return [];
    }
  }

  @override
  Future<bool> validatePatientToken(String token) async {
    try {
      log('🔍 Validating patient token...');
      final response = await _apiService.post(
        ApiConstants.validatePatientToken,
        data: {'token': token},
      );
      return response['success'] == true;
    } catch (e) {
      log('❌ Error validating patient token: $e');
      return false;
    }
  }
}
