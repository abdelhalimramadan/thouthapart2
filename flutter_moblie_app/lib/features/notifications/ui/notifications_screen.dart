import 'package:flutter/material.dart';
import '../data/models/patient_booking_model.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final baseFontSize = width * 0.04;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final List<PatientBookingModel> notifications = [];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'تنبيهات الحجوزات',
          style: TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.bold,
            fontSize: baseFontSize * 1.25, // 20sp
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: notifications.isEmpty
          ? _buildEmptyState(width, baseFontSize, colorScheme)
          : ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: width * 0.04, vertical: 10),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                return _buildBookingCard(notifications[index], width, baseFontSize, colorScheme);
              },
            ),
    );
  }

  Widget _buildEmptyState(double width, double baseFontSize, ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none_outlined,
            size: 100 * (width / 390),
            color: colorScheme.primary.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'لا توجد تنبيهات حالياً',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: baseFontSize * 1.125, // 18sp
              color: Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'ستظهر حجوزات المرضى الجديدة هنا',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: baseFontSize * 0.875, // 14sp
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingCard(
      PatientBookingModel booking, double width, double baseFontSize, ColorScheme colorScheme) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shadowColor: colorScheme.primary.withValues(alpha: 0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
                  child: Icon(Icons.person, color: colorScheme.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.patientName,
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.bold,
                          fontSize: baseFontSize, // 16sp
                        ),
                      ),
                      Text(
                        booking.phone,
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          color: Colors.grey[600],
                          fontSize: baseFontSize * 0.8125, // 13sp
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'حجز جديد',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      color: Colors.green,
                      fontSize: baseFontSize * 0.6875, // 11sp
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.secondary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildInfoItem(
                      Icons.calendar_today_outlined, booking.date, baseFontSize, colorScheme),
                  _buildInfoItem(
                      Icons.access_time_outlined, booking.time, baseFontSize, colorScheme),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, double baseFontSize, ColorScheme colorScheme) {
    return Row(
      children: [
        Icon(icon, size: 16 * (baseFontSize / 16), color: colorScheme.primary),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.w600,
            fontSize: baseFontSize * 0.875, // 14sp
          ),
        ),
      ],
    );
  }
}
