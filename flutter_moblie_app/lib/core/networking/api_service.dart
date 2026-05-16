import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:thoutha_mobile_app/core/networking/api_constants.dart';
import 'package:thoutha_mobile_app/core/networking/dio_factory.dart';
import 'package:thoutha_mobile_app/core/networking/models/category_model.dart';
import 'package:thoutha_mobile_app/core/networking/models/city_model.dart';
import 'package:thoutha_mobile_app/core/networking/models/university_model.dart';
import 'package:thoutha_mobile_app/features/doctor/data/models/doctor_model.dart';
import 'package:thoutha_mobile_app/features/requests/data/models/case_request_model.dart';
import 'package:thoutha_mobile_app/features/profile/data/models/doctor_profile_model.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;

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
        connectTimeout: Duration(seconds: 10),
        receiveTimeout: Duration(seconds: 10),
        headers: const {
          'Accept': 'application/json',
          'Content-Type': 'application/json'
        },
      ));

  // ── Helpers ──────────────────────────────────────────────────────────────

  /// Generic GET helper
  Future<Map<String, dynamic>> get(String path,
      {Map<String, dynamic>? query}) async {
    try {
      final res = await _dio.get(path, queryParameters: query);
      return _okData(res.data);
    } on DioException catch (e) {
      return _fail(_dioError(e), code: e.response?.statusCode);
    } catch (e) {
      return _fail(e.toString());
    }
  }

  /// Generic POST helper
  Future<Map<String, dynamic>> post(String path, {dynamic data}) async {
    try {
      final res = await _dio.post(path, data: data);
      return _okData(res.data);
    } on DioException catch (e) {
      return _fail(_dioError(e), code: e.response?.statusCode);
    } catch (e) {
      return _fail(e.toString());
    }
  }

  /// Generic PUT helper
  Future<Map<String, dynamic>> put(String path, {dynamic data}) async {
    try {
      final res = await _dio.put(path, data: data);
      return _okData(res.data);
    } on DioException catch (e) {
      return _fail(_dioError(e), code: e.response?.statusCode);
    } catch (e) {
      return _fail(e.toString());
    }
  }

  /// Generic DELETE helper
  Future<Map<String, dynamic>> delete(String path) async {
    try {
      final res = await _dio.delete(path);
      return _okData(res.data);
    } on DioException catch (e) {
      return _fail(_dioError(e), code: e.response?.statusCode);
    } catch (e) {
      return _fail(e.toString());
    }
  }

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
        return 'core.the_connection_timed_out'.tr();
      case DioExceptionType.connectionError:
        return 'core.unable_to_connect_to'.tr();
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
          return 'core.the_path_is_invalid'.tr();
        }
        if (code == 401) return 'core.unauthorized_please_log_in'.tr();
        if (code == 403) return 'core.access_forbidden_403'.tr();
        if (code == 404) return 'core.link_not_found_404'.tr();
        if (code != null && code >= 500) {
          final msg = 'core.server_error_var0'.tr(namedArgs: {'var_0': code.toString()});
          return msg.contains('core.') ? 'booking.an_unexpected_error_occurred'.tr() : msg;
        }
        return serverMsg.toString().isNotEmpty 
            ? serverMsg.toString() 
            : 'core.http_error_var0'.tr(namedArgs: {'var_0': code.toString()});
      default:
        final msg = 'core.unexpected_error_var0'.tr(namedArgs: {'var_0': e.message ?? e.type.name.toString()});
        return msg.contains('core.') ? 'booking.an_unexpected_error_occurred'.tr() : msg;
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
      return _fail('core.failed_to_load_doctors'.tr(), code: res.statusCode);
    } on DioException catch (e) {
      return _fail(_dioError(e), code: e.response?.statusCode);
    } catch (_) {
      return _fail('core.an_unexpected_error_occurred'.tr());
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
      return _fail('core.failed_to_load_doctors'.tr(), code: res.statusCode);
    } on DioException catch (e) {
      return _fail(_dioError(e), code: e.response?.statusCode);
    } catch (_) {
      return _fail('core.an_unexpected_error_occurred'.tr());
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
      return _fail('core.failed_to_load_specializations'.tr(), code: res.statusCode);
    } on DioException catch (e) {
      return _fail(_dioError(e));
    } catch (_) {
      return _fail('core.an_unexpected_error_occurred'.tr());
    }
  }

  Future<Map<String, dynamic>> getCities() async {
    try {
      final res = await _public.get(ApiConstants.getCities);
      if (res.statusCode == 200) {
        return _okList(
            (res.data as List).map((j) => CityModel.fromJson(j)).toList());
      }
      return _fail('core.failed_to_load_cities'.tr(), code: res.statusCode);
    } on DioException catch (e) {
      return _fail(_dioError(e));
    } catch (_) {
      return _fail('core.an_unexpected_error_occurred'.tr());
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
      return _fail('core.failed_to_load_universities'.tr(), code: res.statusCode);
    } on DioException catch (e) {
      return _fail(_dioError(e));
    } catch (_) {
      return _fail('core.an_unexpected_error_occurred'.tr());
    }
  }

  // ── Case Requests ────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getCaseRequestsByCategory(int categoryId) async {
    try {
      print('=== getCaseRequestsByCategory ===');
      print('categoryId: $categoryId');

      Response res;
      try {
        // Try public first (no auth).
        res = await _public.get(
          ApiConstants.getCaseRequestsByCategories,
          queryParameters: {'categoryId': categoryId},
        );
      } on DioException catch (e) {
        // If server requires auth for this endpoint, retry with authenticated Dio.
        final code = e.response?.statusCode;
        if (code == 401 || code == 403) {
          await DioFactory.addDioHeaders();
          res = await _dio.get(
            ApiConstants.getCaseRequestsByCategories,
            queryParameters: {'categoryId': categoryId},
          );
        } else {
          rethrow;
        }
      }

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
        return _fail('core.the_data_format_is'.tr(), code: res.statusCode);
      }
      return _fail('core.failed_to_load_requests'.tr(), code: res.statusCode);
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
      return _fail('core.an_unexpected_error_occurred_1'.tr(namedArgs: {'var_0': e.toString().toString()}));
    }
  }

  Future<Map<String, dynamic>> createCaseRequest(
      Map<String, dynamic> body) async {
    try {
      final res = await _dio.post(ApiConstants.createCaseRequest, data: body);
      if (res.statusCode == 200 || res.statusCode == 201) {
        return _okData(res.data)..['message'] = 'core.the_order_was_created'.tr();
      }
      return _fail('core.failed_to_create_request'.tr(), code: res.statusCode);
    } on DioException catch (e) {
      return _fail(_dioError(e), code: e.response?.statusCode);
    } catch (_) {
      return _fail('core.an_unexpected_error_occurred'.tr());
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
        return _okData(res.data)..['message'] = 'core.the_request_has_been'.tr();
      }
      return _fail('core.failed_to_update_the'.tr(), code: res.statusCode);
    } on DioException catch (e) {
      return _fail(_dioError(e), code: e.response?.statusCode);
    } catch (_) {
      return _fail('core.an_unexpected_error_occurred'.tr());
    }
  }

  /// PUT /api/request/editRequest/{requestId}
  /// Body: { description, dateTime }
  /// dateTime format: "2026-03-10T15:30:00"
  Future<Map<String, dynamic>> editRequest(
    int requestId,
    String description,
    String dateTime,
  ) async {
    try {
      await DioFactory.addDioHeaders();

      // Validate inputs
      if (description.trim().isEmpty) {
        return _fail('core.description_required'.tr());
      }
      if (dateTime.trim().isEmpty) {
        return _fail('core.date_and_time_required'.tr());
      }

      final body = {
        'description': description.trim(),
        'dateTime': dateTime.trim(),
      };

      debugPrint('Sending edit request: Body = $body');

      final res = await _dio.put(
        '${ApiConstants.editRequest}/$requestId',
        data: body,
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        return _okData(res.data)..['message'] = 'core.the_request_has_been'.tr();
      }
      return _fail('core.failed_to_update_request'.tr(namedArgs: {'var_0': res.statusCode.toString()}),
          code: res.statusCode);
    } on DioException catch (e) {
      debugPrint('Edit request error: ${e.message}');
      debugPrint('Response: ${e.response?.data}');
      return _fail(_dioError(e), code: e.response?.statusCode);
    } catch (e) {
      debugPrint('Unexpected error in editRequest: $e');
      return _fail('core.an_unexpected_error_occurred_1'.tr(namedArgs: {'var_0': e.toString()}));
    }
  }

  Future<Map<String, dynamic>> getRequestById(int id) async {
    try {
      final res = await _dio.get('${ApiConstants.getRequestById}/$id');
      if (res.statusCode == 200 && res.data is Map<String, dynamic>) {
        return _okData(
            CaseRequestModel.fromJson(res.data as Map<String, dynamic>));
      }
      return _fail('core.text'.tr(), code: res.statusCode);
    } on DioException catch (e) {
      return _fail(_dioError(e), code: e.response?.statusCode);
    } catch (_) {
      return _fail('core.an_unexpected_error_occurred'.tr());
    }
  }

  Future<Map<String, dynamic>> getRequestsByDoctorId() async {
    try {
      await DioFactory.addDioHeaders();
      final res = await _dio.get(
        ApiConstants.getRequestsByDoctorId,
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
        return _fail('core.the_data_format_is'.tr(), code: res.statusCode);
      }
      return _fail('core.failed_to_load_requests'.tr(), code: res.statusCode);
    } on DioException catch (e) {
      print('=== deleteDoctor error body ===');
      print('status code: ${e.response?.statusCode}');
      print('response data: ${e.response?.data}');
      return _fail(_dioError(e), code: e.response?.statusCode);
    } catch (_) {
      return _fail('core.an_unexpected_error_occurred'.tr());
    }
  }

  /// DELETE /api/request/deleteRequest/{requestId}
  Future<Map<String, dynamic>> deleteRequest(int id, {int? doctorId}) async {
    try {
      await DioFactory.addDioHeaders();

      // Debug logging
      debugPrint('=== deleteRequest Debug ===');
      debugPrint('Request ID to delete: $id');
      debugPrint('Doctor ID: $doctorId');
      debugPrint('API Endpoint: ${ApiConstants.deleteRequest}?id=$id');

      final res = await _dio.delete(
        ApiConstants.deleteRequest,
        queryParameters: {'id': id},
      );

      debugPrint('Delete Response Status: ${res.statusCode}');
      debugPrint('Delete Response Data: ${res.data}');

      if (res.statusCode == 200 || res.statusCode == 204) {
        debugPrint('✓ Request ID $id deleted successfully');
        return {'success': true, 'message': 'core.the_request_has_been_1'.tr()};
      }
      if (res.statusCode == 403) {
        return _fail('core.access_denied_make_sure'.tr(), code: 403);
      }
      return _fail('core.failed_to_delete_request'.tr(), code: res.statusCode);
    } on DioException catch (e) {
      debugPrint('=== deleteRequest DioException ===');
      debugPrint('Status Code: ${e.response?.statusCode}');
      debugPrint('Response Data: ${e.response?.data}');
      debugPrint('Error: ${e.message}');

      final code = e.response?.statusCode;
      if (code == 403) {
        return _fail('core.access_denied_make_sure'.tr(), code: code);
      }
      if (code == 404) return _fail('core.the_request_does_not'.tr(), code: code);
      if (code == 500) return _fail('core.server_error_try_again'.tr(), code: code);
      return _fail(_dioError(e), code: code);
    } catch (e) {
      debugPrint('=== deleteRequest Unexpected Error ===');
      debugPrint('Error: $e');
      return _fail('core.an_unexpected_error_occurred'.tr());
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

            print('=== getDoctorById: Raw JSON (no params) = $jsonData ===');
            final parsed = DoctorProfileModel.fromJson(jsonData);
            print(
                '=== getDoctorById: Parsed = id:${parsed.id}, phone:${parsed.phone}, faculty:${parsed.faculty}, year:${parsed.year}, category:${parsed.category} ===');
            return _okData(parsed);
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
              return _fail('core.the_doctors_data_format'.tr(),
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

      return _fail('core.unable_to_load_doctor'.tr());
    } catch (_) {
      return _fail('core.an_unexpected_error_occurred'.tr());
    }
  }

  Future<Map<String, dynamic>> updateDoctor(Map<String, dynamic> body) async {
    try {
      await DioFactory.addDioHeaders();
      final res = await _dio.put(
        ApiConstants.updateDoctor,
        data: body,
      );
      if (res.statusCode == 200 || res.statusCode == 201) {
        return _okData(res.data);
      }
      if (res.statusCode == 403) {
        return _fail('core.access_denied_check_your'.tr(), code: 403);
      }
      return _fail('core.failed_to_update_doctor'.tr(), code: res.statusCode);
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      if (code == 403) {
        return _fail('core.access_denied_check_your'.tr(), code: code);
      }
      return _fail(_dioError(e), code: code);
    } catch (e) {
      debugPrint('updateDoctor unexpected error: $e');
      return _fail('core.an_unexpected_error_occurred'.tr());
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
        return _fail('core.failed_to_delete_account'.tr(), code: res.statusCode);
      } on DioException catch (postError) {
        // إذا فشل POST، حاول DELETE
        if (postError.response?.statusCode == 404 ||
            postError.response?.statusCode == 405) {
          try {
            final res = await _dio.delete(ApiConstants.deleteDoctor);
            if (res.statusCode == 200 || res.statusCode == 204) {
              return {'success': true};
            }
            return _fail('core.failed_to_delete_account'.tr(), code: res.statusCode);
          } on DioException catch (deleteError) {
            final code = deleteError.response?.statusCode;
            if (code == 404) return _fail('core.the_doctor_is_not'.tr(), code: code);
            if (code == 401) {
              return _fail('core.unauthorized_please_log_in_1'.tr(), code: code);
            }
            if (code == 403) {
              return _fail('core.access_denied_check_your_1'.tr(), code: code);
            }
            return _fail(_dioError(deleteError), code: code);
          }
        }
        // إذا كان الخطأ ليس 404 أو 405، أرجع الخطأ من POST
        final code = postError.response?.statusCode;
        if (code == 404) return _fail('core.the_doctor_is_not'.tr(), code: code);
        if (code == 401) {
          return _fail('core.unauthorized_please_log_in_1'.tr(), code: code);
        }
        if (code == 403) {
          return _fail('core.access_denied_check_your_1'.tr(), code: code);
        }
        return _fail(_dioError(postError), code: code);
      }
    } catch (_) {
      return _fail('core.an_unexpected_error_occurred'.tr());
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

      // Normalize phone number to English digits
      final normalizedPhone = patientPhoneNumber
          .replaceAll('core.str_0'.tr(), '0')
          .replaceAll('core.str_1'.tr(), '1')
          .replaceAll('core.str_2'.tr(), '2')
          .replaceAll('core.str_3'.tr(), '3')
          .replaceAll('core.str_4'.tr(), '4')
          .replaceAll('core.str_5'.tr(), '5')
          .replaceAll('core.str_6'.tr(), '6')
          .replaceAll('core.str_7'.tr(), '7')
          .replaceAll('core.str_8'.tr(), '8')
          .replaceAll('core.str_9'.tr(), '9');

      final body = {
        'patientFirstName': patientFirstName,
        'patientLastName': patientLastName,
        'patientPhoneNumber': normalizedPhone,
      };

      print('=== API CALL: createAppointment ===');
      print('URL: ${ApiConstants.createAppointment}/$requestId');
      print('Body: $body');

      final res = await _dio.post(
        '${ApiConstants.createAppointment}/$requestId',
        data: body,
      );

      print('Response Status: ${res.statusCode}');
      print('Response Data: ${res.data}');

      if (res.statusCode == 200 || res.statusCode == 201) {
        return _okData(res.data)..['message'] = 'core.the_appointment_has_been'.tr();
      }
      return _fail('core.failed_to_book_an'.tr(), code: res.statusCode);
    } on DioException catch (e) {
      print('=== DioException in createAppointment ===');
      print('Status: ${e.response?.statusCode}');
      print('Data: ${e.response?.data}');
      print('Message: ${e.message}');
      
      String errorMsg = _dioError(e);
      
      // Specifically handle duplicate booking error
      final code = e.response?.statusCode;
      if (code == 400 || code == 409 || code == 404) {
        final data = e.response?.data;
        final serverMsg = data is Map 
            ? (data['messageAr'] ?? data['messageEn'] ?? data['message'] ?? '').toString().toLowerCase()
            : data?.toString().toLowerCase() ?? '';
            
        if (serverMsg.contains('already booked') || 
            serverMsg.contains('core.booked'.tr()) || 
            serverMsg.contains('duplicate') ||
            serverMsg.contains('static resource') ||
            serverMsg.contains('core.fixed_resource'.tr())) {
          errorMsg = 'core.we_have_already_booked'.tr();
        }
      }
      
      return _fail(errorMsg, code: code);
    } catch (e) {
      print('=== Unexpected error in createAppointment ===');
      print('Error: $e');
      return _fail('core.an_unexpected_error_occurred'.tr());
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
      return _fail('core.failed_to_load_reservations'.tr(), code: res.statusCode);
    } on DioException catch (e) {
      return _fail(_dioError(e), code: e.response?.statusCode);
    } catch (_) {
      return _fail('core.an_unexpected_error_occurred'.tr());
    }
  }

  /// GET /api/appointment/getApproved
  /// Requires: Bearer JWT_TOKEN
  /// Returns: List of approved appointments
  Future<Map<String, dynamic>> getApprovedAppointments() async {
    try {
      await DioFactory.addDioHeaders();

      final res = await _dio.get(ApiConstants.approvedAppointments);

      if (res.statusCode == 200) {
        if (res.data is List) {
          return _okList(
            (res.data as List)
                .map((e) => Map<String, dynamic>.from(e as Map))
                .toList(),
          );
        } else if (res.data is Map && (res.data as Map).containsKey('data')) {
          final data = (res.data as Map)['data'];
          if (data is List) {
            return _okList(
              data.map((e) => Map<String, dynamic>.from(e as Map)).toList(),
            );
          }
        }
        return _okList([]);
      }
      return _fail('core.failed_to_load_approved'.tr(), code: res.statusCode);
    } on DioException catch (e) {
      return _fail(_dioError(e), code: e.response?.statusCode);
    } catch (_) {
      return _fail('core.an_unexpected_error_occurred'.tr());
    }
  }

  /// GET /api/appointment/getDone
  /// Fetch all confirmed (DONE status) appointments for the doctor
  /// Requires: Bearer JWT_TOKEN (Doctor)
  Future<Map<String, dynamic>> getDoneAppointments() async {
    try {
      await DioFactory.addDioHeaders();

      final res = await _dio.get(ApiConstants.doneAppointments);

      if (res.statusCode == 200) {
        if (res.data is List) {
          return _okList(
            (res.data as List)
                .map((e) => Map<String, dynamic>.from(e as Map))
                .toList(),
          );
        } else if (res.data is Map && (res.data as Map).containsKey('data')) {
          final data = (res.data as Map)['data'];
          if (data is List) {
            return _okList(
              data.map((e) => Map<String, dynamic>.from(e as Map)).toList(),
            );
          }
        }
        return _okList([]);
      }
      return _fail('core.failed_to_load_confirmed'.tr(), code: res.statusCode);
    } on DioException catch (e) {
      return _fail(_dioError(e), code: e.response?.statusCode);
    } catch (_) {
      return _fail('core.an_unexpected_error_occurred'.tr());
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
          ..['message'] = 'core.the_reservation_status_has'.tr(namedArgs: {'var_0': statusAr.toString()});
      }
      return _fail('core.failed_to_update_reservation'.tr(), code: res.statusCode);
    } on DioException catch (e) {
      return _fail(_dioError(e), code: e.response?.statusCode);
    } catch (_) {
      return _fail('core.an_unexpected_error_occurred'.tr());
    }
  }

  /// Convert appointment status to Arabic
  String _statusToArabic(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return 'core.on_hold'.tr();
      case 'APPROVED':
        return 'core.approved'.tr();
      case 'DONE':
        return 'core.complete'.tr();
      case 'CANCELLED':
        return 'core.canceled'.tr();
      default:
        return status;
    }
  }

  /// GET /api/appointment/history
  /// Requires: Bearer JWT_TOKEN (Doctor)
  /// Returns: List of completed/cancelled appointments (isHistory=true)
  Future<Map<String, dynamic>> getAppointmentHistory() async {
    try {
      await DioFactory.addDioHeaders();

      print('=== DEBUG: Calling getAppointmentHistory ===');
      print('URL: ${ApiConstants.appointmentHistory}');

      final res = await _dio.get(
        ApiConstants.appointmentHistory,
      );

      print('Response Status: ${res.statusCode}');
      print('Response Data: ${res.data}');

      if (res.statusCode == 200) {
        // Handle both list and wrapped object responses
        if (res.data is List) {
          return _okList(
            (res.data as List)
                .map((e) => Map<String, dynamic>.from(e as Map))
                .toList(),
          );
        } else if (res.data is Map && (res.data as Map).containsKey('data')) {
          // If data is wrapped in an object
          final data = (res.data as Map)['data'];
          if (data is List) {
            return _okList(
              data.map((e) => Map<String, dynamic>.from(e as Map)).toList(),
            );
          }
        }
        // If empty or no data
        return _okList([]);
      }
      print('=== API Error: ${res.statusCode} ===');
      return _fail('core.failed_to_load_reservation'.tr(), code: res.statusCode);
    } on DioException catch (e) {
      print('=== DioException: ${e.message} ===');
      print('=== Status Code: ${e.response?.statusCode} ===');
      print('=== Response: ${e.response?.data} ===');
      return _fail(_dioError(e), code: e.response?.statusCode);
    } catch (e) {
      print('=== Exception: $e ===');
      return _fail('core.an_unexpected_error_occurred'.tr());
    }
  }

  /// DELETE /api/appointment/deleteAppointment/{appointmentId}
  /// Requires: Bearer JWT_TOKEN (Doctor)
  /// Response: 204 No Content on success
  Future<Map<String, dynamic>> deleteAppointment(int appointmentId) async {
    try {
      await DioFactory.addDioHeaders();

      final res = await _dio.delete(
        '${ApiConstants.deleteAppointment}/$appointmentId',
      );

      if (res.statusCode == 200 || res.statusCode == 204) {
        return {'success': true, 'message': 'core.the_record_has_been'.tr()};
      }
      return _fail('core.failed_to_delete_record'.tr(), code: res.statusCode);
    } on DioException catch (e) {
      return _fail(_dioError(e), code: e.response?.statusCode);
    } catch (_) {
      return _fail('core.an_unexpected_error_occurred'.tr());
    }
  }
}
