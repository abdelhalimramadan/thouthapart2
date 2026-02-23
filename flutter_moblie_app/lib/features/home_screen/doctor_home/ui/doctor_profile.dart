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
      if (mounted) {
        setState(() {
          _error = null;
          _loading = true;
        });
      }
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
          if (res.statusCode == 200) {
            response = res;
          }
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
        
        String? phone;
        phone = userMap?['phone']?.toString();
        
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

        if (phone != null && phone.contains('@')) {
          phone = null;
        }

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
          if ((email?.isNotEmpty ?? false)) {
            await SharedPrefHelper.setData('email', email);
          }
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
      if (!silent && mounted) {
        setState(() => _error = e.message ?? 'تعذر الاتصال بالخادم');
      }
    } catch (_) {
      if (!silent && mounted) {
        setState(() => _error = 'حدث خطأ غير متوقع');
      }
    } finally {
      if (!silent && mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        final bytes = await File(image.path).readAsBytes();
        final base64Image = base64Encode(bytes);

        setState(() {
          _profileImage = base64Image;
        });

        await _uploadImage(base64Image);
      }
    } catch (e) {
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
            const SnackBar(content: Text('تم تحديث الصورة الشخصية بنجاح', style: TextStyle(fontFamily: 'Cairo'))),
          );
        }
      }
    } catch (e) {
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
      if (token == null || token.isEmpty) {
        throw Exception('Token غير موجود. يرجى تسجيل الدخول مرة أخرى');
      }
      
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
      
      final response = await dio.post(
        '/update_profile',
        data: data,
      );
      
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
              const SnackBar(content: Text('تم تحديث البيانات بنجاح', style: TextStyle(fontFamily: 'Cairo')), backgroundColor: Colors.green),
            );
          }
        }
      }
    } on DioException catch (e) {
      String errorMessage = 'حدث خطأ أثناء التحديث';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage, style: const TextStyle(fontFamily: 'Cairo')), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ أثناء التحديث', style: const TextStyle(fontFamily: 'Cairo')), backgroundColor: Colors.red),
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
              title: const Text('تعديل البيانات', textAlign: TextAlign.center, style: TextStyle(fontFamily: 'Cairo')),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: double.maxFinite,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: firstNameCtrl,
                        style: const TextStyle(fontFamily: 'Cairo'),
                        decoration: const InputDecoration(labelText: 'الاسم الأول', labelStyle: TextStyle(fontFamily: 'Cairo')),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: lastNameCtrl,
                        style: const TextStyle(fontFamily: 'Cairo'),
                        decoration: const InputDecoration(labelText: 'اسم العائلة', labelStyle: TextStyle(fontFamily: 'Cairo')),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: phoneCtrl,
                        style: const TextStyle(fontFamily: 'Cairo'),
                        decoration: const InputDecoration(labelText: 'رقم الهاتف', labelStyle: TextStyle(fontFamily: 'Cairo')),
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: selectedCollege,
                        decoration: const InputDecoration(labelText: 'الكلية', labelStyle: TextStyle(fontFamily: 'Cairo')),
                        isExpanded: true,
                        items: _colleges.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontFamily: 'Cairo')))).toList(),
                        onChanged: (v) => setStateDialog(() => selectedCollege = v),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: selectedYear,
                        decoration: const InputDecoration(labelText: 'السنة الدراسية', labelStyle: TextStyle(fontFamily: 'Cairo')),
                        isExpanded: true,
                        items: _studyYears.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontFamily: 'Cairo')))).toList(),
                        onChanged: (v) => setStateDialog(() => selectedYear = v),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: selectedGovernorate,
                        decoration: const InputDecoration(labelText: 'المحافظة', labelStyle: TextStyle(fontFamily: 'Cairo')),
                        isExpanded: true,
                        items: _governorates.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontFamily: 'Cairo')))).toList(),
                        onChanged: (v) => setStateDialog(() => selectedGovernorate = v),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: selectedCategory, 
                        decoration: const InputDecoration(labelText: 'التخصص', labelStyle: TextStyle(fontFamily: 'Cairo')),
                        isExpanded: true,
                        items: _categories.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontFamily: 'Cairo')))).toList(),
                        onChanged: (v) => setStateDialog(() => selectedCategory = v), 
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo')),
                ),
                ElevatedButton(
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
                  child: const Text('حفظ', style: TextStyle(fontFamily: 'Cairo')),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final baseFontSize = width * 0.04;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: theme.scaffoldBackgroundColor,
      drawer: const DoctorDrawer(),
      appBar: AppBar(
        toolbarHeight: 75.6,
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        automaticallyImplyLeading: false,
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu, size: 24 * (width / 390)),
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          ),
        ),
        title: Center(
          child: Text(
            'الملف الشخصي',
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              fontFamily: 'Cairo',
              fontSize: baseFontSize * 1.125, // 18
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_note),
            tooltip: 'تعديل البيانات',
            onPressed: _showEditProfileDialog,
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: theme.brightness == Brightness.dark ? Colors.grey[700] : const Color(0xFFE5E7EB),
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
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _headerCard(theme, textTheme, colorScheme, width, baseFontSize),
                  const SizedBox(height: 12),
                  _infoCard(theme, textTheme, colorScheme, width, baseFontSize),
                  const SizedBox(height: 12),
                  _actionCard(
                    theme: theme,
                    colorScheme: colorScheme,
                    width: width,
                    child: ListTile(
                      leading: Icon(Icons.lock_outline, color: theme.iconTheme.color),
                      title: Text(
                        'تغيير كلمة المرور',
                        style: textTheme.bodyLarge?.copyWith(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.right,
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () => Navigator.pushNamed(context, Routes.resetPasswordScreen),
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    _errorBanner(textTheme, colorScheme, _error!, width, baseFontSize),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _headerCard(ThemeData theme, TextTheme textTheme, ColorScheme colorScheme, double width, double baseFontSize) {
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey[700]! : const Color(0xFFE5E7EB),
          width: 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withValues(alpha: 0.3) : Colors.grey.withValues(alpha: 0.1),
            offset: const Offset(0, 1),
            blurRadius: 3,
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 28 * (width / 390),
                backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
                backgroundImage: _profileImage != null ? MemoryImage(base64Decode(_profileImage!)) : null,
                child: _profileImage == null ? Icon(Icons.person_outline, color: theme.iconTheme.color) : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: InkWell(
                  onTap: _pickImage,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: theme.cardTheme.color ?? Colors.white, width: 1.5),
                    ),
                    child: Icon(
                      Icons.camera_alt,
                      size: 12 * (width / 390),
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _loading
                    ? _shimmerLine(width: 120 * (width / 390), height: 18, theme: theme)
                    : Text(
                        _composeName(_firstName, _lastName) ?? 'دكتور',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: baseFontSize * 1.125, // 18
                          fontFamily: 'Cairo',
                        ),
                        textAlign: TextAlign.right,
                      ),
                const SizedBox(height: 4),
                _loading
                    ? _shimmerLine(width: 180 * (width / 390), height: 14, theme: theme)
                    : Text(
                        _email ?? '-',
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.7),
                          fontFamily: 'Cairo',
                        ),
                        textAlign: TextAlign.right,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoCard(ThemeData theme, TextTheme textTheme, ColorScheme colorScheme, double width, double baseFontSize) {
    final isDark = theme.brightness == Brightness.dark;
    final items = <_InfoItem>[
      _InfoItem(icon: Icons.badge_outlined, label: 'الاسم الأول', value: _firstName),
      _InfoItem(icon: Icons.perm_identity, label: 'اسم العائلة', value: _lastName),
      _InfoItem(icon: Icons.email_outlined, label: 'البريد الإلكتروني', value: _email),
      _InfoItem(icon: Icons.phone_outlined, label: 'رقم الهاتف', value: _phone),
      _InfoItem(icon: Icons.school_outlined, label: 'الكلية', value: _faculty),
      _InfoItem(icon: Icons.event_note_outlined, label: 'السنة الدراسية', value: _year),
      _InfoItem(icon: Icons.work_outline, label: 'التخصص', value: _category),
      _InfoItem(icon: Icons.place_outlined, label: 'المحافظة', value: _governorate),
    ];

    return Container(
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey[700]! : const Color(0xFFE5E7EB),
          width: 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withValues(alpha: 0.3) : Colors.grey.withValues(alpha: 0.1),
            offset: const Offset(0, 1),
            blurRadius: 3,
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            _infoRow(items[i], theme, textTheme, colorScheme, width, baseFontSize),
            if (i != items.length - 1)
              Divider(
                height: 1,
                thickness: 1,
                color: isDark ? Colors.grey[700] : const Color(0xFFE5E7EB),
              ),
          ]
        ],
      ),
    );
  }

  Widget _infoRow(_InfoItem item, ThemeData theme, TextTheme textTheme, ColorScheme colorScheme, double width, double baseFontSize) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      child: Row(
        children: [
          Icon(item.icon, color: theme.iconTheme.color, size: 22 * (width / 390)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  item.label,
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                    fontSize: baseFontSize * 0.75, // 12
                    fontFamily: 'Cairo',
                  ),
                  textAlign: TextAlign.right,
                ),
                const SizedBox(height: 2),
                _loading
                    ? _shimmerLine(width: 160 * (width / 390), height: 16, theme: theme)
                    : Text(
                        (item.value?.isNotEmpty ?? false) ? item.value! : '-',
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: baseFontSize * 0.875, // 14
                          fontFamily: 'Cairo',
                        ),
                        textAlign: TextAlign.right,
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorBanner(TextTheme textTheme, ColorScheme colorScheme, String message, double width, double baseFontSize) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: colorScheme.error),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onErrorContainer,
                fontFamily: 'Cairo',
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  String? _composeName(String? f, String? l) {
    if ((f == null || f.isEmpty) && (l == null || l.isEmpty)) return null;
    if (f != null && f.isNotEmpty && l != null && l.isNotEmpty) return '$f $l';
    return f?.isNotEmpty == true ? f : l;
  }

  Widget _shimmerLine({required double width, required double height, required ThemeData theme}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark ? Colors.grey[800] : Colors.grey[200],
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }

  Widget _actionCard({
    required ThemeData theme,
    required ColorScheme colorScheme,
    required double width,
    required Widget child,
  }) {
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey[700]! : const Color(0xFFE5E7EB),
          width: 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withValues(alpha: 0.3) : Colors.grey.withValues(alpha: 0.1),
            offset: const Offset(0, 1),
            blurRadius: 3,
          ),
        ],
      ),
      child: child,
    );
  }
}

class _InfoItem {
  final IconData icon;
  final String label;
  final String? value;

  _InfoItem({required this.icon, required this.label, required this.value});
}
