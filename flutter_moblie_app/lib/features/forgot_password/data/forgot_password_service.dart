import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:thoutha_mobile_app/core/helpers/phone_helper.dart';
import 'package:thoutha_mobile_app/core/networking/api_constants.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;

/// Handles all password-reset API calls.
///
/// Flow:
///   1. [requestReset]   → POST /api/password-reset/request   (sends OTP via WhatsApp)
///   2. [verifyOtp]      → POST /api/password-reset/verify-otp
///   3. [changePassword] → POST /api/password-reset/change-password
class PasswordResetService {
  PasswordResetService._() {
    _initDio();
  }
  static final PasswordResetService instance = PasswordResetService._();

  // Persistent Dio instance with cookie support for session management
  late final Dio _dio;
  late final CookieJar _cookieJar;

  void _initDio() {
    _cookieJar = CookieJar();
    _dio = Dio(BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: Duration(seconds: 10),
      receiveTimeout: Duration(seconds: 10),
      contentType: 'application/json',
      responseType: ResponseType.json,
      headers: const {'Accept': 'application/json'},
      validateStatus: (status) => status != null,
    ))
      ..interceptors.add(CookieManager(_cookieJar));
  }

  /// Clear cookies (useful when starting a new password reset flow)
  void clearSession() {
    _cookieJar.deleteAll();
  }

  // ── Step 1: Request OTP ─────────────────────────────────────────────────

  /// Sends an OTP to the user's WhatsApp.
  /// [phone] is normalised to +2xxxxxxxxxx before sending.
  Future<Map<String, dynamic>> requestReset(String phone) async {
    // Clear any previous session
    clearSession();

    final normalised = PhoneHelper.normalizeEgyptPhone(phone);
    try {
      final res = await _dio.post(
        ApiConstants.passwordResetRequest,
        data: {'phone_number': normalised},
      );

      if (res.statusCode == 200) {
        final data = res.data is Map ? res.data as Map : {};
        return {
          'success': true,
          'message': data['message'] ?? 'forgot_password.a_verification_code_has'.tr(),
          'expires_in': data['expires_in_seconds'] ?? 300,
          'user_email': data['user_email'],
          'phone': normalised,
        };
      }

      // Handle specific error codes from API docs
      switch (res.statusCode) {
        case 400:
          return {'success': false, 'message': 'forgot_password.invalid_phone_number_format'.tr()};
        case 404:
          return {'success': false, 'message': 'forgot_password.there_is_no_account'.tr()};
        case 429:
          return {
            'success': false,
            'message': 'forgot_password.too_many_requests_wait'.tr()
          };
        case 503:
          return {
            'success': false,
            'message': 'forgot_password.whatsapp_service_is_currently'.tr()
          };
        default:
          return _errorFromResponse(res, 'forgot_password.failed_to_send_verification'.tr());
      }
    } on DioException catch (e) {
      return _dioError(e);
    } catch (e) {
      return {'success': false, 'message': 'booking.an_unexpected_error_occurred'.tr()};
    }
  }

  // ── Step 2: Verify OTP ──────────────────────────────────────────────────

  Future<Map<String, dynamic>> verifyOtp({
    required String phone,
    required String otp,
  }) async {
    final normalised = PhoneHelper.normalizeEgyptPhone(phone);
    try {
      final res = await _dio.post(
        ApiConstants.passwordResetVerifyOtp,
        data: {
          'phone_number': normalised,
          'otp': otp,
        },
      );

      if (res.statusCode == 200) {
        final data = res.data is Map ? res.data as Map : {};
        return {
          'success': true,
          'message': data['message'] ??
              'forgot_password.verification_completed_successfully_you'.tr(),
          'session_expires_in': data['session_expires_in_minutes'] ?? 10,
        };
      }

      // Handle specific error codes from API docs
      switch (res.statusCode) {
        case 400:
          return {
            'success': false,
            'message': 'forgot_password.the_verification_code_is_1'.tr()
          };
        case 404:
          return {
            'success': false,
            'message': 'forgot_password.a_verification_code_was'.tr()
          };
        case 410:
          return {
            'success': false,
            'message': 'forgot_password.the_verification_code_has'.tr()
          };
        case 429:
          return {
            'success': false,
            'message':
                'forgot_password.you_have_exceeded_the'.tr()
          };
        default:
          return _errorFromResponse(res, 'forgot_password.the_verification_code_is'.tr());
      }
    } on DioException catch (e) {
      return _dioError(e);
    } catch (e) {
      return {'success': false, 'message': 'booking.an_unexpected_error_occurred'.tr()};
    }
  }

  // ── Step 3: Change Password ─────────────────────────────────────────────

  Future<Map<String, dynamic>> changePassword({
    required String phone,
    required String newPassword,
    required String confirmPassword,
  }) async {
    if (newPassword != confirmPassword) {
      return {'success': false, 'message': 'forgot_password.the_two_passwords_do'.tr()};
    }
    if (newPassword.length < 6) {
      return {
        'success': false,
        'message': 'forgot_password.password_must_be_at'.tr()
      };
    }

    final normalised = PhoneHelper.normalizeEgyptPhone(phone);
    try {
      final res = await _dio.post(
        ApiConstants.passwordResetChange,
        data: {
          'phone_number': normalised,
          'new_password': newPassword,
          'confirm_password': confirmPassword,
        },
      );

      if (res.statusCode == 200) {
        final data = res.data is Map ? res.data as Map : {};
        return {
          'success': true,
          'message': data['message'] ?? 'forgot_password.the_password_has_been'.tr(),
        };
      }

      // Handle specific error codes from API docs
      switch (res.statusCode) {
        case 400:
          return {
            'success': false,
            'message': 'forgot_password.invalid_data_check_input'.tr()
          };
        case 401:
          return {'success': false, 'message': 'forgot_password.you_must_check_the'.tr()};
        case 403:
          return {
            'success': false,
            'message': 'forgot_password.you_must_verify_the'.tr()
          };
        case 404:
          return {'success': false, 'message': 'forgot_password.there_is_no_account'.tr()};
        case 410:
          return {
            'success': false,
            'message': 'forgot_password.the_session_has_expired'.tr()
          };
        case 429:
          return {
            'success': false,
            'message': 'forgot_password.too_many_requests_wait'.tr()
          };
        default:
          return _errorFromResponse(res, 'forgot_password.failed_to_change_password'.tr());
      }
    } on DioException catch (e) {
      return _dioError(e);
    } catch (e) {
      return {'success': false, 'message': 'booking.an_unexpected_error_occurred'.tr()};
    }
  }

  // ── Helpers ─────────────────────────────────────────────────────────────

  Map<String, dynamic> _errorFromResponse(Response res, String fallback) {
    // Try to read the server's own message first
    String? serverMsg;
    final data = res.data;
    if (data is Map) {
      serverMsg =
          (data['message'] ?? data['error'] ?? data['detail'])?.toString();
    } else if (data is String && data.isNotEmpty) {
      serverMsg = data;
    }

    // If server returns a generic internal error, we ignore it and use our Arabic message
    if (serverMsg != null &&
        (serverMsg.toLowerCase().contains('internal error') ||
            serverMsg.toLowerCase().contains('server error'))) {
      serverMsg = null;
    }

    // Only use hardcoded Arabic if the server returned nothing useful
    final bool hasServerMsg = serverMsg != null && serverMsg.isNotEmpty;
    String msg = hasServerMsg ? serverMsg : fallback;

    if (!hasServerMsg) {
      switch (res.statusCode) {
        case 400:
          msg = 'forgot_password.invalid_data_please_check'.tr();
          break;
        case 404:
          msg = 'forgot_password.there_is_no_account'.tr();
          break;
        case 410:
          msg = 'forgot_password.the_verification_code_has_1'.tr();
          break;
        case 429:
          msg = 'forgot_password.too_many_requests_wait'.tr();
          break;
        case 403:
          msg = 'forgot_password.you_must_check_the'.tr();
          break;
        case 500:
          msg = 'forgot_password.there_is_no_account'.tr();
          break;
        default:
          break;
      }
    }

    return {'success': false, 'message': msg, 'statusCode': res.statusCode};
  }

  Map<String, dynamic> _dioError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return {
        'success': false,
        'message': 'forgot_password.connection_timed_out_check'.tr()
      };
    }
    if (e.type == DioExceptionType.connectionError) {
      return {'success': false, 'message': 'forgot_password.unable_to_connect_to'.tr()};
    }
    return {'success': false, 'message': 'forgot_password.a_network_error_has'.tr()};
  }
}
