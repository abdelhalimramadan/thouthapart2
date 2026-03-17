import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:thotha_mobile_app/features/appointments/data/appointments_service.dart';
import 'package:thotha_mobile_app/features/appointments/data/models/appointment_model.dart';
import 'package:thotha_mobile_app/features/appointments/logic/appointments_state.dart';

class AppointmentsCubit extends Cubit<AppointmentsState> {
  final AppointmentsService _appointmentsService;

  AppointmentsCubit(this._appointmentsService) : super(AppointmentsInitial());

  Future<void> loadAppointmentsByDoctorId(int doctorId) async {
    emit(AppointmentsLoading());
    
    try {
      final result = await _appointmentsService.getAppointmentsByDoctorId(doctorId);
      
      if (result['success'] == true) {
        final appointments = _appointmentsService.parseAppointmentsFromResponse(result);
        emit(AppointmentsLoaded(appointments));
      } else {
        emit(AppointmentsError(result['error'] ?? 'فشل في تحميل المواعيد'));
      }
    } catch (e) {
      emit(AppointmentsError('حدث خطأ غير متوقع: ${e.toString()}'));
    }
  }

  Future<void> createAppointment({

    required String firstName,
    required String lastName,
    required String phone,
    required String requestId,
  }) async {
    emit(AppointmentsLoading());
    
    try {
      final result = await _appointmentsService.createAppointment(
        requestId: requestId,
        patientFirstName: firstName,
        patientLastName: lastName,
        patientPhoneNumber: phone,
      );
      
      if (result['success'] == true) {
        emit(AppointmentsLoaded([])); // Success, but no appointments to show
      } else {
        emit(AppointmentsError(result['error'] ?? 'فشل في إنشاء الحجز'));
      }
    } catch (e) {
      emit(AppointmentsError('حدث خطأ غير متوقع: ${e.toString()}'));
    }
  }

  Future<void> cancelAppointment(String appointmentId, int doctorId) async {
    emit(AppointmentsLoading());
    try {
      final result = await _appointmentsService.cancelAppointment(appointmentId);
      if (result['success'] == true) {
        // Automatically reload after cancelling
        await loadAppointmentsByDoctorId(doctorId);
      } else {
        emit(AppointmentsError(result['error'] ?? 'فشل في إلغاء الحجز'));
      }
    } catch (e) {
      emit(AppointmentsError('حدث خطأ غير متوقع: ${e.toString()}'));
    }
  }

  void refreshAppointments(int doctorId) {
    loadAppointmentsByDoctorId(doctorId);
  }
}
