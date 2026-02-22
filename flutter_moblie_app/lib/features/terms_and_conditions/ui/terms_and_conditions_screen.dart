import 'package:flutter/material.dart';

class TermsAndConditionsScreen extends StatelessWidget {
  const TermsAndConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final baseFontSize = width * 0.04;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'الشروط والأحكام – تطبيق ثوثة',
          style: TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.bold,
            fontSize: baseFontSize * 1.125, // 18
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _buildSection(
              context,
              'أولاً: تعريف التطبيق',
              'تطبيق ثوثة هو تطبيق إلكتروني مجاني هدفه الربط فقط بين طلاب كليات طب الأسنان والمرضى الراغبين في تلقي خدمات علاجية تعليمية.\n\nالتطبيق لا يقدم خدمات طبية، ولا يشرف على العلاج، ولا يتحمل أي مسؤولية طبية أو قانونية ناتجة عن التعامل بين الطالب والمريض.',
              baseFontSize,
            ),
            _buildSection(
              context,
              'ثانياً: دور تطبيق ثوثة',
              '• التطبيق وسيلة ربط فقط بين الطالب والمريض.\n'
              '• لا نضمن حضور أي طرف للموعد.\n'
              '• لا نتحكم في جودة العلاج أو نتائجه.\n'
              '• أي اتفاق يتم هو اتفاق مباشر بين الطرفين.',
              baseFontSize,
            ),
            _buildSection(
              context,
              'شروط وأحكام المرضى',
              '• التطبيق لا يضمن التزام الطالب بالحضور.\n'
              '• المريض مسؤول عن التأكد أنه يتعامل مع طالب وليس طبيباً مرخصاً.\n'
              '• التطبيق غير مسؤول عن أي أضرار طبية أو مادية.\n'
              '• عدم الحضور أو إلغاء الموعد لا يحمل التطبيق أي مسؤولية.',
              baseFontSize,
            ),
            _buildSection(
              context,
              'شروط وأحكام الطلاب',
              '• الطالب يقر بأنه طالب طب أسنان وليس طبيباً.\n'
              '• الطالب يتحمل المسؤولية الكاملة عن أي إجراء طبي.\n'
              '• الالتزام بالمواعيد والتواصل الواضح مع المرضى.\n'
              '• يحق للتطبيق حذف الحساب في حالة إساءة الاستخدام.',
              baseFontSize,
            ),
            _buildSection(
              context,
              'إخلاء المسؤولية',
              'تطبيق ثوثة غير مسؤول عن أي تشخيص طبي أو نتائج علاجية أو نزاعات تحدث بين الطالب والمريض.',
              baseFontSize,
            ),
            _buildSection(
              context,
              'الموافقة',
              'استخدامك للتطبيق يعني موافقتك الكاملة على هذه الشروط.',
              baseFontSize,
            ),
            const SizedBox(height: 24),
            Center(
              child: Text(
                'آخر تحديث: فبراير 2026',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: baseFontSize * 0.75, // 12
                  color: Colors.grey,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, String content, double baseFontSize) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            title,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: baseFontSize * 1.125, // 18
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: baseFontSize * 0.875, // 14
              height: 1.6,
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
        ],
      ),
    );
  }
}
