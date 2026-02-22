import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:intl/intl.dart';
import 'package:thotha_mobile_app/core/helpers/constants.dart';
import 'package:thotha_mobile_app/core/helpers/shared_pref_helper.dart';
import 'package:thotha_mobile_app/core/routing/routes.dart';
import 'package:thotha_mobile_app/core/theming/colors.dart';
import 'package:thotha_mobile_app/core/theming/styles.dart';
import 'package:thotha_mobile_app/core/widgets/app_text_button.dart';
import 'package:thotha_mobile_app/core/di/dependency_injection.dart';
import 'package:thotha_mobile_app/features/home_screen/data/models/case_request_body.dart';
import 'package:thotha_mobile_app/features/home_screen/data/repositories/case_request_repo.dart';
import 'package:thotha_mobile_app/features/home_screen/data/repositories/doctor_repository.dart';
import 'package:thotha_mobile_app/core/networking/models/category_model.dart';
import 'package:thotha_mobile_app/core/networking/models/city_model.dart';

class AddCaseRequestScreen extends StatefulWidget {
  const AddCaseRequestScreen({super.key});

  @override
  State<AddCaseRequestScreen> createState() => _AddCaseRequestScreenState();
}

class _AddCaseRequestScreenState extends State<AddCaseRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedCategory;
  int? _selectedCityId;
  List<CityModel> _cities = [];
  List<CategoryModel> _categoriesList = [];
  bool _isLoadingData = false;

  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
  }

  Future<void> _fetchInitialData() async {
    setState(() {
      _isLoadingData = true;
    });
    try {
      final repo = getIt<DoctorRepository>();
      final citiesFuture = repo.getCities();
      final categoriesFuture = repo.getCategories();
      
      final results = await Future.wait([citiesFuture, categoriesFuture]);
      
      if (mounted) {
        setState(() {
          _cities = results[0] as List<CityModel>;
          _categoriesList = results[1] as List<CategoryModel>;
          _isLoadingData = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingData = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('فشل في تحميل البيانات')),
        );
      }
    }
  }

  @override
  void dispose() {
    _dateController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
      locale: const Locale('ar', 'EG'),
    );
    if (picked != null) {
      setState(() {
        _dateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Localizations.override(
          context: context,
          locale: const Locale('ar', 'EG'),
          child: child,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _timeController.text = picked.format(context);
      });
    }
  }

  void _publishRequest() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final token = await SharedPrefHelper.getSecuredString(SharedPrefKeys.userToken);
    
    if (token.isEmpty ) {
      _showLoginDialog();
    } else {
      try {
        if (mounted) {
           showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const Center(child: CircularProgressIndicator()),
          );
        }

        final selectedCityName = _cities
            .firstWhere((c) => c.id == _selectedCityId,
                orElse: () => CityModel(id: -1, name: ''))
            .name;

        final body = CaseRequestBody(
          specialization: _selectedCategory!,
          date: _dateController.text,
          time: _timeController.text,
          location: selectedCityName,
          description: 'No details', 
        );

        final repo = getIt<CaseRequestRepo>();
        final result = await repo.createCaseRequest(body);

        if (mounted) Navigator.pop(context);

        if (result['success'] == true) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('تم نشر الطلب بنجاح!'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(context);
          }
        } else {
           if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result['error'] ?? 'فشل في نشر الطلب'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) Navigator.pop(context); 
         if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('حدث خطأ غير متوقع'),
                backgroundColor: Colors.red,
              ),
            );
          }
      }
    }
  }

  void _showLoginDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Directionality(
          textDirection: ui.TextDirection.rtl,
          child: AlertDialog(
            title: Text('تسجيل الدخول مطلوب', style: TextStyles.font18DarkBlueBold),
            content: Text(
              'يجب عليك تسجيل الدخول أولاً لتتمكن من نشر طلب حالة.',
              style: TextStyles.font14GrayRegular,
            ),
            actions: [
              TextButton(
                child: Text('إلغاء', style: TextStyles.font14GrayRegular),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                child: Text('تسجيل الدخول', style: TextStyles.font14BlueSemiBold),
                onPressed: () {
                  Navigator.of(context).pop(); 
                  Navigator.of(context).pushNamed(Routes.loginScreen);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final baseFontSize = width * 0.04;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'إضافة طلب حالة',
          style: TextStyles.font18DarkBlueBold.copyWith(
            fontFamily: 'Cairo',
            fontSize: baseFontSize * 1.125, // 18sp
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: ColorsManager.darkBlue),
      ),
      backgroundColor: ColorsManager.offWhite,
      body: SafeArea(
        child: Directionality(
          textDirection: ui.TextDirection.rtl,
          child: SingleChildScrollView(
            padding: EdgeInsets.all(width * 0.06), // 24.w
            child: Form(
              key: _formKey,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: width >= 600 ? 500 : double.infinity,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'بيانات الحالة',
                      style: TextStyles.font18DarkBlueBold.copyWith(
                        fontFamily: 'Cairo',
                        fontSize: baseFontSize * 1.125,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'قم بملء البيانات التالية لنشر طلب حالة جديد',
                      style: TextStyles.font14GrayRegular.copyWith(
                        fontFamily: 'Cairo',
                        fontSize: baseFontSize * 0.875,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Specialization
                    _buildLabel('التخصص', baseFontSize),
                    const SizedBox(height: 8),
                    _isLoadingData
                        ? const Center(child: CircularProgressIndicator())
                        : DropdownButtonFormField<String>(
                            value: _selectedCategory,
                            decoration: _buildInputDecoration(
                              hint: 'اختر التخصص',
                              prefixIcon: Icons.medical_services_outlined,
                              width: width,
                              baseFontSize: baseFontSize,
                            ),
                            items: _categoriesList
                                .map((c) => DropdownMenuItem(
                                    value: c.name, child: Text(c.name, style: const TextStyle(fontFamily: 'Cairo'))))
                                .toList(),
                            onChanged: (v) =>
                                setState(() => _selectedCategory = v),
                            validator: (value) =>
                                value == null ? 'يرجى اختيار التخصص' : null,
                            icon: const Icon(Icons.keyboard_arrow_down,
                                color: ColorsManager.gray),
                          ),
                    const SizedBox(height: 16),

                    // Date
                    _buildLabel('التاريخ المتاح', baseFontSize),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _dateController,
                      readOnly: true,
                      onTap: () => _selectDate(context),
                      decoration: _buildInputDecoration(
                        hint: 'يوم / شهر / سنة',
                        prefixIcon: Icons.calendar_today_outlined,
                        width: width,
                        baseFontSize: baseFontSize,
                      ),
                      validator: (value) =>
                          value!.isEmpty ? 'يرجى اختيار التاريخ' : null,
                      style: const TextStyle(fontFamily: 'Cairo'),
                    ),
                    const SizedBox(height: 16),

                    // Time
                    _buildLabel('الوقت المتاح', baseFontSize),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _timeController,
                      readOnly: true,
                      onTap: () => _selectTime(context),
                      decoration: _buildInputDecoration(
                        hint: '00:00',
                        prefixIcon: Icons.access_time_outlined,
                        width: width,
                        baseFontSize: baseFontSize,
                      ),
                      validator: (value) =>
                          value!.isEmpty ? 'يرجى اختيار الوقت' : null,
                      style: const TextStyle(fontFamily: 'Cairo'),
                    ),
                    const SizedBox(height: 16),

                    // Location / City
                    _buildLabel('المكان / المدينة', baseFontSize),
                    const SizedBox(height: 8),
                    _isLoadingData
                        ? const Center(child: CircularProgressIndicator())
                        : DropdownButtonFormField<int>(
                            value: _selectedCityId,
                            decoration: _buildInputDecoration(
                              hint: 'اختر المدينة',
                              prefixIcon: Icons.location_on_outlined,
                              width: width,
                              baseFontSize: baseFontSize,
                            ),
                            items: _cities
                                .map((c) => DropdownMenuItem(
                                      value: c.id,
                                      child: Text(c.name, style: const TextStyle(fontFamily: 'Cairo')),
                                    ))
                                .toList(),
                            onChanged: (v) => setState(() => _selectedCityId = v),
                            validator: (value) =>
                                value == null ? 'يرجى اختيار المدينة' : null,
                            icon: const Icon(Icons.keyboard_arrow_down,
                                color: ColorsManager.gray),
                          ),
                    const SizedBox(height: 40),

                    // Publish Button
                    AppTextButton(
                      buttonText: 'نشر الطلب',
                      textStyle: TextStyles.font16WhiteSemiBold.copyWith(
                        fontFamily: 'Cairo',
                        fontSize: baseFontSize,
                      ),
                      backgroundColor: ColorsManager.mainBlue,
                      onPressed: _publishRequest,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String hint,
    required IconData prefixIcon,
    required double width,
    required double baseFontSize,
  }) {
    return InputDecoration(
      isDense: true,
      contentPadding: EdgeInsets.symmetric(horizontal: width * 0.05, vertical: 18),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: ColorsManager.mainBlue, width: 1.3),
        borderRadius: BorderRadius.circular(16.0),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: ColorsManager.lighterGray, width: 1.3),
        borderRadius: BorderRadius.circular(16.0),
      ),
      errorBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.red, width: 1.3),
        borderRadius: BorderRadius.circular(16.0),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.red, width: 1.3),
        borderRadius: BorderRadius.circular(16.0),
      ),
      hintStyle: TextStyles.font14LightGrayRegular.copyWith(
        fontFamily: 'Cairo',
        fontSize: baseFontSize * 0.875,
      ),
      hintText: hint,
      prefixIcon: Icon(
        prefixIcon,
        color: ColorsManager.mainBlue,
        size: 22,
      ),
      fillColor: ColorsManager.moreLighterGray,
      filled: true,
    );
  }

  Widget _buildLabel(String label, double baseFontSize) {
    return Text(
      label,
      style: TextStyles.font14DarkBlueMedium.copyWith(
        fontFamily: 'Cairo',
        fontSize: baseFontSize * 0.875,
      ),
    );
  }
}
