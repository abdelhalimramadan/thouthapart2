import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:thotha_mobile_app/features/onboarding/widgets/doctor_image_and_text.dart';
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

  // List of onboarding pages data
  final List<Map<String, String>> _pages = [
    {
      'image': 'assets/images/1-onboarding.jpg',
      'title': 'اعثر على أفضل الأطباء',
      'description':
          'في ثوثة جمعنا أفضل طلاب وأطباء الأسنان عشان نقدم لك رعاية حقيقية بأسعار طلابية. ابتسامتك في أيد أمينة، مع نخبة من أمهر الأطباء الشباب.',
    },
    {
      'image': 'assets/images/on boarding 2.jpg',
      'title': 'احجز موعدك بسهولة',
      'description':
          'اختار الموعد المناسب لك واحجز مع طبيبك المفضل في ثواني. خدمة حجز المواعديد لدينا سهلة وسريعة وآمنة.',
    },
    {
      'image': 'assets/images/onbourding3.jpg',
      'title': 'متابعة دقيقة لصحة أسنانك',
      'description':
          'احصل على سجل كامل لعلاجاتك ومواعيدك القادمة. نحن نهتم بابتسامتك من أول زيارة.',
    },
  ];

  void _onSkipPressed() {
    Navigator.pushNamedAndRemoveUntil(
      context,
      Routes.categoriesScreen,
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
        child: Stack(
          children: [
            // Full screen gradient overlay
            Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(-0.8, -0.5),
                  radius: 1.2,
                  colors: [
                    ColorsManager.layerBlur1.withAlpha(80),
                    ColorsManager.layerBlur1.withAlpha(30),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.4, 1.0],
                ),
              ),
            ),
            // Bottom-right gradient overlay
            Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0.8, 0.5),
                  radius: 1.2,
                  colors: [
                    ColorsManager.layerBlur2.withAlpha(80),
                    ColorsManager.layerBlur2.withAlpha(30),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.4, 1.0],
                ),
              ),
            ),

            PageView.builder(
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


            // Action Buttons Container
            Positioned(
              bottom: 40.h,
              left: 0,
              right: 0,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 32.w),
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
                          if (mounted) {
                            _onSkipPressed();
                          }
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
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
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
          width: currentPage == index ? 20.w : 8.w,
          height: 8.h,
          decoration: BoxDecoration(
            color: currentPage == index
                ? ColorsManager.mainBlue
                : Colors.grey.withAlpha(76),
            borderRadius: BorderRadius.circular(4.r),
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
      height: 52.h,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: ColorsManager.mainBlue,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          elevation: 0,
        ),
        child: Text(
          isLastPage ? 'ابدأ الآن' : 'التالي',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16.sp,
            fontFamily: 'Cairo',
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
