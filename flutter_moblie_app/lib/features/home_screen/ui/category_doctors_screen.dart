import 'package:flutter/material.dart';

import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:thotha_mobile_app/core/di/dependency_injection.dart';
import 'package:thotha_mobile_app/core/helpers/shared_pref_helper.dart';
import 'package:thotha_mobile_app/core/networking/api_service.dart';
import 'package:thotha_mobile_app/core/theming/colors.dart';
import 'package:thotha_mobile_app/features/booking/ui/booking_confirmation_screen.dart';
import 'package:thotha_mobile_app/features/home_screen/data/models/case_request_model.dart';
import 'package:thotha_mobile_app/features/home_screen/data/repositories/case_request_repo.dart';
import 'package:thotha_mobile_app/features/home_screen/doctor_home/ui/add_case_request_screen.dart';
import 'package:thotha_mobile_app/core/helpers/constants.dart';

class CategoryDoctorsScreen extends StatefulWidget {
  final String categoryName;
  final int? categoryId;
  final int? cityId;
  final String? cityName;
  final bool showAddCaseButton;

  const CategoryDoctorsScreen({
    super.key,
    required this.categoryName,
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
    _checkLoginStatus();
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
      } else if (widget.categoryName.isNotEmpty) {
        print('Using CategoryName (public fallback): ${widget.categoryName}');
        result = await _repo.getAllRequests();
      } else {
        result = {'success': false, 'error': 'لم يتم تحديد التخصص'};
      }
    }

    if (!mounted) return;

    print('API Result Success: ${result['success']}');
    print('API Result Error: ${result['error']}');
    print('API Result Status Code: ${result['statusCode']}');

    if (result['success'] == true) {
      var all = List<CaseRequestModel>.from(result['data'] as List);
      print('Total requests loaded (raw): ${all.length}');

      // إذا كان دكتور مسجّل دخولًا، ما زلنا نلتزم بالتخصص/المدينة المختارة في الشاشة
      if (widget.categoryName.isNotEmpty) {
        print('Filtering by category name: ${widget.categoryName}');
        all = all
            .where((r) =>
                r.categoryName.toLowerCase() ==
                widget.categoryName.toLowerCase())
            .toList();
        print('Requests after category filter: ${all.length}');
      }

      if (widget.cityName != null && widget.cityName!.isNotEmpty) {
        all = all
            .where((r) => r.doctorCityName == widget.cityName)
            .toList();
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
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;
    final baseFontSize = width * 0.04;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.categoryName,
          style: TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.w700,
            fontSize: baseFontSize * 1.125,
          ),
        ),
        centerTitle: true,
      ),
      floatingActionButton: (widget.showAddCaseButton && _isDoctorLoggedIn)
          ? FloatingActionButton.extended(
              onPressed: () => _updateCategoryAndNavigate(),
              label: const Text(
                'نشر حالة جديدة',
                style:
                    TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
              ),
              icon: const Icon(Icons.add_task_rounded, color: Colors.white),
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
                        _buildError(baseFontSize),
                      ],
                    )
                  : _requests.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            SizedBox(height: height * 0.2),
                            _buildEmpty(baseFontSize, width),
                          ],
                        )
                      : ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: EdgeInsets.fromLTRB(
                            width * 0.04,
                            16,
                            width * 0.04,
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
                                width,
                                baseFontSize,
                                isDark,
                                theme,
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
    double width,
    double baseFontSize,
    bool isDark,
    ThemeData theme,
    bool isLoggedIn,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(
          color: isDark ? Colors.grey[700]! : const Color(0xFFE5E7EB),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row: categoryName + id badge + delete (when logged in)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    req.categoryName,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: baseFontSize * 1.05,
                      fontWeight: FontWeight.w700,
                      color: ColorsManager.mainBlue,
                    ),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (req.id != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: ColorsManager.mainBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '#${req.id}',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: baseFontSize * 0.72,
                            fontWeight: FontWeight.bold,
                            color: ColorsManager.mainBlue,
                          ),
                        ),
                      ),
                    if (isLoggedIn) ...[
                      const SizedBox(width: 8),
                      Material(
                        color: Colors.red.withOpacity(0.08),
                        shape: const CircleBorder(),
                        child: IconButton(
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            color: Colors.red,
                            size: 20,
                          ),
                          tooltip: 'حذف الطلب',
                          onPressed: () => _deleteRequest(req),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),

            // Doctor name
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.person_outline, size: 15, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    req.doctorFullName,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: baseFontSize * 0.88,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.grey[200] : Colors.grey[800],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            // City · University
            if (req.doctorCityName.isNotEmpty ||
                req.doctorUniversityName.isNotEmpty) ...[
              const SizedBox(height: 5),
              Row(
                children: [
                  Icon(Icons.location_on_outlined,
                      size: 15, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      [req.doctorCityName, req.doctorUniversityName]
                          .where((s) => s.isNotEmpty)
                          .join(' · '),
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: baseFontSize * 0.82,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],

            // Phone
            if (req.doctorPhoneNumber.isNotEmpty) ...[
              const SizedBox(height: 5),
              Row(
                children: [
                  Icon(Icons.phone_outlined, size: 15, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    req.doctorPhoneNumber,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: baseFontSize * 0.82,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],

            // Description
            if (req.description.isNotEmpty &&
                req.description != 'No details') ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[850] : const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  req.description,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: baseFontSize * 0.85,
                    color: isDark ? Colors.grey[200] : Colors.grey[800],
                    height: 1.5,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // Date and time chips + Book Now (for Guest)
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      _buildChip(
                        icon: Icons.calendar_today_outlined,
                        text: req.formattedDate,
                        baseFontSize: baseFontSize,
                        isDark: isDark,
                      ),
                      const SizedBox(width: 10),
                      if (req.formattedTime.isNotEmpty)
                        _buildChip(
                          icon: Icons.access_time_outlined,
                          text: req.formattedTime,
                          baseFontSize: baseFontSize,
                          isDark: isDark,
                        ),
                    ],
                  ),
                ),
                if (!isLoggedIn)
                  SizedBox(
                    height: 36.h,
                    child: ElevatedButton(
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
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColorsManager.mainBlue,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'احجز الآن',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 13.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip({
    required IconData icon,
    required String text,
    required double baseFontSize,
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
              fontSize: baseFontSize * 0.75,
              color: isDark ? Colors.grey[200] : Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(double baseFontSize, double width) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.assignment_outlined,
            size: 70 * (width / 390),
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'لا توجد حالات في هذا التخصص حالياً',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: baseFontSize * 0.95,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'كن أول من ينشر حالة!',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: baseFontSize * 0.85,
              color: ColorsManager.mainBlue,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(double baseFontSize) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded,
              size: 56, color: Colors.redAccent),
          const SizedBox(height: 12),
          Text(
            _error ?? 'حدث خطأ غير متوقع',
            textAlign: TextAlign.center,
            style:
                const TextStyle(fontFamily: 'Cairo', color: Colors.redAccent),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadRequests,
            icon: const Icon(Icons.refresh),
            label: const Text('إعادة المحاولة',
                style: TextStyle(fontFamily: 'Cairo')),
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
    final width = MediaQuery.of(context).size.width;
    final baseFontSize = width * 0.04;

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
                    fontSize: baseFontSize * 1.2,
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
                  isDark: isDark,
                  baseFontSize: baseFontSize),
              _DetailRow(
                  icon: Icons.person_outline,
                  label: 'الطبيب',
                  value: req.doctorFullName,
                  isDark: isDark,
                  baseFontSize: baseFontSize),
              _DetailRow(
                  icon: Icons.phone_outlined,
                  label: 'الهاتف',
                  value: req.doctorPhoneNumber,
                  isDark: isDark,
                  baseFontSize: baseFontSize),
              _DetailRow(
                  icon: Icons.location_city_outlined,
                  label: 'المدينة',
                  value: req.doctorCityName,
                  isDark: isDark,
                  baseFontSize: baseFontSize),
              _DetailRow(
                  icon: Icons.school_outlined,
                  label: 'الجامعة',
                  value: req.doctorUniversityName,
                  isDark: isDark,
                  baseFontSize: baseFontSize),
              _DetailRow(
                  icon: Icons.calendar_today_outlined,
                  label: 'التاريخ',
                  value: req.formattedDate,
                  isDark: isDark,
                  baseFontSize: baseFontSize),
              _DetailRow(
                  icon: Icons.access_time_outlined,
                  label: 'الوقت',
                  value: req.formattedTime,
                  isDark: isDark,
                  baseFontSize: baseFontSize),

              // ── Description ──
              if (req.description.isNotEmpty &&
                  req.description != 'No details') ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[850] : const Color(0xFFF9FAFB),
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
                      fontSize: baseFontSize * 0.9,
                      color: isDark ? Colors.grey[200] : Colors.grey[800],
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
                        color: Colors.white),
                    label: Text(
                      'احجز الآن',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: baseFontSize * 1.05,
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
  final double baseFontSize;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
    required this.baseFontSize,
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
              fontSize: baseFontSize * 0.88,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.grey[300] : Colors.grey[700],
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: baseFontSize * 0.88,
                color: isDark ? Colors.grey[100] : Colors.grey[900],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
