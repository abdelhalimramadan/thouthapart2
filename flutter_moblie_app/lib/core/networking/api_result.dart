import 'package:thotha_mobile_app/core/networking/api_error_handler.dart';

import 'api_error_model.dart';

/// Represents the result of an API operation
/// 
/// Usage:
/// ```dart
/// Future<ApiResult<User>> getUser(int id) async {
///   try {
///     final response = await apiService.getUser(id);
///     return ApiResult.success(User.fromJson(response.data));
///   } catch (e) {
///     return ApiResult.failure(ApiErrorHandler.handleError(e));
///   }
/// }
/// ```
class ApiResult<T> {
  final T? data;
  final ApiErrorModel? error;
  final bool isSuccess;

  const ApiResult._({
    this.data,
    this.error,
    required this.isSuccess,
  });

  /// Creates a successful result with data
  factory ApiResult.success(T data) {
    return ApiResult._(
      data: data,
      isSuccess: true,
    );
  }

  /// Creates a failure result with error
  factory ApiResult.failure(ApiErrorModel error) {
    return ApiResult._(
      error: error,
      isSuccess: false,
    );
  }

  /// Creates a failure result from any exception
  factory ApiResult.error(dynamic error) {
    final apiError = error is ApiErrorModel 
        ? error 
        : ApiErrorHandler.handleError(error);
    return ApiResult.failure(apiError);
  }

  /// Checks if the result is successful
  bool get isSuccessful => isSuccess;

  /// Checks if the result is a failure
  bool get isFailure => !isSuccess;

  /// Gets the data if successful, throws error if failure
  T get dataOrThrow {
    if (isSuccess && data != null) {
      return data!;
    }
    throw error ?? Exception('Unknown error');
  }

  /// Gets the data if successful, returns null if failure
  T? get dataOrNull => isSuccess ? data : null;

  /// Gets the error if failure, returns null if successful
  ApiErrorModel? get errorOrNull => isFailure ? error : null;

  /// Maps the successful data to a new type
  ApiResult<R> map<R>(R Function(T data) mapper) {
    if (isSuccess && data != null) {
      try {
        return ApiResult.success(mapper(data!));
      } catch (e) {
        return ApiResult.error(e);
      }
    }
    return ApiResult.failure(error!);
  }

  /// Maps the error to a new error
  ApiResult<T> mapError(ApiErrorModel Function(ApiErrorModel error) mapper) {
    if (isFailure && error != null) {
      return ApiResult.failure(mapper(error!));
    }
    return this;
  }

  /// Executes a function if successful, returns the same result
  ApiResult<T> onSuccess(void Function(T data) action) {
    if (isSuccess && data != null) {
      action(data!);
    }
    return this;
  }

  /// Executes a function if failure, returns the same result
  ApiResult<T> onFailure(void Function(ApiErrorModel error) action) {
    if (isFailure && error != null) {
      action(error!);
    }
    return this;
  }

  /// Executes different functions based on success or failure
  R fold<R>(
    R Function(T data) onSuccess,
    R Function(ApiErrorModel error) onFailure,
  ) {
    if (isSuccess && data != null) {
      return onSuccess(data!);
    } else if (isFailure && error != null) {
      return onFailure(error!);
    } else {
      return onFailure(ApiErrorModel.unknownError('Unknown error occurred'));
    }
  }

  /// Returns the data if successful, otherwise returns the provided fallback value
  T getOrElse(T fallback) {
    return isSuccess && data != null ? data! : fallback;
  }

  /// Returns the data if successful, otherwise executes the provided function
  T getOrElseElse(T Function() fallback) {
    return isSuccess && data != null ? data! : fallback();
  }

  /// Chains another async operation if successful
  Future<ApiResult<R>> then<R>(Future<ApiResult<R>> Function(T data) operation) async {
    if (isSuccess && data != null) {
      try {
        return await operation(data!);
      } catch (e) {
        return ApiResult.error(e);
      }
    }
    return ApiResult.failure(error!);
  }

  /// Chains another async operation regardless of success or failure
  Future<ApiResult<R>> thenAlways<R>(Future<ApiResult<R>> Function(ApiResult<T> result) operation) async {
    try {
      return await operation(this);
    } catch (e) {
      return ApiResult.error(e);
    }
  }

  /// Converts to a map representation (useful for JSON serialization)
  Map<String, dynamic> toMap() {
    return {
      'isSuccess': isSuccess,
      'data': data,
      'error': error?.toJson(),
    };
  }

  /// Creates ApiResult from a map
  factory ApiResult.fromMap(
    Map<String, dynamic> map, {
    T Function(dynamic)? dataFromJson,
  }) {
    final isSuccess = map['isSuccess'] as bool? ?? false;
    
    if (isSuccess) {
      final data = map['data'];
      final parsedData = dataFromJson != null && data != null 
          ? dataFromJson(data) 
          : data as T?;
      return ApiResult.success(parsedData as T);
    } else {
      final errorMap = map['error'] as Map<String, dynamic>?;
      final error = errorMap != null 
          ? ApiErrorModel.fromJson(errorMap) 
          : ApiErrorModel.unknownError('Unknown error');
      return ApiResult.failure(error);
    }
  }

  @override
  String toString() {
    if (isSuccess) {
      return 'ApiResult.success(data: $data)';
    } else {
      return 'ApiResult.failure(error: $error)';
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ApiResult<T> &&
        other.isSuccess == isSuccess &&
        other.data == data &&
        other.error == error;
  }

  @override
  int get hashCode => isSuccess.hashCode ^ data.hashCode ^ error.hashCode;
}

/// Extension methods for Future<ApiResult<T>>
extension FutureApiResultExtensions<T> on Future<ApiResult<T>> {
  /// Maps the successful data to a new type
  Future<ApiResult<R>> map<R>(R Function(T data) mapper) async {
    final result = await this;
    return result.map(mapper);
  }

  /// Maps the error to a new error
  Future<ApiResult<T>> mapError(ApiErrorModel Function(ApiErrorModel error) mapper) async {
    final result = await this;
    return result.mapError(mapper);
  }

  /// Executes a function if successful
  Future<ApiResult<T>> onSuccess(void Function(T data) action) async {
    final result = await this;
    return result.onSuccess(action);
  }

  /// Executes a function if failure
  Future<ApiResult<T>> onFailure(void Function(ApiErrorModel error) action) async {
    final result = await this;
    return result.onFailure(action);
  }

  /// Executes different functions based on success or failure
  Future<R> fold<R>(
    R Function(T data) onSuccess,
    R Function(ApiErrorModel error) onFailure,
  ) async {
    final result = await this;
    return result.fold(onSuccess, onFailure);
  }
}