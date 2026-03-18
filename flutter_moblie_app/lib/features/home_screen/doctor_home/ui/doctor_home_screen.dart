import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/helpers/constants.dart';
import '../../../../core/helpers/shared_pref_helper.dart';
import '../../../../core/utils/notification_helper.dart';
import '../drawer/doctor_drawer_screen.dart';
import '../../../notifications/ui/notifications_screen.dart';
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
      print('=== DEBUG: Calling getPendingAppointments() ===');
      final result = await _apiService.getPendingAppointments();

      print('=== DEBUG: API Response: $result ===');

      if (!mounted) return;

      if (result['success'] == true) {
        final data = result['data'];
        print('=== DEBUG: Data received: $data ===');
        setState(() {
          _pendingAppointments = List<Map<String, dynamic>>.from(data as List);
          _isLoadingAppointments = false;
        });
      } else {
        final error = result['error']?.toString() ?? 'فشل في تحميل الحجوزات';
        print('=== DEBUG: API Error: $error ===');
        setState(() {
          _appointmentsError = error;
          _isLoadingAppointments = false;
        });
      }
    } catch (e, stack) {
      print('=== DEBUG: Exception: $e ===');
      print('=== DEBUG: Stack trace: $stack ===');
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
                        padding: const EdgeInsets.symmetric(vertical: 12),
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
                          fontSize: baseFontSize * 0.9,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
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
                        padding: const EdgeInsets.symmetric(vertical: 12),
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
                          fontSize: baseFontSize * 0.9,
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
    final width = MediaQuery.of(context).size.width;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;
    final baseFontSize = width * 0.04;
    final unreadCount = NotificationHelper.getUnreadCount();

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      drawer: const DoctorDrawer(),
      appBar: _buildAppBar(width, cs, tt, baseFontSize, unreadCount),
      body: RefreshIndicator(
        onRefresh: _fetchPendingAppointments,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildGreeting(width, baseFontSize),
              _buildSectionTitle('حجوزاتي القادمة', width, baseFontSize),
              _buildAppointmentsSection(width, baseFontSize),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // ── AppBar ─────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar(
    double width,
    ColorScheme cs,
    TextTheme tt,
    double baseFontSize,
    int unreadCount,
  ) {
    return AppBar(
      toolbarHeight: 70,
      elevation: 0,
      backgroundColor: Colors.white,
      foregroundColor: cs.onSurface,
      automaticallyImplyLeading: false,
      leading: IconButton(
        icon: const Icon(Icons.menu, size: 24),
        onPressed: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      titleSpacing: 0,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/splash-logo.png',
            width: 36 * (width / 390),
            height: 36 * (width / 390),
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 8),
          Text(
            'لوحة التحكم',
            style: tt.titleLarge?.copyWith(
              fontFamily: 'Cairo',
              fontSize: baseFontSize * 1.125,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
      actions: [
        Stack(children: [
          IconButton(
            icon: const Icon(Icons.notifications_none, size: 24),
            onPressed: _openNotifications,
          ),
          if (unreadCount > 0)
            Positioned(
              right: 8,
              top: 10,
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.error,
                    shape: BoxShape.circle),
                child: Center(
                  child: Text(
                    unreadCount > 9 ? '9+' : '$unreadCount',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.onError,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ),
            ),
        ]),
        const SizedBox(width: 8),
      ],
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(height: 1, color: Color(0xFFE5E7EB)),
      ),
    );
  }

  // ── Greeting ───────────────────────────────────────────────────
  Widget _buildGreeting(double width, double baseFontSize) {
    return Padding(
      padding: EdgeInsets.fromLTRB(width * 0.05, 20, width * 0.05, 10),
      child: _isLoadingName
          ? const SizedBox(
              height: 30, child: CircularProgressIndicator(strokeWidth: 2))
          : Text(
              _firstName != null
                  ? 'مرحباً، د/ $_firstName 👋'
                  : 'مرحباً، دكتور 👋',
              textAlign: TextAlign.right,
              textDirection: ui.TextDirection.rtl,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: baseFontSize * 1.4,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF111827),
              ),
            ),
    );
  }

  // ── Section title ──────────────────────────────────────────────
  Widget _buildSectionTitle(String title, double width, double baseFontSize) {
    return Padding(
      padding: EdgeInsets.fromLTRB(width * 0.05, 18, width * 0.05, 6),
      child: Align(
        alignment: Alignment.centerRight,
        child: Text(
          title,
          style: TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.w700,
            fontSize: baseFontSize * 1.1,
            color: const Color(0xFF111827),
          ),
        ),
      ),
    );
  }

  // ── Appointments section ──────────────────────────────────────
  Widget _buildAppointmentsSection(double width, double baseFontSize) {
    if (_isLoadingAppointments) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_appointmentsError != null) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: width * 0.05, vertical: 16),
        child: Column(
          children: [
            Text(_appointmentsError!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontFamily: 'Cairo', color: Colors.redAccent)),
            const SizedBox(height: 8),
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
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: width * 0.05, vertical: 40),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.calendar_today_outlined,
                  size: 48, color: Colors.grey[300]),
              const SizedBox(height: 12),
              const Text(
                'لا توجد حجوزات قادمة حالياً',
                style: TextStyle(
                    fontFamily: 'Cairo', color: Colors.grey, fontSize: 15),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.only(top: 10, bottom: 8),
      itemCount: _pendingAppointments.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
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
          width: width,
          baseFontSize: baseFontSize,
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
            baseFontSize: baseFontSize,
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
  final double width;
  final double baseFontSize;
  final VoidCallback onTap;

  const _AppointmentCard({
    required this.appointment,
    required this.displayDate,
    required this.displayTime,
    required this.width,
    required this.baseFontSize,
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
    final statusColor = const Color(0xFF84E5F3);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: width * 0.04),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 3)),
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
                      horizontal: 10 * (width / 390),
                      vertical: 4 * (width / 390)),
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
                Expanded(
                  child: Text(
                    patientName,
                    textAlign: TextAlign.right,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: baseFontSize,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1D61E7),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            // Service/Category
            Row(
              textDirection: ui.TextDirection.rtl,
              children: [
                Icon(Icons.medical_services_outlined,
                    size: 14, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    service,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: baseFontSize * 0.8,
                        color: Colors.grey[600]),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Phone + Date/Time chips
            Row(
              textDirection: ui.TextDirection.rtl,
              children: [
                _InfoChip(
                    icon: Icons.phone_outlined,
                    text: phone,
                    baseFontSize: baseFontSize),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              textDirection: ui.TextDirection.rtl,
              children: [
                _InfoChip(
                    icon: Icons.calendar_today_outlined,
                    text: displayDate,
                    baseFontSize: baseFontSize),
                const SizedBox(width: 8),
                _InfoChip(
                    icon: Icons.access_time_outlined,
                    text: displayTime,
                    baseFontSize: baseFontSize),
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
  final double baseFontSize;
  const _InfoChip(
      {required this.icon, required this.text, required this.baseFontSize});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
          color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 13, color: const Color(0xFF1D61E7)),
        const SizedBox(width: 4),
        Text(text,
            style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: baseFontSize * 0.72,
                color: Colors.grey[800])),
      ]),
    );
  }
}
