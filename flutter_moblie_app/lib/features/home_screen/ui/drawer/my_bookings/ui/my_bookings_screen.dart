import 'package:flutter/material.dart';
import 'package:thotha_mobile_app/features/home_screen/ui/drawer/drawer.dart';
import 'package:thotha_mobile_app/features/home_screen/ui/drawer/settings/ui/settings_screen.dart';

class MyBookingsScreen extends StatelessWidget {
  MyBookingsScreen({super.key});
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

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: theme.scaffoldBackgroundColor,
      drawer: const Drawer(
        child: HomeDrawer(),
      ),
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: SizedBox(
          width: double.infinity,
          height: 50,
          child: Stack(
            children: [
              Positioned(
                left: 0,
                child: IconButton(
                  icon: Icon(
                    Icons.menu,
                    color: theme.iconTheme.color,
                    size: 32 * (width / 390),
                  ),
                  onPressed: () {
                    _scaffoldKey.currentState?.openDrawer();
                  },
                ),
              ),
              Positioned(
                right: width * 0.08,
                child: Image.asset(
                  'assets/images/splash-logo.png',
                  width: 46 * (width / 390),
                  height: 50 * (width / 390),
                  fit: BoxFit.contain,
                ),
              ),
            ],
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // User greeting
              Padding(
                padding: EdgeInsets.symmetric(horizontal: width * 0.05, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(
                      Icons.notifications_none,
                      size: 30 * (width / 390),
                      color: theme.iconTheme.color,
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'مرحباً، أهلاً بعودتك',
                          textDirection: TextDirection.rtl,
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.w400,
                            fontSize: baseFontSize,
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                        ),
                        Text(
                          'يوسف ايمن',
                          textDirection: TextDirection.rtl,
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.w600,
                            fontSize: baseFontSize * 1.375, // 22
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Search bar
              Container(
                width: double.infinity,
                height: 44,
                margin: EdgeInsets.symmetric(horizontal: width * 0.05, vertical: 10),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isDark ? Colors.grey[700]! : const Color(0xFF021433),
                    width: 0.5,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      ' ابحث عن ',
                      style: TextStyle(fontFamily: 'Cairo', fontSize: baseFontSize * 0.875),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.search,
                      size: 20,
                      color: theme.iconTheme.color?.withOpacity(0.7),
                    ),
                  ],
                ),
              ),

              // Main Content
              Padding(
                padding: EdgeInsets.symmetric(horizontal: width * 0.05, vertical: 15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'حجوزاتي القادمه',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.w700,
                        fontSize: baseFontSize * 1.75, // 28
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildBookingCard(
                      context: context,
                      patientName: 'زياد جمال',
                      service: 'تدريب زراعة اسنان',
                      time: '11:30 صباحا',
                      date: '2025-11-29',
                      profileImage: 'assets/images/test.jpg',
                      width: width,
                      baseFontSize: baseFontSize,
                    ),
                  ],
                ),
              ),
              SizedBox(height: MediaQuery.of(context).padding.bottom + 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBookingCard({
    required BuildContext context,
    required String patientName,
    required String service,
    required String time,
    required String date,
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
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.3) : Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            textDirection: TextDirection.rtl,
            children: [
              Container(
                width: 70 * (width / 390),
                height: 70 * (width / 390),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  image: DecorationImage(
                    image: AssetImage(profileImage),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      patientName,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.w600,
                        fontSize: baseFontSize * 1.125, // 18
                      ),
                    ),
                    Text(
                      service,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: baseFontSize * 0.875, // 14
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          time,
                          style: TextStyle(fontSize: baseFontSize * 0.75, color: Colors.grey),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.access_time, size: 14, color: Colors.grey),
                        const SizedBox(width: 12),
                        Text(
                          date,
                          style: TextStyle(fontSize: baseFontSize * 0.75, color: Colors.grey),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.calendar_month, size: 14, color: Colors.grey),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFEF2F2),
                    foregroundColor: const Color(0xFFE7000B),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                      side: const BorderSide(color: Color(0xFFE7000B)),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  child: Text(
                    'إلغاء',
                    style: TextStyle(fontFamily: 'Cairo', fontSize: baseFontSize * 0.875),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEFF6FF),
                    foregroundColor: const Color(0xFF155DFC),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                      side: const BorderSide(color: Color(0xFF155DFC)),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  child: Text(
                    'تعديل',
                    style: TextStyle(fontFamily: 'Cairo', fontSize: baseFontSize * 0.875),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

extension SettingsNavigation on BuildContext {
  void navigateToSettings() {
    Navigator.push(
      this,
      MaterialPageRoute(builder: (context) => SettingsScreen()),
    );
  }
}
