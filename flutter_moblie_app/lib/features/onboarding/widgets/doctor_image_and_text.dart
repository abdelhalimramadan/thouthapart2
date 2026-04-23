import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theming/colors.dart';

class DoctorImageAndText extends StatelessWidget {
  final String imagePath;
  final String title;
  final String description;

  const DoctorImageAndText({
    super.key,
    required this.imagePath,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxWidth = constraints.maxWidth;
        final double maxHeight = constraints.maxHeight;
        final bool isTablet = maxWidth >= 600;
        final bool isShortScreen = maxHeight < 400; // Case where keyboard or small phone limits height

        // Dynamic Image Sizing:
        // On small phones, we aggressively shrink the image to ensure text is visible.
        final double imageSize = isTablet
            ? (maxWidth * 0.45).clamp(280.0, 450.0)
            : isShortScreen 
                ? (maxHeight * 0.4) 
                : (maxWidth * 0.75).clamp(200.0, 320.0);

        return Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isTablet ? 60.w : 24.w,
                vertical: 12.h,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Image container
                  Container(
                    width: imageSize,
                    height: imageSize,
                    margin: EdgeInsets.only(bottom: isShortScreen ? 12.h : 24.h),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: ColorsManager.mainBlue.withAlpha(50),
                          spreadRadius: 6.r,
                          blurRadius: 15.r,
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        imagePath,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),

                  // Title
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: isTablet ? 30.sp : 24.sp,
                      fontWeight: FontWeight.bold,
                      color: ColorsManager.mainBlue,
                    ),
                  ),

                  SizedBox(height: isShortScreen ? 8.h : 16.h),

                  // Description
                  Text(
                    description,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: isTablet ? 20.sp : 16.sp,
                      color: Colors.grey[800], // High contrast for accessibility
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
