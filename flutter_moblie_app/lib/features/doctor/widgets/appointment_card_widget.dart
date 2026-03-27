import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AppointmentCardWidget extends StatelessWidget {
  final BuildContext context;
  final String patientName;
  final String phone;
  final String service;
  final String time;
  final String date;
  final String? statusLabel;
  final Color? statusColor;
  final VoidCallback? onTap;
  final Widget? actionButtons;

  const AppointmentCardWidget({
    super.key,
    required this.context,
    required this.patientName,
    required this.phone,
    required this.service,
    required this.time,
    required this.date,
    this.statusLabel,
    this.statusColor,
    this.onTap,
    this.actionButtons,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(14.r),
        decoration: BoxDecoration(
          color: theme.cardTheme.color ?? colorScheme.surface,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
              color: isDark ? Colors.grey[700]! : const Color(0xFFE5E7EB)),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withAlpha((0.3 * 255).round())
                  : Colors.grey.withAlpha((0.08 * 255).round()),
              blurRadius: 10.r,
              offset: Offset(0, 2.h),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header: Name + Status Badge
            Row(
              textDirection: TextDirection.rtl,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    patientName,
                    textAlign: TextAlign.right,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.w600,
                          fontSize: 16.sp,
                          color: isDark ? Colors.white : Colors.black,
                        ) ??
                        TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.w600,
                          fontSize: 16.sp,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                  ),
                ),
                if (statusLabel != null && statusColor != null) ...[
                  SizedBox(width: 8.w),
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Text(
                      statusLabel!,
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.bold,
                        fontSize: 11.sp,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            SizedBox(height: 12.h),
            // Phone
            Row(
              textDirection: TextDirection.rtl,
              children: [
                Icon(Icons.phone_outlined, size: 14.r, color: Colors.grey[600]),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    phone,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 14.sp,
                      color: isDark ? Colors.white70 : Colors.grey[700],
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 10.h),
            // Date
            Row(
              textDirection: TextDirection.rtl,
              children: [
                Icon(Icons.calendar_today_outlined,
                    size: 14.r, color: Colors.grey[600]),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    date,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 14.sp,
                      color: isDark ? Colors.white70 : Colors.grey[700],
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 10.h),
            // Time
            Row(
              textDirection: TextDirection.rtl,
              children: [
                Icon(Icons.access_time_outlined,
                    size: 14.r, color: Colors.grey[600]),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    time,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 14.sp,
                      color: isDark ? Colors.white70 : Colors.grey[700],
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 10.h),
            // Service
            Row(
              textDirection: TextDirection.rtl,
              children: [
                Icon(Icons.medical_services_outlined,
                    size: 14.r, color: Colors.grey[600]),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    service,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 14.sp,
                      color: isDark ? Colors.white70 : Colors.grey[700],
                    ),
                  ),
                ),
              ],
            ),
            // Action Buttons (Optional)
            if (actionButtons != null) ...[
              SizedBox(height: 12.h),
              actionButtons!,
            ],
          ],
        ),
      ),
    );
  }
}
