part of 'notifications_cubit.dart';

class NotificationsState {
  const NotificationsState._();

  const factory NotificationsState.initial() = InitialState;
  const factory NotificationsState.loading() = LoadingState;
  const factory NotificationsState.success(List<NotificationLogModel> notifications) = SuccessState;
  const factory NotificationsState.failure(String message) = FailureState;
}

class InitialState extends NotificationsState {
  const InitialState() : super._();
}

class LoadingState extends NotificationsState {
  const LoadingState() : super._();
}

class SuccessState extends NotificationsState {
  final List<NotificationLogModel> notifications;

  const SuccessState(this.notifications) : super._();
}

class FailureState extends NotificationsState {
  final String message;

  const FailureState(this.message) : super._();
}

