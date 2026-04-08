import 'package:thoutha_mobile_app/core/networking/api_service.dart';
import 'package:thoutha_mobile_app/core/di/dependency_injection.dart';
import 'package:thoutha_mobile_app/core/theming/colors.dart';
import 'package:thoutha_mobile_app/core/helpers/shared_pref_helper.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class BookingConfirmationScreen extends StatefulWidget {
  final String doctorName;
  final String date;
  final String time;
  final String specialty;
  final int? requestId;
  final int? doctorId;

  const BookingConfirmationScreen({
    super.key,
    required this.doctorName,
    required this.date,
    required this.time,
    this.specialty = 'طب الأسنان',
    this.requestId,
    this.doctorId,
  });

  @override
  State<BookingConfirmationScreen> createState() =>
      _BookingConfirmationScreenState();
}

class _BookingConfirmationScreenState extends State<BookingConfirmationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();

  // Appointment-related variables
  late ApiService _apiService;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _apiService = getIt<ApiService>();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      _completeBooking();
    }
  }

  void _completeBooking() async {
    if (widget.requestId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'عذراً، لا يمكن إتمام الحجز بدون تحديد حالة. يرجى المحاولة من صفحة الحالات.',
              style: TextStyle(fontFamily: 'Cairo')),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Call the API to create appointment
      final result = await _apiService.createAppointment(
        widget.requestId!,
        _firstNameController.text,
        _lastNameController.text,
        _phoneController.text,
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      if (result['success'] == true) {
        // حفظ البيانات للمرة القادمة
        await SharedPrefHelper.setData(
            'first_name', _firstNameController.text.trim());
        await SharedPrefHelper.setData(
            'last_name', _lastNameController.text.trim());
        await SharedPrefHelper.setData(
            'phone_number', _phoneController.text.trim());

        // Success - show confirmation dialog
        if (!mounted) return;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => Directionality(
            textDirection: TextDirection.rtl,
            child: AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.r)),
              titlePadding: const EdgeInsets.only(top: 20, left: 20, right: 20),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              actionsPadding:
                  const EdgeInsets.only(bottom: 16, left: 16, right: 16),
              actionsAlignment: MainAxisAlignment.center,
              title: Text(
                'تم الحجز بنجاح',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                  color: ColorsManager.mainBlue,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72.w,
                    height: 72.w,
                    decoration: BoxDecoration(
                      color: ColorsManager.mainBlue.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.check_rounded,
                        color: ColorsManager.mainBlue, size: 42.w),
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    'تم حجز موعدك بنجاح مع ${widget.doctorName}\nفي يوم ${widget.date} الساعة ${widget.time}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 14.sp,
                      color: const Color(0xFF1F2937),
                      height: 1.6,
                    ),
                  ),
                ],
              ),
              actions: [
                Center(
                  child: SizedBox(
                    width: 140.w,
                    height: 40.h,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColorsManager.mainBlue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                      ),
                      child: Text(
                        'حسناً',
                        style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 14.sp,
                            color: Colors.white,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      } else {
        // Error
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result['message'] ?? 'فشل في إنشاء الموعد',
              style: const TextStyle(fontFamily: 'Cairo'),
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'حدث خطأ: ${e.toString()}',
            style: const TextStyle(fontFamily: 'Cairo'),
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: Stack(
            children: [
              Container(
                width: double.infinity,
                height: double.infinity,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(-0.7, -0.7),
                    radius: 1.5,
                    colors: [
                      const Color(0xFF84E5F3).withValues(alpha: 0.4),
                      const Color(0xFF84E5F3).withValues(alpha: 0.1),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.3, 0.8],
                  ),
                ),
              ),
              Container(
                width: double.infinity,
                height: double.infinity,
                decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(0.7, 0.7),
                    radius: 1.5,
                    colors: [
                      ColorsManager.layerBlur2,
                      Colors.transparent,
                    ],
                    stops: [0.1, 0.8],
                  ),
                ),
              ),
              // Top Back Button
              Positioned(
                top: 40.h,
                right: 20.w,
                child: IconButton(
                  icon: Icon(
                    Icons.arrow_forward_ios,
                    color: ColorsManager.mainBlue,
                    size: 24.w,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              Center(
                child: Padding(
                  padding: EdgeInsets.all(24.w),
                  child: Container(
                    width: double.infinity,
                    constraints: BoxConstraints(
                      maxWidth: 1.sw >= 600 ? 500.w : double.infinity,
                    ),
                    padding: EdgeInsets.all(24.w),
                    decoration: BoxDecoration(
                      color: theme.cardTheme.color ?? colorScheme.surface,
                      borderRadius: BorderRadius.circular(16.r),
                      boxShadow: [
                        BoxShadow(
                          color: isDark
                              ? Colors.black.withValues(alpha: 0.3)
                              : Colors.grey.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: SingleChildScrollView(
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(
                              child: Text(
                                'تأكيد الحجز',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontFamily: 'Cairo',
                                  fontSize: 24.sp,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.primary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Card(
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'معلومات الطبيب',
                                      style:
                                          theme.textTheme.titleMedium?.copyWith(
                                        fontFamily: 'Cairo',
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    _buildInfoRow(
                                        'الطبيب:', widget.doctorName, 14.sp),
                                    const SizedBox(height: 8),
                                    _buildInfoRow(
                                        'التخصص:', widget.specialty, 14.sp),
                                    const SizedBox(height: 8),
                                    _buildInfoRow(
                                        'التاريخ:', widget.date, 14.sp),
                                    const SizedBox(height: 8),
                                    _buildInfoRow('الوقت:', widget.time, 14.sp),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'معلومات المريض',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontFamily: 'Cairo',
                                fontSize: 18.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _firstNameController,
                              style: const TextStyle(fontFamily: 'Cairo'),
                              decoration: InputDecoration(
                                labelText: 'الاسم الأول',
                                labelStyle:
                                    const TextStyle(fontFamily: 'Cairo'),
                                prefixIcon: Icon(Icons.person_outline,
                                    color: theme.iconTheme.color),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                              ),
                              textInputAction: TextInputAction.next,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'الرجاء إدخال الاسم الأول';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _lastNameController,
                              style: const TextStyle(fontFamily: 'Cairo'),
                              decoration: InputDecoration(
                                labelText: 'اسم العائلة',
                                labelStyle:
                                    const TextStyle(fontFamily: 'Cairo'),
                                prefixIcon: Icon(Icons.person_outline,
                                    color: theme.iconTheme.color),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                              ),
                              textInputAction: TextInputAction.next,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'الرجاء إدخال اسم العائلة';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _phoneController,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(fontFamily: 'Cairo'),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                    RegExp(r'[0-9\u0660-\u0669]')),
                              ],
                              decoration: InputDecoration(
                                labelText: 'رقم الجوال',
                                labelStyle:
                                    const TextStyle(fontFamily: 'Cairo'),
                                hintText: '01X XXX XXXXX',
                                hintStyle: const TextStyle(fontFamily: 'Cairo'),
                                prefixIcon: Icon(Icons.phone_android,
                                    color: theme.iconTheme.color),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'الرجاء إدخال رقم الجوال';
                                }

                                String cleanPhone =
                                    value.replaceAll(RegExp(r'[\s\-\(\)]'), '');

                                if (cleanPhone.startsWith('01')) {
                                  if (cleanPhone.length != 11) {
                                    return 'رقم الجوال المصري يجب أن يكون 11 رقم';
                                  }
                                  if (!RegExp(r'^01[0-25]\d{8}$')
                                      .hasMatch(cleanPhone)) {
                                    return 'رقم الجوال المصري غير صحيح';
                                  }
                                } else if (cleanPhone.startsWith('+20')) {
                                  if (cleanPhone.length != 13) {
                                    return 'رقم الجوال المصري يجب أن يكون 13 رقم مع +20';
                                  }
                                  if (!RegExp(r'^\+201[0-25]\d{8}$')
                                      .hasMatch(cleanPhone)) {
                                    return 'رقم الجوال المصري غير صحيح';
                                  }
                                } else {
                                  return 'الرجاء إدخال رقم جوال مصري صحيح';
                                }

                                return null;
                              },
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              height: 48,
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed:
                                    _isLoading ? null : () => _submitForm(),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: colorScheme.primary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8.r),
                                  ),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Text(
                                        'تأكيد الحجز',
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                          fontFamily: 'Cairo',
                                          fontSize: 16.sp,
                                          color: colorScheme.onPrimary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, double fontSize) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontFamily: 'Cairo',
            fontSize: fontSize,
            color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontFamily: 'Cairo',
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
