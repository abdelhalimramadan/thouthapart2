import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:thotha_mobile_app/core/helpers/shared_pref_helper.dart';
import 'package:thotha_mobile_app/core/networking/api_service.dart';
import 'package:thotha_mobile_app/core/networking/dio_factory.dart';
import 'package:thotha_mobile_app/core/networking/models/category_model.dart';
import 'package:thotha_mobile_app/core/networking/models/city_model.dart';
import 'package:thotha_mobile_app/core/networking/models/university_model.dart';
import 'package:thotha_mobile_app/features/home_screen/doctor_home/ui/account_deletion_screen.dart';
import 'package:thotha_mobile_app/features/home_screen/doctor_home/ui/doctor_home_screen.dart';
import 'package:thotha_mobile_app/features/home_screen/doctor_home/ui/edit_doctor_profile_screen.dart';


class DoctorProfile extends StatefulWidget {
  const DoctorProfile({Key? key}) : super(key: key);

  @override
  State<DoctorProfile> createState() => _DoctorProfileState();
}

class _DoctorProfileState extends State<DoctorProfile> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _loading = false;

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

  // API service
  final ApiService _apiService = ApiService();


  @override
  void initState() {
    super.initState();
    _bootstrap();
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

  // Update _bootstrap and _fetchProfile to update Controllers instead of Strings
  Future<void> _bootstrap() async {
    setState(() => _loading = true);
    try {
      final cachedFirst = await SharedPrefHelper.getString('first_name');
      final cachedLast = await SharedPrefHelper.getString('last_name');
      final cachedEmail = await SharedPrefHelper.getString('email');
      final cachedPhone = await SharedPrefHelper.getString('phone');
      final cachedFaculty = await SharedPrefHelper.getString('faculty');
      final cachedYear = await SharedPrefHelper.getString('year');
      final cachedGovernorate = await SharedPrefHelper.getString('governorate');
      final cachedCategory = await SharedPrefHelper.getString('category');

      if (mounted) {
        setState(() {
          if (cachedFirst != null) _firstNameController.text = cachedFirst;
          if (cachedLast != null) _lastNameController.text = cachedLast;
          if (cachedEmail != null) _emailController.text = cachedEmail;
          if (cachedPhone != null && !cachedPhone.contains('@')) _phoneController.text = cachedPhone;

          _faculty = (cachedFaculty?.isNotEmpty ?? false) ? cachedFaculty : _faculty;
          _year = (cachedYear?.isNotEmpty ?? false) ? cachedYear : _year;
          _governorate = (cachedGovernorate?.isNotEmpty ?? false) ? cachedGovernorate : _governorate;
          _category = (cachedCategory?.isNotEmpty ?? false) ? cachedCategory : _category;
        });
      }
      unawaited(_fetchProfile(silent: true));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _fetchProfile({bool silent = false}) async {
    if (!silent) {
      if (mounted) setState(() { _loading = true; });
    }
    try {
      final dio = DioFactory.getDio();
      Response? response;
      // Try relative paths — DioFactory sets baseUrl automatically
      for (final path in ['/profile', '/me']) {
        try {
          response = await dio.get(path);
          if ((response.statusCode ?? 0) == 200) break;
        } catch (_) {}
      }

      if (response == null) {
        try {
          final res = await dio.post('/update_profile', data: {});
          if (res.statusCode == 200) response = res;
        } catch (_) {}
      }

      if (response != null && response.statusCode == 200) {
        final data = response.data;
        Map<String, dynamic>? userMap;
        if (data is Map<String, dynamic>) {
          userMap = Map<String, dynamic>.from(data);
          if (userMap['user'] is Map) {
            userMap = Map<String, dynamic>.from(userMap['user']);
          }
        }

        String? getVal(String a, String b) {
          if (userMap == null) return null;
          return (userMap[a] ?? userMap[b])?.toString();
        }

        final firstName = getVal('first_name', 'firstName');
        final lastName = getVal('last_name', 'lastName');
        final email = userMap?['email']?.toString();

        String? phone = userMap?['phone']?.toString();
        final possiblePhoneKeys = ['tel', 'telephone', 'phone_number', 'mobile', 'phoneNumber', 'phone'];
        for (var key in possiblePhoneKeys) {
          if ((phone == null || phone.isEmpty) && userMap?[key] != null) {
            phone = userMap?[key]?.toString();
          }
        }
        if (phone != null && phone.contains('@')) phone = null;

        final faculty = userMap?['faculty']?.toString();
        final year = userMap?['year']?.toString();
        final governorate = (userMap?['governorate'] ?? userMap?['governorate_id'])?.toString();
        final category = (userMap?['category'] ?? userMap?['specialty'] ?? userMap?['specialization'])?.toString();

        // Save doctor_id if available
        final docId = userMap?['id'];
        if (docId != null) {
           await SharedPrefHelper.setData('doctor_id', docId is int ? docId : int.tryParse(docId.toString()) ?? 0);
        }

        if (mounted) {
          setState(() {
            if (firstName != null && firstName.isNotEmpty) _firstNameController.text = firstName;
            if (lastName != null && lastName.isNotEmpty) _lastNameController.text = lastName;
            if (email != null && email.isNotEmpty) _emailController.text = email;
            if (phone != null && phone.isNotEmpty) _phoneController.text = phone;

            if (faculty != null && faculty.isNotEmpty) _faculty = faculty;
            if (year != null && year.isNotEmpty) _year = year;
            if (governorate != null && governorate.isNotEmpty) _governorate = governorate;
            if (category != null && category.isNotEmpty) _category = category;
          });
        }

        // Save to prefs... (existing code)
        if ((firstName?.isNotEmpty ?? false)) {
             await SharedPrefHelper.setData('first_name', firstName);
             await SharedPrefHelper.setData('last_name', lastName ?? '');
             if ((email?.isNotEmpty ?? false)) await SharedPrefHelper.setData('email', email);
             if (phone != null) await SharedPrefHelper.setData('phone', phone);
             if (faculty != null) await SharedPrefHelper.setData('faculty', faculty);
             if (year != null) await SharedPrefHelper.setData('year', year);
             if (governorate != null) await SharedPrefHelper.setData('governorate', governorate);
             if (category != null) await SharedPrefHelper.setData('category', category);
        }
      }
    } catch (_) {
      // Ignore errors
    } finally {
      if (!silent && mounted) setState(() => _loading = false);
    }
  }



  void _onChangePassword() {
     showDialog(
       context: context,
       builder: (context) => AlertDialog(
         title: const Text('تغيير كلمة المرور', style: TextStyle(fontFamily: 'Cairo')),
         content: const Text('سيتم إضافة هذه الميزة قريباً\nيمكنك تسجيل الخروج واستخدام "نسيت كلمة المرور"', style: TextStyle(fontFamily: 'Cairo')),
         actions: [
           TextButton(
             onPressed: () => Navigator.pop(context),
             child: const Text('حسناً', style: TextStyle(fontFamily: 'Cairo')),
           ),
         ],
       ),
     );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
            'الملف الشخصي',
            style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
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
            icon: const Icon(Icons.mode_edit_outline_outlined),
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
                await _bootstrap();
              }
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Profile Picture
                  Center(
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.grey[200],
                          child: const Icon(Icons.person, size: 60, color: Colors.grey),
                        ),
                        // Camera icon could go here
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Fields
                  _buildTextField('الاسم الأول', _firstNameController),
                  _buildTextField('اسم العائلة', _lastNameController),
                  // Email is usually read-only or handled carefully
                  _buildTextField('البريد الإلكتروني', _emailController, keyboardType: TextInputType.emailAddress, enabled: false), // Keep email disabled for now
                  _buildTextField('رقم الهاتف', _phoneController, keyboardType: TextInputType.phone),

                  _buildDropdownField('الكلية', _faculty, _colleges, (v) => setState(() => _faculty = v)),
                  _buildDropdownField('الفرقة الدراسية', _year, _studyYears, (v) => setState(() => _year = v)),
                  _buildDropdownField('المحافظة', _governorate, _governorates, (v) => setState(() => _governorate = v)),
                  _buildDropdownField('التخصص', _category, _categories, (v) => setState(() => _category = v)),

                  const SizedBox(height: 32),

                  const Divider(),
                  const SizedBox(height: 16),

                  // Change Password Button
                  OutlinedButton.icon(
                    onPressed: _onChangePassword,
                    icon: const Icon(Icons.lock_outline),
                    label: const Text('تغيير كلمة المرور', style: TextStyle(fontFamily: 'Cairo')),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.black87,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: Colors.grey),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Delete Account Button
                  OutlinedButton.icon(
                    onPressed: () {
                       Navigator.push(
                         context,
                         MaterialPageRoute(builder: (context) => const AccountDeletionScreen()),
                       );
                    },
                    icon: const Icon(Icons.delete_forever),
                    label: const Text('حذف الحساب', style: TextStyle(fontFamily: 'Cairo')),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {TextInputType keyboardType = TextInputType.text, bool enabled = true}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        enabled: false,   // read-only — التعديل في صفحة منفصلة
        keyboardType: keyboardType,
        style: const TextStyle(fontFamily: 'Cairo'),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontFamily: 'Cairo'),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 15),
          filled: true,
          fillColor: Colors.grey[50],
        ),
      ),
    );
  }

  Widget _buildDropdownField(String label, String? selectedValue, List<String> options, ValueChanged<String?> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontFamily: 'Cairo'),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
          filled: true,
          fillColor: Colors.grey[50],
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: selectedValue,
            onChanged: null,   // read-only
            isExpanded: true,
            icon: const SizedBox(),
            style: const TextStyle(fontFamily: 'Cairo', color: Colors.black87),
            items: options.map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value, style: const TextStyle(fontFamily: 'Cairo')),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
