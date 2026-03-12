import 'dart:ui';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:geolocator/geolocator.dart';
import 'package:thotha_mobile_app/core/networking/models/city_model.dart';
import 'package:thotha_mobile_app/features/home_screen/ui/category_doctors_screen.dart';
import 'package:thotha_mobile_app/features/home_screen/ui/drawer/drawer.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:thotha_mobile_app/core/di/dependency_injection.dart';
import 'package:thotha_mobile_app/features/home_screen/logic/doctor_cubit.dart';

import 'package:thotha_mobile_app/features/home_screen/logic/doctor_state.dart';


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
  List<CityModel> _loadedCities = [];
  bool _isDetecting = false;
  bool _gpsFinished = false;
  bool _autoSelectApplied = false;
  List<String> _gpsNameCandidates = [];
  String? _gpsFailureMessage;

  // Asset mapping for categories
  final Map<String, String> _categoryAssets = {
    'فحص شامل': 'assets/svg/فحص شامل.svg',
    'حشو أسنان': 'assets/svg/حشو اسنان.svg',
    'زراعة أسنان': 'assets/svg/زراعه اسنان.svg',
    'خلع الأسنان': 'assets/svg/خلع اسنان.svg',
    'تبييض الأسنان': 'assets/svg/تبيض اسنان.svg',
    'تقويم الأسنان': 'assets/svg/تقويم اسنان.svg',
    'تركيبات الأسنان': 'assets/svg/تركيبات اسنان.svg',
  };

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
          showAddCaseButton: widget.showAddCaseCategory,
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
      'فحص شامل.svg',
      'حشو اسنان.svg',
      'زراعه اسنان.svg',
      'خلع اسنان.svg',
      'تبيض اسنان.svg',
      'تقويم اسنان.svg',
      'تركيبات اسنان.svg',
    ];

    final categoryNames = [
      'فحص شامل',
      'حشو أسنان',
      'زراعة أسنان',
      'خلع الأسنان',
      'تبييض الأسنان',
      'تقويم الأسنان',
      'تركيبات الأسنان',
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
            SvgPicture.asset(
              resolvedAssetPath,
              width: 48 * (width / 390),
              height: 48 * (width / 390),
              fit: BoxFit.contain,
              placeholderBuilder: (BuildContext context) => Container(
                width: 48,
                height: 48,
                color: isDark ? Colors.grey[800] : Colors.grey[200],
                child: const Icon(Icons.image, size: 24, color: Colors.grey),
              ),
            ),
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
  void initState() {
    super.initState();
    _autoDetectCity();
  }

  /// Strips common Arabic administrative prefixes
  String _stripPrefix(String s) => s
      .replaceAll(RegExp(r'^محافظة\s*'), '')
      .replaceAll(RegExp(r'^مديرية\s*'), '')
      .replaceAll(RegExp(r'^مدينة\s*'), '')
      .replaceAll(RegExp(r'^قسم\s*'), '')
      .replaceAll(RegExp(r'\s*محافظة$'), '')
      .trim();

  /// Returns true if [a] and [b] share enough characters
  bool _namesMatch(String a, String b) {
    final na = _stripPrefix(a.trim());
    final nb = _stripPrefix(b.trim());
    if (na.isEmpty || nb.isEmpty) return false;
    if (na.contains(nb) || nb.contains(na)) return true;
    for (int len = 3; len <= na.length && len <= nb.length; len++) {
      for (int i = 0; i <= na.length - len; i++) {
        if (nb.contains(na.substring(i, i + len))) return true;
      }
    }
    return false;
  }

  /// Tries to match GPS candidates against loaded cities
  void _tryAutoSelectCity() {
    print('=== GPS: _tryAutoSelectCity called ===');
    print('=== GPS: _autoSelectApplied = $_autoSelectApplied ===');
    print('=== GPS: _selectedCityId = $_selectedCityId ===');
    print('=== GPS: _gpsFinished = $_gpsFinished ===');
    print('=== GPS: _loadedCities count = ${_loadedCities.length} ===');
    print('=== GPS: candidates = $_gpsNameCandidates ===');
    
    if (_autoSelectApplied || _selectedCityId != null) {
      print('=== GPS: Already applied or city selected, returning ===');
      return;
    }
    if (!_gpsFinished || _loadedCities.isEmpty) {
      print('=== GPS: GPS not finished or no cities loaded, returning ===');
      return;
    }

    _autoSelectApplied = true;

    CityModel? match;
    outer:
    for (final raw in _gpsNameCandidates) {
      for (final c in _loadedCities) {
        print('=== GPS: Comparing "$raw" with "${c.name}" ===');
        if (_namesMatch(raw, c.name)) {
          match = c;
          print('=== GPS: MATCH FOUND! ${c.name} (id: ${c.id}) ===');
          break outer;
        }
      }
    }

    if (match != null && mounted) {
      print('=== GPS: Setting city to ${match.name} ===');
      setState(() {
        _selectedCityId = match!.id;
        _gpsFailureMessage = null;
      });
      context.read<DoctorCubit>().filterByCity(match.id);
    } else {
      print('=== GPS: No match found ===');
    }
  }

  /// Gets GPS coordinates and auto-selects city
  Future<void> _autoDetectCity() async {
    print('=== GPS: Starting auto detection ===');
    if (!mounted) {
      print('=== GPS: Not mounted, returning ===');
      return;
    }
    setState(() => _isDetecting = true);
    try {
      print('=== GPS: Checking permission ===');
      LocationPermission perm = await Geolocator.checkPermission();
      print('=== GPS: Current permission = $perm ===');
      if (perm == LocationPermission.denied) {
        print('=== GPS: Permission denied, requesting ===');
        perm = await Geolocator.requestPermission();
        print('=== GPS: After request permission = $perm ===');
      }
      if (perm == LocationPermission.deniedForever || perm == LocationPermission.denied) {
        print('=== GPS: Permission still denied ===');
        if (mounted) {
          setState(() {
            _gpsFinished = true;
            _gpsFailureMessage = 'لا يمكن تحديد الموقع دون منح إذن الوصول';
          });
        }
        return;
      }

      print('=== GPS: Checking if service enabled ===');
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      print('=== GPS: Service enabled = $serviceEnabled ===');
      if (!serviceEnabled) {
        if (mounted) {
          setState(() {
            _gpsFinished = true;
            _gpsFailureMessage = 'خدمة الموقع معطّلة';
          });
        }
        return;
      }

      print('=== GPS: Getting current position ===');
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 15),
        ),
      );
      print('=== GPS: Position = ${pos.latitude}, ${pos.longitude} ===');

      print('=== GPS: Calling Nominatim API ===');
      final dio = Dio();
      final res = await dio.get(
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
      print('=== GPS: API status = ${res.statusCode} ===');
      print('=== GPS: API data = ${res.data} ===');

      final candidates = <String>[];
      const addressKeys = ['state', 'county', 'city', 'town', 'village', 'state_district', 'region', 'municipality'];

      if (res.statusCode == 200 && res.data is Map) {
        final address = res.data['address'] as Map?;
        print('=== GPS: Address = $address ===');
        if (address != null) {
          for (final key in addressKeys) {
            final v = address[key];
            if (v is String && v.isNotEmpty) {
              candidates.add(v);
              print('=== GPS: Found candidate - $key: $v ===');
            }
          }
        }
      }

      print('=== GPS: Total candidates = ${candidates.length} ===');
      if (mounted) {
        setState(() => _gpsNameCandidates = candidates);
      }
    } catch (e, stack) {
      print('=== GPS: ERROR = $e ===');
      print('=== GPS: STACK = $stack ===');
    } finally {
      print('=== GPS: Finished, calling _tryAutoSelectCity ===');
      if (mounted) {
        setState(() {
          _gpsFinished = true;
          _isDetecting = false;
        });
      }
      _tryAutoSelectCity();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
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
          actions: [
            if (_selectedCityId != null)
              BlocBuilder<DoctorCubit, DoctorState>(
                builder: (context, state) {
                  String? cityName;
                  if (state is DoctorSuccess) {
                    final selectedCity = state.cities.firstWhere(
                      (c) => c.id == _selectedCityId,
                      orElse: () => state.cities.first,
                    );
                    cityName = selectedCity.name;
                  }
                  if (cityName == null) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          cityName,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontFamily: 'Cairo',
                            fontSize: baseFontSize * 0.85,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.location_on,
                          size: 20,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
        drawer: widget.drawer,
        body: SafeArea(
          child: BlocConsumer<DoctorCubit, DoctorState>(
            listener: (context, state) {
              if (state is DoctorSuccess && state.cities.isNotEmpty) {
                _loadedCities = state.cities;
                _tryAutoSelectCity();
              }
            },
            builder: (context, state) {
              if (state is DoctorLoading) {
                return const Center(child: CircularProgressIndicator());
              } else if (state is DoctorError) {
                return Center(child: Text(state.error, style: const TextStyle(fontFamily: 'Cairo')));
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              if (_isDetecting || _gpsFailureMessage != null)
                                Padding(
                                  padding: const EdgeInsets.only(right: 4, bottom: 8),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (_isDetecting)
                                        SizedBox(
                                          width: 14,
                                          height: 14,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Theme.of(context).colorScheme.primary,
                                          ),
                                        ),
                                      if (_isDetecting) const SizedBox(width: 8),
                                      Text(
                                        _isDetecting
                                            ? 'جارٍ تحديد موقعك...'
                                            : _gpsFailureMessage ?? '',
                                        style: TextStyle(
                                          fontFamily: 'Cairo',
                                          fontSize: baseFontSize * 0.8,
                                          color: _gpsFailureMessage != null
                                              ? Colors.orange
                                              : Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              Container(
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
                                    hint: Text(
                                      'اختر المدينة',
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontFamily: 'Cairo',
                                        fontSize: baseFontSize * 0.875,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    isExpanded: true,
                                    icon: Icon(Icons.arrow_drop_down, color: Theme.of(context).iconTheme.color),
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
                                        context.read<DoctorCubit>().filterByCity(val);
                                      }
                                    },
                                  ),
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
                                    final asset = _categoryAssets[category.name] ??
                                        'assets/svg/فحص شامل.svg';

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
