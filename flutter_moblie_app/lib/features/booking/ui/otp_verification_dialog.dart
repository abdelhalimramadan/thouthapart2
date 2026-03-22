import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pinput/pinput.dart';
import 'package:thotha_mobile_app/core/networking/otp_service.dart';

class OtpVerificationDialog extends StatefulWidget {
  final String contactInfo;
  final bool isEmail;
  final Function(String) onVerified;
  final Function(String)? onResend;

  const OtpVerificationDialog({
    Key? key,
    required this.contactInfo,
    this.isEmail = false,
    required this.onVerified,
    this.onResend,
  }) : super(key: key);

  @override
  State<OtpVerificationDialog> createState() => _OtpVerificationDialogState();
}

class _OtpVerificationDialogState extends State<OtpVerificationDialog> {
  final _otpController = TextEditingController();
  final _focusNode = FocusNode();
  final OtpService _otpService = OtpService();
  bool _isLoading = false;
  bool _isResending = false;
  String? _error;
  int _resendCountdown = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
    // Auto focus
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _startTimer() {
    _resendCountdown = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown > 0) {
        if (mounted) {
          setState(() {
            _resendCountdown--;
          });
        }
      } else {
        timer.cancel();
      }
    });
  }

  void _verifyOtp(String pin) async {
    if (pin.length != 6) {
      setState(() {
        _error = 'رمز التحقق يجب أن يكون 6 أرقام';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await _otpService.verifyOtp(widget.contactInfo, pin);

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        if (result['success']) {
          Navigator.pop(context);
          widget.onVerified(pin);
        } else {
          setState(() {
            _error = result['error'] ?? 'فشل التحقق من الرمز';
          });

          _otpController.clear();
          _focusNode.requestFocus();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'حدث خطأ غير متوقع';
        });
      }
    }
  }

  Future<void> _resendOtp() async {
    setState(() {
      _isResending = true;
      _error = null;
    });

    try {
      final result = await _otpService.sendOtp(widget.contactInfo);

      if (mounted) {
        setState(() {
          _isResending = false;
        });

        if (result['success']) {
          _startTimer();
          widget.onResend?.call(widget.contactInfo);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم إعادة إرسال رمز التحقق',
                  style: TextStyle(fontFamily: 'Cairo')),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        } else {
          setState(() {
            _error = result['error'] ?? 'فشل إعادة الإرسال';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isResending = false;
          _error = 'حدث خطأ غير متوقع';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Pin Theme
    final defaultPinTheme = PinTheme(
      width: 1.sw > 600 ? 56.w : (1.sw - 80.w) / 6,
      height: 60.h,
      textStyle: TextStyle(
        fontSize: 22.sp,
        color: isDark ? Colors.white : const Color(0xFF1E293B),
        fontWeight: FontWeight.w600,
      ),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: Colors.transparent),
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration!.copyWith(
        border: Border.all(color: const Color(0xFF0B8FAC), width: 2.w),
        color: isDark ? Colors.black : const Color(0xFFFFFFFF),
      ),
    );

    final errorPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration!.copyWith(
        border: Border.all(color: Colors.redAccent, width: 2.w),
        color: isDark ? const Color(0xFF451A1A) : const Color(0xFFFEF2F2),
      ),
    );

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      insetPadding: EdgeInsets.all(20.r),
      child: Padding(
        padding: EdgeInsets.all(24.r),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header Icon
              Container(
                width: 72.w,
                height: 72.h,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F2FE)
                      .withValues(alpha: isDark ? 0.1 : 1.0),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.mark_email_read_outlined,
                    size: 32.r, color: const Color(0xFF0B8FAC)),
              ),
              SizedBox(height: 24.h),
              Text(
                widget.isEmail ? "تأكيد البريد الإلكتروني" : "تأكيد رقم الهاتف",
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                "أدخل رمز التحقق المرسل إلى\n${widget.contactInfo}",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 14.sp,
                  color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                  height: 1.5,
                ),
              ),
              SizedBox(height: 32.h),

              Directionality(
                textDirection: TextDirection.ltr,
                child: Pinput(
                  length: 6,
                  controller: _otpController,
                  focusNode: _focusNode,
                  defaultPinTheme: defaultPinTheme,
                  focusedPinTheme: focusedPinTheme,
                  errorPinTheme: errorPinTheme,
                  forceErrorState: _error != null,
                  onCompleted: _verifyOtp,
                  pinputAutovalidateMode: PinputAutovalidateMode.onSubmit,
                  validator: (pin) {
                    if (pin == null || pin.isEmpty) {
                      return 'مطلوب';
                    }
                    if (pin.length != 6) {
                      return '6 أرقام';
                    }
                    return null;
                  },
                ),
              ),

              if (_error != null)
                Padding(
                  padding: EdgeInsets.only(top: 16.h),
                  child: Text(
                    _error!,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      color: Colors.redAccent,
                      fontSize: 14.sp,
                    ),
                  ),
                ),

              SizedBox(height: 32.h),
              _isLoading
                  ? SizedBox(
                      height: 48.h,
                      width: 48.w,
                      child: const Center(
                        child: CircularProgressIndicator(
                            color: Color(0xFF0B8FAC)),
                      ),
                    )
                  : Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _resendCountdown > 0
                                  ? "إعادة الإرسال بعد ${_resendCountdown} ثانية"
                                  : "لم يصلك الرمز؟",
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 14.sp,
                                color: isDark
                                    ? Colors.grey[400]
                                    : const Color(0xFF64748B),
                              ),
                            ),
                            if (_resendCountdown == 0)
                              _isResending
                                  ? Padding(
                                      padding: EdgeInsets.only(right: 8.w),
                                      child: SizedBox(
                                        width: 16.w,
                                        height: 16.h,
                                        child: const CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Color(0xFF0B8FAC),
                                        ),
                                      ),
                                    )
                                  : TextButton(
                                      onPressed: _resendOtp,
                                      child: const Text(
                                        "إعادة الإرسال",
                                        style: TextStyle(
                                          fontFamily: 'Cairo',
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF0B8FAC),
                                        ),
                                      ),
                                    ),
                          ],
                        ),
                        SizedBox(height: 16.h),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            "إلغاء",
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 14.sp,
                              color:
                                  isDark ? Colors.grey[500] : Colors.grey[600],
                            ),
                          ),
                        ),
                      ],
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
