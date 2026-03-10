import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:thotha_mobile_app/features/home_screen/doctor_home/data/models/doctor_profile_model.dart';
import 'package:dio/dio.dart';

part 'profile_state.freezed.dart';

@freezed
class ProfileState<T> with _$ProfileState<T> {
  const factory ProfileState.initial() = _Initial;
  
  // Represents "Stale-While-Revalidate" state (loading but showing cached data)
  const factory ProfileState.loading({DoctorProfileModel? cachedData}) = Loading<T>;
  
  const factory ProfileState.success(T data) = Success<T>;
  
  const factory ProfileState.error({required String error, required DioExceptionType? type}) = Error;
}
