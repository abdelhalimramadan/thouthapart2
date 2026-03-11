import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:thotha_mobile_app/core/di/dependency_injection.dart';
import 'package:thotha_mobile_app/core/networking/models/city_model.dart';
import 'package:thotha_mobile_app/core/networking/models/university_model.dart';
import 'package:thotha_mobile_app/features/home_screen/doctor_home/logic/profile_cubit.dart';
import 'package:thotha_mobile_app/features/home_screen/doctor_home/logic/profile_state.dart';
import 'package:thotha_mobile_app/features/home_screen/doctor_home/data/models/doctor_profile_model.dart';
import 'package:thotha_mobile_app/features/home_screen/doctor_home/ui/account_deletion_screen.dart';
import 'package:thotha_mobile_app/features/home_screen/doctor_home/ui/doctor_home_screen.dart';
import 'package:thotha_mobile_app/features/forgot_password/ui/change_password_screen.dart';

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

  final _universityCtrl = TextEditingController();
  final _yearCtrl       = TextEditingController();
  final _cityCtrl       = TextEditingController();


  @override
  void dispose() {
    _universityCtrl.dispose();
    _yearCtrl.dispose();
    _cityCtrl.dispose();
    super.dispose();
  }

  void _onSave() {
    final cubit = context.read<ProfileCubit>();
    final currentState = cubit.state;
    
    DoctorProfileModel? currentProfile;
    currentState.whenOrNull(
      success: (data, universities, cities) => currentProfile = data,
      loading: (cachedData, universities, cities) => currentProfile = cachedData,
    );

    final body = <String, dynamic>{
      'firstName':      currentProfile?.firstName,
      'lastName':       currentProfile?.lastName,
      'phoneNumber':    currentProfile?.phone,
      'email':          currentProfile?.email,
      'universityName': _universityCtrl.text.trim(),
      'studyYear':      _yearCtrl.text.trim(),
      'cityName':       _cityCtrl.text.trim(),
    };
    
    // Remove nulls to avoid backend errors
    body.removeWhere((key, value) => value == null);

    final profileCubit = context.read<ProfileCubit>();
    profileCubit.updateProfile(body);
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
                .where((item) => item.toLowerCase().contains(searchQuery.toLowerCase()))
                .toList();
            
            return Directionality(
              textDirection: TextDirection.rtl,
              child: AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                title: Text(title, style: TextStyle(fontFamily: 'Cairo', fontSize: 18.sp, fontWeight: FontWeight.bold)),
                content: SizedBox(
                  width: double.maxFinite,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        onChanged: (val) => setDialogState(() => searchQuery = val),
                        textAlign: TextAlign.right,
                        decoration: InputDecoration(
                          hintText: 'بحث...',
                          hintStyle: TextStyle(fontFamily: 'Cairo', fontSize: 14.sp),
                          prefixIcon: const Icon(Icons.search),
                          isDense: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
                        ),
                      ),
                      SizedBox(height: 12.h),
                      ConstrainedBox(
                        constraints: BoxConstraints(maxHeight: 300.h),
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: filteredItems.length,
                          separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey[200]),
                          itemBuilder: (context, index) {
                            return ListTile(
                              title: Text(
                                filteredItems[index],
                                style: TextStyle(fontFamily: 'Cairo', fontSize: 16.sp),
                                textAlign: TextAlign.right,
                              ),
                              onTap: () {
                                controller.text = filteredItems[index];
                                Navigator.pop(context);
                                _onSave(); // Auto save on selection
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
          'الملف الشخصي',
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black, size: 20.sp),
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
              success: (p, universities, cities) {
                _universityCtrl.text = p.faculty ?? '';
                _yearCtrl.text       = p.year ?? '';
                _cityCtrl.text       = p.governorate ?? '';
              },
              error: (msg, type) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(msg), backgroundColor: Colors.red),
                );
              },
            );
          },
          builder: (context, state) {
            final loadingWidget = state.mapOrNull(
              loading: (s) => s.cachedData != null
                  ? _buildContent(s.cachedData!, s.universities, s.cities)
                  : null,
              success: (s) => _buildContent(s.data, s.universities, s.cities),
              error: (s) => Center(child: Text(s.error)),
            );
            return loadingWidget ?? const Center(child: CircularProgressIndicator());
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
            // ── Save Button ───────────────────────────────────────────────
            InkWell(
              onTap: _onSave,
              borderRadius: BorderRadius.circular(12.r),
              child: Container(
                width: double.infinity,
                height: 54.h,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1D61E7), Color(0xFF0B8FAC)],
                  ),
                  borderRadius: BorderRadius.circular(12.r),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1D61E7).withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
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
                icon: const Icon(Icons.lock_reset_rounded,
                    color: Color(0xFF1D61E7), size: 20),
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
            // ── Delete Account Button ─────────────────────────────────────
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
                  'حذف الحساب',
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

  Widget _buildContent(DoctorProfileModel profile, List<UniversityModel> universities, List<CityModel> cities) {
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
                _buildFieldItem(label: 'الإيميل', value: profile.email ?? '', isRtl: false),
                _divider(),
                _buildFieldItem(label: 'الاسم الأول', value: profile.firstName ?? ''),
                _divider(),
                _buildFieldItem(label: 'اسم العائلة', value: profile.lastName ?? ''),
                _divider(),
                _buildFieldItem(label: 'رقم الهاتف', value: profile.phone ?? '', isVerified: true),
                _divider(),
                _buildEditableField(
                  label: 'الجامعة',
                  id: 'university',
                  displayValue: profile.faculty,
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
                  displayValue: profile.year,
                  onTap: () => _showSelectionDialog(
                    title: 'اختر السنة الدراسية',
                    items: const ['الأولى', 'الثانية', 'الثالثة', 'الرابعة', 'الخامسة', 'امتياز', 'مزاول'],
                    controller: _yearCtrl,
                  ),
                ),
                _divider(),
                _buildEditableField(
                  label: 'المحافظة',
                  id: 'city',
                  displayValue: profile.governorate,
                  onTap: () => _showSelectionDialog(
                    title: 'اختر المحافظة',
                    items: cities.map((c) => c.name).toList(),
                    controller: _cityCtrl,
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

  Widget _buildFieldItem({
    required String label,
    required String value,
    bool isRtl = true,
    bool isVerified = false,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 12.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 14.sp,
              color: const Color(0xFF9CA3AF),
            ),
          ),
          SizedBox(height: 4.h),
          Row(
            mainAxisAlignment: isRtl ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              if (isVerified) ...[
                Icon(Icons.check_circle, color: Colors.green, size: 16.sp),
                SizedBox(width: 4.w),
              ],
              Text(
                value,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1F2937),
                ),
                textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
              ),
            ],
          ),
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
              (displayValue == null || displayValue.isEmpty) ? 'غير محدد' : displayValue,
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

  Widget _divider() {
    return Divider(height: 1, color: const Color(0xFFF3F4F6), thickness: 1.2.h);
  }
}
