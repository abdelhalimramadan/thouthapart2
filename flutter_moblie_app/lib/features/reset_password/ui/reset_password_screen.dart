import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/routing/routes.dart';
import '../../../core/theming/colors.dart';
import '../../../core/theming/styles.dart';
import '../../../core/widgets/app_text_button.dart';
import '../../forgot_password/data/forgot_password_service.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String phone;

  const ResetPasswordScreen({super.key, required this.phone});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey               = GlobalKey<FormState>();
  final _newPassCtrl           = TextEditingController();
  final _confirmPassCtrl       = TextEditingController();

  bool    _obscureNew          = true;
  bool    _obscureConfirm      = true;
  bool    _isLoading           = false;
  String? _errorMessage;


  @override
  void dispose() {
    _newPassCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
    // Restore orientations
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
  }

  // ── Validation ──────────────────────────────────────────────────────────
  String? _validateNew(String? v) {
    if (v == null || v.isEmpty) return 'الرجاء إدخال كلمة المرور الجديدة';
    if (v.length < 6) return 'يجب أن تكون 6 أحرف على الأقل';
    return null;
  }

  String? _validateConfirm(String? v) {
    if (v == null || v.isEmpty) return 'الرجاء تأكيد كلمة المرور';
    if (v != _newPassCtrl.text) return 'كلمتا المرور غير متطابقتين';
    return null;
  }

  // ── Submit ──────────────────────────────────────────────────────────────
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() { _isLoading = true; _errorMessage = null; });

    try {
      final result = await PasswordResetService.instance.changePassword(
        phone:           widget.phone,
        newPassword:     _newPassCtrl.text,
        confirmPassword: _confirmPassCtrl.text,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        _showSuccessDialog();
      } else {
        setState(() => _errorMessage = result['message'] ?? 'فشل تغيير كلمة المرور');
      }
    } catch (_) {
      if (mounted) setState(() => _errorMessage = 'حدث خطأ غير متوقع');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuccessDialog() {
    final width = MediaQuery.of(context).size.width;
    final fs    = width * 0.04;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            constraints: BoxConstraints(maxWidth: width >= 600 ? 500 : double.infinity),
            padding: EdgeInsets.all(width * 0.06),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.green, size: 80),
                const SizedBox(height: 16),
                Text(
                  'تم تغيير كلمة المرور!',
                  style: TextStyle(fontFamily: 'Cairo', fontSize: fs * 1.4, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'يمكنك الآن تسجيل الدخول بكلمة المرور الجديدة.',
                  style: TextStyle(fontFamily: 'Cairo', color: Colors.grey[600], fontSize: fs * 0.875),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: AppTextButton(
                    buttonText: 'تسجيل الدخول',
                    textStyle: TextStyles.font16WhiteSemiBold.copyWith(fontFamily: 'Cairo'),
                    onPressed: () {
                      Navigator.of(context).pushNamedAndRemoveUntil(
                        Routes.loginScreen,
                        (route) => false,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final fs    = width * 0.04;

    return Scaffold(
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
                  width: double.infinity,
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Logo + Title
                          Center(
                            child: Image.asset(
                              'assets/images/splash-logo.png',
                              width: 80 * (width / 390),
                              height: 80 * (width / 390),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Center(
                            child: Text(
                              'إعادة تعيين كلمة المرور',
                              style: TextStyles.font24BlueBold.copyWith(fontFamily: 'Cairo', fontSize: fs * 1.5),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Center(
                            child: Text(
                              'أنشئ كلمة مرور جديدة لا تقل عن 6 أحرف',
                              style: TextStyles.font14GrayRegular.copyWith(fontFamily: 'Cairo', fontSize: fs * 0.875),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // New password
                          _FieldLabel(text: 'كلمة المرور الجديدة', fs: fs),
                          const SizedBox(height: 6),
                          _PasswordField(
                            controller: _newPassCtrl,
                            hint: 'أدخل كلمة المرور الجديدة',
                            obscure: _obscureNew,
                            onToggle: () => setState(() => _obscureNew = !_obscureNew),
                            validator: _validateNew,
                          ),
                          const SizedBox(height: 16),

                          // Confirm password
                          _FieldLabel(text: 'تأكيد كلمة المرور', fs: fs),
                          const SizedBox(height: 6),
                          _PasswordField(
                            controller: _confirmPassCtrl,
                            hint: 'أعد إدخال كلمة المرور',
                            obscure: _obscureConfirm,
                            onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
                            validator: _validateConfirm,
                          ),

                          // Error message
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

                          const SizedBox(height: 32),

                          // Submit
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: _isLoading
                                ? const Center(child: CircularProgressIndicator())
                                : AppTextButton(
                                    buttonText: 'تغيير كلمة المرور',
                                    textStyle: TextStyles.font16WhiteSemiBold.copyWith(fontFamily: 'Cairo'),
                                    onPressed: _submit,
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
        width: double.infinity, height: double.infinity,
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: center, radius: 1.5,
            colors: [color.withValues(alpha: 0.4), color.withValues(alpha: 0.1), Colors.transparent],
            stops: const [0.0, 0.3, 0.8],
          ),
        ),
      );
}

// ── Reusable field label ────────────────────────────────────────────────────
class _FieldLabel extends StatelessWidget {
  final String text;
  final double fs;
  const _FieldLabel({required this.text, required this.fs});

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: TextStyles.font14DarkBlueMedium.copyWith(fontFamily: 'Cairo', fontSize: fs * 0.875),
      );
}

// ── Reusable password field ─────────────────────────────────────────────────
class _PasswordField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool obscure;
  final VoidCallback onToggle;
  final FormFieldValidator<String> validator;

  const _PasswordField({
    required this.controller,
    required this.hint,
    required this.obscure,
    required this.onToggle,
    required this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(fontFamily: 'Cairo'),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontFamily: 'Cairo', color: Colors.grey),
        suffixIcon: IconButton(
          icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
          onPressed: onToggle,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: ColorsManager.mainBlue, width: 2),
        ),
      ),
      validator: validator,
    );
  }
}
