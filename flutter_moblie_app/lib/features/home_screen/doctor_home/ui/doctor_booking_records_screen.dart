import 'package:flutter/material.dart';
import 'package:thotha_mobile_app/core/utils/notification_helper.dart';
import 'package:thotha_mobile_app/features/home_screen/doctor_home/drawer/doctor_drawer_screen.dart';
import 'package:thotha_mobile_app/features/notifications/ui/notifications_screen.dart';

class DoctorBookingRecordsScreen extends StatefulWidget {
  const DoctorBookingRecordsScreen({super.key});

  @override
  State<DoctorBookingRecordsScreen> createState() => _DoctorBookingRecordsScreenState();
}

class _DoctorBookingRecordsScreenState extends State<DoctorBookingRecordsScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;
    final baseFontSize = width * 0.04;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: theme.scaffoldBackgroundColor,
      drawer: const DoctorDrawer(),
      appBar: AppBar(
        toolbarHeight: 75.6,
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        automaticallyImplyLeading: false,
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu, size: 24 * (width / 390)),
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          ),
        ),
        titleSpacing: 0,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/splash-logo.png',
              width: 37 * (width / 390),
              height: 40 * (width / 390),
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 8),
            Text(
              'لوحة التحكم',
              style: textTheme.titleLarge?.copyWith(
                fontFamily: 'Cairo',
                fontSize: baseFontSize * 1.125, // 18
                fontWeight: FontWeight.w600,
                height: 1.5,
              ),
            ),
          ],
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: Icon(Icons.notifications_none, size: 24 * (width / 390)),
                onPressed: () {
                  NotificationHelper.hasUnreadNotifications = false;
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const NotificationsScreen()),
                  ).then((_) {
                    if (mounted) setState(() {});
                  });
                },
              ),
              if (NotificationHelper.getUnreadCount() > 0)
              Positioned(
                right: 8,
                top: 10,
                child: Container(
                  width: 16 * (width / 390),
                  height: 16 * (width / 390),
                  decoration: BoxDecoration(
                    color: colorScheme.error,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      NotificationHelper.getUnreadCount() > 9 ? '9+' : '${NotificationHelper.getUnreadCount()}',
                      style: textTheme.labelSmall?.copyWith(
                        color: colorScheme.onError,
                        fontSize: baseFontSize * 0.625, // 10
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.1),
          child: Container(
            height: 1.1,
            color: isDark ? Colors.grey[700]! : const Color(0xFFE5E7EB),
          ),
        ),
      ),
      body: _buildMainContent(context, width, height, baseFontSize),
    );
  }

  Widget _buildBookingCard({
    required BuildContext context,
    required String patientName,
    required String service,
    required String date,
    required String status,
    required Color statusColor,
    required String profileImage,
    required double width,
    required double baseFontSize,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.grey[700]! : const Color(0xFFE5E7EB)),
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                     Container(
                       padding: EdgeInsets.symmetric(
                           horizontal: 12 * (width / 390), vertical: 4 * (width / 390)),
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
                           fontSize: baseFontSize * 0.75, // 12
                         ),
                       ),
                     ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                             Text(
                               patientName,
                               textAlign: TextAlign.right,
                               maxLines: 1,
                               overflow: TextOverflow.ellipsis,
                               style: theme.textTheme.titleMedium?.copyWith(
                                 fontFamily: 'Cairo',
                                 fontWeight: FontWeight.w600,
                                 fontSize: baseFontSize * 1.125, // 18
                               ),
                             ),
                            const SizedBox(height: 4),
                             Text(
                               service,
                               textAlign: TextAlign.right,
                               maxLines: 1,
                               overflow: TextOverflow.ellipsis,
                               style: theme.textTheme.bodyMedium?.copyWith(
                                 fontFamily: 'Cairo',
                                 color: colorScheme.onSurface.withAlpha((0.6 * 255).round()),
                                 fontSize: baseFontSize, // 16
                               ),
                             ),
                            const SizedBox(height: 8),
                             Row(
                               mainAxisAlignment: MainAxisAlignment.end,
                               children: [
                                 Text(
                                   date,
                                   style: theme.textTheme.bodySmall?.copyWith(
                                     fontSize: baseFontSize * 0.75, // 12
                                   ),
                                 ),
                                 const SizedBox(width: 4),
                                 Icon(
                                   Icons.calendar_month,
                                   size: 16 * (width / 390),
                                   color: colorScheme.onSurface.withAlpha((0.6 * 255).round()),
                                 ),
                               ],
                             ),
                          ],
                        ),
                      ),
                    ),
                    Container(
                      width: 60 * (width / 390),
                      height: 70 * (width / 390),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        image: DecorationImage(
                          image: AssetImage(profileImage),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildMainContent(BuildContext context, double width, double height, double baseFontSize) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text(
              'سجل الحجوزات',
              textAlign: TextAlign.right,
              style: theme.textTheme.titleLarge?.copyWith(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.w700,
                fontSize: baseFontSize * 1.5, // 24
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildBookingCard(
            context: context,
            patientName: 'زياد جمال',
            service: 'تقويم اسنان',
            date: '2025-11-29',
            status: 'مكتمل',
            statusColor: Colors.greenAccent,
            profileImage: 'assets/images/zozjpg.jpg',
            width: width,
            baseFontSize: baseFontSize,
          ),
          const SizedBox(height: 12),
          _buildBookingCard(
            context: context,
            patientName: 'عبدالحليم رمضان',
            service: 'حشو عصب',
            date: '2025-11-30',
            status: 'انتظار',
            statusColor: Colors.orangeAccent,
            profileImage: 'assets/images/halim.jpg',
            width: width,
            baseFontSize: baseFontSize,
          ),
          const SizedBox(height: 12),
          _buildBookingCard(
            context: context,
            patientName: 'محمد اشرف',
            service: 'تنظيف أسنان',
            date: '2025-12-01',
            status: 'ملغي',
            statusColor: Colors.redAccent,
            profileImage: 'assets/images/kateb.jpg',
            width: width,
            baseFontSize: baseFontSize,
          ),
          const SizedBox(height: 12),
          _buildBookingCard(
            context: context,
            patientName: 'جوزيف جورح',
            service: 'تركيب كوبري',
            date: '2025-12-02',
            status: 'مكتمل',
            statusColor: Colors.greenAccent,
            profileImage: 'assets/images/joseoh.jpeg',
            width: width,
            baseFontSize: baseFontSize,
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }
}
