import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/utils/notification_helper.dart';
import '../drawer/doctor_drawer_screen.dart';
import '../../../notifications/ui/notifications_screen.dart';

class DoctorBookingRecordsScreen extends StatefulWidget {
  const DoctorBookingRecordsScreen({super.key});

  @override
  State<DoctorBookingRecordsScreen> createState() =>
      _DoctorBookingRecordsScreenState();
}

class _DoctorBookingRecordsScreenState
    extends State<DoctorBookingRecordsScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: theme.scaffoldBackgroundColor,
      drawer: const DoctorDrawer(),
      appBar: AppBar(
        toolbarHeight: 70.h,
        elevation: 0,
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
        automaticallyImplyLeading: false,
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu, size: 24.r),
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          ),
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
              style: textTheme.titleLarge?.copyWith(
                fontFamily: 'Cairo',
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: Icon(Icons.notifications_none, size: 24.r),
                onPressed: () {
                  NotificationHelper.hasUnreadNotifications = false;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const NotificationsScreen()),
                  ).then((_) {
                    if (mounted) setState(() {});
                  });
                },
              ),
              if (NotificationHelper.getUnreadCount() > 0)
                Positioned(
                  right: 8.w,
                  top: 10.h,
                  child: Container(
                    width: 16.w,
                    height: 16.w,
                    decoration: BoxDecoration(
                      color: colorScheme.error,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        NotificationHelper.getUnreadCount() > 9
                            ? '9+'
                            : '${NotificationHelper.getUnreadCount()}',
                        style: textTheme.labelSmall?.copyWith(
                          color: colorScheme.onError,
                          fontSize: 10.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(width: 8.w),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1.h),
          child: Container(
            height: 1.h,
            color: isDark ? Colors.grey[700]! : const Color(0xFFE5E7EB),
          ),
        ),
      ),
      body: _buildMainContent(context),
    );
  }

  void _showBookingDetails({
    required BuildContext context,
    required String patientName,
    required String phone,
    required String date,
    required String time,
    required String service,
    required String profileImage,
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
              Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[600] : Colors.grey[300],
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              SizedBox(height: 20.h),
              Row(
                textDirection: TextDirection.rtl,
                children: [
                  Container(
                    width: 64.w,
                    height: 64.w,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12.r),
                      image: DecorationImage(
                        image: AssetImage(profileImage),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Text(
                    patientName,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.w700,
                      fontSize: 20.sp,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20.h),
              Divider(
                  color: isDark ? Colors.grey[700] : const Color(0xFFE5E7EB)),
              SizedBox(height: 12.h),
              _buildDetailRow(
                context: context,
                icon: Icons.phone_outlined,
                label: 'رقم الهاتف',
                value: phone,
              ),
              SizedBox(height: 14.h),
              _buildDetailRow(
                context: context,
                icon: Icons.calendar_month_outlined,
                label: 'التاريخ',
                value: date,
              ),
              SizedBox(height: 14.h),
              _buildDetailRow(
                context: context,
                icon: Icons.access_time_outlined,
                label: 'الوقت',
                value: time,
              ),
              SizedBox(height: 14.h),
              _buildDetailRow(
                context: context,
                icon: Icons.medical_services_outlined,
                label: 'التخصص',
                value: service,
              ),
              SizedBox(height: 24.h),
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
      textDirection: TextDirection.rtl,
      children: [
        Container(
          width: 38.w,
          height: 38.w,
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[800] : const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Icon(icon, size: 18.r, color: isDark ? Colors.white : const Color(0xFF021433)),
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

  Widget _buildBookingCard({
    required BuildContext context,
    required String patientName,
    required String phone,
    required String service,
    required String time,
    required String date,
    required String status,
    required Color statusColor,
    required String profileImage,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => _showBookingDetails(
        context: context,
        patientName: patientName,
        phone: phone,
        date: date,
        time: time,
        service: service,
        profileImage: profileImage,
      ),
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
        child: Row(
          textDirection: TextDirection.rtl,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Patient Image
            Container(
              width: 52.w,
              height: 52.w,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8.r),
                image: DecorationImage(
                  image: AssetImage(profileImage),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            SizedBox(width: 10.w),
            // Name
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
                ),
              ),
            ),
            SizedBox(width: 8.w),
            // Status badge
            Container(
              padding: EdgeInsets.symmetric(
                  horizontal: 10.w, vertical: 4.h),
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
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 15.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 10.h),
            child: Text(
              'سجل الحجوزات',
              textAlign: TextAlign.right,
              style: theme.textTheme.titleLarge?.copyWith(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.w700,
                fontSize: 24.sp,
                height: 1.5,
              ),
            ),
          ),
          SizedBox(height: 12.h),
          _buildBookingCard(
            context: context,
            patientName: 'زياد جمال',
            phone: '01012345678',
            service: 'تقويم اسنان',
            time: '11:30 صباحا',
            date: '2025-11-29',
            status: 'مكتمل',
            statusColor: Colors.greenAccent,
            profileImage: 'assets/images/zozjpg.jpg',
          ),
          SizedBox(height: 12.h),
          _buildBookingCard(
            context: context,
            patientName: 'عبدالحليم رمضان',
            phone: '01098765432',
            service: 'حشو عصب',
            time: '02:45 مساءً',
            date: '2025-11-30',
            status: 'انتظار',
            statusColor: Colors.orangeAccent,
            profileImage: 'assets/images/halim.jpg',
          ),
          SizedBox(height: 12.h),
          _buildBookingCard(
            context: context,
            patientName: 'محمد اشرف',
            phone: '01156781234',
            service: 'تنظيف أسنان',
            time: '10:15 صباحا',
            date: '2025-12-01',
            status: 'ملغي',
            statusColor: Colors.redAccent,
            profileImage: 'assets/images/kateb.jpg',
          ),
          SizedBox(height: 12.h),
          _buildBookingCard(
            context: context,
            patientName: 'جوزيف جورح',
            phone: '01234567890',
            service: 'تركيب كوبري',
            time: '04:30 مساءً',
            date: '2025-12-02',
            status: 'مكتمل',
            statusColor: Colors.greenAccent,
            profileImage: 'assets/images/joseoh.jpeg',
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 16.h),
        ],
      ),
    );
  }
}
