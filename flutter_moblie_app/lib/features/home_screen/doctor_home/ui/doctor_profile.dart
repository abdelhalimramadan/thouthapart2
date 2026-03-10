import 'package:flutter/material.dart';
import 'package:thotha_mobile_app/core/helpers/shared_pref_helper.dart';
import 'package:thotha_mobile_app/core/networking/api_service.dart';
import 'package:thotha_mobile_app/core/routing/routes.dart';
import 'package:thotha_mobile_app/core/theming/colors.dart';
import 'package:thotha_mobile_app/features/home_screen/doctor_home/ui/account_deletion_screen.dart';
import 'package:thotha_mobile_app/features/home_screen/doctor_home/ui/doctor_home_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DoctorProfile — view-only profile page with edit button
// ─────────────────────────────────────────────────────────────────────────────
class DoctorProfile extends StatefulWidget {
  const DoctorProfile({super.key});

  @override
  State<DoctorProfile> createState() => _DoctorProfileState();
}

class _DoctorProfileState extends State<DoctorProfile> {
  String _firstName  = '';
  String _lastName   = '';
  String _email      = '';
  String _phone      = '';
  String _university = '';
  String _studyYear  = '';
  String _city       = '';
  String _category   = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    setState(() => _isLoading = true);
    try {
      final firstName   = await SharedPrefHelper.getString('first_name')  ?? '';
      final lastName    = await SharedPrefHelper.getString('last_name')   ?? '';
      final email       = await SharedPrefHelper.getString('email')       ?? '';
      final phone       = await SharedPrefHelper.getString('phone')       ?? '';
      final faculty     = await SharedPrefHelper.getString('faculty')     ?? '';
      final year        = await SharedPrefHelper.getString('year')        ?? '';
      final governorate = await SharedPrefHelper.getString('governorate') ?? '';
      final category    = await SharedPrefHelper.getString('category')    ?? '';

      if (mounted) {
        setState(() {
          _firstName  = firstName;
          _lastName   = lastName;
          _email      = email;
          _phone      = phone;
          _university = faculty;
          _studyYear  = year;
          _city       = governorate;
          _category   = category;
          _isLoading  = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showEditDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditProfileSheet(
        firstName:  _firstName,
        lastName:   _lastName,
        phone:      _phone,
        university: _university,
        studyYear:  _studyYear,
        city:       _city,
        category:   _category,
        onSaved: _loadProfileData,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF2D2D2D) : Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'الملف الشخصي',
          style: TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: isDark ? Colors.white : Colors.black),
          onPressed: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                settings: const RouteSettings(name: 'doctor-home'),
                builder: (_) => const DoctorHomeScreen(),
              ),
            );
          },
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.edit_outlined,
                color: isDark ? Colors.white : ColorsManager.mainBlue),
            tooltip: 'تعديل الملف الشخصي',
            onPressed: _showEditDialog,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildField('الاسم الأول',        _firstName),
                  const SizedBox(height: 16),
                  _buildField('اسم العائلة',        _lastName),
                  const SizedBox(height: 16),
                  _buildField('البريد الإلكتروني', _email),
                  const SizedBox(height: 16),
                  _buildField('رقم الهاتف',         _phone),
                  const SizedBox(height: 16),
                  _buildField('الجامعة',             _university),
                  const SizedBox(height: 16),
                  _buildField('السنة الدراسية',     _studyYear),
                  const SizedBox(height: 16),
                  _buildField('المحافظة',            _city),
                  const SizedBox(height: 16),
                  _buildField('التخصص',              _category),
                  const SizedBox(height: 24),

                  // ── Edit profile ──────────────────────────────
                  _buildActionButton(
                    label: 'تعديل الملف الشخصي',
                    icon: Icons.edit_note_rounded,
                    gradientColors: const [Color(0xFF1D61E7), Color(0xFF0B8FAC)],
                    onTap: _showEditDialog,
                  ),
                  const SizedBox(height: 16),

                  // ── Change password ───────────────────────────
                  _buildActionButton(
                    label: 'تغيير كلمة المرور',
                    icon: Icons.lock_outline,
                    gradientColors: const [Color(0xFF667EEA), Color(0xFF764BA2)],
                    onTap: () => Navigator.of(context)
                        .pushNamed(Routes.changePasswordScreen),
                  ),
                  const SizedBox(height: 16),

                  // ── Delete account ────────────────────────────
                  _buildActionButton(
                    label: 'حذف الحساب',
                    icon: Icons.delete_outline,
                    gradientColors: const [Color(0xFFE53935), Color(0xFFD32F2F)],
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const AccountDeletionScreen()),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _buildField(String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 4, bottom: 8),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
            textAlign: TextAlign.right,
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2D2D2D) : Colors.white,
            border: Border.all(
              color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.3)
                    : Colors.grey.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            value.isNotEmpty ? value : 'غير محدد',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: value.isNotEmpty
                  ? (isDark ? Colors.white : Colors.black)
                  : Colors.grey,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required List<Color> gradientColors,
    required VoidCallback onTap,
  }) {
    return Container(
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: gradientColors,
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: gradientColors[0].withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 20, color: Colors.white),
        label: Text(
          label,
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 16,
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _EditProfileSheet — modal bottom sheet with editable fields
// ─────────────────────────────────────────────────────────────────────────────
class _EditProfileSheet extends StatefulWidget {
  final String firstName;
  final String lastName;
  final String phone;
  final String university;
  final String studyYear;
  final String city;
  final String category;
  final VoidCallback onSaved;

  const _EditProfileSheet({
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.university,
    required this.studyYear,
    required this.city,
    required this.category,
    required this.onSaved,
  });

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _firstNameCtrl;
  late final TextEditingController _lastNameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _universityCtrl;
  late final TextEditingController _yearCtrl;
  late final TextEditingController _cityCtrl;
  late final TextEditingController _categoryCtrl;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _firstNameCtrl  = TextEditingController(text: widget.firstName);
    _lastNameCtrl   = TextEditingController(text: widget.lastName);
    _phoneCtrl      = TextEditingController(text: widget.phone);
    _universityCtrl = TextEditingController(text: widget.university);
    _yearCtrl       = TextEditingController(text: widget.studyYear);
    _cityCtrl       = TextEditingController(text: widget.city);
    _categoryCtrl   = TextEditingController(text: widget.category);
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _phoneCtrl.dispose();
    _universityCtrl.dispose();
    _yearCtrl.dispose();
    _cityCtrl.dispose();
    _categoryCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    // Get doctor ID
    int doctorId = await SharedPrefHelper.getInt('doctor_id');
    if (doctorId == 0) {
      final s = await SharedPrefHelper.getString('doctor_id');
      doctorId = int.tryParse(s ?? '') ?? 0;
    }

    final body = <String, dynamic>{
      if (doctorId != 0) 'id': doctorId,
      'firstName':      _firstNameCtrl.text.trim(),
      'lastName':       _lastNameCtrl.text.trim(),
      'phoneNumber':    _phoneCtrl.text.trim(),
      'universityName': _universityCtrl.text.trim(),
      'studyYear':      _yearCtrl.text.trim(),
      'cityName':       _cityCtrl.text.trim(),
      'categoryName':   _categoryCtrl.text.trim(),
    };

    final result = await ApiService().updateDoctor(body);

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (result['success'] == true) {
      // Persist to SharedPreferences
      await SharedPrefHelper.setData('first_name',  _firstNameCtrl.text.trim());
      await SharedPrefHelper.setData('last_name',   _lastNameCtrl.text.trim());
      await SharedPrefHelper.setData('phone',       _phoneCtrl.text.trim());
      await SharedPrefHelper.setData('faculty',     _universityCtrl.text.trim());
      await SharedPrefHelper.setData('year',        _yearCtrl.text.trim());
      await SharedPrefHelper.setData('governorate', _cityCtrl.text.trim());
      await SharedPrefHelper.setData('category',    _categoryCtrl.text.trim());

      if (!mounted) return;
      Navigator.pop(context);
      widget.onSaved();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم تحديث البيانات بنجاح ✅',
              style: TextStyle(fontFamily: 'Cairo')),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result['error']?.toString() ?? 'فشل التحديث',
            style: const TextStyle(fontFamily: 'Cairo'),
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark    = Theme.of(context).brightness == Brightness.dark;
    final width     = MediaQuery.of(context).size.width;
    final bottomPad = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 12, 20, bottomPad + 24),
      child: SingleChildScrollView(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Drag handle ───────────────────────────────
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                Center(
                  child: Text(
                    'تعديل الملف الشخصي',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: width * 0.05,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Divider(color: isDark ? Colors.grey[700] : Colors.grey[200]),
                const SizedBox(height: 12),

                // ── Editable fields ───────────────────────────
                _field(label: 'الاسم الأول',    ctrl: _firstNameCtrl,  icon: Icons.person_outline,            isDark: isDark),
                _field(label: 'اسم العائلة',    ctrl: _lastNameCtrl,   icon: Icons.person_outline,            isDark: isDark),
                _field(label: 'رقم الهاتف',     ctrl: _phoneCtrl,      icon: Icons.phone_outlined,            isDark: isDark, keyboardType: TextInputType.phone),
                _field(label: 'الجامعة',         ctrl: _universityCtrl, icon: Icons.school_outlined,           isDark: isDark),
                _field(label: 'السنة الدراسية', ctrl: _yearCtrl,       icon: Icons.calendar_month_outlined,   isDark: isDark),
                _field(label: 'المحافظة',        ctrl: _cityCtrl,       icon: Icons.location_city_outlined,    isDark: isDark),
                _field(label: 'التخصص',          ctrl: _categoryCtrl,   icon: Icons.medical_services_outlined, isDark: isDark),

                const SizedBox(height: 24),

                // ── Save button ───────────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : _save,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.save_outlined, color: Colors.white),
                    label: Text(
                      _isSaving ? 'جاري الحفظ...' : 'حفظ التغييرات',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: width * 0.042,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorsManager.mainBlue,
                      disabledBackgroundColor:
                          ColorsManager.mainBlue.withValues(alpha: 0.6),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field({
    required String label,
    required TextEditingController ctrl,
    required IconData icon,
    required bool isDark,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: ctrl,
        keyboardType: keyboardType,
        textDirection: TextDirection.rtl,
        style: TextStyle(
          fontFamily: 'Cairo',
          color: isDark ? Colors.white : Colors.black87,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            fontFamily: 'Cairo',
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
          prefixIcon: Icon(icon, color: ColorsManager.mainBlue, size: 20),
          filled: true,
          fillColor: isDark ? const Color(0xFF2D2D2D) : const Color(0xFFF9FAFB),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
                color: isDark ? Colors.grey[700]! : Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
                color: isDark ? Colors.grey[700]! : Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: ColorsManager.mainBlue, width: 1.5),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        ),
        validator: (v) =>
            (v == null || v.trim().isEmpty) ? 'هذا الحقل مطلوب' : null,
      ),
    );
  }
}
