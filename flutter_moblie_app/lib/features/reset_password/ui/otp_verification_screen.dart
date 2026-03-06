import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/routing/routes.dart';
import '../../../core/theming/colors.dart';
import '../../../core/theming/styles.dart';
import '../../../core/widgets/app_text_button.dart';
import '../../forgot_password/data/forgot_password_service.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String phone;
  final int expiresInSeconds;

  const OtpVerificationScreen({
    super.key,
    required this.phone,
    this.expiresInSeconds = 300,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final List<TextEditingController> _otpControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  final _formKey = GlobalKey<FormState>();

  bool    _isVerifying  = false;
  bool    _isResending  = false;
  String? _errorMessage;
  late int _secondsLeft;
  Timer?  _timer;

  @override
  void initState() {
    super.initState();
    _secondsLeft = widget.expiresInSeconds;
    _startTimer();
    // Auto-focus first cell
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNodes[0].requestFocus();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _otpControllers) c.dispose();
    for (final f in _focusNodes) f.dispose();
    super.dispose();
  }

  // ── Timer ───────────────────────────────────────────────────────────────
  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      if (_secondsLeft <= 0) { t.cancel(); return; }
      setState(() => _secondsLeft--);
    });
  }

  String get _timerLabel {
    final m = _secondsLeft ~/ 60;
    final s = _secondsLeft % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  bool get _canResend => _secondsLeft <= 0;

  // ── OTP input helpers ───────────────────────────────────────────────────
  void _onOtpDigit(String value, int index) {
    if (value.length == 1 && index < 5) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  String get _otpValue =>
      _otpControllers.map((c) => c.text).join('');

  void _clearOtp() {
    for (final c in _otpControllers) c.clear();
    _focusNodes[0].requestFocus();
  }

  // ── Verify ──────────────────────────────────────────────────────────────
  Future<void> _verify() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() { _isVerifying = true; _errorMessage = null; });

    try {
      final result = await PasswordResetService.instance.verifyOtp(
        phone: widget.phone,
        otp: _otpValue,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        Navigator.pushReplacementNamed(
          context,
          Routes.resetPasswordScreen,
          arguments: {'phone': widget.phone},
        );
      } else {
        _clearOtp();
        setState(() => _errorMessage = result['message'] ?? 'رمز التحقق غير صحيح');
      }
    } catch (_) {
      if (mounted) setState(() => _errorMessage = 'حدث خطأ، أعد المحاولة');
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  // ── Resend ──────────────────────────────────────────────────────────────
  Future<void> _resend() async {
    if (!_canResend) return;

    setState(() { _isResending = true; _errorMessage = null; });

    try {
      final result = await PasswordResetService.instance.requestReset(widget.phone);
      if (!mounted) return;

      if (result['success'] == true) {
        _clearOtp();
        setState(() {
          _secondsLeft = result['expires_in'] ?? 300;
        });
        _startTimer();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ تم إعادة إرسال رمز التحقق', style: TextStyle(fontFamily: 'Cairo')),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        setState(() => _errorMessage = result['message'] ?? 'فشل إعادة إرسال الرمز');
      }
    } catch (_) {
      if (mounted) setState(() => _errorMessage = 'حدث خطأ في إعادة الإرسال');
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final fs    = width * 0.04;

    return Scaffold(
      appBar: AppBar(
        title: Text('تأكيد رمز التحقق', style: TextStyle(fontFamily: 'Cairo', fontSize: fs * 1.1)),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Background gradients
          _gradient(const Alignment(-0.7, -0.7), ColorsManager.layerBlur1),
          _gradient(const Alignment(0.7, 0.7),   ColorsManager.layerBlur2),

          Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(width * 0.06),
                child: Container(
                  constraints: BoxConstraints(maxWidth: width >= 600 ? 500 : double.infinity),
                  padding: EdgeInsets.all(width * 0.06),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: Directionality(
                    textDirection: TextDirection.rtl,
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(height: 8),

                          // Icon
                          Container(
                            width: 72, height: 72,
                            decoration: BoxDecoration(
                              color: ColorsManager.mainBlue.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.chat_bubble_outline_rounded, size: 36, color: ColorsManager.mainBlue),
                          ),
                          const SizedBox(height: 16),

                          // Title
                          Text(
                            'أدخل رمز التحقق',
                            style: TextStyles.font24BlueBold.copyWith(fontFamily: 'Cairo', fontSize: fs * 1.5),
                          ),
                          const SizedBox(height: 8),

                          // Subtitle
                          RichText(
                            textAlign: TextAlign.center,
                            text: TextSpan(
                              style: TextStyle(fontFamily: 'Cairo', fontSize: fs * 0.85, color: Colors.grey[600]),
                              children: [
                                const TextSpan(text: 'تم إرسال رمز مكوّن من 6 أرقام عبر الواتساب إلى\n'),
                                TextSpan(
                                  text: widget.phone,
                                  style: TextStyle(fontWeight: FontWeight.bold, color: ColorsManager.mainBlue, fontSize: fs * 0.9),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // OTP cells
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: List.generate(6, (i) => _OtpCell(
                              controller: _otpControllers[i],
                              focusNode: _focusNodes[i],
                              width: width,
                              onChanged: (v) => _onOtpDigit(v, i),
                            )),
                          ),

                          // Error
                          if (_errorMessage != null) ...[
                            const SizedBox(height: 14),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.red.shade200),
                              ),
                              child: Row(children: [
                                Icon(Icons.error_outline, color: Colors.red.shade600, size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(_errorMessage!,
                                      style: TextStyle(color: Colors.red.shade700, fontFamily: 'Cairo', fontSize: fs * 0.8)),
                                ),
                              ]),
                            ),
                          ],

                          const SizedBox(height: 24),

                          // Verify button
                          SizedBox(
                            width: double.infinity,
                            child: AppTextButton(
                              buttonText: _isVerifying ? 'جاري التحقق...' : 'تحقق',
                              textStyle: TextStyles.font16WhiteSemiBold.copyWith(fontFamily: 'Cairo'),
                              onPressed: _isVerifying ? null : _verify,
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Timer + Resend
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (!_canResend) ...[
                                Text('انتهاء الرمز خلال ', style: TextStyle(fontFamily: 'Cairo', color: Colors.grey[600], fontSize: fs * 0.8)),
                                Text(_timerLabel, style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: ColorsManager.mainBlue, fontSize: fs * 0.85)),
                              ] else ...[
                                Text('لم تستلم الرمز؟ ', style: TextStyle(fontFamily: 'Cairo', color: Colors.grey[600])),
                                _isResending
                                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                                    : TextButton(
                                        onPressed: _resend,
                                        child: Text('إعادة إرسال', style: TextStyles.font13BlueSemiBold.copyWith(fontFamily: 'Cairo')),
                                      ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Loading overlay
          if (_isVerifying)
            Container(
              color: Colors.black.withValues(alpha: 0.4),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _gradient(Alignment center, Color color) => Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: center, radius: 1.5,
            colors: [color.withValues(alpha: 0.5), color.withValues(alpha: 0.1), Colors.transparent],
          ),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Single OTP digit cell
// ─────────────────────────────────────────────────────────────────────────────
class _OtpCell extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final double width;
  final ValueChanged<String> onChanged;

  const _OtpCell({
    required this.controller,
    required this.focusNode,
    required this.width,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: (width * 0.11).clamp(36.0, 56.0),
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        decoration: InputDecoration(
          counterText: '',
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: ColorsManager.mainBlue, width: 2),
          ),
        ),
        onChanged: onChanged,
        validator: (v) => (v == null || v.isEmpty) ? '' : null,
      ),
    );
  }
}
