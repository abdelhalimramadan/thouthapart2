import 'dart:ui';
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

class SecondaryHomeScreen extends StatefulWidget {
  const SecondaryHomeScreen(
      {super.key,
      this.drawer = const HomeDrawer(),
      this.showAddCaseCategory = false});

  final Widget drawer;
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
  /// like "القاهرة" matching "القليوبية" via shared leading characters.
  bool _namesMatch(String a, String b) {
    final na = _stripPrefix(a.trim());
    final nb = _stripPrefix(b.trim());
    if (na.isEmpty || nb.isEmpty) return false; // Exact match after stripping
    if (na == nb) return true;
    // One fully contains the other (require ≥4 chars to avoid "ال" false hits)
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
            'لم يتمكن التطبيق من تحديد المحافظة تلقائيًا،\nيرجى الاختيار يدويًا';
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
                'تم رفض إذن الموقع بشكل دائم، يرجى تفعيله من إعدادات التطبيق';
          });
        }
        return;
      }
      if (perm == LocationPermission.denied) {
        if (mounted) {
          setState(() {
            _gpsFinished = true;
            _gpsFailureMessage = 'لا يمكن تحديد الموقع دون منح إذن الوصول';
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
                'خدمة الموقع معطّلة، يرجى تفعيلها لتحديد المحافظة تلقائيًا';
          });
        }
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
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
          receiveTimeout: const Duration(seconds: 10),
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
  final Map<String, String> _categoryAssets = {
    'فحص شامل': 'assets/svg/فحص شامل.svg',
    'حشو أسنان': 'assets/svg/حشو اسنان.svg',
    'حشو تجميلي': 'assets/svg/تجميلي.svg',
    'حشو املجم': 'assets/svg/املغم.svg',
    'حشو عصب': 'assets/svg/حشو اسنان.svg',
    'زراعة أسنان': 'assets/svg/زراعه اسنان.svg',
    'زراعة الأسنان': 'assets/svg/زراعه اسنان.svg',
    'خلع الأسنان': 'assets/svg/خلع اسنان.svg',
    'الجراحة والخلع': 'assets/svg/خلع اسنان.svg',
    'تبييض الأسنان': 'assets/svg/تبيض اسنان.svg',
    'تنظيف وتبييض الأسنان': 'assets/svg/تبيض اسنان.svg',
    'تقويم الأسنان': 'assets/svg/تقويم اسنان.svg',
    'تيجان وجسور': 'assets/images/تيجان وجسور.webp',
    'تركيبات الأسنان': 'assets/svg/تركيبات اسنان.svg',
    'تركيبات متحركة': 'assets/svg/تركيبات اسنان.svg',
    'طب أسنان الأطفال': 'assets/svg/اطفال2.svg',
  };

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
              nextScreen: const SecondaryHomeScreen(
                drawer: DoctorDrawer(),
                showAddCaseCategory: true,
              ),
              nextRouteSettings: const RouteSettings(name: 'add-case'),
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
      'حشو املغم.svg',
      'حشو عصب .svg',
      'حشو تجميلي.svg',
      'زراعه الأسنان.svg',
      'الجراحة وخلع .svg',
      'تنظيف وتبييض الأسنان .svg',
      'تقويم الأسنان.svg',
      'تركيبات متحركة.svg',
      'تيجان وجسور.svg',
      'طب أسنان الأطفال.svg',
    ];

    final categoryNames = [
      'حشو املغم',
      'حشو عصب',
      'حشو تجميلي',
      'زراعة الأسنان',
      'الجراحة والخلع ',
      'تنظيف وتبييض الأسنان',
      'تقويم الأسنان',
      'تركيبات  متحركة',
      'تيجان وجسور',
      'طب أسنان الأطفال',
    ];

    final fileName =
        index < svgFiles.length ? svgFiles[index] : 'placeholder.svg';
    final resolvedAssetPath =
        assetPath.isNotEmpty ? assetPath : 'assets/svg/$fileName';
    final resolvedCategoryName = categoryName.isNotEmpty
        ? categoryName
        : (index < categoryNames.length ? categoryNames[index] : '');

    return GestureDetector(
      onTap: () {
        _handleCategoryTap(
          categoryName: resolvedCategoryName,
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
                  ? Colors.black.withValues(alpha: 0.3)
                  : Colors.grey.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 12),
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
                          child: const Icon(Icons.image, size: 32, color: Colors.grey),
                        ),
                      )
                    : Image.asset(
                        resolvedAssetPath,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: isDark ? Colors.grey[800] : Colors.grey[200],
                          child: const Icon(Icons.image, size: 32, color: Colors.grey),
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 8),
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
            const SizedBox(height: 12),
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
    return name.contains('نشر حالة جديدة') ||
        name.contains('إضافة حالة جديدة') ||
        compact.contains('نشرحالةجديدة') ||
        compact.contains('اضافةحالةجديدة');
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

          final navigator = Navigator.of(context);

          if (navigator.canPop()) {
            navigator.pop();
          } else {
            if (widget.drawer is DoctorDrawer) {
              navigator.pushReplacementNamed(Routes.doctorHomeScreen);
            } else {
              if (context.mounted) {
                final doctorId = await SharedPrefHelper.getInt('doctor_id');
                navigator.pushNamedAndRemoveUntil(
                  doctorId != 0 ? Routes.doctorHomeScreen : Routes.categoriesScreen,
                  (route) => false,
                );
              }
            }
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
                Navigator.of(context).canPop()
                    ? Icons.arrow_back_ios_new_rounded
                    : Icons.menu,
                size: 24,
                color: Theme.of(context).iconTheme.color,
              ),
              onPressed: () async {
                final navigator = Navigator.of(context);
                if (navigator.canPop()) {
                  navigator.pop();
                } else {
                  _scaffoldKey.currentState?.openDrawer();
                }
              },
            ),
            title: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'نشر حالة جديدة',
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
        drawer: widget.drawer,
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
                return const Center(child: CircularProgressIndicator());
              } else if (state is DoctorError) {
                return Center(
                    child: Text(state.error,
                        style: const TextStyle(fontFamily: 'Cairo')));
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
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(
                                      right: 4, bottom: 8),
                                  child: Text(
                                    'اختر المحافظة',
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
                                          : const Color(0xFFD1D5DC),
                                      width: 1.1,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary
                                            .withAlpha(77),
                                        blurRadius: 4,
                                        offset: const Offset(0, 1),
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
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              _isDetecting
                                                  ? 'جارٍ تحديد موقعك...'
                                                  : 'اختر المدينة',
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
                                  const Icon(Icons.location_off,
                                      color: Colors.orange, size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _gpsFailureMessage!,
                                      style: TextStyle(
                                        fontFamily: 'Cairo',
                                        fontSize: baseFontSize * 0.8,
                                        color: isDark ? Colors.white.withOpacity(0.9) : Colors.orange.shade800,
                                      ),
                                      textDirection: TextDirection.rtl,
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
                            'اختر التخصص لنشر الحالة',
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
                                  physics: const NeverScrollableScrollPhysics(),
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
                                        _categoryAssets[category.name] ??
                                            'assets/svg/فحص شامل.svg';

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

                        const SizedBox(height: 100), // Reserve space at bottom
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
