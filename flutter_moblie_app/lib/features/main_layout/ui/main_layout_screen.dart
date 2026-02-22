import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/routing/routes.dart';
import '../../../features/chat/ui/chat_screen.dart';
import '../../home_screen/ui/home_screen.dart';

class MainLayoutScreen extends StatefulWidget {
  final int initialIndex;

  const MainLayoutScreen({super.key, this.initialIndex = 0});

  @override
  State<MainLayoutScreen> createState() => _MainLayoutScreenState();
}

class _MainLayoutScreenState extends State<MainLayoutScreen> {
  late int _currentIndex;
  late final List<Widget> _screens;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
    _screens = [
      const HomeScreen(),
      const ChatScreen(),
    ];
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (index == 2) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        Routes.loginScreen,
        (route) => false,
      );
    } else {
      setState(() {
        _currentIndex = index;
        _pageController.jumpToPage(index);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
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
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: isDark ? 0.4 : 0.12),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Flexible(
              child: _buildNavItem(
                icon: Icons.home_sharp,
                activeIcon: Icons.home_sharp,
                label: 'الصفحة الرئيسية',
                isActive: _currentIndex == 0,
                onTap: () => _onItemTapped(0),
                width: width,
              ),
            ),
            Flexible(
              child: _buildSvgNavItem(
                iconPath: 'assets/svg/ثوثه الدكتور 1.svg',
                label: 'ثوثة المساعد',
                isActive: _currentIndex == 1,
                onTap: () => _onItemTapped(1),
                width: width,
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: _buildNavItem(
                icon : Icons.person,
                activeIcon: Icons.person,
                label: 'الملف',
                isActive: _currentIndex == 2,
                onTap: () => _onItemTapped(2),
                width: width,
              ),
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
    final baseFontSize = width * 0.04;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        splashColor: Theme.of(context)
            .colorScheme
            .onSurface
            .withValues(alpha: Theme.of(context).brightness == Brightness.dark ? 0.2 : 0.12),
        highlightColor: Theme.of(context)
            .colorScheme
            .onSurface
            .withValues(alpha: Theme.of(context).brightness == Brightness.dark ? 0.15 : 0.1),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: const BoxDecoration(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isActive && activeIcon != null ? activeIcon : icon,
                color: isActive
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
                size: 24 * (width / 390),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontFamily: 'Cairo',
                      color: isActive
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: baseFontSize * 0.6875, // 11
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSvgNavItem({
    required String iconPath,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
    required double width,
  }) {
    final baseFontSize = width * 0.04;
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            iconPath,
            width: 24 * (width / 390),
            height: 24 * (width / 390),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontFamily: 'Cairo',
                  color: isActive
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: baseFontSize * 0.75, // 12
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                ),
          ),
        ],
      ),
    );
  }
}
