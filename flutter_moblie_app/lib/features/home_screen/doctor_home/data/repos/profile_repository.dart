import 'package:dio/dio.dart';
import 'package:thotha_mobile_app/core/helpers/shared_pref_helper.dart';
import 'package:thotha_mobile_app/core/networking/dio_factory.dart';
import 'package:thotha_mobile_app/features/home_screen/doctor_home/data/models/doctor_profile_model.dart';

class ProfileRepository {
  final Dio _dio = DioFactory.getDio();

  /// Centralized logic to fetch profile with fallbacks and strict model parsing
  Future<DoctorProfileModel> fetchProfile() async {
    Response? response;
    DioException? lastError;
    bool validJsonResponseFound = false;

    // Ordered by specificity as requested in the plan
    final endpoints = ['/api/auth/profile', '/api/user/me', '/profile', '/me', '/update_profile'];

    for (final path in endpoints) {
      try {
        if (path == '/update_profile') {
           response = await _dio.post(path, data: {});
        } else {
           response = await _dio.get(path);
        }
        
        // Ensure we actually got JSON data, not an HTML page fallback (like a 200 OK Cloudflare page)
        if (response.statusCode == 200 && response.data != null && response.data is Map<String, dynamic>) {
          validJsonResponseFound = true;
          break; // Success! We found the correct JSON endpoint.
        }
      } on DioException catch (e) {
        lastError = e;
        continue; // Fallback to next endpoint
      }
    }

    if (validJsonResponseFound && response != null) {
      final data = response.data;
      Map<String, dynamic> jsonData = data as Map<String, dynamic>;
      if (jsonData.containsKey('user') && jsonData['user'] is Map) {
        jsonData = Map<String, dynamic>.from(jsonData['user']);
      }
      final profile = DoctorProfileModel.fromJson(jsonData);
      await _cacheProfileLocally(profile);
      return profile;
    }

    if (lastError != null) {
      throw lastError; // Let cubit handle specific network error
    } else {
      throw Exception('Failed to load profile: Endpoints did not return valid JSON data. Check Network/API Paths.');
    }
  }

  Future<void> _cacheProfileLocally(DoctorProfileModel profile) async {
    if (profile.id != null) await SharedPrefHelper.setData('doctor_id', profile.id!);
    if (profile.firstName != null) await SharedPrefHelper.setData('first_name', profile.firstName!);
    if (profile.lastName != null) await SharedPrefHelper.setData('last_name', profile.lastName!);
    if (profile.email != null) await SharedPrefHelper.setData('email', profile.email!);
    if (profile.phone != null) await SharedPrefHelper.setData('phone', profile.phone!);
    if (profile.faculty != null) await SharedPrefHelper.setData('faculty', profile.faculty!);
    if (profile.year != null) await SharedPrefHelper.setData('year', profile.year!);
    if (profile.governorate != null) await SharedPrefHelper.setData('governorate', profile.governorate!);
    if (profile.category != null) await SharedPrefHelper.setData('category', profile.category!);
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
}
