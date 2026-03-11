import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';
import 'package:thotha_mobile_app/core/networking/models/city_model.dart';
import 'package:thotha_mobile_app/core/networking/models/university_model.dart';
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

    // 2. Fetch fresh data (Profile, Universities, Cities)
    try {
      final results = await Future.wait([
        _repository.fetchProfile(),
        _repository.getUniversities(),
        _repository.getCities(),
      ]);

      final freshProfile = results[0] as DoctorProfileModel;
      final universities = results[1] as List<UniversityModel>;
      final cities       = results[2] as List<CityModel>;

      emit(ProfileState.success(
        freshProfile,
        universities: universities,
        cities: cities,
      ));
    } on DioException catch (e) {
      emit(ProfileState.error(
        error: _getErrorMessage(e),
        type: e.type,
      ));
    } catch (e) {
      emit(ProfileState.error(
        error: e.toString().contains('Exception:') 
            ? e.toString().split('Exception:').last.trim() 
            : "حدث خطأ غير متوقع",
        type: null,
      ));
    }
  }

  Future<void> updateProfile(Map<String, dynamic> body) async {
    emit(ProfileState.loading(cachedData: state.whenOrNull(
      success: (data, universities, cities) => data,
      loading: (cachedData, universities, cities) => cachedData,
    )));
    try {
      await _repository.updateProfile(body);
      
      // Get current dropdown lists to preserve them in the success state
      final currentUniversities = state.maybeWhen(
        success: (_, u, c) => u,
        loading: (_, u, c) => u,
        orElse: () => <UniversityModel>[],
      );
      final currentCities = state.maybeWhen(
        success: (_, u, c) => c,
        loading: (_, u, c) => c,
        orElse: () => <CityModel>[],
      );

      final freshProfile = await _repository.fetchProfile();
      emit(ProfileState.success(
        freshProfile,
        universities: currentUniversities,
        cities: currentCities,
      ));
    } on DioException catch (e) {
      emit(ProfileState.error(
        error: _getErrorMessage(e),
        type: e.type,
      ));
    } catch (e) {
      emit(ProfileState.error(
        error: e.toString().contains('Exception:') 
            ? e.toString().split('Exception:').last.trim() 
            : "حدث خطأ أثناء تحديث البيانات: $e",
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
