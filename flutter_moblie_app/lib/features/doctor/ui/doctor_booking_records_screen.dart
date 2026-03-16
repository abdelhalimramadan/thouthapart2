import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:thotha_mobile_app/core/di/dependency_injection.dart';
import 'package:thotha_mobile_app/core/helpers/constants.dart';
import 'package:thotha_mobile_app/core/helpers/shared_pref_helper.dart';
import 'package:thotha_mobile_app/core/utils/notification_helper.dart';
import 'package:thotha_mobile_app/features/appointments/data/models/appointment_model.dart';
import 'package:thotha_mobile_app/features/appointments/logic/appointments_cubit.dart';
import 'package:thotha_mobile_app/features/appointments/logic/appointments_state.dart';
import 'package:thotha_mobile_app/features/doctor/drawer/doctor_drawer_screen.dart';
import 'package:thotha_mobile_app/features/notifications/ui/notifications_screen.dart';

class DoctorBookingRecordsScreen extends StatefulWidget {
  const DoctorBookingRecordsScreen({super.key});

  @override
  State<DoctorBookingRecordsScreen> createState() => _DoctorBookingRecordsScreenState();
}

class _DoctorBookingRecordsScreenState extends State<DoctorBookingRecordsScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late final AppointmentsCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = getIt<AppointmentsCubit>();
    _loadAppointments();
  }

  Future<void> _loadAppointments() async {
    final doctorId = await _extractDoctorIdFromToken();
    if (doctorId != 0 && mounted) {
      _cubit.loadAppointmentsByDoctorId(doctorId);
    }
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  Future<int> _extractDoctorIdFromToken() async {
    try {
      final token = await SharedPrefHelper.getSecuredString(SharedPrefKeys.userToken);
      if (token == null || token.isEmpty) return 0;

      final parts = token.split('.');
      if (parts.length != 3) return 0;

      String payload = parts[1];
      while (payload.length % 4 != 0) {
        payload += '=';
      }

      final decoded = json.decode(utf8.decode(base64Url.decode(payload))) as Map?;
      if (decoded == null) return 0;

      final rawId = decoded['id'] ?? decoded['doctorId'] ?? decoded['doctor_id'];
      final did = int.tryParse(rawId?.toString() ?? '') ?? 0;

      if (did != 0) {
        await SharedPrefHelper.setData('doctor_id', did);
      }

      return did;
    } catch (_) {
      return 0;
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

    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
            key: _scaffoldKey,
            backgroundColor: theme.scaffoldBackgroundColor,
            drawer: const DoctorDrawer(),
            appBar: AppBar(
              toolbarHeight: 75.6,
              elevation: 0,
              backgroundColor: Theme.of(context).colorScheme.surface,
              foregroundColor: Theme.of(context).colorScheme.onSurface,
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
                        NotificationHelper.hasUnreadNotifications = false;
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const NotificationsScreen()),
                        ).then((_) {
                          if (mounted) setState(() {});
                        });
                      },
                    ),
                    if (NotificationHelper.getUnreadCount() > 0)
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
                            NotificationHelper.getUnreadCount() > 9 ? '9+' : '${NotificationHelper.getUnreadCount()}',
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
                child: Container(
                  height: 1.1,
                  color: isDark ? Colors.grey[700]! : const Color(0xFFE5E7EB),
                ),
              ),
            ),
            body: _buildMainContent(context, width, height, baseFontSize),
      ),
    );
  }

  void _showBookingDetails({
    required BuildContext context,
    required String patientName,
    required String phone,
    required String date,
    required String status,
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
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[600] : Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              // Patient Icon instead of image
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFF1D61E7).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.person_outline,
                  color: const Color(0xFF1D61E7),
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                patientName,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.w700,
                  fontSize: baseFontSize * 1.25,
                ),
              ),
              const SizedBox(height: 20),
              Divider(color: isDark ? Colors.grey[700] : const Color(0xFFE5E7EB)),
              const SizedBox(height: 12),
              _buildDetailRow(
                context: context,
                icon: Icons.phone_outlined,
                label: 'رقم الهاتف',
                value: phone,
                baseFontSize: baseFontSize,
              ),
              const SizedBox(height: 14),
              _buildDetailRow(
                context: context,
                icon: Icons.calendar_month_outlined,
                label: 'تاريخ الحجز',
                value: date,
                baseFontSize: baseFontSize,
              ),
              const SizedBox(height: 14),
              _buildDetailRow(
                context: context,
                icon: Icons.info_outline,
                label: 'الحالة',
                value: status,
                baseFontSize: baseFontSize,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.check_circle_outline, color: Colors.white),
                  label: const Text(
                    'تم',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1D61E7),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
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
      textDirection: TextDirection.rtl,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[800] : const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: const Color(0xFF021433)),
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

  Widget _buildBookingCard({
    required BuildContext context,
    required String patientName,
    required String phone,
    required String date,
    required String status,
    required Color statusColor,
    required double width,
    required double baseFontSize,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => _showBookingDetails(
        context: context,
        patientName: patientName,
        phone: phone,
        date: date,
        status: status,
        baseFontSize: baseFontSize,
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.cardTheme.color ?? colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDark ? Colors.grey[700]! : const Color(0xFFE5E7EB)),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withAlpha((0.3 * 255).round())
                  : Colors.grey.withAlpha((0.08 * 255).round()),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          textDirection: TextDirection.rtl,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Patient Icon (instead of image)
            Container(
              width: 52 * (width / 390),
              height: 52 * (width / 390),
              decoration: BoxDecoration(
                color: const Color(0xFF1D61E7).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.person_outline,
                color: const Color(0xFF1D61E7),
                size: 28 * (width / 390),
              ),
            ),
            const SizedBox(width: 12),
            // Patient Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    patientName,
                    textAlign: TextAlign.right,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.w600,
                      fontSize: baseFontSize * 1.0,
                    ),
                  ),
                  if (phone.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      phone,
                      textAlign: TextAlign.right,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontFamily: 'Cairo',
                        fontSize: baseFontSize * 0.85,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                  if (date.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      date,
                      textAlign: TextAlign.right,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontFamily: 'Cairo',
                        fontSize: baseFontSize * 0.75,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Status badge
            Container(
              padding: EdgeInsets.symmetric(
                  horizontal: 10 * (width / 390), vertical: 4 * (width / 390)),
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                status,
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.bold,
                  fontSize: baseFontSize * 0.7,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent(BuildContext context, double width, double height, double baseFontSize) {
    final theme = Theme.of(context);

    return BlocBuilder<AppointmentsCubit, AppointmentsState>(
      builder: (context, state) {
        // Show loading for initial and loading states
        if (state is AppointmentsInitial || state is AppointmentsLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is AppointmentsError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(state.message, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () async {
                    final cubit = context.read<AppointmentsCubit>();
                    final doctorId = await _extractDoctorIdFromToken();
                    if (doctorId != 0 && mounted) {
                      cubit.loadAppointmentsByDoctorId(doctorId);
                    }
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('إعادة المحاولة'),
                ),
              ],
            ),
          );
        }

        if (state is AppointmentsLoaded) {
          final appointments = state.appointments;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Text(
                    'سجل الحجوزات',
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
                if (appointments.isEmpty)
                  Center(
                    child: Column(
                      children: [
                        const SizedBox(height: 60),
                        Icon(Icons.calendar_today_outlined, size: 64, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text(
                          'لا توجد حجوزات مسجلة',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: baseFontSize * 1.1,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ...appointments.map((appt) {
                    final appointment = appt as AppointmentModel;
                    final status = appointment.displayStatus;
                    final statusColor = status == 'مؤكد' ? Colors.green : Colors.orange;
                    return Column(
                      children: [
                        _buildBookingCard(
                          context: context,
                          patientName: appointment.patientFullName.isNotEmpty
                              ? appointment.patientFullName
                              : 'مريض',
                          phone: appointment.patientPhoneNumber ?? '',
                          date: _formatDate(appointment.createdAt),
                          status: status,
                          statusColor: statusColor,
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
          );
        }

        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';
    try {
      final dt = DateTime.parse(dateStr);
      return '${dt.day.toString().padLeft(2, '0')}/'
          '${dt.month.toString().padLeft(2, '0')}/'
          '${dt.year}';
    } catch (_) {
      return dateStr;
    }
  }
}
