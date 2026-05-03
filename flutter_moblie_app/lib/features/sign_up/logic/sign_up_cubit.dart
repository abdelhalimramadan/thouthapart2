import 'package:bloc/bloc.dart';
import 'package:dio/dio.dart';
import 'package:meta/meta.dart';
import 'package:thoutha_mobile_app/core/helpers/phone_helper.dart';
import 'package:thoutha_mobile_app/core/networking/api_constants.dart';
import 'package:thoutha_mobile_app/core/networking/otp_service.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;

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
    String? confirmPassword,
  }) async {
    try {
      emit(SignUpLoading());

      // Basic validation
      if (email.isEmpty || password.isEmpty) {
        emit(SignUpError('sign_up.email_and_password_are'.tr()));
        return;
      }

      if (password.length < 6) {
        emit(SignUpError('login.password_must_be_at'.tr()));
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
          connectTimeout: Duration(seconds: 15),
          receiveTimeout: Duration(seconds: 15),
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
        if (formattedPhone != null) 'phoneNumber': formattedPhone,
        if (college != null && college.trim().isNotEmpty)
          'universityName': college.trim(),
        if (studyYear != null && studyYear.trim().isNotEmpty)
          'studyYear': studyYear.trim(),
        if (governorate != null && governorate.trim().isNotEmpty)
          'cityName': governorate.trim(),
        if (category != null && category.trim().isNotEmpty)
          'categoryName': category.trim(),
        if (confirmPassword != null && confirmPassword.trim().isNotEmpty)
          'confirmPassword': confirmPassword.trim(),
      };

      print('✅ SignUp Request URL: ${ApiConstants.baseUrl}/api/auth/signup');
      print('✅ SignUp Request Data: $requestData');
      print(
          '✅ SignUp Headers: Content-Type=application/json (NO Authorization)');

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
              message: otpResult['message'] ?? 'sign_up.verification_code_has_been'.tr(),
            ));
          } else {
            emit(SignUpError(
              'sign_up.the_account_was_created'.tr(),
            ));
          }
        } else {
          // No phone number, just emit success
          emit(SignUpSuccess(token ?? '', message: 'sign_up.registration_completed_successfully'.tr()));
        }
      } else {
        // Handle error responses
        String errorMessage = 'sign_up.an_error_occurred_in'.tr();

        if (response.data != null) {
          if (response.data is List) {
            // Backend returns array of errors
            final errors = response.data as List;
            if (errors.isNotEmpty) {
              // Check if error is about email or phone
              String errorText = errors
                  .map((e) => e['messageAr'] ?? e['messageEn'] ?? '')
                  .where((msg) => msg.isNotEmpty)
                  .join('\n');

              // Detect email duplicate
              if (errorText.contains('email') ||
                  errorText.contains('sign_up.mail'.tr()) ||
                  errorText.contains('Email') ||
                  errorText.contains('sign_up.mail_1'.tr()) ||
                  errorText.contains('sign_up.existing'.tr()) ||
                  errorText.contains('sign_up.user'.tr()) ||
                  errorText.contains('sign_up.registered'.tr()) ||
                  errorText.contains('sign_up.repetition'.tr())) {
                errorMessage = 'sign_up.this_email_is_already'.tr();
              }
              // Detect phone duplicate
              else if (errorText.contains('phone') ||
                  errorText.contains('sign_up.telephone'.tr()) ||
                  errorText.contains('Phone') ||
                  errorText.contains('sign_up.phone'.tr()) ||
                  errorText.contains('sign_up.number'.tr()) ||
                  errorText.contains('doctor.phone_number'.tr()) ||
                  errorText.contains('phoneNumber')) {
                errorMessage = 'sign_up.the_phone_number_is'.tr();
              } else {
                errorMessage = errorText;
              }
            }
          } else if (response.data is Map) {
            final responseMap = response.data as Map;
            String rawMessage = responseMap['messageAr'] ??
                responseMap['messageEn'] ??
                responseMap['message'] ??
                responseMap['error'] ??
                'sign_up.an_error_occurred_in'.tr();

            // Detect email duplicate
            if (rawMessage.contains('email') ||
                rawMessage.contains('sign_up.mail'.tr()) ||
                rawMessage.contains('Email') ||
                rawMessage.contains('sign_up.mail_1'.tr()) ||
                rawMessage.contains('sign_up.user'.tr()) ||
                rawMessage.contains('sign_up.existing'.tr()) ||
                rawMessage.contains('sign_up.registered'.tr()) ||
                rawMessage.contains('sign_up.repetition'.tr()) ||
                rawMessage.contains('sign_up.find'.tr()) ||
                rawMessage.contains('sign_up.supplier'.tr())) {
              errorMessage = 'sign_up.this_email_is_already'.tr();
            }
            // Detect phone duplicate
            else if (rawMessage.contains('phone') ||
                rawMessage.contains('sign_up.telephone'.tr()) ||
                rawMessage.contains('Phone') ||
                rawMessage.contains('sign_up.phone'.tr()) ||
                rawMessage.contains('sign_up.number'.tr()) ||
                rawMessage.contains('doctor.phone_number'.tr()) ||
                rawMessage.contains('phoneNumber')) {
              errorMessage = 'sign_up.the_phone_number_is'.tr();
            } else {
              errorMessage = rawMessage;
            }
          }
        }

        // Status code 409 also means conflict (duplicate)
        if (response.statusCode == 409) {
          // Try to determine if it's email or phone from previous attempts
          // Default to email since it's more common
          errorMessage = 'sign_up.this_email_is_already'.tr();
        }

        // If message contains "No static resource found" or similar, it's likely a duplicate email
        if (errorMessage.contains('sign_up.static_resource_not_found'.tr()) ||
            errorMessage.contains('No static resource found') ||
            errorMessage.contains('doctor.fixed_resource'.tr())) {
          errorMessage = 'sign_up.this_email_is_already'.tr();
        }

        emit(SignUpError(errorMessage));
      }
    } on DioException catch (e) {
      String errorMessage = 'sign_up.an_error_occurred_connecting'.tr();

      if (e.response != null) {
        if (e.response!.data is List) {
          final errors = e.response!.data as List;
          if (errors.isNotEmpty) {
            // Check if error is about email or phone
            String errorText = errors
                .map((e) => e['messageAr'] ?? e['messageEn'] ?? '')
                .where((msg) => msg.isNotEmpty)
                .join('\n');

            // Detect email duplicate
            if (errorText.contains('email') ||
                errorText.contains('sign_up.mail'.tr()) ||
                errorText.contains('Email') ||
                errorText.contains('sign_up.mail_1'.tr()) ||
                errorText.contains('sign_up.existing'.tr()) ||
                errorText.contains('sign_up.user'.tr()) ||
                errorText.contains('sign_up.registered'.tr()) ||
                errorText.contains('sign_up.repetition'.tr())) {
              errorMessage = 'sign_up.this_email_is_already'.tr();
            }
            // Detect phone duplicate
            else if (errorText.contains('phone') ||
                errorText.contains('sign_up.telephone'.tr()) ||
                errorText.contains('Phone') ||
                errorText.contains('sign_up.phone'.tr()) ||
                errorText.contains('sign_up.number'.tr()) ||
                errorText.contains('doctor.phone_number'.tr()) ||
                errorText.contains('phoneNumber')) {
              errorMessage = 'sign_up.the_phone_number_is'.tr();
            } else {
              errorMessage = errorText;
            }
          }
        } else if (e.response!.data is Map) {
          final responseMap = e.response!.data as Map;
          String rawMessage = responseMap['messageAr'] ??
              responseMap['messageEn'] ??
              responseMap['message'] ??
              'sign_up.invalid_data'.tr();

          // Detect email duplicate
          if (rawMessage.contains('email') ||
              rawMessage.contains('sign_up.mail'.tr()) ||
              rawMessage.contains('Email') ||
              rawMessage.contains('sign_up.mail_1'.tr()) ||
              rawMessage.contains('sign_up.user'.tr()) ||
              rawMessage.contains('sign_up.existing'.tr()) ||
              rawMessage.contains('sign_up.registered'.tr()) ||
              rawMessage.contains('sign_up.repetition'.tr()) ||
              rawMessage.contains('sign_up.find'.tr()) ||
              rawMessage.contains('sign_up.supplier'.tr())) {
            errorMessage = 'sign_up.this_email_is_already'.tr();
          }
          // Detect phone duplicate
          else if (rawMessage.contains('phone') ||
              rawMessage.contains('sign_up.telephone'.tr()) ||
              rawMessage.contains('Phone') ||
              rawMessage.contains('sign_up.phone'.tr()) ||
              rawMessage.contains('sign_up.number'.tr()) ||
              rawMessage.contains('doctor.phone_number'.tr()) ||
              rawMessage.contains('phoneNumber')) {
            errorMessage = 'sign_up.the_phone_number_is'.tr();
          } else {
            errorMessage = rawMessage;
          }
        }

        // Status code 409 also means conflict (duplicate)
        if (e.response!.statusCode == 409) {
          errorMessage = 'sign_up.this_email_is_already'.tr();
        }

        // If message contains "No static resource found" or similar, it's likely a duplicate email
        if (errorMessage.contains('sign_up.static_resource_not_found'.tr()) ||
            errorMessage.contains('No static resource found') ||
            errorMessage.contains('doctor.fixed_resource'.tr())) {
          errorMessage = 'sign_up.this_email_is_already'.tr();
        }
      } else if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        errorMessage = 'sign_up.the_connection_to_the'.tr();
      } else if (e.type == DioExceptionType.unknown) {
        errorMessage = 'sign_up.no_internet_connection'.tr();
      }

      emit(SignUpError(errorMessage));
    } catch (e) {
      emit(SignUpError('حدث خطأ غير متوقع: ${e.toString()}'));
    }
  }
}
