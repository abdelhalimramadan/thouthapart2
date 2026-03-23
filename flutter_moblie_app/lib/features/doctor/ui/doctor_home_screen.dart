import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../../../core/helpers/constants.dart';
import '../../../../core/helpers/shared_pref_helper.dart';
import '../../../../core/utils/notification_helper.dart';
import '../widgets/doctor_drawer_screen.dart';
import '../../notifications/ui/notifications_screen.dart';
import '../../../../core/di/dependency_injection.dart';
import '../../../../core/networking/api_service.dart';

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
  bool _isLoadingAppointments = true;
  String? _appointmentsError;

  // ── Lifecycle ──────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    // Run both fetches in parallel — faster startup
    Future.wait([_fetchDoctorName(), _fetchPendingAppointments()]);
  }

  // ── Data Fetching ──────────────────────────────────────────────

  /// Fetches the doctor's first name from cache or API, then saves the
  /// Fetch doctor's name from cache or token
  Future<void> _fetchDoctorName() async {
    try {
      // Try cache first — avoids unnecessary network call
      final cached = await SharedPrefHelper.getString('first_name');
      if (cached.isNotEmpty) {
        if (mounted)
          setState(() {
            _firstName = cached;
            _isLoadingName = false;
          });
        return;
      }

      // Decode JWT token directly — no extra HTTP call needed
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
              }
            }
          }
        } catch (_) {}
      }
    } catch (_) {
      // Silently fail — UI shows fallback "دكتور"
    } finally {
      if (mounted) setState(() => _isLoadingName = false);
    }
  }

  Future<void> _fetchPendingAppointments() async {
    if (!mounted) return;
    setState(() {
      _isLoadingAppointments = true;
      _appointmentsError = null;
    });

    try {
      final result = await _apiService.getPendingAppointments();



      if (!mounted) return;

      if (result['success'] == true) {
        final data = result['data'];

        setState(() {
          _pendingAppointments = List<Map<String, dynamic>>.from(data as List);
          _isLoadingAppointments = false;
        });
      } else {
        final error = result['error']?.toString() ?? 'فشل في تحميل الحجوزات';

        setState(() {
          _appointmentsError = error;
          _isLoadingAppointments = false;
        });
      }
    } catch (e, stack) {


      if (mounted)
        setState(() {
          _isLoadingAppointments = false;
          _appointmentsError = 'حدث خطأ غير متوقع: $e';
        });
    }
  }

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
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
          ),
          padding: EdgeInsets.only(
            top: 20.h,
            left: 20.w,
            right: 20.w,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 28.h,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[600] : Colors.grey[300],
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              SizedBox(height: 20.h),
              // Patient name
              Text(
                patientName,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.w700,
                  fontSize: 20.sp,
                ),
              ),
              SizedBox(height: 20.h),
              Divider(
                  color: isDark ? Colors.grey[700] : const Color(0xFFE5E7EB)),
              SizedBox(height: 12.h),
              // Phone
              _buildDetailRow(
                context: context,
                icon: Icons.phone_outlined,
                label: 'رقم الهاتف',
                value: phone,
              ),
              SizedBox(height: 14.h),
              // Date
              _buildDetailRow(
                context: context,
                icon: Icons.calendar_month_outlined,
                label: 'التاريخ',
                value: date,
              ),
              SizedBox(height: 14.h),
              // Time
              _buildDetailRow(
                context: context,
                icon: Icons.access_time_outlined,
                label: 'الوقت',
                value: time,
              ),
              SizedBox(height: 14.h),
              // Specialty
              _buildDetailRow(
                context: context,
                icon: Icons.medical_services_outlined,
                label: 'التخصص',
                value: service,
              ),
              SizedBox(height: 24.h),
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
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                          side: const BorderSide(color: Color(0xFF16A34A)),
                        ),
                      ),
                      child: Text(
                        'قبول',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.w600,
                          fontSize: 14.sp,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
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
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                          side: const BorderSide(color: Color(0xFFE7000B)),
                        ),
                      ),
                      child: Text(
                        'رفض',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.w600,
                          fontSize: 14.sp,
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
          width: 38.w,
          height: 38.w,
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[800] : const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Icon(icon, size: 18.r, color: const Color(0xFF021433)),
        ),
        SizedBox(width: 12.w),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 12.sp,
                color: Colors.grey,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.w600,
                fontSize: 14.sp,
              ),
            ),
          ],
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
              'تم ${status == 'APPROVED' ? 'قبول' : 'رفض'} الحجز بنجاح',
              style: const TextStyle(fontFamily: 'Cairo'),
            ),
            backgroundColor:
                status == 'APPROVED' ? Colors.green : Colors.orange,
            duration: const Duration(seconds: 2),
          ),
        );

        // Refresh the list after a short delay
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          _fetchPendingAppointments();
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

  void _openNotifications() {
    NotificationHelper.hasUnreadNotifications = false;
    Navigator.push(context,
            MaterialPageRoute(builder: (_) => const NotificationsScreen()))
        .then((_) {
      if (mounted) setState(() {});
    });
  }

  // ── Build ──────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;
    final unreadCount = NotificationHelper.getUnreadCount();

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: theme.scaffoldBackgroundColor,
      drawer: const DoctorDrawer(),
      appBar: _buildAppBar(cs, tt, unreadCount, theme),
      body: RefreshIndicator(
        onRefresh: _fetchPendingAppointments,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildGreeting(),
              _buildSectionTitle('حجوزاتي القادمة'),
              _buildAppointmentsSection(),
              SizedBox(height: 40.h),
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
    int unreadCount,
    ThemeData theme,
  ) {
    final cs = theme.colorScheme;
    final isDark = cs.brightness == Brightness.dark;
    return AppBar(
      toolbarHeight: 70.h,
      elevation: 0,
      backgroundColor: isDark ? Colors.transparent : Colors.white,
      foregroundColor: cs.onSurface,
      automaticallyImplyLeading: false,
      leading: IconButton(
        icon: Icon(Icons.menu, size: 24.r),
        onPressed: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      titleSpacing: 0,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/splash-logo.png',
            width: 36.w,
            height: 36.w,
            fit: BoxFit.contain,
          ),
          SizedBox(width: 8.w),
          Text(
            'لوحة التحكم',
            style: tt.titleLarge?.copyWith(
              fontFamily: 'Cairo',
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
      actions: [
        Stack(children: [
          IconButton(
            icon: Icon(Icons.notifications_none, size: 24.r),
            onPressed: _openNotifications,
          ),
          if (unreadCount > 0)
            Positioned(
              right: 8.w,
              top: 10.h,
              child: Container(
                width: 16.w,
                height: 16.w,
                decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.error,
                    shape: BoxShape.circle),
                child: Center(
                  child: Text(
                    unreadCount > 9 ? '9+' : '$unreadCount',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.onError,
                          fontSize: 10.sp,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ),
            ),
        ]),
        SizedBox(width: 8.w),
      ],
      bottom: PreferredSize(
        preferredSize: Size.fromHeight(1.h),
        child: Divider(
          height: 1,
          color: theme.dividerColor.withAlpha(isDark ? 50 : 255),
        ),
      ),
    );
  }

  // ── Greeting ───────────────────────────────────────────────────
  Widget _buildGreeting() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 20.h, 16.w, 10.h),
      child: _isLoadingName
          ? SizedBox(
              height: 30.h, child: const CircularProgressIndicator(strokeWidth: 2))
          : Text(
              _firstName != null
                  ? 'مرحباً، د/ $_firstName 👋'
                  : 'مرحباً، دكتور 👋',
              textAlign: TextAlign.right,
              textDirection: ui.TextDirection.rtl,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 22.sp,
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
      padding: EdgeInsets.fromLTRB(16.w, 18.h, 16.w, 6.h),
      child: Align(
        alignment: Alignment.centerRight,
        child: Text(
          title,
          style: TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.w700,
            fontSize: 16.sp,
            color: isDarkMode ? Colors.white70 : const Color(0xFF111827),
          ),
        ),
      ),
    );
  }

  // ── Appointments section ──────────────────────────────────────
  Widget _buildAppointmentsSection() {
    if (_isLoadingAppointments) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 40.h),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_appointmentsError != null) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        child: Column(
          children: [
            Text(_appointmentsError!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontFamily: 'Cairo', color: Colors.redAccent)),
            SizedBox(height: 8.h),
            TextButton.icon(
              onPressed: _fetchPendingAppointments,
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المحاولة',
                  style: TextStyle(fontFamily: 'Cairo')),
            ),
          ],
        ),
      );
    }

    if (_pendingAppointments.isEmpty) {
      final isDarkMode = Theme.of(context).brightness == Brightness.dark;
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 40.h),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.calendar_today_outlined,
                  size: 48.r,
                  color: isDarkMode ? Colors.white24 : Colors.grey[300]),
              SizedBox(height: 12.h),
              Text(
                'لا توجد حجوزات قادمة حالياً',
                style: TextStyle(
                    fontFamily: 'Cairo',
                    color: isDarkMode ? Colors.white38 : Colors.grey,
                    fontSize: 15.sp),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.only(top: 10.h, bottom: 8.h),
      itemCount: _pendingAppointments.length,
      separatorBuilder: (_, __) => SizedBox(height: 16.h),
      itemBuilder: (_, i) {
        final appointment = _pendingAppointments[i];

        // Parse dateTime correctly using the correct API key 'appointmentDate'
        final String rawDateTime = appointment['appointmentDate'] ?? '';
        String displayDate = appointment['date'] ?? 'غير محدد';
        String displayTime = appointment['time'] ?? 'غير محدد';

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

        return _AppointmentCard(
          appointment: appointment,
          displayDate: displayDate,
          displayTime: displayTime,
          onTap: () => _showAppointmentDetails(
            context: context,
            appointmentId: appointment['id'] ?? 0,
            patientName:
                '${appointment['patientFirstName'] ?? 'مريض'} ${appointment['patientLastName'] ?? ''}'
                    .trim(),
            phone: appointment['patientPhoneNumber'] ?? 'غير متوفر',
            date: displayDate,
            time: displayTime,
            service: appointment['categoryName'] ?? 'تخصص عام',
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _AppointmentCard — stateless, const-safe
// ─────────────────────────────────────────────────────────────────────────────
class _AppointmentCard extends StatelessWidget {
  final Map<String, dynamic> appointment;
  final String displayDate;
  final String displayTime;
  final VoidCallback onTap;

  const _AppointmentCard({
    required this.appointment,
    required this.displayDate,
    required this.displayTime,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final patientName =
        '${appointment['patientFirstName'] ?? 'مريض'} ${appointment['patientLastName'] ?? ''}'
            .trim();
    final phone = appointment['patientPhoneNumber'] ?? 'غير متوفر';
    final service = appointment['categoryName'] ?? 'تخصص عام';
    final status = appointment['status'] ?? 'قادم';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statusColor = const Color(0xFF84E5F3);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 16.w),
        padding: EdgeInsets.all(14.r),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[900]?.withAlpha(200) : Colors.white,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
              color: isDark ? Colors.grey[800]! : const Color(0xFFE5E7EB)),
          boxShadow: [
            BoxShadow(
                color: isDark
                    ? Colors.black.withOpacity(0.3)
                    : Colors.black.withOpacity(0.05),
                blurRadius: 8.r,
                offset: Offset(0, 3.h)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Header: Patient Name | Status Badge
            Row(
              textDirection: ui.TextDirection.rtl,
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: 10.w,
                      vertical: 4.h),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.bold,
                      fontSize: 12.sp,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    patientName,
                    textAlign: TextAlign.right,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.blue[300] : const Color(0xFF1D61E7),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 6.h),
            // Service/Category
            Row(
              textDirection: ui.TextDirection.rtl,
              children: [
                Icon(Icons.medical_services_outlined,
                    size: 14.r, color: Colors.grey[500]),
                SizedBox(width: 4.w),
                Expanded(
                  child: Text(
                    service,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 13.sp,
                        color: Colors.grey[600]),
                  ),
                ),
              ],
            ),
            SizedBox(height: 10.h),
            // Phone + Date/Time chips
            Row(
              textDirection: ui.TextDirection.rtl,
              children: [
                _InfoChip(
                    icon: Icons.phone_outlined,
                    text: phone),
              ],
            ),
            SizedBox(height: 8.h),
            Row(
              textDirection: ui.TextDirection.rtl,
              children: [
                _InfoChip(
                    icon: Icons.calendar_today_outlined,
                    text: displayDate),
                SizedBox(width: 8.w),
                _InfoChip(
                    icon: Icons.access_time_outlined,
                    text: displayTime),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
          color: isDark ? Colors.grey[800]?.withAlpha(150) : Colors.grey[100],
          borderRadius: BorderRadius.circular(8.r)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 13.r, color: isDark ? Colors.blue[300] : const Color(0xFF1D61E7)),
        SizedBox(width: 4.w),
        Text(text,
            style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 11.sp,
                color: isDark ? Colors.white70 : Colors.grey[800])),
      ]),
    );
  }
}
