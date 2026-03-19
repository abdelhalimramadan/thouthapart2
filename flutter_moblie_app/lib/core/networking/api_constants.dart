class ApiConstants {
  ApiConstants._(); // prevent instantiation

  static const String baseUrl = 'https://thoutha.page';
  static const String otpBaseUrl = baseUrl;

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
  static const String deleteRequest = '/api/request/deleteRequest';
  static const String getRequestsByDoctorId =
      '/api/request/getRequestsByDoctorId';
  static const String editRequest = '/api/request/editRequest';

  // ── Appointments ──────────────────────────────────────────────
  static const String createAppointment = '/api/appointment/createAppointment';
  static const String pendingAppointments =
      '/api/appointment/pendingAppointments';
  static const String updateAppointmentStatus = '/api/appointment/updateStatus';
  static const String appointmentHistory = '/api/appointment/history';
  static const String deleteAppointment = '/api/appointment/deleteAppointment';

  // ── Chatbot ──────────────────────────────────────────────────
  static const String startSession = '/api/session/start';
  static const String submitAnswer = '/api/session/answer';
  static const String chat = '/api/chat';
}
