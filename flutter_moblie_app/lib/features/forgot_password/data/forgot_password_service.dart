import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:thoutha_mobile_app/core/helpers/phone_helper.dart';
import 'package:thoutha_mobile_app/core/networking/api_constants.dart';

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
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
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
          'message': data['message'] ?? 'تم إرسال رمز التحقق على الواتساب',
          'expires_in': data['expires_in_seconds'] ?? 300,
          'user_email': data['user_email'],
          'phone': normalised,
        };
      }

      // Handle specific error codes from API docs
      switch (res.statusCode) {
        case 400:
          return {'success': false, 'message': 'تنسيق رقم الهاتف غير صحيح'};
        case 404:
          return {'success': false, 'message': 'لا يوجد حساب مرتبط بهذا الرقم'};
        case 429:
          return {
            'success': false,
            'message': 'طلبات كثيرة جداً، انتظر قليلاً ثم أعد المحاولة'
          };
        case 503:
          return {
            'success': false,
            'message': 'خدمة الواتساب غير متاحة حالياً، حاول مرة أخرى لاحقاً'
          };
        default:
          return _errorFromResponse(res, 'فشل في إرسال رمز التحقق');
      }
    } on DioException catch (e) {
      return _dioError(e);
    } catch (e) {
      return {'success': false, 'message': 'حدث خطأ غير متوقع'};
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
              'تم التحقق بنجاح، يمكنك الآن تغيير كلمة المرور',
          'session_expires_in': data['session_expires_in_minutes'] ?? 10,
        };
      }

      // Handle specific error codes from API docs
      switch (res.statusCode) {
        case 400:
          return {
            'success': false,
            'message': 'رمز التحقق غير صحيح أو البيانات ناقصة'
          };
        case 404:
          return {
            'success': false,
            'message': 'لم يتم إرسال رمز تحقق لهذا الرقم، يرجى طلب رمز جديد'
          };
        case 410:
          return {
            'success': false,
            'message': 'انتهت صلاحية رمز التحقق، يرجى طلب رمز جديد'
          };
        case 429:
          return {
            'success': false,
            'message':
                'تجاوزت عدد المحاولات المسموح بها، يرجى الانتظار والمحاولة لاحقاً'
          };
        default:
          return _errorFromResponse(res, 'رمز التحقق غير صحيح');
      }
    } on DioException catch (e) {
      return _dioError(e);
    } catch (e) {
      return {'success': false, 'message': 'حدث خطأ غير متوقع'};
    }
  }

  // ── Step 3: Change Password ─────────────────────────────────────────────

  Future<Map<String, dynamic>> changePassword({
    required String phone,
    required String newPassword,
    required String confirmPassword,
  }) async {
    if (newPassword != confirmPassword) {
      return {'success': false, 'message': 'كلمتا المرور غير متطابقتين'};
    }
    if (newPassword.length < 6) {
      return {
        'success': false,
        'message': 'كلمة المرور يجب أن تكون 6 أحرف على الأقل'
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
          'message': data['message'] ?? 'تم تغيير كلمة المرور بنجاح',
        };
      }

      // Handle specific error codes from API docs
      switch (res.statusCode) {
        case 400:
          return {
            'success': false,
            'message': 'بيانات غير صحيحة، تحقق من المدخلات'
          };
        case 401:
          return {'success': false, 'message': 'يجب التحقق من رمز OTP أولاً'};
        case 403:
          return {
            'success': false,
            'message': 'يجب التحقق من رمز OTP أولاً قبل تغيير كلمة المرور'
          };
        case 404:
          return {'success': false, 'message': 'لا يوجد حساب مرتبط بهذا الرقم'};
        case 410:
          return {
            'success': false,
            'message': 'انتهت صلاحية الجلسة، يرجى إعادة التحقق من الرمز'
          };
        case 429:
          return {
            'success': false,
            'message': 'طلبات كثيرة جداً، انتظر قليلاً ثم أعد المحاولة'
          };
        default:
          return _errorFromResponse(res, 'فشل في تغيير كلمة المرور');
      }
    } on DioException catch (e) {
      return _dioError(e);
    } catch (e) {
      return {'success': false, 'message': 'حدث خطأ غير متوقع'};
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

    // Only use hardcoded Arabic if the server returned nothing useful
    final bool hasServerMsg = serverMsg != null && serverMsg.isNotEmpty;
    String msg = hasServerMsg ? serverMsg : fallback;

    if (!hasServerMsg) {
      switch (res.statusCode) {
        case 400:
          msg = '$fallback (تحقق من تنسيق رقم الهاتف)';
          break;
        case 404:
          msg = 'لا يوجد حساب مرتبط بهذا الرقم';
          break;
        case 410:
          msg = 'انتهت صلاحية رمز التحقق، أعد المحاولة';
          break;
        case 429:
          msg = 'طلبات كثيرة جداً، انتظر قليلاً ثم أعد المحاولة';
          break;
        case 403:
          msg = 'يجب التحقق من رمز OTP أولاً';
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
        'message': 'انتهت مهلة الاتصال، تحقق من الإنترنت'
      };
    }
    if (e.type == DioExceptionType.connectionError) {
      return {'success': false, 'message': 'تعذر الاتصال بالخادم'};
    }
    return {'success': false, 'message': 'حدث خطأ في الشبكة'};
  }
}
