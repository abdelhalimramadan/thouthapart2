import 'package:flutter/material.dart';
import 'package:thotha_mobile_app/features/appointments/data/appointments_service.dart';
import 'package:thotha_mobile_app/features/appointments/data/models/appointment_model.dart';
import 'package:thotha_mobile_app/core/networking/api_service.dart';

/// Simple Appointment Booking Example
/// 
/// Usage:
/// ```dart
/// final result = await SimpleAppointmentBooking.createAppointment(
///   requestId: '5',
///   patientFirstName: 'Ahmed',
///   patientLastName: 'Hassan',
///   patientPhoneNumber: '0509876543',
/// );
/// ```
class SimpleAppointmentBooking {
  static final AppointmentsService _appointmentsService = AppointmentsService(ApiService());

  /// Create appointment for a request - SUPER SIMPLE
  /// 
  /// POST /api/appointment/createAppointment?requestId={requestId}
  /// Content-Type: application/json
  /// 
  /// Parameters:
  /// - requestId: The ID from GET /api/request/getAllRequests
  /// - patientFirstName: Patient's first name
  /// - patientLastName: Patient's last name  
  /// - patientPhoneNumber: Patient's phone number
  /// 
  /// Response (200 OK):
  /// {
  ///   "doctorFirstName": "Mohamed",
  ///   "doctorLastName": "Ahmed",
  ///   "doctorPhoneNumber": "0501234567",
  ///   "doctorCity": "Cairo",
  ///   "patientFirstName": "Ahmed",
  ///   "patientLastName": "Hassan",
  ///   "patientPhoneNumber": "0509876543",
  ///   "requestDescription": "Professional teeth cleaning",
  ///   "categoryName": "Cleaning",
  ///   "appointmentDate": "2026-03-25T09:00:00",
  ///   "durationMinutes": null,
  ///   "status": "PENDING",
  ///   "notes": null,
  ///   "createdAt": "2026-03-20T10:15:37",
  ///   "isExpired": false,
  ///   "isHistory": false
  /// }
  static Future<Map<String, dynamic>> createAppointment({
    required String requestId,
    required String patientFirstName,
    required String patientLastName,
    required String patientPhoneNumber,
  }) async {
    try {
      // Validate input
      final validation = _validateAppointmentData(
        patientFirstName: patientFirstName,
        patientLastName: patientLastName,
        patientPhoneNumber: patientPhoneNumber,
      );
      
      if (validation.isNotEmpty) {
        return {
          'success': false,
          'error': validation,
        };
      }

      // Create appointment
      final result = await _appointmentsService.createAppointment(
        requestId: requestId,
        patientFirstName: patientFirstName,
        patientLastName: patientLastName,
        patientPhoneNumber: patientPhoneNumber,
      );

      return result;
    } catch (e) {
      return {
        'success': false,
        'error': 'فشل في إنشاء الحجز: $e',
      };
    }
  }

  /// Validate appointment data
  static String _validateAppointmentData({
    required String patientFirstName,
    required String patientLastName,
    required String patientPhoneNumber,
  }) {
    // First name validation
    if (patientFirstName.trim().isEmpty) {
      return 'الرجاء إدخال الاسم الأول';
    }

    // Last name validation
    if (patientLastName.trim().isEmpty) {
      return 'الرجاء إدخال اسم العائلة';
    }

    // Phone validation
    if (patientPhoneNumber.trim().isEmpty) {
      return 'الرجاء إدخال رقم الجوال';
    }

    // Clean phone number
    String cleanPhone = patientPhoneNumber.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    
    // Egypt phone validation
    if (cleanPhone.startsWith('01')) {
      if (cleanPhone.length != 11) {
        return 'رقم الجوال المصري يجب أن يكون 11 رقم';
      }
      if (!RegExp(r'^01[0-2]\d{8}$').hasMatch(cleanPhone)) {
        return 'رقم الجوال المصري غير صحيح';
      }
    } else if (cleanPhone.startsWith('+20')) {
      if (cleanPhone.length != 13) {
        return 'رقم الجوال المصري يجب أن يكون 13 رقم مع +20';
      }
      if (!RegExp(r'^\+201[0-2]\d{8}$').hasMatch(cleanPhone)) {
        return 'رقم الجوال المصري غير صحيح';
      }
    } else {
      return 'الرجاء إدخال رقم جوال مصري صحيح';
    }

    return ''; // No errors
  }

  /// Example usage in a widget
  static Widget buildExampleWidget() {
    return Scaffold(
      appBar: AppBar(title: const Text('حجز موعد')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'مثال حجز موعد بسيط',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                final result = await createAppointment(
                  requestId: '5',
                  patientFirstName: 'أحمد',
                  patientLastName: 'محمد',
                  patientPhoneNumber: '0501234567',
                );

                if (result['success'] == true) {
                  print('Appointment created successfully!');
                  print('Response: ${result['data']}');
                } else {
                  print('Error: ${result['error']}');
                }
              },
              child: const Text('احجز موعد'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Extension for easy usage
extension AppointmentBookingExtension on BuildContext {
  /// Show success/error snackbar for appointment booking
  void showAppointmentResult(Map<String, dynamic> result) {
    final message = result['success'] == true 
        ? 'تم إنشاء الحجز بنجاح' 
        : result['error'] ?? 'فشل في إنشاء الحجز';
    
    final color = result['success'] == true ? Colors.green : Colors.red;

    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontFamily: 'Cairo'),
        ),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
