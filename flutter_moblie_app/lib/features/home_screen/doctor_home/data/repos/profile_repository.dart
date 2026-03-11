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

  /// Centralized logic to fetch profile with fallbacks and strict model parsing
  Future<DoctorProfileModel> fetchProfile() async {
    Response? response;
    // Ordered by specificity
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
        response = await _dio.get(path);

        // Ensure we actually got JSON data
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

          final profile = DoctorProfileModel.fromJson(jsonData);
          await _cacheProfileLocally(profile);
          return profile;
        }
      } catch (_) {
        // Continue to next endpoint
      }
    }

    // FINAL FALLBACK: Decode the JWT token if API fails.
    // Only use token data for fields that are NOT already cached locally
    // to avoid overwriting freshly saved data with stale JWT values.
    try {
      final tokenProfile = await _getProfileFromToken();
      if (tokenProfile != null) {
        final cached = await getCachedProfile();
        // Merge: prefer local cache over JWT (cache has latest saved values)
        final merged = DoctorProfileModel(
          id: tokenProfile.id ?? cached.id,
          firstName: (cached.firstName?.isNotEmpty == true)
              ? cached.firstName
              : tokenProfile.firstName,
          lastName: (cached.lastName?.isNotEmpty == true)
              ? cached.lastName
              : tokenProfile.lastName,
          email: (cached.email?.isNotEmpty == true)
              ? cached.email
              : tokenProfile.email,
          phone: (cached.phone?.isNotEmpty == true)
              ? cached.phone
              : tokenProfile.phone,
          faculty: (cached.faculty?.isNotEmpty == true)
              ? cached.faculty
              : tokenProfile.faculty,
          year: (cached.year?.isNotEmpty == true)
              ? cached.year
              : tokenProfile.year,
          governorate: (cached.governorate?.isNotEmpty == true)
              ? cached.governorate
              : tokenProfile.governorate,
          category: (cached.category?.isNotEmpty == true)
              ? cached.category
              : tokenProfile.category,
        );
        await _cacheProfileLocally(merged);
        return merged;
      }
    } catch (_) {}

    // If everything fails, try to return cached data instead of throwing
    final cached = await getCachedProfile();
    if (cached.firstName != null && cached.firstName!.isNotEmpty) {
      return cached;
    }

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
    if (profile.id != null)
      await SharedPrefHelper.setData('doctor_id', profile.id!);
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
    final result = await getIt<ApiService>().updateDoctor(body);
    if (result['success'] == true) {
      // Sync with local cache so drawer and home see the updates immediately
      final updatedProfile = DoctorProfileModel(
        firstName: body['firstName']?.toString(),
        lastName: body['lastName']?.toString(),
        email: body['email']?.toString(),
        phone: body['phoneNumber']?.toString(),
        faculty: body['universityName']?.toString(),
        year: body['studyYear']?.toString(),
        governorate: body['cityName']?.toString(),
      );
      await _cacheProfileLocally(updatedProfile);
    } else {
      throw Exception(result['error']?.toString() ?? 'فشل تحديث البيانات');
    }
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
