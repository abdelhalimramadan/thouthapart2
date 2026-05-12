import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../notifications/logic/notifications_cubit.dart';
import '../../../../core/helpers/constants.dart';
import '../../../../core/helpers/shared_pref_helper.dart';
import '../../../../core/utils/notification_helper.dart';
import '../../../../core/routing/routes.dart';
import '../drawer_doctor/doctor_drawer_screen.dart';
import '../../notifications/ui/notifications_screen.dart';
import '../../../../core/di/dependency_injection.dart';
import '../../../../core/networking/api_service.dart';
import '../widgets/appointment_card_widget.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:showcaseview/showcaseview.dart';
import 'package:thoutha_mobile_app/tour/tour_config.dart';
import 'package:thoutha_mobile_app/tour/tour_service.dart';
import 'package:thoutha_mobile_app/tour/tour_widgets.dart';
<<<<<<< Updated upstream
=======
import 'package:thoutha_mobile_app/tour/multi_tour_widget.dart';
>>>>>>> Stashed changes

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
  late NotificationsCubit _notificationsCubit;
  bool _isTourStarted = false;

  // ── Lifecycle ──────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _notificationsCubit = getIt<NotificationsCubit>();
    // Run all fetches in parallel — faster startup
    Future.wait([
      _fetchDoctorName(),
      _fetchAllAppointments(),
      _notificationsCubit.fetchNotifications(showLoading: false),
    ]);
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
      // Silently fail — UI shows fallback 'doctor.doctor'.tr()
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
              code == 403 || 
              code == 400 || 
              errorStr.contains('doctor.unauthorized'.tr()) || 
              errorStr.contains('static resource') || 
              errorStr.contains('doctor.fixed_resource'.tr())) {
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
          SnackBar(
            content: Text('doctor.you_are_logged_out'.tr(), style: TextStyle(fontFamily: 'Cairo')),
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
        final error = (pendingResult['error'] ?? approvedResult['error'] ?? doneResult['error'])?.toString() ?? 'doctor.failed_to_load_reservations'.tr();
        setState(() {
          _appointmentsError = error;
          _isLoadingAppointments = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingAppointments = false;
          _appointmentsError = 'doctor.an_unexpected_error_occurred'.tr(namedArgs: {'e': e.toString()});
        });
      }
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
                  color: isDark ? Colors.grey[700] : Color(0xFFE5E7EB)),
              SizedBox(height: 12),
              // Date
              _buildDetailRow(
                context: context,
                icon: Icons.calendar_month_outlined,
                label: 'doctor.the_date'.tr(),
                value: date,
              ),
              SizedBox(height: 14),
              // Time
              _buildDetailRow(
                context: context,
                icon: Icons.access_time_outlined,
                label: 'doctor.the_time'.tr(),
                value: time,
              ),
              SizedBox(height: 14),
              // Specialty
              _buildDetailRow(
                context: context,
                icon: Icons.medical_services_outlined,
                label: 'doctor.specialization'.tr(),
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
                        backgroundColor: Color(0xFFF0FDF4),
                        foregroundColor: Color(0xFF16A34A),
                        elevation: 0,
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(color: Color(0xFF16A34A)),
                        ),
                      ),
                      child: Text(
                        'doctor.acceptance'.tr(),
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
                        backgroundColor: Color(0xFFFEF2F2),
                        foregroundColor: Color(0xFFE7000B),
                        elevation: 0,
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(color: Color(0xFFE7000B)),
                        ),
                      ),
                      child: Text(
                        'doctor.to_reject'.tr(),
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
            color: isDark ? Colors.grey[800] : Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: isDark ? Colors.white : Color(0xFF021433)),
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
        builder: (ctx) => Center(
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
                  ? 'doctor.your_reservation_has_been_2'.tr()
                  : status == 'DONE'
                      ? 'doctor.your_reservation_has_been'.tr()
                      : 'doctor.your_reservation_has_been_1'.tr(),
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

      // Close loading dialog if still open
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'doctor.an_unexpected_error_occurred'.tr(namedArgs: {'e': e.toString()}),
            style: TextStyle(fontFamily: 'Cairo'),
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
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

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        SystemNavigator.pop();
      },
      child: MultiTourWidget(
        child: ShowCaseWidget(
        onComplete: (index, key) {
          TourService.onDismiss(key)();
        },
        builder: (context) {
          if (!_isTourStarted) {
            _isTourStarted = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) TourService.startTourForScreen(context, 'doctor_home');
            });
          }
          return Scaffold(
        key: _scaffoldKey,
        backgroundColor: theme.scaffoldBackgroundColor,
        drawer: DoctorDrawer(),
        appBar: _buildAppBar(cs, tt, theme),
        body: RefreshIndicator(
          onRefresh: _fetchAllAppointments,
          child: SingleChildScrollView(
            physics: AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildGreeting(),
                // Tour: Pending Appointments Section
                Showcase.withWidget(
                      height: 150,
                      width: 280,
                  key: TourConfig.doctorHomePendingKey,
                  container: CustomTourTooltip(
                    title: 'الحجوزات المعلّقة',
                    description: 'حجوزات تحتاج قبولك أو رفضك',
                    onNext: () => ShowCaseWidget.of(context)!.next(),
                  ),
                  child: _buildSectionTitle(
                    'doctor.my_next_reservations'.tr(),
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        Routes.doctorNextBookingScreen,
                      );
                    },
                  ),
                ),
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.38,
                  child: _buildAppointmentsList(_pendingAppointments, isPending: true),
                ),
                SizedBox(height: 10),
                // Tour: Confirmed Cases Section
                Showcase.withWidget(
                      height: 150,
                      width: 280,
                  key: TourConfig.doctorHomeConfirmedKey,
                  container: CustomTourTooltip(
                    title: 'الحالات المؤكدة',
                    description: 'الحجوزات التي تم قبولها وتأكيدها',
                    onNext: () => ShowCaseWidget.of(context)!.next(),
                    isLast: true,
                  ),
                  child: _buildSectionTitle(
                    'doctor.confirmed_cases'.tr(),
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        Routes.doctorConfirmedAppointmentsScreen,
                      );
                    },
                  ),
                ),
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.38,
                  child: _buildAppointmentsList(_approvedAppointments, isPending: false),
                ),
                SizedBox(height: 40),
              ],
            ),
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
      leading: Showcase.withWidget(
                      height: 150,
                      width: 280,
        key: TourConfig.doctorHomeMenuKey,
        container: CustomTourTooltip(
          title: 'القائمة',
          description: 'افتح القائمة الجانبية لإدارة حسابك وحجوزاتك',
          onNext: () => ShowCaseWidget.of(context)!.next(),
        ),
        child: IconButton(
          icon: Icon(Icons.menu, size: 24),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
      ),
      centerTitle: true,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'doctor.home'.tr(),
            style: tt.titleLarge?.copyWith(
              fontFamily: 'Cairo',
              fontSize: 18,
              fontWeight: FontWeight.w700,
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
      actions: [
        BlocBuilder<NotificationsCubit, NotificationsState>(
          bloc: _notificationsCubit,
          builder: (context, state) {
            int unreadCount = 0;
            if (state is SuccessState) {
              unreadCount = state.notifications
                  .where((n) => n.readStatus == false)
                  .length;
            }

            return Showcase.withWidget(
                      height: 150,
                      width: 280,
              key: TourConfig.doctorHomeNotificationsKey,
              container: CustomTourTooltip(
                title: 'الإشعارات',
                description: 'اضغط لعرض إشعارات الحجوزات الجديدة',
                onNext: () => ShowCaseWidget.of(context)!.next(),
              ),
              child: Badge(
              label: Text(
                unreadCount > 9 ? '9+' : unreadCount.toString(),
                style: const TextStyle(fontSize: 10, color: Colors.white),
              ),
              isLabelVisible: unreadCount > 0,
              backgroundColor: Colors.red,
              largeSize: 18,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              offset: const Offset(-2, 2),
              child: IconButton(
                icon: Icon(Icons.notifications_none, size: 24),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => NotificationsScreen()),
                  ).then((_) {
                    // Re-fetch when coming back to update the count
                    _notificationsCubit.fetchNotifications(showLoading: false);
                  });
                },
              ),
            ),
            );
          },
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
              child: CircularProgressIndicator(strokeWidth: 2))
          : Text(
              _firstName != null
                  ? 'doctor.hello_dr_firstname'.tr(namedArgs: {'_firstName': _firstName!})
                  : 'doctor.hello_doctor'.tr(),
              textAlign: TextAlign.start,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Color(0xFF111827),
              ),
            ),
    );
  }

  // ── Section title ──────────────────────────────────────────────
  Widget _buildSectionTitle(String title, {VoidCallback? onTap}) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 18, 16, 6),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: GestureDetector(
          onTap: onTap,
          child: Text(
            title,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: isDarkMode ? Colors.white : Color(0xFF111827),
            ),
          ),
        ),
      ),
    );
  }

  // ── Appointments list builder ──────────────────────────────────
  Widget _buildAppointmentsList(List<Map<String, dynamic>> appointments, {required bool isPending}) {
    if (_isLoadingAppointments) {
      return Padding(
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
                style: TextStyle(
                    fontFamily: 'Cairo', color: Colors.redAccent)),
            SizedBox(height: 8),
            TextButton.icon(
              onPressed: _fetchAllAppointments,
              icon: Icon(Icons.refresh),
              label: Text('doctor.retry'.tr(),
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
              Transform.translate(
                offset: const Offset(0, -45),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isPending ? Icons.calendar_today_outlined : Icons.check_circle_outline,
                      size: 40,
                      color: isDarkMode ? Colors.white30 : Colors.grey[400],
                    ),
                    SizedBox(height: 12),
                    Text(
                      isPending ? 'doctor.there_are_no_reservations_1'.tr() : 'doctor.there_are_no_confirmed'.tr(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: isDarkMode ? Colors.white : Color(0xFF0C4A6E),
                      ),
                    ),
                  ],
                ),
              ),
              if (isPending) ...[
                SizedBox(height: 12),
                _buildInstructionItem(
                  isDarkMode: isDarkMode,
                  icon: Icons.check_circle_outline,
                  iconColor: Color(0xFF16A34A),
                  text: 'doctor.accept_the_reservation_to'.tr(),
                ),
                SizedBox(height: 6),
                _buildInstructionItem(
                  isDarkMode: isDarkMode,
                  icon: Icons.cancel_outlined,
                  iconColor: Color(0xFFE7000B),
                  text: 'doctor.reject_the_reservation_to'.tr(),
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
      separatorBuilder: (_, __) => SizedBox(height: 12),
      itemBuilder: (_, i) {
        final appointment = appointments[i];

        final String rawDateTime = appointment['appointmentDate'] ?? '';
        String displayDate = appointment['date'] ?? 'doctor.undefined'.tr();
        String displayTime = appointment['time'] ?? 'doctor.undefined'.tr();

        if (rawDateTime.isNotEmpty) {
          try {
            final dt = DateTime.parse(rawDateTime);
            displayDate = DateFormat('dd/MM/yyyy').format(dt);
            displayTime = DateFormat('hh:mm a', context.locale.languageCode)
                .format(dt)
                .replaceAll('AM', 'doctor.am'.tr())
                .replaceAll('PM', 'doctor.evening'.tr());
          } catch (_) {}
        }

        return AppointmentCardWidget(
          context: context,
          patientName: '${appointment['patientFirstName'] ?? 'doctor.patient'.tr()} ${appointment['patientLastName'] ?? ''}'.trim(),
          phone: appointment['patientPhoneNumber'] ?? 'doctor.unavailable'.tr(),
          service: appointment['categoryName'] ?? 'doctor.general_specialty'.tr(),
          date: displayDate,
          time: displayTime,
          statusLabel: isPending ? 'doctor.on_hold'.tr() : 'doctor.confirmed'.tr(),
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
    final phone = appointment['patientPhoneNumber'] ?? 'doctor.unavailable'.tr();
    final service = appointment['categoryName'] ?? 'doctor.general_specialty'.tr();

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
              SizedBox(height: 20),
              Text(
                patientName,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                ),
              ),
              SizedBox(height: 20),
              Divider(color: isDark ? Colors.grey[700] : Color(0xFFE5E7EB)),
              SizedBox(height: 12),
              _buildDetailRow(
                context: context,
                icon: Icons.phone_outlined,
                label: 'doctor.phone_number'.tr(),
                value: phone,
              ),
              SizedBox(height: 14),
              _buildDetailRow(
                context: context,
                icon: Icons.calendar_month_outlined,
                label: 'doctor.the_date'.tr(),
                value: date,
              ),
              SizedBox(height: 14),
              _buildDetailRow(
                context: context,
                icon: Icons.access_time_outlined,
                label: 'doctor.the_time'.tr(),
                value: time,
              ),
              SizedBox(height: 14),
              _buildDetailRow(
                context: context,
                icon: Icons.medical_services_outlined,
                label: 'doctor.specialization'.tr(),
                value: service,
              ),
              SizedBox(height: 24),
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
                  child: Text('doctor.closing'.tr(), style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
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
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 13,
              height: 1.6,
              color: isDarkMode ? Colors.white : Color(0xFF475569),
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
