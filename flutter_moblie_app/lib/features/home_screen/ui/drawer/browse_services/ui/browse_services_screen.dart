import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:thotha_mobile_app/features/home_screen/ui/category_doctors_screen.dart';
import 'package:thotha_mobile_app/features/home_screen/ui/drawer/drawer.dart';

final List<String> categoryNames = [
  'فحص شامل',
  'حشو العصب',
  'زراعه الأسنان',
  'خلع الأسنان',
  'تبييض الأسنان',
  'تقويم الأسنان',
  'تركيبات الأسنان',
];
final svgFiles = [
  'فحص شامل.svg',
  'حشو اسنان.svg',
  'زراعه اسنان.svg',
  'خلع اسنان.svg',
  'تبيض اسنان.svg',
  'تقويم اسنان.svg',
  'تركيبات اسنان.svg',
];
final Map<String, String> serviceDescriptions = {
  'فحص شامل': 'فحص شامل للأسنان واللثة ',
  'حشو العصب': 'علاج جذور الأسنان',
  'زراعه الأسنان': 'حلول للأسنان المفقودة',
  'خلع الأسنان': 'خلع بسيط وجراحي للأسنان',
  'تبييض الأسنان': 'تنظيف وإزالة الجير',
  'تقويم الأسنان': 'تقويم شفاف وتقليدي',
  'تركيبات الأسنان': 'تركيبات ثابتة ومتحركة',
};

class BrowseServicesScreen extends StatefulWidget {
  const BrowseServicesScreen({super.key});

  @override
  State<BrowseServicesScreen> createState() => _BrowseServicesScreenState();
}

class _BrowseServicesScreenState extends State<BrowseServicesScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  Future<String> _loadSvg(String path) async {
    try {
      await DefaultAssetBundle.of(context).loadString(path);
      return path;
    } catch (e) {
      debugPrint('Failed to load SVG at path: $path');
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;
    final baseFontSize = width * 0.04;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: theme.scaffoldBackgroundColor,
      drawer: const Drawer(
        child: HomeDrawer(),
      ),
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: SizedBox(
          width: double.infinity,
          height: 50,
          child: Stack(
            children: [
              Positioned(
                left: 0,
                child: IconButton(
                  icon: Icon(
                    Icons.menu,
                    color: theme.iconTheme.color,
                    size: 32 * (width / 390),
                  ),
                  onPressed: () {
                    _scaffoldKey.currentState?.openDrawer();
                  },
                ),
              ),
              Positioned(
                right: width * 0.08,
                child: Image.asset(
                  'assets/images/splash-logo.png',
                  width: 46 * (width / 390),
                  height: 50 * (width / 390),
                  fit: BoxFit.contain,
                ),
              ),
            ],
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: width * 0.05, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(width: 70), // Placeholder for left-side icons if any
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'مرحباً، أهلاً بعودتك',
                      textDirection: TextDirection.rtl,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.w400,
                        fontSize: baseFontSize, // 16
                        height: 1.5,
                        color: const Color(0xFF858585),
                      ),
                    ),
                    Text(
                      'تصفح ما لدينا',
                      textDirection: TextDirection.rtl,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.w600,
                        fontSize: baseFontSize * 1.375, // 22
                        height: 1.5,
                        color: isDark ? Colors.white : const Color(0xFF101828),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(right: width * 0.09, top: 20, bottom: 10),
            child: Text(
              'جميع الخدمات المتوفرة',
              style: theme.textTheme.titleLarge?.copyWith(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.bold,
                fontSize: baseFontSize * 1.5, // 24
                height: 1.5,
              ),
              textAlign: TextAlign.right,
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: width * 0.05),
              itemCount: categoryNames.length,
              itemBuilder: (context, index) {
                return InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CategoryDoctorsScreen(
                          categoryName: categoryNames[index],
                          categoryId: null,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 15),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.cardTheme.color ?? colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        width: 1.1,
                        color: isDark ? Colors.grey[700]! : const Color(0xFFE5E7EB),
                      ),
                    ),
                    child: Row(
                      textDirection: TextDirection.rtl,
                      children: [
                        Container(
                          width: 80 * (width / 390),
                          height: 80 * (width / 390),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Color(0xFF84E5F3), Color(0xFF8DECB4)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: FutureBuilder<String>(
                            future: _loadSvg('assets/svg/${svgFiles[index]}'),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                              } else if (snapshot.hasError) {
                                return Icon(Icons.medical_services, color: Colors.blue[400], size: 30);
                              } else {
                                return SvgPicture.asset(
                                  'assets/svg/${svgFiles[index]}',
                                  fit: BoxFit.contain,
                                );
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                categoryNames[index],
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontWeight: FontWeight.w600,
                                  fontSize: baseFontSize * 1.125, // 18
                                  height: 1.5,
                                  color: isDark ? Colors.white : const Color(0xFF0A0A0A),
                                ),
                                textAlign: TextAlign.right,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                serviceDescriptions[categoryNames[index]] ?? '',
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontWeight: FontWeight.w400,
                                  fontSize: baseFontSize * 0.875, // 14
                                  height: 1.5,
                                  color: (isDark ? Colors.white : const Color(0xFF858585)).withOpacity(0.7),
                                ),
                                textAlign: TextAlign.right,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text(
                                    'طالب متاح ',
                                    style: TextStyle(
                                      fontFamily: 'Cairo',
                                      fontSize: baseFontSize * 0.75, // 12
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                  Text(
                                    '${index + 5} ',
                                    style: TextStyle(
                                      fontFamily: 'Cairo',
                                      fontSize: baseFontSize * 0.75, // 12
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.person_outline,
                                    color: theme.colorScheme.primary,
                                    size: 16,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
