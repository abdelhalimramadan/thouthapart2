import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:thoutha_mobile_app/features/notifications/data/models/notification_log_model.dart';
import 'package:thoutha_mobile_app/features/notifications/data/repos/notification_repo.dart';

part 'notifications_state.dart';

class NotificationsCubit extends Cubit<NotificationsState> {
  final INotificationRepo _notificationRepo;

  NotificationsCubit(this._notificationRepo)
      : super(const NotificationsState.initial());

  /// Fetch all notifications from API
  Future<void> fetchNotifications() async {
    emit(const NotificationsState.loading());
    final notifications = await _notificationRepo.getNotifications();
    emit(NotificationsState.success(notifications));
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
    final success = await _notificationRepo.markAllNotificationsAsRead();
    if (success) {
      // Refresh notifications after marking all as read
      await fetchNotifications();
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
