import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:thotha_mobile_app/core/theming/theme_provider.dart';
import 'package:thotha_mobile_app/features/home_screen/ui/drawer/drawer.dart';
import 'package:thotha_mobile_app/features/terms_and_conditions/ui/terms_and_conditions_screen.dart';

class HomeSettingsScreen extends StatefulWidget {
  const HomeSettingsScreen({super.key});

  @override
  State<HomeSettingsScreen> createState() => _HomeSettingsScreenState();
}

class _HomeSettingsScreenState extends State<HomeSettingsScreen> {
  // State variables for each toggle
  bool _notificationsEnabled = false;
  bool _receiveOffers = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final baseFontSize = width * 0.04;
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: theme.scaffoldBackgroundColor,
      drawer: const HomeDrawer(),
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor ?? theme.scaffoldBackgroundColor,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: SizedBox(
          width: double.infinity,
          height: 50,
          child: Stack(
            children: [
              // Menu icon on the left
              Positioned(
                left: 0,
                child: IconButton(
                  icon: const Icon(
                    Icons.menu,
                    size: 30,
                  ),
                  onPressed: () {
                    _scaffoldKey.currentState?.openDrawer();
                  },
                ),
              ),
              // Logo centered
              Center(
                child: Image.asset(
                  'assets/images/splash-logo.png',
                  width: 46 * (width / 390),
                  height: 50,
                  fit: BoxFit.contain,
                ),
              ),
            ],
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Main Settings Container
            Column(
              children: [
                // Settings Header
                Container(
                  color: Colors.transparent,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.only(right: 20, top: 20),
                  child: Text(
                    'إعدادات المستخدم',
                    style: textTheme.headlineSmall?.copyWith(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.w700,
                      fontSize: baseFontSize * 1.5, // 24
                      height: 1.5,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
                const SizedBox(height: 24),

                // Main Content Container
                Container(
                  width: width * 0.9,
                  constraints: const BoxConstraints(maxWidth: 500),
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Notifications Toggle
                      _buildToggleRow(
                        title: 'الإشعارات',
                        value: _notificationsEnabled,
                        onChanged: (v) => setState(() => _notificationsEnabled = v),
                        baseFontSize: baseFontSize,
                        theme: theme,
                      ),
                      _buildToggleRow(
                        title: 'تلقي العروض',
                        value: _receiveOffers,
                        onChanged: (v) => setState(() => _receiveOffers = v),
                        baseFontSize: baseFontSize,
                        theme: theme,
                      ),

                      // Dark Mode Toggle
                      Consumer<ThemeProvider>(
                        builder: (context, themeProvider, child) {
                          return _buildToggleRow(
                            title: 'الوضع الداكن',
                            value: themeProvider.isDarkMode,
                            onChanged: (v) => themeProvider.toggleTheme(v),
                            baseFontSize: baseFontSize,
                            theme: theme,
                          );
                        },
                      ),

                      // Terms and Conditions
                      InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const TermsAndConditionsScreen(),
                            ),
                          );
                        },
                        child: Container(
                          width: double.infinity,
                          height: 50,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Icon(
                                Icons.arrow_back_ios,
                                size: 16,
                                color: textTheme.bodyLarge?.color,
                              ),
                              const Spacer(),
                              Text(
                                'الشروط والأحكام',
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: baseFontSize, // 16
                                  fontWeight: FontWeight.bold,
                                  color: textTheme.bodyLarge?.color,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildToggleRow({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
    required double baseFontSize,
    required ThemeData theme,
  }) {
    return Container(
      width: double.infinity,
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: theme.dividerColor.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeTrackColor: const Color(0xFF8DECB8),
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: theme.dividerColor,
          ),
          Text(
            title,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: baseFontSize, // 16
              fontWeight: FontWeight.bold,
              color: theme.textTheme.bodyLarge?.color,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
