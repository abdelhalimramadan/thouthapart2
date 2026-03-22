import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:thotha_mobile_app/core/helpers/shared_pref_helper.dart';
import 'package:thotha_mobile_app/core/networking/api_service.dart';

import '../../../../core/routing/routes.dart';

class AccountDeletionScreen extends StatefulWidget {
  const AccountDeletionScreen({Key? key}) : super(key: key);

  @override
  State<AccountDeletionScreen> createState() => _AccountDeletionScreenState();
}

class _AccountDeletionScreenState extends State<AccountDeletionScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  String? _errorMessage; // ← inline error shown in UI
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  static const _darkBlue = Color(0xFF021433);
  static const _gradientEnd = Color(0xFF0A3A7A);

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.1),
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

  Future<void> _deleteAccount() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final result = await ApiService().deleteDoctor();

      if (result['success'] == true) {
        // حذف جميع البيانات من الـ cache
        await SharedPrefHelper.clearAllData(); // حذف SharedPreferences
        await SharedPrefHelper
            .clearAllSecuredData(); // حذف FlutterSecureStorage (التوكن)
        if (!mounted) return;
        _showSnack('تم حذف الحساب بنجاح');
        await Future.delayed(const Duration(seconds: 1));
        if (!mounted) return;
        Navigator.of(context).pushNamedAndRemoveUntil(
          Routes.loginScreen,
          (Route<dynamic> route) => false,
        );
      } else {
        final code = result['statusCode'] as int?;
        final backendError = result['error']?.toString();
        final String msg;
        if (backendError != null && backendError.isNotEmpty) {
          msg = backendError;
        } else if (code == 400) {
          msg = 'طلب غير صحيح، تأكد من البيانات';
        } else if (code == 401) {
          msg = 'غير مصرح: يرجى تسجيل الدخول مجدداً';
        } else if (code == 403) {
          msg = 'ممنوع الوصول، تأكد من صلاحياتك';
        } else if (code == 404) {
          msg = 'الطبيب غير موجود';
        } else {
          msg = result['error'] ?? 'فشل في حذف الحساب';
        }
        setState(() => _errorMessage = msg);
      }
    } catch (_) {
      setState(() => _errorMessage = 'حدث خطأ أثناء الاتصال بالخادم');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _confirmDeleteAccount() async {
    if (_isLoading) return;
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final isDark = Theme.of(dialogContext).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF161B22) : Colors.white,
          title: Text(
            'تأكيد حذف الحساب',
            style: TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.w700,
                fontSize: 18.sp),
          ),
          content: Text(
            'هل أنت متأكد أنك تريد حذف الحساب نهائياً؟ هذا الإجراء لا يمكن التراجع عنه.',
            style: TextStyle(fontFamily: 'Cairo', height: 1.5, fontSize: 14.sp),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text('إلغاء',
                  style: TextStyle(fontFamily: 'Cairo', fontSize: 14.sp)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[700],
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r)),
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text('حذف',
                  style: TextStyle(
                      fontFamily: 'Cairo', fontSize: 14.sp, color: Colors.white)),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true) {
      await _deleteAccount();
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg,
            style: TextStyle(fontFamily: 'Cairo', fontSize: 14.sp)),
        backgroundColor: isError ? Colors.red[700] : Colors.green[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
        margin: EdgeInsets.all(16.r),
      ),
    );
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
            // ─── Custom App Bar ───────────────────────────────────────────────
            SliverAppBar(
              expandedHeight: 180.h,
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
                      // Decorative circles
                      Positioned(
                        top: -30.h,
                        left: -30.w,
                        child: Container(
                          width: 140.w,
                          height: 140.w,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.04),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 20.h,
                        left: 60.w,
                        child: Container(
                          width: 80.w,
                          height: 80.w,
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
                            // Warning icon
                            Container(
                              width: 60.r,
                              height: 60.r,
                              decoration: BoxDecoration(
                                color: Colors.red.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: Colors.red.withValues(alpha: 0.4),
                                    width: 2.w),
                              ),
                              child: Icon(
                                Icons.delete_forever_rounded,
                                color: Colors.redAccent,
                                size: 30.r,
                              ),
                            ),
                            SizedBox(height: 10.h),
                            Text(
                              'حذف الحساب',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontWeight: FontWeight.w700,
                                fontSize: 20.sp,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              'هذا الإجراء لا يمكن التراجع عنه',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 13.sp,
                                color: Colors.white.withValues(alpha: 0.65),
                              ),
                            ),
                            SizedBox(height: 20.h),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              leading: Padding(
                padding: EdgeInsets.only(right: 8.w),
                child: IconButton(
                  icon: Container(
                    width: 36.r,
                    height: 36.r,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Icon(Icons.arrow_back_ios_new_rounded,
                        color: Colors.white, size: 16.r),
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
                    padding: EdgeInsets.all(16.r),
                    child: Column(
                      children: [
                        SizedBox(height: 4.h),

                        // ── Warning Card ────────────────────────────────────
                        _buildWarningCard(isDark),
                        SizedBox(height: 16.h),

                        // ── What Will Be Deleted ─────────────────────────
                        _buildWillBeDeletedCard(isDark),
                        SizedBox(height: 24.h),

                        // ── Delete Button ────────────────────────────────
                        Column(
                          children: [
                            if (_errorMessage != null)
                              Container(
                                alignment: Alignment.centerRight,
                                padding:
                                    EdgeInsets.symmetric(vertical: 8.h),
                                child: Text(
                                  _errorMessage!,
                                  style: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: 14.sp,
                                    color: Colors.redAccent,
                                  ),
                                ),
                              ),
                            _buildDeleteButton(),
                          ],
                        ),
                        SizedBox(height: 12.h),

                        // ── Cancel Button ────────────────────────────────
                        _buildCancelButton(isDark),

                        SizedBox(
                            height: MediaQuery.of(context).padding.bottom + 24.h),
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

  // ── Warning Card ──────────────────────────────────────────────────────────
  Widget _buildWarningCard(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            Colors.red.withValues(alpha: isDark ? 0.18 : 0.08),
            Colors.orange.withValues(alpha: isDark ? 0.10 : 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.red.withValues(alpha: 0.25)),
      ),
      padding: EdgeInsets.all(16.r),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40.r,
            height: 40.r,
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(Icons.warning_amber_rounded,
                color: Colors.redAccent, size: 22.r),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'تحذير مهم',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w700,
                    fontSize: 14.sp,
                    color: Colors.redAccent,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'حذف الحساب إجراء دائم ولا يمكن التراجع عنه. ستفقد جميع بياناتك وسجلاتك بشكل نهائي.',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 13.sp,
                    height: 1.6,
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

  // ── What Will Be Deleted Card ─────────────────────────────────────────────
  Widget _buildWillBeDeletedCard(bool isDark) {
    final items = [
      (Icons.person_outline, 'بيانات الملف الشخصي'),
      (Icons.event_note_outlined, 'سجل الحجوزات والمواعيد'),
      (Icons.medical_services_outlined, 'بيانات الحالات الطبية'),
      (Icons.chat_bubble_outline, 'محادثات ورسائل التطبيق'),
      (Icons.notifications_none_outlined, 'الإشعارات والتنبيهات'),
    ];

    return _buildSectionCard(
      isDark: isDark,
      title: 'ما الذي سيتم حذفه؟',
      icon: Icons.info_outline_rounded,
      child: Column(
        children: items.map((item) {
          return Padding(
            padding: EdgeInsets.symmetric(vertical: 8.h),
            child: Row(
              children: [
                Container(
                  width: 32.r,
                  height: 32.r,
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Icon(item.$1, size: 16.r, color: Colors.red[400]),
                ),
                SizedBox(width: 12.w),
                Text(
                  item.$2,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white70 : const Color(0xFF374151),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDeleteButton() {
    return SizedBox(
      width: double.infinity,
      height: 52.h,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.red[700]!, Colors.red[500]!],
          ),
          borderRadius: BorderRadius.circular(14.r),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withValues(alpha: 0.35),
              blurRadius: 12.r,
              offset: Offset(0, 4.h),
            ),
          ],
        ),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
          ),
          onPressed: _isLoading ? null : _confirmDeleteAccount,
          child: _isLoading
              ? SizedBox(
                  width: 22.r,
                  height: 22.r,
                  child: const CircularProgressIndicator(
                      strokeWidth: 2.5, color: Colors.white))
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.delete_forever_rounded,
                        color: Colors.white, size: 20.r),
                    SizedBox(width: 8.w),
                    Text(
                      'حذف الحساب نهائياً',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.w700,
                        fontSize: 15.sp,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  // ── Cancel Button ─────────────────────────────────────────────────────────
  Widget _buildCancelButton(bool isDark) {
    return SizedBox(
      width: double.infinity,
      height: 50.h,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          side: BorderSide(
            color: isDark ? Colors.grey[700]! : const Color(0xFFD1D5DB),
          ),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
        ),
        onPressed: () => Navigator.of(context).pop(),
        child: Text(
          'العودة للملف الشخصي',
          style: TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.w600,
            fontSize: 14.sp,
            color: isDark ? Colors.white70 : const Color(0xFF374151),
          ),
        ),
      ),
    );
  }

  // ── Section Card Helper ───────────────────────────────────────────────────
  Widget _buildSectionCard({
    required bool isDark,
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161B22) : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
            color: isDark ? Colors.grey[800]! : const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.2)
                : Colors.grey.withValues(alpha: 0.07),
            blurRadius: 8.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 0),
            child: Row(
              children: [
                Icon(icon, size: 16.r, color: const Color(0xFF021433)),
                SizedBox(width: 6.w),
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w700,
                    fontSize: 13.sp,
                    color: isDark ? Colors.white70 : const Color(0xFF021433),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 6.h),
          Divider(
              height: 1,
              color: isDark ? Colors.grey[800] : const Color(0xFFE5E7EB)),
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 14.h),
            child: child,
          ),
        ],
      ),
    );
  }
}
