import 'package:flutter/material.dart';
import 'package:thotha_mobile_app/core/di/dependency_injection.dart';
import 'package:thotha_mobile_app/core/helpers/shared_pref_helper.dart';
import 'package:thotha_mobile_app/core/networking/api_service.dart';
import 'package:thotha_mobile_app/core/theming/colors.dart';
import 'package:thotha_mobile_app/features/home_screen/data/models/case_request_model.dart';
import 'package:thotha_mobile_app/features/home_screen/data/repositories/case_request_repo.dart';
import 'package:thotha_mobile_app/features/home_screen/doctor_home/ui/add_case_request_screen.dart';

class CategoryDoctorsScreen extends StatefulWidget {
  final String categoryName;
  final int? categoryId;
  final int? cityId;
  final String? cityName;

  const CategoryDoctorsScreen({
    super.key,
    required this.categoryName,
    this.categoryId,
    this.cityId,
    this.cityName,
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

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    Map<String, dynamic> result;
    if (widget.categoryId != null) {
      result = await _repo.getRequestsByCategoryId(widget.categoryId!);
    } else {
      result = {'success': false, 'error': 'لم يتم تحديد التخصص'};
    }

    if (!mounted) return;

    if (result['success'] == true) {
      setState(() {
        _requests = List<CaseRequestModel>.from(result['data'] as List);
        _isLoading = false;
      });
    } else {
      setState(() {
        _error = result['error']?.toString() ?? 'فشل في تحميل الحالات';
        _isLoading = false;
      });
    }
  }

  /// Updates the doctor's categoryName to the current category then opens
  /// the AddCaseRequestScreen. All other doctor fields are kept as-is.
  Future<void> _updateCategoryAndNavigate() async {
    // Load all doctor info from SharedPreferences
    int doctorId = await SharedPrefHelper.getInt('doctor_id');
    if (doctorId == 0) {
      final idStr = await SharedPrefHelper.getString('doctor_id');
      doctorId = int.tryParse(idStr ?? '') ?? 0;
    }

    final firstName = await SharedPrefHelper.getString('first_name') ?? '';
    final lastName  = await SharedPrefHelper.getString('last_name')  ?? '';
    final phone     = await SharedPrefHelper.getString('phone')      ?? '';
    final faculty   = await SharedPrefHelper.getString('faculty')    ?? '';
    final year      = await SharedPrefHelper.getString('year')       ?? '';
    final governorate = await SharedPrefHelper.getString('governorate') ?? '';

    final body = <String, dynamic>{
      if (doctorId != 0)     'id':             doctorId,
      if (firstName.isNotEmpty) 'firstName':   firstName,
      if (lastName.isNotEmpty)  'lastName':    lastName,
      if (phone.isNotEmpty)     'phoneNumber': phone,
      if (year.isNotEmpty)      'studyYear':   year,
      if (faculty.isNotEmpty)   'universityName': faculty,
      if (governorate.isNotEmpty) 'cityName':  governorate,
      'categoryName': widget.categoryName,
    };

    final result = await _apiService.updateDoctor(body);

    if (result['success'] == true) {
      // Update cached category in SharedPreferences
      await SharedPrefHelper.setData('category', widget.categoryName);
    } else {
      // Silently continue even on failure – don't block navigation
      debugPrint('updateDoctor failed: ${result['error']}');
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

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _updateCategoryAndNavigate(),
        label: const Text(
          'نشر حالة جديدة',
          style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
        ),
        icon: const Icon(Icons.add_task_rounded, color: Colors.white),
        backgroundColor: ColorsManager.mainBlue,
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
                        child: ListView.separated(
                          padding: EdgeInsets.fromLTRB(
                            width * 0.04,
                            16,
                            width * 0.04,
                            100, // space for FAB
                          ),
                          itemCount: _requests.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            return _buildRequestCard(
                              context,
                              _requests[index],
                              width,
                              baseFontSize,
                              isDark,
                              theme,
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
  ) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
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
            // Header row: specialization + id badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    req.specialization,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: baseFontSize * 1.05,
                      fontWeight: FontWeight.w700,
                      color: ColorsManager.mainBlue,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: ColorsManager.mainBlue.withValues(alpha: 0.1),
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
              ],
            ),

            // Location
            if (req.location.isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.location_on_outlined, size: 15, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      req.location,
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

            // Description
            if (req.description.isNotEmpty && req.description != 'No details') ...[
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
            const SizedBox(height: 10),

            // Date and time chips
            Row(
              children: [
                _buildChip(
                  icon: Icons.calendar_today_outlined,
                  text: req.date,
                  baseFontSize: baseFontSize,
                  isDark: isDark,
                ),
                const SizedBox(width: 10),
                _buildChip(
                  icon: Icons.access_time_outlined,
                  text: req.time,
                  baseFontSize: baseFontSize,
                  isDark: isDark,
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
          const Icon(Icons.error_outline_rounded, size: 56, color: Colors.redAccent),
          const SizedBox(height: 12),
          Text(
            _error ?? 'حدث خطأ غير متوقع',
            textAlign: TextAlign.center,
            style: const TextStyle(fontFamily: 'Cairo', color: Colors.redAccent),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadRequests,
            icon: const Icon(Icons.refresh),
            label: const Text('إعادة المحاولة', style: TextStyle(fontFamily: 'Cairo')),
            style: ElevatedButton.styleFrom(backgroundColor: ColorsManager.mainBlue),
          ),
        ],
      ),
    );
  }
}
