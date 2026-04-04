class ApiConstants {
  ApiConstants._(); // prevent instantiation
  static const String baseUrl = 'https://thoutha.page';
  static const String otpBaseUrl = baseUrl;

  // ── Notification Microservice (Development) ───────────────────
  static const String notificationMicroserviceUrl =
      'http://16.16.218.59:9000/api/v1/notifications';
  // ── Authentication ────────────────────────────────────────────
  static const String doctorLogin = '/api/auth/login/doctor';
  static const String signup = '/api/auth/signup';
  // ── Password Reset ────────────────────────────────────────────
  static const String passwordResetRequest = '/api/password-reset/request';
  static const String passwordResetVerifyOtp = '/api/password-reset/verify-otp';
  static const String passwordResetChange =
      '/api/password-reset/change-password';
  // ── OTP ───────────────────────────────────────────────────────
  static const String sendOtp = '/api/otp/send';
  static const String verifyOtp = '/api/otp/verify';
  // ── Doctor (public) ───────────────────────────────────────────
  static const String getDoctorsByCities = '/api/doctor/getDoctorsByCity';
  static const String getDoctorsByCategories =
      '/api/doctor/getDoctorsByCategory';
  // ── Doctor (authenticated) ────────────────────────────────────
  static const String getDoctorById = '/api/doctor/getDoctorById';
  static const String updateDoctor = '/api/doctor/updateDoctor';
  static const String deleteDoctor = '/api/doctor/deleteDoctor';
  // ── Reference data ────────────────────────────────────────────
  static const String getUniversities = '/api/university/getAllUniversities';
  static const String getCategories = '/api/category/getCategories';
  static const String getCities = '/api/cities/getAllCities';
  // ── Case Requests ─────────────────────────────────────────────
  static const String getCaseRequestsByCategories =
      '/api/request/getRequestByCategoryId';
  static const String createCaseRequest = '/api/request/createRequest';
  static const String updateCaseRequest = '/api/request/updateRequest';
  static const String getRequestById = '/api/request/getRequestById';
  static const String deleteRequest =
      '/api/request/deleteRequest'; // {requestId} will be appended
  static const String getRequestsByDoctorId =
      '/api/request/getRequestsByDoctorId';
  static const String editRequest = '/api/request/editRequest';
  // ── Appointments ──────────────────────────────────────────────
  static const String createAppointment = '/api/appointment/createAppointment';
  static const String pendingAppointments =
      '/api/appointment/pendingAppointments';
  static const String approvedAppointments = '/api/appointment/getApproved';
  static const String doneAppointments = '/api/appointment/getDone';
  static const String updateAppointmentStatus = '/api/appointment/updateStatus';
  static const String appointmentHistory = '/api/appointment/history';
  static const String deleteAppointment = '/api/appointment/deleteAppointment';
  // ── Chatbot ──────────────────────────────────────────────────
  static const String startSession = '/api/session/start';
  static const String submitAnswer = '/api/session/answer';
  static const String chat = '/api/chat';
  // ── Notifications Microservice (16.16.218.59:9000) ──────────────
  // Base URL for all notification operations
  static const String notificationBaseUrl = 'http://16.16.218.59:9000/api/v1';

  // Device Token Registration
  static const String registerDeviceToken =
      'http://16.16.218.59:9000/api/v1/device-tokens/register'; // Main backend (8080)

  // Notification History & Management
  static const String getNotifications =
      'http://16.16.218.59:9000/api/v1/notifications'; // GET all
  static const String getNotificationById =
      'http://16.16.218.59:9000/api/v1/notifications/{id}'; // GET one
  static const String markNotificationAsRead =
      'http://16.16.218.59:9000/api/v1/notifications/{id}/read'; // PATCH
  static const String markAllNotificationsAsRead =
      'http://16.16.218.59:9000/api/v1/notifications/read-all'; // PATCH
  static const String deleteNotification =
      'http://16.16.218.59:9000/api/v1/notifications/{id}'; // DELETE one
  static const String deleteAllNotifications =
      'http://16.16.218.59:9000/api/v1/notifications'; // DELETE all

  // Notification Preferences & Settings
  static const String getNotificationPreferences =
      'http://16.16.218.59:9000/api/v1/notification-preferences'; // GET
  static const String updateNotificationPreferences =
      'http://16.16.218.59:9000/api/v1/notification-preferences'; // PUT/PATCH

  // Notification History
  static const String notificationHistory =
      'http://16.16.218.59:9000/api/v1/notifications/history'; // GET with pagination
}
