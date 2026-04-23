import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:thoutha_mobile_app/features/onboarding/widgets/doctor_image_and_text.dart';
import 'package:flutter/material.dart';

import '../../core/routing/routes.dart';
import '../../core/theming/colors.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final int _numPages = 3;

  final List<Map<String, String>> _pages = [
    {
      'image': 'assets/images/onboarding1.jpg',
      'title': 'اعثر على أفضل الأطباء',
      'description':
          'في ثوثة جمعنا أفضل طلاب وأطباء الأسنان عشان نقدم لك رعاية حقيقية بأسعار طلابية. ابتسامتك في أيد أمينة، مع نخبة من أمهر الأطباء الشباب.',
    },
    {
      'image': 'assets/images/onboarding2.jpg',
      'title': 'احجز موعدك بسهولة',
      'description':
          'اختار الموعد المناسب لك واحجز مع طبيبك المفضل في ثواني. خدمة حجز المواعديد لدينا سهلة وسريعة وآمنة.',
    },
    {
      'image': 'assets/images/onboarding3.jpg',
      'title': 'متابعة دقيقة لصحة أسنانك',
      'description':
          'احصل على سجل كامل لعلاجاتك ومواعيدك القادمة. نحن نهتم بابتسامتك من أول زيارة.',
    },
  ];

  void _onSkipPressed() {
    Navigator.pushNamedAndRemoveUntil(
      context,
      Routes.welcomeScreen,
      (route) => false,
    );
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentPage = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isTablet = constraints.maxWidth >= 600;
            final isSmallPhone = constraints.maxHeight < 700;

            return Stack(
              children: [
                // 1. Background Gradients (Kept in Stack for z-index)
                _buildBackgroundGradients(),

                // 2. Main Content (Structural Column to avoid overlaps)
                Column(
                  children: [
                    // Top Skip Button (Optional, if we want one)
                    // ... or just leave the bottom skip

                    // Sliding Content
                    Expanded(
                      flex: isSmallPhone ? 4 : 5,
                      child: PageView.builder(
                        controller: _pageController,
                        onPageChanged: _onPageChanged,
                        itemCount: _pages.length,
                        itemBuilder: (context, index) {
                          return DoctorImageAndText(
                            imagePath: _pages[index]['image']!,
                            title: _pages[index]['title']!,
                            description: _pages[index]['description']!,
                            key: ValueKey('onboarding_$index'),
                          );
                        },
                      ),
                    ),

                    // Page Indicators
                    PageIndicator(
                      currentPage: _currentPage,
                      pageCount: _pages.length,
                    ),

                    SizedBox(height: isSmallPhone ? 20.h : 30.h),

                    // Action Buttons (CTA)
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isTablet ? 120.w : 32.w,
                        vertical: 16.h,
                      ),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: 520, // Strict px for tablet spread control
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GetStartedButton(
                              isLastPage: _currentPage == _numPages - 1,
                              onPressed: () async {
                                if (_currentPage < _numPages - 1) {
                                  await _pageController.nextPage(
                                    duration: const Duration(milliseconds: 400),
                                    curve: Curves.easeInOut,
                                  );
                                } else {
                                  if (mounted) _onSkipPressed();
                                }
                              },
                            ),
                            if (_currentPage < _numPages - 1)
                              TextButton(
                                onPressed: _onSkipPressed,
                                child: Text(
                                  'ندخل في الموضوع علي طول',
                                  style: TextStyle(
                                    color: ColorsManager.darkBlue,
                                    fontSize: 16.sp,
                                    fontFamily: 'Cairo',
                                    fontWeight: FontWeight.bold,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: isSmallPhone ? 10.h : 24.h),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildBackgroundGradients() {
    return Stack(
      children: [
        Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(-0.8, -0.6),
              radius: 1.4,
              colors: [
                ColorsManager.mainBlue.withAlpha(140),
                ColorsManager.mainBlue.withAlpha(40),
                Colors.transparent,
              ],
              stops: const [0.0, 0.45, 1.0],
            ),
          ),
        ),
        Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0.9, 0.6),
              radius: 1.4,
              colors: [
                ColorsManager.layerBlur2.withAlpha(140),
                ColorsManager.layerBlur2.withAlpha(40),
                Colors.transparent,
              ],
              stops: const [0.0, 0.45, 1.0],
            ),
          ),
        ),
      ],
    );
  }
}

class PageIndicator extends StatelessWidget {
  final int currentPage;
  final int pageCount;

  const PageIndicator({
    super.key,
    required this.currentPage,
    required this.pageCount,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        pageCount,
        (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: EdgeInsets.symmetric(horizontal: 4.w),
          width: currentPage == index ? 22.r : 10.r,
          height: 10.r,
          decoration: BoxDecoration(
            color: currentPage == index
                ? ColorsManager.mainBlue
                : Colors.grey.withAlpha(76),
            borderRadius: BorderRadius.circular(5.r),
          ),
        ),
      ),
    );
  }
}

class GetStartedButton extends StatelessWidget {
  final bool isLastPage;
  final VoidCallback onPressed;

  const GetStartedButton({
    super.key,
    required this.isLastPage,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 60.h, // Fixed professional height for better visibility
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: ColorsManager.mainBlue,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          elevation: 4,
        ),
        child: Text(
          isLastPage ? 'ابدأ الآن' : 'التالي',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18.sp,
            fontFamily: 'Cairo',
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
