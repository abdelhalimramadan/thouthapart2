import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:thoutha_mobile_app/features/booking/ui/booking_confirmation_screen.dart';
import 'package:thoutha_mobile_app/features/doctor/data/models/doctor_model.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final doctor = widget.doctor;

    return Align(
      alignment: Alignment.topCenter,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 16.w),
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          color: theme.cardTheme.color ?? colorScheme.surface,
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: SafeArea(
          top: false,
          child: ListView(
            controller: widget.controller,
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 16.h,
            ),
            children: [
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
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
                          size: 24.r, color: theme.iconTheme.color),
                    ),
                    Text(
                      'تفاصيل الطبيب',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontFamily: 'Cairo',
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16.h),
              Center(
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: theme.cardTheme.color ?? colorScheme.surface,
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(height: 20.h),
                          Text(
                            doctor.fullName,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontFamily: 'Cairo',
                              fontWeight: FontWeight.w700,
                              fontSize: 28.sp,
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 16.h),
                          Text(
                            doctor.categoryName,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontFamily: 'Cairo',
                              fontWeight: FontWeight.w400,
                              fontSize: 18.sp,
                              height: 1.5,
                              color: theme.textTheme.bodyLarge?.color
                                  ?.withValues(alpha: 0.7),
                            ),
                          ),
                          SizedBox(height: 16.h),
                          SizedBox(
                            width: double.infinity,
                            child: Wrap(
                              alignment: WrapAlignment.center,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 24.w,
                              runSpacing: 8.h,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.location_on_outlined,
                                      size: 16.r,
                                      color: const Color(0xFF858585),
                                    ),
                                    SizedBox(width: 4.w),
                                    Text(
                                      doctor.cityName,
                                      style: TextStyle(
                                        fontFamily: 'Cairo',
                                        fontWeight: FontWeight.w400,
                                        fontSize: 16.sp,
                                        height: 1.5,
                                        color: const Color(0xFF858585),
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.star,
                                      color: Colors.amber,
                                      size: 20.r,
                                    ),
                                    SizedBox(width: 4.w),
                                    RichText(
                                      text: TextSpan(
                                        style: TextStyle(
                                          fontFamily: 'Cairo',
                                          fontWeight: FontWeight.w400,
                                          fontSize: 16.sp,
                                          height: 1.5,
                                          color: isDark
                                              ? Colors.white
                                              : Colors.black,
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
                          SizedBox(height: 12.h),
                          if (doctor.price != null)
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 10.w, vertical: 6.h),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F5E9),
                                borderRadius: BorderRadius.circular(20.r),
                              ),
                              child: Text(
                                'سعر الكشف: ${doctor.price} جنيه',
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF2E7D32),
                                ),
                              ),
                            ),
                          SizedBox(height: 16.h),
                          Container(
                            width: double.infinity,
                            margin: EdgeInsets.symmetric(
                                horizontal: 8.w, vertical: 20.h),
                            padding: EdgeInsets.all(12.r),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.grey[800] : Colors.white,
                              borderRadius: BorderRadius.circular(8.r),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 4.r,
                                  offset: Offset(0, 2.h),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'عن الطبيب',
                                  style: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18.sp,
                                    height: 1.5,
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF0A0A0A),
                                  ),
                                  textAlign: TextAlign.right,
                                ),
                                SizedBox(height: 4.h),
                                Text(
                                  doctor.description ??
                                      'طبيب أسنان متخصص ذو خبرة عالية في مجال طب الأسنان.',
                                  style: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontWeight: FontWeight.w400,
                                    fontSize: 16.sp,
                                    height: 1.625,
                                    color: isDark
                                        ? Colors.grey[300]
                                        : const Color(0xFF858585),
                                  ),
                                  textAlign: TextAlign.right,
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(12.r),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                _InfoTile(
                                  icon: Icons.school_outlined,
                                  title: 'الجامعة',
                                  subtitle: doctor.universityName,
                                ),
                                SizedBox(height: 10.h),
                                _InfoTile(
                                  icon: Icons.location_on_outlined,
                                  title: 'العنوان',
                                  subtitle: doctor.cityName,
                                ),
                                SizedBox(height: 10.h),
                                if (doctor.email != null)
                                  _InfoTile(
                                    icon: Icons.mail_outline,
                                    title: 'البريد الإلكتروني',
                                    subtitle: doctor.email!,
                                  ),
                              ],
                            ),
                          ),
                          SizedBox(height: 16.h),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                'احجز موعدك',
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16.sp,
                                  color: isDark ? Colors.white : Colors.black,
                                ),
                              ),
                              SizedBox(width: 8.w),
                              Icon(Icons.calendar_today_outlined,
                                  size: 18.r, color: const Color(0xFF0B8FAC)),
                              SizedBox(width: 6.w),
                            ],
                          ),
                          SizedBox(height: 12.h),
                          SizedBox(
                            height: 44.h,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              reverse: true,
                              itemCount: 4,
                              padding: EdgeInsets.symmetric(horizontal: 8.w),
                              separatorBuilder: (_, __) => SizedBox(width: 8.w),
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
                                  onTap: () =>
                                      setState(() => _selectedDay = label),
                                );
                              },
                            ),
                          ),
                          SizedBox(height: 15.h),
                          Column(
                            children: [
                              _TimeListTile(
                                label: '9:00 صباحاً',
                                selected: _selectedTime?.hour == 9 &&
                                    _selectedTime?.minute == 0,
                                onTap: () => setState(() => _selectedTime =
                                    const TimeOfDay(hour: 9, minute: 0)),
                              ),
                              SizedBox(height: 8.h),
                              _TimeListTile(
                                label: '10:00 صباحاً',
                                selected: _selectedTime?.hour == 10 &&
                                    _selectedTime?.minute == 0,
                                onTap: () => setState(() => _selectedTime =
                                    const TimeOfDay(hour: 10, minute: 0)),
                              ),
                              SizedBox(height: 8.h),
                              _TimeListTile(
                                label: '12:00 ظهراً',
                                selected: _selectedTime?.hour == 12 &&
                                    _selectedTime?.minute == 0,
                                onTap: () => setState(() => _selectedTime =
                                    const TimeOfDay(hour: 12, minute: 0)),
                              ),
                              SizedBox(height: 8.h),
                              _TimeListTile(
                                label: '02:00 مساءً',
                                selected: _selectedTime?.hour == 14 &&
                                    _selectedTime?.minute == 0,
                                onTap: () => setState(() => _selectedTime =
                                    const TimeOfDay(hour: 14, minute: 0)),
                              ),
                              SizedBox(height: 8.h),
                              _TimeListTile(
                                label: '04:00 مساءً',
                                selected: _selectedTime?.hour == 16 &&
                                    _selectedTime?.minute == 0,
                                onTap: () => setState(() => _selectedTime =
                                    const TimeOfDay(hour: 16, minute: 0)),
                              ),
                              SizedBox(height: 8.h),
                              _TimeListTile(
                                label: '06:00 مساءً',
                                selected: _selectedTime?.hour == 18 &&
                                    _selectedTime?.minute == 0,
                                onTap: () => setState(() => _selectedTime =
                                    const TimeOfDay(hour: 18, minute: 0)),
                              ),
                            ],
                          ),
                          SizedBox(height: 16.h),
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(12.r),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.blueGrey[900]
                                  : const Color(0xFFEFF7FF),
                              borderRadius: BorderRadius.circular(8.r),
                              border:
                                  Border.all(color: const Color(0xFFB3DAFF)),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    'جميع الخدمات تتم تحت إشراف مباشر من أعضاء هيئة التدريس بالكلية',
                                    style: TextStyle(
                                      fontFamily: 'Cairo',
                                      fontSize: 12.sp,
                                      color: isDark
                                          ? Colors.grey[200]
                                          : const Color(0xFF1F2937),
                                      height: 1.6,
                                    ),
                                  ),
                                ),
                                Icon(Icons.sticky_note_2_outlined,
                                    color: const Color(0xFF3B82F6), size: 20.r),
                              ],
                            ),
                          ),
                          SizedBox(height: 16.h),
                          Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(8.r),
                                  onTap: () => Navigator.pop(context),
                                  child: Container(
                                    height: 44.h,
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? Colors.grey[800]
                                          : const Color(0xFFF3F4F6),
                                      borderRadius: BorderRadius.circular(8.r),
                                    ),
                                    child: Center(
                                      child: Text(
                                        'إلغاء',
                                        style: TextStyle(
                                          fontFamily: 'Cairo',
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14.sp,
                                          color: isDark
                                              ? Colors.white
                                              : const Color(0xFF111827),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: GestureDetector(
                                  onTap: _isBookingEnabled
                                      ? () {
                                          final String doctorName =
                                              '${widget.doctor.firstName} ${widget.doctor.lastName}';
                                          final String date =
                                              _selectedDay ?? '';
                                          final String time =
                                              _selectedTime?.format(context) ??
                                                  '';
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  BookingConfirmationScreen(
                                                doctorName: doctorName,
                                                specialty:
                                                    widget.doctor.categoryName,
                                                date: date,
                                                time: time,
                                                requestId: null,
                                              ),
                                            ),
                                          );
                                        }
                                      : null,
                                  child: Container(
                                    height: 44.h,
                                    decoration: BoxDecoration(
                                      color: _isBookingEnabled
                                          ? const Color(0xFF10B981)
                                          : const Color(0xFF9CA3AF),
                                      borderRadius: BorderRadius.circular(8.r),
                                    ),
                                    child: Center(
                                      child: Text(
                                        'تأكيد الحجز',
                                        style: TextStyle(
                                          fontFamily: 'Cairo',
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14.sp,
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
                          SizedBox(height: 16.h),
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

  const _InfoTile(
      {required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(8.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6.r,
            offset: Offset(0, 2.h),
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
                    fontSize: 15.sp,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF111827),
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  subtitle,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w400,
                    color: isDark ? Colors.grey[300] : const Color(0xFF111827),
                  ),
                ),
              ],
            ),
          ),
          Icon(icon, color: const Color(0xFF0B8FAC), size: 24.r),
        ],
      ),
    );
  }
}

class _DayChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  const _DayChip({required this.label, this.selected = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final BorderRadius radius = BorderRadius.circular(8.r);
    final Widget child = Text(
      label,
      style: TextStyle(
        fontFamily: 'Cairo',
        fontWeight: FontWeight.w700,
        fontSize: 14.sp,
        color: selected
            ? Colors.white
            : (isDark ? Colors.grey[200] : const Color(0xFF111827)),
      ),
    );

    if (selected) {
      return InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
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
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
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

  const _TimeListTile({required this.label, this.selected = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final BorderRadius radius = BorderRadius.circular(10.r);
    final Color borderColor = selected
        ? const Color(0xFF8DECB4)
        : (isDark ? Colors.grey[700]! : const Color(0xFFE5E7EB));
    final Widget text = Text(
      label,
      style: TextStyle(
        fontFamily: 'Cairo',
        fontWeight: FontWeight.w700,
        fontSize: 14.sp,
        color: selected
            ? Colors.white
            : (isDark ? Colors.grey[200] : const Color(0xFF111827)),
      ),
    );

    return InkWell(
      borderRadius: radius,
      onTap: onTap,
      child: Container(
        height: 48.h,
        padding: EdgeInsets.symmetric(horizontal: 14.w),
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
              blurRadius: 4.r,
              offset: Offset(0, 2.h),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(Icons.access_time,
                size: 18.r,
                color: selected
                    ? Colors.white
                    : (isDark ? Colors.grey[200] : const Color(0xFF111827))),
            text,
          ],
        ),
      ),
    );
  }
}
