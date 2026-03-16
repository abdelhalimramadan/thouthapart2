import 'package:thotha_mobile_app/core/networking/models/api_error.dart';

class ApiResult<T> {
  final bool success;
  final T? data;
  final ApiError? error;

  const ApiResult._({
    required this.success,
    this.data,
    this.error,
  });

  factory ApiResult.success(T data) {
    return ApiResult._(success: true, data: data);
  }

  factory ApiResult.failure(ApiError error) {
    return ApiResult._(success: false, error: error);
  }

  Map<String, dynamic> toJson() {
    if (success) {
      return {
        'success': true,
        'data': data,
      };
    }

    return {
      'success': false,
      'error': error?.messageAr ?? 'Request failed',
      if (error?.statusCode != null) 'statusCode': error!.statusCode,
      if (error?.messageEn != null) 'messageEn': error!.messageEn,
      if (error?.details != null) 'errorDetails': error!.details,
    };
  }
}

