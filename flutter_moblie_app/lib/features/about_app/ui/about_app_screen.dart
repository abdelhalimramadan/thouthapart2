import 'package:flutter/material.dart';
import 'package:thoutha_mobile_app/features/doctor/drawer_doctor/doctor_drawer_screen.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;

class AboutAppScreen extends StatefulWidget {
  const AboutAppScreen({super.key});

  @override
  State<AboutAppScreen> createState() => _AboutAppScreenState();
}

class _AboutAppScreenState extends State<AboutAppScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isTablet = screenWidth >= 600;

    return Directionality(
      textDirection: context.locale.languageCode == 'ar'
          ? TextDirection.rtl
          : TextDirection.ltr,
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: theme.scaffoldBackgroundColor,
        drawer: DoctorDrawer(),
        appBar: AppBar(
          toolbarHeight: isTablet ? 78 : 68,
          backgroundColor: colorScheme.surface,
          foregroundColor: colorScheme.onSurface,
          elevation: 0,
          automaticallyImplyLeading: false,
          leading: Builder(
            builder: (context) => IconButton(
              icon: Icon(Icons.menu, size: 24),
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            ),
          ),
          titleSpacing: 0,
          centerTitle: true,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'about_app.about_the_application'.tr(),
                style: textTheme.titleLarge?.copyWith(
                  fontFamily: 'Cairo',
                  fontSize: isTablet ? 20 : 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(width: 8),
              Image.asset(
                'assets/images/splash-logo.png',
                width: isTablet ? 40 : 34,
                height: isTablet ? 40 : 34,
                fit: BoxFit.contain,
              ),
            ],
          ),
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isTablet ? 28 : 16,
            vertical: isTablet ? 24 : 16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: EdgeInsets.all(isTablet ? 24 : 16),
                decoration: BoxDecoration(
                  color: theme.cardTheme.color ?? colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? Colors.grey[700]! : Color(0xFFE5E7EB),
                    width: 1.1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Text(
                        'about_app.thutha'.tr(),
                        style: textTheme.titleLarge?.copyWith(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.w800,
                          fontSize: isTablet ? 30 : 24,
                        ),
                        textAlign: TextAlign.start,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'about_app.thoutha_is_an_application'.tr() +
                          'about_app.it_provides_a_clear'.tr() +
                          'about_app.our_goal_is_to'.tr(),
                      style: textTheme.bodyMedium?.copyWith(
                        fontFamily: 'Cairo',
                        fontSize: isTablet ? 18 : 15,
                        fontWeight: FontWeight.w600,
                        height: 1.8,
                        color: isDark
                            ? Colors.white
                            : colorScheme.onSurface.withOpacity(0.78),
                      ),
                      textAlign: TextAlign.start,
                    ),
                    SizedBox(height: 14),
                    Text(
                      'about_app.version_103'.tr(),
                      style: textTheme.bodySmall?.copyWith(
                        fontFamily: 'Cairo',
                        fontSize: isTablet ? 14 : 13,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? Colors.white70
                            : colorScheme.onSurface.withOpacity(0.6),
                      ),
                      textAlign: TextAlign.start,
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
