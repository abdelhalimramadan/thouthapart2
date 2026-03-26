import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:thoutha_mobile_app/core/di/dependency_injection.dart';
import 'package:thoutha_mobile_app/core/networking/models/category_model.dart';
import 'package:thoutha_mobile_app/core/networking/models/city_model.dart';
import 'package:thoutha_mobile_app/core/networking/models/university_model.dart';
import 'package:thoutha_mobile_app/features/doctor/ui/account_deletion_screen.dart';
import 'package:thoutha_mobile_app/features/forgot_password/ui/change_password_screen.dart';
import 'package:thoutha_mobile_app/features/profile/data/models/doctor_profile_model.dart';
import 'package:thoutha_mobile_app/features/profile/logic/profile_cubit.dart';
import 'package:thoutha_mobile_app/features/profile/logic/profile_state.dart';
import 'package:thoutha_mobile_app/features/requests/ui/my_requests_screen.dart';

import '../../doctor/ui/doctor_home_screen.dart';

class DoctorProfileScreen extends StatelessWidget {
  const DoctorProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<ProfileCubit>()..fetchProfile(),
      child: const DoctorProfileBody(),
    );
  }
}

class DoctorProfileBody extends StatefulWidget {
  const DoctorProfileBody({super.key});

  @override
  State<DoctorProfileBody> createState() => _DoctorProfileBodyState();
}

class _DoctorProfileBodyState extends State<DoctorProfileBody> {
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _universityCtrl = TextEditingController();
  final _yearCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _categoryCtrl = TextEditingController();

  late final FocusNode _firstNameFocusNode;
  late final FocusNode _lastNameFocusNode;
  late final FocusNode _emailFocusNode;
  late final FocusNode _phoneFocusNode;

  // Original values — set once when profile loads
  String _origFirstName = '';
  String _origLastName = '';
  String _origEmail = '';
  String _origUniversity = '';
  String _origYear = '';
  String _origCity = '';
  String _origPhone = '';
  String _origCategory = '';

  bool _hasChanges = false;
  bool _isSaving = false; // true while a save request is in-flight

  @override
  void initState() {
    super.initState();
    _firstNameFocusNode = FocusNode();
    _lastNameFocusNode = FocusNode();
    _emailFocusNode = FocusNode();
    _phoneFocusNode = FocusNode();
    _firstNameCtrl.addListener(_checkChanges);
    _lastNameCtrl.addListener(_checkChanges);
    _emailCtrl.addListener(_checkChanges);
    _universityCtrl.addListener(_checkChanges);
    _yearCtrl.addListener(_checkChanges);
    _cityCtrl.addListener(_checkChanges);
    _phoneCtrl.addListener(_checkChanges);
    _categoryCtrl.addListener(_checkChanges);
  }

  void _checkChanges() {
    final changed = _firstNameCtrl.text.trim() != _origFirstName ||
        _lastNameCtrl.text.trim() != _origLastName ||
        _emailCtrl.text.trim() != _origEmail ||
        _universityCtrl.text.trim() != _origUniversity ||
        _yearCtrl.text.trim() != _origYear ||
        _cityCtrl.text.trim() != _origCity ||
        _phoneCtrl.text.trim() != _origPhone ||
        _categoryCtrl.text.trim() != _origCategory;
    if (changed != _hasChanges) setState(() => _hasChanges = changed);
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _universityCtrl.dispose();
    _yearCtrl.dispose();
    _cityCtrl.dispose();
    _phoneCtrl.dispose();
    _categoryCtrl.dispose();
    _firstNameFocusNode.dispose();
    _lastNameFocusNode.dispose();
    _emailFocusNode.dispose();
    _phoneFocusNode.dispose();
    super.dispose();
  }

  bool _isValidEmail(String value) {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value);
  }

  bool _isValidPhone(String value) {
    final normalized = value.replaceAll(RegExp(r'[\s-]'), '');
    return RegExp(r'^\+?[0-9]{10,15}$').hasMatch(normalized);
  }

  String? _validateInputs() {
    final firstName = _firstNameCtrl.text.trim();
    final lastName = _lastNameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final university = _universityCtrl.text.trim();
    final year = _yearCtrl.text.trim();
    final city = _cityCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    final category = _categoryCtrl.text.trim();

    if (firstName.isEmpty || firstName.length < 2) {
      return 'يرجى إدخال الاسم الأول بشكل صحيح';
    }
    if (lastName.isEmpty || lastName.length < 2) {
      return 'يرجى إدخال اسم العائلة بشكل صحيح';
    }
    if (email.isEmpty || !_isValidEmail(email)) {
      return 'يرجى إدخال بريد إلكتروني صحيح';
    }
    if (phone.isEmpty || !_isValidPhone(phone)) {
      return 'يرجى إدخال رقم هاتف صحيح';
    }
    if (university.isEmpty) {
      return 'يرجى اختيار الجامعة';
    }
    if (year.isEmpty) {
      return 'يرجى اختيار السنة الدراسية';
    }
    if (city.isEmpty) {
      return 'يرجى اختيار المحافظة';
    }
    if (category.isEmpty) {
      return 'يرجى اختيار التخصص';
    }
    return null;
  }

  Future<void> _onSave() async {
    if (_isSaving) return;

    final validationError = _validateInputs();
    if (validationError != null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(validationError,
              style: const TextStyle(fontFamily: 'Cairo')),
          backgroundColor: Colors.red[700],
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    final cubit = context.read<ProfileCubit>();

    // Build update body - التوكن في headers يكفي للـ API
    final body = <String, dynamic>{
      'firstName': _firstNameCtrl.text.trim(),
      'lastName': _lastNameCtrl.text.trim(),
      'phoneNumber': _phoneCtrl.text.trim(),
      'email': _emailCtrl.text.trim(),
      'universityName': _universityCtrl.text.trim(),
      'studyYear': _yearCtrl.text.trim(),
      'cityName': _cityCtrl.text.trim(),
      'categoryName': _categoryCtrl.text.trim(),
    };

    if (!mounted) return;
    setState(() => _isSaving = true);
    cubit.updateProfile(body);
  }

  void _showSelectionDialog({
    required String title,
    required List<String> items,
    required TextEditingController controller,
  }) {
    showDialog(
      context: context,
      builder: (context) {
        String searchQuery = '';
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final filteredItems = items
                .where((item) =>
                    item.toLowerCase().contains(searchQuery.toLowerCase()))
                .toList();

            return Directionality(
              textDirection: TextDirection.rtl,
              child: AlertDialog(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.r)),
                title: Text(title,
                    style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold)),
                content: SizedBox(
                  width: double.maxFinite,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        onChanged: (val) =>
                            setDialogState(() => searchQuery = val),
                        textAlign: TextAlign.right,
                        decoration: InputDecoration(
                          hintText: 'بحث...',
                          hintStyle:
                              TextStyle(fontFamily: 'Cairo', fontSize: 14.sp),
                          prefixIcon: const Icon(Icons.search),
                          isDense: true,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.r)),
                        ),
                      ),
                      SizedBox(height: 12.h),
                      ConstrainedBox(
                        constraints: BoxConstraints(maxHeight: 300.h),
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: filteredItems.length,
                          separatorBuilder: (_, __) =>
                              Divider(height: 1, color: Colors.grey[200]),
                          itemBuilder: (context, index) {
                            return ListTile(
                              title: Text(
                                filteredItems[index],
                                style: TextStyle(
                                    fontFamily: 'Cairo', fontSize: 16.sp),
                                textAlign: TextAlign.right,
                              ),
                              onTap: () {
                                controller.text = filteredItems[index];
                                Navigator.pop(context);
                                // No auto-save — user must press save button
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'الملف الشخصي',
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: isDark ? Colors.white : Colors.black, size: 24.r),
          onPressed: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const DoctorHomeScreen()),
            );
          },
        ),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: BlocConsumer<ProfileCubit, ProfileState<DoctorProfileModel>>(
          listener: (context, state) {
            state.whenOrNull(
              success: (p, universities, cities, categories) {
                final firstName = p.firstName ?? '';
                final lastName = p.lastName ?? '';
                final email = p.email ?? '';
                final uni = p.faculty ?? '';
                final yr = p.year ?? '';
                final city = p.governorate ?? '';
                final phone = p.phone ?? '';
                final category = p.category ?? '';
                _firstNameCtrl.text = firstName;
                _lastNameCtrl.text = lastName;
                _emailCtrl.text = email;
                _universityCtrl.text = uni;
                _yearCtrl.text = yr;
                _cityCtrl.text = city;
                _phoneCtrl.text = phone;
                _categoryCtrl.text = category;
                _origFirstName = firstName;
                _origLastName = lastName;
                _origEmail = email;
                _origUniversity = uni;
                _origYear = yr;
                _origCity = city;
                _origPhone = phone;
                _origCategory = category;
                if (_hasChanges) setState(() => _hasChanges = false);
                // Show success snackbar only after a save, not on first load
                if (_isSaving) {
                  _isSaving = false;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text(
                        'Profile Updated Successfully',
                        style: TextStyle(fontFamily: 'Cairo'),
                      ),
                      backgroundColor: Colors.green[700],
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                }
              },
              error: (msg, type) {
                _isSaving = false;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content:
                        Text(msg, style: const TextStyle(fontFamily: 'Cairo')),
                    backgroundColor: Colors.red[700],
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                );
              },
            );
          },
          builder: (context, state) {
            final loadingWidget = state.mapOrNull(
              loading: (s) => s.cachedData != null
                  ? _buildContent(
                      s.cachedData!, s.universities, s.cities, s.categories)
                  : null,
              success: (s) =>
                  _buildContent(s.data, s.universities, s.cities, s.categories),
              error: (s) => Center(child: Text(s.error)),
            );
            return loadingWidget ??
                const Center(child: CircularProgressIndicator());
          },
        ),
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[900] : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
              blurRadius: 10.r,
              offset: Offset(0, -5.h),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Save Button ───────────────────────────────────────────────
            InkWell(
              onTap: (_hasChanges && !_isSaving) ? _onSave : null,
              borderRadius: BorderRadius.circular(12.r),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: double.infinity,
                height: 54.h,
                decoration: BoxDecoration(
                  gradient: (_hasChanges && !_isSaving)
                      ? const LinearGradient(
                          colors: [Color(0xFF1D61E7), Color(0xFF0B8FAC)],
                        )
                      : LinearGradient(
                          colors: [Colors.grey.shade400, Colors.grey.shade400],
                        ),
                  borderRadius: BorderRadius.circular(12.r),
                  boxShadow: [
                    BoxShadow(
                      color: (_hasChanges && !_isSaving)
                          ? const Color(0xFF1D61E7).withValues(alpha: 0.2)
                          : Colors.transparent,
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: _isSaving
                      ? SizedBox(
                          width: 20.w,
                          height: 20.w,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'حفظ',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ),
            SizedBox(height: 10.h),
            // ── Change Password Button ────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 50.h,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF1D61E7), width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ChangePasswordScreen(),
                    ),
                  );
                },
                icon: Icon(Icons.lock_reset_rounded,
                    color: const Color(0xFF1D61E7), size: 24.r),
                label: Text(
                  'تغيير كلمة المرور',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1D61E7),
                  ),
                ),
              ),
            ),
            SizedBox(height: 10.h),
            // ── Request and Delete Buttons ─────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 50.h,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1D61E7),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const MyRequestsScreen(),
                          ),
                        );
                      },
                      icon: Icon(Icons.assignment_outlined, size: 24.r),
                      label: Text(
                        'طلباتي',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: SizedBox(
                    height: 50.h,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red, width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AccountDeletionScreen(),
                          ),
                        );
                      },
                      icon: Icon(Icons.delete_forever_rounded,
                          color: Colors.red, size: 24.r),
                      label: Text(
                        'حذف الحساب',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize:
                              14.sp, // Reduced slightly to fit side-by-side
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(
      DoctorProfileModel profile,
      List<UniversityModel> universities,
      List<CityModel> cities,
      List<CategoryModel> categories) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return SingleChildScrollView(
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            'معلوماتك الشخصية',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF4B5563),
            ),
          ),
          SizedBox(height: 20.h),
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: theme.cardTheme.color ??
                  (isDark ? Colors.grey[900] : Colors.white),
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                  blurRadius: 10.r,
                  offset: Offset(0, 4.h),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildEditableInputField(
                  label: 'الإيميل',
                  controller: _emailCtrl,
                  focusNode: _emailFocusNode,
                  keyboardType: TextInputType.emailAddress,
                  textDirection: TextDirection.ltr,
                  textAlign: TextAlign.left,
                  hintText: 'example@mail.com',
                ),
                _divider(),
                _buildEditableInputField(
                  label: 'الاسم الأول',
                  controller: _firstNameCtrl,
                  focusNode: _firstNameFocusNode,
                  hintText: 'أدخل الاسم الأول',
                ),
                _divider(),
                _buildEditableInputField(
                  label: 'اسم العائلة',
                  controller: _lastNameCtrl,
                  focusNode: _lastNameFocusNode,
                  hintText: 'أدخل اسم العائلة',
                ),
                _divider(),
                _buildEditablePhoneField(),
                _divider(),
                _buildEditableField(
                  label: 'الجامعة',
                  id: 'university',
                  displayValue: _universityCtrl.text.isNotEmpty
                      ? _universityCtrl.text
                      : profile.faculty,
                  onTap: () => _showSelectionDialog(
                    title: 'اختر الجامعة',
                    items: universities.map((u) => u.name).toList(),
                    controller: _universityCtrl,
                  ),
                ),
                _divider(),
                _buildEditableField(
                  label: 'السنة الدراسية',
                  id: 'year',
                  displayValue:
                      _yearCtrl.text.isNotEmpty ? _yearCtrl.text : profile.year,
                  onTap: () => _showSelectionDialog(
                    title: 'اختر السنة الدراسية',
                    items: const [
                      'الأولى',
                      'الثانية',
                      'الثالثة',
                      'الرابعة',
                      'الخامسة',
                      'امتياز',
                      'مزاول'
                    ],
                    controller: _yearCtrl,
                  ),
                ),
                _divider(),
                _buildEditableField(
                  label: 'المحافظة',
                  id: 'city',
                  displayValue: _cityCtrl.text.isNotEmpty
                      ? _cityCtrl.text
                      : profile.governorate,
                  onTap: () => _showSelectionDialog(
                    title: 'اختر المحافظة',
                    items: cities.map((c) => c.name).toList(),
                    controller: _cityCtrl,
                  ),
                ),
                _divider(),
                _buildEditableField(
                  label: 'التخصص',
                  id: 'category',
                  displayValue: _categoryCtrl.text.isNotEmpty
                      ? _categoryCtrl.text
                      : profile.category,
                  onTap: () => _showSelectionDialog(
                    title: 'اختر التخصص',
                    items: categories.map((c) => c.name).toList(),
                    controller: _categoryCtrl,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 20.h),
        ],
      ),
    );
  }

  Widget _buildEditableField({
    required String label,
    required String id,
    String? displayValue,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 12.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: onTap,
                child: ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Color(0xFF1D61E7), Color(0xFF0B8FAC)],
                  ).createShader(bounds),
                  child: Icon(
                    Icons.edit_outlined,
                    size: 20.r,
                    color: Colors.white,
                  ),
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 14.sp,
                  color: const Color(0xFF9CA3AF),
                ),
              ),
            ],
          ),
          SizedBox(height: 4.h),
          GestureDetector(
            onTap: onTap,
            child: Text(
              (displayValue == null || displayValue.isEmpty)
                  ? 'غير محدد'
                  : displayValue,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF1F2937),
              ),
              textDirection: TextDirection.rtl,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableInputField({
    required String label,
    required TextEditingController controller,
    required FocusNode focusNode,
    TextInputType keyboardType = TextInputType.text,
    TextDirection textDirection = TextDirection.rtl,
    TextAlign textAlign = TextAlign.right,
    String hintText = '',
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 12.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () => FocusScope.of(context).requestFocus(focusNode),
                child: ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Color(0xFF1D61E7), Color(0xFF0B8FAC)],
                  ).createShader(bounds),
                  child: Icon(
                    Icons.edit_outlined,
                    size: 20.r,
                    color: Colors.white,
                  ),
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 14.sp,
                  color: const Color(0xFF9CA3AF),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          TextField(
            focusNode: focusNode,
            controller: controller,
            keyboardType: keyboardType,
            textDirection: textDirection,
            textAlign: textAlign,
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 14.sp,
                color: const Color(0xFFD1D5DB),
              ),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
                borderSide: const BorderSide(
                  color: Color(0xFFE5E7EB),
                  width: 1.2,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
                borderSide: const BorderSide(
                  color: Color(0xFFE5E7EB),
                  width: 1.2,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
                borderSide: const BorderSide(
                  color: Color(0xFF1D61E7),
                  width: 1.5,
                ),
              ),
            ),
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1F2937),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditablePhoneField() {
    return _buildEditableInputField(
      label: 'رقم الهاتف',
      controller: _phoneCtrl,
      focusNode: _phoneFocusNode,
      keyboardType: TextInputType.phone,
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.left,
      hintText: 'أدخل رقم الهاتف',
    );
  }

  Widget _divider() {
    return Divider(height: 1, color: const Color(0xFFF3F4F6), thickness: 1.2.h);
  }
}
