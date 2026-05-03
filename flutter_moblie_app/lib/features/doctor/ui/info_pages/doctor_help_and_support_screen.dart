import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:thoutha_mobile_app/features/doctor/drawer_doctor/doctor_drawer_screen.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;

class DoctorHelpAndSupportScreen extends StatefulWidget {
  const DoctorHelpAndSupportScreen({super.key});

  @override
  State<DoctorHelpAndSupportScreen> createState() => _DoctorHelpAndSupportScreenState();
}

class _DoctorHelpAndSupportScreenState extends State<DoctorHelpAndSupportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _messageController = TextEditingController();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isSending = false;
  static const String _supportEmail = 'support@thoutha.page';

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _launchEmail(String userMessage) async {
    final emailUri = Uri.parse(
      'mailto:$_supportEmail'
      '?subject=${Uri.encodeComponent('Support Request')}'
      '&body=${Uri.encodeComponent(userMessage)}',
    );

    try {
      await launchUrl(emailUri);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('doctor.the_email_application_cannot'.tr(), style: TextStyle(fontFamily: 'Cairo')),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _sendMessage() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSending = true);

    await _launchEmail(_messageController.text.trim());

    if (!mounted) return;
    setState(() => _isSending = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Directionality(
      textDirection: context.locale.languageCode == 'ar'
          ? TextDirection.rtl
          : TextDirection.ltr,
      child: Scaffold(
        key: _scaffoldKey,
        drawer: DoctorDrawer(),
        appBar: AppBar(
          toolbarHeight: 70,
          elevation: 0,
          backgroundColor: theme.colorScheme.surface,
          foregroundColor: theme.colorScheme.onSurface,
          automaticallyImplyLeading: false,
          leading: Builder(
            builder: (context) => IconButton(
              icon: Icon(Icons.menu, size: 24),
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            ),
          ),
          titleSpacing: 0,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'doctor.student_support'.tr(),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontFamily: 'Cairo',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(width: 8),
              Image.asset(
                'assets/images/splash-logo.png',
                width: 36,
                height: 36,
                fit: BoxFit.contain,
              ),
            ],
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('doctor.the_thootha_support_team'.tr(),
                  style:
                      TextStyle(fontFamily: 'Cairo', fontSize: 14, height: 1.6)),
              SizedBox(height: 24),
              _buildSectionTitle(
                  theme, 'doctor.frequently_asked_questions_for'.tr()),
              _buildFaqItem(
                  'doctor.how_do_i_delete'.tr(), 'doctor.you_can_delete_the'.tr()),
              _buildFaqItem(
                  'doctor.why_is_my_phone'.tr(), 'doctor.the_number_is_only'.tr()),
              SizedBox(height: 24),
              _buildSectionTitle(theme, 'doctor.contact_support'.tr()),
              Text(
                'doctor.you_can_contact_us'.tr(),
                style: TextStyle(fontFamily: 'Cairo', fontSize: 13),
              ),
              SizedBox(height: 8),
              InkWell(
                onTap: () => _launchEmail('Please describe your issue here.'),
                child: Row(
                  children: [
                    Icon(Icons.email_outlined,
                        size: 20, color: theme.colorScheme.primary),
                    SizedBox(width: 8),
                    Text(
                      _supportEmail,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.primary,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              Text(
                'doctor.or_you_can_submit'.tr(),
                style: TextStyle(fontFamily: 'Cairo', fontSize: 13),
              ),
              SizedBox(height: 12),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _messageController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'doctor.write_your_problem_here'.tr(),
                        hintStyle: TextStyle(fontFamily: 'Cairo', fontSize: 13),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (v) => (v == null || v.isEmpty)
                          ? 'doctor.please_write_the_message'.tr()
                          : null,
                    ),
                    SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _isSending ? null : _sendMessage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isSending
                            ? SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              )
                            : Text(
                                'doctor.submit_the_request'.tr(),
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
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
    );
  }

  Widget _buildSectionTitle(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(title, style: TextStyle(fontFamily: 'Cairo', fontSize: 16, fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
    );
  }

  Widget _buildFaqItem(String question, String answer) {
    return ExpansionTile(
      title: Text(question, style: TextStyle(fontFamily: 'Cairo', fontSize: 14, fontWeight: FontWeight.w600)),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Text(answer, style: TextStyle(fontFamily: 'Cairo', fontSize: 13, color: Colors.grey)),
        ),
      ],
    );
  }
}
