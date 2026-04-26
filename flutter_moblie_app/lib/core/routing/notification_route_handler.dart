import 'dart:developer';
import 'package:thoutha_mobile_app/core/di/dependency_injection.dart';
import 'package:thoutha_mobile_app/features/notifications/logic/notifications_cubit.dart';
import 'package:thoutha_mobile_app/core/helpers/shared_pref_helper.dart';
import 'package:thoutha_mobile_app/core/routing/routes.dart';
import 'package:thoutha_mobile_app/core/routing/navigator_service.dart';
import 'package:thoutha_mobile_app/features/notifications/data/models/notification_payload_model.dart';

/// Handles navigation routing based on notification payload.
/// Maps notification data to existing app routes safely.
class NotificationRouteHandler {
  /// Route to appropriate screen based on notification payload.
  /// Falls back to NotificationsScreen if no confident mapping exists.
  static Future<void> routeFromNotification(
      NotificationPayloadModel payload) async {
    try {
      log('NotificationRouteHandler: routing from payload: $payload');

      // Get navigator context
      final navigator = NavigatorService.navigatorKey.currentState;
      if (navigator == null) {
        log('NotificationRouteHandler: Navigator not available');
        return;
      }

      String? targetRoute;
      Map<String, dynamic>? arguments;

      // Map payload fields to routes
      // Only navigate if we have confident data to pass

      // Mark notification as read if we have an ID
      if (payload.notificationId != null) {
        final notificationId = int.tryParse(payload.notificationId!);
        if (notificationId != null) {
          try {
            getIt<NotificationsCubit>().markAsRead(notificationId);
            log('NotificationRouteHandler: Marked notification $notificationId as read');
          } catch (e) {
            log('NotificationRouteHandler: Could not mark as read: $e');
          }
        }
      }

      if (payload.appointmentId?.isNotEmpty == true) {
        // Navigate to appointments if appointmentId is present
        final doctorId = await SharedPrefHelper.getInt('doctor_id');
        targetRoute = doctorId != 0 
          ? Routes.doctorNextBookingScreen 
          : Routes.appointmentsScreen;
        arguments = {'appointmentId': payload.appointmentId};
        log('NotificationRouteHandler: routing to appointments with ID: ${payload.appointmentId}');
      }

      // If no specific mapping, go to notifications screen
      if (targetRoute == null) {
        targetRoute = Routes.notificationsScreen;
        log('NotificationRouteHandler: routing to notifications screen (default)');
      }

      // Navigate
      navigator.pushNamed(
        targetRoute,
        arguments: arguments,
      );
    } catch (e) {
      log('NotificationRouteHandler error: $e');
    }
  }
}
