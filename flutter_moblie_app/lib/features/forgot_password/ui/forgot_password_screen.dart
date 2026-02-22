import 'package:flutter/material.dart';

import '../../../core/routing/routes.dart';
import '../../../core/theming/colors.dart';
import '../../../core/theming/styles.dart';
import '../../../core/widgets/app_text_button.dart';
import '../data/forgot_password_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await ForgotPasswordService().sendOtp(_emailController.text.trim());
      
      if (response['success'] == true) {
        if (mounted) {
          Navigator.pushNamed(
            context,
            Routes.otpVerificationScreen,
            arguments: {
              'email': _emailController.text.trim(),
            },
          );
        }
      } else {
        setState(() {
          _errorMessage = response['message'] ?? 'حدث خطأ في إرسال رمز التحقق';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'حدث خطأ في إرسال رمز التحقق. الرجاء المحاولة مرة أخرى';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;
    final baseFontSize = width * 0.04;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Full screen gradient overlay
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(-0.7, -0.7),
                radius: 1.5,
                colors: [
                  ColorsManager.layerBlur1.withAlpha(102),
                  ColorsManager.layerBlur1.withAlpha(25),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.3, 0.8],
              ),
            ),
          ),
          // Bottom-right gradient overlay
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0.7, 0.7),
                radius: 1.5,
                colors: [
                  ColorsManager.layerBlur2.withAlpha(102),
                  ColorsManager.layerBlur2.withAlpha(25),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.3, 0.8],
              ),
            ),
          ),
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
                      maxWidth: width >= 600 ? 500 : double.infinity,
                    ),
                    padding: EdgeInsets.all(width * 0.06),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(25),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Directionality(
                      textDirection: TextDirection.rtl,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(height: height * 0.02),
                          Image.asset(
                            'assets/images/splash-logo.png',
                            width: width * 0.2,
                            height: width * 0.2,
                            fit: BoxFit.contain,
                          ),
                          Text(
                            'نسيت كلمة المرور',
                            style: TextStyle(
                              fontSize: baseFontSize * 1.5,
                              fontWeight: FontWeight.bold,
                              color: ColorsManager.mainBlue,
                              fontFamily: 'Cairo',
                            ),
                          ),
                          SizedBox(height: height * 0.02),
                          Text(
                            'ادخل بريدك الإلكتروني وسنرسل لك كود لإعادة تعيين كلمة المرور',
                            style: TextStyle(
                              fontSize: baseFontSize * 0.875,
                              color: Colors.grey,
                              fontFamily: 'Cairo',
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: height * 0.03),
                          Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                TextFormField(
                                  controller: _emailController,
                                  decoration: InputDecoration(
                                    labelText: 'البريد الإلكتروني',
                                    hintText: 'أدخل بريدك الإلكتروني',
                                    prefixIcon: const Icon(Icons.email_outlined),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  keyboardType: TextInputType.emailAddress,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'الرجاء إدخال البريد الإلكتروني';
                                    }
                                    if (!RegExp(r'^[^@]+@[^\s]+\.[^\s]+$').hasMatch(value)) {
                                      return 'الرجاء إدخال بريد إلكتروني صالح';
                                    }
                                    return null;
                                  },
                                ),
                                if (_errorMessage != null) ...[
                                  SizedBox(height: height * 0.02),
                                  Text(
                                    _errorMessage!,
                                    style: const TextStyle(
                                      color: Colors.red,
                                      fontFamily: 'Cairo',
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                                SizedBox(height: height * 0.03),
                                SizedBox(
                                  height: 52,
                                  width: double.infinity,
                                  child: _isLoading
                                      ? const Center(child: CircularProgressIndicator())
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
                                SizedBox(height: height * 0.02),
                                Align(
                                  alignment: Alignment.center,
                                  child: TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                    child: Text(
                                      'العودة لتسجيل الدخول',
                                      style: TextStyle(
                                        fontSize: baseFontSize * 0.8,
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
}
