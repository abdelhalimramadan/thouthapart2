import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:thotha_mobile_app/core/networking/api_constants.dart';
import 'package:thotha_mobile_app/core/networking/dio_factory.dart';
import 'package:thotha_mobile_app/core/networking/models/category_model.dart';
import 'package:thotha_mobile_app/core/networking/models/city_model.dart';
import 'package:thotha_mobile_app/core/networking/models/university_model.dart';
import 'package:thotha_mobile_app/core/networking/models/api_error.dart';
import 'package:thotha_mobile_app/core/networking/models/api_result.dart';
import 'package:thotha_mobile_app/features/doctor/data/models/doctor_model.dart';
import 'package:thotha_mobile_app/features/requests/data/models/case_request_model.dart';
import 'package:thotha_mobile_app/features/profile/data/models/profile_model.dart';

/// Centralised API service.
///
/// All paths are *relative* ΓÇö DioFactory already sets `baseUrl` to
/// `https://thoutha.page`, so we never concatenate `baseUrl` here.
class ApiService {
  // Authenticated Dio ΓÇö shared singleton with Bearer token interceptor
  late final Dio _dio = DioFactory.getDio();

  // Public Dio ΓÇö no auth, used for open reference-data endpoints
  Dio get _public => Dio(BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: const {
          'Accept': 'application/json',
          'Content-Type': 'application/json'
        },
      ));

  // ΓöÇΓöÇ Helpers ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ

  /// Wraps a successful list response.
  Map<String, dynamic> _okList(List items) =>
      ApiResult<List>.success(items).toJson();

  /// Wraps a successful map/object response.
  Map<String, dynamic> _okData(dynamic data) =>
      ApiResult<dynamic>.success(data).toJson();

  /// Wraps a failure in a unified API error shape.
  Map<String, dynamic> _fail(String msg, {int? code, dynamic details}) {
    return ApiResult<dynamic>.failure(
      ApiError(
        messageAr: msg,
        statusCode: code,
        details: details,
      ),
    ).toJson();
  }

  /// Converts Dio errors to user-friendly Arabic strings.
  String _dioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
        return '╪º┘å╪¬┘ç╪¬ ┘à┘ç┘ä╪⌐ ╪º┘ä╪º╪¬╪╡╪º┘ä. ╪¬╪¡┘é┘é ┘à┘å ╪º┘ä╪Ñ┘å╪¬╪▒┘å╪¬';
      case DioExceptionType.connectionError:
        return '╪¬╪╣╪░╪▒ ╪º┘ä╪º╪¬╪╡╪º┘ä ╪¿╪º┘ä╪«╪º╪»┘à. ╪¬╪¡┘é┘é ┘à┘å ╪º┘ä╪Ñ┘å╪¬╪▒┘å╪¬';
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
          return '╪º┘ä┘à╪│╪º╪▒ ╪║┘è╪▒ ╪╡╪¡┘è╪¡ ╪╣┘ä┘ë ╪º┘ä╪«╪º╪»┘à. ┘è╪▒╪¼┘ë ╪º┘ä┘à╪¡╪º┘ê┘ä╪⌐ ┘à╪▒╪⌐ ╪ú╪«╪▒┘ë';
        }
        if (code == 401) return '╪║┘è╪▒ ┘à╪╡╪▒╪¡: ┘è╪▒╪¼┘ë ╪¬╪│╪¼┘è┘ä ╪º┘ä╪»╪«┘ê┘ä ┘à╪¼╪»╪»╪º┘ï (401)';
        if (code == 403) return '┘à┘à┘å┘ê╪╣ ╪º┘ä┘ê╪╡┘ê┘ä (403)';
        if (code == 404) return '╪º┘ä╪▒╪º╪¿╪╖ ╪║┘è╪▒ ┘à┘ê╪¼┘ê╪» (404)';
        if (code != null && code >= 500) return '╪«╪╖╪ú ┘ü┘è ╪º┘ä╪«╪º╪»┘à ($code)';
        return '╪«╪╖╪ú HTTP $code${serverMsg.isNotEmpty ? ": $serverMsg" : ""}';
      default:
        return '╪«╪╖╪ú ╪║┘è╪▒ ┘à╪¬┘ê┘é╪╣: ${e.message ?? e.type.name}';
    }
  }

  // ΓöÇΓöÇ Doctors (public) ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ

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
      return _fail('┘ü╪┤┘ä ┘ü┘è ╪¬╪¡┘à┘è┘ä ╪º┘ä╪ú╪╖╪¿╪º╪í', code: res.statusCode);
    } on DioException catch (e) {
      return _fail(_dioError(e), code: e.response?.statusCode);
    } catch (_) {
      return _fail('╪¡╪»╪½ ╪«╪╖╪ú ╪║┘è╪▒ ┘à╪¬┘ê┘é╪╣');
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
      return _fail('┘ü╪┤┘ä ┘ü┘è ╪¬╪¡┘à┘è┘ä ╪º┘ä╪ú╪╖╪¿╪º╪í', code: res.statusCode);
    } on DioException catch (e) {
      return _fail(_dioError(e), code: e.response?.statusCode);
    } catch (_) {
      return _fail('╪¡╪»╪½ ╪«╪╖╪ú ╪║┘è╪▒ ┘à╪¬┘ê┘é╪╣');
    }
  }

  // ΓöÇΓöÇ Reference data (public) ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ

  Future<Map<String, dynamic>> getCategories() async {
    try {
      final res = await _public.get(ApiConstants.getCategories);
      if (res.statusCode == 200) {
        return _okList(
            (res.data as List).map((j) => CategoryModel.fromJson(j)).toList());
      }
      return _fail('┘ü╪┤┘ä ┘ü┘è ╪¬╪¡┘à┘è┘ä ╪º┘ä╪¬╪«╪╡╪╡╪º╪¬', code: res.statusCode);
    } on DioException catch (e) {
      return _fail(_dioError(e));
    } catch (_) {
      return _fail('╪¡╪»╪½ ╪«╪╖╪ú ╪║┘è╪▒ ┘à╪¬┘ê┘é╪╣');
    }
  }

  Future<Map<String, dynamic>> getCities() async {
    try {
      final res = await _public.get(ApiConstants.getCities);
      if (res.statusCode == 200) {
        return _okList(
            (res.data as List).map((j) => CityModel.fromJson(j)).toList());
      }
      return _fail('┘ü╪┤┘ä ┘ü┘è ╪¬╪¡┘à┘è┘ä ╪º┘ä┘à╪»┘å', code: res.statusCode);
    } on DioException catch (e) {
      return _fail(_dioError(e));
    } catch (_) {
      return _fail('╪¡╪»╪½ ╪«╪╖╪ú ╪║┘è╪▒ ┘à╪¬┘ê┘é╪╣');
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
      return _fail('┘ü╪┤┘ä ┘ü┘è ╪¬╪¡┘à┘è┘ä ╪º┘ä╪¼╪º┘à╪╣╪º╪¬', code: res.statusCode);
    } on DioException catch (e) {
      return _fail(_dioError(e));
    } catch (_) {
      return _fail('╪¡╪»╪½ ╪«╪╖╪ú ╪║┘è╪▒ ┘à╪¬┘ê┘é╪╣');
    }
  }

  // ΓöÇΓöÇ Case Requests ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ

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
        return _fail('╪╡┘è╪║╪⌐ ╪º┘ä╪¿┘è╪º┘å╪º╪¬ ╪║┘è╪▒ ╪╡╪¡┘è╪¡╪⌐', code: res.statusCode);
      }
      return _fail('┘ü╪┤┘ä ┘ü┘è ╪¬╪¡┘à┘è┘ä ╪º┘ä╪╖┘ä╪¿╪º╪¬', code: res.statusCode);
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
      return _fail('╪¡╪»╪½ ╪«╪╖╪ú ╪║┘è╪▒ ┘à╪¬┘ê┘é╪╣: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> createCaseRequest(
      Map<String, dynamic> body) async {
    try {
      final res = await _dio.post(ApiConstants.createCaseRequest, data: body);
      if (res.statusCode == 200 || res.statusCode == 201) {
        return _okData(res.data)..['message'] = '╪¬┘à ╪Ñ┘å╪┤╪º╪í ╪º┘ä╪╖┘ä╪¿ ╪¿┘å╪¼╪º╪¡';
      }
      return _fail('┘ü╪┤┘ä ┘ü┘è ╪Ñ┘å╪┤╪º╪í ╪º┘ä╪╖┘ä╪¿', code: res.statusCode);
    } on DioException catch (e) {
      return _fail(_dioError(e), code: e.response?.statusCode);
    } catch (_) {
      return _fail('╪¡╪»╪½ ╪«╪╖╪ú ╪║┘è╪▒ ┘à╪¬┘ê┘é╪╣');
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
        return _okData(res.data)..['message'] = '╪¬┘à ╪¬╪¡╪»┘è╪½ ╪º┘ä╪╖┘ä╪¿ ╪¿┘å╪¼╪º╪¡';
      }
      return _fail('┘ü╪┤┘ä ┘ü┘è ╪¬╪¡╪»┘è╪½ ╪º┘ä╪╖┘ä╪¿', code: res.statusCode);
    } on DioException catch (e) {
      return _fail(_dioError(e), code: e.response?.statusCode);
    } catch (_) {
      return _fail('╪¡╪»╪½ ╪«╪╖╪ú ╪║┘è╪▒ ┘à╪¬┘ê┘é╪╣');
    }
  }

  Future<Map<String, dynamic>> getRequestById(int id) async {
    try {
      final res = await _dio.get('${ApiConstants.getRequestById}/$id');
      if (res.statusCode == 200 && res.data is Map<String, dynamic>) {
        return _okData(
            CaseRequestModel.fromJson(res.data as Map<String, dynamic>));
      }
      return _fail('┘ü╪┤┘ä ┘ü┘è ╪¬╪¡┘à┘è┘ä ╪º┘ä╪╖┘ä╪¿', code: res.statusCode);
    } on DioException catch (e) {
      return _fail(_dioError(e), code: e.response?.statusCode);
    } catch (_) {
      return _fail('╪¡╪»╪½ ╪«╪╖╪ú ╪║┘è╪▒ ┘à╪¬┘ê┘é╪╣');
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
      return _fail('┘ü╪┤┘ä ┘ü┘è ╪¬╪¡┘à┘è┘ä ╪º┘ä╪╖┘ä╪¿╪º╪¬', code: res.statusCode);
    } on DioException catch (e) {
      return _fail(_dioError(e), code: e.response?.statusCode);
    } catch (_) {
      return _fail('╪¡╪»╪½ ╪«╪╖╪ú ╪║┘è╪▒ ┘à╪¬┘ê┘é╪╣');
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
        return _fail('╪╡┘è╪║╪⌐ ╪º┘ä╪¿┘è╪º┘å╪º╪¬ ╪║┘è╪▒ ╪╡╪¡┘è╪¡╪⌐', code: res.statusCode);
      }
      return _fail('┘ü╪┤┘ä ┘ü┘è ╪¬╪¡┘à┘è┘ä ╪º┘ä╪╖┘ä╪¿╪º╪¬', code: res.statusCode);
    } on DioException catch (e) {
      print('=== deleteDoctor error body ===');
      print('status code: ${e.response?.statusCode}');
      print('response data: ${e.response?.data}');
      return _fail(_dioError(e), code: e.response?.statusCode);
    } catch (_) {
      return _fail('╪¡╪»╪½ ╪«╪╖╪ú ╪║┘è╪▒ ┘à╪¬┘ê┘é╪╣');
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
        return _fail('┘à┘à┘å┘ê╪╣ ╪º┘ä┘ê╪╡┘ê┘ä: ╪¬╪ú┘â╪» ┘à┘å ╪ú┘å ┘ç╪░╪º ╪º┘ä╪╖┘ä╪¿ ╪«╪º╪╡ ╪¿┘â', code: 403);
      return _fail('┘ü╪┤┘ä ┘ü┘è ╪¡╪░┘ü ╪º┘ä╪╖┘ä╪¿', code: res.statusCode);
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      if (code == 403)
        return _fail('┘à┘à┘å┘ê╪╣ ╪º┘ä┘ê╪╡┘ê┘ä: ╪¬╪ú┘â╪» ┘à┘å ╪ú┘å ┘ç╪░╪º ╪º┘ä╪╖┘ä╪¿ ╪«╪º╪╡ ╪¿┘â', code: code);
      if (code == 404) return _fail('╪º┘ä╪╖┘ä╪¿ ╪║┘è╪▒ ┘à┘ê╪¼┘ê╪»', code: code);
      if (code == 500) return _fail('╪«╪╖╪ú ┘ü┘è ╪º┘ä╪«╪º╪»┘à╪î ╪¡╪º┘ê┘ä ┘à╪▒╪⌐ ╪ú╪«╪▒┘ë', code: code);
      return _fail(_dioError(e), code: code);
    } catch (_) {
      return _fail('╪¡╪»╪½ ╪«╪╖╪ú ╪║┘è╪▒ ┘à╪¬┘ê┘é╪╣');
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
              final parsed = ProfileModel.fromJson(jsonData);
              print('=== getDoctorById: Parsed = id:${parsed.id}, phone:${parsed.phone}, faculty:${parsed.faculty}, year:${parsed.year}, category:${parsed.category} ===');
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
              return _fail('╪╡┘è╪║╪⌐ ╪¿┘è╪º┘å╪º╪¬ ╪º┘ä╪╖╪¿┘è╪¿ ╪║┘è╪▒ ╪╡╪¡┘è╪¡╪⌐', code: res.statusCode);
            }

            print('=== getDoctorById: Raw JSON (with params) = $jsonData ===');
            final parsed = ProfileModel.fromJson(jsonData);
            print('=== getDoctorById: Parsed = id:${parsed.id}, phone:${parsed.phone}, faculty:${parsed.faculty}, year:${parsed.year}, category:${parsed.category} ===');
            final parsedId = parsed.id ?? _doctorIdFromJson(jsonData) ?? doctorId;
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

      return _fail('╪¬╪╣╪░╪▒ ╪¬╪¡┘à┘è┘ä ╪¿┘è╪º┘å╪º╪¬ ╪º┘ä╪╖╪¿┘è╪¿');
    } catch (_) {
      return _fail('╪¡╪»╪½ ╪«╪╖╪ú ╪║┘è╪▒ ┘à╪¬┘ê┘é╪╣');
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
        return _fail('┘à┘à┘å┘ê╪╣ ╪º┘ä┘ê╪╡┘ê┘ä: ╪¬╪ú┘â╪» ┘à┘å ╪╡┘ä╪º╪¡┘è╪º╪¬┘â', code: 403);
      return _fail('┘ü╪┤┘ä ┘ü┘è ╪¬╪¡╪»┘è╪½ ╪¿┘è╪º┘å╪º╪¬ ╪º┘ä╪╖╪¿┘è╪¿', code: res.statusCode);
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      if (code == 403)
        return _fail('┘à┘à┘å┘ê╪╣ ╪º┘ä┘ê╪╡┘ê┘ä: ╪¬╪ú┘â╪» ┘à┘å ╪╡┘ä╪º╪¡┘è╪º╪¬┘â', code: code);
      return _fail(_dioError(e), code: code);
    } catch (e) {
      debugPrint('updateDoctor unexpected error: $e');
      return _fail('╪¡╪»╪½ ╪«╪╖╪ú ╪║┘è╪▒ ┘à╪¬┘ê┘é╪╣');
    }
  }

  Future<Map<String, dynamic>> deleteDoctor() async {
    try {
      await DioFactory.addDioHeaders();
      // ╪¡╪º┘ê┘ä POST ╪ú┘ê┘ä╪º┘ï (╪¿╪╣╪╢ ╪º┘ä┘Ç APIs ╪¬╪│╪¬╪«╪»┘à POST ┘ä┘ä╪¡╪░┘ü)
      try {
        final res = await _dio.delete(ApiConstants.deleteDoctor);
        if (res.statusCode == 200 || res.statusCode == 204) {
          return {'success': true};
        }
        return _fail('┘ü╪┤┘ä ┘ü┘è ╪¡╪░┘ü ╪º┘ä╪¡╪│╪º╪¿', code: res.statusCode);
      } on DioException catch (postError) {
        // ╪Ñ╪░╪º ┘ü╪┤┘ä POST╪î ╪¡╪º┘ê┘ä DELETE
        if (postError.response?.statusCode == 404 ||
            postError.response?.statusCode == 405) {
          try {
            final res = await _dio.delete(ApiConstants.deleteDoctor);
            if (res.statusCode == 200 || res.statusCode == 204) {
              return {'success': true};
            }
            return _fail('┘ü╪┤┘ä ┘ü┘è ╪¡╪░┘ü ╪º┘ä╪¡╪│╪º╪¿', code: res.statusCode);
          } on DioException catch (deleteError) {
            final code = deleteError.response?.statusCode;
            if (code == 404) return _fail('╪º┘ä╪╖╪¿┘è╪¿ ╪║┘è╪▒ ┘à┘ê╪¼┘ê╪»', code: code);
            if (code == 401)
              return _fail('╪║┘è╪▒ ┘à╪╡╪▒╪¡: ┘è╪▒╪¼┘ë ╪¬╪│╪¼┘è┘ä ╪º┘ä╪»╪«┘ê┘ä ┘à╪¼╪»╪»╪º┘ï', code: code);
            if (code == 403)
              return _fail('┘à┘à┘å┘ê╪╣ ╪º┘ä┘ê╪╡┘ê┘ä╪î ╪¬╪ú┘â╪» ┘à┘å ╪╡┘ä╪º╪¡┘è╪º╪¬┘â', code: code);
            return _fail(_dioError(deleteError), code: code);
          }
        }
        // ╪Ñ╪░╪º ┘â╪º┘å ╪º┘ä╪«╪╖╪ú ┘ä┘è╪│ 404 ╪ú┘ê 405╪î ╪ú╪▒╪¼╪╣ ╪º┘ä╪«╪╖╪ú ┘à┘å POST
        final code = postError.response?.statusCode;
        if (code == 404) return _fail('╪º┘ä╪╖╪¿┘è╪¿ ╪║┘è╪▒ ┘à┘ê╪¼┘ê╪»', code: code);
        if (code == 401)
          return _fail('╪║┘è╪▒ ┘à╪╡╪▒╪¡: ┘è╪▒╪¼┘ë ╪¬╪│╪¼┘è┘ä ╪º┘ä╪»╪«┘ê┘ä ┘à╪¼╪»╪»╪º┘ï', code: code);
        if (code == 403)
          return _fail('┘à┘à┘å┘ê╪╣ ╪º┘ä┘ê╪╡┘ê┘ä╪î ╪¬╪ú┘â╪» ┘à┘å ╪╡┘ä╪º╪¡┘è╪º╪¬┘â', code: code);
        return _fail(_dioError(postError), code: code);
      }
    } catch (_) {
      return _fail('╪¡╪»╪½ ╪«╪╖╪ú ╪║┘è╪▒ ┘à╪¬┘ê┘é╪╣');
    }
  }

  // Appointments

  Future<Map<String, dynamic>> getAllAppointments() async {
    try {
      await DioFactory.addDioHeaders();
      final res = await _dio.get(ApiConstants.getAllAppointments);

      if (res.statusCode == 200) {
        final data = res.data;
        final List<dynamic>? raw = data is List
            ? data
            : (data is Map
                ? (data['data'] ?? data['content'] ?? data['items']) as List?
                : null);

        if (raw != null) {
          // Keep payload as JSON maps to preserve current cubit contract.
          return _okList(raw.map((e) => Map<String, dynamic>.from(e as Map)).toList());
        }
      }

      return _fail('فشل في تحميل الحجوزات', code: res.statusCode);
    } on DioException catch (e) {
      return _fail(_dioError(e), code: e.response?.statusCode);
    } catch (_) {
      return _fail('حدث خطأ غير متوقع');
    }
  }

  Future<Map<String, dynamic>> getAppointmentsByDoctorId(int doctorId) async {
    try {
      await DioFactory.addDioHeaders();
      final res = await _dio.get(
        ApiConstants.getAppointmentsByDoctorId,
        queryParameters: {'doctorId': doctorId},
      );

      if (res.statusCode == 200) {
        final data = res.data;
        final List<dynamic>? raw = data is List
            ? data
            : (data is Map
                ? (data['data'] ?? data['content'] ?? data['items']) as List?
                : null);

        if (raw != null) {
          return _okList(raw.map((e) => Map<String, dynamic>.from(e as Map)).toList());
        }
      }

      return _fail('فشل في تحميل حجوزات الطبيب', code: res.statusCode);
    } on DioException catch (e) {
      return _fail(_dioError(e), code: e.response?.statusCode);
    } catch (_) {
      return _fail('حدث خطأ غير متوقع');
    }
  }

  Future<Map<String, dynamic>> createAppointment(Map<String, dynamic> body) async {
    try {
      await DioFactory.addDioHeaders();
      final res = await _dio.post(ApiConstants.createAppointment, data: body);

      if (res.statusCode == 200 || res.statusCode == 201) {
        return _okData(res.data);
      }

      return _fail('فشل في إنشاء الحجز', code: res.statusCode);
    } on DioException catch (e) {
      return _fail(_dioError(e), code: e.response?.statusCode);
    } catch (_) {
      return _fail('حدث خطأ غير متوقع');
    }
  }

  Future<Map<String, dynamic>> getAppointmentById(int id) async {
    try {
      await DioFactory.addDioHeaders();
      final res = await _dio.get(
        ApiConstants.getAppointmentById,
        queryParameters: {'id': id},
      );

      if (res.statusCode == 200) {
        final data = res.data;
        final dynamic raw = data is Map
            ? (data['data'] ?? data['item'] ?? data)
            : data;

        if (raw is Map) {
          return _okData(Map<String, dynamic>.from(raw));
        }
      }

      return _fail('فشل في تحميل تفاصيل الحجز', code: res.statusCode);
    } on DioException catch (e) {
      return _fail(_dioError(e), code: e.response?.statusCode);
    } catch (_) {
      return _fail('حدث خطأ غير متوقع');
    }
  }
}
