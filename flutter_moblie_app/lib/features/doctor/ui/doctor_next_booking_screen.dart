import 'package:flutter/material.dart';
import 'package:thoutha_mobile_app/core/di/dependency_injection.dart';
import 'package:thoutha_mobile_app/core/networking/api_service.dart';
import 'package:thoutha_mobile_app/core/routing/routes.dart';
import 'package:thoutha_mobile_app/features/doctor/drawer_doctor/doctor_drawer_screen.dart';
import 'package:thoutha_mobile_app/features/doctor/widgets/appointment_card_widget.dart';
import 'dart:ui' as ui show TextDirection;
import 'package:easy_localization/easy_localization.dart' hide TextDirection;

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
  bool _hasCheckedArguments = false;

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

          // Handle navigation from notification
          if (!_hasCheckedArguments) {
            _hasCheckedArguments = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _handleArguments();
            });
          }
        } else {
          setState(() {
            _isLoading = false;
            _errorMessage = result['error'] ?? 'doctor.failed_to_load_reservations'.tr();
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

  void _handleArguments() {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null && args.containsKey('appointmentId')) {
      final String? targetId = args['appointmentId']?.toString();
      if (targetId != null && targetId.isNotEmpty) {
        // Try to find the appointment in the list
        final booking = _bookings.firstWhere(
          (b) => b['id']?.toString() == targetId,
          orElse: () => {},
        );

        if (booking.isNotEmpty) {
          final width = MediaQuery.of(context).size.width;
          final baseFontSize = width * 0.04;

          // Parse dateTime for display
          final String rawDateTime = booking['appointmentDate'] ?? '';
          String displayDate = booking['date'] ?? 'doctor.undefined'.tr();
          String displayTime = booking['time'] ?? 'doctor.undefined'.tr();

          if (rawDateTime.isNotEmpty) {
            try {
              final dt = DateTime.parse(rawDateTime);
              displayDate = DateFormat('dd/MM/yyyy').format(dt);
              displayTime = DateFormat('hh:mm a', 'ar')
                  .format(dt)
                  .replaceAll('AM', 'doctor.am'.tr())
                  .replaceAll('PM', 'doctor.evening'.tr());
            } catch (_) {}
          }

          _showBookingDetails(
            context: context,
            patientName:
                '${booking['patientFirstName'] ?? 'مريض'} ${booking['patientLastName'] ?? ''}'
                    .trim(),
            phone: booking['patientPhoneNumber'] ?? 'doctor.unavailable'.tr(),
            date: displayDate,
            time: displayTime,
            service: booking['categoryName'] ?? 'doctor.general_specialty'.tr(),
            baseFontSize: baseFontSize,
          );
        }
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
    final textTheme = theme.textTheme;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.of(context).pushReplacementNamed(Routes.doctorHomeScreen);
      },
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: theme.scaffoldBackgroundColor,
        drawer: DoctorDrawer(),
        appBar: AppBar(
          toolbarHeight: 70,
          elevation: 0,
          backgroundColor:
              isDark ? Colors.transparent : theme.colorScheme.surface,
          foregroundColor: theme.colorScheme.onSurface,
          automaticallyImplyLeading: false,
          leading: Builder(
            builder: (context) => IconButton(
              icon: Icon(Icons.menu, size: 24),
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            ),
          ),
          titleSpacing: 0,
          centerTitle: true,
          title: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'doctor.upcoming_reservations'.tr(),
                style: textTheme.titleLarge?.copyWith(
                  fontFamily: 'Cairo',
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(width: 8),
              Image.asset(
                'assets/images/splash-logo.png',
                width: 36,
                height: 36,
                fit: BoxFit.contain,
              ),
            ],
          ),
          // ...existing code...
        ),
        body: _isLoading
            ? Center(child: CircularProgressIndicator())
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
                        SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            color: Colors.red,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _fetchPendingAppointments,
                          child: Text('doctor.retry_1'.tr(),
                              style: TextStyle(fontFamily: 'Cairo')),
                        ),
                      ],
                    ),
                  )
                : _buildMainContent(context, width, height, baseFontSize),
      ),
    );
  }

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
              SizedBox(height: 20),
              // Patient name
              Text(
                patientName,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.w700,
                  fontSize: baseFontSize * 1.25,
                ),
              ),
              SizedBox(height: 20),
              Divider(
                  color: isDark ? Colors.grey[700] : Color(0xFFE5E7EB)),
              SizedBox(height: 12),
              // Phone
              _buildDetailRow(
                context: context,
                icon: Icons.phone_outlined,
                label: 'doctor.phone_number'.tr(),
                value: phone,
                baseFontSize: baseFontSize,
              ),
              SizedBox(height: 14),
              // Date
              _buildDetailRow(
                context: context,
                icon: Icons.calendar_month_outlined,
                label: 'doctor.the_date'.tr(),
                value: date,
                baseFontSize: baseFontSize,
              ),
              SizedBox(height: 14),
              // Time
              _buildDetailRow(
                context: context,
                icon: Icons.access_time_outlined,
                label: 'doctor.the_time'.tr(),
                value: time,
                baseFontSize: baseFontSize,
              ),
              SizedBox(height: 14),
              // Specialty
              _buildDetailRow(
                context: context,
                icon: Icons.medical_services_outlined,
                label: 'doctor.specialization'.tr(),
                value: service,
                baseFontSize: baseFontSize,
              ),
              SizedBox(height: 24),
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
            color: isDark ? Colors.grey[800] : Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon,
              size: 18, color: isDark ? Colors.white : Color(0xFF021433)),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
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
              icon: Icon(Icons.thumb_up_outlined),
              label: Text(
                'doctor.acceptance'.tr(),
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF10B981),
                foregroundColor: Colors.white,
                elevation: 2,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () =>
                  _handleAppointmentStatus(context, appointmentId, 'CANCELLED'),
              icon: Icon(Icons.thumb_down_outlined),
              label: Text(
                'doctor.to_reject'.tr(),
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFEF4444),
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
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: 48,
                color: isDark ? Colors.white30 : Colors.grey[400],
              ),
              SizedBox(height: 16),
              Text(
                'doctor.there_are_no_reservations_1'.tr(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.w700,
                  fontSize: 17,
                  color: isDark ? Colors.white : Color(0xFF0C4A6E),
                ),
              ),
              SizedBox(height: 16),
              Text(
                'doctor.when_any_patient_books'.tr(),
                textAlign: TextAlign.right,
                textDirection: ui.TextDirection.rtl,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 13.5,
                  height: 1.6,
                  color: isDark ? Colors.white70 : Color(0xFF334155),
                ),
              ),
              Text(
                'doctor.str_234'.tr(),
                textAlign: TextAlign.right,
                textDirection: ui.TextDirection.rtl,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 13.5,
                  height: 1.6,
                  color: isDark ? Colors.white70 : Color(0xFF334155),
                ),
              ),
              SizedBox(height: 12),
              _buildInstructionRow(
                isDarkMode: isDark,
                icon: Icons.check_circle_outline,
                iconColor: Color(0xFF16A34A),
                text: 'doctor.click_accept_to_add'.tr(),
              ),
              SizedBox(height: 8),
              _buildInstructionRow(
                isDarkMode: isDark,
                icon: Icons.cancel_outlined,
                iconColor: Color(0xFFE7000B),
                text: 'doctor.click_delete_to_cancel'.tr(),
              ),
            ],
          ),
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
                'doctor.my_next_reservations'.tr(),
                textAlign: TextAlign.right,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                  height: 1.4,
                ),
              ),
            ),
            SizedBox(height: 12),
            ..._bookings.asMap().entries.map((entry) {
              final booking = entry.value;

              // Parse dateTime correctly using the correct API key 'appointmentDate'
              final String rawDateTime = booking['appointmentDate'] ?? '';
              String displayDate = booking['date'] ?? 'doctor.undefined'.tr();
              String displayTime = booking['time'] ?? 'doctor.undefined'.tr();

              if (rawDateTime.isNotEmpty) {
                try {
                  final dt = DateTime.parse(rawDateTime);
                  // Format: 18/03/2026
                  displayDate = DateFormat('dd/MM/yyyy').format(dt);
                  // Format: 04:00 مساءً
                  displayTime = DateFormat('hh:mm a', 'ar')
                      .format(dt)
                      .replaceAll('AM', 'doctor.am'.tr())
                      .replaceAll('PM', 'doctor.evening'.tr());
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
                    phone: booking['patientPhoneNumber'] ?? 'doctor.unavailable'.tr(),
                    service: booking['categoryName'] ?? 'doctor.general_specialty'.tr(),
                    time: displayTime,
                    date: displayDate,
                    status: 'doctor.on_hold'.tr(),
                    statusColor: Colors.orange,
                    width: width,
                    baseFontSize: baseFontSize,
                  ),
                  SizedBox(height: 12),
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
              status == 'APPROVED' ? 'doctor.your_reservation_has_been_2'.tr() : 'doctor.your_reservation_was_rejected'.tr(),
              style: TextStyle(fontFamily: 'Cairo'),
            ),
            backgroundColor: status == 'APPROVED' || status == 'DONE'
                ? Colors.green
                : Colors.red,
            duration: Duration(seconds: 2),
          ),
        );

        // Navigate to booking records if approved
        if (status == 'APPROVED') {
          await Future.delayed(Duration(milliseconds: 500));
          if (mounted) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              Routes.doctorBookingRecordsScreen,
              (route) => route.isFirst,
            );
          }
        } else {
          // Refresh the list for other statuses
          await Future.delayed(Duration(milliseconds: 500));
          if (mounted) {
            _fetchPendingAppointments();
          }
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result['error'] ?? 'doctor.failed_to_update_reservation_1'.tr(),
              style: TextStyle(fontFamily: 'Cairo'),
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'حدث خطأ: ${e.toString()}',
            style: TextStyle(fontFamily: 'Cairo'),
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  /// Convert appointment status to Arabic
  String _statusToArabic(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return 'doctor.on_hold'.tr();
      case 'APPROVED':
        return 'doctor.approved'.tr();
      case 'DONE':
        return 'doctor.complete'.tr();
      case 'CANCELLED':
        return 'doctor.canceled'.tr();
      default:
        return status;
    }
  }

  Widget _buildInstructionRow({
    required bool isDarkMode,
    required IconData icon,
    required Color iconColor,
    required String text,
  }) {
    return Row(
      textDirection: ui.TextDirection.rtl,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(top: 2),
          child: Icon(icon, size: 18, color: iconColor),
        ),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            textAlign: TextAlign.right,
            textDirection: ui.TextDirection.rtl,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 13,
              height: 1.6,
              color: isDarkMode ? Colors.white60 : Color(0xFF475569),
            ),
          ),
        ),
      ],
    );
  }
}
