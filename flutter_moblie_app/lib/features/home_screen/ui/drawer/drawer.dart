import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:thoutha_mobile_app/core/routing/routes.dart';
import 'package:thoutha_mobile_app/core/theming/theme_provider.dart';
import 'package:thoutha_mobile_app/features/help_and_support/ui/help_and_support_screen.dart';
import 'package:thoutha_mobile_app/features/terms_and_conditions/ui/terms_and_conditions_screen.dart';
import 'package:thoutha_mobile_app/features/privacy_policy/ui/privacy_policy_screen.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:thoutha_mobile_app/features/chat/ui/chat_screen.dart';

class HomeDrawer extends StatelessWidget {
  const HomeDrawer({super.key});

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
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Row(
            children: [
              customIcon ??
                  Icon(icon,
                      size: 24.r,
                      color: iconColor ?? Theme.of(context).iconTheme.color),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  title,
                  textAlign: TextAlign.right,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.bold,
                        fontSize: fontSize ?? 16.sp,
                        color: textColor ??
                            Theme.of(context).colorScheme.onSurface,
                      ),
                ),
              ),
            ],
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
    double? fontSize,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Row(
          children: [
            Icon(icon,
                size: 24.r,
                color: iconColor ?? Theme.of(context).iconTheme.color),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                title,
                textAlign: TextAlign.right,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.bold,
                      fontSize: fontSize ?? 16.sp,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
              ),
            ),
            Switch.adaptive(
              value: value,
              onChanged: onChanged,
              activeTrackColor: const Color(0xFF8DECB8),
              inactiveThumbColor: Colors.white,
              inactiveTrackColor: Theme.of(context).dividerColor,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double topPad = MediaQuery.of(context).padding.top;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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
                      padding: EdgeInsets.only(top: topPad, bottom: 20.h),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        border: Border(
                          bottom: BorderSide(
                            color: theme.dividerColor.withValues(alpha: 0.1),
                            width: 1.w,
                          ),
                        ),
                      ),
                      child: Column(
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: IconButton(
                              icon: Icon(
                                Icons.close,
                                color: colorScheme.onSurface,
                                size: 28.r,
                              ),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ),
                          Image.asset(
                            'assets/images/splash-logo.png',
                            width: 70.w,
                            height: 70.h,
                            fit: BoxFit.contain,
                          ),
                          SizedBox(height: 12.h),
                          Text(
                            'رعاية ذكية، لمسة طبية',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface,
                              fontFamily: 'Cairo',
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Menu Items
                    _menuItem(
                      context,
                      title: 'الصفحة الرئيسية',
                      icon: Icons.home_outlined,
                      fontSize: 16.sp,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          Routes.categoriesScreen,
                          (route) => false,
                        );
                      },
                    ),
                    _menuItem(
                      context,
                      title: 'ثوثه المساعد',
                      customIcon: SvgPicture.asset(
                        'assets/svg/ثوثه الدكتور 1.svg',
                        width: 24.w,
                        height: 24.h,
                      ),
                      fontSize: 16.sp,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ChatScreen(),
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
                          onChanged: (v) => themeProvider.toggleTheme(v),
                          icon: Icons.dark_mode_outlined,
                          fontSize: 16.sp,
                        );
                      },
                    ),
                    _menuItem(
                      context,
                      title: 'الشروط والأحكام',
                      icon: Icons.description_outlined,
                      fontSize: 16.sp,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const TermsAndConditionsScreen(),
                          ),
                        );
                      },
                    ),
                    _menuItem(
                      context,
                      title: 'سياسة الخصوصية',
                      icon: Icons.shield_outlined,
                      fontSize: 16.sp,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PrivacyPolicyScreen(),
                          ),
                        );
                      },
                    ),
                    _menuItem(
                      context,
                      title: 'المساعدة والدعم',
                      icon: Icons.help_outline,
                      fontSize: 16.sp,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const HelpAndSupportScreen(),
                          ),
                        );
                      },
                    ),
                    _menuItem(
                      context,
                      title: 'تسجيل الدخول',
                      icon: Icons.login_outlined,
                      fontSize: 16.sp,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          Routes.loginScreen,
                          (route) => false,
                        );
                      },
                    ),
                  ],
                ),
              ),

              // Footer Section
              Padding(
                padding: EdgeInsets.symmetric(vertical: 16.h),
                child: Column(
                  children: [
                    const Divider(indent: 32, endIndent: 32),
                    SizedBox(height: 8.h),
                    Text(
                      'الإصدار 1.0.0',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.bold,
                        fontSize: 12.sp,
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
  }
}
