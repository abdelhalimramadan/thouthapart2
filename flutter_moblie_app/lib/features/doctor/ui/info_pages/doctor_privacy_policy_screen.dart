import 'package:flutter/material.dart';
import 'package:thoutha_mobile_app/features/doctor/drawer_doctor/doctor_drawer_screen.dart';

class DoctorPrivacyPolicyScreen extends StatefulWidget {
  const DoctorPrivacyPolicyScreen({super.key});

  @override
  State<DoctorPrivacyPolicyScreen> createState() => _DoctorPrivacyPolicyScreenState();
}

class _DoctorPrivacyPolicyScreenState extends State<DoctorPrivacyPolicyScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: theme.scaffoldBackgroundColor,
      drawer: const DoctorDrawer(),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 140,
              pinned: true,
              automaticallyImplyLeading: false,
              backgroundColor: theme.colorScheme.surface,
              foregroundColor: theme.colorScheme.onSurface,
              centerTitle: true,
              flexibleSpace: FlexibleSpaceBar(
                background: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'خصوصية الطلاب',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
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
              ),
              leading: Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu, size: 24),
                  onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildSection(
                          isDark: isDark,
                          title: 'بيانات الطلاب المعالجة',
                          icon: Icons.person_pin_outlined,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildBodyText(isDark, 'نقوم بجمع البيانات التالية لضمان جودة الخدمة:'),
                              const SizedBox(height: 10),
                              _buildBullet(isDark, 'الاسم الكامل وصورة الملف الشخصي.'),
                              _buildBullet(isDark, 'بيانات الجامعة والمستوى الدراسي (إن وجد).'),
                              _buildBullet(isDark, 'تاريخ سجل الحجوزات والطلبات.'),
                              _buildBullet(isDark, 'التقييمات المقدمة من المرضى.'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildSection(
                          isDark: isDark,
                          title: 'كيفية ظهور بياناتك',
                          icon: Icons.visibility_outlined,
                          child: _buildBodyText(isDark, 'يظهر اسمك وتخصصك (والتقييمات) للمرضى لمساعدتهم في اختيار الطالب المناسب. لا يتم عرض رقم هاتفك إلا بعد تأكيد الحجز (حسب إعدادات التطبيق).'),
                        ),
                        const SizedBox(height: 12),
                        _buildSection(
                          isDark: isDark,
                          title: 'أمن الحساب',
                          icon: Icons.security_outlined,
                          child: _buildBodyText(isDark, 'أنت مسؤول عن الحفاظ على سرية بيانات دخولك. ننصح بتغيير كلمة المرور بشكل دوري وعدم مشاركتها مع أي شخص.'),
                        ),
                        const SizedBox(height: 24),
                        _buildFooter(isDark),
                        SizedBox(height: MediaQuery.of(context).padding.bottom + 24),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required bool isDark, required String title, required IconData icon, required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161B22) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.grey[800]! : const Color(0xFFE5E7EB)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: isDark ? Colors.white70 : const Color(0xFF021433)),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700, fontSize: 14)),
            ],
          ),
          const Divider(height: 24),
          child,
        ],
      ),
    );
  }

  Widget _buildBodyText(bool isDark, String text) {
    return Text(text, style: const TextStyle(fontFamily: 'Cairo', fontSize: 13, height: 1.6));
  }

  Widget _buildBullet(bool isDark, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(text, style: const TextStyle(fontFamily: 'Cairo', fontSize: 13))),
        ],
      ),
    );
  }

  Widget _buildFooter(bool isDark) {
    return Center(
      child: Text('آخر تحديث: أبريل 2026', style: TextStyle(fontFamily: 'Cairo', fontSize: 11, color: isDark ? Colors.white54 : Colors.grey[500])),
    );
  }
}
