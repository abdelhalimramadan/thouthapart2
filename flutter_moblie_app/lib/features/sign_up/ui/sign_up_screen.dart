import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:thoutha_mobile_app/core/helpers/app_regex.dart';
import 'package:thoutha_mobile_app/core/networking/api_service.dart';
import 'package:thoutha_mobile_app/core/networking/models/category_model.dart';
import 'package:thoutha_mobile_app/core/networking/models/city_model.dart';
import 'package:thoutha_mobile_app/core/networking/models/university_model.dart';
import 'package:thoutha_mobile_app/core/routing/routes.dart';
import 'package:thoutha_mobile_app/core/theming/colors.dart';
import 'package:thoutha_mobile_app/core/widgets/app_text_button.dart';
import 'package:thoutha_mobile_app/features/booking/ui/otp_verification_dialog.dart';
import 'package:thoutha_mobile_app/features/login/ui/widgets/password_validations.dart';
import 'package:thoutha_mobile_app/features/sign_up/logic/sign_up_cubit.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
//import 'package:showcaseview/showcaseview.dart';
//import 'package:thoutha_mobile_app/tour/tour_config.dart';
//import 'package:thoutha_mobile_app/tour/tour_service.dart';

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
  final TextEditingController confirmPasswordController =
      TextEditingController();

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
  bool _obscureConfirmPassword = true;

  final ApiService _apiService = ApiService();
  List<CityModel> _cities = [];
  List<UniversityModel> _universities = [];
  List<CategoryModel> _categories = [];

  bool _isLoadingCities = false;
  bool _isLoadingUniversities = false;
  bool _isLoadingCategories = false;

  final List<String> _studyYears = [
    'sign_up.fourth_band'.tr(),
    'sign_up.fifth_division'.tr(),
    'profile.privilege'.tr(),
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
    confirmPasswordController.dispose();
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
            Future.delayed(Duration(seconds: 3), () {
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
                    SnackBar(
                      content: Text('sign_up.phone_number_verified_successfully'.tr()),
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
                        center: Alignment(-0.8, -0.5),
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
                        center: Alignment(0.8, 0.5),
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
                                horizontal: 24,
                                vertical: 24,
                              ),
                              child: Center(
                                child: Container(
                                  width: double.infinity,
                                  constraints: BoxConstraints(
                                    maxWidth: MediaQuery.of(context).size.width >= 600 ? 500 : double.infinity,
                                  ),
                                  padding: EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).cardTheme.color,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: isDarkMode
                                            ? Colors.black.withAlpha(102)
                                            : Colors.black.withAlpha(25),
                                        blurRadius: 10,
                                        offset: Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Directionality(
                                    textDirection: TextDirection.rtl,
                                    child: Form(
                                      key: _formKey,
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          SizedBox(height: 16),
                                          Image.asset(
                                            'assets/images/splash-logo.png',
                                            width: 80,
                                            height: 80,
                                            fit: BoxFit.contain,
                                          ),
                                          Text(
                                            'login.create_an_account_1'.tr(),
                                            style: TextStyle(
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
                                              color: isDarkMode
                                                  ? Colors.white
                                                  : ColorsManager.mainBlue,
                                              fontFamily: 'Cairo',
                                            ),
                                          ),
                                          Text(
                                            'sign_up.create_your_account_to'.tr(),
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: isDarkMode
                                                  ? Colors.white70
                                                  : Colors.grey,
                                              fontFamily: 'Cairo',
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                          SizedBox(height: 16),
                                          // First Name Field
                                          TextFormField(
                                            controller: firstNameController,
                                            textInputAction: TextInputAction.next,
                                            inputFormatters: [
                                              FilteringTextInputFormatter.allow(
                                                RegExp(r'[\u0621-\u064A\s]'),
                                              ),
                                            ],
                                            decoration: InputDecoration(
                                              labelText: 'booking.first_name'.tr(),
                                              helperText: 'sign_up.enter_the_name_in'.tr(),
                                              prefixIcon:
                                                  Icon(Icons.person_outline),
                                            ),
                                            validator: (value) {
                                              if (value == null || value.trim().isEmpty) {
                                                return 'booking.please_enter_first_name'.tr();
                                              }
                                              if (!AppRegex.isArabicName(value.trim())) {
                                                return 'sign_up.the_first_name_must'.tr();
                                              }
                                              return null;
                                            },
                                          ),
                                          SizedBox(height: 16),
                                          // Last Name Field
                                          TextFormField(
                                            controller: lastNameController,
                                            textInputAction: TextInputAction.next,
                                            inputFormatters: [
                                              FilteringTextInputFormatter.allow(
                                                RegExp(r'[\u0621-\u064A\s]'),
                                              ),
                                            ],
                                            decoration: InputDecoration(
                                              labelText: 'sign_up.last_name'.tr(),
                                              helperText: 'sign_up.enter_the_name_in'.tr(),
                                              prefixIcon:
                                                  Icon(Icons.person_outline),
                                            ),
                                            validator: (value) {
                                              if (value == null || value.trim().isEmpty) {
                                                return 'sign_up.please_enter_last_name'.tr();
                                              }
                                              if (!AppRegex.isArabicName(value.trim())) {
                                                return 'sign_up.the_last_name_must'.tr();
                                              }
                                              return null;
                                            },
                                          ),
                                          SizedBox(height: 16),
                                          // Email Field
                                          TextFormField(
                                            controller: emailController,
                                            keyboardType:
                                                TextInputType.emailAddress,
                                            decoration: InputDecoration(
                                              labelText: 'doctor.email'.tr(),
                                              prefixIcon:
                                                  Icon(Icons.email_outlined),
                                              helperText: 'sign_up.must_end_with_universityedueg'.tr(),
                                            ),
                                            validator: (value) {
                                              if (value == null ||
                                                  value.isEmpty ||
                                                  !AppRegex.isEmailValid(value)) {
                                                return 'login.please_enter_a_valid'.tr();
                                              }
                                              if (!value.endsWith('.edu.eg')) {
                                                return 'sign_up.email_must_end_with'.tr();
                                              }
                                              return null;
                                            },
                                          ),
                                          SizedBox(height: 16),
                                          // Phone Number Field
                                          TextFormField(
                                            controller: phoneController,
                                            keyboardType: TextInputType.phone,
                                            decoration: InputDecoration(
                                              labelText: 'doctor.phone_number'.tr(),
                                              prefixIcon:
                                                  Icon(Icons.phone_outlined),
                                            ),
                                            validator: (value) {
                                              if (value == null ||
                                                  value.isEmpty ||
                                                  !AppRegex.isPhoneNumberValid(
                                                      value)) {
                                                return 'sign_up.please_enter_a_valid'.tr();
                                              }
                                              return null;
                                            },
                                          ),
                                          SizedBox(height: 16),
                                          // University/College Dropdown
                                          _isLoadingUniversities
                                              ? Center(
                                                  key: ValueKey('uni_loading'),
                                                  child:
                                                      CircularProgressIndicator())
                                              : DropdownButtonFormField<String>(
                                                  key: ValueKey(
                                                      'uni_dropdown'),
                                                  isExpanded: true,
                                                  decoration: InputDecoration(
                                                    labelText: 'sign_up.choose_college'.tr(),
                                                  ),
                                                  items: _universities
                                                      .map((u) {
                                                        final name = u.name;
                                                        if (name.trim().isEmpty) {
                                                          return null;
                                                        }
                                                        return DropdownMenuItem<String>(
                                                          value: name,
                                                          child: Text(name),
                                                        );
                                                      })
                                                      .whereType<DropdownMenuItem<String>>()
                                                      .toList(),
                                                  onChanged: (v) => setState(
                                                      () => _selectedCollege = v),
                                                  validator: (value) {
                                                    if (value == null ||
                                                        value.isEmpty) {
                                                      return 'sign_up.please_select_a_college'.tr();
                                                    }
                                                    return null;
                                                  },
                                                ),
                                          SizedBox(height: 16),
                                          // Study Year Dropdown
                                          DropdownButtonFormField<String>(
                                            isExpanded: true,
                                            decoration: InputDecoration(
                                              labelText: 'profile.academic_year'.tr(),
                                            ),
                                            items: _studyYears
                                                .map((y) => DropdownMenuItem(
                                                    value: y, child: Text(y)))
                                                .toList(),
                                            onChanged: (v) => setState(
                                                () => _selectedStudyYear = v),
                                            validator: (value) {
                                              if (value == null || value.isEmpty) {
                                                return 'sign_up.please_select_the_academic'.tr();
                                              }
                                              return null;
                                            },
                                          ),
                                          SizedBox(height: 16),
                                          // City/Governorate Dropdown
                                          _isLoadingCities
                                              ? Center(
                                                  key: ValueKey('city_loading'),
                                                  child:
                                                      CircularProgressIndicator())
                                              : DropdownButtonFormField<String>(
                                                  key: ValueKey(
                                                      'city_dropdown'),
                                                  isExpanded: true,
                                                  decoration: InputDecoration(
                                                    labelText: 'doctor.select_the_governorate'.tr(),
                                                    helperText: 'sign_up.select_the_governorate_to'.tr(),
                                                  ),
                                                  items: _cities
                                                      .map((city) {
                                                        final name = city.name;
                                                        if (name.trim().isEmpty) {
                                                          return null;
                                                        }
                                                        return DropdownMenuItem<String>(
                                                          value: name,
                                                          child: Text(name),
                                                        );
                                                      })
                                                      .whereType<DropdownMenuItem<String>>()
                                                      .toList(),
                                                  onChanged: (v) => setState(() =>
                                                      _selectedGovernorate = v),
                                                  validator: (value) {
                                                    if (value == null ||
                                                        value.isEmpty) {
                                                      return 'sign_up.please_select_a_governorate'.tr();
                                                    }
                                                    return null;
                                                  },
                                                ),
                                          SizedBox(height: 16),
                                          // Category/Specialty Dropdown
                                          _isLoadingCategories
                                              ? Center(
                                                  key: ValueKey('cat_loading'),
                                                  child:
                                                      CircularProgressIndicator())
                                              : DropdownButtonFormField<String>(
                                                  key: ValueKey(
                                                      'cat_dropdown'),
                                                  isExpanded: true,
                                                  decoration: InputDecoration(
                                                    labelText: 'profile.choose_your_specialty'.tr(),
                                                  ),
                                                  items: _categories
                                                      .map((cat) {
                                                        final name = cat.name;
                                                        if (name.trim().isEmpty) {
                                                          return null;
                                                        }
                                                        return DropdownMenuItem<String>(
                                                          value: name,
                                                          child: Text(name),
                                                        );
                                                      })
                                                      .whereType<DropdownMenuItem<String>>()
                                                      .toList(),
                                                  onChanged: (v) => setState(
                                                      () => _selectedCategory = v),
                                                  validator: (value) {
                                                    if (value == null ||
                                                        value.isEmpty) {
                                                      return 'sign_up.please_choose_a_specialty'.tr();
                                                    }
                                                    return null;
                                                  },
                                                ),
                                          SizedBox(height: 16),
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
                                                hasNumber =
                                                    AppRegex.hasNumber(password);
                                                hasMinLength =
                                                    AppRegex.hasMinLength(password);
                                              });
                                            },
                                            decoration: InputDecoration(
                                              labelText: 'login.password'.tr(),
                                              prefixIcon:
                                                  Icon(Icons.lock_outline),
                                              suffixIcon: IconButton(
                                                icon: Icon(
                                                  _obscurePassword
                                                      ? Icons.visibility_off
                                                      : Icons.visibility,
                                                ),
                                                onPressed: () {
                                                  setState(() {
                                                    _obscurePassword =
                                                        !_obscurePassword;
                                                  });
                                                },
                                              ),
                                            ),
                                            validator: (value) {
                                              if (value == null || value.isEmpty) {
                                                return 'login.please_enter_your_password'.tr();
                                              }
                                              return null;
                                            },
                                          ),
                                          SizedBox(height: 16),
                                          // Confirm Password Field
                                          TextFormField(
                                            controller: confirmPasswordController,
                                            obscureText: _obscureConfirmPassword,
                                            decoration: InputDecoration(
                                              labelText: 'reset_password.confirm_password'.tr(),
                                              prefixIcon:
                                                  Icon(Icons.lock_outline),
                                              suffixIcon: IconButton(
                                                icon: Icon(
                                                  _obscureConfirmPassword
                                                      ? Icons.visibility_off
                                                      : Icons.visibility,
                                                ),
                                                onPressed: () {
                                                  setState(() {
                                                    _obscureConfirmPassword =
                                                        !_obscureConfirmPassword;
                                                  });
                                                },
                                              ),
                                            ),
                                            validator: (value) {
                                              if (value == null || value.isEmpty) {
                                                return 'reset_password.please_confirm_your_password'.tr();
                                              }
                                              if (value !=
                                                  passwordController.text) {
                                                return 'sign_up.passwords_do_not_match'.tr();
                                              }
                                              return null;
                                            },
                                          ),

                                          SizedBox(height: 16),
                                          PasswordValidations(
                                            hasLowerCase: hasLowerCase,
                                            hasUpperCase: hasUpperCase,
                                            hasSpecialCharacters:
                                                hasSpecialCharacters,
                                            hasNumber: hasNumber,
                                            hasMinLength: hasMinLength,
                                          ),
                                          SizedBox(height: 24),
                                          // Sign Up Button
                                          BlocBuilder<SignUpCubit, SignUpState>(
                                            builder: (context, state) {
                                              return SizedBox(
                                                width: double.infinity,
                                                height: 52,
                                                child: state is SignUpLoading
                                                    ? Center(
                                                        child:
                                                            CircularProgressIndicator())
                                                    : AppTextButton(
                                                        buttonText: 'login.create_an_account'.tr(),
                                                        textStyle: TextStyle(
                                                          fontSize: 16,
                                                          color: Colors.white,
                                                          fontWeight:
                                                              FontWeight.bold,
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
                                                                SnackBar(
                                                                  content: Text(
                                                                      'sign_up.please_ensure_you_complete'.tr()),
                                                                  backgroundColor:
                                                                      Colors.red,
                                                                ),
                                                              );
                                                              return;
                                                            }

                                                            context
                                                                .read<SignUpCubit>()
                                                                .signUp(
                                                                  email:
                                                                      emailController
                                                                          .text
                                                                          .trim(),
                                                                  password:
                                                                      passwordController
                                                                          .text,
                                                                  confirmPassword:
                                                                      confirmPasswordController
                                                                          .text,
                                                                  firstName:
                                                                      firstNameController
                                                                          .text
                                                                          .trim(),
                                                                  lastName:
                                                                      lastNameController
                                                                          .text
                                                                          .trim(),
                                                                  phone:
                                                                      phoneController
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
                                          SizedBox(height: 16),
                                          Wrap(
                                            alignment: WrapAlignment.center,
                                            crossAxisAlignment:
                                                WrapCrossAlignment.center,
                                            children: [
                                              Text(
                                                'sign_up.already_have_an_account'.tr(),
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: isDarkMode
                                                      ? Colors.white
                                                      : ColorsManager.darkBlue,
                                                  fontWeight: FontWeight.w500,
                                                  fontFamily: 'Cairo',
                                                ),
                                              ),
                                              TextButton(
                                                onPressed: () {
                                                  Navigator.of(context).pushNamed(
                                                      Routes.loginScreen);
                                                },
                                                child: Text(
                                                  'home_screen.login'.tr(),
                                                  style: TextStyle(
                                                    fontSize: 13,
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
