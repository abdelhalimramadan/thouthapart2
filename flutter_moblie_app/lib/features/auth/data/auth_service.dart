import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:thotha_mobile_app/core/helpers/constants.dart';
import 'package:thotha_mobile_app/core/helpers/shared_pref_helper.dart';
import 'package:thotha_mobile_app/core/networking/api_constants.dart';
import 'package:thotha_mobile_app/core/networking/dio_factory.dart';

class AuthService {
  final Dio _dio = DioFactory.getDio();

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      // Validate input
      if (email.isEmpty || password.isEmpty) {
        return {
          'success': false,
          'error': 'البريد الإلكتروني وكلمة المرور مطلوبان',
          'statusCode': 400,
        };
      }

      // Make the API request
      final response = await _dio.post(
        '${ApiConstants.baseUrl}/api/auth/login/doctor',
        data: {
          'email': email.trim(),
          'password': password,
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          validateStatus: (status) =>
              status! < 500, // Handle 4xx errors manually
        ),
      );

      // Handle successful response
      if (response.statusCode == 200) {
        // Prefer token from API when available, otherwise generate
        // one compatible with the Flask backend (base64(email)).
        String? token = response.data['token'];
        if (token == null || token.isEmpty) {
          token = base64Encode(utf8.encode(email.trim()));
        }

        // Save token securely and set header for subsequent requests
        await SharedPrefHelper.setSecuredString(
            SharedPrefKeys.userToken, token);
        DioFactory.setTokenIntoHeaderAfterLogin(token);

        // Always save the email used for login to support fallback
        await SharedPrefHelper.setData('email', email);

        // Try to persist user's name/email from the login response if available
        try {
          final data = response.data;
          String? f;
          String? l;
          String? e;
          String? p;
          String? y;
          String? g;
          String? fa;
          String? c;

          if (data is Map) {
            // Common shapes: top-level or nested under 'user'
            Map? userMap;
            if (data['user'] is Map) {
              userMap = data['user'] as Map;
            } else {
              userMap = data;
            }

            f = (userMap['first_name'] ?? userMap['firstName']) as String?;
            l = (userMap['last_name'] ?? userMap['lastName']) as String?;
            e = (userMap['email']) as String?;
            p = (userMap['phone'] ?? userMap['tel'])?.toString();
            y = (userMap['year'] ?? userMap['study_year']) as String?;
            g = (userMap['governorate'] ?? userMap['city']) as String?;
            fa = (userMap['faculty'] ?? userMap['college']) as String?;
            c = (userMap['category'] ?? userMap['specialization'])?.toString();

            if (f != null && f.isNotEmpty) {
              await SharedPrefHelper.setData('first_name', f);
              await SharedPrefHelper.setData('last_name', l ?? '');
              if (e != null && e.isNotEmpty) await SharedPrefHelper.setData('email', e);
              if (p != null && p.isNotEmpty) await SharedPrefHelper.setData('phone', p);
              if (y != null && y.isNotEmpty) await SharedPrefHelper.setData('year', y);
              if (g != null && g.isNotEmpty) await SharedPrefHelper.setData('governorate', g);
              if (fa != null && fa.isNotEmpty) await SharedPrefHelper.setData('faculty', fa);
              if (c != null && c.isNotEmpty) await SharedPrefHelper.setData('category', c);
            }
          }
        } catch (_) {
          // ignore persistence failures; UI can fallback to /me
        }

        return {
          'success': true,
          'data': response.data,
          'token': token,
        };
      }

      // Handle error responses
      return {
        'success': false,
        'error': _getErrorMessage(response.statusCode, response.data),
        'statusCode': response.statusCode,
      };
    } on DioException catch (e) {
      // Handle Dio errors (network errors, etc.)
      return {
        'success': false,
        'error': _handleDioError(e),
        'statusCode': e.response?.statusCode ?? 500,
      };
    } catch (e) {
      // Handle any other errors
      return {
        'success': false,
        'error': 'حدث خطأ غير متوقع. الرجاء المحاولة مرة أخرى',
        'statusCode': 500,
      };
    }
  }

  String _getErrorMessage(int? statusCode, dynamic responseData) {
    switch (statusCode) {
      case 400:
        return 'بيانات الدخول غير صحيحة';
      case 401:
        return 'البريد الإلكتروني أو كلمة المرور غير صحيحة';
      case 403:
        return 'غير مصرح لك بالدخول';
      case 404:
        return 'الحساب غير موجود';
      case 422:
        // Handle validation errors from the server
        if (responseData is Map && responseData['errors'] != null) {
          return responseData['errors'].values.first[0] ?? 'بيانات غير صالحة';
        }
        return 'بيانات غير صالحة';
      default:
        return 'حدث خطأ في الخادم. الرجاء المحاولة مرة أخرى';
    }
  }

  String _handleDioError(DioException e) {
    print('Dio Error: ${e.message}');
    print('Error Type: ${e.type}');
    if (e.response != null) {
      print('Response Status: ${e.response?.statusCode}');
      print('Response Data: ${e.response?.data}');
    }

    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return 'انتهت مهلة الاتصال بالخادم. الرجاء التحقق من اتصالك بالإنترنت';
    } else if (e.type == DioExceptionType.connectionError) {
      return 'تعذر الاتصال بالخادم. الرجاء التحقق من اتصالك بالإنترنت';
    } else if (e.response != null) {
      return _getErrorMessage(e.response?.statusCode, e.response?.data);
    } else {
      return 'حدث خطأ غير متوقع. الرجاء المحاولة مرة أخرى';
    }
  }

  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String confirm,
    required String first_name,
    required String last_name,
    required String phone,
    required String faculty,
    required String year,
    required String governorate,
  }) async {
    try {
      if (email.isEmpty ||
          password.isEmpty ||
          first_name.isEmpty ||
          last_name.isEmpty ||
          phone.isEmpty ||
          faculty.isEmpty ||
          year.isEmpty ||
          governorate.isEmpty ||
          confirm.isEmpty) {
        return {
          'success': false,
          'error': 'البريد الإلكتروني وكلمة المرور مطلوبان',
          'statusCode': 400,
        };
      }

      if (password.length <= 6) {
        return {
          'success': false,
          'error': 'يجب أن تكون كلمة المرور 6 أحرف على الأقل',
          'statusCode': 400,
        };
      }

      final response = await _dio.post(
        '${ApiConstants.baseUrl}/register',
        data: {
          'email': email.trim(),
          'password': password,
          'faculty': faculty,
          'first_name': first_name,
          'last_name': last_name,
          'governorate': governorate,
          'year': year,
          'phone': phone,
          'confirm_password': confirm,
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
          validateStatus: (status) => status! < 500,
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Persist provided user info so UI can greet correctly after signup
        try {
          if (first_name.isNotEmpty) {
            await SharedPrefHelper.setData('first_name', first_name);
            await SharedPrefHelper.setData('last_name', last_name);
            await SharedPrefHelper.setData('email', email.trim());
            await SharedPrefHelper.setData('phone', phone);
            await SharedPrefHelper.setData('faculty', faculty);
            await SharedPrefHelper.setData('year', year);
            await SharedPrefHelper.setData('governorate', governorate);
          }
        } catch (_) {}

        return {
          'success': true,
          'data': response.data,
          'message': 'تم إنشاء الحساب بنجاح',
        };
      } else {
        // Handle different error status codes
        String errorMessage = 'حدث خطأ في التسجيل';
        if (response.statusCode == 400) {
          errorMessage = response.data?['message'] ?? 'بيانات غير صالحة';
        } else if (response.statusCode == 409) {
          errorMessage = 'هذا البريد الإلكتروني مسجل مسبقاً';
        }

        return {
          'success': false,
          'error': errorMessage,
          'statusCode': response.statusCode,
        };
      }
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data?['message'] ??
            'تعذر الاتصال بالخادم. يرجى المحاولة مرة أخرى',
        'statusCode': e.response?.statusCode,
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'حدث خطأ غير متوقع: ${e.toString()}',
      };
    }
  }
}
