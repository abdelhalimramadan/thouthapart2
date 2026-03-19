import 'dart:ui' as ui show TextDirection;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:thotha_mobile_app/core/di/dependency_injection.dart';
import 'package:thotha_mobile_app/core/networking/api_service.dart';
import 'package:thotha_mobile_app/features/home_screen/doctor_home/ui/doctor_home_screen.dart';

class AppointmentHistoryScreen extends StatefulWidget {
  const AppointmentHistoryScreen({
    super.key,
  });

  @override
  State<AppointmentHistoryScreen> createState() =>
      _AppointmentHistoryScreenState();
}

class _AppointmentHistoryScreenState extends State<AppointmentHistoryScreen> {
  late ApiService _apiService;
  List<Map<String, dynamic>> _history = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _apiService = getIt<ApiService>();
    _fetchAppointmentHistory();
  }

  Future<void> _fetchAppointmentHistory() async {
    try {
      print('=== DEBUG: Fetching appointment history ===');
      final result = await _apiService.getAppointmentHistory();

      print('=== DEBUG: Result: $result ===');

      if (mounted) {
        if (result['success'] == true && result['data'] != null) {
          setState(() {
            _history = List<Map<String, dynamic>>.from(result['data'] as List);
            _isLoading = false;
            _errorMessage = null;
          });
          print('=== DEBUG: Loaded ${_history.length} appointments ===');
        } else {
          final errorMsg = result['error'] ?? 'فشل في تحميل السجل';
          print('=== DEBUG: Error - $errorMsg ===');
          setState(() {
            _isLoading = false;
            _errorMessage = errorMsg;
            _history = [];
          });
        }
      }
    } catch (e, stack) {
      print('=== DEBUG: Exception: $e ===');
      print('=== DEBUG: Stack: $stack ===');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'حدث خطأ: ${e.toString()}';
          _history = [];
        });
      }
    }
  }

  Future<void> _deleteAppointment(int appointmentId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'تأكيد الحذف',
          style: TextStyle(fontFamily: 'Cairo'),
        ),
        content: const Text(
          'هل تريد حذف هذا السجل؟',
          style: TextStyle(fontFamily: 'Cairo'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'إلغاء',
              style: TextStyle(fontFamily: 'Cairo'),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'حذف',
              style: TextStyle(fontFamily: 'Cairo', color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final result = await _apiService.deleteAppointment(appointmentId);

      if (!mounted) return;

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'تم حذف السجل بنجاح',
              style: TextStyle(fontFamily: 'Cairo'),
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        await _fetchAppointmentHistory();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result['error'] ?? 'فشل في حذف السجل',
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

  Future<void> _updateAppointmentStatus(int appointmentId, String status) async {
    try {
      final result =
          await _apiService.updateAppointmentStatus(appointmentId, status);

      if (!mounted) return;

      if (result['success'] == true) {
        final statusAr = _statusToArabic(status);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تم تحديث حالة الحجز إلى $statusAr بنجاح',
              style: const TextStyle(fontFamily: 'Cairo'),
            ),
            backgroundColor:
                status.toUpperCase() == 'CANCELLED' ? Colors.orange : Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
        await _fetchAppointmentHistory();
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

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final baseFontSize = width * 0.04;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const DoctorHomeScreen(),
              ),
            );
          },
        ),
        title: Text(
          'سجل الحجوزات',
          style: theme.textTheme.titleLarge?.copyWith(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        elevation: 0,
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
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          children: [
                            Text(
                              _errorMessage!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontFamily: 'Cairo',
                                color: Colors.red,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (_errorMessage!.contains('404') ||
                                _errorMessage!.contains('لم يتم العثور'))
                              Column(
                                children: [
                                  const SizedBox(height: 12),
                                  Text(
                                    'تأكد من أن لديك حجوزات سابقة أو حاول إعادة المحاولة',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontFamily: 'Cairo',
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _fetchAppointmentHistory,
                        icon: const Icon(Icons.refresh),
                        label: const Text(
                          'إعادة محاولة',
                          style: TextStyle(fontFamily: 'Cairo'),
                        ),
                      ),
                    ],
                  ),
                )
              : _history.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.history,
                            size: 64,
                            color: Colors.grey[300],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'لا توجد حجوزات سابقة',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: baseFontSize * 1.125,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _fetchAppointmentHistory,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 15,
                        ),
                        itemCount: _history.length,
                        itemBuilder: (context, index) {
                          final appointment = _history[index];

                          // Parsing Date and Time securely
                          String displayDate = 'غير محدد';
                          String displayTime = 'غير محدد';
                          final String rawDateTime =
                              appointment['appointmentDate'] ?? '';

                          if (rawDateTime.isNotEmpty) {
                            try {
                              final dt = DateTime.parse(rawDateTime);
                              displayDate = DateFormat('dd/MM/yyyy').format(dt);
                              displayTime = DateFormat('hh:mm a', 'ar')
                                  .format(dt)
                                  .replaceAll('AM', 'صباحاً')
                                  .replaceAll('PM', 'مساءً');
                            } catch (e) {
                              if (rawDateTime.contains('T')) {
                                final parts = rawDateTime.split('T');
                                displayDate = parts[0];
                                displayTime = parts[1].substring(0, 5);
                              }
                            }
                          }

                          return _buildHistoryCard(
                            context: context,
                            appointment: appointment,
                            displayDate: displayDate,
                            displayTime: displayTime,
                            baseFontSize: baseFontSize,
                            isDark: isDark,
                            theme: theme,
                            onDelete: () =>
                                _deleteAppointment(appointment['id'] ?? 0),
                          );
                        },
                      ),
                    ),
    );
  }

  Widget _buildHistoryCard({
    required BuildContext context,
    required Map<String, dynamic> appointment,
    required String displayDate,
    required String displayTime,
    required double baseFontSize,
    required bool isDark,
    required ThemeData theme,
    required VoidCallback onDelete,
  }) {
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey[700]! : const Color(0xFFE5E7EB),
        ),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Patient name + Status
          Row(
            textDirection: ui.TextDirection.rtl,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '${appointment['patientFirstName'] ?? 'مريض'} ${appointment['patientLastName'] ?? ''}'
                      .trim(),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w600,
                    fontSize: baseFontSize * 1.0,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _getStatusColor(appointment['status']),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _statusToArabic(appointment['status'] ?? 'PENDING'),
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
          const Divider(height: 20),
          // Details
          _buildDetailItem(
            icon: Icons.phone_outlined,
            label: 'رقم الهاتف',
            value: appointment['patientPhoneNumber'] ?? 'غير محدد',
            baseFontSize: baseFontSize,
          ),
          const SizedBox(height: 10),
          _buildDetailItem(
            icon: Icons.medical_services_outlined,
            label: 'التخصص',
            value: appointment['categoryName'] ?? 'غير محدد',
            baseFontSize: baseFontSize,
          ),
          const SizedBox(height: 10),
          _buildDetailItem(
            icon: Icons.calendar_month_outlined,
            label: 'التاريخ',
            value: displayDate,
            baseFontSize: baseFontSize,
          ),
          const SizedBox(height: 10),
          _buildDetailItem(
            icon: Icons.access_time_outlined,
            label: 'الوقت',
            value: displayTime,
            baseFontSize: baseFontSize,
          ),
          const SizedBox(height: 14),
          // Actions: if still PENDING → show تأكيد / إلغاء, otherwise delete only
          Builder(builder: (context) {
            final status = (appointment['status'] ?? 'PENDING').toString();
            final isPending = status.toUpperCase() == 'PENDING';
            if (isPending) {
              return Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () =>
                          _updateAppointmentStatus(appointment['id'] ?? 0, 'DONE'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF0FDF4),
                        foregroundColor: const Color(0xFF16A34A),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                          side: const BorderSide(color: Color(0xFF16A34A)),
                        ),
                      ),
                      child: Text(
                        'تأكيد الحالة',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: baseFontSize * 0.85,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _updateAppointmentStatus(
                          appointment['id'] ?? 0, 'CANCELLED'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFEF2F2),
                        foregroundColor: const Color(0xFFE7000B),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                          side: const BorderSide(color: Color(0xFFE7000B)),
                        ),
                      ),
                      child: Text(
                        'إلغاء الحالة',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: baseFontSize * 0.85,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }

            return SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline),
                label: const Text(
                  'حذف السجل',
                  style: TextStyle(fontFamily: 'Cairo'),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFEF2F2),
                  foregroundColor: const Color(0xFFE7000B),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                    side: const BorderSide(color: Color(0xFFE7000B)),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildDetailItem({
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
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[800] : const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            icon,
            size: 14,
            color: const Color(0xFF021433),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: baseFontSize * 0.7,
                  color: Colors.grey,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.w600,
                  fontSize: baseFontSize * 0.85,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String? status) {
    switch (status?.toUpperCase()) {
      case 'APPROVED':
        return const Color(0xFF84E5F3);
      case 'DONE':
        return const Color(0xFF16A34A);
      case 'CANCELLED':
        return const Color(0xFFE7000B);
      default:
        return Colors.grey;
    }
  }

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
