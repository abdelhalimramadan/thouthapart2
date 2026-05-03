import 'package:dio/dio.dart';
import 'package:thoutha_mobile_app/core/helpers/phone_helper.dart';
import 'package:thoutha_mobile_app/core/networking/api_constants.dart';
import 'package:thoutha_mobile_app/core/networking/dio_factory.dart';
import 'package:thoutha_mobile_app/core/networking/connectivity_service.dart';
import 'dart:async';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;

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
  Future<Map<String, dynamic>> sendOtp(String phoneNumber,
      {int retryCount = 0}) async {
    try {
      // Ensure service is initialized
      await initialize();

      // Check connectivity first
      if (!_connectivityService.isConnected) {
        final hasConnection = await _connectivityService.waitForConnectivity();
        if (!hasConnection) {
          return {
            'success': false,
            'error':
                'core.no_internet_connection_please'.tr(),
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

      // Ensure phone number doesn't start with + for the API
      final String formattedPhone =
          PhoneHelper.normalizeEgyptPhone(phoneNumber);

      print('Sending OTP to: $formattedPhone');

      final response = await _dio.post(
        '${ApiConstants.otpBaseUrl}${ApiConstants.sendOtp}',
        data: {
          'phone_number': formattedPhone,
          'otp': '',
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
          'message': response.data['message'] ?? 'core.verification_code_sent_successfully'.tr(),
          'retryable': false,
        };
      } else {
        String errorMessage = 'core.failed_to_send_verification'.tr();
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
        print(
            'Retrying OTP send due to network error... Attempt ${retryCount + 1}/$_maxRetries');
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
        'error': 'core.an_unexpected_error_occurred'.tr(),
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
  Future<Map<String, dynamic>> verifyOtp(String phoneNumber, String otp,
      {int retryCount = 0}) async {
    try {
      // Ensure service is initialized
      await initialize();

      // Check connectivity first
      if (!_connectivityService.isConnected) {
        final hasConnection = await _connectivityService.waitForConnectivity();
        if (!hasConnection) {
          return {
            'success': false,
            'error':
                'core.no_internet_connection_please'.tr(),
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

      // Ensure phone number doesn't start with + for the API
      final String formattedPhone =
          PhoneHelper.normalizeEgyptPhone(phoneNumber);

      print('Verifying OTP: $otp for phone: $formattedPhone');

      final response = await _dio.post(
        '${ApiConstants.otpBaseUrl}${ApiConstants.verifyOtp}',
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
          'message': response.data['message'] ?? 'core.verified_successfully'.tr(),
          'data': response.data,
          'retryable': false,
        };
      } else {
        String errorMessage = 'core.the_verification_code_is'.tr();
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
          errorMessage = 'core.the_verification_code_is'.tr();
          retryable = false;
        } else if (response.statusCode == 404) {
          errorMessage = 'core.verification_code_not_found'.tr();
          retryable = false;
        } else if (response.statusCode == 410 || response.statusCode == 408) {
          errorMessage = 'core.the_verification_code_has'.tr();
          retryable = false;
        }

        // Retry logic for server errors
        if (retryable && retryCount < _maxRetries) {
          print(
              'Retrying OTP verify... Attempt ${retryCount + 1}/$_maxRetries');
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
        print(
            'Retrying OTP verify due to network error... Attempt ${retryCount + 1}/$_maxRetries');
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
        'error': 'core.an_unexpected_error_occurred'.tr(),
        'retryable': false,
      };
    }
  }

  /// Validate phone number format
  Map<String, dynamic> _validatePhoneNumber(String phoneNumber) {
    if (phoneNumber.isEmpty) {
      return {
        'valid': false,
        'error': 'core.phone_number_required'.tr(),
      };
    }

    String formattedPhone = phoneNumber.trim();
    // For validation, we can handle both cases, but let's normalize internally
    if (formattedPhone.startsWith('+')) {
      formattedPhone = formattedPhone.substring(1);
    }

    // Egyptian phone number validation (normalized without +)
    if (formattedPhone.startsWith('20')) {
      final phoneRegex = RegExp(r'^20(1[0-6]\d{8})$');
      if (!phoneRegex.hasMatch(formattedPhone)) {
        return {
          'valid': false,
          'error': 'core.the_egyptian_phone_number'.tr(),
        };
      }
    } else {
      // International phone validation (basic, normalized without +)
      final phoneRegex = RegExp(r'^\d{10,15}$');
      if (!phoneRegex.hasMatch(formattedPhone)) {
        return {
          'valid': false,
          'error': 'core.invalid_phone_number_it'.tr(),
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
        'error': 'core.phone_number_required'.tr(),
      };
    }

    if (otp.isEmpty) {
      return {
        'valid': false,
        'error': 'core.verification_code_required'.tr(),
      };
    }

    if (otp.length != 6) {
      return {
        'valid': false,
        'error': 'core.verification_code_must_be'.tr(),
      };
    }

    if (!RegExp(r'^\d{6}$').hasMatch(otp)) {
      return {
        'valid': false,
        'error': 'core.the_verification_code_must'.tr(),
      };
    }

    return {'valid': true};
  }

  /// Calculate exponential backoff delay
  Duration _calculateBackoff(int retryCount) {
    return Duration(
        milliseconds: _baseDelay.inMilliseconds * (1 << retryCount));
  }

  /// Check if error is retryable
  bool _isRetryableError(DioException e) {
    return e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError ||
        (e.response?.statusCode != null && e.response!.statusCode! >= 500);
  }

  String _handleDioError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return 'core.the_connection_timed_out_1'.tr();
    } else if (e.type == DioExceptionType.connectionError) {
      return 'core.failed_to_connect_to'.tr();
    } else if (e.response?.statusCode == 400) {
      return e.response?.data?['message'] ?? 'core.incorrect_data'.tr();
    } else if (e.response?.statusCode == 401) {
      return 'core.unauthorized'.tr();
    } else if (e.response?.statusCode == 404) {
      return 'core.the_service_is_not'.tr();
    } else if (e.response?.statusCode == 500) {
      return 'core.server_error'.tr();
    }
    return 'core.an_unexpected_error_occurred'.tr();
  }
}
