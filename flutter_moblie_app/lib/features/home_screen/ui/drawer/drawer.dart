import 'package:flutter/material.dart';
import 'package:thotha_mobile_app/core/routing/routes.dart';
import 'package:thotha_mobile_app/features/help_and_support/ui/help_and_support_screen.dart';
import 'package:thotha_mobile_app/features/home_screen/ui/drawer/settings/ui/home_settings_screen.dart'
    show HomeSettingsScreen;
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: topPad + 180,
              padding: EdgeInsets.only(top: topPad),
              child: Column(
                mainAxisSize: MainAxisSize.max,
                children: [
                   SizedBox(
                    height: 56,
                    child: Stack(
                      children: [
                        Center(
                          child: Text(
                            'القائمة',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontFamily: 'Cairo',
                              fontWeight: FontWeight.bold,
                              fontSize: baseFontSize * 1.25, // 20sp
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: IconButton(
                            icon: const Icon(
                              Icons.close,
                              color: Colors.black,
                              size: 30,
                            ),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Logo Image
                        Image.asset(
                          'assets/images/splash-logo.png',
                          width: 77 * (width / 390),
                          height: 77 * (width / 390),
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(height: 16),
                        // Title Text
                        Text(
                          'رعاية ذكية، لمسة طبية',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: baseFontSize * 0.875, // 14sp
                            fontWeight: FontWeight.bold,
                            color: ColorsManager.fontColor,
                            fontFamily: 'Cairo',
                          ),
                        ),
                      ],
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
                    icon: Icons.home_outlined,
                    baseFontSize: baseFontSize,
                    onTap: () {
                      Navigator.pop(context); // Close drawer
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
                      Navigator.pop(context); // Close drawer
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ChatScreen(),
                        ),
                      );
                    },
                  ),
                  _menuItem(
                    context,
                    title: 'الإعدادات',
                    icon: Icons.settings_outlined,
                    baseFontSize: baseFontSize,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const HomeSettingsScreen()),
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
                    icon: Icons.person,
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
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Divider(height: 24),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: Text(
                  'الإصدار 1.0.0',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.bold,
                    fontSize: baseFontSize * 0.75, // 12sp
                    color: colorScheme.onSurfaceVariant,
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
