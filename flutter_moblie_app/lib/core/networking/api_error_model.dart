import 'package:equatable/equatable.dart';
import 'package:dio/dio.dart';

enum ErrorType {
  network,
  server,
  validation,
  authentication,
  authorization,
  notFound,
  timeout,
  unknown,
}

class ApiErrorModel extends Equatable {
  final String message;
  final String? code;
  final ErrorType type;
  final int? statusCode;
  final dynamic details;

  const ApiErrorModel({
    required this.message,
    this.code,
    required this.type,
    this.statusCode,
    this.details,
  });

  factory ApiErrorModel.fromDioException(DioException exception) {
    String message = 'حدث خطأ غير متوقع';
    String? code;
    ErrorType type = ErrorType.unknown;
    int? statusCode = exception.response?.statusCode;

    switch (exception.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        message = 'انتهت مهلة الاتصال. تحقق من اتصال الإنترنت وحاول مرة أخرى';
        type = ErrorType.timeout;
        break;
        
      case DioExceptionType.connectionError:
        message = 'تعذر الاتصال بالخادم. تحقق من اتصال الإنترنت';
        type = ErrorType.network;
        break;
        
      case DioExceptionType.badResponse:
        statusCode = exception.response?.statusCode;
        final responseData = exception.response?.data;
        
        // Extract error message from response
        if (responseData is Map<String, dynamic>) {
          message = responseData['messageAr'] ??
                     responseData['messageEn'] ??
                     responseData['message'] ??
                     responseData['error'] ??
                     'حدث خطأ في الخادم';
          code = responseData['code']?.toString();
        } else if (responseData != null) {
          message = responseData.toString();
        }

        // Determine error type based on status code
        if (statusCode == 400) {
          type = ErrorType.validation;
          if (message == 'حدث خطأ غير متوقع') {
            message = 'البيانات المدخلة غير صحيحة';
          }
        } else if (statusCode == 401) {
          type = ErrorType.authentication;
          if (message == 'حدث خطأ غير متوقع') {
            message = 'غير مصرح: يرجى تسجيل الدخول مجدداً';
          }
        } else if (statusCode == 403) {
          type = ErrorType.authorization;
          if (message == 'حدث خطأ غير متوقع') {
            message = 'ممنوع الوصول: ليس لديك صلاحية للوصول إلى هذه المعلومات';
          }
        } else if (statusCode == 404) {
          type = ErrorType.notFound;
          if (message == 'حدث خطأ غير متوقع') {
            message = 'الصفحة المطلوبة غير موجودة';
          }
        } else if (statusCode != null && statusCode >= 500) {
          type = ErrorType.server;
          if (message == 'حدث خطأ غير متوقع') {
            message = 'خطأ في الخادم: يرجى المحاولة مرة أخرى لاحقاً';
          }
        } else {
          type = ErrorType.unknown;
        }
        break;
        
      case DioExceptionType.cancel:
        message = 'تم إلغاء الطلب';
        type = ErrorType.unknown;
        break;
        
      case DioExceptionType.unknown:
        if (exception.error?.toString().contains('SocketException') == true) {
          message = 'لا يوجد اتصال بالإنترنت';
          type = ErrorType.network;
        } else {
          message = 'حدث خطأ غير متوقع: ${exception.message}';
          type = ErrorType.unknown;
        }
        break;
        
      default:
        message = 'حدث خطأ غير متوقع: ${exception.message}';
        type = ErrorType.unknown;
    }

    return ApiErrorModel(
      message: message,
      code: code,
      type: type,
      statusCode: statusCode,
      details: exception.response?.data,
    );
  }

  factory ApiErrorModel.fromException(Exception exception) {
    return ApiErrorModel(
      message: exception.toString(),
      type: ErrorType.unknown,
    );
  }

  factory ApiErrorModel.networkError(String message) {
    return ApiErrorModel(
      message: message,
      type: ErrorType.network,
    );
  }

  factory ApiErrorModel.serverError(String message, {int? statusCode}) {
    return ApiErrorModel(
      message: message,
      type: ErrorType.server,
      statusCode: statusCode,
    );
  }

  factory ApiErrorModel.validationError(String message) {
    return ApiErrorModel(
      message: message,
      type: ErrorType.validation,
    );
  }

  factory ApiErrorModel.authenticationError(String message) {
    return ApiErrorModel(
      message: message,
      type: ErrorType.authentication,
    );
  }

  factory ApiErrorModel.authorizationError(String message) {
    return ApiErrorModel(
      message: message,
      type: ErrorType.authorization,
    );
  }

  factory ApiErrorModel.notFoundError(String message) {
    return ApiErrorModel(
      message: message,
      type: ErrorType.notFound,
    );
  }

  factory ApiErrorModel.timeoutError(String message) {
    return ApiErrorModel(
      message: message,
      type: ErrorType.timeout,
    );
  }

  factory ApiErrorModel.unknownError(String message) {
    return ApiErrorModel(
      message: message,
      type: ErrorType.unknown,
    );
  }

  bool get isNetworkError => type == ErrorType.network;
  bool get isServerError => type == ErrorType.server;
  bool get isValidationError => type == ErrorType.validation;
  bool get isAuthenticationError => type == ErrorType.authentication;
  bool get isAuthorizationError => type == ErrorType.authorization;
  bool get isNotFoundError => type == ErrorType.notFound;
  bool get isTimeoutError => type == ErrorType.timeout;
  bool get isUnknownError => type == ErrorType.unknown;

  @override
  List<Object?> get props => [message, code, type, statusCode, details];

  @override
  String toString() {
    return 'ApiErrorModel(message: $message, code: $code, type: $type, statusCode: $statusCode)';
  }

  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'code': code,
      'type': type.name,
      'statusCode': statusCode,
      'details': details,
    };
  }

  factory ApiErrorModel.fromJson(Map<String, dynamic> json) {
    return ApiErrorModel(
      message: json['message'] ?? '',
      code: json['code'],
      type: ErrorType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => ErrorType.unknown,
      ),
      statusCode: json['statusCode'],
      details: json['details'],
    );
  }

  ApiErrorModel copyWith({
    String? message,
    String? code,
    ErrorType? type,
    int? statusCode,
    dynamic details,
  }) {
    return ApiErrorModel(
      message: message ?? this.message,
      code: code ?? this.code,
      type: type ?? this.type,
      statusCode: statusCode ?? this.statusCode,
      details: details ?? this.details,
    );
  }
}