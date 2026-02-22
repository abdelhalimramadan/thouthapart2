import 'package:bloc/bloc.dart';
import 'package:dio/dio.dart';
import 'package:meta/meta.dart';
import 'package:thotha_mobile_app/core/helpers/phone_helper.dart';
import 'package:thotha_mobile_app/core/networking/api_constants.dart';
import 'package:thotha_mobile_app/core/networking/otp_service.dart';

part 'sign_up_state.dart';

class SignUpCubit extends Cubit<SignUpState> {
  final OtpService _otpService = OtpService();

  SignUpCubit() : super(SignUpInitial());

  Future<void> signUp({
    required String email,
    required String password,
    String? firstName,
    String? lastName,
    String? phone,
    String? college,
    String? studyYear,
    String? governorate,
    String? category,
  }) async {
    try {
      emit(SignUpLoading());

      // Basic validation
      if (email.isEmpty || password.isEmpty) {
        emit(SignUpError('البريد الإلكتروني وكلمة المرور مطلوبان'));
        return;
      }

      if (password.length < 6) {
        emit(SignUpError('يجب أن تكون كلمة المرور 6 أحرف على الأقل'));
        return;
      }

      // Normalize phone number using PhoneHelper (no + prefix)
      String? formattedPhone =
          phone != null ? PhoneHelper.normalizeEgyptPhone(phone) : null;

      // Create a fresh Dio instance WITHOUT Authorization header
      // This ensures NO Bearer token is sent for signup
      final authDio = Dio(
        BaseOptions(
          baseUrl: ApiConstants.baseUrl,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          validateStatus: (status) => status! < 500,
        ),
      );

      // Prepare the request data with correct field names matching backend
      // IMPORTANT: Send NAMES (strings), NOT IDs (integers)
      final requestData = {
        'email': email.trim().toLowerCase(),
        'password': password.trim(),
        if (firstName != null && firstName.trim().isNotEmpty)
          'firstName': firstName.trim(),
        if (lastName != null && lastName.trim().isNotEmpty)
          'lastName': lastName.trim(),
        if (formattedPhone != null)
          'phoneNumber': formattedPhone,
        if (college != null && college.trim().isNotEmpty)
          'universityName': college.trim(),
        if (studyYear != null && studyYear.trim().isNotEmpty)
          'studyYear': studyYear.trim(),
        if (governorate != null && governorate.trim().isNotEmpty)
          'cityName': governorate.trim(),
        if (category != null && category.trim().isNotEmpty)
          'categoryName': category.trim(),
      };

      print('✅ SignUp Request URL: ${ApiConstants.baseUrl}/api/auth/signup');
      print('✅ SignUp Request Data: $requestData');
      print('✅ SignUp Headers: Content-Type=application/json (NO Authorization)');

      // Send POST request WITHOUT Authorization header
      final response = await authDio.post(
        '/api/auth/signup',
        data: requestData,
      );

      print('✅ SignUp Response Status: ${response.statusCode}');
      print('✅ SignUp Response Data: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Extract token from response
        String? token;
        if (response.data is Map) {
          token = response.data['token'] ?? response.data['accessToken'];
        }

        // Signup successful, now send OTP to phone number
        if (formattedPhone != null) {
          final otpResult = await _otpService.sendOtp(formattedPhone);

          if (otpResult['success']) {
            emit(SignUpOtpSent(
              phoneNumber: formattedPhone,
              email: email.trim(),
              message: otpResult['message'] ?? 'تم إرسال رمز التحقق',
            ));
          } else {
            emit(SignUpError(
              'تم إنشاء الحساب لكن فشل إرسال رمز التحقق. يرجى تسجيل الدخول.',
            ));
          }
        } else {
          // No phone number, just emit success
          emit(SignUpSuccess(token ?? '', message: 'تم التسجيل بنجاح'));
        }
      } else {
        // Handle error responses
        String errorMessage = 'حدث خطأ في التسجيل';

        if (response.data != null) {
          if (response.data is List) {
            // Backend returns array of errors
            final errors = response.data as List;
            if (errors.isNotEmpty) {
              errorMessage = errors
                  .map((e) => e['messageAr'] ?? e['messageEn'] ?? '')
                  .where((msg) => msg.isNotEmpty)
                  .join('\n');
            }
          } else if (response.data is Map) {
            errorMessage = response.data['messageAr'] ??
                response.data['messageEn'] ??
                response.data['message'] ??
                response.data['error'] ??
                'حدث خطأ في التسجيل';
          }
        }

        if (response.statusCode == 409) {
          errorMessage = 'هذا البريد الإلكتروني مسجل مسبقاً';
        }

        emit(SignUpError(errorMessage));
      }
    } on DioException catch (e) {
      String errorMessage = 'حدث خطأ في الاتصال بالخادم';

      if (e.response != null) {
        if (e.response!.data is List) {
          final errors = e.response!.data as List;
          if (errors.isNotEmpty) {
            errorMessage = errors
                .map((e) => e['messageAr'] ?? e['messageEn'] ?? '')
                .where((msg) => msg.isNotEmpty)
                .join('\n');
          }
        } else if (e.response!.data is Map) {
          errorMessage = e.response!.data['messageAr'] ??
              e.response!.data['messageEn'] ??
              e.response!.data['message'] ??
              'بيانات غير صالحة';
        }

        if (e.response!.statusCode == 409) {
          errorMessage = 'هذا البريد الإلكتروني مسجل مسبقاً';
        }
      } else if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        errorMessage = 'انتهت مهلة الاتصال بالخادم';
      } else if (e.type == DioExceptionType.unknown) {
        errorMessage = 'لا يوجد اتصال بالإنترنت';
      }

      emit(SignUpError(errorMessage));
    } catch (e) {
      emit(SignUpError('حدث خطأ غير متوقع: ${e.toString()}'));
    }
  }
}
