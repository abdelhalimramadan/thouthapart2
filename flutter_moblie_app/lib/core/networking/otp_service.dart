import 'package:dio/dio.dart';
import 'package:thotha_mobile_app/core/networking/api_constants.dart';
import 'package:thotha_mobile_app/core/networking/dio_factory.dart';
import 'package:thotha_mobile_app/core/networking/connectivity_service.dart';
import 'dart:async';

class OtpService {
  final Dio _dio = DioFactory.getDio();
  final ConnectivityService _connectivityService = ConnectivityService();
  static const int _maxRetries = 3;
  static const Duration _baseDelay = Duration(seconds: 1);
  static const Duration _requestTimeout = Duration(seconds: 30);
  bool _isInitialized = false;

  /// Initialize the OTP service
  Future<void> initialize() async {
    if (!_isInitialized) {
      await _connectivityService.initialize();
      _isInitialized = true;
    }
  }

  /// Send OTP to the provided phone number with retry mechanism
  /// 
  /// [phoneNumber] should be in international format: +20XXXXXXXXXX
  /// [retryCount] current retry attempt (used internally)
  /// 
  /// Returns a Map with:
  /// - 'success': true/false
  /// - 'message': success/error message
  /// - 'retryable': true if request can be retried
  Future<Map<String, dynamic>> sendOtp(String phoneNumber, {int retryCount = 0}) async {
    try {
      // Ensure service is initialized
      await initialize();
      
      // Check connectivity first
      if (!_connectivityService.isConnected) {
        final hasConnection = await _connectivityService.waitForConnectivity();
        if (!hasConnection) {
          return {
            'success': false,
            'error': 'لا يوجد اتصال بالإنترنت. يرجى التحقق من الاتصال والمحاولة مرة أخرى.',
            'retryable': true,
          };
        }
      }

      // Validate phone number format before sending
      final validationResult = _validatePhoneNumber(phoneNumber);
      if (!validationResult['valid']) {
        return {
          'success': false,
          'error': validationResult['error'],
          'retryable': false,
        };
      }

      // Ensure phone number starts with +
      String formattedPhone = phoneNumber.trim();
      if (!formattedPhone.startsWith('+')) {
        formattedPhone = '+$formattedPhone';
      }

      print('Sending OTP to: $formattedPhone');

      final response = await _dio.post(
        '${ApiConstants.baseUrl}${ApiConstants.sendOtp}',
        data: {
          'phone_number': formattedPhone,
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          validateStatus: (status) => status! < 500,
          sendTimeout: _requestTimeout,
          receiveTimeout: _requestTimeout,
        ),
      );

      print('Send OTP Response Status: ${response.statusCode}');
      print('Send OTP Response Data: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': response.data['message'] ?? 'تم إرسال رمز التحقق بنجاح',
          'retryable': false,
        };
      } else {
        String errorMessage = 'فشل إرسال رمز التحقق';
        bool retryable = true;

        if (response.data != null) {
          if (response.data is Map) {
            errorMessage = response.data['message'] ??
                response.data['error'] ??
                errorMessage;
          } else if (response.data is String) {
            errorMessage = response.data;
          }
        }

        // Determine if error is retryable
        if (response.statusCode == 400) {
          retryable = false; // Bad request - don't retry
        } else if (response.statusCode == 429) {
          retryable = true; // Rate limit - can retry with delay
        }

        // Retry logic
        if (retryable && retryCount < _maxRetries) {
          print('Retrying OTP send... Attempt ${retryCount + 1}/$_maxRetries');
          await Future.delayed(_calculateBackoff(retryCount));
          return sendOtp(phoneNumber, retryCount: retryCount + 1);
        }

        return {
          'success': false,
          'error': errorMessage,
          'retryable': retryable && retryCount < _maxRetries,
        };
      }
    } on DioException catch (e) {
      print('DioException in sendOtp: ${e.message}');
      
      // Retry logic for network errors
      if (retryCount < _maxRetries && _isRetryableError(e)) {
        print('Retrying OTP send due to network error... Attempt ${retryCount + 1}/$_maxRetries');
        await Future.delayed(_calculateBackoff(retryCount));
        return sendOtp(phoneNumber, retryCount: retryCount + 1);
      }
      
      return {
        'success': false,
        'error': _handleDioError(e),
        'retryable': false,
      };
    } catch (e) {
      print('Exception in sendOtp: ${e.toString()}');
      return {
        'success': false,
        'error': 'حدث خطأ غير متوقع',
        'retryable': false,
      };
    }
  }

  /// Verify the OTP code with retry mechanism
  ///
  /// [phoneNumber] should be in international format: +20XXXXXXXXXX
  /// [otp] is the 6-digit code received via SMS
  /// [retryCount] current retry attempt (used internally)
  ///
  /// Returns a Map with:
  /// - 'success': true/false
  /// - 'message': success/error message
  /// - 'retryable': true if request can be retried
  Future<Map<String, dynamic>> verifyOtp(String phoneNumber, String otp, {int retryCount = 0}) async {
    try {
      // Ensure service is initialized
      await initialize();
      
      // Check connectivity first
      if (!_connectivityService.isConnected) {
        final hasConnection = await _connectivityService.waitForConnectivity();
        if (!hasConnection) {
          return {
            'success': false,
            'error': 'لا يوجد اتصال بالإنترنت. يرجى التحقق من الاتصال والمحاولة مرة أخرى.',
            'retryable': true,
          };
        }
      }

      // Validate inputs
      final validationResult = _validateOtpInputs(phoneNumber, otp);
      if (!validationResult['valid']) {
        return {
          'success': false,
          'error': validationResult['error'],
          'retryable': false,
        };
      }

      // Ensure phone number starts with +
      String formattedPhone = phoneNumber.trim();
      if (!formattedPhone.startsWith('+')) {
        formattedPhone = '+$formattedPhone';
      }

      print('Verifying OTP: $otp for phone: $formattedPhone');

      final response = await _dio.post(
        '${ApiConstants.baseUrl}${ApiConstants.verifyOtp}',
        data: {
          'phone_number': formattedPhone,
          'otp': otp,
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          validateStatus: (status) => status! < 500,
          sendTimeout: _requestTimeout,
          receiveTimeout: _requestTimeout,
        ),
      );

      print('Verify OTP Response Status: ${response.statusCode}');
      print('Verify OTP Response Data: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': response.data['message'] ?? 'تم التحقق بنجاح',
          'data': response.data,
          'retryable': false,
        };
      } else {
        String errorMessage = 'رمز التحقق غير صحيح';
        bool retryable = false;

        if (response.data != null) {
          if (response.data is Map) {
            errorMessage = response.data['message'] ??
                response.data['error'] ??
                errorMessage;
          } else if (response.data is String) {
            errorMessage = response.data;
          }
        }

        // More specific error messages
        if (response.statusCode == 400) {
          errorMessage = 'رمز التحقق غير صحيح';
          retryable = false;
        } else if (response.statusCode == 404) {
          errorMessage = 'لم يتم العثور على رمز التحقق';
          retryable = false;
        } else if (response.statusCode == 410 || response.statusCode == 408) {
          errorMessage = 'انتهت صلاحية رمز التحقق. يرجى طلب رمز جديد';
          retryable = false;
        }

        // Retry logic for server errors
        if (retryable && retryCount < _maxRetries) {
          print('Retrying OTP verify... Attempt ${retryCount + 1}/$_maxRetries');
          await Future.delayed(_calculateBackoff(retryCount));
          return verifyOtp(phoneNumber, otp, retryCount: retryCount + 1);
        }

        return {
          'success': false,
          'error': errorMessage,
          'retryable': retryable && retryCount < _maxRetries,
        };
      }
    } on DioException catch (e) {
      print('DioException in verifyOtp: ${e.message}');
      
      // Retry logic for network errors
      if (retryCount < _maxRetries && _isRetryableError(e)) {
        print('Retrying OTP verify due to network error... Attempt ${retryCount + 1}/$_maxRetries');
        await Future.delayed(_calculateBackoff(retryCount));
        return verifyOtp(phoneNumber, otp, retryCount: retryCount + 1);
      }
      
      return {
        'success': false,
        'error': _handleDioError(e),
        'retryable': false,
      };
    } catch (e) {
      print('Exception in verifyOtp: ${e.toString()}');
      return {
        'success': false,
        'error': 'حدث خطأ غير متوقع',
        'retryable': false,
      };
    }
  }

  /// Validate phone number format
  Map<String, dynamic> _validatePhoneNumber(String phoneNumber) {
    if (phoneNumber.isEmpty) {
      return {
        'valid': false,
        'error': 'رقم الهاتف مطلوب',
      };
    }

    String formattedPhone = phoneNumber.trim();
    if (!formattedPhone.startsWith('+')) {
      formattedPhone = '+$formattedPhone';
    }

    // Egyptian phone number validation
    if (formattedPhone.startsWith('+20')) {
      final phoneRegex = RegExp(r'^\+20(1[0-2]\d{8})$');
      if (!phoneRegex.hasMatch(formattedPhone)) {
        return {
          'valid': false,
          'error': 'رقم الهاتف المصري غير صحيح. يجب أن يكون بالصيغة: +20XXXXXXXXXX',
        };
      }
    } else {
      // International phone validation (basic)
      final phoneRegex = RegExp(r'^\+\d{10,15}$');
      if (!phoneRegex.hasMatch(formattedPhone)) {
        return {
          'valid': false,
          'error': 'رقم الهاتف غير صحيح. يجب أن يبدأ بـ + ويحتوي على 10-15 رقم',
        };
      }
    }

    return {'valid': true};
  }

  /// Validate OTP inputs
  Map<String, dynamic> _validateOtpInputs(String phoneNumber, String otp) {
    if (phoneNumber.isEmpty) {
      return {
        'valid': false,
        'error': 'رقم الهاتف مطلوب',
      };
    }

    if (otp.isEmpty) {
      return {
        'valid': false,
        'error': 'رمز التحقق مطلوب',
      };
    }

    if (otp.length != 6) {
      return {
        'valid': false,
        'error': 'رمز التحقق يجب أن يكون 6 أرقام',
      };
    }

    if (!RegExp(r'^\d{6}$').hasMatch(otp)) {
      return {
        'valid': false,
        'error': 'رمز التحقق يجب أن يحتوي على أرقام فقط',
      };
    }

    return {'valid': true};
  }

  /// Calculate exponential backoff delay
  Duration _calculateBackoff(int retryCount) {
    return Duration(milliseconds: _baseDelay.inMilliseconds * (1 << retryCount));
  }

  /// Check if error is retryable
  bool _isRetryableError(DioException e) {
    return e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError ||
        (e.response?.statusCode != null && 
         e.response!.statusCode! >= 500);
  }

  String _handleDioError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return 'انتهت مهلة الاتصال. تحقق من الإنترنت.';
    } else if (e.type == DioExceptionType.connectionError) {
      return 'فشل الاتصال بالخادم. تحقق من الإنترنت.';
    } else if (e.response?.statusCode == 400) {
      return e.response?.data?['message'] ?? 'بيانات غير صحيحة';
    } else if (e.response?.statusCode == 401) {
      return 'غير مصرح';
    } else if (e.response?.statusCode == 404) {
      return 'الخدمة غير متوفرة';
    } else if (e.response?.statusCode == 500) {
      return 'خطأ في الخادم';
    }
    return 'حدث خطأ غير متوقع';
  }
}
