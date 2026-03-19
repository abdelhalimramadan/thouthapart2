import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/routing/routes.dart';
import '../../../core/theming/colors.dart';
import '../../../core/widgets/app_text_button.dart';
import '../data/forgot_password_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneCtrl = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    super.dispose();
  }

  // ── Validation ──────────────────────────────────────────────────────────
  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) return 'الرجاء إدخال رقم الهاتف';
    final digits = value.trim().replaceAll(RegExp(r'[^\d]'), '');
    if (digits.length < 10 || digits.length > 13) return 'رقم الهاتف غير صالح';
    return null;
  }

  // ── Action ──────────────────────────────────────────────────────────────
  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await PasswordResetService.instance
          .requestReset(_phoneCtrl.text.trim());

      if (!mounted) return;

      if (result['success'] == true) {
        Navigator.pushNamed(
          context,
          Routes.otpVerificationScreen,
          arguments: {
            'phone': result['phone'], // normalised +2xxx
            'expires_in': result['expires_in'] ?? 300,
          },
        );
      } else {
        setState(() => _errorMessage = result['message'] ?? 'حدث خطأ');
      }
    } catch (_) {
      if (mounted) setState(() => _errorMessage = 'حدث خطأ غير متوقع');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    final fs = width * 0.04;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      body: Stack(
        children: [
          // Background gradients (unchanged from original design)
          _gradient(const Alignment(-0.7, -0.7), ColorsManager.layerBlur1),
          _gradient(const Alignment(0.7, 0.7), ColorsManager.layerBlur2),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: width * 0.06,
                    vertical: height * 0.03,
                  ),
                  child: Container(
                    width: double.infinity,
                    constraints: BoxConstraints(
                        maxWidth: width >= 600 ? 500 : double.infinity),
                    padding: EdgeInsets.all(width * 0.06),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF2D2D2D) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                            color: isDark
                                ? Colors.black.withAlpha(50)
                                : Colors.black.withAlpha(25),
                            blurRadius: 10,
                            offset: const Offset(0, 4))
                      ],
                    ),
                    child: Directionality(
                      textDirection: TextDirection.rtl,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(height: height * 0.01),

                          // Logo
                          Image.asset(
                            'assets/images/splash-logo.png',
                            width: width * 0.2,
                            height: width * 0.2,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(height: 8),

                          // Title
                          Text(
                            'نسيت كلمة المرور',
                            style: TextStyle(
                              fontSize: fs * 1.5,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? Colors.white
                                  : ColorsManager.mainBlue,
                              fontFamily: 'Cairo',
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Subtitle
                          Text(
                            'سنرسل لك رمز تحقق على الواتساب',
                            style: TextStyle(
                                fontSize: fs * 0.875,
                                color: isDark ? Colors.grey[400] : Colors.grey,
                                fontFamily: 'Cairo'),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: height * 0.03),

                          // Form
                          Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Phone field
                                TextFormField(
                                  controller: _phoneCtrl,
                                  keyboardType: TextInputType.phone,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                        RegExp(r'[\d+]'))
                                  ],
                                  textDirection: TextDirection.ltr,
                                  style: TextStyle(
                                    fontFamily: 'Cairo',
                                    letterSpacing: 1.2,
                                    color: isDark ? Colors.white : Colors.black,
                                  ),
                                  decoration: InputDecoration(
                                    labelText: 'رقم الهاتف',
                                    hintText: '01xxxxxxxxx',
                                    prefixIcon: Icon(
                                        Icons.phone_android_outlined,
                                        color:
                                            isDark ? Colors.grey[400] : null),
                                    labelStyle: TextStyle(
                                      fontFamily: 'Cairo',
                                      color: isDark ? Colors.grey[400] : null,
                                    ),
                                    hintStyle: TextStyle(
                                        color: Colors.grey[400],
                                        fontFamily: 'Cairo'),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: isDark
                                            ? Colors.grey[700]!
                                            : Colors.grey[300]!,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: isDark
                                            ? Colors.grey[700]!
                                            : Colors.grey[300]!,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                          color: ColorsManager.mainBlue,
                                          width: 2),
                                    ),
                                  ),
                                  validator: _validatePhone,
                                ),

                                // Error message
                                if (_errorMessage != null) ...[
                                  SizedBox(height: height * 0.015),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                          color: Colors.red.shade200),
                                    ),
                                    child: Row(children: [
                                      Icon(Icons.error_outline,
                                          color: Colors.red.shade600, size: 18),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          _errorMessage!,
                                          style: TextStyle(
                                              color: Colors.red.shade700,
                                              fontFamily: 'Cairo',
                                              fontSize: fs * 0.8),
                                        ),
                                      ),
                                    ]),
                                  ),
                                ],

                                SizedBox(height: height * 0.03),

                                // Send button
                                SizedBox(
                                  height: 52,
                                  width: double.infinity,
                                  child: _isLoading
                                      ? const Center(
                                          child: CircularProgressIndicator())
                                      : AppTextButton(
                                          buttonText: 'إرسال رمز التحقق',
                                          textStyle: const TextStyle(
                                            fontSize: 16,
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontFamily: 'Cairo',
                                          ),
                                          onPressed: _sendOtp,
                                        ),
                                ),

                                // Back to login
                                const SizedBox(height: 12),
                                Center(
                                  child: TextButton(
                                    onPressed: () {
                                      Navigator.of(context)
                                          .pushNamedAndRemoveUntil(
                                        Routes.loginScreen,
                                        (route) => false,
                                      );
                                    },
                                    child: Text(
                                      'العودة لتسجيل الدخول',
                                      style: TextStyle(
                                        fontSize: fs * 0.8,
                                        color: ColorsManager.mainBlue,
                                        fontWeight: FontWeight.w500,
                                        fontFamily: 'Cairo',
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _gradient(Alignment center, Color color) => Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: center,
            radius: 1.5,
            colors: [
              color.withAlpha(102),
              color.withAlpha(25),
              Colors.transparent
            ],
            stops: const [0.0, 0.3, 0.8],
          ),
        ),
      );
}
