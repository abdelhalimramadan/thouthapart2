import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:thotha_mobile_app/core/helpers/constants.dart';
import 'package:thotha_mobile_app/core/helpers/shared_pref_helper.dart';
import 'package:thotha_mobile_app/core/networking/dio_factory.dart';
import 'package:thotha_mobile_app/core/networking/api_service.dart';
import 'package:thotha_mobile_app/core/di/dependency_injection.dart';
import 'package:thotha_mobile_app/core/networking/models/city_model.dart';
import 'package:thotha_mobile_app/core/networking/models/university_model.dart';
import 'package:thotha_mobile_app/core/networking/models/category_model.dart';
import 'package:thotha_mobile_app/features/home_screen/doctor_home/data/models/doctor_profile_model.dart';

class ProfileRepository {
  final Dio _dio = DioFactory.getDio();

  /// Centralized logic to fetch profile from server using token in headers
  /// NO CACHING - Always fetches fresh data from the server
  /// Workflow: Login (save token) -> Use token to fetch doctor data -> Display it
  Future<DoctorProfileModel> fetchProfile() async {
    // Primary: Try getDoctorById using token from headers (no request body)
    // الـ Token موجود في headers تلقائياً من DioFactory
    print(
        '=== fetchProfile: Attempting to fetch doctor profile using token ===');
    try {
      final profileResult = await getIt<ApiService>().getDoctorById();
      if (profileResult['success'] == true &&
          profileResult['data'] is DoctorProfileModel) {
        final profile = profileResult['data'] as DoctorProfileModel;
        print(
            '=== fetchProfile: Successfully fetched fresh doctor profile ===');
        // NO CACHING - Return fresh data directly from server
        return profile;
      }
    } catch (e) {
      print('=== fetchProfile: getDoctorById failed: $e ===');
      // Continue to fallback endpoints
    }

    // Fallback: Try other endpoints if primary fails
    Response? response;
    final endpoints = [
      '/api/auth/profile',
      '/api/doctor/profile',
      '/api/user/me',
      '/api/me',
      '/profile',
      '/me'
    ];

    for (final path in endpoints) {
      try {
        print('=== fetchProfile: Trying fallback endpoint: $path ===');
        response = await _dio.get(path);

        if (response.statusCode == 200 &&
            response.data != null &&
            response.data is Map<String, dynamic>) {
          final data = response.data;
          Map<String, dynamic> jsonData = data as Map<String, dynamic>;

          // Unwrap if nested under 'user', 'data', or 'doctor'
          if (jsonData.containsKey('user') && jsonData['user'] is Map) {
            jsonData = Map<String, dynamic>.from(jsonData['user']);
          } else if (jsonData.containsKey('data') && jsonData['data'] is Map) {
            jsonData = Map<String, dynamic>.from(jsonData['data']);
          } else if (jsonData.containsKey('doctor') &&
              jsonData['doctor'] is Map) {
            jsonData = Map<String, dynamic>.from(jsonData['doctor']);
          }

          print('=== fetchProfile: Fallback endpoint $path succeeded ===');
          final profile = DoctorProfileModel.fromJson(jsonData);
          // NO CACHING - Return fresh data directly
          return profile;
        }
      } catch (e) {
        print('=== fetchProfile: Fallback endpoint $path failed: $e ===');
        // Continue to next endpoint
      }
    }

    // FINAL FALLBACK: Return cached data only if API completely fails
    // This ensures the app doesn't crash, but users see stale data
    try {
      final cached = await getCachedProfile();
      if (cached.firstName != null && cached.firstName!.isNotEmpty) {
        print(
            '=== fetchProfile: All endpoints failed, returning cached profile ===');
        return cached;
      }
    } catch (_) {}

    throw Exception('لا يمكن تحميل البيانات، يرجى التحقق من الاتصال');
  }

  Future<DoctorProfileModel?> _getProfileFromToken() async {
    try {
      final token =
          await SharedPrefHelper.getSecuredString(SharedPrefKeys.userToken);
      if (token == null || token.isEmpty) return null;

      final parts = token.split('.');
      if (parts.length != 3) return null;

      // Base64Url decode the payload part (index 1)
      String payload = parts[1];
      // Add padding if needed
      while (payload.length % 4 != 0) {
        payload += '=';
      }

      final Map<String, dynamic> decoded =
          json.decode(utf8.decode(base64Url.decode(payload)));

      return DoctorProfileModel(
        id: int.tryParse(decoded['id']?.toString() ?? ''),
        firstName: (decoded['firstName'] ?? decoded['first_name'])?.toString(),
        lastName: (decoded['lastName'] ?? decoded['last_name'])?.toString(),
        email: decoded['email']?.toString() ?? decoded['sub']?.toString(),
        phone: (decoded['phoneNumber'] ?? decoded['phone'])?.toString(),
        faculty: (decoded['universityName'] ?? decoded['faculty'])?.toString(),
        year: (decoded['studyYear'] ?? decoded['year'])?.toString(),
        governorate:
            (decoded['cityName'] ?? decoded['governorate'])?.toString(),
        category: (decoded['categoryName'] ?? decoded['category'])?.toString(),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _cacheProfileLocally(DoctorProfileModel profile) async {
    // لا تحفظ الـ ID - التوكن هو المصدر الوحيد للهوية
    if (profile.firstName != null)
      await SharedPrefHelper.setData('first_name', profile.firstName!);
    if (profile.lastName != null)
      await SharedPrefHelper.setData('last_name', profile.lastName!);
    if (profile.email != null)
      await SharedPrefHelper.setData('email', profile.email!);
    if (profile.phone != null)
      await SharedPrefHelper.setData('phone', profile.phone!);
    if (profile.faculty != null)
      await SharedPrefHelper.setData('faculty', profile.faculty!);
    if (profile.year != null)
      await SharedPrefHelper.setData('year', profile.year!);
    if (profile.governorate != null)
      await SharedPrefHelper.setData('governorate', profile.governorate!);
    if (profile.category != null)
      await SharedPrefHelper.setData('category', profile.category!);
  }

  Future<DoctorProfileModel> getCachedProfile() async {
    final cachedFirst = await SharedPrefHelper.getString('first_name');
    final cachedLast = await SharedPrefHelper.getString('last_name');
    final cachedEmail = await SharedPrefHelper.getString('email');
    final cachedPhone = await SharedPrefHelper.getString('phone');
    final cachedFaculty = await SharedPrefHelper.getString('faculty');
    final cachedYear = await SharedPrefHelper.getString('year');
    final cachedGov = await SharedPrefHelper.getString('governorate');
    final cachedCat = await SharedPrefHelper.getString('category');

    return DoctorProfileModel(
      id: null,
      // لا نحفظ الـ ID - التوكن كافي
      firstName: cachedFirst,
      lastName: cachedLast,
      email: cachedEmail,
      phone: cachedPhone,
      faculty: cachedFaculty,
      year: cachedYear,
      governorate: cachedGov,
      category: cachedCat,
    );
  }

  Future<void> updateProfile(Map<String, dynamic> body) async {
    // NO CACHING - Just call the API to update the profile
    // The UI will handle displaying the updated data without caching it
    final result = await getIt<ApiService>().updateDoctor(body);
    if (result['success'] != true) {
      throw Exception(result['error']?.toString() ?? 'فشل تحديث البيانات');
    }
    // Profile updated successfully - no caching, fresh data will be fetched when needed
  }

  Future<List<UniversityModel>> getUniversities() async {
    final result = await getIt<ApiService>().getUniversities();
    if (result['success'] == true) {
      return result['data'] as List<UniversityModel>;
    }
    throw Exception(result['error'] ?? 'فشل في تحميل قائمة الجامعات');
  }

  Future<List<CityModel>> getCities() async {
    final result = await getIt<ApiService>().getCities();
    if (result['success'] == true) {
      return result['data'] as List<CityModel>;
    }
    throw Exception(result['error'] ?? 'فشل في تحميل قائمة المدن');
  }

  Future<List<CategoryModel>> getCategories() async {
    final result = await getIt<ApiService>().getCategories();
    if (result['success'] == true) {
      return result['data'] as List<CategoryModel>;
    }
    throw Exception(result['error'] ?? 'فشل في تحميل قائمة التخصصات');
  }
}
