import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:thotha_mobile_app/core/networking/api_constants.dart';
import 'package:thotha_mobile_app/core/networking/dio_factory.dart';
import 'package:thotha_mobile_app/core/networking/models/category_model.dart';
import 'package:thotha_mobile_app/core/networking/models/city_model.dart';
import 'package:thotha_mobile_app/core/networking/models/university_model.dart';
import 'package:thotha_mobile_app/features/home_screen/data/models/doctor_model.dart';
import 'package:thotha_mobile_app/features/home_screen/data/models/case_request_model.dart';
import 'package:thotha_mobile_app/features/home_screen/doctor_home/data/models/doctor_profile_model.dart';

/// Centralised API service.
///
/// All paths are *relative* — DioFactory already sets `baseUrl` to
/// `https://thoutha.page`, so we never concatenate `baseUrl` here.
class ApiService {
  // Authenticated Dio — shared singleton with Bearer token interceptor
  late final Dio _dio = DioFactory.getDio();

  // Public Dio — no auth, used for open reference-data endpoints
  Dio get _public => Dio(BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: const {
          'Accept': 'application/json',
          'Content-Type': 'application/json'
        },
      ));

  // ── Helpers ──────────────────────────────────────────────────────────────

  /// Wraps a successful list response.
  Map<String, dynamic> _okList(List items) => {'success': true, 'data': items};

  /// Wraps a successful map/object response.
  Map<String, dynamic> _okData(dynamic data) => {'success': true, 'data': data};

  /// Wraps a failure.
  Map<String, dynamic> _fail(String msg, {int? code}) =>
      {'success': false, 'error': msg, if (code != null) 'statusCode': code};

  /// Converts Dio errors to user-friendly Arabic strings.
  String _dioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
        return 'انتهت مهلة الاتصال. تحقق من الإنترنت';
      case DioExceptionType.connectionError:
        return 'تعذر الاتصال بالخادم. تحقق من الإنترنت';
      case DioExceptionType.badResponse:
        final code = e.response?.statusCode;
        final serverMsg = e.response?.data is Map
            ? (e.response!.data['messageAr'] ??
                e.response!.data['messageEn'] ??
                e.response!.data['message'] ??
                e.response!.data['error'] ??
                '')
            : e.response?.data?.toString() ?? '';
        if (serverMsg.toString().contains('No static resource found')) {
          return 'المسار غير صحيح على الخادم. يرجى المحاولة مرة أخرى';
        }
        if (code == 401) return 'غير مصرح: يرجى تسجيل الدخول مجدداً (401)';
        if (code == 403) return 'ممنوع الوصول (403)';
        if (code == 404) return 'الرابط غير موجود (404)';
        if (code != null && code >= 500) return 'خطأ في الخادم ($code)';
        return 'خطأ HTTP $code${serverMsg.isNotEmpty ? ": $serverMsg" : ""}';
      default:
        return 'خطأ غير متوقع: ${e.message ?? e.type.name}';
    }
  }

  // ── Doctors (public) ─────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getDoctorsByCity(int cityId) async {
    try {
      final res = await _public.get(
        ApiConstants.getDoctorsByCities,
        queryParameters: {'cityId': cityId},
      );
      if (res.statusCode == 200) {
        return _okList(
            (res.data as List).map((j) => DoctorModel.fromJson(j)).toList());
      }
      return _fail('فشل في تحميل الأطباء', code: res.statusCode);
    } on DioException catch (e) {
      return _fail(_dioError(e), code: e.response?.statusCode);
    } catch (_) {
      return _fail('حدث خطأ غير متوقع');
    }
  }

  Future<Map<String, dynamic>> getDoctorsByCategory(int categoryId) async {
    try {
      final res = await _public.get(
        ApiConstants.getDoctorsByCategories,
        queryParameters: {'categoryId': categoryId},
      );
      if (res.statusCode == 200) {
        return _okList(
            (res.data as List).map((j) => DoctorModel.fromJson(j)).toList());
      }
      return _fail('فشل في تحميل الأطباء', code: res.statusCode);
    } on DioException catch (e) {
      return _fail(_dioError(e), code: e.response?.statusCode);
    } catch (_) {
      return _fail('حدث خطأ غير متوقع');
    }
  }

  // ── Reference data (public) ──────────────────────────────────────────────

  Future<Map<String, dynamic>> getCategories() async {
    try {
      final res = await _public.get(ApiConstants.getCategories);
      if (res.statusCode == 200) {
        return _okList(
            (res.data as List).map((j) => CategoryModel.fromJson(j)).toList());
      }
      return _fail('فشل في تحميل التخصصات', code: res.statusCode);
    } on DioException catch (e) {
      return _fail(_dioError(e));
    } catch (_) {
      return _fail('حدث خطأ غير متوقع');
    }
  }

  Future<Map<String, dynamic>> getCities() async {
    try {
      final res = await _public.get(ApiConstants.getCities);
      if (res.statusCode == 200) {
        return _okList(
            (res.data as List).map((j) => CityModel.fromJson(j)).toList());
      }
      return _fail('فشل في تحميل المدن', code: res.statusCode);
    } on DioException catch (e) {
      return _fail(_dioError(e));
    } catch (_) {
      return _fail('حدث خطأ غير متوقع');
    }
  }

  Future<Map<String, dynamic>> getUniversities() async {
    try {
      final res = await _public.get(ApiConstants.getUniversities);
      if (res.statusCode == 200) {
        return _okList((res.data as List)
            .map((j) => UniversityModel.fromJson(j))
            .toList());
      }
      return _fail('فشل في تحميل الجامعات', code: res.statusCode);
    } on DioException catch (e) {
      return _fail(_dioError(e));
    } catch (_) {
      return _fail('حدث خطأ غير متوقع');
    }
  }

  // ── Case Requests ────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getCaseRequestsByCategory(int categoryId) async {
    try {
      print('=== getCaseRequestsByCategory ===');
      print('categoryId: $categoryId');

      final res = await _public.get(
        ApiConstants.getCaseRequestsByCategories,
        queryParameters: {'categoryId': categoryId},
      );

      print('statusCode: ${res.statusCode}');
      print('responseType: ${res.data?.runtimeType}');
      print('responseData: ${res.data}');

      if (res.statusCode == 200) {
        final data = res.data;
        // Support both plain List and Map with data/content/items key
        final List? raw = data is List
            ? data
            : (data is Map
                ? (data['data'] ??
                    data['content'] ??
                    data['items'] ??
                    data['requests']) as List?
                : null);
        if (raw != null) {
          final List<CaseRequestModel> parsed = [];
          for (final j in raw) {
            try {
              final map = Map<String, dynamic>.from(j as Map);
              parsed.add(CaseRequestModel.fromJson(map));
            } catch (e) {
              print('WARNING: failed to parse case request item: $e\nitem: $j');
            }
          }
          return _okList(parsed);
        }
        print('ERROR: unexpected response format: $data');
        return _fail('صيغة البيانات غير صحيحة', code: res.statusCode);
      }
      return _fail('فشل في تحميل الطلبات', code: res.statusCode);
    } on DioException catch (e) {
      print('=== DioException in getCaseRequestsByCategory ===');
      print('type: ${e.type}');
      print('statusCode: ${e.response?.statusCode}');
      print('responseData: ${e.response?.data}');
      print('message: ${e.message}');
      return _fail(_dioError(e), code: e.response?.statusCode);
    } catch (e, st) {
      print('=== UNEXPECTED ERROR in getCaseRequestsByCategory ===');
      print('error: $e');
      print('stackTrace: $st');
      return _fail('حدث خطأ غير متوقع: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> createCaseRequest(
      Map<String, dynamic> body) async {
    try {
      final res = await _dio.post(ApiConstants.createCaseRequest, data: body);
      if (res.statusCode == 200 || res.statusCode == 201) {
        return _okData(res.data)..['message'] = 'تم إنشاء الطلب بنجاح';
      }
      return _fail('فشل في إنشاء الطلب', code: res.statusCode);
    } on DioException catch (e) {
      return _fail(_dioError(e), code: e.response?.statusCode);
    } catch (_) {
      return _fail('حدث خطأ غير متوقع');
    }
  }

  Future<Map<String, dynamic>> updateCaseRequest(
      int requestId, Map<String, dynamic> body) async {
    try {
      final res = await _dio.put(
        ApiConstants.updateCaseRequest,
        queryParameters: {'id': requestId},
        data: body,
      );
      if (res.statusCode == 200 || res.statusCode == 201) {
        return _okData(res.data)..['message'] = 'تم تحديث الطلب بنجاح';
      }
      return _fail('فشل في تحديث الطلب', code: res.statusCode);
    } on DioException catch (e) {
      return _fail(_dioError(e), code: e.response?.statusCode);
    } catch (_) {
      return _fail('حدث خطأ غير متوقع');
    }
  }

  /// PUT /api/request/editRequest/{requestId}
  /// Body: { description, dateTime }
  Future<Map<String, dynamic>> editRequest(
    int requestId,
    String description,
    String dateTime,
  ) async {
    try {
      await DioFactory.addDioHeaders();

      final body = {
        'description': description,
        'dateTime': dateTime,
      };

      final res = await _dio.put(
        '${ApiConstants.editRequest}/$requestId',
        data: body,
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        return _okData(res.data)..['message'] = 'تم تحديث الطلب بنجاح';
      }
      return _fail('فشل في تحديث الطلب', code: res.statusCode);
    } on DioException catch (e) {
      return _fail(_dioError(e), code: e.response?.statusCode);
    } catch (_) {
      return _fail('حدث خطأ غير متوقع');
    }
  }

  Future<Map<String, dynamic>> getRequestById(int id) async {
    try {
      final res = await _dio.get('${ApiConstants.getRequestById}/$id');
      if (res.statusCode == 200 && res.data is Map<String, dynamic>) {
        return _okData(
            CaseRequestModel.fromJson(res.data as Map<String, dynamic>));
      }
      return _fail('فشل في تحميل الطلب', code: res.statusCode);
    } on DioException catch (e) {
      return _fail(_dioError(e), code: e.response?.statusCode);
    } catch (_) {
      return _fail('حدث خطأ غير متوقع');
    }
  }

  Future<Map<String, dynamic>> getAllRequests() async {
    try {
      final res = await _dio.get(ApiConstants.getAllRequests);
      if (res.statusCode == 200 && res.data is List) {
        return _okList(
          (res.data as List)
              .map((e) => CaseRequestModel.fromJson(
                  Map<String, dynamic>.from(e as Map)))
              .toList(),
        );
      }
      return _fail('فشل في تحميل الطلبات', code: res.statusCode);
    } on DioException catch (e) {
      return _fail(_dioError(e), code: e.response?.statusCode);
    } catch (_) {
      return _fail('حدث خطأ غير متوقع');
    }
  }

  Future<Map<String, dynamic>> getRequestsByDoctorId(int doctorId) async {
    try {
      await DioFactory.addDioHeaders();
      final res = await _dio.get(
        ApiConstants.getRequestsByDoctorId,
        queryParameters: {'doctorId': doctorId},
      );

      if (res.statusCode == 200) {
        final data = res.data;
        // Support: plain List OR Map with data/content/items key
        final List? raw = data is List
            ? data
            : (data is Map
                ? (data['data'] ??
                    data['content'] ??
                    data['items'] ??
                    data['requests']) as List?
                : null);
        if (raw != null) {
          return _okList(
            raw
                .map((e) => CaseRequestModel.fromJson(
                    Map<String, dynamic>.from(e as Map)))
                .toList(),
          );
        }
        return _fail('صيغة البيانات غير صحيحة', code: res.statusCode);
      }
      return _fail('فشل في تحميل الطلبات', code: res.statusCode);
    } on DioException catch (e) {
      print('=== deleteDoctor error body ===');
      print('status code: ${e.response?.statusCode}');
      print('response data: ${e.response?.data}');
      return _fail(_dioError(e), code: e.response?.statusCode);
    } catch (_) {
      return _fail('حدث خطأ غير متوقع');
    }
  }

  Future<Map<String, dynamic>> deleteRequest(int id, {int? doctorId}) async {
    try {
      await DioFactory.addDioHeaders();
      final params = <String, dynamic>{'id': id};
      if (doctorId != null && doctorId != 0) params['doctorId'] = doctorId;
      final res = await _dio.delete(
        ApiConstants.deleteRequest,
        queryParameters: params,
      );
      if (res.statusCode == 200 || res.statusCode == 204)
        return {'success': true};
      if (res.statusCode == 403)
        return _fail('ممنوع الوصول: تأكد من أن هذا الطلب خاص بك', code: 403);
      return _fail('فشل في حذف الطلب', code: res.statusCode);
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      if (code == 403)
        return _fail('ممنوع الوصول: تأكد من أن هذا الطلب خاص بك', code: code);
      if (code == 404) return _fail('الطلب غير موجود', code: code);
      if (code == 500) return _fail('خطأ في الخادم، حاول مرة أخرى', code: code);
      return _fail(_dioError(e), code: code);
    } catch (_) {
      return _fail('حدث خطأ غير متوقع');
    }
  }

  int? _doctorIdFromJson(Map<String, dynamic> json) {
    final raw = json['id'] ?? json['doctorId'] ?? json['doctor_id'];
    return int.tryParse(raw?.toString() ?? '');
  }

  /// Fetch current doctor profile using token from headers
  /// If [doctorId] is provided, it will try with query parameters as fallback
  /// If [doctorId] is null, it will use only the token from headers
  Future<Map<String, dynamic>> getDoctorById([int? doctorId]) async {
    try {
      await DioFactory.addDioHeaders();

      // If no doctorId provided, use just the token from headers
      if (doctorId == null) {
        try {
          final res = await _dio.get(
            ApiConstants.getDoctorById,
            // No query parameters - token in header is enough
          );

          if (res.statusCode == 200 && res.data is Map) {
            Map<String, dynamic>? jsonData;
            final payload = res.data;

            if (payload['doctor'] is Map) {
              jsonData = Map<String, dynamic>.from(payload['doctor'] as Map);
            } else if (payload['data'] is Map) {
              jsonData = Map<String, dynamic>.from(payload['data'] as Map);
            } else {
              jsonData = Map<String, dynamic>.from(payload);
            }

            if (jsonData != null) {
              print('=== getDoctorById: Raw JSON (no params) = $jsonData ===');
              final parsed = DoctorProfileModel.fromJson(jsonData);
              print(
                  '=== getDoctorById: Parsed = id:${parsed.id}, phone:${parsed.phone}, faculty:${parsed.faculty}, year:${parsed.year}, category:${parsed.category} ===');
              return _okData(parsed);
            }
          }
        } on DioException catch (e) {
          print('=== getDoctorById: Request without params failed: $e ===');
          return _fail(_dioError(e), code: e.response?.statusCode);
        }
      }

      // Fallback: try with doctorId query parameters if provided
      if (doctorId != null) {
        final attempts = <Map<String, dynamic>>[
          {'doctorId': doctorId},
          {'id': doctorId},
          {'doctor_id': doctorId},
        ];

        for (final params in attempts) {
          try {
            final res = await _dio.get(
              ApiConstants.getDoctorById,
              queryParameters: params,
            );

            if (res.statusCode != 200) {
              continue;
            }

            Map<String, dynamic>? jsonData;
            final payload = res.data;
            if (payload is Map) {
              if (payload['doctor'] is Map) {
                jsonData = Map<String, dynamic>.from(payload['doctor'] as Map);
              } else if (payload['data'] is Map) {
                jsonData = Map<String, dynamic>.from(payload['data'] as Map);
              } else {
                jsonData = Map<String, dynamic>.from(payload);
              }
            }

            if (jsonData == null) {
              return _fail('صيغة بيانات الطبيب غير صحيحة',
                  code: res.statusCode);
            }

            print('=== getDoctorById: Raw JSON (with params) = $jsonData ===');
            final parsed = DoctorProfileModel.fromJson(jsonData);
            print(
                '=== getDoctorById: Parsed = id:${parsed.id}, phone:${parsed.phone}, faculty:${parsed.faculty}, year:${parsed.year}, category:${parsed.category} ===');
            final parsedId =
                parsed.id ?? _doctorIdFromJson(jsonData) ?? doctorId;
            return _okData(parsed.copyWith(id: parsedId));
          } on DioException catch (e) {
            final code = e.response?.statusCode;
            if (code == 400 || code == 404) {
              continue;
            }
            return _fail(_dioError(e), code: code);
          }
        }
      }

      return _fail('تعذر تحميل بيانات الطبيب');
    } catch (_) {
      return _fail('حدث خطأ غير متوقع');
    }
  }

  Future<Map<String, dynamic>> updateDoctor(Map<String, dynamic> body) async {
    try {
      await DioFactory.addDioHeaders();
      final res = await _dio.put(
        ApiConstants.updateDoctor,
        data: body,
      );
      if (res.statusCode == 200 || res.statusCode == 201)
        return _okData(res.data);
      if (res.statusCode == 403)
        return _fail('ممنوع الوصول: تأكد من صلاحياتك', code: 403);
      return _fail('فشل في تحديث بيانات الطبيب', code: res.statusCode);
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      if (code == 403)
        return _fail('ممنوع الوصول: تأكد من صلاحياتك', code: code);
      return _fail(_dioError(e), code: code);
    } catch (e) {
      debugPrint('updateDoctor unexpected error: $e');
      return _fail('حدث خطأ غير متوقع');
    }
  }

  Future<Map<String, dynamic>> deleteDoctor() async {
    try {
      await DioFactory.addDioHeaders();
      // حاول POST أولاً (بعض الـ APIs تستخدم POST للحذف)
      try {
        final res = await _dio.delete(ApiConstants.deleteDoctor);
        if (res.statusCode == 200 || res.statusCode == 204) {
          return {'success': true};
        }
        return _fail('فشل في حذف الحساب', code: res.statusCode);
      } on DioException catch (postError) {
        // إذا فشل POST، حاول DELETE
        if (postError.response?.statusCode == 404 ||
            postError.response?.statusCode == 405) {
          try {
            final res = await _dio.delete(ApiConstants.deleteDoctor);
            if (res.statusCode == 200 || res.statusCode == 204) {
              return {'success': true};
            }
            return _fail('فشل في حذف الحساب', code: res.statusCode);
          } on DioException catch (deleteError) {
            final code = deleteError.response?.statusCode;
            if (code == 404) return _fail('الطبيب غير موجود', code: code);
            if (code == 401)
              return _fail('غير مصرح: يرجى تسجيل الدخول مجدداً', code: code);
            if (code == 403)
              return _fail('ممنوع الوصول، تأكد من صلاحياتك', code: code);
            return _fail(_dioError(deleteError), code: code);
          }
        }
        // إذا كان الخطأ ليس 404 أو 405، أرجع الخطأ من POST
        final code = postError.response?.statusCode;
        if (code == 404) return _fail('الطبيب غير موجود', code: code);
        if (code == 401)
          return _fail('غير مصرح: يرجى تسجيل الدخول مجدداً', code: code);
        if (code == 403)
          return _fail('ممنوع الوصول، تأكد من صلاحياتك', code: code);
        return _fail(_dioError(postError), code: code);
      }
    } catch (_) {
      return _fail('حدث خطأ غير متوقع');
    }
  }

  // ── Appointments ─────────────────────────────────────────────────────────

  /// Create an appointment for a case request
  /// POST /api/appointment/createAppointment/{requestId}
  /// Body: { patientFirstName, patientLastName, patientPhoneNumber }
  Future<Map<String, dynamic>> createAppointment(
    int requestId,
    String patientFirstName,
    String patientLastName,
    String patientPhoneNumber,
  ) async {
    try {
      await DioFactory.addDioHeaders();

      final body = {
        'patientFirstName': patientFirstName,
        'patientLastName': patientLastName,
        'patientPhoneNumber': patientPhoneNumber,
      };

      final res = await _dio.post(
        '${ApiConstants.createAppointment}/$requestId',
        data: body,
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        return _okData(res.data)..['message'] = 'تم حجز الموعد بنجاح';
      }
      return _fail('فشل في حجز الموعد', code: res.statusCode);
    } on DioException catch (e) {
      return _fail(_dioError(e), code: e.response?.statusCode);
    } catch (_) {
      return _fail('حدث خطأ غير متوقع');
    }
  }

  /// GET /api/appointment/pendingAppointments
  /// Requires: Bearer JWT_TOKEN
  Future<Map<String, dynamic>> getPendingAppointments() async {
    try {
      await DioFactory.addDioHeaders();

      final res = await _dio.get(ApiConstants.pendingAppointments);

      if (res.statusCode == 200 && res.data is List) {
        return _okList(
          (res.data as List)
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList(),
        );
      }
      return _fail('فشل في تحميل الحجوزات', code: res.statusCode);
    } on DioException catch (e) {
      return _fail(_dioError(e), code: e.response?.statusCode);
    } catch (_) {
      return _fail('حدث خطأ غير متوقع');
    }
  }

  /// PUT /api/appointment/updateStatus/{appointmentId}?status=APPROVED|DONE|CANCELLED
  /// Requires: Bearer JWT_TOKEN (Doctor)
  /// Available Statuses: PENDING, APPROVED, DONE, CANCELLED
  Future<Map<String, dynamic>> updateAppointmentStatus(
    int appointmentId,
    String status,
  ) async {
    try {
      await DioFactory.addDioHeaders();

      final res = await _dio.put(
        '${ApiConstants.updateAppointmentStatus}/$appointmentId',
        queryParameters: {'status': status},
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        final statusAr = _statusToArabic(status);
        return _okData(res.data)
          ..['message'] = 'تم تحديث حالة الحجز إلى $statusAr بنجاح';
      }
      return _fail('فشل في تحديث حالة الحجز', code: res.statusCode);
    } on DioException catch (e) {
      return _fail(_dioError(e), code: e.response?.statusCode);
    } catch (_) {
      return _fail('حدث خطأ غير متوقع');
    }
  }

  /// Convert appointment status to Arabic
  String _statusToArabic(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return 'قيد الانتظار';
      case 'APPROVED':
        return 'موافق عليه';
      case 'DONE':
        return 'مكتمل';
      case 'CANCELLED':
        return 'ملغى';
      default:
        return status;
    }
  }
}
