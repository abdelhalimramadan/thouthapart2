import 'package:flutter/material.dart';
import 'package:thotha_mobile_app/features/booking/ui/booking_confirmation_screen.dart';
import 'package:thotha_mobile_app/features/home_screen/data/models/doctor_model.dart';
import 'dart:ui';

class DoctorInfoContent extends StatefulWidget {
  final ScrollController controller;
  final DoctorModel doctor;

  const DoctorInfoContent({
    super.key,
    required this.controller,
    required this.doctor,
  });

  @override
  State<DoctorInfoContent> createState() => _DoctorInfoContentState();
}

class _DoctorInfoContentState extends State<DoctorInfoContent> {
  String? _selectedDay;
  TimeOfDay? _selectedTime;

  bool get _isBookingEnabled => _selectedDay != null && _selectedTime != null;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final baseFontSize = width * 0.04;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final doctor = widget.doctor;

    return Align(
      alignment: Alignment.topCenter,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardTheme.color ?? colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: SafeArea(
          top: false,
          child: ListView(
            controller: widget.controller,
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            ),
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                        color: isDark
                            ? Colors.grey[700]!
                            : const Color(0xFFE5E7EB),
                        width: 1.1),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Icon(Icons.close,
                          size: 24, color: theme.iconTheme.color),
                    ),
                    Text(
                      'تفاصيل الطبيب',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontFamily: 'Cairo',
                        fontSize: baseFontSize * 1.125, // 18
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 150 * (width / 390),
                      height: 150 * (width / 390),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: theme.colorScheme.surfaceContainerHighest,
                      ),
                      child: doctor.photo != null &&
                              doctor.photo!.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                doctor.photo!,
                                fit: BoxFit.cover,
                                errorBuilder:
                                    (context, error, stackTrace) {
                                  return Icon(Icons.person,
                                      size: 64 * (width / 390),
                                      color: theme
                                          .colorScheme.onSurfaceVariant);
                                },
                              ),
                            )
                          : Icon(Icons.person,
                              size: 64 * (width / 390),
                              color: theme.colorScheme.onSurfaceVariant),
                    ),
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(top: 8),
                      decoration: BoxDecoration(
                        color:
                            theme.cardTheme.color ?? colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(height: 20),
                          Text(
                            doctor.fullName,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontFamily: 'Cairo',
                              fontWeight: FontWeight.w700,
                              fontSize: baseFontSize * 1.75, // 28
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            doctor.categoryName,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontFamily: 'Cairo',
                              fontWeight: FontWeight.w400,
                              fontSize: baseFontSize * 1.125, // 18
                              height: 1.5,
                              color: theme.textTheme.bodyLarge?.color
                                  ?.withValues(alpha: 0.7),
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: Wrap(
                              alignment: WrapAlignment.center,
                              crossAxisAlignment:
                                  WrapCrossAlignment.center,
                              spacing: 24,
                              runSpacing: 8,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.location_on_outlined,
                                      size: 16,
                                      color: Color(0xFF858585),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      doctor.cityName,
                                      style: TextStyle(
                                        fontFamily: 'Cairo',
                                        fontWeight: FontWeight.w400,
                                        fontSize: baseFontSize, // 16
                                        height: 1.5,
                                        color: const Color(0xFF858585),
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.star,
                                      color: Colors.amber,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 4),
                                    RichText(
                                      text: TextSpan(
                                        style: TextStyle(
                                          fontFamily: 'Cairo',
                                          fontWeight: FontWeight.w400,
                                          fontSize: baseFontSize, // 16
                                          height: 1.5,
                                          color: isDark ? Colors.white : Colors.black,
                                        ),
                                        children: const [
                                          TextSpan(text: '4.8 '),
                                          TextSpan(
                                            text: '(124 تقييم)',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (doctor.price != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F5E9),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'سعر الكشف: ${doctor.price} جنيه',
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: baseFontSize * 0.875, // 14
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF2E7D32),
                                ),
                              ),
                            ),
                          const SizedBox(height: 16),
                          Container(
                            width: double.infinity,
                            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 20),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.grey[800] : Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'عن الطبيب',
                                  style: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontWeight: FontWeight.bold,
                                    fontSize: baseFontSize * 1.125, // 18
                                    height: 1.5,
                                    color: isDark ? Colors.white : const Color(0xFF0A0A0A),
                                  ),
                                  textAlign: TextAlign.right,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  doctor.description ??
                                      'طبيب أسنان متخصص ذو خبرة عالية في مجال طب الأسنان.',
                                  style: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontWeight: FontWeight.w400,
                                    fontSize: baseFontSize, // 16
                                    height: 1.625,
                                    color: isDark ? Colors.grey[300] : const Color(0xFF858585),
                                  ),
                                  textAlign: TextAlign.right,
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.end,
                              children: [
                                _InfoTile(
                                  icon: Icons.school_outlined,
                                  title: 'الجامعة',
                                  subtitle: doctor.universityName,
                                  baseFontSize: baseFontSize,
                                ),
                                const SizedBox(height: 10),
                                _InfoTile(
                                  icon: Icons.location_on_outlined,
                                  title: 'العنوان',
                                  subtitle: doctor.cityName,
                                  baseFontSize: baseFontSize,
                                ),
                                const SizedBox(height: 10),
                                _InfoTile(
                                  icon: Icons.phone_outlined,
                                  title: 'رقم الهاتف',
                                  subtitle: doctor.phoneNumber,
                                  baseFontSize: baseFontSize,
                                ),
                                const SizedBox(height: 10),
                                if (doctor.email != null)
                                  _InfoTile(
                                    icon: Icons.mail_outline,
                                    title: 'البريد الإلكتروني',
                                    subtitle: doctor.email!,
                                    baseFontSize: baseFontSize,
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                'احجز موعدك',
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontWeight: FontWeight.w700,
                                  fontSize: baseFontSize,
                                  color: isDark ? Colors.white : Colors.black,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.calendar_today_outlined,
                                  size: 18, color: Color(0xFF0B8FAC)),
                              const SizedBox(width: 6),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 44,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              reverse: true,
                              itemCount: 4,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8),
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: 8),
                              itemBuilder: (context, index) {
                                final days = [
                                  'الأحد',
                                  'الإثنين',
                                  'الثلاثاء',
                                  'الأربعاء'
                                ];
                                final label = days[index];
                                return _DayChip(
                                  label: label,
                                  selected: _selectedDay == label,
                                  baseFontSize: baseFontSize,
                                  onTap: () => setState(
                                      () => _selectedDay = label),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 15),
                          Column(
                            children: [
                              _TimeListTile(
                                label: '9:00 صباحاً',
                                baseFontSize: baseFontSize,
                                selected: _selectedTime?.hour == 9 &&
                                    _selectedTime?.minute == 0,
                                onTap: () => setState(() =>
                                    _selectedTime = const TimeOfDay(
                                        hour: 9, minute: 0)),
                              ),
                              const SizedBox(height: 8),
                              _TimeListTile(
                                label: '10:00 صباحاً',
                                baseFontSize: baseFontSize,
                                selected: _selectedTime?.hour == 10 &&
                                    _selectedTime?.minute == 0,
                                onTap: () => setState(() =>
                                    _selectedTime = const TimeOfDay(
                                        hour: 10, minute: 0)),
                              ),
                              const SizedBox(height: 8),
                              _TimeListTile(
                                label: '12:00 ظهراً',
                                baseFontSize: baseFontSize,
                                selected: _selectedTime?.hour == 12 &&
                                    _selectedTime?.minute == 0,
                                onTap: () => setState(() =>
                                    _selectedTime = const TimeOfDay(
                                        hour: 12, minute: 0)),
                              ),
                              const SizedBox(height: 8),
                              _TimeListTile(
                                label: '02:00 مساءً',
                                baseFontSize: baseFontSize,
                                selected: _selectedTime?.hour == 14 &&
                                    _selectedTime?.minute == 0,
                                onTap: () => setState(() =>
                                    _selectedTime = const TimeOfDay(
                                        hour: 14, minute: 0)),
                              ),
                              const SizedBox(height: 8),
                              _TimeListTile(
                                label: '04:00 مساءً',
                                baseFontSize: baseFontSize,
                                selected: _selectedTime?.hour == 16 &&
                                    _selectedTime?.minute == 0,
                                onTap: () => setState(() =>
                                    _selectedTime = const TimeOfDay(
                                        hour: 16, minute: 0)),
                              ),
                              const SizedBox(height: 8),
                              _TimeListTile(
                                label: '06:00 مساءً',
                                baseFontSize: baseFontSize,
                                selected: _selectedTime?.hour == 18 &&
                                    _selectedTime?.minute == 0,
                                onTap: () => setState(() =>
                                    _selectedTime = const TimeOfDay(
                                        hour: 18, minute: 0)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.blueGrey[900] : const Color(0xFFEFF7FF),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: const Color(0xFFB3DAFF)),
                            ),
                            child: Row(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    'جميع الخدمات تتم تحت إشراف مباشر من أعضاء هيئة التدريس بالكلية',
                                    style: TextStyle(
                                      fontFamily: 'Cairo',
                                      fontSize: baseFontSize * 0.75, // 12
                                      color: isDark ? Colors.grey[200] : const Color(0xFF1F2937),
                                      height: 1.6,
                                    ),
                                  ),
                                ),
                                const Icon(Icons.sticky_note_2_outlined,
                                    color: Color(0xFF3B82F6), size: 20),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  borderRadius:
                                      BorderRadius.circular(8),
                                  onTap: () => Navigator.pop(context),
                                  child: Container(
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: isDark ? Colors.grey[800] : const Color(0xFFF3F4F6),
                                      borderRadius:
                                          BorderRadius.circular(8),
                                    ),
                                    child: Center(
                                      child: Text(
                                        'إلغاء',
                                        style: TextStyle(
                                          fontFamily: 'Cairo',
                                          fontWeight: FontWeight.w700,
                                          fontSize: baseFontSize * 0.875, // 14
                                          color: isDark ? Colors.white : const Color(0xFF111827),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: GestureDetector(
                                  onTap: _isBookingEnabled
                                      ? () {
                                          final String doctorName =
                                              '${widget.doctor.firstName} ${widget.doctor.lastName}';
                                          final String date =
                                              _selectedDay ?? '';
                                          final String time =
                                              _selectedTime?.format(
                                                      context) ??
                                                  '';
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  BookingConfirmationScreen(
                                                doctorName: doctorName,
                                                specialty: widget.doctor.categoryName,
                                                date: date,
                                                time: time,
                                              ),
                                            ),
                                          );
                                        }
                                      : null,
                                  child: Container(
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: _isBookingEnabled
                                          ? const Color(0xFF10B981)
                                          : const Color(0xFF9CA3AF),
                                      borderRadius:
                                          BorderRadius.circular(8),
                                    ),
                                    child: Center(
                                      child: Text(
                                        'تأكيد الحجز',
                                        style: TextStyle(
                                          fontFamily: 'Cairo',
                                          fontWeight: FontWeight.w700,
                                          fontSize: baseFontSize * 0.875, // 14
                                          color: _isBookingEnabled
                                              ? Colors.white
                                              : Colors.white
                                                  .withValues(alpha: 0.7),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final double baseFontSize;

  const _InfoTile(
      {required this.icon, required this.title, required this.subtitle, required this.baseFontSize});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  title,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: baseFontSize * 0.9375, // 15
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: baseFontSize * 0.875, // 14
                    fontWeight: FontWeight.w400,
                    color: isDark ? Colors.grey[300] : const Color(0xFF111827),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          const Icon(icon, color: Color(0xFF0B8FAC)),
        ],
      ),
    );
  }
}

class _DayChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final double baseFontSize;

  const _DayChip({required this.label, this.selected = false, this.onTap, required this.baseFontSize});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final BorderRadius radius = BorderRadius.circular(8);
    final Widget child = Text(
      label,
      style: TextStyle(
        fontFamily: 'Cairo',
        fontWeight: FontWeight.w700,
        fontSize: baseFontSize * 0.875, // 14
        color: selected ? Colors.white : (isDark ? Colors.grey[200] : const Color(0xFF111827)),
      ),
    );

    if (selected) {
      return InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [Color(0xFF84E5F3), Color(0xFF8DECB4)],
            ),
            borderRadius: radius,
          ),
          child: child,
        ),
      );
    }
    return InkWell(
      borderRadius: radius,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[800] : const Color(0xFFF3F4F6),
          borderRadius: radius,
        ),
        child: child,
      ),
    );
  }
}

class _TimeListTile extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final double baseFontSize;

  const _TimeListTile({required this.label, this.selected = false, this.onTap, required this.baseFontSize});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final BorderRadius radius = BorderRadius.circular(10);
    final Color borderColor =
        selected ? const Color(0xFF8DECB4) : (isDark ? Colors.grey[700]! : const Color(0xFFE5E7EB));
    final Widget text = Text(
      label,
      style: TextStyle(
        fontFamily: 'Cairo',
        fontWeight: FontWeight.w700,
        fontSize: baseFontSize * 0.875, // 14
        color: selected ? Colors.white : (isDark ? Colors.grey[200] : const Color(0xFF111827)),
      ),
    );

    return InkWell(
      borderRadius: radius,
      onTap: onTap,
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          gradient: selected
              ? const LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [Color(0xFF84E5F3), Color(0xFF8DECB4)],
                )
              : null,
          color: selected ? null : (isDark ? Colors.grey[800] : Colors.white),
          borderRadius: radius,
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(Icons.access_time,
                size: 18,
                color: selected ? Colors.white : (isDark ? Colors.grey[200] : const Color(0xFF111827))),
            text,
          ],
        ),
      ),
    );
  }
}
