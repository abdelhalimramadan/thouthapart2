import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:thotha_mobile_app/core/routing/routes.dart';
import 'package:thotha_mobile_app/core/theming/theme_provider.dart';
import 'package:thotha_mobile_app/features/help_and_support/ui/help_and_support_screen.dart';
import 'package:thotha_mobile_app/features/terms_and_conditions/ui/terms_and_conditions_screen.dart';

import 'package:flutter_svg/flutter_svg.dart';
import 'package:thotha_mobile_app/features/chat/ui/chat_screen.dart';

import '../../../../core/theming/colors.dart';

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
    required double baseFontSize,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Row(
            children: [
              customIcon ??
                  Icon(icon,
                      color: iconColor ?? Theme.of(context).iconTheme.color),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  textAlign: TextAlign.right,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.bold,
                        fontSize: baseFontSize, // 16sp
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
    required double baseFontSize,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Row(
          children: [
            Icon(icon, color: iconColor ?? Theme.of(context).iconTheme.color),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                textAlign: TextAlign.right,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.bold,
                      fontSize: baseFontSize,
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
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final baseFontSize = width * 0.04;
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
                      padding: EdgeInsets.only(top: topPad, bottom: 20),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        border: Border(
                          bottom: BorderSide(
                            color: theme.dividerColor.withValues(alpha: 0.1),
                            width: 1,
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
                                size: 28,
                              ),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ),
                          Image.asset(
                            'assets/images/splash-logo.png',
                            width: 70 * (width / 390),
                            height: 70 * (width / 390),
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'رعاية ذكية، لمسة طبية',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: baseFontSize * 0.875,
                              fontWeight: FontWeight.bold,
                              color: ColorsManager.fontColor,
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
                      baseFontSize: baseFontSize,
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
                        width: 24,
                        height: 24,
                      ),
                      baseFontSize: baseFontSize,
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
                          baseFontSize: baseFontSize,
                        );
                      },
                    ),
                    _menuItem(
                      context,
                      title: 'الشروط والأحكام',
                      icon: Icons.description_outlined,
                      baseFontSize: baseFontSize,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const TermsAndConditionsScreen(),
                          ),
                        );
                      },
                    ),
                    _menuItem(
                      context,
                      title: 'المساعدة والدعم',
                      icon: Icons.help_outline,
                      baseFontSize: baseFontSize,
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
                      baseFontSize: baseFontSize,
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
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  children: [
                    const Divider(indent: 32, endIndent: 32),
                    const SizedBox(height: 8),
                    Text(
                      'الإصدار 1.0.0',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.bold,
                        fontSize: baseFontSize * 0.75,
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
