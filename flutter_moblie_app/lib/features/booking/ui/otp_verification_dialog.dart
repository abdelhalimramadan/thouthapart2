import 'dart:async';
import 'package:flutter/material.dart';
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
      _focusNode.requestFocus();
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
        setState(() {
          _resendCountdown--;
        });
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
          
          // Clear the input on error
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
          
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('تم إعادة إرسال رمز التحقق'),
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
    final theme = Theme.of(context);

    // Pin Theme
    final defaultPinTheme = PinTheme(
      width: 56,
      height: 60,
      textStyle: TextStyle(
        fontSize: 22,
        color: const Color(0xFF1E293B),
        fontWeight: FontWeight.w600,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.transparent),
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration!.copyWith(
        border: Border.all(color: const Color(0xFF0B8FAC), width: 2),
        color: const Color(0xFFFFFFFF),
      ),
    );

    final errorPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration!.copyWith(
        border: Border.all(color: Colors.redAccent, width: 2),
        color: const Color(0xFFFEF2F2),
      ),
    );

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.all(20),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header Icon
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFFE0F2FE),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.mark_email_read_outlined,
                size: 32,
                color: const Color(0xFF0B8FAC)
              ),
            ),
            const SizedBox(height: 24),
            Text(
              widget.isEmail ? "تأكيد البريد الإلكتروني" : "تأكيد رقم الهاتف",
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "أدخل رمز التحقق المرسل إلى\n${widget.contactInfo}",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 14,
                color: const Color(0xFF64748B),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),

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
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  _error!,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    color: Colors.redAccent,
                    fontSize: 14,
                  ),
                ),
              ),

            const SizedBox(height: 32),
            _isLoading
              ? SizedBox(
                  height: 48,
                  width: 48,
                  child: Center(
                    child: CircularProgressIndicator(color: const Color(0xFF0B8FAC)),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _resendCountdown > 0
                          ? "إعادة الإرسال بعد ${_resendCountdown} ثانية"
                          : "لم يصلك الرمز؟",
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 14,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    if (_resendCountdown == 0)
                      _isResending
                          ? Padding(
                              padding: EdgeInsets.only(right: 8),
                              child: SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: const Color(0xFF0B8FAC),
                                ),
                              ),
                            )
                          : TextButton(
                              onPressed: _resendOtp,
                              child: Text(
                                "إعادة الإرسال",
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF0B8FAC),
                                ),
                              ),
                            ),
                  ],
                ),
          ],
        ),
      ),
    );
  }
}

