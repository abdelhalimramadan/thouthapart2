import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:thotha_mobile_app/core/theming/theme_provider.dart';
import 'package:thotha_mobile_app/features/home_screen/doctor_home/drawer/doctor_drawer_screen.dart';
import 'package:thotha_mobile_app/features/home_screen/ui/drawer/drawer.dart';

class SettingsScreen extends StatefulWidget {
  /// If true, the screen will show the Doctor drawer when opening the menu.
  final bool useDoctorDrawer;

  const SettingsScreen({super.key, this.useDoctorDrawer = false});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // State variables for each toggle
  bool _notificationsEnabled = false;
  bool _receiveOffers = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final baseFontSize = width * 0.04;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
        key: _scaffoldKey,
        backgroundColor: theme.scaffoldBackgroundColor,
        // Show the drawer based on where Settings was opened from
        drawer: widget.useDoctorDrawer
            ? const DoctorDrawer()
            : const HomeDrawer(),
        appBar: AppBar(
          backgroundColor: theme.colorScheme.surface,
          elevation: 0,
          automaticallyImplyLeading: false,
          toolbarHeight: 75.6,
          title: Container(
            width: double.infinity,
            height: 50 * (width / 390),
            child: Stack(
              children: [
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: IconButton(
                      icon: Icon(
                        Icons.menu,
                        color: theme.iconTheme.color,
                        size: 30 * (width / 390),
                      ),
                      onPressed: () {
                        _scaffoldKey.currentState?.openDrawer();
                      },
                    ),
                  ),
                ),
                Center(
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
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1.1),
            child: Container(
              height: 1.1,
              color: isDark ? Colors.grey[700]! : const Color(0xFFE5E7EB),
            ),
          ),
        ),
        body: SingleChildScrollView(
          child: Column(children: [
          const SizedBox(height: 20),
          Column(
            children: [
              Container(
                width: double.infinity,
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'الإعدادات',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w700,
                    fontSize: baseFontSize * 1.75, // 28
                    height: 1.5,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                width: width * 0.95,
                decoration: BoxDecoration(
                  color: theme.cardTheme.color ?? colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isDark ? Colors.grey[700]! : const Color(0xFFE5E7EB)),
                ),
                child: Column(
                  children: [
                    // Notifications Toggle
                    _buildToggleRow(
                      context,
                      'الإشعارات',
                      _notificationsEnabled,
                      (val) => setState(() => _notificationsEnabled = val),
                    ),

                    // Receive Offers Toggle
                    _buildToggleRow(
                      context,
                      'تلقي العروض',
                      _receiveOffers,
                      (val) => setState(() => _receiveOffers = val),
                    ),

                    // Dark Mode Toggle
                    Consumer<ThemeProvider>(
                      builder: (context, themeProvider, child) {
                        return _buildToggleRow(
                          context,
                          'الوضع الداكن',
                          themeProvider.isDarkMode,
                          (val) => themeProvider.toggleTheme(val),
                        );
                      },
                    ),
                    const SizedBox(height: 14),
                  ],
                ),
              ),
            ],
          )
        ])));
  }

  Widget _buildToggleRow(BuildContext context, String title, bool value, Function(bool) onChanged) {
    final theme = Theme.of(context);
    final width = MediaQuery.of(context).size.width;
    final baseFontSize = width * 0.04;

    return Container(
      width: double.infinity,
      height: 49.0 * (width / 390),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: theme.brightness == Brightness.dark ? Colors.grey[700]! : const Color(0xFFE5E7EB),
            width: 1.1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Transform.scale(
            scale: 0.8 * (width / 390).clamp(0.8, 1.2),
            child: Switch.adaptive(
              value: value,
              onChanged: onChanged,
              activeColor: const Color(0xFF8DECB8),
              inactiveTrackColor: const Color(0xFFE5E7EB),
            ),
          ),
          Text(
            title,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontFamily: 'Cairo',
              fontSize: baseFontSize, // 16
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
