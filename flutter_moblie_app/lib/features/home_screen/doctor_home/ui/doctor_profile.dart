import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:thotha_mobile_app/core/helpers/shared_pref_helper.dart';
import 'package:thotha_mobile_app/core/helpers/constants.dart';
import 'package:thotha_mobile_app/core/networking/api_constants.dart';
import 'package:thotha_mobile_app/core/networking/api_service.dart';
import 'package:thotha_mobile_app/core/networking/dio_factory.dart';
import 'package:thotha_mobile_app/core/networking/models/category_model.dart';
import 'package:thotha_mobile_app/core/networking/models/city_model.dart';
import 'package:thotha_mobile_app/core/networking/models/university_model.dart';
import 'package:thotha_mobile_app/core/routing/routes.dart';
import 'package:thotha_mobile_app/features/home_screen/doctor_home/drawer/doctor_drawer_screen.dart';
import 'package:thotha_mobile_app/features/home_screen/doctor_home/ui/account_deletion_screen.dart';

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

  // Populated from API — empty until fetched
  List<String> _governorates = [];
  List<String> _categories = [];
  List<String> _colleges = [];

  // No API for study years — hardcoded
  final List<String> _studyYears = [
    'الفرقة الرابعة', 'الفرقة الخامسة', 'امتياز',
  ];

  // Flag set when ANY reference-data API call fails
  bool _refDataError = false;

  // API service
  final ApiService _apiService = ApiService();

  // Loading flags for API dropdowns
  bool _loadingCities = false;
  bool _loadingUniversities = false;
  bool _loadingCategories = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
    _fetchReferenceData();
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
    if (mounted) setState(() => _loadingCities = true);
    try {
      final result = await _apiService.getCities();
      if (result['success'] == true && mounted) {
        final cities = result['data'] as List<CityModel>;
        setState(() => _governorates = cities.map((c) => c.name).toList());
      } else if (mounted) {
        setState(() => _refDataError = true);
      }
    } catch (_) {
      if (mounted) setState(() => _refDataError = true);
    } finally {
      if (mounted) setState(() => _loadingCities = false);
    }
  }

  Future<void> _fetchUniversities() async {
    if (mounted) setState(() => _loadingUniversities = true);
    try {
      final result = await _apiService.getUniversities();
      if (result['success'] == true && mounted) {
        final universities = result['data'] as List<UniversityModel>;
        setState(() => _colleges = universities.map((u) => u.name).toList());
      } else if (mounted) {
        setState(() => _refDataError = true);
      }
    } catch (_) {
      if (mounted) setState(() => _refDataError = true);
    } finally {
      if (mounted) setState(() => _loadingUniversities = false);
    }
  }

  Future<void> _fetchCategories() async {
    if (mounted) setState(() => _loadingCategories = true);
    try {
      final result = await _apiService.getCategories();
      if (result['success'] == true && mounted) {
        final categories = result['data'] as List<CategoryModel>;
        setState(() => _categories = categories.map((c) => c.name).toList());
      } else if (mounted) {
        setState(() => _refDataError = true);
      }
    } catch (_) {
      if (mounted) setState(() => _refDataError = true);
    } finally {
      if (mounted) setState(() => _loadingCategories = false);
    }
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
      // Use the unified authenticated endpoint
      final result = await _apiService.updateDoctor({'profile_image': base64Image});
      if (result['success'] == true) {
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
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['error']?.toString() ?? 'حدث خطأ أثناء تحديث الصورة', style: const TextStyle(fontFamily: 'Cairo')),
              backgroundColor: Colors.red,
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
      // Use the unified authenticated endpoint
      final result = await _apiService.updateDoctor(data);

      if (result['success'] == true) {
        // Keep local UI values in sync with what user edited (best-effort)
        if (mounted) {
          setState(() {
            if (data.containsKey('category')) _category = data['category']?.toString();
            if (data.containsKey('first_name')) _firstName = data['first_name']?.toString();
            if (data.containsKey('firstName')) _firstName = data['firstName']?.toString();
            if (data.containsKey('last_name')) _lastName = data['last_name']?.toString();
            if (data.containsKey('lastName')) _lastName = data['lastName']?.toString();
            if (data.containsKey('phone')) _phone = data['phone']?.toString();
            if (data.containsKey('phoneNumber')) _phone = data['phoneNumber']?.toString();
            if (data.containsKey('faculty')) _faculty = data['faculty']?.toString();
            if (data.containsKey('universityName')) _faculty = data['universityName']?.toString();
            if (data.containsKey('year')) _year = data['year']?.toString();
            if (data.containsKey('studyYear')) _year = data['studyYear']?.toString();
            if (data.containsKey('governorate')) _governorate = data['governorate']?.toString();
            if (data.containsKey('cityName')) _governorate = data['cityName']?.toString();
          });
        }

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
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                result['error']?.toString() ?? 'حدث خطأ أثناء التحديث',
                style: const TextStyle(fontFamily: 'Cairo'),
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('حدث خطأ أثناء التحديث', style: TextStyle(fontFamily: 'Cairo')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text('الملف الشخصي', style: TextStyle(fontFamily: 'Cairo')),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () async {
              final data = {
                'first_name': _firstName,
                'last_name': _lastName,
                'email': _email,
                'phone': _phone,
                'faculty': _faculty,
                'year': _year,
                'governorate': _governorate,
                'category': _category,
              };
              // Filter out null values
              data.removeWhere((key, value) => value == null);

              await _updateProfileData(data);
            },
          ),
        ],
      ),
      body: _loading ? const Center(child: CircularProgressIndicator()) : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: _profileImage != null ? MemoryImage(base64Decode(_profileImage!)) : null,
                  child: _profileImage == null
                      ? const Icon(Icons.camera_alt, size: 50, color: Colors.grey)
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildTextField('الاسم الأول', _firstName, (value) => setState(() => _firstName = value)),
            _buildTextField('اسم العائلة', _lastName, (value) => setState(() => _lastName = value)),
            _buildTextField('البريد الإلكتروني', _email, (value) => setState(() => _email = value), keyboardType: TextInputType.emailAddress),
            _buildTextField('رقم الهاتف', _phone, (value) => setState(() => _phone = value), keyboardType: TextInputType.phone),
            _buildDropdownField('الكلية', _faculty, _colleges, (value) => setState(() => _faculty = value)),
            _buildDropdownField('الفرقة الدراسية', _year, _studyYears, (value) => setState(() => _year = value)),
            _buildDropdownField('المحافظة', _governorate, _governorates, (value) => setState(() => _governorate = value)),
            _buildDropdownField('التخصص', _category, _categories, (value) => setState(() => _category = value)),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () async {
                final data = {
                  'first_name': _firstName,
                  'last_name': _lastName,
                  'email': _email,
                  'phone': _phone,
                  'faculty': _faculty,
                  'year': _year,
                  'governorate': _governorate,
                  'category': _category,
                };
                // Filter out null values
                data.removeWhere((key, value) => value == null);

                await _updateProfileData(data);
              },
              child: const Text('حفظ التغييرات', style: TextStyle(fontFamily: 'Cairo')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, String? initialValue, ValueChanged<String?> onChanged, {TextInputType keyboardType = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        initialValue: initialValue,
        onChanged: onChanged,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
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
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: selectedValue,
            onChanged: onChanged,
            isExpanded: true,
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
