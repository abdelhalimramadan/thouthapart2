import 'package:flutter/material.dart';
import 'package:thoutha_mobile_app/features/doctor/drawer_doctor/doctor_drawer_screen.dart';

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

  Future<void> _sendMessage() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSending = true);
    await Future.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;
    setState(() => _isSending = false);
    _messageController.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم استلام طلب الدعم، سنرد عليك قريباً.', style: TextStyle(fontFamily: 'Cairo')), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      key: _scaffoldKey,
      drawer: const DoctorDrawer(),
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
              'دعم الطلاب',
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
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('فريق دعم ثوثة مخصص لمساعدة الطلاب في إدارة حالاتهم وحل أي مشاكل تقنية تواجههم.', style: TextStyle(fontFamily: 'Cairo', fontSize: 14, height: 1.6)),
              const SizedBox(height: 24),
              _buildSectionTitle(theme, 'الأسئلة الشائعة للطلاب'),
              _buildFaqItem('كيف يمكنني حذف حالة قمت بنشرها؟', 'يمكنك حذف الحالة من قسم "طلباتي" في القائمة الجانبية.'),
              _buildFaqItem('لماذا لا يظهر رقم هاتفي للمرضى؟', 'يظهر الرقم فقط للمرضى الذين أكدت حجزهم لضمان جديتهم.'),
              const SizedBox(height: 24),
              _buildSectionTitle(theme, 'تواصل مع الدعم'),
              const Text(
                'يمكنك التواصل معنا مباشرة عبر البريد الإلكتروني:',
                style: TextStyle(fontFamily: 'Cairo', fontSize: 13),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: () {
                  // Optionally: launch mailto
                },
                child: Row(
                  children: [
                    Icon(Icons.email_outlined,
                        size: 20, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
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
              const SizedBox(height: 20),
              const Text(
                'أو يمكنك إرسال مشكلتك عبر النموذج التالي:',
                style: TextStyle(fontFamily: 'Cairo', fontSize: 13),
              ),
              const SizedBox(height: 12),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _messageController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'اكتب مشكلتك هنا بالتفصيل...',
                        hintStyle: const TextStyle(fontFamily: 'Cairo', fontSize: 13),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (v) => (v == null || v.isEmpty) ? 'يرجى كتابة الرسالة' : null,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isSending ? null : _sendMessage,
                        style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        child: _isSending ? const CircularProgressIndicator() : const Text('إرسال الطلب', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
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
      title: Text(question, style: const TextStyle(fontFamily: 'Cairo', fontSize: 14, fontWeight: FontWeight.w600)),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Text(answer, style: const TextStyle(fontFamily: 'Cairo', fontSize: 13, color: Colors.grey)),
        ),
      ],
    );
  }
}
