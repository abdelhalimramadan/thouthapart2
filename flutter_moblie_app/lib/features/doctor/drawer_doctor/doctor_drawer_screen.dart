import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:thoutha_mobile_app/core/di/dependency_injection.dart';
import 'package:thoutha_mobile_app/core/helpers/shared_pref_helper.dart';
import 'package:thoutha_mobile_app/core/networking/api_service.dart';
import 'package:thoutha_mobile_app/core/theming/theme_provider.dart';
import 'package:thoutha_mobile_app/features/about_app/ui/about_app_screen.dart'
    show AboutAppScreen;
import 'package:thoutha_mobile_app/features/doctor/ui/doctor_booking_records_screen.dart';
import 'package:thoutha_mobile_app/features/doctor/ui/doctor_confirmed_appointments_screen.dart';
import 'package:thoutha_mobile_app/features/doctor/ui/doctor_next_booking_screen.dart';
import 'package:thoutha_mobile_app/features/doctor/ui/info_pages/doctor_help_and_support_screen.dart';
import 'package:thoutha_mobile_app/features/doctor/ui/info_pages/doctor_privacy_policy_screen.dart';
import 'package:thoutha_mobile_app/features/doctor/ui/info_pages/doctor_terms_and_conditions_screen.dart';
import 'package:thoutha_mobile_app/features/profile/ui/doctor_profile.dart';
import 'package:thoutha_mobile_app/features/requests/ui/my_requests_screen.dart';
import 'package:thoutha_mobile_app/features/doctor/ui/secondary_home_screen.dart'
    show SecondaryHomeScreen;
import 'package:thoutha_mobile_app/features/login/ui/login_screen.dart';

import '../ui/doctor_home_screen.dart';
import '../../profile/data/models/doctor_profile_model.dart';

class DoctorDrawer extends StatefulWidget {
  const DoctorDrawer({super.key});

  static final ValueNotifier<String?> profileImageNotifier =
      ValueNotifier(null);

  @override
  State<DoctorDrawer> createState() => _DoctorDrawerState();
}

class _DoctorDrawerState extends State<DoctorDrawer> {
  String? _firstName;
  String? _lastName;
  String? _email;
  String? _profileImage;
  int? _doctorId;
  String _appVersion = '1.0.0';
  bool _isLoadingName = false;

  static const _cCyan = Color(0xFF84E5F3);
  static const _cGreen = Color(0xFF8DECB4);

  late ApiService _apiService;

  @override
  void initState() {
    super.initState();
    _apiService = getIt<ApiService>();
    _fetchDoctorInfo();
    _fetchAppVersion();
    DoctorDrawer.profileImageNotifier.addListener(_updateProfileImage);
  }

  @override
  void dispose() {
    DoctorDrawer.profileImageNotifier.removeListener(_updateProfileImage);
    super.dispose();
  }

  void _updateProfileImage() {
    if (DoctorDrawer.profileImageNotifier.value != null) {
      setState(() {
        _profileImage = DoctorDrawer.profileImageNotifier.value;
      });
    }
  }

  Future<void> _fetchAppVersion() async {
    try {
      final PackageInfo packageInfo = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() {
          _appVersion = packageInfo.version;
        });
      }
    } catch (e) {
      debugPrint('Error fetching app version: $e');
    }
  }

  void _showLogoutConfirmation(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: Text(
              'تأكيد تسجيل الخروج',
              textAlign: TextAlign.right,
              style:
                  textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            content: Text(
              'هل أنت متأكد من رغبتك في تسجيل الخروج؟',
              textAlign: TextAlign.right,
              style: textTheme.bodyMedium,
            ),
            actions: <Widget>[
              TextButton(
                child: Text(
                  'إلغاء',
                  style: textTheme.bodyLarge?.copyWith(
                    color: isDark ? Colors.grey[400] : Colors.grey[700],
                  ),
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
              TextButton(
                child: Text(
                  'تسجيل خروج',
                  style: textTheme.bodyLarge?.copyWith(
                    color: Colors.red,
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                    (Route<dynamic> route) => false,
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _menuItem(
    BuildContext context, {
    required String title,
    required IconData icon,
    Color? iconColor,
    Color? textColor,
    bool isSelected = false,
    VoidCallback? onTap,
  }) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? _cCyan.withAlpha(26) : null,
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isSelected
                      ? _cCyan
                      : (iconColor ?? Theme.of(context).iconTheme.color),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    textAlign: TextAlign.right,
                    style: textTheme.bodyLarge?.copyWith(
                      fontFamily: 'Cairo',
                      fontSize: 15,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected
                          ? _cCyan
                          : textColor ??
                              Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
                if (isSelected)
                  Container(
                    width: 4,
                    height: 24,
                    decoration: BoxDecoration(
                      color: _cCyan,
                      borderRadius: const BorderRadius.horizontal(
                        left: Radius.circular(4),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _toggleMenuItem(
    BuildContext context, {
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
    IconData? icon,
    Color? iconColor,
  }) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Row(
            children: [
              Icon(
                icon,
                color: iconColor ?? Theme.of(context).iconTheme.color,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  textAlign: TextAlign.right,
                  style: textTheme.bodyLarge?.copyWith(
                    fontFamily: 'Cairo',
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              Switch.adaptive(
                value: value,
                onChanged: onChanged,
                activeTrackColor: const Color(0xFF10B981),
                inactiveThumbColor: Colors.white,
                inactiveTrackColor: Theme.of(context).dividerColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _fetchDoctorInfo() async {
    setState(() => _isLoadingName = true);

    try {
      final cachedFirstName = await SharedPrefHelper.getString('first_name');
      final cachedLastName = await SharedPrefHelper.getString('last_name');
      final cachedEmail = await SharedPrefHelper.getString('email');
      final cachedImage = await SharedPrefHelper.getString('profile_image');
      
      // doctor_id is stored as int, so use getInt
      final cachedId = await SharedPrefHelper.getInt('doctor_id');
      // getInt returns 0 if not found, convert to null
      final doctorId = cachedId > 0 ? cachedId : null;

      debugPrint('Drawer - Cached data: firstName=$cachedFirstName, lastName=$cachedLastName, email=$cachedEmail, doctorId=$doctorId');

      // Always load cached data if available
      if (cachedFirstName != null && cachedFirstName.isNotEmpty) {
        setState(() {
          _firstName = cachedFirstName;
          _lastName = cachedLastName;
          _email = cachedEmail;
          _profileImage =
              (cachedImage?.isNotEmpty ?? false) ? cachedImage : _profileImage;
          _doctorId = doctorId;
        });
        debugPrint('Drawer - Loaded cached data into state');
      } else {
        debugPrint('Drawer - No cached data found');
      }

      // Fetch from API to update info and get doctor ID if missing/changed
      final result = await _apiService.getDoctorById();
      debugPrint('Drawer - API result: $result');
      
      if (result['success'] == true && result['data'] != null) {
        final doctorData = result['data'] as DoctorProfileModel;
        debugPrint('Drawer - Doctor data from API: firstName=${doctorData.firstName}, lastName=${doctorData.lastName}, email=${doctorData.email}');
        
        // Only update with non-null values from API to preserve cached data
        if (doctorData.firstName != null ||
            doctorData.lastName != null ||
            doctorData.email != null) {
          setState(() {
            _firstName = doctorData.firstName ?? _firstName;
            _lastName = doctorData.lastName ?? _lastName;
            _email = doctorData.email ?? _email;
            _doctorId = doctorData.id ?? _doctorId;
          });
          debugPrint('Drawer - Updated state with API data');
        }

        if (doctorData.firstName != null) {
          await SharedPrefHelper.setData('first_name', doctorData.firstName!);
        }
        if (doctorData.lastName != null) {
          await SharedPrefHelper.setData('last_name', doctorData.lastName!);
        }
        if (doctorData.email != null) {
          await SharedPrefHelper.setData('email', doctorData.email!);
        }
        if (doctorData.id != null) {
          await SharedPrefHelper.setData('doctor_id', doctorData.id);
        }
      } else {
        debugPrint('Drawer - API call failed or returned no data');
      }
    } catch (e) {
      debugPrint('Exception fetching doctor info: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingName = false);
      }
    }
  }

  int _getCurrentIndex() {
    final currentRoute =
        ModalRoute.of(context)?.settings.name?.toLowerCase() ?? '';
    if (currentRoute.contains('doctor-home')) return 0;
    if (currentRoute.contains('add-case')) return 1;
    if (currentRoute.contains('doctor-profile') ||
        currentRoute.contains('profile')) return 2;
    if (currentRoute.contains('upcoming-bookings') ||
        currentRoute.contains('doctor-next-booking')) return 3;
    if (currentRoute.contains('booking-records') ||
        currentRoute.contains('records') ||
        currentRoute.contains('appointment-history')) return 4;
    if (currentRoute.contains('confirmed-appointments') ||
        currentRoute.contains('doctor-confirmed-appointments')) return 5;
    if (currentRoute.contains('doctor-requests')) return 6;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;
    final double topPad = MediaQuery.of(context).padding.top;
    final int currentIndex = _getCurrentIndex();

    return Drawer(
      child: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: topPad + 160,
              padding: EdgeInsets.only(top: topPad),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: isDark
                      ? [_cCyan.withAlpha(200), _cGreen.withAlpha(200)]
                      : [_cCyan, _cGreen],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.max,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(width: 48),
                        Expanded(
                          child: Text(
                            'القائمة',
                            textAlign: TextAlign.center,
                            style: textTheme.titleLarge?.copyWith(
                              fontFamily: 'Cairo',
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.surface,
                            ),
                          ),
                        ),
                        IconButton(
                          padding: EdgeInsets.zero,
                          icon: Icon(
                            Icons.close,
                            color: Theme.of(context).colorScheme.surface,
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color:
                            Theme.of(context).colorScheme.surface.withAlpha(64),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Directionality(
                        textDirection: TextDirection.rtl,
                        child: Row(
                          children: [
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      (_firstName != null &&
                                              _firstName!.isNotEmpty)
                                          ? 'د/ ${_firstName!} ${_lastName ?? ''}'
                                          : 'دكتور',
                                      style:
                                          textTheme.titleMedium?.copyWith(
                                        fontFamily: 'Cairo',
                                        color: Theme.of(context)
                                            .colorScheme
                                            .surface,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _email != null && _email!.isNotEmpty
                                          ? _email!
                                          : '********',
                                      style: textTheme.bodySmall?.copyWith(
                                        fontFamily: 'Cairo',
                                        color: Theme.of(context)
                                            .colorScheme
                                            .surface,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _menuItem(
                    context,
                    title: 'الصفحة الرئيسية',
                    icon: Icons.home,
                    isSelected: currentIndex == 0,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          settings: const RouteSettings(name: 'doctor-home'),
                          builder: (context) => const DoctorHomeScreen(),
                        ),
                      );
                    },
                  ),
                  _menuItem(
                    context,
                    title: 'إضافة حالة جديدة',
                    icon: Icons.add_circle_outline,
                    isSelected: currentIndex == 1,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          settings: const RouteSettings(name: 'add-case'),
                          builder: (context) => const SecondaryHomeScreen(
                            drawer: DoctorDrawer(),
                            showAddCaseCategory: true,
                          ),
                        ),
                      );
                    },
                  ),
                  _menuItem(
                    context,
                    title: 'الملف الشخصي',
                    icon: Icons.person_outline,
                    isSelected: currentIndex == 2,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          settings: const RouteSettings(name: 'doctor-profile'),
                          builder: (context) => const DoctorProfileScreen(),
                        ),
                      );
                    },
                  ),
                  _menuItem(
                    context,
                    title: 'الحجوزات القادمة',
                    icon: Icons.event_note_outlined,
                    isSelected: currentIndex == 3,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          settings:
                              const RouteSettings(name: 'upcoming-bookings'),
                          builder: (context) => DoctorNextBookingScreen(),
                        ),
                      );
                    },
                  ),
                  _menuItem(
                    context,
                    title: 'سجل الحجوزات',
                    icon: Icons.history,
                    isSelected: currentIndex == 4,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          settings:
                              const RouteSettings(name: 'booking-records'),
                          builder: (context) =>
                              const DoctorBookingRecordsScreen(),
                        ),
                      );
                    },
                  ),
                  _menuItem(
                    context,
                    title: 'الحجوزات المؤكدة',
                    icon: Icons.check_circle_outline,
                    isSelected: currentIndex == 5,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          settings: const RouteSettings(
                              name: 'confirmed-appointments'),
                          builder: (context) =>
                              const DoctorConfirmedAppointmentsScreen(),
                        ),
                      );
                    },
                  ),
                  _menuItem(
                    context,
                    title: 'طلباتي',
                    icon: Icons.assignment_outlined,
                    isSelected: currentIndex == 6,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          settings:
                              const RouteSettings(name: 'doctor-requests'),
                          builder: (context) => const MyRequestsScreen(),
                        ),
                      );
                    },
                  ),
                  Consumer<ThemeProvider>(
                    builder: (context, themeProvider, _) {
                      return _toggleMenuItem(
                        context,
                        title: 'الوضع الداكن',
                        value: themeProvider.isDarkMode,
                        onChanged: (value) => themeProvider.toggleTheme(value),
                        icon: Icons.dark_mode_outlined,
                      );
                    },
                  ),
                  _menuItem(
                    context,
                    title: 'حول التطبيق',
                    icon: Icons.info_outline,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AboutAppScreen(),
                        ),
                      );
                    },
                  ),
                  _menuItem(
                    context,
                    title: 'الشروط والأحكام',
                    icon: Icons.description_outlined,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const DoctorTermsAndConditionsScreen(),
                        ),
                      );
                    },
                  ),
                  _menuItem(
                    context,
                    title: 'سياسة الخصوصية',
                    icon: Icons.shield_outlined,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const DoctorPrivacyPolicyScreen(),
                        ),
                      );
                    },
                  ),
                  _menuItem(
                    context,
                    title: 'المساعدة والدعم',
                    icon: Icons.help_outline,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const DoctorHelpAndSupportScreen(),
                        ),
                      );
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Divider(height: 24),
                  ),
                  _menuItem(
                    context,
                    title: 'تسجيل الخروج',
                    icon: Icons.logout_outlined,
                    textColor: Colors.red,
                    onTap: () {
                      Navigator.pop(context);
                      _showLogoutConfirmation(context);
                    },
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: Text(
                  'الإصدار $_appVersion',
                  style: textTheme.bodySmall?.copyWith(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
