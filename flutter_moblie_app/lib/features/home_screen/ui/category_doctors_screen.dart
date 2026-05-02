import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:thoutha_mobile_app/core/di/dependency_injection.dart';
import 'package:thoutha_mobile_app/core/helpers/shared_pref_helper.dart';
import 'package:thoutha_mobile_app/core/networking/api_service.dart';
import 'package:thoutha_mobile_app/core/theming/colors.dart';
import 'package:thoutha_mobile_app/features/booking/ui/booking_confirmation_screen.dart';
import 'package:thoutha_mobile_app/features/requests/data/models/case_request_model.dart';
import 'package:thoutha_mobile_app/features/requests/data/repos/case_request_repo.dart';
import 'package:thoutha_mobile_app/features/requests/ui/add_case_request_screen.dart';
import 'package:thoutha_mobile_app/core/helpers/constants.dart';

class CategoryDoctorsScreen extends StatefulWidget {
  final String categoryName;
  final String? categorySvg;
  final int? categoryId;
  final int? cityId;
  final String? cityName;
  final bool showAddCaseButton;

  const CategoryDoctorsScreen({
    super.key,
    required this.categoryName,
    this.categorySvg,
    this.categoryId,
    this.cityId,
    this.cityName,
    this.showAddCaseButton = false,
  });

  @override
  State<CategoryDoctorsScreen> createState() => _CategoryDoctorsScreenState();
}

class _CategoryDoctorsScreenState extends State<CategoryDoctorsScreen> {
  final CaseRequestRepo _repo = getIt<CaseRequestRepo>();
  final ApiService _apiService = ApiService();

  List<CaseRequestModel> _requests = [];
  bool _isLoading = false;
  String? _error;
  bool _isDoctorLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _checkLoginStatus();
    _loadRequests();
  }

  Future<void> _checkLoginStatus() async {
    try {
      final token =
          await SharedPrefHelper.getSecuredString(SharedPrefKeys.userToken);

      // If we have a token, we are logged in.
      // If we were also told to show the add button, we treat the user as a doctor.
      final isLoggedIn = token.isNotEmpty && token != 'null';

      if (mounted) {
        setState(() {
          _isDoctorLoggedIn = isLoggedIn && widget.showAddCaseButton;
        });
      }
    } catch (e) {
      debugPrint('Error in _checkLoginStatus: $e');
    }
  }

  Future<void> _loadRequests() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    Map<String, dynamic> result;

    print('=== Loading Requests ===');
    print('CategoryId: ${widget.categoryId}');
    print('CategoryName: ${widget.categoryName}');

    // إذا كان المستخدم دكتور مسجّل دخولًا، اعرض فقط الطلبات الخاصة به
    if (_isDoctorLoggedIn) {
      print('Loading requests for current doctor only.');
      result = await _repo.getRequestsByDoctorId();
    } else {
      // زائر/مريض: استخدم منطق الكاتيجوري القديم
      if (widget.categoryId != null) {
        print('Using CategoryId (public): ${widget.categoryId}');
        result = await _repo.getRequestsByCategoryId(widget.categoryId!);
      } else {
        result = {'success': false, 'error': 'لم يتم تحديد التخصّص بشكل صحيح'};
      }
    }

    if (!mounted) return;

    print('API Result Success: ${result['success']}');
    print('API Result Error: ${result['error']}');
    print('API Result Status Code: ${result['statusCode']}');

    if (result['success'] == true) {
      var all = List<CaseRequestModel>.from(result['data'] as List);
      print('Total requests loaded (raw): ${all.length}');

      // Apply name filter only if categoryId is NOT provided (fallback)
      // If categoryId is provided, the API result is already category-specific.
      if (widget.categoryId == null && widget.categoryName.isNotEmpty) {
        print('Filtering by category name (fallback): ${widget.categoryName}');
        all = all
            .where((r) =>
                r.categoryName.toLowerCase() ==
                widget.categoryName.toLowerCase())
            .toList();
        print('Requests after name filter: ${all.length}');
      }

      if (widget.cityName != null && widget.cityName!.isNotEmpty) {
        all = all.where((r) => r.doctorCityName == widget.cityName).toList();
        print('Requests after city filter: ${all.length}');
      }

      setState(() {
        _requests = all;
        _isLoading = false;
      });
    } else {
      final errorMsg = result['error']?.toString() ?? 'فشل في تحميل الحالات';
      print('Error occurred: $errorMsg');
      setState(() {
        _error = errorMsg;
        _isLoading = false;
      });
    }
  }

  /// Updates the doctor's categoryName to the current category then opens
  /// the AddCaseRequestScreen. All other doctor fields are kept as-is.
  Future<void> _updateCategoryAndNavigate() async {
    // Show loading indicator while calling the API
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );
    }

    // Load all doctor info from SharedPreferences
    final firstName = await SharedPrefHelper.getString('first_name');
    final lastName = await SharedPrefHelper.getString('last_name');
    final phone = await SharedPrefHelper.getString('phone');
    final faculty = await SharedPrefHelper.getString('faculty');
    final yearString = await SharedPrefHelper.getString('year');
    final governorate = await SharedPrefHelper.getString('governorate');

    // studyYear must be an integer per the API contract
    final dynamic studyYear =
        int.tryParse(yearString) ?? (yearString.isNotEmpty ? yearString : null);

    final body = <String, dynamic>{
      if (firstName.isNotEmpty) 'firstName': firstName,
      if (lastName.isNotEmpty) 'lastName': lastName,
      if (phone.isNotEmpty) 'phoneNumber': phone,
      if (studyYear != null) 'studyYear': studyYear,
      if (faculty.isNotEmpty) 'universityName': faculty,
      if (governorate.isNotEmpty) 'cityName': governorate,
      'categoryName': widget.categoryName,
    };

    final result = await _apiService.updateDoctor(body);

    // Dismiss loading indicator
    if (mounted) Navigator.of(context, rootNavigator: true).pop();

    if (result['success'] == true) {
      await SharedPrefHelper.setData('category', widget.categoryName);
    } else {
      debugPrint('updateDoctor failed: ${result['error']}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result['error']?.toString() ?? 'فشل في تحديث التخصص',
              style: const TextStyle(fontFamily: 'Cairo'),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddCaseRequestScreen(
          initialSpecialization: widget.categoryName,
        ),
      ),
    ).then((_) => _loadRequests());
  }

  /// Asks for confirmation then deletes [req] via the authenticated API.
  Future<void> _deleteRequest(CaseRequestModel req) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                style: TextStyle(fontFamily: 'Cairo', color: Colors.grey),
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
                style: TextStyle(fontFamily: 'Cairo', color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true || !mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final result = await _repo.deleteRequest(req.id ?? 0);

    if (!mounted) return;
    Navigator.pop(context); // dismiss loading overlay

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'تم حذف الطلب بنجاح',
            textAlign: TextAlign.right,
            style: const TextStyle(fontFamily: 'Cairo'),
          ),
          backgroundColor: Colors.green,
        ),
      );
      // Automatically refresh the list from server to ensure accuracy
      _loadRequests();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result['error']?.toString() ?? 'فشل في حذف الطلب',
            style: const TextStyle(fontFamily: 'Cairo'),
          ),
          backgroundColor: Colors.red[700],
        ),
      );
    }
  }

  /// Opens a bottom sheet with full case details + Book Now button.
  void _showCaseDetails(CaseRequestModel req) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CaseDetailsSheet(
        req: req,
        // doctor (logged-in) sees delete icon → no Book Now
        // patient/guest sees Book Now → no delete icon
        showBookNow: !_isDoctorLoggedIn,
        onBookNow: () {
          Navigator.pop(context); // close sheet
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BookingConfirmationScreen(
                doctorName: req.doctorFullName,
                date: req.formattedDate,
                time: req.formattedTime,
                specialty: req.categoryName,
                requestId: req.id,
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.categoryName,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
            if (widget.categorySvg != null) ...[
              const SizedBox(width: 10),
              widget.categorySvg!.endsWith('.svg')
                  ? SvgPicture.asset(
                      widget.categorySvg!,
                      width: 28,
                      height: 28,
                    )
                  : Image.asset(
                      widget.categorySvg!,
                      width: 28,
                      height: 28,
                    ),
            ],
          ],
        ),
        centerTitle: true,
      ),
      floatingActionButton: (widget.showAddCaseButton && _isDoctorLoggedIn)
          ? FloatingActionButton.extended(
              onPressed: () => _updateCategoryAndNavigate(),
              label: const Text(
                'نشر حالة جديدة',
                style: TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.bold,
                    fontSize: 14),
              ),
              icon:
                  const Icon(Icons.add_task_rounded, color: Colors.white, size: 24),
              backgroundColor: ColorsManager.mainBlue,
            )
          : null,
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: RefreshIndicator(
          onRefresh: _loadRequests,
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(height: height * 0.2),
                        _buildError(),
                      ],
                    )
                  : _requests.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            SizedBox(height: height * 0.2),
                            _buildEmpty(),
                          ],
                        )
                      : ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(
                            16,
                            16,
                            16,
                            100, // space for FAB
                          ),
                          itemCount: _requests.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 16),
                          itemBuilder: (context, index) {
                            return GestureDetector(
                              onTap: () => _showCaseDetails(_requests[index]),
                              child: _buildRequestCard(
                                context,
                                _requests[index],
                                isDark,
                                _isDoctorLoggedIn,
                              ),
                            );
                          },
                        ),
        ),
      ),
    );
  }

  Widget _buildRequestCard(
    BuildContext context,
    CaseRequestModel req,
    bool isDark,
    bool isLoggedIn,
  ) {
    final theme = Theme.of(context);
    final String initial = req.doctorFullName.replaceFirst(RegExp(r'^د\.\s*'), '').isNotEmpty 
        ? req.doctorFullName.replaceFirst(RegExp(r'^د\.\s*'), '')[0] 
        : '';

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Upper section with colored background and doctor info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  ColorsManager.layerBlur2.withValues(alpha: 0.3),
                  ColorsManager.layerBlur1.withValues(alpha: 0.2),
                ],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Doctor Name and Category (Now on the Right in RTL)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            req.doctorFullName,
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: ColorsManager.fontColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Available Now Badge (Now on the Left in RTL)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      PulsingDot(color: Colors.green),
                      const SizedBox(width: 6),
                      Text(
                        'متاح الآن',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Main Content Section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Info Grid (2x2)
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoBox(
                        label: 'الجامعة',
                        value: req.doctorUniversityName,
                        icon: Icons.home_work_outlined,
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildInfoBox(
                        label: 'المحافظة',
                        value: req.doctorCityName,
                        icon: Icons.location_on,
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoBox(
                        label: 'اليوم',
                        value: req.formattedDate,
                        icon: Icons.calendar_today,
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildInfoBox(
                        label: 'الساعة',
                        value: req.formattedTime,
                        icon: Icons.access_time_filled,
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),

                if (req.description.isNotEmpty && req.description != 'No details') ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[900] : ColorsManager.moreLighterGray,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? Colors.white24 : Colors.black.withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.info_outline, size: 18, color: Colors.blue),
                            const SizedBox(width: 8),
                            Text(
                              'تفاصيل الحالة',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.blue[300] : Colors.blue[800],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          req.description,
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 13,
                            height: 1.5,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                // Book Now Button
                if (!isLoggedIn)
                  Container(
                    width: double.infinity,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [ColorsManager.mainBlue, Color(0xFF42A5F5)],
                        begin: Alignment.centerRight,
                        end: Alignment.centerLeft,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: ColorsManager.mainBlue.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BookingConfirmationScreen(
                              doctorName: req.doctorFullName,
                              date: req.formattedDate,
                              time: req.formattedTime,
                              specialty: req.categoryName,
                              requestId: req.id,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.calendar_month, color: Colors.white, size: 20),
                      label: const Text(
                        'حجز موعد',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBox({
    required String label,
    required String value,
    required IconData icon,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : ColorsManager.offWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: ColorsManager.mainBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: ColorsManager.mainBlue),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 11,
                    color: isDark ? Colors.white : Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  value.isEmpty ? 'غير محدد' : value,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 11,
                    color: isDark ? Colors.white : ColorsManager.fontColor,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.end,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildChip({
    required IconData icon,
    required String text,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: ColorsManager.mainBlue),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 12,
              color: isDark ? Colors.white : Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.assignment_outlined,
            size: 70,
            color: isDark ? Colors.white30 : Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'لا توجد حالات في هذا التخصص حالياً',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 16,
              color: isDark ? Colors.white70 : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline_rounded,
              size: 56, color: Colors.redAccent),
          const SizedBox(height: 12),
          Text(
            _error ?? 'حدث خطأ غير متوقع',
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontFamily: 'Cairo', color: Colors.redAccent, fontSize: 14),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadRequests,
            icon: const Icon(Icons.refresh, size: 20),
            label: const Text('إعادة المحاولة',
                style: TextStyle(fontFamily: 'Cairo', fontSize: 14)),
            style: ElevatedButton.styleFrom(
                backgroundColor: ColorsManager.mainBlue),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _CaseDetailsSheet — Bottom sheet with full case details + Book Now button
// ─────────────────────────────────────────────────────────────────────────────
class _CaseDetailsSheet extends StatelessWidget {
  final CaseRequestModel req;
  final VoidCallback onBookNow;
  final bool showBookNow;

  const _CaseDetailsSheet({
    required this.req,
    required this.onBookNow,
    this.showBookNow = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
          20, 12, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: SingleChildScrollView(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Drag handle ──
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),

              // ── Title ──
              Center(
                child: Text(
                  'تفاصيل الحالة',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Divider(color: isDark ? Colors.grey[700] : Colors.grey[200]),
              const SizedBox(height: 8),

              // ── Details rows ──
              _DetailRow(
                  icon: Icons.medical_services_outlined,
                  label: 'التخصص',
                  value: req.categoryName,
                  isDark: isDark),
              _DetailRow(
                  icon: Icons.person_outline,
                  label: 'الطبيب',
                  value: req.doctorFullName,
                  isDark: isDark),
              _DetailRow(
                  icon: Icons.location_city_outlined,
                  label: 'المدينة',
                  value: req.doctorCityName,
                  isDark: isDark),
              _DetailRow(
                  icon: Icons.school_outlined,
                  label: 'الجامعة',
                  value: req.doctorUniversityName,
                  isDark: isDark),
              _DetailRow(
                  icon: Icons.calendar_today_outlined,
                  label: 'التاريخ',
                  value: req.formattedDate,
                  isDark: isDark),
              _DetailRow(
                  icon: Icons.access_time_outlined,
                  label: 'الوقت',
                  value: req.formattedTime,
                  isDark: isDark),

              // ── Description ──
              if (req.description.isNotEmpty &&
                  req.description != 'No details') ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[900] : ColorsManager.moreLighterGray,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: isDark
                            ? Colors.grey[700]!
                            : const Color(0xFFE5E7EB)),
                  ),
                  child: Text(
                    req.description,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 14,
                      color: isDark ? Colors.white : Colors.grey[800],
                      height: 1.6,
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // ── Book Now button ──
              if (showBookNow)
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: onBookNow,
                    icon: const Icon(Icons.calendar_month_rounded,
                        color: Colors.white, size: 24),
                    label: const Text(
                      'احجز الآن',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorsManager.mainBlue,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 2,
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

// ─────────────────────────────────────────────────────────────────────────────
// _DetailRow — single info row in the bottom sheet
// ─────────────────────────────────────────────────────────────────────────────
class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isDark;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: ColorsManager.mainBlue),
          const SizedBox(width: 10),
          Text(
            '$label: ',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white.withOpacity(0.9) : Colors.grey[700],
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 14,
                color: isDark ? Colors.white : Colors.grey[900],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
class PulsingDot extends StatefulWidget {
  final Color color;
  const PulsingDot({super.key, required this.color});

  @override
  State<PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<PulsingDot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color.withValues(alpha: _animation.value),
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: _animation.value * 0.5),
                blurRadius: 4,
                spreadRadius: 2 * _animation.value,
              ),
            ],
          ),
        );
      },
    );
  }
}
