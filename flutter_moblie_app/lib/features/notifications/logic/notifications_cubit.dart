import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:thoutha_mobile_app/core/helpers/constants.dart';
import 'package:thoutha_mobile_app/core/helpers/shared_pref_helper.dart';
import 'package:thoutha_mobile_app/features/notifications/data/models/notification_log_model.dart';
import 'package:thoutha_mobile_app/features/notifications/data/repos/notification_repo.dart';

part 'notifications_state.dart';

class NotificationsCubit extends Cubit<NotificationsState> {
  final INotificationRepo _notificationRepo;

  NotificationsCubit(this._notificationRepo)
      : super(NotificationsState.initial());

  /// Fetch all notifications from API
  Future<void> fetchNotifications({bool showLoading = true}) async {
    if (showLoading && !isClosed) {
      emit(NotificationsState.loading());
    }

    final doctorToken = await SharedPrefHelper.getSecuredString(SharedPrefKeys.userToken);
    List<NotificationLogModel> notifications = [];

    if (doctorToken.isNotEmpty && doctorToken != 'null') {
      // 1. Logged-in Doctor
      notifications = await _notificationRepo.getNotifications();
    } else {
      // 2. Patient (Guest)
      final patientToken = await SharedPrefHelper.getString(SharedPrefKeys.patientToken);
      if (patientToken.isNotEmpty) {
        notifications = await _notificationRepo.getPatientNotifications(patientToken);
      }
    }

    if (!isClosed) {
      emit(NotificationsState.success(notifications));
    }
  }

  /// Request a new patient temporary token and fetch notifications
  Future<void> fetchPatientNotificationsByPhone(String phone) async {
    emit(NotificationsState.loading());
    final token = await _notificationRepo.getPatientToken(phone: phone);
    if (token != null) {
      await SharedPrefHelper.setData(SharedPrefKeys.patientToken, token);
      final notifications = await _notificationRepo.getPatientNotifications(token);
      emit(NotificationsState.success(notifications));
    } else {
      emit(NotificationsState.success([]));
    }
  }

  /// Mark a specific notification as read
  Future<void> markAsRead(int notificationId) async {
    final success =
        await _notificationRepo.markNotificationAsRead(notificationId);
    if (success) {
      // Refresh notifications after marking as read
      await fetchNotifications();
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    final currentState = state;
    if (currentState is SuccessState && !isClosed) {
      final updated = currentState.notifications
          .map((notification) => notification.copyWith(readStatus: true))
          .toList();
      emit(NotificationsState.success(updated));
    }

    final success = await _notificationRepo.markAllNotificationsAsRead();
    if (success && !isClosed) {
      // Sync with backend in background without showing loading flicker.
      await fetchNotifications(showLoading: false);
    } else {
      // Re-sync from backend if optimistic update fails.
      await fetchNotifications(showLoading: false);
    }
  }

  /// Delete a specific notification
  Future<void> deleteNotification(int notificationId) async {
    final success = await _notificationRepo.deleteNotification(notificationId);
    if (success) {
      // Refresh notifications after deletion
      await fetchNotifications();
    }
  }

  /// Delete all notifications
  Future<void> deleteAllNotifications() async {
    final success = await _notificationRepo.deleteAllNotifications();
    if (success) {
      // Refresh notifications after deletion
      await fetchNotifications();
    }
  }

  /// Get count of unread notifications
  int getUnreadCount() {
    if (state is SuccessState) {
      final notifications = (state as SuccessState).notifications;
      return notifications.where((n) => !n.readStatus).length;
    }
    return 0;
  }
}
