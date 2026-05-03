import 'package:easy_localization/easy_localization.dart' hide TextDirection;
/// Notification types based on microservice specification
enum NotificationType {
  // Appointment related
  appointmentConfirmed,
  appointmentCancelled,
  appointmentReminder,

  // Booking requests
  bookingRequestApproved,
  bookingRequestRejected,

  // Treatment plans
  treatmentPlanCreated,
  treatmentPlanUpdated,

  // Payments
  paymentSuccessful,
  paymentFailed,

  // System
  profileUpdateRequired,
  systemAlert,
  generalAnnouncement,

  unknown;

  /// Convert enum to backend API value
  /// e.g., appointmentConfirmed → "APPOINTMENT_CONFIRMED"
  String get backendValue {
    switch (this) {
      case NotificationType.appointmentConfirmed:
        return 'APPOINTMENT_CONFIRMED';
      case NotificationType.appointmentCancelled:
        return 'APPOINTMENT_CANCELLED';
      case NotificationType.appointmentReminder:
        return 'APPOINTMENT_REMINDER';
      case NotificationType.bookingRequestApproved:
        return 'BOOKING_REQUEST_APPROVED';
      case NotificationType.bookingRequestRejected:
        return 'BOOKING_REQUEST_REJECTED';
      case NotificationType.treatmentPlanCreated:
        return 'TREATMENT_PLAN_CREATED';
      case NotificationType.treatmentPlanUpdated:
        return 'TREATMENT_PLAN_UPDATED';
      case NotificationType.paymentSuccessful:
        return 'PAYMENT_SUCCESSFUL';
      case NotificationType.paymentFailed:
        return 'PAYMENT_FAILED';
      case NotificationType.profileUpdateRequired:
        return 'PROFILE_UPDATE_REQUIRED';
      case NotificationType.systemAlert:
        return 'SYSTEM_ALERT';
      case NotificationType.generalAnnouncement:
        return 'GENERAL_ANNOUNCEMENT';
      default:
        return 'UNKNOWN';
    }
  }

  /// Parse backend value to enum
  /// e.g., "APPOINTMENT_CONFIRMED" → appointmentConfirmed
  static NotificationType fromBackendValue(String? value) {
    if (value == null || value.isEmpty) {
      return NotificationType.unknown;
    }

    try {
      return NotificationType.values.firstWhere(
        (type) => type.backendValue == value.toUpperCase(),
        orElse: () => NotificationType.unknown,
      );
    } catch (_) {
      return NotificationType.unknown;
    }
  }

  /// Get user-friendly display name in Arabic
  String get displayName {
    switch (this) {
      case NotificationType.appointmentConfirmed:
        return 'notifications.the_appointment_has_been'.tr();
      case NotificationType.appointmentCancelled:
        return 'notifications.the_appointment_has_been_1'.tr();
      case NotificationType.appointmentReminder:
        return 'notifications.appointment_reminder'.tr();
      case NotificationType.bookingRequestApproved:
        return 'notifications.your_reservation_request_has'.tr();
      case NotificationType.bookingRequestRejected:
        return 'notifications.your_reservation_request_has_1'.tr();
      case NotificationType.treatmentPlanCreated:
        return 'notifications.a_treatment_plan_has'.tr();
      case NotificationType.treatmentPlanUpdated:
        return 'notifications.the_treatment_plan_has'.tr();
      case NotificationType.paymentSuccessful:
        return 'notifications.payment_succeeded'.tr();
      case NotificationType.paymentFailed:
        return 'notifications.payment_failed'.tr();
      case NotificationType.profileUpdateRequired:
        return 'notifications.requires_profile_update'.tr();
      case NotificationType.systemAlert:
        return 'notifications.system_alert'.tr();
      case NotificationType.generalAnnouncement:
        return 'notifications.public_announcement'.tr();
      default:
        return 'notifications.new_notification'.tr();
    }
  }
}
