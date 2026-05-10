import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:thoutha_mobile_app/core/routing/routes.dart';
import 'package:thoutha_mobile_app/core/theming/theme_provider.dart';
import 'package:thoutha_mobile_app/features/help_and_support/ui/help_and_support_screen.dart';
import 'package:thoutha_mobile_app/features/terms_and_conditions/ui/terms_and_conditions_screen.dart';
import 'package:thoutha_mobile_app/features/privacy_policy/ui/privacy_policy_screen.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:thoutha_mobile_app/features/chat/ui/chat_screen.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:showcaseview/showcaseview.dart';
import 'package:thoutha_mobile_app/tour/tour_config.dart';
import 'package:thoutha_mobile_app/tour/tour_service.dart';

class HomeDrawer extends StatefulWidget {
  const HomeDrawer({super.key});

  @override
  State<HomeDrawer> createState() => _HomeDrawerState();
}

class _HomeDrawerState extends State<HomeDrawer> {
  bool _isTourStarted = false;

  @override
  void initState() {
    super.initState();
  }

  Widget _menuItem(
    BuildContext context, {
    required String title,
    IconData? icon,
    Widget? customIcon,
    Color? iconColor,
    Color? textColor,
    VoidCallback? onTap,
    double? fontSize,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            customIcon ??
                Icon(icon,
                    size: 24,
                    color: iconColor ?? Theme.of(context).iconTheme.color),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                textAlign: TextAlign.start,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: fontSize ?? 16,
                      color: textColor ??
                          Theme.of(context).colorScheme.onSurface,
                    ),
              ),
            ),
          ],
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
    double? fontSize,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Icon(icon,
              size: 24,
              color: iconColor ?? Theme.of(context).iconTheme.color),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.start,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: fontSize ?? 16,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeTrackColor: Color(0xFF8DECB8),
            inactiveThumbColor: isDark ? Colors.black : Colors.white,
            inactiveTrackColor: Theme.of(context).dividerColor,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double topPad = MediaQuery.of(context).padding.top;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ShowCaseWidget(
      onComplete: (index, key) {
        TourService.onDismiss(key)();
      },
      builder: (context) {
        if (!_isTourStarted) {
          _isTourStarted = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) TourService.startTourForScreen(context, 'home_drawer');
          });
        }
        return Drawer(
      child: Container(
        color: theme.scaffoldBackgroundColor,
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    // Header Section
                    Container(
                      padding: EdgeInsets.only(top: topPad, bottom: 20),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        border: Border(
                          bottom: BorderSide(
                            color: theme.dividerColor.withOpacity(0.1),
                          ),
                        ),
                      ),
                      child: Column(
                        children: [
                          Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: IconButton(
                              icon: Icon(
                                Icons.close,
                                color: colorScheme.onSurface,
                                size: 28,
                              ),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ),
                          Image.asset(
                            'assets/images/splash-logo.png',
                            width: 70,
                            height: 70,
                            fit: BoxFit.contain,
                          ),
                          SizedBox(height: 12),
                          Text(
                            'home_screen.smart_care_medical_touch'.tr(),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface,
                              fontFamily: 'Cairo',
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Menu Items
                    Showcase(
                      key: TourConfig.drawerHomeKey,
                      title: 'الرئيسية',
                      description: 'ارجع لصفحة التصفح الرئيسية',
                      child: _menuItem(
                      context,
                      title: 'doctor.home'.tr(),
                      icon: Icons.home_outlined,
                      fontSize: 16,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          Routes.categoriesScreen,
                          (route) => false,
                        );
                      },
                    ),
                    ),
                    Showcase(
                      key: TourConfig.drawerChatKey,
                      title: 'مساعد ثوثة',
                      description: 'تحدث مع المساعد الذكي للحصول على توصيات',
                      child: _menuItem(
                      context,
                      title: 'home_screen.thutha_assistant'.tr(),
                      customIcon: SvgPicture.asset(
                        'assets/svg/ثوثه الدكتور 1.svg',
                        width: 24,
                        height: 24,
                      ),
                      fontSize: 16,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatScreen(),
                          ),
                        );
                      },
                    ),
                    ),
                    Consumer<ThemeProvider>(
                      builder: (context, themeProvider, _) {
                        return _toggleMenuItem(
                          context,
                          title: 'doctor.dark_mode'.tr(),
                          value: themeProvider.isDarkMode,
                          onChanged: (v) => themeProvider.toggleTheme(v),
                          icon: Icons.dark_mode_outlined,
                          fontSize: 16,
                        );
                      },
                    ),
                    Showcase(
                      key: TourConfig.drawerLanguageKey,
                      title: 'تغيير اللغة',
                      description: 'بدّل بين العربية والإنجليزية',
                      child: _toggleMenuItem(
                      context,
                      title: 'doctor.change_language'.tr(),
                      value: context.locale.languageCode == 'en',
                      onChanged: (v) {
                        if (v) {
                          context.setLocale(const Locale('en'));
                        } else {
                          context.setLocale(const Locale('ar'));
                        }
                      },
                      icon: Icons.language,
                      fontSize: 16,
                    ),
                    ),
                    _menuItem(
                      context,
                      title: 'doctor.terms_and_conditions'.tr(),
                      icon: Icons.description_outlined,
                      fontSize: 16,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                TermsAndConditionsScreen(),
                          ),
                        );
                      },
                    ),
                    _menuItem(
                      context,
                      title: 'doctor.privacy_policy'.tr(),
                      icon: Icons.shield_outlined,
                      fontSize: 16,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PrivacyPolicyScreen(),
                          ),
                        );
                      },
                    ),
                    _menuItem(
                      context,
                      title: 'doctor.help_and_support'.tr(),
                      icon: Icons.help_outline,
                      fontSize: 16,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => HelpAndSupportScreen(),
                          ),
                        );
                      },
                    ),
                    Showcase(
                      key: TourConfig.drawerLoginKey,
                      title: 'تسجيل الدخول',
                      description: 'سجّل دخولك كطبيب لإدارة حجوزاتك',
                      child: _menuItem(
                      context,
                      title: 'home_screen.login'.tr(),
                      icon: Icons.login_outlined,
                      fontSize: 16,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          Routes.loginScreen,
                          (route) => false,
                        );
                      },
                    ),
                    ),
                  ],
                ),
              ),

              // Footer Section
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  children: [
                    Divider(indent: 32, endIndent: 32),
                    SizedBox(height: 8),
                    Text(
                      'home_screen.version_100'.tr(),
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
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
    },
   );
  }
}
