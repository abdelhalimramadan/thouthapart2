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
      'image': 'assets/images/2-inboarding.jpg',
      'title': 'احجز موعدك بسهولة',
      'description':
          'اختار الموعد المناسب لك واحجز مع طبيبك المفضل في ثواني. خدمة حجز المواعديد لدينا سهلة وسريعة وآمنة.',
    },
    {
      'image': 'assets/images/3-onboarding.jpg',
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
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;

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
                  center: Alignment(-0.7, -0.7),
                  radius: 1.5,
                  colors: [
                    ColorsManager.layerBlur1.withAlpha(102),
                    ColorsManager.layerBlur1.withAlpha(25),
                    Colors.transparent,
                  ],
                  stops: const [0.1, 0.5, 0.8],
                ),
              ),
            ),
            // Bottom-right gradient overlay
            Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0.7, 0.7),
                  radius: 1.5,
                  colors: [
                    ColorsManager.layerBlur2.withAlpha(102),
                    ColorsManager.layerBlur2.withAlpha(25),
                    Colors.transparent,
                  ],
                  stops: const [0.1, 0.5, 0.8],
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

            // Page Indicator
            Positioned(
              bottom: height * 0.15,
              left: 0,
              right: 0,
              child: PageIndicator(
                currentPage: _currentPage,
                pageCount: _numPages,
              ),
            ),

            // Action Buttons Container
            Positioned(
              bottom: height * 0.05,
              left: 0,
              right: 0,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: width * 0.08),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GetStartedButton(
                      isLastPage: _currentPage == _numPages - 1,
                      onPressed: () async {
                        if (_currentPage < _numPages - 1) {
                          await _pageController.nextPage(
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.ease,
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
                            fontSize: width * 0.04,
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
    final width = MediaQuery.of(context).size.width;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        pageCount,
        (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: EdgeInsets.symmetric(horizontal: width * 0.01),
          width: currentPage == index ? width * 0.05 : width * 0.02,
          height: width * 0.02,
          decoration: BoxDecoration(
            color: currentPage == index
                ? ColorsManager.mainBlue
                : Colors.grey.withAlpha(76),
            borderRadius: BorderRadius.circular(width * 0.01),
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
    final width = MediaQuery.of(context).size.width;
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: ColorsManager.mainBlue,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: Text(
          isLastPage ? 'ابدأ الآن' : 'التالي',
          style: TextStyle(
            color: Colors.white,
            fontSize: width * 0.04,
            fontFamily: 'Cairo',
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

