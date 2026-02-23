import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/routing/routes.dart';
import '../../../../core/theming/colors.dart';
import '../../../../core/theming/styles.dart';
import '../../../../core/widgets/app_text_button.dart';
import '../logic/sign_up_cubit.dart';
import '../../../../core/networking/api_service.dart';
import '../../../../core/networking/models/city_model.dart';
import '../../../../core/networking/models/university_model.dart';
import '../../../../core/networking/models/category_model.dart';
import '../../../../core/helpers/app_regex.dart';
import '../../login/ui/widgets/password_validations.dart';
import '../../booking/ui/otp_verification_dialog.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  String? _selectedCollege;
  String? _selectedStudyYear;
  String? _selectedGovernorate;
  String? _selectedCategory;

  final _formKey = GlobalKey<FormState>();
  bool hasLowerCase = false;
  bool hasUpperCase = false;
  bool hasSpecialCharacters = false;
  bool hasNumber = false;
  bool hasMinLength = false;
  bool _obscurePassword = true;

  final ApiService _apiService = ApiService();
  List<CityModel> _cities = [];
  List<UniversityModel> _universities = [];
  List<CategoryModel> _categories = [];

  bool _isLoadingCities = false;
  bool _isLoadingUniversities = false;
  bool _isLoadingCategories = false;

  final List<String> _studyYears = [
    'الفرقة الأولى',
    'الفرقة الثانية',
    'الفرقة الثالثة',
    'الفرقة الرابعة',
    'الفرقة الخامسة',
    'امتياز',
  ];

  @override
  void initState() {
    super.initState();
    _fetchReferenceData();
  }

  Future<void> _fetchReferenceData() async {
    await Future.wait([
      _fetchCities(),
      _fetchUniversities(),
      _fetchCategories(),
    ]);
  }

  Future<void> _fetchCities() async {
    setState(() {
      _isLoadingCities = true;
    });
    final result = await _apiService.getCities();
    setState(() {
      _isLoadingCities = false;
      if (result['success']) {
        _cities = result['data'] as List<CityModel>;
      }
    });
  }

  Future<void> _fetchUniversities() async {
    setState(() {
      _isLoadingUniversities = true;
    });
    final result = await _apiService.getUniversities();
    setState(() {
      _isLoadingUniversities = false;
      if (result['success']) {
        _universities = result['data'] as List<UniversityModel>;
      }
    });
  }

  Future<void> _fetchCategories() async {
    setState(() {
      _isLoadingCategories = true;
    });
    final result = await _apiService.getCategories();
    setState(() {
      _isLoadingCategories = false;
      if (result['success']) {
        _categories = result['data'] as List<CategoryModel>;
      }
    });
  }

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;
    final baseFontSize = width * 0.04;

    return BlocProvider(
      create: (context) => SignUpCubit(),
      child: BlocListener<SignUpCubit, SignUpState>(
        listener: (context, state) {
          if (state is SignUpSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
              ),
            );
            Future.delayed(const Duration(seconds: 3), () {
              Navigator.pushReplacementNamed(context, Routes.loginScreen);
            });
          } else if (state is SignUpOtpSent) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => OtpVerificationDialog(
                contactInfo: state.phoneNumber,
                onVerified: (pin) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('تم التحقق من رقم الهاتف بنجاح'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  Navigator.pushReplacementNamed(context, Routes.loginScreen);
                },
              ),
            );
          } else if (state is SignUpError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        child: Scaffold(
          backgroundColor: Colors.white,
          body: Stack(
            children: [
              // Full screen gradient overlay
              Container(
                width: double.infinity,
                height: double.infinity,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(-0.7, -0.7),
                    radius: 1.5,
                    colors: [
                      ColorsManager.layerBlur1.withAlpha(102),
                      ColorsManager.layerBlur1.withAlpha(25),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.3, 0.8],
                  ),
                ),
              ),
              // Bottom-right gradient overlay
              Container(
                width: double.infinity,
                height: double.infinity,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0.7, 0.7),
                    radius: 1.5,
                    colors: [
                      ColorsManager.layerBlur2.withAlpha(102),
                      ColorsManager.layerBlur2.withAlpha(25),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.3, 0.8],
                  ),
                ),
              ),
              SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: width * 0.06,
                        vertical: height * 0.03,
                      ),
                      child: Container(
                        width: double.infinity,
                        constraints: BoxConstraints(
                          maxWidth: width >= 600 ? 500 : double.infinity,
                        ),
                        padding: EdgeInsets.all(width * 0.06),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16.0),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(25),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Directionality(
                          textDirection: TextDirection.rtl,
                          child: Form(
                            key: _formKey,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                SizedBox(height: height * 0.02),
                                Image.asset(
                                  'assets/images/splash-logo.png',
                                  width: width * 0.2,
                                  height: width * 0.2,
                                  fit: BoxFit.contain,
                                ),
                                Text(
                                  ' إنشاء حساب',
                                  style: TextStyle(
                                    fontSize: baseFontSize * 1.5,
                                    fontWeight: FontWeight.bold,
                                    color: ColorsManager.mainBlue,
                                    fontFamily: 'Cairo',
                                  ),
                                ),
                                Text(
                                  'أنشئ حسابك للبدء في استخدام التطبيق.',
                                  style: TextStyle(
                                    fontSize: baseFontSize * 0.875,
                                    color: Colors.grey,
                                    fontFamily: 'Cairo',
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(height: height * 0.02),
                                // First Name Field
                                TextFormField(
                                  controller: firstNameController,
                                  textInputAction: TextInputAction.next,
                                  decoration: InputDecoration(
                                    labelText: 'الاسم الأول',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    prefixIcon: const Icon(Icons.person_outline),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'الرجاء إدخال الاسم الأول';
                                    }
                                    return null;
                                  },
                                ),
                                SizedBox(height: height * 0.02),
                                // Last Name Field
                                TextFormField(
                                  controller: lastNameController,
                                  textInputAction: TextInputAction.next,
                                  decoration: InputDecoration(
                                    labelText: 'الاسم الأخير',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    prefixIcon: const Icon(Icons.person_outline),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'الرجاء إدخال الاسم الأخير';
                                    }
                                    return null;
                                  },
                                ),
                                SizedBox(height: height * 0.02),
                                // Email Field
                                TextFormField(
                                  controller: emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  decoration: InputDecoration(
                                    labelText: 'البريد الإلكتروني',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    prefixIcon: const Icon(Icons.email_outlined),
                                  ),
                                  validator: (value) {
                                    if (value == null ||
                                        value.isEmpty ||
                                        !AppRegex.isEmailValid(value)) {
                                      return 'الرجاء إدخال بريد إلكتروني صالح';
                                    }
                                    return null;
                                  },
                                ),
                                SizedBox(height: height * 0.02),
                                // Phone Number Field
                                TextFormField(
                                  controller: phoneController,
                                  keyboardType: TextInputType.phone,
                                  decoration: InputDecoration(
                                    labelText: 'رقم الهاتف',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    prefixIcon: const Icon(Icons.phone_outlined),
                                  ),
                                  validator: (value) {
                                    if (value == null ||
                                        value.isEmpty ||
                                        !AppRegex.isPhoneNumberValid(value)) {
                                      return 'الرجاء إدخال رقم هاتف صالح';
                                    }
                                    return null;
                                  },
                                ),
                                SizedBox(height: height * 0.02),
                                // University/College Dropdown
                                _isLoadingUniversities
                                    ? const Center(key: ValueKey('uni_loading'), child: CircularProgressIndicator())
                                    : DropdownButtonFormField<String>(
                                        key: const ValueKey('uni_dropdown'),
                                        isExpanded: true,
                                        decoration: InputDecoration(
                                          labelText: 'اختر الكلية',
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        ),
                                        items: _universities
                                            .map((u) => DropdownMenuItem(
                                                value: u.name, child: Text(u.name)))
                                            .toList(),
                                        onChanged: (v) =>
                                            setState(() => _selectedCollege = v),
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'الرجاء اختيار الكلية';
                                          }
                                          return null;
                                        },
                                      ),
                                SizedBox(height: height * 0.02),
                                // Study Year Dropdown
                                DropdownButtonFormField<String>(
                                  isExpanded: true,
                                  decoration: InputDecoration(
                                    labelText: 'السنة الدراسية',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  items: _studyYears
                                      .map((y) => DropdownMenuItem(
                                          value: y, child: Text(y)))
                                      .toList(),
                                  onChanged: (v) =>
                                      setState(() => _selectedStudyYear = v),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'الرجاء اختيار السنة الدراسية';
                                    }
                                    return null;
                                  },
                                ),
                                SizedBox(height: height * 0.02),
                                // City/Governorate Dropdown
                                _isLoadingCities
                                    ? const Center(key: ValueKey('city_loading'), child: CircularProgressIndicator())
                                    : DropdownButtonFormField<String>(
                                        key: const ValueKey('city_dropdown'),
                                        isExpanded: true,
                                        decoration: InputDecoration(
                                          labelText: 'اختر المحافظة',
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        ),
                                        items: _cities
                                            .map((city) => DropdownMenuItem(
                                                value: city.name,
                                                child: Text(city.name)))
                                            .toList(),
                                        onChanged: (v) =>
                                            setState(() => _selectedGovernorate = v),
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'الرجاء اختيار المحافظة';
                                          }
                                          return null;
                                        },
                                      ),
                                SizedBox(height: height * 0.02),
                                // Category/Specialty Dropdown
                                _isLoadingCategories
                                    ? const Center(key: ValueKey('cat_loading'), child: CircularProgressIndicator())
                                    : DropdownButtonFormField<String>(
                                        key: const ValueKey('cat_dropdown'),
                                        isExpanded: true,
                                        decoration: InputDecoration(
                                          labelText: 'اختر التخصص',
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        ),
                                        items: _categories
                                            .map((cat) => DropdownMenuItem(
                                                value: cat.name,
                                                child: Text(cat.name)))
                                            .toList(),
                                        onChanged: (v) =>
                                            setState(() => _selectedCategory = v),
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'الرجاء اختيار التخصص';
                                          }
                                          return null;
                                        },
                                      ),
                                SizedBox(height: height * 0.02),
                                // Password Field
                                TextFormField(
                                  controller: passwordController,
                                  obscureText: _obscurePassword,
                                  onChanged: (password) {
                                    setState(() {
                                      hasLowerCase = AppRegex.hasLowerCase(password);
                                      hasUpperCase = AppRegex.hasUpperCase(password);
                                      hasSpecialCharacters =
                                          AppRegex.hasSpecialCharacter(password);
                                      hasNumber = AppRegex.hasNumber(password);
                                      hasMinLength = AppRegex.hasMinLength(password);
                                    });
                                  },
                                  decoration: InputDecoration(
                                    labelText: 'كلمة المرور',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    prefixIcon: const Icon(Icons.lock_outline),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_off
                                            : Icons.visibility,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _obscurePassword = !_obscurePassword;
                                        });
                                      },
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'الرجاء إدخال كلمة المرور';
                                    }
                                    return null;
                                  },
                                ),
                                SizedBox(height: height * 0.02),
                                PasswordValidations(
                                  hasLowerCase: hasLowerCase,
                                  hasUpperCase: hasUpperCase,
                                  hasSpecialCharacters: hasSpecialCharacters,
                                  hasNumber: hasNumber,
                                  hasMinLength: hasMinLength,
                                ),
                                SizedBox(height: height * 0.03),
                                // Sign Up Button
                                BlocBuilder<SignUpCubit, SignUpState>(
                                  builder: (context, state) {
                                    return SizedBox(
                                      width: double.infinity,
                                      height: 52,
                                      child: state is SignUpLoading
                                          ? const Center(
                                              child: CircularProgressIndicator())
                                          : AppTextButton(
                                              buttonText: 'إنشاء حساب',
                                              textStyle: const TextStyle(
                                                fontSize: 16,
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontFamily: 'Cairo',
                                              ),
                                              onPressed: () {
                                                if (_formKey.currentState!.validate()) {
                                                  if (!hasLowerCase ||
                                                      !hasUpperCase ||
                                                      !hasSpecialCharacters ||
                                                      !hasNumber ||
                                                      !hasMinLength) {
                                                    ScaffoldMessenger.of(context)
                                                        .showSnackBar(
                                                      const SnackBar(
                                                        content: Text(
                                                            'يرجى التأكد من استكمال جميع شروط كلمة المرور'),
                                                        backgroundColor: Colors.red,
                                                      ),
                                                    );
                                                    return;
                                                  }

                                                  context.read<SignUpCubit>().signUp(
                                                        email: emailController.text
                                                            .trim(),
                                                        password:
                                                            passwordController.text,
                                                        firstName: firstNameController
                                                            .text
                                                            .trim(),
                                                        lastName: lastNameController
                                                            .text
                                                            .trim(),
                                                        phone: phoneController.text
                                                            .trim(),
                                                        college: _selectedCollege,
                                                        studyYear: _selectedStudyYear,
                                                        governorate:
                                                            _selectedGovernorate,
                                                        category: _selectedCategory,
                                                      );
                                                }
                                              },
                                            ),
                                    );
                                  },
                                ),
                                SizedBox(height: height * 0.02),
                                // Already have an account? Login
                                Wrap(
                                  alignment: WrapAlignment.center,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Text(
                                      'لديك حساب بالفعل؟',
                                      style: TextStyle(
                                        fontSize: baseFontSize * 0.8,
                                        color: ColorsManager.darkBlue,
                                        fontWeight: FontWeight.w500,
                                        fontFamily: 'Cairo',
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(context)
                                            .pushNamed(Routes.loginScreen);
                                      },
                                      child: Text(
                                        'تسجيل الدخول',
                                        style: TextStyle(
                                          fontSize: baseFontSize * 0.8,
                                          color: ColorsManager.mainBlue,
                                          fontWeight: FontWeight.bold,
                                          decoration: TextDecoration.underline,
                                          fontFamily: 'Cairo',
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
