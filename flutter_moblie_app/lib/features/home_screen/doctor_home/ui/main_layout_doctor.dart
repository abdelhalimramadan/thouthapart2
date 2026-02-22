import 'package:flutter/material.dart';

import 'package:thotha_mobile_app/features/home_screen/doctor_home/doctor_next_booking_screen.dart';
import 'package:thotha_mobile_app/features/home_screen/doctor_home/ui/doctor_booking_records_screen.dart';


import 'doctor_home_screen.dart';

class MainLayoutDoctor extends StatefulWidget {
  final int initialIndex;

  const MainLayoutDoctor({super.key, this.initialIndex = 0});

  @override
  State<MainLayoutDoctor> createState() => _MainLayoutDoctorState();
}

class _MainLayoutDoctorState extends State<MainLayoutDoctor> {
  late int _currentIndex;
  late final List<Widget> _screens;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
    _screens = [
      const DoctorHomeScreen(),
      DoctorNextBookingScreen(),
      DoctorBookingRecordsScreen(),
    ];
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
      _pageController.jumpToPage(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: _screens,
      ),
      bottomNavigationBar: Container(
        height: 75 * (height / 812).clamp(0.8, 1.2),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withAlpha(isDark ? (0.4 * 255).round() : (0.12 * 255).round()),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          children: [
            _buildNavItem(
              icon: Icons.calendar_today,
              label: 'الحجوزات',
              isActive: _currentIndex == 1,
              onTap: () => _onItemTapped(1),
              width: width,
            ),
            SizedBox(width: 24 * (width / 390)),
            _buildNavItem(
              icon: Icons.list_alt_rounded,
              label: 'السجل',
              isActive: _currentIndex == 2,
              onTap: () => _onItemTapped(2),
              width: width,
            ),
            SizedBox(width: 24 * (width / 390)),
            _buildNavItem(
              icon: Icons.home_sharp,
              label: 'الرئيسية',
              isActive: _currentIndex == 0,
              onTap: () => _onItemTapped(0),
              width: width,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
    required double width,
    IconData? activeIcon,
  }) {
    final double iconSize = 25 * (width / 390);
    final baseFontSize = width * 0.04;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            transform: Matrix4.translationValues(0, isActive ? -5 : 0, 0),
            padding: EdgeInsets.symmetric(horizontal: 12 * (width / 390), vertical: isActive ? 8 : 5),
            decoration: BoxDecoration(
              color: isActive ? Theme.of(context).colorScheme.primary.withAlpha((0.08 * 255).round()) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: Theme.of(context).colorScheme.primary.withAlpha((0.12 * 255).round()),
                        blurRadius: 8,
                        offset: const Offset(0, 6),
                      )
                    ]
                  : null,
            ),
            child: Icon(
              isActive && activeIcon != null ? activeIcon : icon,
              size: iconSize,
              color: isActive ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 0),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontFamily: 'Cairo',
                  color: isActive ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: baseFontSize * 0.75, // 12
                  fontWeight: isActive ? FontWeight.w400 : FontWeight.normal,
                ),
          ),
        ],
      ),
    );
  }
}