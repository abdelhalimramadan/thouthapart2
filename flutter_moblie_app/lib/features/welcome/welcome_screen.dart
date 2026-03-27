import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/routing/routes.dart';
import '../../core/theming/colors.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              Colors.cyan[100]!,
              Colors.green[100]!,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: 30.h),

                  // Main Title
                  Text(
                    'ثوثة',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 24.sp,
                      fontWeight: FontWeight.bold,
                      color: ColorsManager.mainBlue,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  SizedBox(height: 16.h),

                  // Subtitle
                  Text(
                    'برنامج الأسنان',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 36.sp,
                      fontWeight: FontWeight.bold,
                      color: ColorsManager.mainBlue,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  SizedBox(height: 12.h),

                  // Description
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: Text(
                      'الربط الذكي بين طالب الدراسات العليا والمرضى',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 14.sp,
                        color: Colors.grey[700],
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  SizedBox(height: 50.h),

                  // What does the platform offer section
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: Text(
                      'الخدمات المتاحة',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  SizedBox(height: 25.h),

                  // Service Cards
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: Column(
                      children: [
                        _buildServiceCard(
                          icon: Icons.favorite,
                          title: 'جودة عالية',
                          description:
                              'أحدث الطرق والتقنيات في علاج الأسنان تحت إشراف أطباء متخصصين',
                          isDark: isDark,
                        ),
                        SizedBox(height: 16.h),
                        _buildServiceCard(
                          icon: Icons.price_check,
                          title: 'أسعار مناسبة',
                          description:
                              'أسعار خاصة للمرضى مع إمكانية العلاج بالمجان في بعض الحالات',
                          isDark: isDark,
                        ),
                        SizedBox(height: 16.h),
                        _buildServiceCard(
                          icon: Icons.school,
                          title: 'متدربين محترفين',
                          description:
                              'طلاب دراسات عليا تحت إشراف مباشر من أطباء أسنان متخصصين',
                          isDark: isDark,
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 30.h),

                  // Mission Section
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: Container(
                      padding: EdgeInsets.all(20.r),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border(
                          right: BorderSide(
                            color: ColorsManager.mainBlue,
                            width: 5.w,
                          ),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'رسالتنا',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          SizedBox(height: 12.h),
                          Text(
                            'توفير خدمات طب أسنان عالية الجودة بأسعار في متناول الجميع، مع توفير فرص تدريبية قيمة لطلاب الدراسات العليا تحت إشراف أطباء متخصصين.',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 13.sp,
                              color: Colors.grey[700],
                              height: 1.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 30.h),

                  // Partnership text
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: Text(
                      'انضم لثوثة واحصل على أفضل علاج للأسنان',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 14.sp,
                        color: ColorsManager.mainBlue,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  SizedBox(height: 25.h),

                  // Register Button
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: SizedBox(
                      width: double.infinity,
                      height: 54.h,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pushNamed(context, Routes.signUpScreen);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ColorsManager.mainBlue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                          elevation: 4,
                        ),
                        child: Text(
                          'إنشاء حساب',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 20.h),

                  // Copyright
                  Text(
                    'جميع الحقوق محفوظة © ثوثة 2026',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 12.sp,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),

                  SizedBox(height: 30.h),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildServiceCard({
    required IconData icon,
    required String title,
    required String description,
    required bool isDark,
  }) {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 8.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12.r),
            decoration: BoxDecoration(
              color: ColorsManager.mainBlue.withAlpha(30),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(
              icon,
              color: ColorsManager.mainBlue,
              size: 28.r,
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 6.h),
                Text(
                  description,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 12.sp,
                    color: Colors.grey[700],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
