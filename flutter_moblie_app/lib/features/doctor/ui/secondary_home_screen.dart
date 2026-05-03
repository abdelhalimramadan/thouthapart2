import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:geolocator/geolocator.dart';
import 'package:thoutha_mobile_app/core/networking/models/city_model.dart';
import 'package:thoutha_mobile_app/features/home_screen/ui/category_doctors_screen.dart';
import 'package:thoutha_mobile_app/features/home_screen/ui/drawer/drawer.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:thoutha_mobile_app/core/di/dependency_injection.dart';
import 'package:thoutha_mobile_app/features/doctor/logic/doctor_cubit.dart';
import 'package:thoutha_mobile_app/core/routing/routes.dart';
import 'package:thoutha_mobile_app/features/doctor/logic/doctor_state.dart';
import 'package:thoutha_mobile_app/core/helpers/constants.dart';
import 'package:thoutha_mobile_app/core/helpers/shared_pref_helper.dart';
import 'package:thoutha_mobile_app/features/login/ui/login_screen.dart';
import 'package:thoutha_mobile_app/features/doctor/drawer_doctor/doctor_drawer_screen.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;

class SecondaryHomeScreen extends StatefulWidget {
  SecondaryHomeScreen(
      {super.key,
      this.drawer,
      this.showAddCaseCategory = false});

  final Widget? drawer;
  final bool showAddCaseCategory;

  @override
  State<SecondaryHomeScreen> createState() => _SecondaryHomeScreenState();
}

class _SecondaryHomeScreenState extends State<SecondaryHomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  int? _selectedCityId;
  // All candidate strings returned by Nominatim (state, county, city, etc.)
  List<String> _gpsNameCandidates = [];
  bool _gpsFinished =
      false; // true once GPS attempt completes (success or fail)
  bool _autoSelectApplied = false;
  bool _isLoggedIn = false;
  bool _isDetecting = false;
  String? _gpsFailureMessage; // non-null → show failure banner
  List<CityModel> _loadedCities = [];

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final token =
        await SharedPrefHelper.getSecuredString(SharedPrefKeys.userToken);
    if (mounted) {
      setState(() {
        _isLoggedIn = token.isNotEmpty && token != 'null';
        if (_isLoggedIn) {
          _selectedCityId = null;
          _gpsNameCandidates = [];
          _gpsFinished = false;
          _autoSelectApplied = false;
          _isDetecting = false;
          _gpsFailureMessage = null;
        }
      });
      if (!_isLoggedIn) {
        _autoDetectCity();
      }
    }
  }

  // ── GPS helpers ──────────────────────────────────────────────────────────

  /// Strips common Arabic administrative prefixes Nominatim adds.
  String _stripPrefix(String s) => s
      .replaceAll(RegExp(r'^محافظة\s*'), '')
      .replaceAll(RegExp(r'^مديرية\s*'), '')
      .replaceAll(RegExp(r'^مدينة\s*'), '')
      .replaceAll(RegExp(r'^قسم\s*'), '')
      .replaceAll(RegExp(r'\s*محافظة$'), '')
      .trim();

  /// Returns true if [a] and [b] refer to the same governorate.
  /// Uses containment only (after stripping prefixes) to avoid false positives
  /// like 'doctor.cairo'.tr() matching 'doctor.qalyubia'.tr() via shared leading characters.
  bool _namesMatch(String a, String b) {
    final na = _stripPrefix(a.trim());
    final nb = _stripPrefix(b.trim());
    if (na.isEmpty || nb.isEmpty) return false; // Exact match after stripping
    if (na == nb) return true;
    // One fully contains the other (require ≥4 chars to avoid 'chat.the'.tr() false hits)
    if (na.length >= 4 && nb.contains(na)) return true;
    if (nb.length >= 4 && na.contains(nb)) return true;
    return false;
  }

  /// Tries to match any GPS candidate against the loaded cities list.
  /// Safe to call multiple times — stops after first successful match.
  void _tryAutoSelectCity() {
    if (_isLoggedIn) return;
    if (_autoSelectApplied || _selectedCityId != null) return;
    // Wait until BOTH GPS and cities are ready
    if (!_gpsFinished || _loadedCities.isEmpty) return;

    _autoSelectApplied = true;

    CityModel? match;
    outer:
    for (final raw in _gpsNameCandidates) {
      for (final c in _loadedCities) {
        if (_namesMatch(raw, c.name)) {
          match = c;
          break outer;
        }
      }
    }

    if (match != null) {
      setState(() {
        _selectedCityId = match!.id;
        _gpsFailureMessage = null;
      });
    } else {
      setState(() {
        _gpsFailureMessage =
            'doctor.the_application_was_unable'.tr();
      });
    }
  }

  /// Gets GPS coordinates → reverse-geocodes via Nominatim → populates candidates.
  Future<void> _autoDetectCity() async {
    if (_isLoggedIn) return;
    if (mounted) setState(() => _isDetecting = true);
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() {
            _gpsFinished = true;
            _gpsFailureMessage =
                'doctor.location_permission_has_been'.tr();
          });
        }
        return;
      }
      if (perm == LocationPermission.denied) {
        if (mounted) {
          setState(() {
            _gpsFinished = true;
            _gpsFailureMessage = 'doctor.the_location_cannot_be'.tr();
          });
        }
        return;
      }

      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          setState(() {
            _gpsFinished = true;
            _gpsFailureMessage =
                'doctor.the_location_service_is'.tr();
          });
        }
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      final dio = Dio();

      // Fetch Arabic response
      final resAr = await dio.get(
        'https://nominatim.openstreetmap.org/reverse',
        queryParameters: {
          'lat': pos.latitude,
          'lon': pos.longitude,
          'format': 'json',
          'accept-language': 'ar',
        },
        options: Options(
          headers: {'User-Agent': 'ThothaApp/1.0'},
          receiveTimeout: Duration(seconds: 10),
        ),
      );

      final candidates = <String>[];
      const addressKeys = [
        'state',
        'county',
        'city',
        'town',
        'village',
        'state_district',
        'region',
        'municipality',
      ];

      if (resAr.statusCode == 200 && resAr.data is Map) {
        final address = resAr.data['address'] as Map?;
        if (address != null) {
          for (final key in addressKeys) {
            final v = address[key];
            if (v is String && v.isNotEmpty) candidates.add(v);
          }
        }
      }

      if (mounted) {
        setState(() => _gpsNameCandidates = candidates);
      }
    } catch (_) {
      // Network or GPS failure — leave banner null, skip silently
    } finally {
      if (mounted) {
        setState(() {
          _gpsFinished = true;
          _isDetecting = false;
        });
        _tryAutoSelectCity();
      }
    }
  }

  // Asset mapping for categories
  // Asset mapping for categories using Arabic names as stable keys from API
  final Map<String, String> _categoryAssets = {
    'فحص شامل': 'assets/svg/فحص شامل.svg',
    'حشو اسنان': 'assets/svg/حشو اسنان.svg',
    'تجميلي': 'assets/svg/تجميلي.svg',
    'املغم': 'assets/svg/املغم.svg',
    'حشو عصب': 'assets/svg/حشو اسنان.svg',
    'زراعه اسنان': 'assets/svg/زراعه اسنان.svg',
    'زراعة الأسنان': 'assets/svg/زراعه اسنان.svg',
    'خلع اسنان': 'assets/svg/خلع اسنان.svg',
    'الجراحة وخلع': 'assets/svg/خلع اسنان.svg',
    'تبيض اسنان': 'assets/svg/تبيض اسنان.svg',
    'تنظيف وتبييض الأسنان': 'assets/svg/تبيض اسنان.svg',
    'تقويم اسنان': 'assets/svg/تقويم اسنان.svg',
    'تقويم الأسنان': 'assets/svg/تقويم اسنان.svg',
    'تيجان وجسور': 'assets/svg/ثوثه الدكتور 1.svg', // Fallback if image not found
    'تركيبات اسنان': 'assets/svg/تركيبات اسنان.svg',
    'تركيبات متحركة': 'assets/svg/تركيبات اسنان.svg',
    'اطفال2': 'assets/svg/اطفال2.svg',
    'طب أسنان الأطفال': 'assets/svg/اطفال2.svg',
  };

  // Translation mapping for categories
  final Map<String, String> _categoryTranslations = {
    'فحص شامل': 'chat.comprehensive_examination',
    'حشو اسنان': 'doctor.dental_filling',
    'تجميلي': 'chat.cosmetic_filler',
    'املغم': 'chat.amalgam_filling',
    'حشو عصب': 'chat.nerve_filling',
    'زراعه اسنان': 'chat.dental_implants',
    'زراعة الأسنان': 'chat.dental_implants',
    'خلع اسنان': 'chat.tooth_extraction',
    'الجراحة وخلع': 'chat.surgery_and_extraction',
    'تبيض اسنان': 'chat.teeth_whitening',
    'تنظيف وتبييض الأسنان': 'chat.teeth_cleaning_and_whitening',
    'تقويم اسنان': 'chat.orthodontics',
    'تقويم الأسنان': 'chat.orthodontics',
    'تيجان وجسور': 'chat.crowns_and_bridges',
    'تركيبات اسنان': 'chat.dental_prosthetics',
    'تركيبات متحركة': 'chat.moving_installations',
    'طب أسنان الأطفال': 'chat.pediatric_dentistry',
  };

  String _getAssetForCategory(String categoryName) {
    String name = categoryName.trim();
    if (_categoryAssets.containsKey(name)) {
      return _categoryAssets[name]!;
    }

    // Normalization to handle variations in Arabic characters
    String normalized = name
        .replaceAll('ة', 'ه')
        .replaceAll('أ', 'ا')
        .replaceAll('إ', 'ا')
        .replaceAll('آ', 'ا')
        .replaceAll('ى', 'ي');

    if (normalized.contains('فحص') || normalized.toLowerCase().contains('examination') || normalized.toLowerCase().contains('checkup')) return 'assets/svg/فحص شامل.svg';
    if (normalized.contains('املغم') || normalized.contains('املجم') || normalized.toLowerCase().contains('amalgam')) return 'assets/svg/املغم.svg';
    if (normalized.contains('عصب') || normalized.toLowerCase().contains('nerve') || normalized.toLowerCase().contains('root canal')) return 'assets/svg/حشو اسنان.svg';
    if (normalized.contains('تجميلي') || normalized.contains('تحميلي') || normalized.toLowerCase().contains('cosmetic') || normalized.toLowerCase().contains('composite')) return 'assets/svg/تجميلي.svg';
    if (normalized.contains('زراعه') || normalized.contains('زراعة') || normalized.toLowerCase().contains('implant')) return 'assets/svg/زراعه اسنان.svg';
    if (normalized.contains('خلع') || normalized.contains('جراحه') || normalized.contains('جراحة') || normalized.toLowerCase().contains('extraction') || normalized.toLowerCase().contains('surgery')) return 'assets/svg/خلع اسنان.svg';
    if (normalized.contains('تبيض') || normalized.contains('تنظيف') || normalized.toLowerCase().contains('whitening') || normalized.toLowerCase().contains('cleaning')) return 'assets/svg/تبيض اسنان.svg';
    if (normalized.contains('تقويم') || normalized.toLowerCase().contains('orthodontic') || normalized.toLowerCase().contains('brace')) return 'assets/svg/تقويم اسنان.svg';
    if (normalized.contains('تركيبات') || normalized.toLowerCase().contains('prosthetic') || normalized.toLowerCase().contains('installation')) return 'assets/svg/تركيبات اسنان.svg';
    if (normalized.contains('تيجان') || normalized.contains('جسور') || normalized.toLowerCase().contains('crown') || normalized.toLowerCase().contains('bridge')) return 'assets/images/تيجان وجسور.webp';
    if (normalized.contains('اطفال') || normalized.contains('أطفال') || normalized.toLowerCase().contains('pediatric') || normalized.toLowerCase().contains('child')) return 'assets/svg/اطفال2.svg';

    return 'assets/svg/فحص شامل.svg';
  }

  String _localizedCategoryName(String category) {
    final name = category.trim();
    if (_categoryTranslations.containsKey(name)) {
      return _categoryTranslations[name]!.tr();
    }
    
    // Check for variations if exact match fails
    String normalized = name
        .replaceAll('ة', 'ه')
        .replaceAll('أ', 'ا')
        .replaceAll('إ', 'ا')
        .replaceAll('آ', 'ا')
        .replaceAll('ى', 'ي');

    if (normalized.contains('فحص') || normalized.toLowerCase().contains('examination') || normalized.toLowerCase().contains('checkup')) return 'chat.comprehensive_examination'.tr();
    if (normalized.contains('املغم') || normalized.contains('املجم') || normalized.toLowerCase().contains('amalgam')) return 'chat.amalgam_filling'.tr();
    if (normalized.contains('عصب') || normalized.toLowerCase().contains('nerve') || normalized.toLowerCase().contains('root canal')) return 'chat.nerve_filling'.tr();
    if (normalized.contains('تجميلي') || normalized.contains('تحميلي') || normalized.toLowerCase().contains('cosmetic') || normalized.toLowerCase().contains('composite')) return 'chat.cosmetic_filler'.tr();
    if (normalized.contains('زراعه') || normalized.contains('زراعة') || normalized.toLowerCase().contains('implant')) return 'chat.dental_implants'.tr();
    if (normalized.contains('خلع') || normalized.contains('جراحه') || normalized.toLowerCase().contains('extraction') || normalized.toLowerCase().contains('surgery')) return 'chat.surgery_and_extraction'.tr();
    if (normalized.contains('تبيض') || normalized.contains('تنظيف') || normalized.toLowerCase().contains('whitening') || normalized.toLowerCase().contains('cleaning')) return 'chat.teeth_cleaning_and_whitening'.tr();
    if (normalized.contains('تقويم') || normalized.toLowerCase().contains('orthodontic') || normalized.toLowerCase().contains('brace')) return 'chat.orthodontics'.tr();
    if (normalized.contains('تيجان') || normalized.contains('جسور') || normalized.toLowerCase().contains('crown') || normalized.toLowerCase().contains('bridge')) return 'chat.crowns_and_bridges'.tr();
    if (normalized.contains('تركيبات') || normalized.toLowerCase().contains('prosthetic') || normalized.toLowerCase().contains('installation')) return 'chat.dental_prosthetics'.tr();
    if (normalized.contains('اطفال') || normalized.toLowerCase().contains('pediatric') || normalized.toLowerCase().contains('child')) return 'chat.pediatric_dentistry'.tr();

    return category;
  }

  Future<void> _handleCategoryTap({
    required String categoryName,
    required int? categoryId,
    required String? cityName,
  }) async {
    if (widget.showAddCaseCategory && _isAddCaseCategory(categoryName)) {
      final token =
          await SharedPrefHelper.getSecuredString(SharedPrefKeys.userToken);
      if (token.isEmpty) {
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LoginScreen(
              nextScreen: SecondaryHomeScreen(
                drawer: DoctorDrawer(),
                showAddCaseCategory: true,
              ),
              nextRouteSettings: RouteSettings(name: 'add-case'),
            ),
          ),
        );
        return;
      }
    }

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CategoryDoctorsScreen(
          categoryName: categoryName,
          categorySvg: _getAssetForCategory(categoryName),
          categoryId: categoryId,
          cityId: _selectedCityId,
          cityName: cityName,
          showAddCaseButton: true,
        ),
      ),
    );
  }

  Widget _buildSquareCategory(String assetPath, int index, String categoryName,
      double width, double height, double baseFontSize,
      {int? categoryId, String? cityName}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final svgFiles = [
      'املغم.svg',
      'حشو اسنان.svg',
      'تجميلي.svg',
      'زراعه اسنان.svg',
      'خلع اسنان.svg',
      'تبيض اسنان.svg',
      'تقويم اسنان.svg',
      'تركيبات اسنان.svg',
      'ثوثه الدكتور 1.svg',
      'اطفال2.svg',
    ];

    final categoryNames = [
      'doctor.amalgam_filling'.tr(),
      'chat.nerve_filling'.tr(),
      'chat.cosmetic_filler'.tr(),
      'chat.dental_implants'.tr(),
      'chat.surgery_and_extraction_1'.tr(),
      'chat.teeth_cleaning_and_whitening'.tr(),
      'chat.orthodontics'.tr(),
      'doctor.moving_installations'.tr(),
      'chat.crowns_and_bridges'.tr(),
      'chat.pediatric_dentistry'.tr(),
    ];

    final fileName =
        index < svgFiles.length ? svgFiles[index] : 'placeholder.svg';
    final resolvedAssetPath =
        assetPath.isNotEmpty ? assetPath : 'assets/svg/$fileName';
    final resolvedCategoryName = categoryName.isNotEmpty
        ? _localizedCategoryName(categoryName)
        : (index < categoryNames.length ? categoryNames[index] : '');

    return GestureDetector(
      onTap: () {
        _handleCategoryTap(
          categoryName: categoryName,
          categoryId: categoryId,
          cityName: cityName,
        );
      },
      child: Container(
        margin: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withOpacity(0.3)
                  : Colors.grey.withOpacity(0.1),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: 12),
            // Display image flexibly to avoid overflow and clipping.
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: resolvedAssetPath.endsWith('.svg')
                    ? SvgPicture.asset(
                        resolvedAssetPath,
                        fit: BoxFit.contain,
                        placeholderBuilder: (BuildContext context) => Container(
                          color: isDark ? Colors.grey[800] : Colors.grey[200],
                          child: Icon(Icons.image, size: 32, color: Colors.grey),
                        ),
                      )
                    : Image.asset(
                        resolvedAssetPath,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: isDark ? Colors.grey[800] : Colors.grey[200],
                          child: Icon(Icons.image, size: 32, color: Colors.grey),
                        ),
                      ),
              ),
            ),
            SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                resolvedCategoryName,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.w600,
                      fontSize: width > 600 ? 15.0 : (baseFontSize * 0.875).clamp(12.0, 15.0),
                      height: 1.2,
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  bool _isAddCaseCategory(String name) {
    final compact = name.replaceAll(' ', '');
    return name.contains('doctor.post_a_new_status'.tr()) ||
        name.contains('doctor.add_a_new_case'.tr()) ||
        compact.contains('doctor.str_267'.tr()) ||
        compact.contains('doctor.add_a_new_case_1'.tr());
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;
    final baseFontSize = width * 0.04;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocProvider(
      create: (context) => getIt<DoctorCubit>()..loadInitialData(),
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) async {
          if (didPop) return;

          if (widget.drawer is DoctorDrawer || widget.showAddCaseCategory) {
            Navigator.of(context).pushReplacementNamed(Routes.doctorHomeScreen);
          } else {
            Navigator.of(context).pushReplacementNamed(Routes.categoriesScreen);
          }
        },
        child: Scaffold(
          key: _scaffoldKey,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            automaticallyImplyLeading: false,
            backgroundColor: Theme.of(context).colorScheme.surface,
            elevation: 0,
            leading: IconButton(
              icon: Icon(
                Icons.menu,
                size: 24,
                color: Theme.of(context).iconTheme.color,
              ),
              onPressed: () {
                _scaffoldKey.currentState?.openDrawer();
              },
            ),
            title: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'doctor.post_a_new_status'.tr(),
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.bold,
                    fontSize: (baseFontSize * 1.1).clamp(18.0, 24.0),
                  ),
                ),
                SizedBox(width: 8),
                Image.asset(
                  'assets/images/splash-logo.png',
                  width: 36,
                  height: 36,
                  fit: BoxFit.contain,
                ),
              ],
            ),
            centerTitle: true,
          ),
        drawer: widget.drawer ?? const HomeDrawer(),
        body: SafeArea(
          child: BlocConsumer<DoctorCubit, DoctorState>(
            listener: (context, state) {
              if (!_isLoggedIn &&
                  state is DoctorSuccess &&
                  state.cities.isNotEmpty) {
                _loadedCities = state.cities;
                _tryAutoSelectCity();
              }
            },
            builder: (context, state) {
              if (state is DoctorLoading) {
                return Center(child: CircularProgressIndicator());
              } else if (state is DoctorError) {
                return Center(
                    child: Text(state.error,
                        style: TextStyle(fontFamily: 'Cairo')));
              } else if (state is DoctorSuccess) {
                final categories = state.categories;
                final cities = state.cities;

                final visibleCategories = categories;

                return SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.zero,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [


                        // City Dropdown — only visible when NOT logged in
                        if (!_isLoggedIn) ...[
                          Container(
                            width: double.infinity,
                            margin: EdgeInsets.symmetric(
                                horizontal: width * 0.06, vertical: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(
                                      left: 4, right: 4, bottom: 8),
                                  child: Text(
                                    'doctor.select_the_governorate'.tr(),
                                    style: TextStyle(
                                      fontFamily: 'Cairo',
                                      fontSize: baseFontSize * 0.9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Container(
                                  height: 52,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12),
                                  decoration: BoxDecoration(
                                    color:
                                        Theme.of(context).colorScheme.surface,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isDark
                                          ? Colors.grey[700]!
                                          : Color(0xFFD1D5DC),
                                      width: 1.1,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary
                                            .withAlpha(77),
                                        blurRadius: 4,
                                        offset: Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<int>(
                                      value: _selectedCityId,
                                      hint: Row(
                                        children: [
                                          Icon(
                                            _isDetecting
                                                ? Icons.location_searching
                                                : Icons.my_location,
                                            size: 16,
                                            color: _isDetecting
                                                ? Theme.of(context)
                                                    .colorScheme
                                                    .primary
                                                : (isDark ? Colors.white70 : Colors.grey[500]),
                                          ),
                                          SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              _isDetecting
                                                  ? 'doctor.locating_your_location'.tr()
                                                  : 'doctor.select_city'.tr(),
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleMedium
                                                  ?.copyWith(
                                                    fontFamily: 'Cairo',
                                                    fontSize:
                                                        baseFontSize * 0.875,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                      isExpanded: true,
                                      icon: _isDetecting
                                          ? SizedBox(
                                              width: 18,
                                              height: 18,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .primary,
                                              ),
                                            )
                                          : Icon(Icons.arrow_drop_down,
                                              color: Theme.of(context)
                                                  .iconTheme
                                                  .color),
                                      items: cities.map((city) {
                                        return DropdownMenuItem<int>(
                                          value: city.id,
                                          child: Text(
                                            city.name,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium
                                                ?.copyWith(
                                                  fontFamily: 'Cairo',
                                                  fontSize:
                                                      baseFontSize * 0.875,
                                                ),
                                            textAlign: TextAlign.right,
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: (val) {
                                        setState(() {
                                          _selectedCityId = val;
                                          _gpsFailureMessage = null;
                                        });
                                        if (val != null) {
                                          context
                                              .read<DoctorCubit>()
                                              .filterByCity(val);
                                        }
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // GPS failure banner
                          if (_gpsFailureMessage != null)
                            Container(
                              margin: EdgeInsets.symmetric(
                                  horizontal: width * 0.06),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.orange.withAlpha(30),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: Colors.orange.shade300, width: 1),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.location_off,
                                      color: Colors.orange, size: 18),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _gpsFailureMessage!,
                                      style: TextStyle(
                                        fontFamily: 'Cairo',
                                        fontSize: baseFontSize * 0.8,
                                        color: isDark ? Colors.white.withOpacity(0.9) : Colors.orange.shade800,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],

                        // Services Header
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          child: Text(
                            'doctor.choose_the_specialty_to'.tr(),
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontFamily: 'Cairo',
                                  fontWeight: FontWeight.bold,
                                  fontSize: (baseFontSize * 1.06).clamp(16.0, 22.0),
                                  height: 1.2,
                                ),
                            textAlign: TextAlign.center,
                          ),
                        ),

                        // Categories Grid
                        if (visibleCategories.isNotEmpty)
                          Padding(
                            padding:
                                EdgeInsets.symmetric(horizontal: width * 0.05),
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final crossAxisCount = width > 600 ? 4 : 2;
                                return GridView.builder(
                                  shrinkWrap: true,
                                  physics: NeverScrollableScrollPhysics(),
                                  gridDelegate:
                                      SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: crossAxisCount,
                                    mainAxisSpacing: 12,
                                    crossAxisSpacing: 12,
                                    childAspectRatio: 1.0,
                                  ),
                                  itemCount: visibleCategories.length,
                                  itemBuilder: (context, index) {
                                    final category = visibleCategories[index];
                                    final asset =
                                        _getAssetForCategory(category.name);

                                    String? selectedCityName;
                                    if (_selectedCityId != null) {
                                      try {
                                        selectedCityName = cities
                                            .firstWhere(
                                                (c) => c.id == _selectedCityId)
                                            .name;
                                      } catch (_) {}
                                    }

                                    return _buildSquareCategory(
                                        asset,
                                        index,
                                        category.name,
                                        width,
                                        height,
                                        baseFontSize,
                                        categoryId: category.id,
                                        cityName: selectedCityName);
                                  },
                                );
                              },
                            ),
                          ),

                        SizedBox(height: 100), // Reserve space at bottom
                      ],
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    ),
  );
}}
