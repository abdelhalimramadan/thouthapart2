import 'package:thotha_mobile_app/core/networking/api_service.dart';
import 'package:thotha_mobile_app/features/home_screen/data/models/case_request_body.dart';

class CaseRequestRepo {
  final ApiService _apiService;

  CaseRequestRepo(this._apiService);

  Future<Map<String, dynamic>> createCaseRequest(CaseRequestBody body) async {
    try {
      final response = await _apiService.createCaseRequest(body.toJson());
      return response;
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> getRequestById(int id) async {
    try {
      return await _apiService.getRequestById(id);
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> getAllRequests() async {
    try {
      return await _apiService.getAllRequests();
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> getRequestsByDoctorId(int doctorId) async {
    try {
      return await _apiService.getRequestsByDoctorId(doctorId);
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> deleteRequest(int id) async {
    try {
      return await _apiService.deleteRequest(id);
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
}
