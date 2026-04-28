import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/helpers/constants.dart';
import '../../../../core/helpers/shared_pref_helper.dart';
import '../../../../core/utils/notification_helper.dart';
import '../../../../core/routing/routes.dart';
import '../drawer_doctor/doctor_drawer_screen.dart';
import '../../notifications/ui/notifications_screen.dart';
import '../../../../core/di/dependency_injection.dart';
import '../../../../core/networking/api_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../notifications/logic/notifications_cubit.dart';
import '../widgets/appointment_card_widget.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DoctorHomeScreen
// ─────────────────────────────────────────────────────────────────────────────
class DoctorHomeScreen extends StatefulWidget {
  const DoctorHomeScreen({super.key});

  @override
  State<DoctorHomeScreen> createState() => _DoctorHomeScreenState();
}

class _DoctorHomeScreenState extends State<DoctorHomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ApiService _apiService = getIt<ApiService>();

  // ── State ──────────────────────────────────────────────────────
  String? _firstName;
  bool _isLoadingName = true;

  List<Map<String, dynamic>> _pendingAppointments = [];
  List<Map<String, dynamic>> _approvedAppointments = [];
  bool _isLoadingAppointments = true;
  String? _appointmentsError;

  // ── Lifecycle ──────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    // Run both fetches in parallel — faster startup
    Future.wait([_fetchDoctorName(), _fetchAllAppointments()]);
  }

  // ── Data Fetching ──────────────────────────────────────────────

  /// Fetches the doctor's first name from JWT token (priority 1),
  /// then API (priority 2), cache is NOT used to avoid stale data
  Future<void> _fetchDoctorName() async {
    try {
      // Priority 1: Try JWT token first
      final token =
          await SharedPrefHelper.getSecuredString(SharedPrefKeys.userToken);
      if (token != null && token.isNotEmpty) {
        try {
          final parts = token.split('.');
          if (parts.length == 3) {
            String payload = parts[1];
            while (payload.length % 4 != 0) {
              payload += '=';
            }
            final decoded =
                json.decode(utf8.decode(base64Url.decode(payload))) as Map?;
            if (decoded != null) {
              // Extract name
              final fn = (decoded['firstName'] ??
                      decoded['first_name'] ??
                      decoded['name'])
                  ?.toString();
              if (fn != null && fn.isNotEmpty) {
                await SharedPrefHelper.setData('first_name', fn);
                if (mounted) setState(() => _firstName = fn);
                return; // Success — exit early
              }
            }
          }
        } catch (_) {}
      }

      // Priority 2: Fetch from API if token decode fails
      try {
        final result = await _apiService.getDoctorById();
        if (result['success'] == true && result['data'] != null) {
          // ignore: avoid_dynamic_calls
          final fn =
              result['data']['firstName'] ?? result['data']['first_name'];
          if (fn != null && fn.toString().isNotEmpty) {
            final fnStr = fn.toString();
            await SharedPrefHelper.setData('first_name', fnStr);
            if (mounted) setState(() => _firstName = fnStr);
            return;
          }
        }
      } catch (_) {}
    } catch (_) {
      // Silently fail — UI shows fallback "دكتور"
    } finally {
      if (mounted) setState(() => _isLoadingName = false);
    }
  }

  Future<void> _fetchAllAppointments() async {
    if (!mounted) return;
    setState(() {
      _isLoadingAppointments = true;
      _appointmentsError = null;
    });

    try {
      final results = await Future.wait([
        _apiService.getPendingAppointments(),
        _apiService.getApprovedAppointments(),
        _apiService.getDoneAppointments(),
      ]);

      final pendingResult = results[0];
      final approvedResult = results[1];
      final doneResult = results[2];

      if (!mounted) return;

      // Check for unauthorized errors (401 or specific bad responses indicating dead session/deleted account)
      bool isUnauthorized = false;
      for (final res in results) {
        if (res['success'] == false) {
          final code = res['statusCode'];
          final errorStr = res['error']?.toString() ?? '';
          if (code == 401 || 
              code == 400 || 
              errorStr.contains('غير مصرح') || 
              errorStr.contains('static resource') || 
              errorStr.contains('المورد الثابت')) {
            isUnauthorized = true;
            break;
          }
        }
      }

      if (isUnauthorized) {
        // Wipe all dead data
        await SharedPrefHelper.clearAllData();
        await SharedPrefHelper.clearAllSecuredData();
        await SharedPrefHelper.setData('has_seen_onboarding', true);
        
        if (!mounted) return;
        
        // Show alert to user
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تسجيل الخروج لانتهاء الجلسة أو حذف الحساب', style: TextStyle(fontFamily: 'Cairo')),
            backgroundColor: Colors.redAccent,
          ),
        );
        
        // Redirect to Patient Home
        Navigator.of(context).pushNamedAndRemoveUntil(
          Routes.categoriesScreen,
          (route) => false,
        );
        return;
      }

      if (pendingResult['success'] == true && 
          approvedResult['success'] == true && 
          doneResult['success'] == true) {
        setState(() {
          _pendingAppointments = List<Map<String, dynamic>>.from(pendingResult['data'] as List);
          _approvedAppointments = [
            ...List<Map<String, dynamic>>.from(approvedResult['data'] as List),
            ...List<Map<String, dynamic>>.from(doneResult['data'] as List),
          ];
          _isLoadingAppointments = false;
        });
      } else {
        final error = (pendingResult['error'] ?? approvedResult['error'] ?? doneResult['error'])?.toString() ?? 'فشل في تحميل الحجوزات';
        setState(() {
          _appointmentsError = error;
          _isLoadingAppointments = false;
        });
      }
    } catch (e) {
      if (mounted)
        setState(() {
          _isLoadingAppointments = false;
          _appointmentsError = 'حدث خطأ غير متوقع: $e';
        });
    }
  }

  Future<void> _fetchPendingAppointments() => _fetchAllAppointments();

  // ── Actions ────────────────────────────────────────────────────

  void _showAppointmentDetails({
    required BuildContext context,
    required int appointmentId,
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
                  fontSize: 20,
                ),
              ),
              SizedBox(height: 20),
              Divider(
                  color: isDark ? Colors.grey[700] : const Color(0xFFE5E7EB)),
              SizedBox(height: 12),
              // Date
              _buildDetailRow(
                context: context,
                icon: Icons.calendar_month_outlined,
                label: 'التاريخ',
                value: date,
              ),
              SizedBox(height: 14),
              // Time
              _buildDetailRow(
                context: context,
                icon: Icons.access_time_outlined,
                label: 'الوقت',
                value: time,
              ),
              SizedBox(height: 14),
              // Specialty
              _buildDetailRow(
                context: context,
                icon: Icons.medical_services_outlined,
                label: 'التخصص',
                value: service,
              ),
              SizedBox(height: 24),
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _updateAppointmentStatus(
                        context,
                        appointmentId,
                        'APPROVED',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF0FDF4),
                        foregroundColor: const Color(0xFF16A34A),
                        elevation: 0,
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: const BorderSide(color: Color(0xFF16A34A)),
                        ),
                      ),
                      child: Text(
                        'قبول',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _updateAppointmentStatus(
                        context,
                        appointmentId,
                        'CANCELLED',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFEF2F2),
                        foregroundColor: const Color(0xFFE7000B),
                        elevation: 0,
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: const BorderSide(color: Color(0xFFE7000B)),
                        ),
                      ),
                      child: Text(
                        'رفض',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
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
          child: Icon(icon, size: 18, color: isDark ? Colors.white : const Color(0xFF021433)),
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
                  color: isDark ? Colors.white70 : Colors.grey,
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

  Future<void> _updateAppointmentStatus(
    BuildContext context,
    int appointmentId,
    String status,
  ) async {
    try {
      // Close the bottom sheet
      Navigator.pop(context);

      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      final result = await _apiService.updateAppointmentStatus(
        appointmentId,
        status,
      );

      if (!mounted) return;

      // Close loading dialog
      Navigator.pop(context);

      if (result['success'] == true) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              status == 'APPROVED'
                  ? 'تم قبول الحجز بنجاح'
                  : status == 'DONE'
                      ? 'تم تأكيد الحجز بنجاح'
                      : 'تم إلغاء الحجز بنجاح',
              style: const TextStyle(fontFamily: 'Cairo'),
            ),
            backgroundColor: status == 'APPROVED' || status == 'DONE'
                ? Colors.green
                : Colors.red,
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

      // Close loading dialog if still open
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

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

  // ── Build ──────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: theme.scaffoldBackgroundColor,
      drawer: const DoctorDrawer(),
      appBar: _buildAppBar(cs, tt, theme),
      body: RefreshIndicator(
        onRefresh: _fetchAllAppointments,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildGreeting(),
              _buildSectionTitle('حجوزاتي القادمة'),
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.38,
                child: _buildAppointmentsList(_pendingAppointments, isPending: true),
              ),
              const SizedBox(height: 10),
              _buildSectionTitle('الحالات المؤكدة'),
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.38,
                child: _buildAppointmentsList(_approvedAppointments, isPending: false),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // ── AppBar ─────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar(
    ColorScheme cs,
    TextTheme tt,
    ThemeData theme,
  ) {
    final cs = theme.colorScheme;
    final isDark = cs.brightness == Brightness.dark;
    return AppBar(
      toolbarHeight: 70,
      elevation: 0,
      backgroundColor: isDark ? Colors.transparent : Colors.white,
      foregroundColor: cs.onSurface,
      automaticallyImplyLeading: false,
      leading: IconButton(
        icon: Icon(Icons.menu, size: 24),
        onPressed: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      centerTitle: true,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'الصفحة الرئيسية',
            style: tt.titleLarge?.copyWith(
              fontFamily: 'Cairo',
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 8),
          Image.asset(
            'assets/images/splash-logo.png',
            width: 36,
            height: 36,
            fit: BoxFit.contain,
          ),
        ],
      ),
      actions: [
        BlocProvider(
          create: (_) => getIt<NotificationsCubit>()..fetchNotifications(),
          child: BlocBuilder<NotificationsCubit, NotificationsState>(
            builder: (context, state) {
              int reactiveUnreadCount = 0;
              if (state is SuccessState) {
                reactiveUnreadCount = state.notifications
                    .where((n) => !n.readStatus)
                    .length;
              }

              return Stack(children: [
                IconButton(
                  icon: Icon(Icons.notifications_none, size: 24),
                  onPressed: () {
                    NotificationHelper.hasUnreadNotifications = false;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const NotificationsScreen()),
                    ).then((_) {
                      // Refresh when coming back
                      if (context.mounted) {
                        context.read<NotificationsCubit>().fetchNotifications();
                      }
                    });
                  },
                ),
                if (reactiveUnreadCount > 0)
                  Positioned(
                    right: 8,
                    top: 10,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: reactiveUnreadCount > 9 ? 4 : 5,
                        vertical: 1,
                      ),
                      constraints: BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.error,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          '$reactiveUnreadCount',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: Theme.of(context).colorScheme.onError,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                    ),
                  ),
              ]);
            },
          ),
        ),
        SizedBox(width: 8),
      ],
    );
  }

  // ── Greeting ───────────────────────────────────────────────────
  Widget _buildGreeting() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 20, 16, 10),
      child: _isLoadingName
          ? SizedBox(
              height: 30,
              child: const CircularProgressIndicator(strokeWidth: 2))
          : Text(
              _firstName != null
                  ? 'مرحباً، د/ $_firstName 👋'
                  : 'مرحباً، دكتور 👋',
              textAlign: TextAlign.right,
              textDirection: ui.TextDirection.rtl,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : const Color(0xFF111827),
              ),
            ),
    );
  }

  // ── Section title ──────────────────────────────────────────────
  Widget _buildSectionTitle(String title) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 18, 16, 6),
      child: Align(
        alignment: Alignment.centerRight,
        child: Text(
          title,
          style: TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: isDarkMode ? Colors.white : const Color(0xFF111827),
          ),
        ),
      ),
    );
  }

  // ── Appointments list builder ──────────────────────────────────
  Widget _buildAppointmentsList(List<Map<String, dynamic>> appointments, {required bool isPending}) {
    if (_isLoadingAppointments) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_appointmentsError != null && isPending) { // Show error only in the first section
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          children: [
            Text(_appointmentsError!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontFamily: 'Cairo', color: Colors.redAccent)),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _fetchAllAppointments,
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المحاولة',
                  style: TextStyle(fontFamily: 'Cairo')),
            ),
          ],
        ),
      );
    }

    if (appointments.isEmpty) {
      final isDarkMode = Theme.of(context).brightness == Brightness.dark;
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isPending ? Icons.calendar_today_outlined : Icons.check_circle_outline,
                size: 40,
                color: isDarkMode ? Colors.white30 : Colors.grey[400],
              ),
              const SizedBox(height: 12),
              Text(
                isPending ? 'لا توجد حجوزات حالياً' : 'لا توجد حالات مؤكدة',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: isDarkMode ? Colors.white : const Color(0xFF0C4A6E),
                ),
              ),
              if (isPending) ...[
                const SizedBox(height: 12),
                _buildInstructionItem(
                  isDarkMode: isDarkMode,
                  icon: Icons.check_circle_outline,
                  iconColor: const Color(0xFF16A34A),
                  text: 'قبول الحجز لإضافته للحالات المؤكدة.',
                ),
                const SizedBox(height: 6),
                _buildInstructionItem(
                  isDarkMode: isDarkMode,
                  icon: Icons.cancel_outlined,
                  iconColor: const Color(0xFFE7000B),
                  text: 'رفض الحجز لإزالته نهائياً.',
                ),
              ],
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.only(top: 10, bottom: 20, left: 16, right: 16),
      itemCount: appointments.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) {
        final appointment = appointments[i];

        final String rawDateTime = appointment['appointmentDate'] ?? '';
        String displayDate = appointment['date'] ?? 'غير محدد';
        String displayTime = appointment['time'] ?? 'غير محدد';

        if (rawDateTime.isNotEmpty) {
          try {
            final dt = DateTime.parse(rawDateTime);
            displayDate = DateFormat('dd/MM/yyyy').format(dt);
            displayTime = DateFormat('hh:mm a', 'ar')
                .format(dt)
                .replaceAll('AM', 'صباحاً')
                .replaceAll('PM', 'مساءً');
          } catch (_) {}
        }

        return AppointmentCardWidget(
          context: context,
          patientName: '${appointment['patientFirstName'] ?? 'مريض'} ${appointment['patientLastName'] ?? ''}'.trim(),
          phone: appointment['patientPhoneNumber'] ?? 'غير متوفر',
          service: appointment['categoryName'] ?? 'تخصص عام',
          date: displayDate,
          time: displayTime,
          statusLabel: isPending ? 'قيد الانتظار' : 'مؤكدة',
          statusColor: isPending ? Colors.orange : Colors.greenAccent,
          showDetails: isPending,
          onTap: () {
             if (isPending) {
                Navigator.pushNamed(
                  context,
                  Routes.doctorNextBookingScreen,
                  arguments: {'appointmentId': appointment['id']},
                );
             } else {
                _showConfirmedDetails(
                  context: context,
                  appointment: appointment,
                  date: displayDate,
                  time: displayTime,
                );
             }
          },
        );
      },
    );
  }

  void _showConfirmedDetails({
    required BuildContext context,
    required Map<String, dynamic> appointment,
    required String date,
    required String time,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final patientName = '${appointment['patientFirstName'] ?? 'مريض'} ${appointment['patientLastName'] ?? ''}'.trim();
    final phone = appointment['patientPhoneNumber'] ?? 'غير متوفر';
    final service = appointment['categoryName'] ?? 'تخصص عام';

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
              Text(
                patientName,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
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
              ),
              const SizedBox(height: 14),
              _buildDetailRow(
                context: context,
                icon: Icons.calendar_month_outlined,
                label: 'التاريخ',
                value: date,
              ),
              const SizedBox(height: 14),
              _buildDetailRow(
                context: context,
                icon: Icons.access_time_outlined,
                label: 'الوقت',
                value: time,
              ),
              const SizedBox(height: 14),
              _buildDetailRow(
                context: context,
                icon: Icons.medical_services_outlined,
                label: 'التخصص',
                value: service,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('إغلاق', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Instruction item helper ────────────────────────────────────
  Widget _buildInstructionItem({
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
              color: isDarkMode ? Colors.white : const Color(0xFF475569),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _AppointmentCard — stateless, const-safe
// ─────────────────────────────────────────────────────────────────────────────
