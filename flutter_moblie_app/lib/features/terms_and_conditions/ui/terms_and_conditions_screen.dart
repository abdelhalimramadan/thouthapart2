import 'package:flutter/material.dart';
import 'package:thoutha_mobile_app/features/doctor/drawer_doctor/doctor_drawer_screen.dart';

class TermsAndConditionsScreen extends StatefulWidget {
  const TermsAndConditionsScreen({super.key});

  @override
  State<TermsAndConditionsScreen> createState() => _TermsAndConditionsScreenState();
}

class _TermsAndConditionsScreenState extends State<TermsAndConditionsScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: theme.scaffoldBackgroundColor,
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
        centerTitle: true,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/splash-logo.png',
              width: 36,
              height: 36,
              fit: BoxFit.contain,
            ),
            SizedBox(width: 8),
            Text(
              'الشروط والاحكام',
              style: textTheme.titleLarge?.copyWith(
                fontFamily: 'Cairo',
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _buildSection(
              context,
              'أولاً: تعريف التطبيق',
              'تطبيق ثوثة هو تطبيق إلكتروني مجاني هدفه الربط فقط بين طلاب كليات طب الأسنان والمرضى الراغبين في تلقي خدمات علاجية تعليمية.\n\nالتطبيق لا يقدم خدمات طبية، ولا يشرف على العلاج، ولا يتحمل أي مسؤولية طبية أو قانونية ناتجة عن التعامل بين الطالب والمريض.',
            ),
            _buildSection(
              context,
              'ثانياً: دور تطبيق ثوثة',
              '• التطبيق وسيلة ربط فقط بين الطالب والمريض.\n'
                  '• لا نضمن حضور أي طرف للموعد.\n'
                  '• لا نتحكم في جودة العلاج أو نتائجه.\n'
                  '• أي اتفاق يتم هو اتفاق مباشر بين الطرفين.',
            ),
            _buildSection(
              context,
              'شروط وأحكام المرضى',
              '• التطبيق لا يضمن التزام الطالب بالحضور.\n'
                  '• المريض مسؤول عن التأكد أنه يتعامل مع طالب وليس طبيباً مرخصاً.\n'
                  '• التطبيق غير مسؤول عن أي أضرار طبية أو مادية.\n'
                  '• عدم الحضور أو إلغاء الموعد لا يحمل التطبيق أي مسؤولية.',
            ),
            _buildSection(
              context,
              'شروط وأحكام الطلاب',
              '• الطالب يقر بأنه طالب طب أسنان وليس طبيباً.\n'
                  '• الطالب يتحمل المسؤولية الكاملة عن أي إجراء طبي.\n'
                  '• الالتزام بالمواعيد والتواصل الواضح مع المرضى.\n'
                  '• يحق للتطبيق حذف الحساب في حالة إساءة الاستخدام.',
            ),
            _buildSection(
              context,
              'إخلاء المسؤولية',
              'تطبيق ثوثة غير مسؤول عن أي تشخيص طبي أو نتائج علاجية أو نزاعات تحدث بين الطالب والمريض.',
            ),
            _buildSection(
              context,
              'الموافقة',
              'استخدامك للتطبيق يعني موافقتك الكاملة على هذه الشروط.',
            ),
            const SizedBox(height: 24),
            Center(
              child: Text(
                'آخر تحديث: فبراير 2026',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
      BuildContext context, String title, String content) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            title,
            textAlign: TextAlign.right,
            style: theme.textTheme.titleMedium?.copyWith(
              fontFamily: 'Cairo',
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          ...content.split('\n').map((line) => Padding(
                padding: const EdgeInsets.only(bottom: 2, right: 0),
                child: Text(
                  line,
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.rtl,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontFamily: 'Cairo',
                    fontSize: 13,
                    height: 1.6,
                  ),
                ),
              )),
        ],
      ),
    );
  }
}
