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
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              ColorsManager.mainBlue.withAlpha((0.1 * 255).round()),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 30.h),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo/Brand
                  SizedBox(height: 40.h),
                  Container(
                    width: 120.w,
                    height: 120.w,
                    decoration: BoxDecoration(
                      color: ColorsManager.mainBlue,
                      borderRadius: BorderRadius.circular(30.r),
                    ),
                    child: Center(
                      child: Text(
                        'ثوثة',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 48.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 60.h),

                  // Coming Soon Badge
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                    decoration: BoxDecoration(
                      color: Colors.orange.withAlpha((0.2 * 255).round()),
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(
                        color: Colors.orange,
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      '🚀 Coming Soon',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange[800],
                      ),
                    ),
                  ),

                  SizedBox(height: 30.h),

                  // Main Title
                  Text(
                    'مرحباً بك في ثوثة',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 32.sp,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  SizedBox(height: 16.h),

                  // Description
                  Text(
                    'نحن نعمل على تحسين تجربتك\nقريباً سنطلق ميزات جديدة ومثيرة',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.grey[400] : Colors.grey[700],
                      height: 1.6,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  SizedBox(height: 80.h),

                  // Features Coming
                  Container(
                    padding: EdgeInsets.all(20.r),
                    decoration: BoxDecoration(
                      color: ColorsManager.mainBlue
                          .withAlpha((0.05 * 255).round()),
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(
                        color: ColorsManager.mainBlue
                            .withAlpha((0.2 * 255).round()),
                      ),
                    ),
                    child: Column(
                      children: [
                        _buildFeatureItem(
                          icon: Icons.schedule,
                          title: 'حجز المواعيد',
                          subtitle: 'احجز موعدك بسهولة',
                        ),
                        SizedBox(height: 16.h),
                        _buildFeatureItem(
                          icon: Icons.medical_services_outlined,
                          title: 'استشارات طبية',
                          subtitle: 'تواصل مع أفضل الأطباء',
                        ),
                        SizedBox(height: 16.h),
                        _buildFeatureItem(
                          icon: Icons.assignment_outlined,
                          title: 'سجل طبي',
                          subtitle: 'احتفظ بسجل صحتك',
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 60.h),

                  // Register Button
                  SizedBox(
                    width: double.infinity,
                    height: 56.h,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pushNamed(context, Routes.signUpScreen);
                      },
                      icon: const Icon(Icons.person_add_outlined),
                      label: Text(
                        'إنشاء حساب',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColorsManager.mainBlue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        elevation: 4,
                      ),
                    ),
                  ),

                  SizedBox(height: 60.h),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(12.r),
          decoration: BoxDecoration(
            color: ColorsManager.mainBlue,
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 24.r,
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
              SizedBox(height: 4.h),
              Text(
                subtitle,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 12.sp,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
