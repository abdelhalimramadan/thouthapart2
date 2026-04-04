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
        return 'تم تأكيد الموعد';
      case NotificationType.appointmentCancelled:
        return 'تم إلغاء الموعد';
      case NotificationType.appointmentReminder:
        return 'تذكير بالموعد';
      case NotificationType.bookingRequestApproved:
        return 'تم قبول طلب الحجز';
      case NotificationType.bookingRequestRejected:
        return 'تم رفض طلب الحجز';
      case NotificationType.treatmentPlanCreated:
        return 'تم إنشاء خطة العلاج';
      case NotificationType.treatmentPlanUpdated:
        return 'تم تحديث خطة العلاج';
      case NotificationType.paymentSuccessful:
        return 'نجح الدفع';
      case NotificationType.paymentFailed:
        return 'فشل الدفع';
      case NotificationType.profileUpdateRequired:
        return 'يتطلب تحديث الملف الشخصي';
      case NotificationType.systemAlert:
        return 'تنبيه النظام';
      case NotificationType.generalAnnouncement:
        return 'إعلان عام';
      default:
        return 'إشعار جديد';
    }
  }
}
