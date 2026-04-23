import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// المسافات الرأسية: متخليهاش تزيد عن الحجم الأصلي بمرة ونص مثلاً
SizedBox verticalSpace(double height) => SizedBox(
  height: height.h.clamp(height, height * 1.5),
);

SizedBox horizontalSpace(double width) => SizedBox(
  width: width.w.clamp(width, width * 1.5),
);
