import 'package:flutter/material.dart';
import 'package:thoutha_mobile_app/features/home_screen/ui/drawer/drawer.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;

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
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Last update date
  late final String _lastUpdated;

  @override
  void initState() {
    super.initState();
    _lastUpdated = 'privacy_policy.march_2_2026'.tr();
    _animController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: Offset(0, 0.08),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic));
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
    final theme = Theme.of(context);

    return Directionality(
      textDirection: context.locale.languageCode == 'ar'
          ? TextDirection.rtl
          : TextDirection.ltr,
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: theme.scaffoldBackgroundColor,
        drawer: HomeDrawer(),
        body: CustomScrollView(
          slivers: [
            // ─── Custom SliverAppBar ──────────────────────────────────────────
            SliverAppBar(
              expandedHeight: 140,
              pinned: true,
              automaticallyImplyLeading: false,
              backgroundColor: theme.colorScheme.surface,
              foregroundColor: theme.colorScheme.onSurface,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                  ),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'doctor.privacy_policy'.tr(),
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontFamily: 'Cairo',
                                    fontWeight: FontWeight.w700,
                                    fontSize: 18,
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
                            SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              leading: Padding(
                padding: const EdgeInsetsDirectional.only(end: 8),
                child: Builder(
                  builder: (context) => IconButton(
                    icon: Icon(Icons.menu, size: 24),
                    onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                  ),
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
                        SizedBox(height: 4),

                        // ── Intro Banner ────────────────────────────────────
                        _buildIntroBanner(isDark),
                        SizedBox(height: 14),

                        // ── Section 1 ───────────────────────────────────────
                        _buildSection(
                          isDark: isDark,
                          number: 'privacy_policy.str_1'.tr(),
                          title: 'privacy_policy.data_we_collect'.tr(),
                          icon: Icons.storage_outlined,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildBodyText(
                                isDark,
                                'privacy_policy.the_application_may_collect'.tr(),
                              ),
                              SizedBox(height: 10),
                              _buildBullet(
                                  isDark, 'privacy_policy.the_full_name'.tr()),
                              _buildBullet(isDark, 'doctor.phone_number'.tr()),
                              _buildBullet(isDark,
                                  'privacy_policy.the_selected_governorate'.tr()),
                              _buildBullet(
                                  isDark, 'privacy_policy.booking_details'.tr()),
                              _buildBullet(isDark,
                                  'privacy_policy.login_data_for_doctors'.tr()),
                              SizedBox(height: 10),
                              _buildNote(
                                isDark,
                                'privacy_policy.the_application_does_not'.tr(),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 12),

                        // ── Section 2 ───────────────────────────────────────
                        _buildSection(
                          isDark: isDark,
                          number: 'privacy_policy.str_2'.tr(),
                          title: 'privacy_policy.how_to_use_the'.tr(),
                          icon: Icons.settings_outlined,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildBodyText(
                                isDark,
                                'privacy_policy.the_data_is_only'.tr(),
                              ),
                              SizedBox(height: 10),
                              _buildBullet(isDark,
                                  'privacy_policy.completing_the_reservation_process'.tr()),
                              _buildBullet(isDark,
                                  'privacy_policy.sending_notifications_to_the'.tr()),
                              _buildBullet(isDark,
                                  'privacy_policy.improve_the_user_experience'.tr()),
                              _buildBullet(isDark,
                                  'privacy_policy.helping_the_user_through'.tr()),
                              SizedBox(height: 10),
                              _buildNote(
                                isDark,
                                'privacy_policy.user_data_is_not'.tr(),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 12),

                        // ── Section 3 ───────────────────────────────────────
                        _buildSection(
                          isDark: isDark,
                          number: 'privacy_policy.str_3'.tr(),
                          title: 'privacy_policy.data_protection'.tr(),
                          icon: Icons.lock_outline_rounded,
                          child: _buildBodyText(
                            isDark,
                            'privacy_policy.we_are_committed_to'.tr(),
                          ),
                        ),
                        SizedBox(height: 12),

                        // ── Section 4 ───────────────────────────────────────
                        _buildSection(
                          isDark: isDark,
                          number: 'privacy_policy.str_4'.tr(),
                          title: 'privacy_policy.user_rights'.tr(),
                          icon: Icons.person_outline_rounded,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildBodyText(isDark,
                                  'privacy_policy.the_user_has_the'.tr()),
                              SizedBox(height: 10),
                              _buildBullet(isDark,
                                  'privacy_policy.request_to_modify_his'.tr()),
                              _buildBullet(isDark,
                                  'privacy_policy.request_to_delete_his'.tr()),
                              _buildBullet(isDark,
                                  'privacy_policy.contact_us_if_you'.tr()),
                            ],
                          ),
                        ),
                        SizedBox(height: 12),

                        // ── Section 5 ───────────────────────────────────────
                        _buildSection(
                          isDark: isDark,
                          number: 'privacy_policy.str_5'.tr(),
                          title: 'privacy_policy.policy_approval'.tr(),
                          icon: Icons.check_circle_outline_rounded,
                          child: _buildBodyText(
                            isDark,
                            'privacy_policy.by_using_the_thoutha'.tr(),
                          ),
                        ),
                        SizedBox(height: 20),

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
          begin: AlignmentDirectional.topEnd,
          end: AlignmentDirectional.bottomStart,
          colors: [
            Color(0xFF021433).withValues(alpha: isDark ? 0.35 : 0.07),
            Color(0xFF0A3A7A).withValues(alpha: isDark ? 0.18 : 0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Color(0xFF021433).withOpacity(0.18),
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
              color: Color(0xFF021433).withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.shield_outlined,
              color: isDark ? Colors.white : Color(0xFF021433),
              size: 22,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'privacy_policy.thutha_application'.tr(),
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: isDark ? Colors.white : Color(0xFF021433),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'privacy_policy.the_thoutha_application_is'.tr(),
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 13,
                    height: 1.7,
                    color: isDark ? Colors.white70 : Color(0xFF374151),
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
        color: isDark ? Color(0xFF161B22) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Color(0xFFE5E7EB),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.2)
                : Colors.grey.withOpacity(0.07),
            blurRadius: 8,
            offset: Offset(0, 2),
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
                    color: Color(0xFF021433),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    number,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Icon(icon, size: 16, color: isDark ? Colors.white70 : Color(0xFF021433)),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.w700,
                      fontSize: 13.5,
                      color: isDark ? Colors.white : Color(0xFF021433),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 8),
          Divider(
            height: 1,
            color: isDark ? Colors.grey[800] : Color(0xFFE5E7EB),
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
        color: isDark ? Colors.white70 : Color(0xFF374151),
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
            decoration: BoxDecoration(
              color: isDark ? Colors.white70 : Color(0xFF021433),
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 13.5,
                height: 1.65,
                color: isDark ? Colors.white70 : Color(0xFF374151),
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
        color: Color(0xFF021433).withValues(alpha: isDark ? 0.20 : 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Color(0xFF021433).withOpacity(0.15),
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
          color: isDark ? Colors.white70 : Color(0xFF021433),
        ),
      ),
    );
  }

  // ── Footer ─────────────────────────────────────────────────────────────────
  Widget _buildFooter(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: AlignmentDirectional.topEnd,
          end: AlignmentDirectional.bottomStart,
          colors: [
            Color(0xFF021433).withValues(alpha: isDark ? 0.40 : 0.06),
            Color(0xFF0A3A7A).withValues(alpha: isDark ? 0.25 : 0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Color(0xFF021433).withOpacity(0.15),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Icon(
            Icons.verified_user_outlined,
            color: isDark ? Colors.white70 : Color(0xFF021433),
            size: 28,
          ),
          SizedBox(height: 8),
          Text(
            'privacy_policy.by_using_the_thoutha_1'.tr(),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 13,
              height: 1.65,
              color: isDark ? Colors.white60 : Color(0xFF374151),
            ),
          ),
          SizedBox(height: 8),
          Text(
            'privacy_policy.policy_updated_on_march'.tr(),
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : Color(0xFF021433),
            ),
          ),
          SizedBox(height: 8),
          Text(
            '${'privacy_policy.last_updated_colon'.tr()} $_lastUpdated',
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
