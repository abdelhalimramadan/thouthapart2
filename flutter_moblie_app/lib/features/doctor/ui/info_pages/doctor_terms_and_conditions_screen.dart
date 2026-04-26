import 'package:flutter/material.dart';
import 'package:thoutha_mobile_app/features/doctor/drawer_doctor/doctor_drawer_screen.dart';

class DoctorTermsAndConditionsScreen extends StatefulWidget {
  const DoctorTermsAndConditionsScreen({super.key});

  @override
  State<DoctorTermsAndConditionsScreen> createState() => _DoctorTermsAndConditionsScreenState();
}

class _DoctorTermsAndConditionsScreenState extends State<DoctorTermsAndConditionsScreen> {
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
            icon: const Icon(Icons.menu, size: 24),
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          ),
        ),
        titleSpacing: 0,
        centerTitle: true,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'الشروط والأحكام',
              style: textTheme.titleLarge?.copyWith(
                fontFamily: 'Cairo',
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 8),
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
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSection(
                context,
                'مقدمة للطلاب',
                'بصفتك مستخدماً للتطبيق كطالب طب أسنان، فإنك تقر وتوافق على الالتزام بالقواعد المهنية والأخلاقية المعمول بها في كليتك وتحت إشراف أعضاء هيئة التدريس.',
              ),
              _buildSection(
                context,
                'أولاً: المسؤولية الطبية',
                '• الطالب هو المسؤول الوحيد عن الإجراءات الطبية التي يقوم بها.\n'
                '• التطبيق لا يوفر غطاءً قانونياً أو تأمينياً للطالب.\n'
                '• يجب إبلاغ المريض بوضوح بأنك "طالب" وأن العلاج يتم في إطار تعليمي.',
              ),
              _buildSection(
                context,
                'ثانياً: الالتزام بالمواعيد',
                '• الالتزام بالحضور في المواعيد المحددة مع المرضى.\n'
                '• في حالة الإلغاء، يجب إخطار المريض قبل الموعد بوقت كافٍ.\n'
                '• تكرار الغياب بدون عذر قد يؤدي لإغلاق حسابك.',
              ),
              _buildSection(
                context,
                'ثالثاً: الخصوصية والاحترافية',
                '• الحفاظ على سرية بيانات المرضى وخصوصيتهم.\n'
                '• التعامل باحترام واحترافية مع جميع مستخدمي التطبيق.\n'
                '• يمنع استخدام بيانات المرضى لأي غرض خارج إطار العلاج التعليمي.',
              ),
              _buildSection(
                context,
                'رابعاً: إخلاء مسؤولية التطبيق',
                'تطبيق ثوثة هو وسيلة ربط تقنية فقط ولا يتدخل في العملية العلاجية أو التقييم الأكاديمي.',
              ),
              const SizedBox(height: 24),
              Center(
                child: Text(
                  'آخر تحديث: أبريل 2026',
                  textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 12,
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.white54 : Colors.grey,
                ),
                ),
              ),
              SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, String content) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            textAlign: TextAlign.start,
            textDirection: TextDirection.rtl,
            style: theme.textTheme.titleMedium?.copyWith(
              fontFamily: 'Cairo',
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          ...content.split('\n').map((line) => Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  line,
                  textAlign: TextAlign.start,
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
