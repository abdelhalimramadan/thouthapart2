import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/helpers/constants.dart';
import '../../../core/helpers/shared_pref_helper.dart';
import '../../../core/utils/notification_helper.dart';
import '../../../core/di/dependency_injection.dart';
import '../drawer/doctor_drawer_screen.dart';
import '../../notifications/ui/notifications_screen.dart';
import '../../appointments/logic/appointments_cubit.dart';
import '../../appointments/logic/appointments_state.dart';
import '../../appointments/data/models/appointment_model.dart';

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
  late final AppointmentsCubit _cubit;

  // ── State ──────────────────────────────────────────────────────
  String? _firstName;
  bool _isLoadingName = true;

  // ── Lifecycle ──────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _cubit = getIt<AppointmentsCubit>();
    _fetchDoctorName();
    _loadAppointments();
  }

  Future<void> _loadAppointments() async {
    final doctorId = await _extractDoctorIdFromToken();
    if (doctorId != 0 && mounted) {
      _cubit.loadAppointmentsByDoctorId(doctorId);
    }
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
  void dispose() {
    _cubit.close();
    super.dispose();
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

  // ── Actions ────────────────────────────────────────────────────

  void _openAppointmentDetails(AppointmentModel appointment) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AppointmentDetailsSheet(appointment: appointment),
    );
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

    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: Colors.white,
        drawer: const DoctorDrawer(),
        appBar: _buildAppBar(width, cs, tt, baseFontSize, unreadCount),
        body: BlocBuilder<AppointmentsCubit, AppointmentsState>(
          builder: (context, state) {
            return RefreshIndicator(
              onRefresh: () => _loadAppointments(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildGreeting(width, baseFontSize),
                    _buildSectionTitle('حجوزاتي القادمة', width, baseFontSize),
                    _buildAppointmentsSection(context, state, width, baseFontSize),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            );
          },
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
              textDirection: TextDirection.rtl,
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

  // ── Appointments section ──────────────────────────────────────────────
  Widget _buildAppointmentsSection(BuildContext context, AppointmentsState state, double width, double baseFontSize) {
    if (state is AppointmentsLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (state is AppointmentsError) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: width * 0.05, vertical: 16),
        child: Column(
          children: [
            Text(state.message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontFamily: 'Cairo', color: Colors.redAccent)),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => _loadAppointments(),
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المحاولة',
                  style: TextStyle(fontFamily: 'Cairo')),
            ),
          ],
        ),
      );
    }

    if (state is AppointmentsLoaded) {
      final appointments = state.appointments;
      
      if (appointments.isEmpty) {
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: width * 0.05, vertical: 40),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.calendar_today_outlined,
                    size: 48, color: Colors.grey[300]),
                const SizedBox(height: 12),
                const Text(
                  'لا توجد حجوزات مسجلة حالياً',
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
        itemCount: appointments.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (_, i) {
          final appointment = appointments[i] as AppointmentModel;
          return _AppointmentCard(
            appointment: appointment,
            width: width,
            baseFontSize: baseFontSize,
            onTap: () => _openAppointmentDetails(appointment),
          );
        },
      );
    }

    return const SizedBox.shrink();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _AppointmentCard — stateless, const-safe
// ─────────────────────────────────────────────────────────────────────────────
class _AppointmentCard extends StatelessWidget {
  final AppointmentModel appointment;
  final double width;
  final double baseFontSize;
  final VoidCallback onTap;

  const _AppointmentCard({
    required this.appointment,
    required this.width,
    required this.baseFontSize,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
            // Header: id badge + status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (appointment.id != null)
                  _IdBadge(id: appointment.id!, baseFontSize: baseFontSize),
                _StatusBadge(
                  status: appointment.displayStatus,
                  baseFontSize: baseFontSize,
                ),
              ],
            ),
            const SizedBox(height: 6),
            // Patient name
            Row(children: [
              Icon(Icons.person_outline, size: 14, color: Colors.grey[500]),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  appointment.patientFullName.isNotEmpty
                      ? appointment.patientFullName
                      : 'مريض',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: baseFontSize * 0.9,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800]),
                ),
              ),
            ]),
            // Phone number
            if (appointment.patientPhoneNumber?.isNotEmpty == true) ...[
              const SizedBox(height: 6),
              Row(children: [
                Icon(Icons.phone_outlined, size: 14, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    appointment.patientPhoneNumber!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: baseFontSize * 0.8,
                        color: Colors.grey[600]),
                  ),
                ),
              ]),
            ],
            const SizedBox(height: 10),
            // Created date chip
            Row(children: [
              _InfoChip(
                  icon: Icons.calendar_today_outlined,
                  text: _formatDate(appointment.createdAt),
                  baseFontSize: baseFontSize),
            ]),
          ],
        ),
      ),
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

class _IdBadge extends StatelessWidget {
  final int? id;
  final double baseFontSize;
  const _IdBadge({required this.id, required this.baseFontSize});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFF1D61E7).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '#${id ?? ""}',
        style: TextStyle(
          fontFamily: 'Cairo',
          fontSize: baseFontSize * 0.68,
          color: const Color(0xFF1D61E7),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  final double baseFontSize;
  const _StatusBadge({required this.status, required this.baseFontSize});

  @override
  Widget build(BuildContext context) {
    final isConfirmed = status == 'مؤكد';
    final color = isConfirmed ? Colors.green : Colors.orange;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontFamily: 'Cairo',
          fontSize: baseFontSize * 0.72,
          color: color,
          fontWeight: FontWeight.bold,
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

// ─────────────────────────────────────────────────────────────────────────────
// _AppointmentDetailsSheet — bottom sheet as separate widget
// ─────────────────────────────────────────────────────────────────────────────
class _AppointmentDetailsSheet extends StatelessWidget {
  final AppointmentModel appointment;
  const _AppointmentDetailsSheet({required this.appointment});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4)),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'تفاصيل الحجز',
            style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87),
          ),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 10),
          _DetailRow(
              icon: Icons.confirmation_number_outlined,
              label: 'رقم الحجز',
              value: '#${appointment.id ?? ""}'),
          _DetailRow(
              icon: Icons.person_outline,
              label: 'المريض',
              value: appointment.patientFullName.isNotEmpty
                  ? appointment.patientFullName
                  : 'غير محدد'),
          if (appointment.patientPhoneNumber?.isNotEmpty == true)
            _DetailRow(
                icon: Icons.phone_outlined,
                label: 'هاتف المريض',
                value: appointment.patientPhoneNumber!),
          _DetailRow(
              icon: Icons.info_outline,
              label: 'الحالة',
              value: appointment.displayStatus),
          if (appointment.createdAt?.isNotEmpty == true)
            _DetailRow(
                icon: Icons.calendar_today_outlined,
                label: 'تاريخ الإنشاء',
                value: _formatDate(appointment.createdAt)),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.check_circle_outline, color: Colors.white),
              label: Text(
                'تم',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1D61E7),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 2,
              ),
            ),
          ),
        ],
      ),
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

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _DetailRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Flexible(
              child: Text(value,
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontFamily: 'Cairo', fontSize: 14))),
          const SizedBox(width: 8),
          Text('$label:',
              style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 14,
                  fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Icon(icon, size: 18, color: const Color(0xFF1D61E7)),
        ],
      ),
    );
  }
}

class _SheetButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _SheetButton(
      {required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(label,
          style: const TextStyle(
              fontFamily: 'Cairo', fontSize: 15, fontWeight: FontWeight.bold)),
    );
  }
}
