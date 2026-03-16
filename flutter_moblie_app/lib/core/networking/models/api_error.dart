class ApiError {
  final String messageAr;
  final String? messageEn;
  final int? statusCode;
  final dynamic details;

  const ApiError({
    required this.messageAr,
    this.messageEn,
    this.statusCode,
    this.details,
  });

  factory ApiError.fromResponse(dynamic responseData, {int? statusCode}) {
    if (responseData is Map) {
      final ar = responseData['messageAr']?.toString();
      final en = responseData['messageEn']?.toString() ??
          responseData['message']?.toString() ??
          responseData['error']?.toString();

      return ApiError(
        messageAr: (ar != null && ar.isNotEmpty) ? ar : (en ?? 'Request failed'),
        messageEn: en,
        statusCode: statusCode,
        details: responseData,
      );
    }

    final text = responseData?.toString();
    return ApiError(
      messageAr: (text != null && text.isNotEmpty) ? text : 'Request failed',
      statusCode: statusCode,
      details: responseData,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'messageAr': messageAr,
      if (messageEn != null) 'messageEn': messageEn,
      if (statusCode != null) 'statusCode': statusCode,
      if (details != null) 'details': details,
    };
  }
}

