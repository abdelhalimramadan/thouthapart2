import 'package:thoutha_mobile_app/core/networking/api_service.dart';
import 'package:thoutha_mobile_app/core/networking/models/category_model.dart';
import 'package:thoutha_mobile_app/core/networking/models/city_model.dart';
import 'package:thoutha_mobile_app/features/doctor/data/models/doctor_model.dart';
import 'package:thoutha_mobile_app/features/requests/data/models/case_request_model.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;

class DoctorRepository {
  final ApiService _apiService;

  DoctorRepository(this._apiService);

  Future<List<DoctorModel>> getDoctorsByCity(int cityId) async {
    final result = await _apiService.getDoctorsByCity(cityId);
    if (result['success'] == true) {
      return result['data'] as List<DoctorModel>;
    }
    throw Exception(result['error'] ?? 'doctor.failed_to_load_doctors'.tr());
  }

  Future<List<DoctorModel>> getDoctorsByCategory(int categoryId) async {
    final result = await _apiService.getDoctorsByCategory(categoryId);
    if (result['success'] == true) {
      return result['data'] as List<DoctorModel>;
    }
    throw Exception(result['error'] ?? 'doctor.failed_to_load_doctors'.tr());
  }

  Future<List<CaseRequestModel>> getCaseRequestsByCategory(int categoryId,
      {String? categoryName}) async {
    // Try the specific endpoint first
    final result = await _apiService.getCaseRequestsByCategory(categoryId);

    if (result['success'] == true) {
      return result['data'] as List<CaseRequestModel>;
    }

    throw Exception(result['error'] ?? 'doctor.failed_to_load_requests'.tr());
  }

  Future<List<CategoryModel>> getCategories() async {
    final result = await _apiService.getCategories();
    if (result['success'] == true) {
      return result['data'] as List<CategoryModel>;
    }
    throw Exception(result['error'] ?? 'doctor.failed_to_load_specializations'.tr());
  }

  Future<List<CityModel>> getCities() async {
    final result = await _apiService.getCities();
    if (result['success'] == true) {
      return result['data'] as List<CityModel>;
    }
    throw Exception(result['error'] ?? 'doctor.failed_to_load_cities'.tr());
  }

  Future<Map<String, dynamic>> deleteDoctor() async {
    try {
      return await _apiService.deleteDoctor();
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
}
