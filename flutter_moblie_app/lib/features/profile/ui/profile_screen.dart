import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:thotha_mobile_app/core/di/dependency_injection.dart';

import 'package:thotha_mobile_app/core/networking/models/city_model.dart';
import 'package:thotha_mobile_app/core/networking/models/university_model.dart';
import 'package:thotha_mobile_app/core/networking/models/category_model.dart';
import 'package:thotha_mobile_app/features/profile/logic/profile_cubit.dart';
import 'package:thotha_mobile_app/features/profile/logic/profile_state.dart';
import 'package:thotha_mobile_app/features/profile/data/models/profile_model.dart';
import 'package:thotha_mobile_app/features/profile/ui/account_deletion_screen.dart';
import 'package:thotha_mobile_app/features/doctor/ui/doctor_home_screen.dart';
import 'package:thotha_mobile_app/features/forgot_password/ui/change_password_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<ProfileCubit>()..fetchProfile(),
      child: const ProfileBody(),
    );
  }
}

class ProfileBody extends StatefulWidget {
  const ProfileBody({super.key});

  @override
  State<ProfileBody> createState() => _ProfileBodyState();
}

class _ProfileBodyState extends State<ProfileBody> {
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

  // Original values ΓÇö set once when profile loads
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
      return 'الاسم الاول';
    }
    if (lastName.isEmpty || lastName.length < 2) {
      return 'الاسم الثاني';
    }
    if (email.isEmpty || !_isValidEmail(email)) {
      return 'البريد الالكتروني';
    }
    if (phone.isEmpty || !_isValidPhone(phone)) {
      return 'رقم الهاتف';
    }
    if (university.isEmpty) {
      return 'الكلية';
    }
    if (year.isEmpty) {
      return 'السنة الدراسية';
    }
    if (city.isEmpty) {
      return 'المحافظه';
    }
    if (category.isEmpty) {
      return 'التخصص';
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

    // Build update body - ╪º┘ä╪¬┘ê┘â┘å ┘ü┘è headers ┘è┘â┘ü┘è ┘ä┘ä┘Ç API
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
                          hintText: '╪¿╪¡╪½...',
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
                                // No auto-save ΓÇö user must press save button
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
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'الملف الشخصى',
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.black, size: 20.sp),
          onPressed: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const DoctorHomeScreen()),
            );
          },
        ),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: BlocConsumer<ProfileCubit, ProfileState<ProfileModel>>(
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
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ΓöÇΓöÇ Save Button ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ
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
            // ΓöÇΓöÇ Change Password Button ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ
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
                icon: const Icon(Icons.lock_reset_rounded,
                    color: Color(0xFF1D61E7), size: 20),
                label: Text(
                  'تغير كلمة المرور',
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
            // ΓöÇΓöÇ Delete Account Button ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ
            SizedBox(
              width: double.infinity,
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
                icon: const Icon(Icons.delete_forever_rounded,
                    color: Colors.red, size: 20),
                label: Text(
                  'حذف الحساب ',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(
      ProfileModel profile,
      List<UniversityModel> universities,
      List<CityModel> cities,
      List<CategoryModel> categories) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            'البيانات الشخصية',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF4B5563),
            ),
          ),
          SizedBox(height: 20.h),
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildEditableInputField(
                  label: 'البريد الالكترونى',
                  controller: _emailCtrl,
                  focusNode: _emailFocusNode,
                  keyboardType: TextInputType.emailAddress,
                  textDirection: TextDirection.ltr,
                  textAlign: TextAlign.left,
                  hintText: 'example@mail.com',
                ),
                _divider(),
                _buildEditableInputField(
                  label: 'الاسم الاول',
                  controller: _firstNameCtrl,
                  focusNode: _firstNameFocusNode,
                  hintText: 'اسم الطبيب',
                ),
                _divider(),
                _buildEditableInputField(
                  label: 'الاسم الثاني',
                  controller: _lastNameCtrl,
                  focusNode: _lastNameFocusNode,
                  hintText: 'اسم العائلة',
                ),
                _divider(),
                _buildEditablePhoneField(),
                _divider(),
                _buildEditableField(
                  label: 'الكلية',
                  id: 'university',
                  displayValue: _universityCtrl.text.isNotEmpty
                      ? _universityCtrl.text
                      : profile.faculty,
                  onTap: () => _showSelectionDialog(
                    title: 'جميع الكليات',
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
                    title: 'السنه الدراسية',
                    items: const [
                      'الفرقة الرابعة',
                      'الفرقةالخامسة',
                      'امتياز',
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
                    title: 'جميع المحافظات',
                    items: cities.map((c) => c.name).toList(),
                    controller: _cityCtrl,
                  ),
                ),
                _divider(),
                _buildEditableField(
                  label: 'التخصص ',
                  id: 'category',
                  displayValue: _categoryCtrl.text.isNotEmpty
                      ? _categoryCtrl.text
                      : profile.category,
                  onTap: () => _showSelectionDialog(
                    title: 'جميع التخصصات',
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
                    size: 20.sp,
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
                  ? 'يس'
                  : displayValue,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1F2937),
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
                    size: 20.sp,
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
      hintText: 'رقم الهاتف',
    );
  }

  Widget _divider() {
    return Divider(height: 1, color: const Color(0xFFF3F4F6), thickness: 1.2.h);
  }
}
