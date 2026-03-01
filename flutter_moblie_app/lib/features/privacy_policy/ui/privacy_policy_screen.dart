import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatefulWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  State<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  static const _darkBlue = Color(0xFF021433);
  static const _gradientEnd = Color(0xFF0A3A7A);

  // Last update date
  static const _lastUpdated = '٢ مارس ٢٠٢٦';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0D1117) : const Color(0xFFF5F6FA),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: CustomScrollView(
          slivers: [
            // ─── Custom SliverAppBar ──────────────────────────────────────────
            SliverAppBar(
              expandedHeight: 200,
              pinned: true,
              automaticallyImplyLeading: false,
              backgroundColor: _darkBlue,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                      colors: [_darkBlue, _gradientEnd],
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Decorative background circles
                      Positioned(
                        top: -40,
                        left: -40,
                        child: Container(
                          width: 160,
                          height: 160,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.04),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: -20,
                        right: -20,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.03),
                          ),
                        ),
                      ),
                      // Content
                      Positioned.fill(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            // Shield icon
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.25),
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                Icons.shield_outlined,
                                color: Colors.white,
                                size: 32,
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'سياسة الخصوصية',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontWeight: FontWeight.w700,
                                fontSize: 21,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'آخر تحديث: $_lastUpdated',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 12.5,
                                color: Colors.white.withValues(alpha: 0.65),
                              ),
                            ),
                            const SizedBox(height: 22),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              leading: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: IconButton(
                  icon: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),

            // ─── Body Content ─────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const SizedBox(height: 4),

                        // ── Intro Banner ────────────────────────────────────
                        _buildIntroBanner(isDark),
                        const SizedBox(height: 14),

                        // ── Section 1 ───────────────────────────────────────
                        _buildSection(
                          isDark: isDark,
                          number: '١',
                          title: 'البيانات التي نقوم بجمعها',
                          icon: Icons.storage_outlined,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildBodyText(
                                isDark,
                                'قد يقوم التطبيق بجمع البيانات التالية:',
                              ),
                              const SizedBox(height: 10),
                              _buildBullet(isDark, 'الاسم الثلاثي'),
                              _buildBullet(isDark, 'رقم الهاتف'),
                              _buildBullet(isDark, 'المحافظة المختارة'),
                              _buildBullet(isDark, 'تفاصيل الحجز'),
                              _buildBullet(isDark, 'بيانات تسجيل الدخول (للدكاترة)'),
                              const SizedBox(height: 10),
                              _buildNote(
                                isDark,
                                '🔒 لا يقوم التطبيق بجمع أو تخزين أي سجلات طبية حساسة.',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // ── Section 2 ───────────────────────────────────────
                        _buildSection(
                          isDark: isDark,
                          number: '٢',
                          title: 'كيفية استخدام البيانات',
                          icon: Icons.settings_outlined,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildBodyText(
                                isDark,
                                'يتم استخدام البيانات فقط من أجل:',
                              ),
                              const SizedBox(height: 10),
                              _buildBullet(isDark,
                                  'إتمام عملية الحجز بين المريض وطالب طب الأسنان'),
                              _buildBullet(isDark,
                                  'إرسال إشعارات للدكتور بوجود حجز جديد'),
                              _buildBullet(isDark,
                                  'تحسين تجربة المستخدم داخل التطبيق'),
                              _buildBullet(isDark,
                                  'مساعدة المستخدم من خلال الشات بوت'),
                              const SizedBox(height: 10),
                              _buildNote(
                                isDark,
                                '🚫 لا يتم بيع أو مشاركة بيانات المستخدمين مع أي طرف ثالث.',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // ── Section 3 ───────────────────────────────────────
                        _buildSection(
                          isDark: isDark,
                          number: '٣',
                          title: 'حماية البيانات',
                          icon: Icons.lock_outline_rounded,
                          child: _buildBodyText(
                            isDark,
                            'نلتزم باتخاذ الإجراءات التقنية المناسبة لحماية بيانات المستخدمين من الوصول غير المصرح به أو الاستخدام غير القانوني.',
                          ),
                        ),
                        const SizedBox(height: 12),

                        // ── Section 4 ───────────────────────────────────────
                        _buildSection(
                          isDark: isDark,
                          number: '٤',
                          title: 'حقوق المستخدم',
                          icon: Icons.person_outline_rounded,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildBodyText(isDark, 'يحق للمستخدم:'),
                              const SizedBox(height: 10),
                              _buildBullet(isDark, 'طلب تعديل بياناته'),
                              _buildBullet(isDark, 'طلب حذف بياناته'),
                              _buildBullet(isDark,
                                  'التواصل معنا في حال وجود أي استفسار متعلق بالخصوصية'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // ── Section 5 ───────────────────────────────────────
                        _buildSection(
                          isDark: isDark,
                          number: '٥',
                          title: 'الموافقة على السياسة',
                          icon: Icons.check_circle_outline_rounded,
                          child: _buildBodyText(
                            isDark,
                            'باستخدامك لتطبيق ثوثة، فإنك توافق على سياسة الخصوصية هذه.',
                          ),
                        ),
                        const SizedBox(height: 20),

                        // ── Footer ───────────────────────────────────────────
                        _buildFooter(isDark),

                        SizedBox(
                            height: MediaQuery.of(context).padding.bottom + 24),
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

  // ── Intro Banner ──────────────────────────────────────────────────────────
  Widget _buildIntroBanner(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            const Color(0xFF021433).withValues(alpha: isDark ? 0.35 : 0.07),
            const Color(0xFF0A3A7A).withValues(alpha: isDark ? 0.18 : 0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF021433).withValues(alpha: 0.18),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFF021433).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.shield_outlined,
              color: Color(0xFF021433),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'تطبيق ثوثة',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: Color(0xFF021433),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'يحرص تطبيق ثوثة على حماية خصوصية مستخدميه من المرضى وطلاب طب الأسنان. توضح هذه السياسة كيفية جمع البيانات واستخدامها وحمايتها داخل التطبيق.',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 13,
                    height: 1.7,
                    color: isDark ? Colors.white70 : const Color(0xFF374151),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Section Card ─────────────────────────────────────────────────────────
  Widget _buildSection({
    required bool isDark,
    required String number,
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161B22) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : const Color(0xFFE5E7EB),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.2)
                : Colors.grey.withValues(alpha: 0.07),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                // Number badge
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: const Color(0xFF021433),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    number,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(icon, size: 16, color: const Color(0xFF021433)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.w700,
                      fontSize: 13.5,
                      color: isDark ? Colors.white : const Color(0xFF021433),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Divider(
            height: 1,
            color: isDark ? Colors.grey[800] : const Color(0xFFE5E7EB),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: child,
          ),
        ],
      ),
    );
  }

  // ── Body Text ─────────────────────────────────────────────────────────────
  Widget _buildBodyText(bool isDark, String text) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: 'Cairo',
        fontSize: 13.5,
        height: 1.75,
        color: isDark ? Colors.white70 : const Color(0xFF374151),
      ),
    );
  }

  // ── Bullet Item ───────────────────────────────────────────────────────────
  Widget _buildBullet(bool isDark, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 7),
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              color: Color(0xFF021433),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 13.5,
                height: 1.65,
                color: isDark ? Colors.white70 : const Color(0xFF374151),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Note / Highlight Box ──────────────────────────────────────────────────
  Widget _buildNote(bool isDark, String text) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF021433).withValues(alpha: isDark ? 0.20 : 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFF021433).withValues(alpha: 0.15),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 13,
          height: 1.6,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white70 : const Color(0xFF021433),
        ),
      ),
    );
  }

  // ── Footer ─────────────────────────────────────────────────────────────────
  Widget _buildFooter(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            const Color(0xFF021433).withValues(alpha: isDark ? 0.40 : 0.06),
            const Color(0xFF0A3A7A).withValues(alpha: isDark ? 0.25 : 0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF021433).withValues(alpha: 0.15),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Icon(
            Icons.verified_user_outlined,
            color: Color(0xFF021433),
            size: 28,
          ),
          const SizedBox(height: 8),
          Text(
            'باستخدامك لتطبيق ثوثة، فإنك توافق تلقائياً على سياسة الخصوصية هذه.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 13,
              height: 1.65,
              color: isDark ? Colors.white60 : const Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'آخر تحديث: $_lastUpdated',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 11.5,
              color: isDark ? Colors.white38 : Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}
