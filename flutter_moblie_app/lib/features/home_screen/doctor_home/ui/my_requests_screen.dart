import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:thotha_mobile_app/core/di/dependency_injection.dart';
import 'package:thotha_mobile_app/core/networking/dio_factory.dart';
import 'package:thotha_mobile_app/core/theming/colors.dart';
import 'package:thotha_mobile_app/features/home_screen/data/models/case_request_model.dart';
import 'package:thotha_mobile_app/features/home_screen/data/repositories/case_request_repo.dart';
import 'package:thotha_mobile_app/core/helpers/shared_pref_helper.dart';
import 'package:thotha_mobile_app/features/home_screen/doctor_home/ui/doctor_home_screen.dart';

class MyRequestsScreen extends StatefulWidget {
  const MyRequestsScreen({Key? key}) : super(key: key);

  @override
  State<MyRequestsScreen> createState() => _MyRequestsScreenState();
}

class _MyRequestsScreenState extends State<MyRequestsScreen> {
  final CaseRequestRepo _repo = getIt<CaseRequestRepo>();

  List<CaseRequestModel> _requests = [];
  bool _isLoading = false;
  String? _error;
  int? _doctorId;

  @override
  void initState() {
    super.initState();
    _initAndLoad();
  }

  Future<void> _initAndLoad() async {
    // doctor_id مخزن كـ int عن طريق setData — نستخدم getInt مباشرة
    int doctorId = await SharedPrefHelper.getInt('doctor_id');

    // fallback: لو getInt رجع 0 نحاول getString (للتوافق مع نسخ قديمة)
    if (doctorId == 0) {
      final idString = await SharedPrefHelper.getString('doctor_id');
      doctorId = int.tryParse(idString) ?? 0;
    }

    // Try fetching profile if ID is missing
    if (doctorId == 0) {
      if (mounted) setState(() => _isLoading = true);

      try {
        // Prepare headers explicitly to avoid race condition in DioFactory
        await DioFactory.addDioHeaders();
        final dio = DioFactory.getDio();

        Response? response;
        // Try multiple potential profile endpoints
        final endpoints = [
          '/profile',
          '/me',
          '/api/profile',
          '/api/me',
          '/api/auth/profile',
          '/api/auth/me'
        ];

        for (final endpoint in endpoints) {
          try {
            response = await dio.get(endpoint);
            if (response.statusCode == 200) break;
          } catch (_) {}
        }

        if (response != null && response.statusCode == 200) {
          final data = response.data;

          int? fetchedId;
          if (data is Map) {
            final raw = data['id'] ?? (data['user'] is Map ? data['user']['id'] : null);
            fetchedId = int.tryParse(raw?.toString() ?? '');
          }

          if (fetchedId != null && fetchedId != 0) {
            doctorId = fetchedId;
            await SharedPrefHelper.setData('doctor_id', doctorId);
          }
        }
      } catch (_) {
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }

    if (!mounted) return;

    if (doctorId == 0) {
      setState(() {
        _error = 'تعذر تحديد هوية الطبيب، يرجى تسجيل الدخول مرة أخرى';
      });
      return;
    }

    setState(() {
      _doctorId = doctorId;
    });

    await _loadRequests();
  }

  Future<void> _loadRequests() async {
    if (_doctorId == null) return;
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final result = await _repo.getRequestsByDoctorId(_doctorId!);
    if (!mounted) return;

    if (result['success'] == true) {
      setState(() {
        _requests = List<CaseRequestModel>.from(result['data'] as List);
        _isLoading = false;
      });
    } else {
      setState(() {
        _error = result['error']?.toString() ?? 'فشل في تحميل طلباتي';
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteRequest(CaseRequestModel request) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'حذف الطلب',
            style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700),
          ),
          content: const Text(
            'هل أنت متأكد من حذف هذا الطلب؟',
            style: TextStyle(fontFamily: 'Cairo'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text(
                'إلغاء',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  color: Colors.grey,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text(
                'حذف',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (confirm != true || !mounted) return;

    // إظهار لودينج بسيط أثناء الحذف
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final result = await _repo.deleteRequest(request.id ?? 0);

    if (!mounted) return;
    Navigator.pop(context); // إغلاق اللودينج

    if (result['success'] == true) {
      setState(() {
        _requests.removeWhere((r) => r.id == request.id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'تم حذف الطلب بنجاح',
            style: TextStyle(fontFamily: 'Cairo'),
          ),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'فشل في حذف الطلب',
            style: TextStyle(fontFamily: 'Cairo'),
          ),
          backgroundColor: Colors.red[700],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final baseFontSize = width * 0.04;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'طلباتي',
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: baseFontSize * 1.125,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: ColorsManager.mainBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          tooltip: 'رجوع',
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  settings: const RouteSettings(name: 'doctor-home'),
                  builder: (context) => const DoctorHomeScreen(),
                ),
              );
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.home_rounded),
            tooltip: 'الرئيسية',
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  settings: const RouteSettings(name: 'doctor-home'),
                  builder: (context) => const DoctorHomeScreen(),
                ),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _buildError(baseFontSize)
                : _requests.isEmpty
                    ? _buildEmpty(baseFontSize, width)
                    : RefreshIndicator(
                        onRefresh: _loadRequests,
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ListView.builder(
                                itemCount: _requests.length,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemBuilder: (context, index) {
                                  final req = _requests[index];
                                  return _buildRequestCard(
                                    req,
                                    width,
                                    baseFontSize,
                                    isDark,
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
      ),
    );
  }

  Widget _buildRequestCard(
    CaseRequestModel req,
    double width,
    double baseFontSize,
    bool isDark,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    req.categoryName,
                    style: TextStyle(
                      fontSize: baseFontSize * 1.125,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ),
                Row(
                  children: [
                    if (req.id != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color:
                              ColorsManager.mainBlue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '#${req.id}',
                          style: TextStyle(
                            color: ColorsManager.mainBlue,
                            fontSize: baseFontSize * 0.75,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Cairo',
                          ),
                        ),
                      ),
                    const SizedBox(width: 8),
                    Material(
                      color: Colors.red.withValues(alpha: 0.08),
                      shape: const CircleBorder(),
                      child: IconButton(
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          color: Colors.red,
                          size: 20,
                        ),
                        onPressed: () => _deleteRequest(req),
                        tooltip: 'حذف الطلب',
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Doctor name
            Row(children: [
              Icon(Icons.person_outline, size: 14, color: Colors.grey[500]),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  req.doctorFullName,
                  style: TextStyle(
                    fontSize: baseFontSize * 0.875,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    fontFamily: 'Cairo',
                  ),
                ),
              ),
            ]),
            // City
            if (req.doctorCityName.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(children: [
                Icon(Icons.location_on_outlined, size: 14, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    req.doctorCityName,
                    style: TextStyle(
                      fontSize: baseFontSize * 0.875,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                      fontFamily: 'Cairo',
                    ),
                  ),
                ),
              ]),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                _buildInfoChip(
                  icon: Icons.calendar_today,
                  text: req.formattedDate,
                  baseFontSize: baseFontSize,
                  isDark: isDark,
                ),
                const SizedBox(width: 12),
                _buildInfoChip(
                  icon: Icons.access_time,
                  text: req.formattedTime,
                  baseFontSize: baseFontSize,
                  isDark: isDark,
                ),
              ],
            ),
            if (req.description.isNotEmpty &&
                req.description != 'No details') ...[
              const SizedBox(height: 12),
              Text(
                req.description,
                style: TextStyle(
                  fontSize: baseFontSize * 0.875,
                  color: isDark ? Colors.grey[200] : Colors.grey[800],
                  fontFamily: 'Cairo',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String text,
    required double baseFontSize,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: ColorsManager.mainBlue),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: baseFontSize * 0.75,
              color: isDark ? Colors.grey[200] : Colors.grey[800],
              fontFamily: 'Cairo',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(double baseFontSize, double width) {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: 50 * (width / 390)),
            Icon(
              Icons.calendar_today_outlined,
              size: 64 * (width / 390),
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'لا توجد طلبات حالية',
              style: TextStyle(
                fontSize: baseFontSize * 1.125,
                color: Colors.grey[600],
                fontFamily: 'Cairo',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(double baseFontSize) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 56,
            color: Colors.redAccent,
          ),
          const SizedBox(height: 12),
          Text(
            _error ?? 'حدث خطأ غير متوقع',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Cairo',
              color: Colors.redAccent,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadRequests,
            icon: const Icon(Icons.refresh),
            label: const Text(
              'إعادة المحاولة',
              style: TextStyle(fontFamily: 'Cairo'),
            ),
          ),
        ],
      ),
    );
  }
}

