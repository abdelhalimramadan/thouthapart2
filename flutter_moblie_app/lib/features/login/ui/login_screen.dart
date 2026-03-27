import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/routing/routes.dart';
import '../../../core/theming/colors.dart';
import '../../auth/data/auth_service.dart';
import '../../doctor/ui/doctor_home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.nextScreen, this.nextRouteSettings});

  final Widget? nextScreen;
  final RouteSettings? nextRouteSettings;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool isLoading = false;
  String? passwordError;
  String? errorMessage;
  bool rememberMe = false;
  bool isObscureText = true;
  late final GlobalKey<FormState> _formKey;
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _formKey = GlobalKey<FormState>();
    _loadSavedCredentials();
  }

  // Load saved credentials if they exist
  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      rememberMe = prefs.getBool('rememberMe') ?? false;
      if (rememberMe) {
        emailController.text = prefs.getString('savedEmail') ?? '';
        passwordController.text = prefs.getString('savedPassword') ?? '';
      }
    });
  }

  // Save or clear credentials based on rememberMe value
  Future<void> _handleRememberMe(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      rememberMe = value;
    });

    if (value) {
      // Save credentials
      await prefs.setBool('rememberMe', true);
      await prefs.setString('savedEmail', emailController.text);
      await prefs.setString('savedPassword', passwordController.text);
    } else {
      // Clear saved credentials
      await prefs.remove('rememberMe');
      await prefs.remove('savedEmail');
      await prefs.remove('savedPassword');
    }
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (rememberMe) {
      await _handleRememberMe(true);
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
      passwordError = null;
    });

    try {
      final result = await AuthService().login(
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      if (result['success'] == true) {
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            Routes.welcomeScreen,
            (route) => false,
          );
        }
      } else {
        String errorMsg =
            result['error'] ?? 'فشل تسجيل الدخول. الرجاء المحاولة مرة أخرى.';
        if (result['statusCode'] == 401) {
          errorMsg = 'البريد الإلكتروني أو كلمة المرور غير صحيحة';
        } else if (result['statusCode'] == 404) {
          errorMsg =
              'لا يوجد حساب مسجل بهذا البريد الإلكتروني. الرجاء إنشاء حساب أولاً';
        }
        setState(() {
          errorMessage = errorMsg;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = 'Login failed. Please try again.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      resizeToAvoidBottomInset: true,
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
                  isDarkMode
                      ? ColorsManager.layerBlur1.withAlpha(50)
                      : ColorsManager.layerBlur1.withAlpha(102),
                  isDarkMode
                      ? ColorsManager.layerBlur1.withAlpha(20)
                      : ColorsManager.layerBlur1.withAlpha(25),
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
                  isDarkMode
                      ? ColorsManager.layerBlur2.withAlpha(50)
                      : ColorsManager.layerBlur2.withAlpha(102),
                  isDarkMode
                      ? ColorsManager.layerBlur2.withAlpha(20)
                      : ColorsManager.layerBlur2.withAlpha(25),
                  Colors.transparent,
                ],
                stops: const [0.1, 0.3, 0.8],
              ),
            ),
          ),

          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 24.w,
                        vertical: 24.h,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: double.infinity,
                            constraints: BoxConstraints(
                              maxWidth: 1.sw >= 600 ? 500.w : double.infinity,
                            ),
                            padding: EdgeInsets.all(24.r),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardTheme.color,
                              borderRadius: BorderRadius.circular(16.r),
                              boxShadow: [
                                BoxShadow(
                                  color: isDarkMode
                                      ? Colors.black.withAlpha(102)
                                      : Colors.black.withAlpha(25),
                                  blurRadius: 10.r,
                                  offset: Offset(0, 4.h),
                                ),
                              ],
                            ),
                            child: Directionality(
                              textDirection: TextDirection.rtl,
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Center(
                                      child: Image.asset(
                                        'assets/images/splash-logo.png',
                                        width: 80.w,
                                        height: 80.h,
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                    SizedBox(height: 8.h),
                                    Text(
                                      'تسجيل الدخول',
                                      style: TextStyle(
                                        fontSize: 24.sp,
                                        fontWeight: FontWeight.bold,
                                        color: ColorsManager.mainBlue,
                                        fontFamily: 'Cairo',
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    SizedBox(height: 8.h),
                                    Text(
                                      'ادخل البريد الإلكتروني وكلمة المرور',
                                      style: TextStyle(
                                        fontSize: 14.sp,
                                        color: isDarkMode
                                            ? Colors.white70
                                            : Colors.grey,
                                        fontFamily: 'Cairo',
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    SizedBox(height: 16.h),

                                    if (errorMessage != null)
                                      Container(
                                        padding: EdgeInsets.all(12.r),
                                        margin: EdgeInsets.only(bottom: 16.h),
                                        decoration: BoxDecoration(
                                          color: isDarkMode
                                              ? Colors.red
                                                  .withValues(alpha: 0.15)
                                              : Colors.red[50],
                                          borderRadius:
                                              BorderRadius.circular(8.r),
                                          border: Border.all(
                                              color: isDarkMode
                                                  ? Colors.red.shade900
                                                  : Colors.red[200]!),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(Icons.error_outline,
                                                color: isDarkMode
                                                    ? Colors.red[300]
                                                    : Colors.red,
                                                size: 20.r),
                                            SizedBox(width: 8.w),
                                            Expanded(
                                              child: Text(
                                                errorMessage!,
                                                style: TextStyle(
                                                  color: isDarkMode
                                                      ? Colors.red[300]
                                                      : Colors.red,
                                                  fontFamily: 'Cairo',
                                                  fontSize: 13.sp,
                                                ),
                                                softWrap: true,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                    // Email Field
                                    TextFormField(
                                      controller: emailController,
                                      keyboardType: TextInputType.emailAddress,
                                      decoration: const InputDecoration(
                                        labelText: 'البريد الإلكتروني',
                                        prefixIcon: Icon(Icons.email_outlined),
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'الرجاء إدخال البريد الإلكتروني';
                                        }
                                        if (!RegExp(r'^[^@]+@[^\s]+\.[^\s]+$')
                                            .hasMatch(value)) {
                                          return 'الرجاء إدخال بريد إلكتروني صالح';
                                        }
                                        return null;
                                      },
                                    ),
                                    SizedBox(height: 16.h),

                                    // Password Field
                                    TextFormField(
                                      controller: passwordController,
                                      obscureText: isObscureText,
                                      decoration: InputDecoration(
                                        labelText: 'كلمة المرور',
                                        prefixIcon:
                                            const Icon(Icons.lock_outline),
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            isObscureText
                                                ? Icons.visibility_off
                                                : Icons.visibility,
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              isObscureText = !isObscureText;
                                            });
                                          },
                                        ),
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'الرجاء إدخال كلمة المرور';
                                        }
                                        if (value.length < 6) {
                                          return 'يجب أن تكون كلمة المرور 6 أحرف على الأقل';
                                        }
                                        return null;
                                      },
                                    ),
                                    SizedBox(height: 8.h),

                                    // Forgot Password & Remember Me
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Flexible(
                                          child: TextButton(
                                            onPressed: () {
                                              Navigator.of(context).pushNamed(
                                                  Routes.forgotPasswordScreen);
                                            },
                                            child: Text(
                                              'نسيت كلمة المرور؟',
                                              style: TextStyle(
                                                fontSize: 13.sp,
                                                color: ColorsManager.mainBlue,
                                                decoration:
                                                    TextDecoration.underline,
                                                fontFamily: 'Cairo',
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            Transform.scale(
                                              scale: 0.9.r,
                                              child: Checkbox(
                                                value: rememberMe,
                                                onChanged: (bool? value) {
                                                  _handleRememberMe(
                                                      value ?? false);
                                                },
                                                activeColor:
                                                    ColorsManager.mainBlue,
                                              ),
                                            ),
                                            Text(
                                              'تذكرني',
                                              style: TextStyle(
                                                fontSize: 13.sp,
                                                color: isDarkMode
                                                    ? Colors.white
                                                    : ColorsManager.darkBlue,
                                                fontWeight: FontWeight.w500,
                                                fontFamily: 'Cairo',
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 16.h),

                                    // Login Button
                                    SizedBox(
                                      width: double.infinity,
                                      height: 52.h,
                                      child: ElevatedButton(
                                        onPressed: isLoading ? null : _login,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              ColorsManager.mainBlue,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8.r),
                                          ),
                                        ),
                                        child: isLoading
                                            ? SizedBox(
                                                width: 20.w,
                                                height: 20.h,
                                                child:
                                                    const CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  color: Colors.white,
                                                ),
                                              )
                                            : Text(
                                                'تسجيل الدخول',
                                                style: TextStyle(
                                                  fontSize: 16.sp,
                                                  color: Colors.white,
                                                  fontFamily: 'Cairo',
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                      ),
                                    ),
                                    SizedBox(height: 8.h),
                                    Text(
                                      'بالدخول، أنت توافق على الشروط والأحكام.',
                                      style: TextStyle(
                                        fontSize: 13.sp,
                                        color: isDarkMode
                                            ? Colors.white60
                                            : Colors.grey,
                                        fontFamily: 'Cairo',
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    SizedBox(height: 16.h),
                                    // Sign up link
                                    Wrap(
                                      alignment: WrapAlignment.center,
                                      crossAxisAlignment:
                                          WrapCrossAlignment.center,
                                      children: [
                                        Text(
                                          'هل ليس لديك حساب بالفعل؟ ',
                                          style: TextStyle(
                                            fontSize: 13.sp,
                                            color: isDarkMode
                                                ? Colors.white
                                                : ColorsManager.darkBlue,
                                            fontWeight: FontWeight.w500,
                                            fontFamily: 'Cairo',
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: () {
                                            Navigator.pushNamed(
                                                context, Routes.signUpScreen);
                                          },
                                          child: Text(
                                            'إنشاء حساب',
                                            style: TextStyle(
                                              fontSize: 13.sp,
                                              color: ColorsManager.mainBlue,
                                              fontWeight: FontWeight.bold,
                                              decoration:
                                                  TextDecoration.underline,
                                              fontFamily: 'Cairo',
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 16.h),
                          // Back button
                          GestureDetector(
                            onTap: () {
                              Navigator.of(context).pushNamedAndRemoveUntil(
                               // Routes.categoriesScreen,
                                Routes.welcomeScreen,
                                (route) => false,
                              );
                            },
                            child: Container(
                              width: double.infinity,
                              constraints: BoxConstraints(
                                maxWidth: 1.sw >= 600 ? 500.w : double.infinity,
                              ),
                              height: 52.h,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                  colors: [
                                    ColorsManager.layerBlur1,
                                    ColorsManager.layerBlur2,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12.r),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withAlpha(25),
                                    blurRadius: 8.r,
                                    offset: Offset(0, 4.h),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  'الرجوع للصفحة الرئيسية',
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'Cairo',
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
              },
            ),
          ),
        ],
      ),
    );
  }
}
