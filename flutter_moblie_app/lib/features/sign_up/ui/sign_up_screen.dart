import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/routing/routes.dart';
import '../../../../core/theming/colors.dart';
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

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
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          resizeToAvoidBottomInset: true,
          body: Stack(
            children: [
              // Full screen gradient overlay
              Container(
                width: double.infinity,
                height: double.infinity,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(-0.8, -0.5),
                    radius: 1.2,
                    colors: [
                      isDarkMode
                          ? ColorsManager.layerBlur1.withAlpha(50)
                          : ColorsManager.layerBlur1.withAlpha(102),
                      isDarkMode
                          ? ColorsManager.layerBlur1.withAlpha(20)
                          : ColorsManager.layerBlur1.withAlpha(25),
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
                    center: const Alignment(0.8, 0.5),
                    radius: 1.2,
                    colors: [
                      isDarkMode
                          ? ColorsManager.layerBlur2.withAlpha(50)
                          : ColorsManager.layerBlur2.withAlpha(102),
                      isDarkMode
                          ? ColorsManager.layerBlur2.withAlpha(20)
                          : ColorsManager.layerBlur2.withAlpha(25),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.3, 0.8],
                  ),
                ),
              ),
              SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 24.w,
                            vertical: 24.h,
                          ),
                          child: Center(
                            child: Container(
                              width: double.infinity,
                              constraints: BoxConstraints(
                                maxWidth: 1.sw >= 600 ? 500.w : double.infinity,
                              ),
                              padding: EdgeInsets.all(24.r),
                              decoration: BoxDecoration(
                                color: Theme.of(context).cardTheme.color,
                                borderRadius: BorderRadius.circular(16.r),
                                boxShadow: [
                                  BoxShadow(
                                    color: isDarkMode
                                        ? Colors.black.withAlpha(102)
                                        : Colors.black.withAlpha(25),
                                    blurRadius: 10.r,
                                    offset: Offset(0, 4.h),
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
                                      SizedBox(height: 16.h),
                                      Image.asset(
                                        'assets/images/splash-logo.png',
                                        width: 80.w,
                                        height: 80.h,
                                        fit: BoxFit.contain,
                                      ),
                                      Text(
                                        ' إنشاء حساب',
                                        style: TextStyle(
                                          fontSize: 24.sp,
                                          fontWeight: FontWeight.bold,
                                          color: isDarkMode
                                              ? Colors.white
                                              : ColorsManager.mainBlue,
                                          fontFamily: 'Cairo',
                                        ),
                                      ),
                                      Text(
                                        'أنشئ حسابك للبدء في استخدام التطبيق.',
                                        style: TextStyle(
                                          fontSize: 14.sp,
                                          color: isDarkMode
                                              ? Colors.white70
                                              : Colors.grey,
                                          fontFamily: 'Cairo',
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      SizedBox(height: 16.h),
                                      // First Name Field
                                      TextFormField(
                                        controller: firstNameController,
                                        textInputAction: TextInputAction.next,
                                        decoration: const InputDecoration(
                                          labelText: 'الاسم الأول',
                                          prefixIcon: Icon(Icons.person_outline),
                                        ),
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'الرجاء إدخال الاسم الأول';
                                          }
                                          return null;
                                        },
                                      ),
                                      SizedBox(height: 16.h),
                                      // Last Name Field
                                      TextFormField(
                                        controller: lastNameController,
                                        textInputAction: TextInputAction.next,
                                        decoration: const InputDecoration(
                                          labelText: 'الاسم الأخير',
                                          prefixIcon: Icon(Icons.person_outline),
                                        ),
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'الرجاء إدخال الاسم الأخير';
                                          }
                                          return null;
                                        },
                                      ),
                                      SizedBox(height: 16.h),
                                      // Email Field
                                      TextFormField(
                                        controller: emailController,
                                        keyboardType: TextInputType.emailAddress,
                                        decoration: const InputDecoration(
                                          labelText: 'البريد الإلكتروني',
                                          prefixIcon: Icon(Icons.email_outlined),
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
                                      SizedBox(height: 16.h),
                                      // Phone Number Field
                                      TextFormField(
                                        controller: phoneController,
                                        keyboardType: TextInputType.phone,
                                        decoration: const InputDecoration(
                                          labelText: 'رقم الهاتف',
                                          prefixIcon: Icon(Icons.phone_outlined),
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
                                      SizedBox(height: 16.h),
                                      // University/College Dropdown
                                      _isLoadingUniversities
                                          ? const Center(
                                              key: ValueKey('uni_loading'),
                                              child: CircularProgressIndicator())
                                          : DropdownButtonFormField<String>(
                                              key: const ValueKey('uni_dropdown'),
                                              isExpanded: true,
                                              decoration: const InputDecoration(
                                                labelText: 'اختر الكلية',
                                              ),
                                              items: _universities
                                                  .map((u) => DropdownMenuItem(
                                                      value: u.name,
                                                      child: Text(u.name)))
                                                  .toList(),
                                              onChanged: (v) => setState(
                                                  () => _selectedCollege = v),
                                              validator: (value) {
                                                if (value == null || value.isEmpty) {
                                                  return 'الرجاء اختيار الكلية';
                                                }
                                                return null;
                                              },
                                            ),
                                      SizedBox(height: 16.h),
                                      // Study Year Dropdown
                                      DropdownButtonFormField<String>(
                                        isExpanded: true,
                                        decoration: const InputDecoration(
                                          labelText: 'السنة الدراسية',
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
                                      SizedBox(height: 16.h),
                                      // City/Governorate Dropdown
                                      _isLoadingCities
                                          ? const Center(
                                              key: ValueKey('city_loading'),
                                              child: CircularProgressIndicator())
                                          : DropdownButtonFormField<String>(
                                              key: const ValueKey('city_dropdown'),
                                              isExpanded: true,
                                              decoration: const InputDecoration(
                                                labelText: 'اختر المحافظة',
                                              ),
                                              items: _cities
                                                  .map((city) => DropdownMenuItem(
                                                      value: city.name,
                                                      child: Text(city.name)))
                                                  .toList(),
                                              onChanged: (v) => setState(
                                                  () => _selectedGovernorate = v),
                                              validator: (value) {
                                                if (value == null || value.isEmpty) {
                                                  return 'الرجاء اختيار المحافظة';
                                                }
                                                return null;
                                              },
                                            ),
                                      SizedBox(height: 16.h),
                                      // Category/Specialty Dropdown
                                      _isLoadingCategories
                                          ? const Center(
                                              key: ValueKey('cat_loading'),
                                              child: CircularProgressIndicator())
                                          : DropdownButtonFormField<String>(
                                              key: const ValueKey('cat_dropdown'),
                                              isExpanded: true,
                                              decoration: const InputDecoration(
                                                labelText: 'اختر التخصص',
                                              ),
                                              items: _categories
                                                  .map((cat) => DropdownMenuItem(
                                                      value: cat.name,
                                                      child: Text(cat.name)))
                                                  .toList(),
                                              onChanged: (v) => setState(
                                                  () => _selectedCategory = v),
                                              validator: (value) {
                                                if (value == null || value.isEmpty) {
                                                  return 'الرجاء اختيار التخصص';
                                                }
                                                return null;
                                              },
                                            ),
                                      SizedBox(height: 16.h),
                                      // Password Field
                                      TextFormField(
                                        controller: passwordController,
                                        obscureText: _obscurePassword,
                                        onChanged: (password) {
                                          setState(() {
                                            hasLowerCase =
                                                AppRegex.hasLowerCase(password);
                                            hasUpperCase =
                                                AppRegex.hasUpperCase(password);
                                            hasSpecialCharacters =
                                                AppRegex.hasSpecialCharacter(
                                                    password);
                                            hasNumber = AppRegex.hasNumber(password);
                                            hasMinLength =
                                                AppRegex.hasMinLength(password);
                                          });
                                        },
                                        decoration: InputDecoration(
                                          labelText: 'كلمة المرور',
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
                                      SizedBox(height: 16.h),
                                      PasswordValidations(
                                        hasLowerCase: hasLowerCase,
                                        hasUpperCase: hasUpperCase,
                                        hasSpecialCharacters: hasSpecialCharacters,
                                        hasNumber: hasNumber,
                                        hasMinLength: hasMinLength,
                                      ),
                                      SizedBox(height: 24.h),
                                      // Sign Up Button
                                      BlocBuilder<SignUpCubit, SignUpState>(
                                        builder: (context, state) {
                                          return SizedBox(
                                            width: double.infinity,
                                            height: 52.h,
                                            child: state is SignUpLoading
                                                ? const Center(
                                                    child:
                                                        CircularProgressIndicator())
                                                : AppTextButton(
                                                    buttonText: 'إنشاء حساب',
                                                    textStyle: TextStyle(
                                                      fontSize: 16.sp,
                                                      color: Colors.white,
                                                      fontWeight: FontWeight.bold,
                                                      fontFamily: 'Cairo',
                                                    ),
                                                    onPressed: () {
                                                      if (_formKey.currentState!
                                                          .validate()) {
                                                        if (!hasLowerCase ||
                                                            !hasUpperCase ||
                                                            !hasSpecialCharacters ||
                                                            !hasNumber ||
                                                            !hasMinLength) {
                                                          ScaffoldMessenger.of(
                                                                  context)
                                                              .showSnackBar(
                                                            const SnackBar(
                                                              content: Text(
                                                                  'يرجى التأكد من استكمال جميع شروط كلمة المرور'),
                                                              backgroundColor:
                                                                  Colors.red,
                                                            ),
                                                          );
                                                          return;
                                                        }

                                                        context
                                                            .read<SignUpCubit>()
                                                            .signUp(
                                                               email: emailController
                                                                  .text
                                                                  .trim(),
                                                               password:
                                                                   passwordController
                                                                       .text,
                                                               firstName:
                                                                   firstNameController
                                                                       .text
                                                                       .trim(),
                                                               lastName:
                                                                   lastNameController
                                                                       .text
                                                                       .trim(),
                                                               phone: phoneController
                                                                   .text
                                                                   .trim(),
                                                               college:
                                                                   _selectedCollege,
                                                               studyYear:
                                                                   _selectedStudyYear,
                                                               governorate:
                                                                   _selectedGovernorate,
                                                               category:
                                                                   _selectedCategory,
                                                             );
                                                      }
                                                    },
                                                  ),
                                          );
                                        },
                                      ),
                                      SizedBox(height: 16.h),
                                      Wrap(
                                        alignment: WrapAlignment.center,
                                        crossAxisAlignment:
                                            WrapCrossAlignment.center,
                                        children: [
                                          Text(
                                            'لديك حساب بالفعل؟',
                                            style: TextStyle(
                                              fontSize: 13.sp,
                                              color: isDarkMode
                                                  ? Colors.white
                                                  : ColorsManager.darkBlue,
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
                                                fontSize: 13.sp,
                                                color: ColorsManager.mainBlue,
                                                fontWeight: FontWeight.bold,
                                                decoration:
                                                    TextDecoration.underline,
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
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
