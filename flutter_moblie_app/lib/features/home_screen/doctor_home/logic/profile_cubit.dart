import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';
import 'package:thotha_mobile_app/features/home_screen/doctor_home/logic/profile_state.dart';
import 'package:thotha_mobile_app/features/home_screen/doctor_home/data/repos/profile_repository.dart';
import 'package:thotha_mobile_app/features/home_screen/doctor_home/data/models/doctor_profile_model.dart';

class ProfileCubit extends Cubit<ProfileState<DoctorProfileModel>> {
  final ProfileRepository _repository;

  ProfileCubit(this._repository) : super(const ProfileState.initial());

  /// Implements Stale-While-Revalidate caching strategy
  Future<void> fetchProfile() async {
    // 1. Instantly load cached data to improve perceived performance
    final cachedProfile = await _repository.getCachedProfile();
    emit(ProfileState.loading(cachedData: cachedProfile));

    // 2. Fetch fresh data silently in background
    try {
      final freshProfile = await _repository.fetchProfile();
      emit(ProfileState.success(freshProfile));
    } on DioException catch (e) {
      emit(ProfileState.error(
        error: _getErrorMessage(e),
        type: e.type,
      ));
    } catch (e) {
      emit(ProfileState.error(
        error: "حدث خطأ غير متوقع",
        type: null,
      ));
    }
  }

  String _getErrorMessage(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return "انتهت مهلة الاتصال. تحقق من جودة الإنترنت وحاول مرة أخرى.";
    } else if (e.type == DioExceptionType.connectionError) {
      return "لا يمكن الاتصال بالخادم. تحقق من اتصالك بالإنترنت.";
    } else if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
      return "يرجى تسجيل الدخول مرة أخرى.";
    }
    return "لا يمكن تحميل البيانات، يرجى المحاولة لاحقاً.";
  }
}
