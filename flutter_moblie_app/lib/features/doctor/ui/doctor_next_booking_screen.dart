import 'package:flutter/material.dart';
import 'package:thoutha_mobile_app/core/di/dependency_injection.dart';
import 'package:thoutha_mobile_app/core/networking/api_service.dart';
import 'package:thoutha_mobile_app/core/routing/routes.dart';
import 'package:thoutha_mobile_app/features/doctor/drawer_doctor/doctor_drawer_screen.dart';
import 'package:thoutha_mobile_app/features/notifications/ui/notifications_screen.dart';
import 'package:thoutha_mobile_app/features/doctor/widgets/appointment_card_widget.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui show TextDirection;

class DoctorNextBookingScreen extends StatefulWidget {
  const DoctorNextBookingScreen({super.key});

  @override
  State<DoctorNextBookingScreen> createState() =>
      _DoctorNextBookingScreenState();
}

class _DoctorNextBookingScreenState extends State<DoctorNextBookingScreen> {
  late ApiService _apiService;
  List<Map<String, dynamic>> _bookings = [];
  bool _isLoading = true;
  String? _errorMessage;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _apiService = getIt<ApiService>();
    _fetchPendingAppointments();
  }

  Future<void> _fetchPendingAppointments() async {
    try {
      final result = await _apiService.getPendingAppointments();

      if (mounted) {
        if (result['success'] == true && result['data'] != null) {
          setState(() {
            _bookings = List<Map<String, dynamic>>.from(result['data'] as List);
            _isLoading = false;
            _errorMessage = null;
          });
        } else {
          setState(() {
            _isLoading = false;
            _errorMessage = result['error'] ?? 'فشل في تحميل الحجوزات';
            _bookings = [];
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'حدث خطأ: ${e.toString()}';
          _bookings = [];
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;
    final baseFontSize = width * 0.04;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: theme.scaffoldBackgroundColor,
      drawer: const DoctorDrawer(),
      appBar: AppBar(
        toolbarHeight: 75.6,
        elevation: 0,
        backgroundColor:
            isDark ? Colors.transparent : theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
        automaticallyImplyLeading: false,
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu, size: 24 * (width / 390)),
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          ),
        ),
        titleSpacing: 0,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/splash-logo.png',
              width: 37 * (width / 390),
              height: 40 * (width / 390),
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 8),
            Text(
              'لوحة التحكم',
              style: textTheme.titleLarge?.copyWith(
                fontFamily: 'Cairo',
                fontSize: baseFontSize * 1.125,
                fontWeight: FontWeight.w600,
                height: 1.5,
              ),
            ),
          ],
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: Icon(Icons.notifications_none, size: 24 * (width / 390)),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const NotificationsScreen()),
                  );
                },
              ),
              Positioned(
                right: 8,
                top: 10,
                child: Container(
                  width: 16 * (width / 390),
                  height: 16 * (width / 390),
                  decoration: BoxDecoration(
                    color: colorScheme.error,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '3',
                      style: textTheme.labelSmall?.copyWith(
                        color: colorScheme.onError,
                        fontSize: baseFontSize * 0.625,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.1),
          child: Divider(
            height: 1.1,
            color: theme.dividerColor.withAlpha(isDark ? 50 : 255),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red[300],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          color: Colors.red,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _fetchPendingAppointments,
                        child: const Text('إعادة محاولة',
                            style: TextStyle(fontFamily: 'Cairo')),
                      ),
                    ],
                  ),
                )
              : _buildMainContent(context, width, height, baseFontSize),
    );
  }

  // ── Bottom sheet with full booking details ──────────────────────────────────
  void _showBookingDetails({
    required BuildContext context,
    required String patientName,
    required String phone,
    required String date,
    required String time,
    required String service,
    required double baseFontSize,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: theme.cardTheme.color ?? theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            top: 20,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 28,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[600] : Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              // Patient name
              Text(
                patientName,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.w700,
                  fontSize: baseFontSize * 1.25,
                ),
              ),
              const SizedBox(height: 20),
              Divider(
                  color: isDark ? Colors.grey[700] : const Color(0xFFE5E7EB)),
              const SizedBox(height: 12),
              // Phone
              _buildDetailRow(
                context: context,
                icon: Icons.phone_outlined,
                label: 'رقم الهاتف',
                value: phone,
                baseFontSize: baseFontSize,
              ),
              const SizedBox(height: 14),
              // Date
              _buildDetailRow(
                context: context,
                icon: Icons.calendar_month_outlined,
                label: 'التاريخ',
                value: date,
                baseFontSize: baseFontSize,
              ),
              const SizedBox(height: 14),
              // Time
              _buildDetailRow(
                context: context,
                icon: Icons.access_time_outlined,
                label: 'الوقت',
                value: time,
                baseFontSize: baseFontSize,
              ),
              const SizedBox(height: 14),
              // Specialty
              _buildDetailRow(
                context: context,
                icon: Icons.medical_services_outlined,
                label: 'التخصص',
                value: service,
                baseFontSize: baseFontSize,
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
    required double baseFontSize,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Row(
      textDirection: ui.TextDirection.rtl,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[800] : const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon,
              size: 18, color: isDark ? Colors.white : const Color(0xFF021433)),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: baseFontSize * 0.75,
                color: Colors.grey,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.w600,
                fontSize: baseFontSize * 0.9,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Simplified booking card ─────────────────────────────────────────────────
  Widget _buildBookingCard({
    required BuildContext context,
    required int appointmentId,
    required String patientName,
    required String phone,
    required String service,
    required String time,
    required String date,
    required String status,
    required Color statusColor,
    required double width,
    required double baseFontSize,
  }) {
    return AppointmentCardWidget(
      context: context,
      patientName: patientName,
      phone: phone,
      service: service,
      time: time,
      date: date,
      statusLabel: status,
      statusColor: statusColor,
      onTap: () => _showBookingDetails(
        context: context,
        patientName: patientName,
        phone: phone,
        date: date,
        time: time,
        service: service,
        baseFontSize: baseFontSize,
      ),
      actionButtons: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () =>
                  _handleAppointmentStatus(context, appointmentId, 'APPROVED'),
              icon: const Icon(Icons.thumb_up_outlined),
              label: Text(
                'قبول',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                elevation: 2,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () =>
                  _handleAppointmentStatus(context, appointmentId, 'REJECTED'),
              icon: const Icon(Icons.thumb_down_outlined),
              label: Text(
                'رفض',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                elevation: 2,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent(
      BuildContext context, double width, double height, double baseFontSize) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 64,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              'لا توجد حجوزات قادمة',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: baseFontSize * 1.125,
                color: isDark ? Colors.white38 : Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchPendingAppointments,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(
                'حجوزاتي القادمة',
                textAlign: TextAlign.right,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.w700,
                  fontSize: baseFontSize * 1.5,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 12),
            ..._bookings.asMap().entries.map((entry) {
              final booking = entry.value;

              // Parse dateTime correctly using the correct API key 'appointmentDate'
              final String rawDateTime = booking['appointmentDate'] ?? '';
              String displayDate = booking['date'] ?? 'غير محدد';
              String displayTime = booking['time'] ?? 'غير محدد';

              if (rawDateTime.isNotEmpty) {
                try {
                  final dt = DateTime.parse(rawDateTime);
                  // Format: 18/03/2026
                  displayDate = DateFormat('dd/MM/yyyy').format(dt);
                  // Format: 04:00 مساءً
                  displayTime = DateFormat('hh:mm a', 'ar')
                      .format(dt)
                      .replaceAll('AM', 'صباحاً')
                      .replaceAll('PM', 'مساءً');
                } catch (e) {
                  // Fallback to raw if parsing fails
                  if (rawDateTime.contains('T')) {
                    final parts = rawDateTime.split('T');
                    displayDate = parts[0];
                    displayTime = parts[1].substring(0, 5);
                  }
                }
              }

              return Column(
                children: [
                  _buildBookingCard(
                    context: context,
                    appointmentId: booking['id'] ?? 0,
                    patientName:
                        '${booking['patientFirstName'] ?? 'مريض'} ${booking['patientLastName'] ?? ''}'
                            .trim(),
                    phone: booking['patientPhoneNumber'] ?? 'غير متوفر',
                    service: booking['categoryName'] ?? 'تخصص عام',
                    time: displayTime,
                    date: displayDate,
                    status: booking['status'] ?? 'قادم',
                    statusColor: const Color(0xFF84E5F3),
                    width: width,
                    baseFontSize: baseFontSize,
                  ),
                  const SizedBox(height: 12),
                ],
              );
            }),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
          ],
        ),
      ),
    );
  }

  /// Update appointment status and navigate to history
  Future<void> _handleAppointmentStatus(
      BuildContext context, int appointmentId, String status) async {
    await _updateAppointmentStatus(appointmentId, status);
  }

  Future<void> _updateAppointmentStatus(
      int appointmentId, String status) async {
    try {
      final result =
          await _apiService.updateAppointmentStatus(appointmentId, status);

      if (!mounted) return;

      if (result['success'] == true) {
        // Show success message
        _statusToArabic(status);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تم ${status == 'APPROVED' ? 'قبول' : 'رفض'} الحجز بنجاح',
              style: const TextStyle(fontFamily: 'Cairo'),
            ),
            backgroundColor:
                status == 'APPROVED' ? Colors.green : Colors.orange,
            duration: const Duration(seconds: 2),
          ),
        );

        // Navigate to booking records if approved
        if (status == 'APPROVED') {
          await Future.delayed(const Duration(milliseconds: 500));
          if (mounted) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              Routes.doctorBookingRecordsScreen,
              (route) => route.isFirst,
            );
          }
        } else {
          // Refresh the list for other statuses
          await Future.delayed(const Duration(milliseconds: 500));
          if (mounted) {
            _fetchPendingAppointments();
          }
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result['error'] ?? 'فشل في تحديث حالة الحجز',
              style: const TextStyle(fontFamily: 'Cairo'),
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'حدث خطأ: ${e.toString()}',
            style: const TextStyle(fontFamily: 'Cairo'),
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  /// Convert appointment status to Arabic
  String _statusToArabic(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return 'قيد الانتظار';
      case 'APPROVED':
        return 'موافق عليه';
      case 'DONE':
        return 'مكتمل';
      case 'CANCELLED':
        return 'ملغى';
      default:
        return status;
    }
  }
}
