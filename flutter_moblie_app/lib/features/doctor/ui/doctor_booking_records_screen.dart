import 'package:flutter/material.dart';
import '../../../../core/utils/notification_helper.dart';
import '../../../../core/di/dependency_injection.dart';
import '../../../../core/networking/api_service.dart';
import '../../../../core/routing/routes.dart';
import '../drawer_doctor/doctor_drawer_screen.dart';
import '../../notifications/ui/notifications_screen.dart';
import '../widgets/appointment_card_widget.dart';

class DoctorBookingRecordsScreen extends StatefulWidget {
  const DoctorBookingRecordsScreen({super.key});

  @override
  State<DoctorBookingRecordsScreen> createState() =>
      _DoctorBookingRecordsScreenState();
}

class _DoctorBookingRecordsScreenState
    extends State<DoctorBookingRecordsScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late ApiService _apiService;
  List<Map<String, dynamic>> _approvedAppointments = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _apiService = getIt<ApiService>();
    _fetchApprovedAppointments();
  }

  Future<void> _fetchApprovedAppointments() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final result = await _apiService.getApprovedAppointments();

      if (!mounted) return;

      if (result['success'] == true) {
        setState(() {
          _approvedAppointments =
              List<Map<String, dynamic>>.from(result['data'] as List);
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = result['error']?.toString() ?? 'فشل في تحميل الحجوزات';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'حدث خطأ: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: theme.scaffoldBackgroundColor,
      drawer: const DoctorDrawer(),
      appBar: AppBar(
        toolbarHeight: 70,
        elevation: 0,
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
        automaticallyImplyLeading: false,
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu, size: 24),
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          ),
        ),
        titleSpacing: 0,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/splash-logo.png',
              width: 36,
              height: 36,
              fit: BoxFit.contain,
            ),
            SizedBox(width: 8),
            Text(
              'سجل الحجوزات',
              style: textTheme.titleLarge?.copyWith(
                fontFamily: 'Cairo',
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
      body: _buildMainContent(context),
    );
  }

  void _showBookingDetails({
    required BuildContext context,
    required String patientName,
    required String phone,
    required String date,
    required String time,
    required String service,
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
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[600] : Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(height: 20),
              Row(
                textDirection: TextDirection.rtl,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      image: DecorationImage(
                        image: const AssetImage('assets/images/dكتور.png'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      patientName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.w700,
                        fontSize: 20,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              Divider(
                  color: isDark ? Colors.grey[700] : const Color(0xFFE5E7EB)),
              SizedBox(height: 12),
              _buildDetailRow(
                context: context,
                icon: Icons.calendar_month_outlined,
                label: 'التاريخ',
                value: date,
              ),
              SizedBox(height: 14),
              _buildDetailRow(
                context: context,
                icon: Icons.access_time_outlined,
                label: 'الوقت',
                value: time,
              ),
              SizedBox(height: 14),
              _buildDetailRow(
                context: context,
                icon: Icons.medical_services_outlined,
                label: 'التخصص',
                value: service,
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
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Row(
      textDirection: TextDirection.rtl,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[800] : const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon,
              size: 18,
              color: isDark ? Colors.white : const Color(0xFF021433)),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
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
      ),
      actionButtons: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _handleConfirmAppointment(context, appointmentId),
              icon: const Icon(Icons.check_circle_outline),
              label: Text(
                'تأكيد',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
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
                padding: EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _handleCancelAppointment(context, appointmentId),
              icon: const Icon(Icons.close_outlined),
              label: Text(
                'إلغاء',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
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
                padding: EdgeInsets.symmetric(vertical: 12),
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

  Future<void> _handleConfirmAppointment(
      BuildContext context, int appointmentId) async {
    try {
      final apiService = getIt<ApiService>();
      final result =
          await apiService.updateAppointmentStatus(appointmentId, 'DONE');

      if (!mounted) return;

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'تم تأكيد الحجز بنجاح',
              style: TextStyle(fontFamily: 'Cairo'),
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        // Navigate to confirmed appointments screen
        Future.delayed(const Duration(milliseconds: 600), () {
          if (mounted) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              Routes.doctorConfirmedAppointmentsScreen,
              (route) => route.isFirst,
            );
          }
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result['error'] ?? 'فشل في تحديث الحجز',
              style: const TextStyle(fontFamily: 'Cairo'),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'حدث خطأ: ${e.toString()}',
              style: const TextStyle(fontFamily: 'Cairo'),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleCancelAppointment(
      BuildContext context, int appointmentId) async {
    try {
      final apiService = getIt<ApiService>();
      final result =
          await apiService.updateAppointmentStatus(appointmentId, 'CANCELLED');

      if (!mounted) return;

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'تم إلغاء الحجز بنجاح',
              style: TextStyle(fontFamily: 'Cairo'),
            ),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
        _fetchApprovedAppointments();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result['error'] ?? 'فشل في إلغاء الحجز',
              style: const TextStyle(fontFamily: 'Cairo'),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'حدث خطأ: ${e.toString()}',
              style: const TextStyle(fontFamily: 'Cairo'),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildMainContent(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.red,
            ),
            SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontFamily: 'Cairo',
              ),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: _fetchApprovedAppointments,
              child: Text(
                'إعادة المحاولة',
                style: const TextStyle(fontFamily: 'Cairo'),
              ),
            ),
          ],
        ),
      );
    }

    if (_approvedAppointments.isEmpty) {
      final isDarkMode = Theme.of(context).brightness == Brightness.dark;
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: 48,
                color: isDarkMode ? Colors.white30 : Colors.grey[400],
              ),
              SizedBox(height: 16),
              Text(
                'لا توجد حجوزات معتمدة حالياً',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.w700,
                  fontSize: 17,
                  color: isDarkMode ? Colors.white : const Color(0xFF0C4A6E),
                ),
              ),
              SizedBox(height: 20),
              Text(
                'داخل سجل الحجوزات:',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: isDarkMode ? Colors.white : const Color(0xFF0C4A6E),
                ),
              ),
              SizedBox(height: 12),
              _buildInstructionRow(
                isDarkMode: isDarkMode,
                icon: Icons.task_alt_outlined,
                iconColor: const Color(0xFF10B981),
                text: 'بعد حضور المريض وإتمام الحالة، اضغط "مكتمل" ليتم نقلها إلى صفحة المرضى كحالة مكتملة.',
              ),
              SizedBox(height: 10),
              _buildInstructionRow(
                isDarkMode: isDarkMode,
                icon: Icons.event_busy_outlined,
                iconColor: Colors.orange,
                text: 'في حال عدم حضور المريض، اضغط "ملغى".',
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Text(
              'سجل الحجوزات',
              textAlign: TextAlign.right,
              style: theme.textTheme.titleLarge?.copyWith(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.w700,
                fontSize: 24,
                height: 1.5,
              ),
            ),
          ),
          SizedBox(height: 12),
          ..._approvedAppointments.asMap().entries.map((entry) {
            final appointment = entry.value;
            return Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: _buildBookingCard(
                context: context,
                appointmentId: appointment['id'] ?? 0,
                patientName:
                    '${appointment['patientFirstName'] ?? 'مريض'} ${appointment['patientLastName'] ?? ''}'
                        .trim(),
                phone: appointment['patientPhoneNumber'] ?? '',
                service: appointment['categoryName'] ?? '',
                time: appointment['appointmentDate'] != null
                    ? appointment['appointmentDate']
                        .toString()
                        .split('T')[1]
                        .substring(0, 5)
                    : '',
                date: appointment['appointmentDate'] != null
                    ? appointment['appointmentDate'].toString().split('T')[0]
                    : '',
                status: appointment['status'] ?? 'معتمد',
                statusColor: Colors.greenAccent,
              ),
            );
          }).toList(),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }

  Widget _buildInstructionRow({
    required bool isDarkMode,
    required IconData icon,
    required Color iconColor,
    required String text,
  }) {
    return Row(
      textDirection: TextDirection.rtl,
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
            textDirection: TextDirection.rtl,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 13,
              height: 1.6,
              color: isDarkMode ? Colors.white60 : const Color(0xFF475569),
            ),
          ),
        ),
      ],
    );
  }
}
