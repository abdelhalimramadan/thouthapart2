import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:thotha_mobile_app/core/networking/api_service.dart';
import 'package:thotha_mobile_app/core/networking/models/category_model.dart';
import 'package:thotha_mobile_app/core/networking/models/city_model.dart';
import 'package:thotha_mobile_app/core/networking/models/university_model.dart';
import 'package:thotha_mobile_app/core/theming/colors.dart' as colors;
import 'package:thotha_mobile_app/features/home_screen/doctor_home/data/models/doctor_profile_model.dart';
import 'package:thotha_mobile_app/features/home_screen/doctor_home/data/repos/profile_repository.dart';
import 'package:thotha_mobile_app/features/home_screen/doctor_home/logic/profile_cubit.dart';
import 'package:thotha_mobile_app/features/home_screen/doctor_home/logic/profile_state.dart';
import 'package:thotha_mobile_app/features/home_screen/doctor_home/ui/account_deletion_screen.dart';
import 'package:thotha_mobile_app/features/home_screen/doctor_home/ui/doctor_home_screen.dart';
import 'package:thotha_mobile_app/features/home_screen/doctor_home/ui/edit_doctor_profile_screen.dart';

class DoctorProfile extends StatelessWidget {
  const DoctorProfile({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ProfileCubit(ProfileRepository())..fetchProfile(),
      child: const DoctorProfileView(),
    );
  }
}

class DoctorProfileView extends StatefulWidget {
  const DoctorProfileView({Key? key}) : super(key: key);

  @override
  State<DoctorProfileView> createState() => _DoctorProfileViewState();
}

class _DoctorProfileViewState extends State<DoctorProfileView> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Controllers
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  // Dropdown values
  String? _faculty;
  String? _year;
  String? _governorate;
  String? _category;

  // Populated from API — empty until fetched
  List<String> _governorates = [];
  List<String> _categories = [];
  List<String> _colleges = [];

  // No API for study years — hardcoded
  final List<String> _studyYears = [
    'الفرقة الأولى', 'الفرقة الثانية', 'الفرقة الثالثة', 'الفرقة الرابعة', 'الفرقة الخامسة', 'امتياز',
  ];

  // API service for reference data
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _fetchReferenceData();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // ── Fetch dropdown data from API ───────────────────────────────────────
  Future<void> _fetchReferenceData() async {
    await Future.wait([
      _fetchCities(),
      _fetchUniversities(),
      _fetchCategories(),
    ]);
  }

  Future<void> _fetchCities() async {
    try {
      final result = await _apiService.getCities();
      if (result['success'] == true && mounted) {
        final cities = result['data'] as List<CityModel>;
        setState(() => _governorates = cities.map((c) => c.name).toList());
      }
    } catch (_) {}
  }

  Future<void> _fetchUniversities() async {
    try {
      final result = await _apiService.getUniversities();
      if (result['success'] == true && mounted) {
        final universities = result['data'] as List<UniversityModel>;
        setState(() => _colleges = universities.map((u) => u.name).toList());
      }
    } catch (_) {}
  }

  Future<void> _fetchCategories() async {
    try {
      final result = await _apiService.getCategories();
      if (result['success'] == true && mounted) {
        final categories = result['data'] as List<CategoryModel>;
        setState(() => _categories = categories.map((c) => c.name).toList());
      }
    } catch (_) {}
  }

  void _populateControllers(DoctorProfileModel profile) {
    if (profile.firstName != null && profile.firstName!.isNotEmpty) _firstNameController.text = profile.firstName!;
    if (profile.lastName != null && profile.lastName!.isNotEmpty) _lastNameController.text = profile.lastName!;
    if (profile.email != null && profile.email!.isNotEmpty) _emailController.text = profile.email!;
    if (profile.phone != null && profile.phone!.isNotEmpty) _phoneController.text = profile.phone!;

    setState(() {
      if (profile.faculty != null && profile.faculty!.isNotEmpty) _faculty = profile.faculty;
      if (profile.year != null && profile.year!.isNotEmpty) _year = profile.year;
      if (profile.governorate != null && profile.governorate!.isNotEmpty) _governorate = profile.governorate;
      if (profile.category != null && profile.category!.isNotEmpty) _category = profile.category;
    });
  }

  void _onChangePassword() {
     showDialog(
       context: context,
       builder: (context) => AlertDialog(
         title: Text('تغيير كلمة المرور', style: TextStyle(fontFamily: 'Cairo', fontSize: 18.sp)),
         content: Text('سيتم إضافة هذه الميزة قريباً\nيمكنك تسجيل الخروج واستخدام "نسيت كلمة المرور"', style: TextStyle(fontFamily: 'Cairo', fontSize: 14.sp)),
         actions: [
           TextButton(
             onPressed: () => Navigator.pop(context),
             child: Text('حسناً', style: TextStyle(fontFamily: 'Cairo', fontSize: 14.sp)),
           ),
         ],
       ),
     );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProfileCubit, ProfileState<DoctorProfileModel>>(
      listener: (context, state) {
        state.maybeWhen(
          success: (profile) => _populateControllers(profile),
          loading: (cachedProfile) {
            if (cachedProfile != null) _populateControllers(cachedProfile);
          },
          error: (err, type) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(err, style: TextStyle(fontFamily: 'Cairo', fontSize: 14.sp))),
            );
          },
          orElse: () {},
        );
      },
      builder: (context, state) {
        final isLoading = state.maybeWhen(
           initial: () => true,
           loading: (cached) => cached == null || cached.firstName == null, // Show spinner only if no cache
           orElse: () => false,
        );

        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: colors.ColorsManager.moreLighterGray,
          appBar: AppBar(
            title: Text(
                'الملف الشخصي',
                style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 18.sp, color: Colors.white)
            ),
            centerTitle: true,
            backgroundColor: const Color(0xFF8DECB8), // لون ثابت للAppBar
            elevation: 0,
            foregroundColor: Colors.white,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, size: 24.sp, color: Colors.white),
              onPressed: () {
                if (Navigator.canPop(context)) {
                  Navigator.of(context).pop();
                } else {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      settings: const RouteSettings(name: 'doctor-home'),
                      builder: (context) => const DoctorHomeScreen(),
                    ),
                  );
                }
              },
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.mode_edit_outline_outlined, size: 24.sp, color: Colors.white),
                onPressed: () async {
                  final updated = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EditDoctorProfileScreen(
                        firstName:   _firstNameController.text,
                        lastName:    _lastNameController.text,
                        phone:       _phoneController.text,
                        faculty:     _faculty,
                        year:        _year,
                        governorate: _governorate,
                        category:    _category,
                      ),
                    ),
                  );
                  if (updated == true && mounted) {
                    context.read<ProfileCubit>().fetchProfile();
                  }
                },
              ),
            ],
          ),
          body: isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      SizedBox(height: 20.h),
                      // Profile Header Card with Gradient Background
                      Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topRight,
                            end: Alignment.bottomLeft,
                            colors: [
                              Color(0xFF84E5F3),
                              Color(0xFF8DECB4),
                            ],
                          ),
                          borderRadius: BorderRadius.all(
                              Radius.circular(30)
                          ),
                        ),
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 40.h),
                          child: Column(
                            children: [
                              // Profile Picture with better design
                              Stack(
                                alignment: Alignment.bottomRight,
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 4),
                                      boxShadow: [
                                        BoxShadow(
                                          color: colors.ColorsManager.layerBlur1.withOpacity(0.3),
                                          blurRadius: 15,
                                          offset: const Offset(0, 8),
                                        ),
                                      ],
                                    ),
                                    child: CircleAvatar(
                                      radius: 65.r,
                                      backgroundColor: Colors.white,
                                      child: Icon(Icons.person, size: 75.sp, color: colors.ColorsManager.mainBlue),
                                    ),
                                  ),
                                  // Camera/Edit icon
                                  Container(
                                    padding: EdgeInsets.all(10.w),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: colors.ColorsManager.layerBlur1.withOpacity(0.2),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Icon(Icons.camera_alt, size: 22.sp, color: colors.ColorsManager.mainBlue),
                                  ),
                                ],
                              ),
                              SizedBox(height: 25.h),
                              
                              // Name display
                              Text(
                                '${_firstNameController.text} ${_lastNameController.text}',
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 24.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 10.h),
                              
                              // Email display
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20.r),
                                ),
                                child: Text(
                                  _emailController.text,
                                  style: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: 14.sp,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      // Information Cards Section
                      Padding(
                        padding: EdgeInsets.all(20.w),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Personal Information Card
                            _buildInfoCard(
                              title: 'المعلومات الشخصية',
                              icon: Icons.person_outline,
                              children: [
                                _buildInfoRow('الاسم الأول', _firstNameController.text),
                                _buildInfoRow('اسم العائلة', _lastNameController.text),
                                _buildInfoRow('رقم الهاتف', _phoneController.text),
                              ],
                            ),
                            
                            SizedBox(height: 20.h),
                            
                            // Academic Information Card
                            _buildInfoCard(
                              title: 'المعلومات الأكاديمية',
                              icon: Icons.school_outlined,
                              children: [
                                _buildInfoRow('الكلية', _faculty ?? 'غير محدد'),
                                _buildInfoRow('الفرقة الدراسية', _year ?? 'غير محدد'),
                                _buildInfoRow('المحافظة', _governorate ?? 'غير محدد'),
                                _buildInfoRow('التخصص', _category ?? 'غير محدد'),
                              ],
                            ),
                            
                            SizedBox(height: 30.h),
                            
                            // Action Buttons
                            _buildActionButtons(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
        );
      },
    );
  }

  // Build information card with better design
  Widget _buildInfoCard({required String title, required IconData icon, required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15.r),
        boxShadow: [
          BoxShadow(
            color: colors.ColorsManager.layerBlur2.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card header
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(10.w),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF84E5F3), Color(0xFF8DECB4)],
                    ),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Icon(icon, size: 20.sp, color: Colors.white),
                ),
                SizedBox(width: 12.w),
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: colors.ColorsManager.fontColor,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            
            // Card content
            ...children,
          ],
        ),
      ),
    );
  }

  // Build information row with better styling
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 14.sp,
                color: colors.ColorsManager.gray,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          // Value
          Expanded(
            flex: 3,
            child: Text(
              value.isNotEmpty ? value : 'غير محدد',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 14.sp,
                color: colors.ColorsManager.fontColor,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  // Build action buttons with better design
  Widget _buildActionButtons() {
    return Column(
      children: [
        // Change Password Button
        Container(
          width: double.infinity,
          height: 52.h,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF84E5F3), Color(0xFF8DECB4)],
            ),
            borderRadius: BorderRadius.circular(15.r),
            boxShadow: [
              BoxShadow(
                color: colors.ColorsManager.layerBlur1.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ElevatedButton.icon(
            onPressed: _onChangePassword,
            icon: Icon(Icons.lock_outline, size: 20.sp, color: Colors.white),
            label: Text('تغيير كلمة المرور', style: TextStyle(fontFamily: 'Cairo', fontSize: 14.sp, color: Colors.white, fontWeight: FontWeight.w600)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.r)),
            ),
          ),
        ),
        
        SizedBox(height: 16.h),
        
        // Delete Account Button
        Container(
          width: double.infinity,
          height: 52.h,
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(15.r),
            border: Border.all(color: Colors.red.withOpacity(0.6), width: 2),
          ),
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AccountDeletionScreen()),
              );
            },
            icon: Icon(Icons.delete_forever, size: 20.sp, color: Colors.red),
            label: Text('حذف الحساب', style: TextStyle(fontFamily: 'Cairo', fontSize: 14.sp, color: Colors.red, fontWeight: FontWeight.w600)),
            style: OutlinedButton.styleFrom(
              backgroundColor: Colors.transparent,
              side: BorderSide.none,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.r)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {TextInputType keyboardType = TextInputType.text, bool enabled = true}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: TextFormField(
        controller: controller,
        enabled: false,   // read-only — التعديل في صفحة منفصلة
        keyboardType: keyboardType,
        style: TextStyle(fontFamily: 'Cairo', fontSize: 14.sp),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(fontFamily: 'Cairo', fontSize: 14.sp),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r)),
          contentPadding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 15.w),
          filled: true,
          fillColor: Colors.grey[50],
        ),
      ),
    );
  }

  Widget _buildDropdownField(String label, String? selectedValue, List<String> options, ValueChanged<String?> onChanged) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(fontFamily: 'Cairo', fontSize: 14.sp),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r)),
          contentPadding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 15.w),
          filled: true,
          fillColor: Colors.grey[50],
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: selectedValue,
            onChanged: null,   // read-only
            isExpanded: true,
            icon: const SizedBox(),
            style: TextStyle(fontFamily: 'Cairo', color: Colors.black87, fontSize: 14.sp),
            items: options.map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value, style: TextStyle(fontFamily: 'Cairo', fontSize: 14.sp)),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
