import 'package:flutter/material.dart';
import 'package:thotha_mobile_app/features/appointments/ui/simple_appointment_booking_screen.dart';

/// Example: How to use the Simple Appointment Booking
/// 
/// This shows how to navigate to the appointment booking screen
/// from any screen that displays requests.
class AppointmentBookingUsageExample extends StatelessWidget {
  const AppointmentBookingUsageExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Appointment Booking Usage')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'مثال على كيفية استخدام حجز الموعد',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            
            // Example Request Card
            _buildRequestCard(
              context,
              requestId: '5',
              doctorName: 'د. محمد أحمد',
              categoryName: 'طب الأسنان',
              description: 'تنظيف أسنان احترافي وتبييض',
              dateTime: '2026-03-25T09:00:00',
            ),
            
            const SizedBox(height: 20),
            
            // Usage Instructions
            _buildUsageInstructions(),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestCard(
    BuildContext context, {
    required String requestId,
    required String doctorName,
    required String categoryName,
    required String description,
    required String dateTime,
  }) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              doctorName,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('التخصص: $categoryName'),
            Text('الوصف: $description'),
            Text('التاريخ: ${_formatDateTime(dateTime)}'),
            const SizedBox(height: 16),
            
            // Book Appointment Button
            ElevatedButton.icon(
              onPressed: () => _navigateToBooking(context, requestId, doctorName, categoryName, description, dateTime),
              icon: const Icon(Icons.calendar_today),
              label: const Text('احجز موعد'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsageInstructions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const Text(
            'كيفية الاستخدام:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            '1. من أي شاشة تعرض الطلبات، أضف زر "احجز موعد"',
            textAlign: TextAlign.right,
          ),
          const Text(
            '2. عند الضغط على الزر، انتقل إلى SimpleAppointmentBookingScreen',
            textAlign: TextAlign.right,
          ),
          const Text(
            '3. مرر البيانات المطلوبة: requestId, doctorName, categoryName, description, dateTime',
            textAlign: TextAlign.right,
          ),
          const Text(
            '4. المريض يملأ 3 حقول فقط: الاسم الأول، اسم العائلة، رقم الجوال',
            textAlign: TextAlign.right,
          ),
          const Text(
            '5. يتم إرسال الطلب إلى: POST /api/appointment/createAppointment/{requestId}',
            textAlign: TextAlign.right,
          ),
          const SizedBox(height: 8),
          const Text(
            'مثال الكود:',
            style: TextStyle(fontWeight: FontWeight.bold),
            textAlign: TextAlign.right,
          ),
          Container(
            padding: const EdgeInsets.all(8),
            color: Colors.grey[200],
            child: const Text(
              '''Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => SimpleAppointmentBookingScreen(
      requestId: '5',
      requestDescription: 'تنظيف أسنان',
      doctorName: 'د. محمد أحمد',
      categoryName: 'طب الأسنان',
      requestDateTime: '2026-03-25T09:00:00',
    ),
  ),
);''',
              style: TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToBooking(
    BuildContext context,
    String requestId,
    String doctorName,
    String categoryName,
    String description,
    String dateTime,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SimpleAppointmentBookingScreen(
          requestId: requestId,
          requestDescription: description,
          doctorName: doctorName,
          categoryName: categoryName,
          requestDateTime: dateTime,
        ),
      ),
    );
  }

  String _formatDateTime(String dateTimeString) {
    try {
      final dateTime = DateTime.parse(dateTimeString);
      return '${dateTime.day.toString().padLeft(2, '0')}/'
          '${dateTime.month.toString().padLeft(2, '0')}/'
          '${dateTime.year} '
          '${dateTime.hour.toString().padLeft(2, '0')}:'
          '${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateTimeString;
    }
  }
}
