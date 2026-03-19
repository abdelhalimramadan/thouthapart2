import 'package:get_it/get_it.dart';
import 'package:thotha_mobile_app/core/networking/api_service.dart';
import 'package:thotha_mobile_app/features/home_screen/data/repositories/doctor_repository.dart';
import 'package:thotha_mobile_app/features/home_screen/data/repositories/case_request_repo.dart';
import 'package:thotha_mobile_app/features/home_screen/logic/doctor_cubit.dart';
import 'package:thotha_mobile_app/features/notifications/data/repos/notification_repo.dart';
import 'package:thotha_mobile_app/features/home_screen/doctor_home/data/repos/profile_repository.dart';
import 'package:thotha_mobile_app/features/home_screen/doctor_home/logic/profile_cubit.dart';
import 'package:thotha_mobile_app/features/home_screen/doctor_home/logic/my_requests_cubit.dart';
import 'package:thotha_mobile_app/features/chat/data/chat_repo.dart';
import 'package:thotha_mobile_app/features/chat/logic/chat_cubit.dart';

final getIt = GetIt.instance;

Future<void> setupGetIt() async {
  // Services
  getIt.registerLazySingleton<ApiService>(() => ApiService());

  // Repositories
  getIt.registerLazySingleton<DoctorRepository>(
    () => DoctorRepository(getIt()),
  );
  getIt.registerLazySingleton<CaseRequestRepo>(
    () => CaseRequestRepo(getIt()),
  );
  getIt.registerLazySingleton<INotificationRepo>(
    () => NotificationRepo(),
  );
  getIt.registerLazySingleton<ProfileRepository>(
    () => ProfileRepository(),
  );
  getIt.registerLazySingleton<ChatRepo>(
    () => ChatRepo(getIt()),
  );

  // Cubits
  getIt.registerFactory<DoctorCubit>(
    () => DoctorCubit(getIt()),
  );
  getIt.registerFactory<ProfileCubit>(
    () => ProfileCubit(getIt()),
  );
  getIt.registerFactory<MyRequestsCubit>(
    () => MyRequestsCubit(getIt()),
  );
  getIt.registerFactory<ChatCubit>(
    () => ChatCubit(getIt()),
  );
}
