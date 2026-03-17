import 'package:dio/dio.dart';
import 'api_error_model.dart';

class ApiErrorHandler {
  /// Handles Dio exceptions and converts them to ApiErrorModel
  static ApiErrorModel handle(DioException exception) {
    return ApiErrorModel.fromDioException(exception);
  }

  /// Handles any exception and converts it to ApiErrorModel
  static ApiErrorModel handleException(Exception exception) {
    if (exception is DioException) {
      return handle(exception);
    }
    return ApiErrorModel.fromException(exception);
  }

  /// Handles generic dynamic errors
  static ApiErrorModel handleError(dynamic error) {
    if (error is DioException) {
      return handle(error);
    } else if (error is Exception) {
      return handleException(error);
    } else if (error is String) {
      return ApiErrorModel.unknownError(error);
    } else {
      return ApiErrorModel.unknownError(error.toString());
    }
  }

  /// Extracts user-friendly message from error response
  static String extractMessage(dynamic responseData, {String defaultMessage = 'حدث خطأ غير متوقع'}) {
    if (responseData is Map<String, dynamic>) {
      return responseData['messageAr'] ??
             responseData['messageEn'] ??
             responseData['message'] ??
             responseData['error'] ??
             responseData['detail'] ??
             defaultMessage;
    } else if (responseData != null) {
      return responseData.toString();
    }
    return defaultMessage;
  }

  /// Extracts error code from response
  static String? extractCode(dynamic responseData) {
    if (responseData is Map<String, dynamic>) {
      return responseData['code']?.toString() ??
             responseData['error_code']?.toString() ??
             responseData['errorCode']?.toString();
    }
    return null;
  }

  /// Determines if error should trigger a logout (for auth errors)
  static bool shouldLogout(ApiErrorModel error) {
    return error.isAuthenticationError || 
           (error.statusCode == 401) ||
           (error.code?.toLowerCase().contains('unauthorized') == true) ||
           (error.code?.toLowerCase().contains('token') == true);
  }

  /// Determines if error should show a retry button
  static bool shouldShowRetry(ApiErrorModel error) {
    return error.isNetworkError || 
           error.isTimeoutError || 
           error.isServerError ||
           (error.statusCode != null && error.statusCode! >= 500);
  }

  /// Determines if error is critical and should be reported
  static bool isCriticalError(ApiErrorModel error) {
    return error.isServerError || 
           error.statusCode == null ||
           (error.statusCode != null && error.statusCode! >= 500);
  }

  /// Gets appropriate action text based on error type
  static String getActionText(ApiErrorModel error) {
    if (error.isNetworkError) {
      return 'تحقق من الاتصال بالإنترنت';
    } else if (error.isTimeoutError) {
      return 'حاول مرة أخرى';
    } else if (error.isAuthenticationError) {
      return 'سجل الدخول مجدداً';
    } else if (error.isValidationError) {
      return 'تحقق من البيانات المدخلة';
    } else if (error.isNotFoundError) {
      return 'العودة للرئيسية';
    } else if (error.isServerError) {
      return 'حاول لاحقاً';
    } else {
      return 'حاول مرة أخرى';
    }
  }

  /// Gets appropriate icon name based on error type (for UI)
  static String getIconName(ApiErrorModel error) {
    if (error.isNetworkError) {
      return 'wifi_off';
    } else if (error.isTimeoutError) {
      return 'timer_off';
    } else if (error.isAuthenticationError) {
      return 'lock';
    } else if (error.isValidationError) {
      return 'error_outline';
    } else if (error.isNotFoundError) {
      return 'search_off';
    } else if (error.isServerError) {
      return 'cloud_off';
    } else {
      return 'error';
    }
  }

  /// Logs error details for debugging
  static void logError(ApiErrorModel error, {String? endpoint, Map<String, dynamic>? additionalInfo}) {
    final logMessage = StringBuffer();
    logMessage.writeln('=== API Error ===');
    logMessage.writeln('Message: ${error.message}');
    logMessage.writeln('Type: ${error.type.name}');
    logMessage.writeln('Code: ${error.code}');
    logMessage.writeln('Status Code: ${error.statusCode}');
    
    if (endpoint != null) {
      logMessage.writeln('Endpoint: $endpoint');
    }
    
    if (error.details != null) {
      logMessage.writeln('Details: ${error.details}');
    }
    
    if (additionalInfo != null) {
      logMessage.writeln('Additional Info: $additionalInfo');
    }
    
    logMessage.writeln('Timestamp: ${DateTime.now().toIso8601String()}');
    logMessage.writeln('================');
    
    // In debug mode, print to console
    assert(() {
      print(logMessage.toString());
      return true;
    }());
    
    // TODO: In production, send to logging service (Crashlytics, Sentry, etc.)
  }

  /// Creates a standardized error response map
  static Map<String, dynamic> createErrorResponse(ApiErrorModel error) {
    return {
      'success': false,
      'error': {
        'message': error.message,
        'code': error.code,
        'type': error.type.name,
        'statusCode': error.statusCode,
        'details': error.details,
        'shouldRetry': shouldShowRetry(error),
        'shouldLogout': shouldLogout(error),
        'actionText': getActionText(error),
        'iconName': getIconName(error),
      }
    };
  }

  /// Parses error response from server response
  static ApiErrorModel parseErrorResponse(int? statusCode, dynamic responseData) {
    final message = extractMessage(responseData);
    final code = extractCode(responseData);
    
    ErrorType type = ErrorType.unknown;
    if (statusCode == 400) {
      type = ErrorType.validation;
    } else if (statusCode == 401) {
      type = ErrorType.authentication;
    } else if (statusCode == 403) {
      type = ErrorType.authorization;
    } else if (statusCode == 404) {
      type = ErrorType.notFound;
    } else if (statusCode != null && statusCode >= 500) {
      type = ErrorType.server;
    }
    
    return ApiErrorModel(
      message: message,
      code: code,
      type: type,
      statusCode: statusCode,
      details: responseData,
    );
  }
}