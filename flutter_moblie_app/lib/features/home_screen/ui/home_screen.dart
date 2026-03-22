import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:thotha_mobile_app/features/home_screen/ui/category_doctors_screen.dart';
import 'package:thotha_mobile_app/features/home_screen/ui/drawer/drawer.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:dio/dio.dart';
import 'package:thotha_mobile_app/core/di/dependency_injection.dart';
import 'package:thotha_mobile_app/features/home_screen/logic/doctor_cubit.dart';
import 'package:thotha_mobile_app/features/home_screen/logic/doctor_state.dart';
import 'package:thotha_mobile_app/core/helpers/shared_pref_helper.dart';
import 'package:thotha_mobile_app/core/helpers/constants.dart';
import 'package:thotha_mobile_app/core/networking/models/city_model.dart';
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.drawer = const HomeDrawer(), this.showAddCaseCategory = false});
  final Widget drawer;
  final bool showAddCaseCategory;
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}
class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
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

  // Asset mapping for categories
  final Map<String, String> _categoryAssets = {
    'حشو املجم': 'assets/svg/املغم.svg',
    'حشو عصب': 'assets/svg/حشو اسنان.svg',
    'حشو تجميلي': 'assets/svg/تجميلي.svg',
    'زراعة الأسنان': 'assets/svg/زراعه اسنان.svg',
    'الجراحة والخلع': 'assets/svg/خلع اسنان.svg',
    'تنظيف وتبيض الأسنان': 'assets/svg/تبيض اسنان.svg',
    'تبييض الأسنان': 'assets/svg/تبيض اسنان.svg',
    'تقويم الأسنان': 'assets/svg/تقويم اسنان.svg',
    'تركيبات الأسنان': 'assets/svg/تركيبات اسنان.svg',
    'التيجان والجسور': 'assets/images/تيجان وجسور.webp',
    'طب أسنان الأطفال': 'assets/svg/اطفال2.svg',
    'تركيبات متحركة': 'assets/svg/تركيبات اسنان.svg',
  };

  String _getAssetForCategory(String categoryName) {
    // Check for exact match
    if (_categoryAssets.containsKey(categoryName)) {
      return _categoryAssets[categoryName]!;
    }
    
    // Check for partial matches
    if (categoryName.contains('فحص')) return 'assets/svg/فحص شامل.svg';
    if (categoryName.contains('املجم') || categoryName.contains('amalgam')) return 'assets/svg/املغم.svg';
    if (categoryName.contains('عصب')) return 'assets/svg/حشو اسنان.svg';
    if (categoryName.contains('تجميلي')) return 'assets/svg/تجميلي.svg';
    if (categoryName.contains('زراعة')) return 'assets/svg/زراعه اسنان.svg';
    if (categoryName.contains('خلع') || categoryName.contains('جراحة')) return 'assets/svg/خلع اسنان.svg';
    if (categoryName.contains('تنظيف') || categoryName.contains('تبييض')) return 'assets/svg/تبيض اسنان.svg';
    if (categoryName.contains('تقويم')) return 'assets/svg/تقويم اسنان.svg';
    if (categoryName.contains('تركيبات') && categoryName.contains('متحركة')) return 'assets/svg/تركيبات اسنان.svg';
    if (categoryName.contains('تركيبات')) return 'assets/svg/تركيبات اسنان.svg';
    if (categoryName.contains('تيجان') || categoryName.contains('جسور')) return 'assets/images/تيجان وجسور.webp';
    if (categoryName.contains('اطفال') || categoryName.contains('pediatric')) return 'assets/svg/اطفال2.svg';
    
    // Default fallback
    return 'assets/svg/فحص شامل.svg';
  }

  Future<void> _handleCategoryTap({
    required String categoryName,
    required int? categoryId,
    required String? cityName,
  }) async {
    // Navigation restricted to CategoryDoctorsScreen
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CategoryDoctorsScreen(
          categoryName: categoryName,
          categoryId: categoryId,
          cityId: _selectedCityId,
          cityName: cityName,
        ),
      ),
    );
  }

  Widget _buildSquareCategory(
      String assetPath, 
      int index, 
      String categoryName,
      double width,
      double height,
      double baseFontSize,
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
      'تيجان وجسور.webp',
      'اطفال.svg',
      'تركيبات اسنان.svg',
    ];

    final categoryNames = [
      'حشو املجم',
      'حشو عصب',
      'حشو تجميلي',
      'زراعة الأسنان',
      'الجراحة والخلع',
      'تنظيف وتبيض الأسنان',
      'تقويم الأسنان',
      'تركيبات الأسنان',
      'التيجان والجسور',
      'طب أسنان الأطفال',
      'تركيبات متحركة',
    ];

    final fileName = index < svgFiles.length ? svgFiles[index] : 'placeholder.svg';
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
              color: isDark ? Colors.black.withValues(alpha: 0.3) : Colors.grey.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Handle both SVG and regular images
            if (resolvedAssetPath.endsWith('.svg')) ...[
              SvgPicture.asset(
                resolvedAssetPath,
                width: 68 * (width / 390),
                height: 68 * (width / 390),
                fit: BoxFit.contain,
                placeholderBuilder: (BuildContext context) => Container(
                  width: 68,
                  height: 68,
                  color: isDark ? Colors.grey[800] : Colors.grey[200],
                  child: const Icon(Icons.image, size: 24, color: Colors.grey),
                ),
              ),
            ] else ...[
              Image.asset(
                resolvedAssetPath,
                width: 68 * (width / 390),
                height: 68 * (width / 390),
                fit: BoxFit.contain,
              ),
            ],
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                resolvedCategoryName,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.w600,
                      fontSize: baseFontSize * 0.875, // 14sp
                      height: 1.2,
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

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
  bool _namesMatch(String a, String b) {
    final na = _stripPrefix(a.trim());
    final nb = _stripPrefix(b.trim());
    if (na.isEmpty || nb.isEmpty) return false;
    if (na == nb) return true;
    if (na.length >= 4 && nb.contains(na)) return true;
    if (nb.length >= 4 && na.contains(nb)) return true;
    return false;
  }

  /// Tries to match any GPS candidate against the loaded cities list.
  void _tryAutoSelectCity() {
    if (_isLoggedIn) return;
    if (_autoSelectApplied || _selectedCityId != null) return;
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
      // Optionally trigger search automatically
      context.read<DoctorCubit>().filterByCity(match.id);
    } else {
      setState(() {
        _gpsFailureMessage =
            'لم يتمكن التطبيق من تحديد المحافظة تلقائيًا،\nيرجى الاختيار يدويًا';
      });
    }
  }

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
        'state', 'county', 'city', 'town', 'village', 'state_district', 'region', 'municipality'
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
      // Silently fail, _tryAutoSelectCity will handle the empty candidates
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
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;
    final baseFontSize = width * 0.04;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocProvider(
      create: (context) => getIt<DoctorCubit>()..loadInitialData(),
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

                final filteredCategories = (_searchController.text.isEmpty || categories.isEmpty)
                    ? categories
                    : categories
                        .where((c) => c.name.contains(_searchController.text))
                        .toList();

                final visibleCategories = filteredCategories
                    
                    .toList();

                return SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.zero,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Search Bar
                        Container(
                          height: 48,
                          margin: EdgeInsets.symmetric(horizontal: width * 0.05, vertical: 10),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.grey[800]?.withValues(alpha: 0.5)
                                : const Color(0xFFD9D9D9).withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 12),
                                child: Icon(Icons.search, color: Colors.grey, size: 22),
                              ),
                              Expanded(
                                child: TextField(
                                  controller: _searchController,
                                  focusNode: _searchFocusNode,
                                  onChanged: (val) {
                                    setState(() {});
                                  },
                                  textAlign: TextAlign.right,
                                  textDirection: TextDirection.rtl,
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontFamily: 'Cairo'),
                                  decoration: InputDecoration(
                                    hintText: 'ابحث عن قسم...',
                                    hintStyle: TextStyle(
                                      fontFamily: 'Cairo',
                                      color: Colors.grey[600],
                                      fontSize: baseFontSize * 0.9,
                                    ),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.mic, color: Colors.grey, size: 22),
                                onPressed: () {},
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                              const SizedBox(width: 8),
                            ],
                          ),
                        ),

                        // Gradient Card
                        Container(
                          width: double.infinity,
                          height: 140,
                          margin: EdgeInsets.symmetric(horizontal: width * 0.05, vertical: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            gradient: const LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [Color(0xFF95F8C9), Color(0xFF54CAF7)],
                            ),
                          ),
                          child: Stack(
                            children: [
                              Positioned(
                                left: 0,
                                top: 10,
                                bottom: 10,
                                child: Image.asset(
                                  'assets/images/دكتور.png',
                                  width: width * 0.4,
                                  fit: BoxFit.contain,
                                ),
                              ),
                              Positioned(
                                right: 20,
                                top: 20,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      'احجز و سجل',
                                      style: TextStyle(
                                        fontFamily: 'Cairo',
                                        color: Colors.white,
                                        fontSize: baseFontSize * 0.9375, // 15sp
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.right,
                                    ),
                                    const SizedBox(height: 8),
                                    SizedBox(
                                      width: width * 0.4,
                                      child: Text(
                                        'مع افضل الاطباء في نطاقك',
                                        style: TextStyle(
                                          fontFamily: 'Cairo',
                                          color: Colors.white,
                                          fontSize: baseFontSize * 0.8125, // 13sp
                                          fontWeight: FontWeight.bold,
                                        ),
                                        textAlign: TextAlign.right,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'احجز الان',
                                        style: TextStyle(
                                          fontFamily: 'Cairo',
                                          color: Colors.black,
                                          fontSize: baseFontSize * 0.7, // 11sp
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // City Dropdown
                        Container(
                          width: double.infinity,
                          margin: EdgeInsets.symmetric(horizontal: width * 0.06, vertical: 16),
                          child: Container(
                            height: 52,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isDark ? Colors.grey[700]! : const Color(0xFFD1D5DC),
                                width: 1.1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
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
                                            : Colors.grey[500],
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
                                                fontSize: baseFontSize * 0.875,
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
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontFamily: 'Cairo',
                                        fontSize: baseFontSize * 0.875,
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
                        ),

                        // GPS failure banner
                        if (!_isLoggedIn && _gpsFailureMessage != null)
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
                                      color: Colors.orange.shade800,
                                    ),
                                    textDirection: TextDirection.rtl,
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Services Header
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Text(
                            'الخدمات المتوفرة',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontFamily: 'Cairo',
                              fontWeight: FontWeight.bold,
                              fontSize: baseFontSize * 1.06, // 17sp
                              height: 1.2,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),

                        // Categories Grid
                        if (visibleCategories.isNotEmpty)
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: width * 0.05),
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final crossAxisCount = width > 600 ? 4 : 2;
                                return GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: crossAxisCount,
                                    mainAxisSpacing: 12,
                                    crossAxisSpacing: 12,
                                    childAspectRatio: 1.0,
                                  ),
                                  itemCount: visibleCategories.length,
                                  itemBuilder: (context, index) {
                                    final category = visibleCategories[index];
                                    final asset = _getAssetForCategory(category.name);

                                    String? selectedCityName;
                                    if (_selectedCityId != null) {
                                      try {
                                        selectedCityName = cities
                                            .firstWhere((c) => c.id == _selectedCityId)
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

                        const SizedBox(height: 20),
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
    );
  }
}
