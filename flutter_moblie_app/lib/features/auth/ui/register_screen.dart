import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:thoutha_mobile_app/core/helpers/app_regex.dart';
import 'package:thoutha_mobile_app/core/helpers/spacing.dart';
import 'package:thoutha_mobile_app/core/routing/routes.dart';
import 'package:thoutha_mobile_app/core/theming/colors.dart';
import 'package:thoutha_mobile_app/core/theming/styles.dart';
import 'package:thoutha_mobile_app/features/auth/data/auth_service.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _facultyController = TextEditingController();
  final _yearController = TextEditingController();
  final _governorateController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _facultyController.dispose();
    _yearController.dispose();
    _governorateController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'auth.email_required'.tr();
    }
    if (!RegExp(r'^[^@]+@[^\s]+\.[^\s]+$').hasMatch(value)) {
      return 'auth.please_enter_a_valid'.tr();
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'auth.password_required'.tr();
    }
    if (value.length < 6) {
      return 'auth.password_must_be_at'.tr();
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'auth.password_confirmation_is_required'.tr();
    }
    if (value != _passwordController.text) {
      return 'auth.passwords_do_not_match'.tr();
    }
    return null;
  }

  String? _validateRequired(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return 'auth.var0_is_required'.tr(namedArgs: {'var_0': fieldName.toString()});
    }
    return null;
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _authService.register(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        confirm: _confirmPasswordController.text,
        first_name: _firstNameController.text.trim(),
        last_name: _lastNameController.text.trim(),
        phone: _phoneController.text.trim(),
        faculty: _facultyController.text.trim(),
        year: _yearController.text.trim(),
        governorate: _governorateController.text.trim(),
      );

      if (response['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                response['message'] ?? 'auth.the_account_has_been'.tr(),
                textAlign: TextAlign.right,
              ),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pushReplacementNamed(context, Routes.loginScreen);
        }
      } else {
        setState(() {
          _errorMessage =
              response['error'] ?? 'auth.account_creation_failed_please'.tr();
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'auth.an_error_occurred_connecting'.tr();
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
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final baseFontSize = width * 0.04;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text('auth.create_a_new_account'.tr()),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  verticalSpace(40),
                  Center(
                    child: Text(
                      'auth.thutha'.tr(),
                      style: TextStyles.font24BlueBold.copyWith(
                        fontSize: baseFontSize * 1.5,
                      ),
                    ),
                  ),
                  verticalSpace(24),
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'auth.email'.tr(),
                      prefixIcon: Icon(Icons.email_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    validator: _validateEmail,
                  ),
                  verticalSpace(16),
                  TextFormField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: 'auth.password'.tr(),
                      prefixIcon: Icon(Icons.lock_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    obscureText: true,
                    validator: _validatePassword,
                  ),
                  verticalSpace(16),
                  TextFormField(
                    controller: _confirmPasswordController,
                    decoration: InputDecoration(
                      labelText: 'auth.confirm_password'.tr(),
                      prefixIcon: Icon(Icons.lock_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    obscureText: true,
                    validator: _validateConfirmPassword,
                  ),
                  verticalSpace(16),
                  TextFormField(
                    controller: _firstNameController,
                    decoration: InputDecoration(
                      labelText: 'auth.first_name'.tr(),
                      prefixIcon: Icon(Icons.person_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'[\u0621-\u064A\s]'),
                      ),
                    ],
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'auth.first_name_required'.tr();
                      }
                      if (!AppRegex.isArabicName(value.trim())) {
                        return 'auth.the_first_name_must'.tr();
                      }
                      return null;
                    },
                  ),
                  verticalSpace(16),
                  TextFormField(
                    controller: _lastNameController,
                    decoration: InputDecoration(
                      labelText: 'auth.last_name'.tr(),
                      prefixIcon: Icon(Icons.person_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'[\u0621-\u064A\s]'),
                      ),
                    ],
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'auth.last_name_required'.tr();
                      }
                      if (!AppRegex.isArabicName(value.trim())) {
                        return 'auth.the_last_name_must'.tr();
                      }
                      return null;
                    },
                  ),
                  verticalSpace(16),
                  TextFormField(
                    controller: _phoneController,
                    decoration: InputDecoration(
                      labelText: 'auth.phone_number'.tr(),
                      prefixIcon: Icon(Icons.phone_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (value) =>
                        _validateRequired(value, 'auth.phone_number'.tr()),
                  ),
                  verticalSpace(16),
                  TextFormField(
                    controller: _facultyController,
                    decoration: InputDecoration(
                      labelText: 'auth.college'.tr(),
                      prefixIcon: Icon(Icons.school_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    validator: (value) => _validateRequired(value, 'auth.college'.tr()),
                  ),
                  verticalSpace(16),
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: 'auth.academic_year'.tr(),
                      prefixIcon: Icon(Icons.calendar_today_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    items: ['auth.fourth'.tr(), 'auth.fifth'.tr(), 'auth.privilege'.tr()]
                        .map((year) => DropdownMenuItem(
                              value: year,
                              child: Text(year),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        _yearController.text = value;
                      }
                    },
                    initialValue: _yearController.text.isNotEmpty
                        ? _yearController.text
                        : null,
                    validator: (value) =>
                        _validateRequired(value, 'auth.academic_year'.tr()),
                  ),
                  verticalSpace(16),
                  TextFormField(
                    controller: _governorateController,
                    decoration: InputDecoration(
                      labelText: 'auth.text'.tr(),
                      helperText: 'auth.text_1'.tr(),
                      prefixIcon: Icon(Icons.location_city_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    validator: (value) => _validateRequired(value, 'auth.text'.tr()),
                  ),
                  if (_errorMessage != null) ...[
                    SizedBox(height: 16),
                    Text(
                      _errorMessage!,
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: baseFontSize * 0.875,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  SizedBox(height: 32),
                  SizedBox(
                    height: 52 * (width / 390),
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _register,
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        backgroundColor: ColorsManager.mainBlue,
                      ),
                      child: _isLoading
                          ? CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            )
                          : Text(
                              'auth.registration'.tr(),
                              style: TextStyle(
                                fontSize: baseFontSize,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                  SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacementNamed(
                          context, Routes.loginScreen);
                    },
                    child: Text(
                      'auth.already_have_an_account'.tr(),
                      style: TextStyle(
                        color: ColorsManager.mainBlue,
                        fontSize: baseFontSize * 0.875,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
