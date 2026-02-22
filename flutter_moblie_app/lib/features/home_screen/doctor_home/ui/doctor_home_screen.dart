import 'package:dio/dio.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../../core/helpers/shared_pref_helper.dart';
import '../../../../core/networking/dio_factory.dart';
import '../../../../core/utils/notification_helper.dart';
import '../drawer/doctor_drawer_screen.dart';
import '../../../notifications/ui/notifications_screen.dart';
import '../../../../core/theming/colors.dart';
import 'add_case_request_screen.dart';

class DoctorHomeScreen extends StatefulWidget {
  const DoctorHomeScreen({Key? key}) : super(key: key);

  @override
  State<DoctorHomeScreen> createState() => _DoctorHomeScreenState();
}

class _DoctorHomeScreenState extends State<DoctorHomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  BarChartGroupData _buildBarGroup(int x, double y, double widthFactor) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          gradient: const LinearGradient(
            colors: [Color(0xFF84E5F3), Color(0xFF8DECB4)],
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
          ),
          width: 25 * widthFactor,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
      showingTooltipIndicators: [0],
    );
  }

  String? _firstName;
  String? _lastName;
  bool _isLoadingName = false;

  @override
  void initState() {
    super.initState();
    _fetchDoctorName();
  }

  Future<void> _fetchDoctorName() async {
    setState(() {
      _isLoadingName = true;
    });

    try {
      final storedFirst = await SharedPrefHelper.getString('first_name');
      final storedLast = await SharedPrefHelper.getString('last_name');

      if (storedFirst != null && storedFirst.isNotEmpty) {
        _firstName = storedFirst;
        _lastName = storedLast;
        setState(() {
          _isLoadingName = false;
        });
        return;
      }

      final dio = DioFactory.getDio();
      Response response;
      try {
        response = await dio.get('/me');
      } catch (_) {
        try {
          response = await dio.get('/profile');
        } catch (_) {
          final email = await SharedPrefHelper.getString('email');
          if (email.isNotEmpty) {
            _firstName = email.split('@').first;
            setState(() => _isLoadingName = false);
            return;
          }
          rethrow;
        }
      }

      if (response.statusCode == 200) {
        final data = response.data;
        _firstName = (data is Map &&
                (data['first_name'] != null || data['firstName'] != null))
            ? (data['first_name'] ?? data['firstName'])
            : (data is Map && data['firstName'] != null
                ? data['firstName']
                : null);
        _lastName = (data is Map &&
                (data['last_name'] != null || data['lastName'] != null))
            ? (data['last_name'] ?? data['lastName'])
            : (data is Map && data['lastName'] != null
                ? data['lastName']
                : null);

        if ((_firstName == null || _firstName!.isEmpty) &&
            data is Map &&
            data['user'] != null) {
          final user = data['user'];
          _firstName = user['first_name'] ?? user['firstName'];
          _lastName = user['last_name'] ?? user['lastName'];
        }

        if (_firstName != null && _firstName!.isNotEmpty) {
          await SharedPrefHelper.setData('first_name', _firstName);
          if (_lastName != null)
            await SharedPrefHelper.setData('last_name', _lastName);
        }
      }
    } catch (e) {
      debugPrint('Exception: $e');
    } finally {
      if (_firstName == null || _firstName!.isEmpty) {
        final email = await SharedPrefHelper.getString('email');
        if (email.isNotEmpty) {
          _firstName = email.split('@').first;
        }
      }
      if (mounted) setState(() => _isLoadingName = false);
    }
  }

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
    final unreadCount = NotificationHelper.getUnreadCount();

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: theme.scaffoldBackgroundColor,
      drawer: const DoctorDrawer(),
      appBar: AppBar(
        toolbarHeight: 75,
        elevation: 0,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        automaticallyImplyLeading: false,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, size: 24),
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
                fontSize: baseFontSize * 1.125, // 18sp
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
                icon: const Icon(Icons.notifications_none, size: 24),
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
              if (unreadCount > 0)
                Positioned(
                  right: 8,
                  top: 10,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: colorScheme.error,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        unreadCount > 9 ? '9+' : '$unreadCount',
                        style: textTheme.labelSmall?.copyWith(
                          color: colorScheme.onError,
                          fontSize: 10,
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddCaseRequestScreen(),
            ),
          );
        },
        backgroundColor: ColorsManager.mainBlue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _buildMainContent(width, height, baseFontSize, colorScheme, textTheme, isDark, theme),
    );
  }

  Widget _buildMainContent(double width, double height, double baseFontSize, ColorScheme colorScheme, TextTheme textTheme, bool isDark, ThemeData theme) {
    return Container(
      color: theme.scaffoldBackgroundColor,
      child: SingleChildScrollView(
        child: Column(
          children: [
            // Welcome Container
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: width * 0.05,
                vertical: height * 0.02,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _isLoadingName
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 3),
                        )
                      : Text(
                          _firstName != null
                              ? ' Welcome $_firstName'
                              : ' مرحباً، د.',
                          style: textTheme.titleLarge?.copyWith(
                            fontFamily: 'Cairo',
                            fontSize: baseFontSize * 1.5, // 24sp
                            fontWeight: FontWeight.w700,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.right,
                        ),
                  const SizedBox(height: 6),
                  Text(
                    'إليك نظرة عامة على حجوزاتك وأدائك',
                    style: textTheme.bodyMedium?.copyWith(
                      fontFamily: 'Cairo',
                      fontSize: baseFontSize * 0.9375, // 15sp
                      fontWeight: FontWeight.w400,
                      height: 1.5,
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    textAlign: TextAlign.right,
                  ),
                ],
              ),
            ),

            // Grid Container with 4 cards
            Padding(
              padding: EdgeInsets.symmetric(horizontal: width * 0.05),
              child: GridView.count(
                crossAxisCount: width > 600 ? 4 : 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: width > 600 ? 1.5 : (187 / 105),
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                children: [
                  _buildStatCard('الحجوزات اليوم', '28', Icons.people_outline, isDark, theme, colorScheme, textTheme, baseFontSize),
                  _buildStatCard('الحجوزات اليوم', '28', Icons.calendar_today, isDark, theme, colorScheme, textTheme, baseFontSize),
                  _buildStatCard('الحجوزات المكتملة', '20', Icons.check_circle_outline, isDark, theme, colorScheme, textTheme, baseFontSize),
                  _buildStatCard('التقييم', '4.8', Icons.star_border, isDark, theme, colorScheme, textTheme, baseFontSize),
                ],
              ),
            ),

            // الحجوزات القادمة اليوم Header
            Container(
              width: double.infinity,
              padding: EdgeInsets.only(
                top: 20,
                left: width * 0.05,
                right: width * 0.05,
              ),
              alignment: Alignment.centerRight,
              child: Text(
                'الحجوزات القادمة اليوم',
                style: textTheme.titleMedium?.copyWith(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.w600,
                  fontSize: baseFontSize * 1.125, // 18sp
                  height: 1.5,
                  color: colorScheme.onSurface,
                ),
                textAlign: TextAlign.right,
              ),
            ),

            // Appointments List
            ListView.builder(
              padding: EdgeInsets.all(width * 0.05),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 3,
              itemBuilder: (context, index) {
                final names = ['محمد اشرف', 'عبدالحليم رمضان', 'زياد جمال'];
                final specialties = ['تنضيف اسنان', 'حشو العصب ', ' تقويم الأسنان'];
                final times = ['1:00', '11:00', '8:00'];
                final images = ['assets/images/kateb.jpg', 'assets/images/halim.jpg', 'assets/images/zozjpg.jpg'];
                
                return _buildAppointmentCard(
                  names[index],
                  specialties[index],
                  times[index],
                  images[index],
                  isDark,
                  theme,
                  colorScheme,
                  width,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, bool isDark, ThemeData theme, ColorScheme colorScheme, TextTheme textTheme, double baseFontSize) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey[700]! : const Color(0xFFE5E7EB),
          width: 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.grey.withValues(alpha: 0.1),
            offset: const Offset(0, 1),
            blurRadius: 3,
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: textTheme.bodySmall?.copyWith(
                    fontFamily: 'Cairo',
                    fontSize: baseFontSize * 0.75, // 12sp
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                    height: 1.0,
                    fontWeight: FontWeight.w400,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: textTheme.titleMedium?.copyWith(
                    fontFamily: 'Cairo',
                    fontSize: baseFontSize * 1.375, // 22sp
                    fontWeight: FontWeight.w600,
                    height: 1.1,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[800] : Colors.grey[200],
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 20,
              color: theme.iconTheme.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentCard(String name, String specialty, String time, String imagePath, bool isDark, ThemeData theme, ColorScheme colorScheme, double width) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey[700]! : const Color(0xFFE5E7EB),
          width: 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withValues(alpha: 0.3) : Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Time info
          Column(
            children: [
              Text(
                'صباحاً',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.w400,
                  fontSize: 12,
                  color: const Color(0xFF8DECB4),
                ),
              ),
              Text(
                time,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.w400,
                  fontSize: 14,
                  color: const Color(0xFF8DECB4),
                ),
              ),
            ],
          ),
          const Spacer(),
          // Patient info
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  name,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                    color: colorScheme.onSurface,
                  ),
                ),
                Text(
                  specialty,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w400,
                    fontSize: 14,
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Patient image
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              image: DecorationImage(
                image: AssetImage(imagePath),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
