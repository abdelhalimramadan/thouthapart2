import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:thotha_mobile_app/core/networking/api_service.dart';
import 'package:thotha_mobile_app/features/appointments/data/models/appointment_model.dart';
import 'package:thotha_mobile_app/features/appointments/logic/appointments_state.dart';

class AppointmentsCubit extends Cubit<AppointmentsState> {
  final ApiService _apiService;

  AppointmentsCubit(this._apiService) : super(const AppointmentsInitial());

  String _currentFilter = 'الكل';
  List<AppointmentModel> _allAppointments = [];

  Future<void> loadAppointments() async {
    emit(const AppointmentsLoading());

    final result = await _apiService.getAllAppointments();

    if (result['success'] == true) {
      final List<dynamic> data = result['data'] ?? [];
      _allAppointments = data
          .map((json) => AppointmentModel.fromJson(Map<String, dynamic>.from(json)))
          .toList();

      final filtered = _applyFilter(_allAppointments, _currentFilter);
      emit(AppointmentsLoaded(filtered, selectedFilter: _currentFilter));
    } else {
      emit(AppointmentsError(result['error'] ?? 'فشل في تحميل الحجوزات'));
    }
  }

  Future<void> loadAppointmentsByDoctorId(int doctorId) async {
    emit(const AppointmentsLoading());

    final result = await _apiService.getAppointmentsByDoctorId(doctorId);

    if (result['success'] == true) {
      final List<dynamic> data = result['data'] ?? [];
      _allAppointments = data
          .map((json) => AppointmentModel.fromJson(Map<String, dynamic>.from(json)))
          .toList();

      final filtered = _applyFilter(_allAppointments, _currentFilter);
      emit(AppointmentsLoaded(filtered, selectedFilter: _currentFilter));
    } else {
      emit(AppointmentsError(result['error'] ?? 'فشل في تحميل حجوزات الطبيب'));
    }
  }

  void setFilter(String filter) {
    _currentFilter = filter;
    final filtered = _applyFilter(_allAppointments, filter);
    emit(AppointmentsLoaded(filtered, selectedFilter: filter));
  }

  List<AppointmentModel> _applyFilter(List<AppointmentModel> appointments, String filter) {
    if (filter == 'الكل') {
      return appointments;
    }
    return appointments.where((appt) => appt.displayStatus == filter).toList();
  }

  Future<void> createAppointment({
    required int doctorId,
    required String doctorFirstName,
    required String doctorLastName,
    required String patientFirstName,
    required String patientLastName,
    required String patientPhoneNumber,
  }) async {
    emit(const AppointmentCreating());

    final body = {
      'doctorId': doctorId,
      'doctorFirstName': doctorFirstName,
      'doctorLastName': doctorLastName,
      'patientFirstName': patientFirstName,
      'patientLastName': patientLastName,
      'patientPhoneNumber': patientPhoneNumber,
    };

    final result = await _apiService.createAppointment(body);

    if (result['success'] == true) {
      emit(AppointmentCreated(result['data']));
      // Reload appointments after creation
      await loadAppointments();
    } else {
      emit(AppointmentCreateError(result['error'] ?? 'فشل في إنشاء الحجز'));
    }
  }

  Future<void> getAppointmentById(int id) async {
    emit(const AppointmentsLoading());

    final result = await _apiService.getAppointmentById(id);

    if (result['success'] == true) {
      final appointment = AppointmentModel.fromJson(Map<String, dynamic>.from(result['data']));
      emit(AppointmentCreated(appointment));
    } else {
      emit(AppointmentsError(result['error'] ?? 'فشل في تحميل تفاصيل الحجز'));
    }
  }
}
