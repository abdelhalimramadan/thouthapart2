import 'package:thotha_mobile_app/features/appointments/data/appointments_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({Key? key}) : super(key: key);

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  List<Map<String, dynamic>> appointments = [];
  List<Map<String, dynamic>> _allAppointments = [];
  bool _isLoading = true;
  String _selectedFilter = 'الكل';

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
     _loadAppointments();
  }

  Future<void> _loadAppointments() async {
    final savedAppointments = await AppointmentsService().getAppointments();

    final processedAppointments = savedAppointments.map((appt) {
      Color statusColor = Colors.grey;
      if (appt['status'] == 'مؤكد') {
        statusColor = Colors.green;
      } else if (appt['status'] == 'قيد الانتظار') {
        statusColor = Colors.orange;
      }

      return {
        ...appt,
        'statusColor': statusColor,
      };
    }).toList();

    if (mounted) {
      setState(() {
        _allAppointments = processedAppointments;
        _applyFilter();
        _isLoading = false;
      });
    }
  }

  void _applyFilter() {
    if (_selectedFilter == 'الكل') {
      appointments = List.from(_allAppointments);
    } else {
      appointments = _allAppointments
          .where((element) => element['status'] == _selectedFilter)
          .toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final baseFontSize = width * 0.04;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'مواعيدي',
          style: TextStyle(fontFamily: 'Cairo', fontSize: baseFontSize * 1.125, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF0B8FAC),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                   _filterChip('الكل', width, baseFontSize),
                  const SizedBox(width: 8),
                  _filterChip('مؤكد', width, baseFontSize),
                  const SizedBox(width: 8),
                  _filterChip('قيد الانتظار', width, baseFontSize),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (appointments.isEmpty)
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 50),
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 64 * (width / 390),
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'لا توجد مواعيد حالية',
                      style: TextStyle(
                        fontSize: baseFontSize * 1.125, // 18
                        color: Colors.grey[600],
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ],
                ),
              )
            else
              ListView.builder(
                itemCount: appointments.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  final appointment = appointments[index];
                  String dateStr = '';
                  if (appointment['date'] is DateTime) {
                     dateStr = DateFormat('yyyy/MM/dd', 'ar').format(appointment['date']);
                  } else {
                     dateStr = appointment['date'].toString();
                  }

                  return GestureDetector(
                    onTap: () => _showAppointmentDetails(context, appointment, width, baseFontSize),
                    child: Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                appointment['doctorName'] ?? '',
                                style: TextStyle(
                                  fontSize: baseFontSize * 1.125, // 18
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Cairo',
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: (appointment['statusColor'] as Color).withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  appointment['status'] ?? '',
                                  style: TextStyle(
                                    color: appointment['statusColor'],
                                    fontSize: baseFontSize * 0.75, // 12
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Cairo',
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            appointment['specialty'] ?? '',
                            style: TextStyle(
                              fontSize: baseFontSize * 0.875, // 14
                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                              fontFamily: 'Cairo',
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              _buildInfoChip(
                                icon: Icons.calendar_today,
                                text: dateStr,
                                baseFontSize: baseFontSize,
                              ),
                              const SizedBox(width: 12),
                              _buildInfoChip(
                                icon: Icons.access_time,
                                text: appointment['time'] ?? '',
                                baseFontSize: baseFontSize,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  );

                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String label, double width, double baseFontSize) {
    final selected = _selectedFilter == label;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = label;
          _applyFilter();
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF0B8FAC).withValues(alpha: 0.1)
              : (isDark ? Colors.grey[800] : Colors.grey[100]),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? const Color(0xFF0B8FAC)
                : (isDark ? Colors.grey[700]! : Colors.grey[300]!),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.filter_alt_outlined,
                size: 16,
                color: selected ? const Color(0xFF0B8FAC) : Colors.grey[600]),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: baseFontSize * 0.75, // 12
                color: selected ? const Color(0xFF0B8FAC) : (isDark ? Colors.grey[300] : Colors.grey[800]),
                fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip({required IconData icon, required String text, required double baseFontSize}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF0B8FAC)),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: baseFontSize * 0.75, // 12
              color: isDark ? Colors.grey[200] : Colors.grey[800],
              fontFamily: 'Cairo',
            ),
          ),
        ],
      ),
    );
  }

  void _showAppointmentDetails(BuildContext context, Map<String, dynamic> appointment, double width, double baseFontSize) {
       String dateStr = '';
       if (appointment['date'] is DateTime) {
          dateStr = DateFormat('yyyy/MM/dd', 'ar').format(appointment['date']);
       } else {
          dateStr = appointment['date'].toString();
       }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(17),
          topRight: Radius.circular(17),
        ),
      ),
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(17),
                topRight: Radius.circular(17),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                 Center(
                   child: Container(
                     width: 50 * (width / 390),
                     height: 5,
                     decoration: BoxDecoration(
                       color: Colors.grey[300],
                       borderRadius: BorderRadius.circular(10),
                     ),
                   ),
                 ),
                 const SizedBox(height: 20),
                 Text(
                   'تفاصيل الموعد',
                   style: TextStyle(
                     fontFamily: 'Cairo',
                     fontSize: baseFontSize * 1.25, // 20
                     fontWeight: FontWeight.w700,
                     color: isDark ? Colors.white : Colors.black,
                   ),
                 ),
                 const SizedBox(height: 20),
                 _buildDetailRow(Icons.person, 'الطبيب', appointment['doctorName'] ?? '', baseFontSize),
                 const SizedBox(height: 16),
                 _buildDetailRow(Icons.medical_services, 'التخصص', appointment['specialty'] ?? '', baseFontSize),
                 const SizedBox(height: 16),
                 _buildDetailRow(Icons.calendar_today, 'التاريخ', dateStr, baseFontSize),
                 const SizedBox(height: 16),
                 _buildDetailRow(Icons.access_time, 'الوقت', appointment['time'] ?? '', baseFontSize),
                 const SizedBox(height: 16),
                 _buildDetailRow(Icons.info_outline, 'الحالة', appointment['status'] ?? '', baseFontSize, color: appointment['statusColor']),
                 const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0B8FAC),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical:10),
                      ),
                      child: Text(
                        'إغلاق',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: baseFontSize,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 25), // Safe area
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, double baseFontSize, {Color? color}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (color ?? const Color(0xFF0B8FAC)).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color ?? const Color(0xFF0B8FAC), size: 20),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: baseFontSize * 0.75, // 12
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: baseFontSize, // 16
                fontWeight: FontWeight.w600,
                color: color ?? (isDark ? Colors.grey[200] : Colors.black87),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
