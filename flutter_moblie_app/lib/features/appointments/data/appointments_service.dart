import 'package:thotha_mobile_app/core/networking/api_service.dart';
import 'package:thotha_mobile_app/features/appointments/data/models/appointment_model.dart';

class AppointmentsService {
  final ApiService _apiService;

  AppointmentsService(this._apiService);

  /// Create a new appointment for a request (no authentication required)
  Future<Map<String, dynamic>> createAppointment({
    required String requestId,
    required String patientFirstName,
    required String patientLastName,
    required String patientPhoneNumber,
  }) async {
    final appointmentData = {
      'patientFirstName': patientFirstName,
      'patientLastName': patientLastName,
      'patientPhoneNumber': patientPhoneNumber,
    };

    return await _apiService.createAppointment(requestId, appointmentData);
  }

  /// Get all appointments for a specific doctor (requires authentication)
  Future<Map<String, dynamic>> getAppointmentsByDoctorId(int doctorId) async {
    return await _apiService.viewAppointmentsByDoctor(doctorId.toString());
  }

  /// Cancel an appointment (requires authentication)
  Future<Map<String, dynamic>> cancelAppointment(String appointmentId) async {
    return await _apiService.cancelAppointment(appointmentId);
  }

  /// Convert API response to list of AppointmentModel objects
  List<AppointmentModel> parseAppointmentsFromResponse(Map<String, dynamic> response) {
    if (response['success'] != true) {
      return [];
    }

    final List<dynamic> appointmentsData = response['data'] ?? [];
    return appointmentsData
        .map((json) => AppointmentModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Get appointment status in Arabic
  String getAppointmentStatusDisplay(String? status) {
    switch (status?.toLowerCase()) {
      case 'confirmed':
      case 'مؤكد':
        return 'مؤكد';
      case 'pending':
      case 'قيد الانتظار':
        return 'قيد الانتظار';
      case 'cancelled':
      case 'ملغي':
        return 'ملغي';
      default:
        return status ?? 'قيد الانتظار';
    }
  }

  /// Get status color based on appointment status
  String getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'confirmed':
      case 'مؤكد':
        return 'green';
      case 'pending':
      case 'قيد الانتظار':
        return 'orange';
      case 'cancelled':
      case 'ملغي':
        return 'red';
      default:
        return 'grey';
    }
  }

  /// Format appointment date for display
  String formatAppointmentDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return '';
    
    try {
      final dateTime = DateTime.parse(dateString);
      return '${dateTime.day.toString().padLeft(2, '0')}/'
          '${dateTime.month.toString().padLeft(2, '0')}/'
          '${dateTime.year}';
    } catch (e) {
      return dateString;
    }
  }

  /// Format appointment time for display
  String formatAppointmentTime(String? timeString) {
    if (timeString == null || timeString.isEmpty) return '';
    
    try {
      final dateTime = DateTime.parse(timeString);
      return '${dateTime.hour.toString().padLeft(2, '0')}:'
          '${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return timeString;
    }
  }

  /// Validate appointment data before creation
  Map<String, String> validateAppointmentData({
    required String firstName,
    required String lastName,
    required String phone,
    String? patientId,
  }) {
    final errors = <String, String>{};

    if (firstName.trim().isEmpty) {
      errors['firstName'] = 'الرجاء إدخال الاسم الأول';
    }

    if (lastName.trim().isEmpty) {
      errors['lastName'] = 'الرجاء إدخال اسم العائلة';
    }

    if (phone.trim().isEmpty) {
      errors['phone'] = 'الرجاء إدخال رقم الجوال';
    } else {
      String cleanPhone = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
      
      if (cleanPhone.startsWith('01')) {
        if (cleanPhone.length != 11) {
          errors['phone'] = 'رقم الجوال المصري يجب أن يكون 11 رقم';
        } else if (!RegExp(r'^01[0-2]\d{8}$').hasMatch(cleanPhone)) {
          errors['phone'] = 'رقم الجوال المصري غير صحيح';
        }
      } else if (cleanPhone.startsWith('+20')) {
        if (cleanPhone.length != 13) {
          errors['phone'] = 'رقم الجوال المصري يجب أن يكون 13 رقم مع +20';
        } else if (!RegExp(r'^\+201[0-2]\d{8}$').hasMatch(cleanPhone)) {
          errors['phone'] = 'رقم الجوال المصري غير صحيح';
        }
      } else {
        errors['phone'] = 'الرجاء إدخال رقم جوال مصري صحيح';
      }
    }

    // PatientId is optional, but if provided, it should be valid
    if (patientId != null && patientId.trim().isNotEmpty) {
      if (!RegExp(r'^[0-9]+$').hasMatch(patientId.trim())) {
        errors['patientId'] = 'رقم المريض يجب أن يتكون من أرقام فقط';
      }
    }

    return errors;
  }
}
