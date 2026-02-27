import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:thotha_mobile_app/core/helpers/shared_pref_helper.dart';
import 'package:thotha_mobile_app/core/helpers/constants.dart';
import 'package:thotha_mobile_app/core/networking/api_constants.dart';
import 'package:thotha_mobile_app/core/networking/dio_factory.dart';
import 'package:thotha_mobile_app/core/routing/routes.dart';
import 'package:thotha_mobile_app/features/home_screen/doctor_home/drawer/doctor_drawer_screen.dart';

class DoctorProfile extends StatefulWidget {
  const DoctorProfile({Key? key}) : super(key: key);

  @override
  State<DoctorProfile> createState() => _DoctorProfileState();
}

class _DoctorProfileState extends State<DoctorProfile> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _loading = false;
  String? _error;

  String? _firstName;
  String? _lastName;
  String? _email;
  String? _phone;
  String? _faculty;
  String? _year;
  String? _governorate;
  String? _category;
  String? _profileImage;

  final List<String> _governorates = [
    'القاهرة', 'الجيزة', 'الإسكندرية', 'الدقهلية', 'الشرقية', 'الغربية',
    'المنوفية', 'البحيرة', 'القليوبية', 'دمياط', 'كفر الشيخ', 'بورسعيد',
    'الإسماعيلية', 'السويس', 'المنيا', 'أسيوط', 'سوهاج', 'قنا', 'الأقصر',
    'أسوان', 'البحر الأحمر', 'مطروح', 'شمال سيناء', 'جنوب سيناء', 'الفيوم',
    'بني سويف', 'الوادي الجديد',
  ];

  final List<String> _categories = [
    'جراحة الوجه والفكين', 'تقويم الأسنان', 'علاج الجذور', 'طب أسنان الأطفال',
    'تركيبات الأسنان', 'علاج اللثة', 'طب الأسنان التجميلي', 'زراعة الأسنان',
  ];

  final List<String> _colleges = [
    'كلية طب الأسنان - القاهرة', 'كلية طب الأسنان - عين شمس',
    'كلية طب الأسنان - الإسكندرية', 'كلية طب الأسنان - المنصورة', 'أخرى',
  ];

  final List<String> _studyYears = [
    'الفرقة الأولى', 'الفرقة الثانية', 'الفرقة الثالثة',
    'الفرقة الرابعة', 'الفرقة الخامسة', 'امتياز',
  ];

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

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
      final cachedImage = await SharedPrefHelper.getString('profile_image');

      if (mounted) {
        setState(() {
          _firstName = (cachedFirst?.isNotEmpty ?? false) ? cachedFirst : _firstName;
          _lastName = (cachedLast?.isNotEmpty ?? false) ? cachedLast : _lastName;
          _email = (cachedEmail?.isNotEmpty ?? false) ? cachedEmail : _email;
          if (cachedPhone?.isNotEmpty ?? false) {
            if (!cachedPhone!.contains('@')) {
              _phone = cachedPhone;
            }
          }
          _faculty = (cachedFaculty?.isNotEmpty ?? false) ? cachedFaculty : _faculty;
          _year = (cachedYear?.isNotEmpty ?? false) ? cachedYear : _year;
          _governorate = (cachedGovernorate?.isNotEmpty ?? false) ? cachedGovernorate : _governorate;
          _category = (cachedCategory?.isNotEmpty ?? false) ? cachedCategory : _category;
          _profileImage = (cachedImage?.isNotEmpty ?? false) ? cachedImage : _profileImage;
        });
      }
      unawaited(_fetchProfile(silent: true));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _fetchProfile({bool silent = false}) async {
    if (!silent) {
      if (mounted) setState(() { _error = null; _loading = true; });
    }
    try {
      final dio = DioFactory.getDio();
      Response? response;
      try {
        response = await dio.get('${ApiConstants.otpBaseUrl}/profile');
      } catch (_) {
        try {
          response = await dio.get('${ApiConstants.otpBaseUrl}/me');
        } catch (_) {}
      }

      if (response == null) {
        try {
          final res = await dio.post('${ApiConstants.otpBaseUrl}/update_profile', data: {});
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
        if ((phone == null || phone.isEmpty) && data is Map) {
          for (var key in possiblePhoneKeys) {
            if (data[key] != null) {
              phone = data[key]?.toString();
              if (phone != null && phone.isNotEmpty) break;
            }
          }
        }
        if (phone != null && phone.contains('@')) phone = null;

        final faculty = userMap?['faculty']?.toString();
        final year = userMap?['year']?.toString();
        final governorate = (userMap?['governorate'] ?? userMap?['governorate_id'])?.toString();
        final category = (userMap?['category'] ?? userMap?['specialty'] ?? userMap?['specialization'])?.toString();
        final profileImage = userMap?['profile_image']?.toString();

        if (mounted) {
          setState(() {
            if (firstName != null && firstName.isNotEmpty) _firstName = firstName;
            if (lastName != null && lastName.isNotEmpty) _lastName = lastName;
            if (email != null && email.isNotEmpty) _email = email;
            if (phone != null && phone.isNotEmpty) _phone = phone;
            if (faculty != null && faculty.isNotEmpty) _faculty = faculty;
            if (year != null && year.isNotEmpty) _year = year;
            if (governorate != null && governorate.isNotEmpty) _governorate = governorate;
            if (category != null && category.isNotEmpty) _category = category;
            if (profileImage != null && profileImage.isNotEmpty) _profileImage = profileImage;
          });
        }

        if ((firstName?.isNotEmpty ?? false)) {
          await SharedPrefHelper.setData('first_name', firstName);
          await SharedPrefHelper.setData('last_name', lastName ?? '');
          if ((email?.isNotEmpty ?? false)) await SharedPrefHelper.setData('email', email);
          if (phone != null) await SharedPrefHelper.setData('phone', phone);
          if (faculty != null) await SharedPrefHelper.setData('faculty', faculty);
          if (year != null) await SharedPrefHelper.setData('year', year);
          if (governorate != null) await SharedPrefHelper.setData('governorate', governorate);
          if (category != null) await SharedPrefHelper.setData('category', category);
          if (profileImage != null) {
            await SharedPrefHelper.setData('profile_image', profileImage);
            DoctorDrawer.profileImageNotifier.value = profileImage;
          }
        }
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return;
      if (!silent && mounted) setState(() => _error = e.message ?? 'تعذر الاتصال بالخادم');
    } catch (_) {
      if (!silent && mounted) setState(() => _error = 'حدث خطأ غير متوقع');
    } finally {
      if (!silent && mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        final bytes = await File(image.path).readAsBytes();
        final base64Image = base64Encode(bytes);
        setState(() => _profileImage = base64Image);
        await _uploadImage(base64Image);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('حدث خطأ أثناء اختيار الصورة', style: TextStyle(fontFamily: 'Cairo'))),
        );
      }
    }
  }

  Future<void> _uploadImage(String base64Image) async {
    try {
      final dio = DioFactory.getDio();
      final response = await dio.post(
        '${ApiConstants.otpBaseUrl}/update_profile',
        data: {'profile_image': base64Image},
      );
      if (response.statusCode == 200) {
        await SharedPrefHelper.setData('profile_image', base64Image);
        DoctorDrawer.profileImageNotifier.value = base64Image;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم تحديث الصورة الشخصية بنجاح', style: TextStyle(fontFamily: 'Cairo')),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('حدث خطأ أثناء تحديث الصورة', style: TextStyle(fontFamily: 'Cairo'))),
        );
      }
    }
  }

  Future<void> _updateProfileData(Map<String, dynamic> data) async {
    setState(() => _loading = true);
    try {
      final token = await SharedPrefHelper.getSecuredString(SharedPrefKeys.userToken);
      if (token == null || token.isEmpty) throw Exception('Token غير موجود');

      final dio = Dio(BaseOptions(
        baseUrl: ApiConstants.otpBaseUrl,
        connectTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 60),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ));

      final response = await dio.post('/update_profile', data: data);

      if (response.statusCode == 200) {
        final responseData = response.data;
        if (responseData is Map && responseData['status'] == 'success') {
          setState(() {
            if (data.containsKey('category')) _category = data['category'];
            if (data.containsKey('first_name')) _firstName = data['first_name'];
            if (data.containsKey('last_name')) _lastName = data['last_name'];
            if (data.containsKey('phone')) _phone = data['phone'];
            if (data.containsKey('faculty')) _faculty = data['faculty'];
            if (data.containsKey('year')) _year = data['year'];
            if (data.containsKey('governorate')) _governorate = data['governorate'];
          });

          if (_category != null) await SharedPrefHelper.setData('category', _category!);
          if (_firstName != null) await SharedPrefHelper.setData('first_name', _firstName!);
          if (_lastName != null) await SharedPrefHelper.setData('last_name', _lastName!);
          if (_phone != null) await SharedPrefHelper.setData('phone', _phone!);
          if (_faculty != null) await SharedPrefHelper.setData('faculty', _faculty!);
          if (_year != null) await SharedPrefHelper.setData('year', _year!);
          if (_governorate != null) await SharedPrefHelper.setData('governorate', _governorate!);

          await _fetchProfile(silent: true);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('تم تحديث البيانات بنجاح', style: TextStyle(fontFamily: 'Cairo')),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      }
    } on DioException catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('حدث خطأ أثناء التحديث', style: TextStyle(fontFamily: 'Cairo')), backgroundColor: Colors.red),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('حدث خطأ أثناء التحديث', style: TextStyle(fontFamily: 'Cairo')), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showEditProfileDialog() {
    final firstNameCtrl = TextEditingController(text: _firstName);
    final lastNameCtrl = TextEditingController(text: _lastName);
    final phoneCtrl = TextEditingController(text: _phone);

    String? selectedCategory = _category;
    String? selectedYear = _year;
    String? selectedGovernorate = _governorate;
    String? selectedCollege = _faculty;

    if (selectedCategory != null && !_categories.contains(selectedCategory)) selectedCategory = null;
    if (selectedYear != null && !_studyYears.contains(selectedYear)) selectedYear = null;
    if (selectedGovernorate != null && !_governorates.contains(selectedGovernorate)) selectedGovernorate = null;
    if (selectedCollege != null && !_colleges.contains(selectedCollege)) selectedCollege = null;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return Directionality(
            textDirection: TextDirection.rtl,
            child: AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('تعديل البيانات', textAlign: TextAlign.center, style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700)),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: double.maxFinite,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _dialogField(firstNameCtrl, 'الاسم الأول', Icons.badge_outlined),
                      const SizedBox(height: 12),
                      _dialogField(lastNameCtrl, 'اسم العائلة', Icons.person_outlined),
                      const SizedBox(height: 12),
                      _dialogField(phoneCtrl, 'رقم الهاتف', Icons.phone_outlined, isPhone: true),
                      const SizedBox(height: 12),
                      _dialogDropdown(
                        label: 'الكلية', icon: Icons.school_outlined,
                        value: selectedCollege, items: _colleges,
                        onChanged: (v) => setStateDialog(() => selectedCollege = v),
                      ),
                      const SizedBox(height: 12),
                      _dialogDropdown(
                        label: 'السنة الدراسية', icon: Icons.event_note_outlined,
                        value: selectedYear, items: _studyYears,
                        onChanged: (v) => setStateDialog(() => selectedYear = v),
                      ),
                      const SizedBox(height: 12),
                      _dialogDropdown(
                        label: 'المحافظة', icon: Icons.place_outlined,
                        value: selectedGovernorate, items: _governorates,
                        onChanged: (v) => setStateDialog(() => selectedGovernorate = v),
                      ),
                      const SizedBox(height: 12),
                      _dialogDropdown(
                        label: 'التخصص', icon: Icons.medical_services_outlined,
                        value: selectedCategory, items: _categories,
                        onChanged: (v) => setStateDialog(() => selectedCategory = v),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo', color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF021433),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () async {
                    Navigator.pop(context);
                    await _updateProfileData({
                      'first_name': firstNameCtrl.text,
                      'last_name': lastNameCtrl.text,
                      'phone': phoneCtrl.text,
                      'category': selectedCategory,
                      'year': selectedYear,
                      'governorate': selectedGovernorate,
                      'faculty': selectedCollege,
                    });
                  },
                  child: const Text('حفظ', style: TextStyle(fontFamily: 'Cairo', color: Colors.white)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _dialogField(TextEditingController ctrl, String label, IconData icon, {bool isPhone = false}) {
    return TextField(
      controller: ctrl,
      style: const TextStyle(fontFamily: 'Cairo'),
      keyboardType: isPhone ? TextInputType.phone : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontFamily: 'Cairo'),
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
    );
  }

  Widget _dialogDropdown({
    required String label,
    required IconData icon,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontFamily: 'Cairo'),
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
      isExpanded: true,
      items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontFamily: 'Cairo')))).toList(),
      onChanged: onChanged,
    );
  }

  // ─────────────────────────── BUILD ──────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final baseFontSize = width * 0.04;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: isDark ? const Color(0xFF0D1117) : const Color(0xFFF5F6FA),
      drawer: const DoctorDrawer(),
      appBar: AppBar(
        toolbarHeight: 60,
        elevation: 0,
        backgroundColor: isDark ? const Color(0xFF161B22) : Colors.white,
        automaticallyImplyLeading: false,
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: Icon(Icons.menu, size: 24 * (width / 390), color: theme.iconTheme.color),
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          ),
        ),
        title: Text(
          'الملف الشخصي',
          style: TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.w700,
            fontSize: baseFontSize * 1.125,
            color: isDark ? Colors.white : const Color(0xFF021433),
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF021433).withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF021433)),
            ),
            tooltip: 'تعديل البيانات',
            onPressed: _showEditProfileDialog,
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: isDark ? Colors.grey[800] : const Color(0xFFE5E7EB),
          ),
        ),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: RefreshIndicator(
          onRefresh: _fetchProfile,
          color: colorScheme.primary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                // ── Header Banner ──────────────────────────────────────────
                _buildHeaderBanner(width, baseFontSize, isDark),

                // ── Info Sections ──────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: Column(
                    children: [
                      // ── Personal info ──────────────────────────────────
                      _buildSectionCard(
                        isDark: isDark,
                        title: 'المعلومات الشخصية',
                        icon: Icons.person_outline,
                        children: [
                          _buildInfoTile(isDark, Icons.badge_outlined, 'الاسم الأول', _firstName, baseFontSize),
                          _buildDivider(isDark),
                          _buildInfoTile(isDark, Icons.perm_identity, 'اسم العائلة', _lastName, baseFontSize),
                          _buildDivider(isDark),
                          _buildInfoTile(isDark, Icons.email_outlined, 'البريد الإلكتروني', _email, baseFontSize),
                          _buildDivider(isDark),
                          _buildInfoTile(isDark, Icons.phone_outlined, 'رقم الهاتف', _phone, baseFontSize),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // ── Academic info ──────────────────────────────────
                      _buildSectionCard(
                        isDark: isDark,
                        title: 'المعلومات الأكاديمية',
                        icon: Icons.school_outlined,
                        children: [
                          _buildInfoTile(isDark, Icons.school_outlined, 'الكلية', _faculty, baseFontSize),
                          _buildDivider(isDark),
                          _buildInfoTile(isDark, Icons.event_note_outlined, 'السنة الدراسية', _year, baseFontSize),
                          _buildDivider(isDark),
                          _buildInfoTile(isDark, Icons.medical_services_outlined, 'التخصص', _category, baseFontSize),
                          _buildDivider(isDark),
                          _buildInfoTile(isDark, Icons.place_outlined, 'المحافظة', _governorate, baseFontSize),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // ── Security ───────────────────────────────────────
                      _buildSectionCard(
                        isDark: isDark,
                        title: 'الأمان',
                        icon: Icons.security_outlined,
                        children: [
                          ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                            leading: Container(
                              width: 36, height: 36,
                              decoration: BoxDecoration(
                                color: isDark ? Colors.grey[800] : const Color(0xFFF3F4F6),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.lock_outline, size: 18, color: Color(0xFF021433)),
                            ),
                            title: const Text('تغيير كلمة المرور', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w600)),
                            trailing: const Icon(Icons.arrow_back_ios, size: 14, color: Colors.grey),
                            onTap: () => Navigator.pushNamed(context, Routes.resetPasswordScreen),
                          ),
                        ],
                      ),

                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.red[200]!),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline, color: Colors.red),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(_error!, style: const TextStyle(fontFamily: 'Cairo', color: Colors.red)),
                              ),
                            ],
                          ),
                        ),
                      ],
                      SizedBox(height: MediaQuery.of(context).padding.bottom + 20),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────── Header Banner ──────────────────────────────────────
  Widget _buildHeaderBanner(double width, double baseFontSize, bool isDark) {
    final fullName = _composeName(_firstName, _lastName);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Color(0xFF021433), Color(0xFF0A3A7A)],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF021433).withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        top: 28,
        bottom: 32,
        left: 20,
        right: 20,
      ),
      child: Column(
        children: [
          // Avatar
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                width: 90 * (width / 390),
                height: 90 * (width / 390),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  color: Colors.grey[300],
                ),
                child: ClipOval(
                  child: _profileImage != null
                      ? Image.memory(base64Decode(_profileImage!), fit: BoxFit.cover)
                      : const Icon(Icons.person, size: 48, color: Colors.grey),
                ),
              ),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.camera_alt, size: 15, color: Color(0xFF021433)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Name
          if (_loading)
            Container(
              width: 140,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
            )
          else
            Text(
              fullName != null ? 'د. $fullName' : 'الملف الشخصي',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.w700,
                fontSize: baseFontSize * 1.25,
                color: Colors.white,
              ),
            ),
          const SizedBox(height: 6),
          // Email
          if (_loading)
            Container(
              width: 180,
              height: 14,
              margin: const EdgeInsets.only(top: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
              ),
            )
          else if (_email != null)
            Text(
              _email!,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: baseFontSize * 0.8,
                color: Colors.white.withOpacity(0.75),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          const SizedBox(height: 10),
          // Category chip
          if (_category != null && _category!.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.3)),
              ),
              child: Text(
                _category!,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.w600,
                  fontSize: baseFontSize * 0.8,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ─────────────────────────── Section Card ───────────────────────────────────
  Widget _buildSectionCard({
    required bool isDark,
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161B22) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.grey[800]! : const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.2) : Colors.grey.withOpacity(0.07),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                Icon(icon, size: 16, color: const Color(0xFF021433)),
                const SizedBox(width: 6),
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: isDark ? Colors.white70 : const Color(0xFF021433),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Divider(height: 1, color: isDark ? Colors.grey[800] : const Color(0xFFE5E7EB)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────── Info Tile ──────────────────────────────────────
  Widget _buildInfoTile(bool isDark, IconData icon, String label, String? value, double baseFontSize) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[800] : const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: const Color(0xFF021433)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: baseFontSize * 0.7,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 2),
                _loading
                    ? Container(
                        height: 14,
                        width: 120,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey[800] : Colors.grey[200],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      )
                    : Text(
                        (value?.isNotEmpty ?? false) ? value! : '—',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.w600,
                          fontSize: baseFontSize * 0.875,
                          color: isDark ? Colors.white : const Color(0xFF111827),
                        ),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(bool isDark) =>
      Divider(height: 1, color: isDark ? Colors.grey[800] : const Color(0xFFF3F4F6));

  String? _composeName(String? f, String? l) {
    if ((f == null || f.isEmpty) && (l == null || l.isEmpty)) return null;
    if ((f?.isNotEmpty ?? false) && (l?.isNotEmpty ?? false)) return '$f $l';
    return f?.isNotEmpty == true ? f : l;
  }
}
