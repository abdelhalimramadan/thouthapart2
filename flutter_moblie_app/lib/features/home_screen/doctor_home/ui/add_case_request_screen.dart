import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:intl/intl.dart';
import 'package:thotha_mobile_app/core/helpers/constants.dart';
import 'package:thotha_mobile_app/core/helpers/shared_pref_helper.dart';
import 'package:thotha_mobile_app/core/routing/routes.dart';
import 'package:thotha_mobile_app/core/theming/colors.dart';
import 'package:thotha_mobile_app/core/theming/styles.dart';
import 'package:thotha_mobile_app/core/widgets/app_text_button.dart';
import 'package:thotha_mobile_app/core/di/dependency_injection.dart';
import 'package:thotha_mobile_app/features/home_screen/data/models/case_request_body.dart';
import 'package:thotha_mobile_app/features/home_screen/data/models/case_request_model.dart';
import 'package:thotha_mobile_app/features/home_screen/data/repositories/case_request_repo.dart';

class AddCaseRequestScreen extends StatefulWidget {
  final String? initialSpecialization;
  final CaseRequestModel? requestToEdit;
  const AddCaseRequestScreen({
    super.key,
    this.initialSpecialization,
    this.requestToEdit,
  });

  @override
  State<AddCaseRequestScreen> createState() => _AddCaseRequestScreenState();
}

class _AddCaseRequestScreenState extends State<AddCaseRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _descriptionController = TextEditingController();

  // Doctor info loaded from SharedPreferences
  String _firstName = '';
  String _lastName = '';
  String _category = '';
  bool _isLoadingInfo = true;

  // Selected date & time
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  // Edit mode flag
  bool get _isEditMode => widget.requestToEdit != null;

  @override
  void initState() {
    super.initState();
    _loadDoctorInfo();
    if (_isEditMode) {
      _prefillFormForEditing();
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  /// If editing, pre-fill the form with the request's data
  void _prefillFormForEditing() {
    final req = widget.requestToEdit;
    if (req != null) {
      _descriptionController.text = req.description;
      try {
        final dt = DateTime.parse(req.dateTime);
        _selectedDate = DateTime(dt.year, dt.month, dt.day);
        _selectedTime = TimeOfDay(hour: dt.hour, minute: dt.minute);
      } catch (_) {
        // If parsing fails, keep dates as null
      }
    }
  }

  Future<void> _loadDoctorInfo() async {
    final firstName = await SharedPrefHelper.getString('first_name') ?? '';
    final lastName = await SharedPrefHelper.getString('last_name') ?? '';
    final category = await SharedPrefHelper.getString('category') ?? '';

    // fallback to initialSpecialization if SharedPref empty
    if (mounted) {
      setState(() {
        _firstName = firstName;
        _lastName = lastName;
        _category = category.isNotEmpty
            ? category
            : (widget.initialSpecialization ?? '');
        _isLoadingInfo = false;
      });
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  String get _formattedDate => _selectedDate != null
      ? DateFormat('yyyy-MM-dd').format(_selectedDate!)
      : '';

  String get _formattedTime => _selectedTime != null
      ? '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}'
      : '';

  /// Builds "2026-03-10T15:30:00" format
  String get _dateTimeIso {
    if (_selectedDate == null || _selectedTime == null) return '';
    return '${_formattedDate}T${_formattedTime}:00';
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(2101),
      locale: const Locale('ar', 'EG'),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (ctx, child) => Localizations.override(
        context: ctx,
        locale: const Locale('ar', 'EG'),
        child: child,
      ),
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  // ── Publish ───────────────────────────────────────────────────────────────

  Future<void> _publishRequest() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى اختيار التاريخ والوقت',
              style: TextStyle(fontFamily: 'Cairo')),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final token =
        await SharedPrefHelper.getSecuredString(SharedPrefKeys.userToken);
    if (token.isEmpty) {
      _showLoginDialog();
      return;
    }

    try {
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => const Center(child: CircularProgressIndicator()),
        );
      }

      final body = CaseRequestBody(
        description: _descriptionController.text.trim().isEmpty
            ? 'لا توجد تفاصيل إضافية'
            : _descriptionController.text.trim(),
        dateTime: _dateTimeIso,
      );

      final repo = getIt<CaseRequestRepo>();
      final result = _isEditMode
          ? await repo.updateCaseRequest(widget.requestToEdit!.id ?? 0, body)
          : await repo.createCaseRequest(body);

      if (mounted) Navigator.pop(context);

      if (result['success'] == true) {
        if (mounted) {
          final message =
              _isEditMode ? 'تم تحديث الطلب بنجاح!' : 'تم نشر الطلب بنجاح!';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text(message, style: const TextStyle(fontFamily: 'Cairo')),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['error'] ?? 'فشل في معالجة الطلب',
                  style: const TextStyle(fontFamily: 'Cairo')),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (_) {
      if (mounted) Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('حدث خطأ غير متوقع',
                style: TextStyle(fontFamily: 'Cairo')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showLoginDialog() {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: ui.TextDirection.rtl,
        child: AlertDialog(
          title:
              Text('تسجيل الدخول مطلوب', style: TextStyles.font18DarkBlueBold),
          content: Text(
            'يجب عليك تسجيل الدخول أولاً لتتمكن من نشر طلب حالة.',
            style: TextStyles.font14GrayRegular,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text('إلغاء', style: TextStyles.font14GrayRegular),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).pushNamed(Routes.loginScreen);
              },
              child: Text('تسجيل الدخول', style: TextStyles.font14BlueSemiBold),
            ),
          ],
        ),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final baseFontSize = width * 0.04;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditMode ? 'تعديل الطلب' : 'إضافة طلب حالة',
          style: TextStyles.font18DarkBlueBold.copyWith(
            fontFamily: 'Cairo',
            fontSize: baseFontSize * 1.125,
            color: isDark ? Colors.white : null,
          ),
        ),
        centerTitle: true,
        backgroundColor: isDark ? const Color(0xFF2D2D2D) : Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(
            color: isDark ? Colors.white : ColorsManager.darkBlue),
      ),
      backgroundColor:
          isDark ? const Color(0xFF1E1E1E) : ColorsManager.offWhite,
      body: SafeArea(
        child: Directionality(
          textDirection: ui.TextDirection.rtl,
          child: SingleChildScrollView(
            padding: EdgeInsets.all(width * 0.06),
            child: Form(
              key: _formKey,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                    maxWidth: width >= 600 ? 500 : double.infinity),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Header ────────────────────────────────────────
                    Text(
                      'بيانات الحالة',
                      style: TextStyles.font18DarkBlueBold.copyWith(
                        fontFamily: 'Cairo',
                        fontSize: baseFontSize * 1.125,
                        color: isDark ? Colors.white : null,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'قم بملء البيانات التالية لنشر طلب حالة جديد',
                      style: TextStyles.font14GrayRegular.copyWith(
                        fontFamily: 'Cairo',
                        fontSize: baseFontSize * 0.875,
                        color: isDark ? Colors.grey[400] : null,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── Doctor Info Card (auto-filled) ────────────────
                    _buildInfoCard(isDark, baseFontSize),
                    const SizedBox(height: 24),

                    // ── DateTime picker ───────────────────────────────
                    _buildLabel('التاريخ والوقت', baseFontSize, isDark),
                    const SizedBox(height: 8),
                    _buildDateTimePicker(isDark, baseFontSize, width),
                    const SizedBox(height: 20),

                    // ── Description ───────────────────────────────────
                    _buildLabel('وصف الحالة (اختياري)', baseFontSize, isDark),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 4,
                      maxLength: 500,
                      textDirection: ui.TextDirection.rtl,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        color: isDark ? Colors.white : Colors.black,
                      ),
                      decoration: _buildDecoration(
                        hint: 'أضف وصفاً تفصيلياً للحالة...',
                        icon: Icons.description_outlined,
                        isDark: isDark,
                        width: width,
                        baseFontSize: baseFontSize,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // ── Publish Button ────────────────────────────────
                    AppTextButton(
                      buttonText: _isEditMode ? 'تحديث الطلب' : 'نشر الطلب',
                      textStyle: TextStyles.font16WhiteSemiBold.copyWith(
                        fontFamily: 'Cairo',
                        fontSize: baseFontSize,
                      ),
                      backgroundColor: ColorsManager.mainBlue,
                      onPressed: _publishRequest,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Doctor Info Card ──────────────────────────────────────────────────────

  Widget _buildInfoCard(bool isDark, double baseFontSize) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2D2D2D) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey.shade700 : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: _isLoadingInfo
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildInfoRow(
                  icon: Icons.person_outline,
                  label: 'الاسم',
                  value: '$_firstName $_lastName',
                  isDark: isDark,
                  baseFontSize: baseFontSize,
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  icon: Icons.medical_services_outlined,
                  label: 'التخصص',
                  value: _category.isNotEmpty ? _category : 'غير محدد',
                  isDark: isDark,
                  baseFontSize: baseFontSize,
                ),
              ],
            ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
    required double baseFontSize,
  }) {
    return Row(
      children: [
        Icon(icon,
            color: isDark ? Colors.grey[400] : ColorsManager.mainBlue,
            size: 20),
        const SizedBox(width: 10),
        Text(
          '$label: ',
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: baseFontSize * 0.875,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: baseFontSize * 0.875,
              color: isDark ? Colors.white : Colors.black87,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // ── DateTime Picker ───────────────────────────────────────────────────────

  Widget _buildDateTimePicker(bool isDark, double baseFontSize, double width) {
    final hasDate = _selectedDate != null;
    final hasTime = _selectedTime != null;

    return Row(
      children: [
        // Date
        Expanded(
          child: GestureDetector(
            onTap: _pickDate,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF2D2D2D)
                    : ColorsManager.moreLighterGray,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color:
                      isDark ? Colors.grey.shade700 : ColorsManager.lighterGray,
                  width: 1.3,
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today_outlined,
                      size: 18,
                      color:
                          isDark ? Colors.grey[400] : ColorsManager.mainBlue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      hasDate ? _formattedDate : 'التاريخ',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: baseFontSize * 0.8,
                        color: hasDate
                            ? (isDark ? Colors.white : Colors.black87)
                            : Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Time
        Expanded(
          child: GestureDetector(
            onTap: _pickTime,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF2D2D2D)
                    : ColorsManager.moreLighterGray,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color:
                      isDark ? Colors.grey.shade700 : ColorsManager.lighterGray,
                  width: 1.3,
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.access_time_outlined,
                      size: 18,
                      color:
                          isDark ? Colors.grey[400] : ColorsManager.mainBlue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      hasTime ? _formattedTime : 'الوقت',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: baseFontSize * 0.8,
                        color: hasTime
                            ? (isDark ? Colors.white : Colors.black87)
                            : Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Widget _buildLabel(String label, double baseFontSize, bool isDark) {
    return Text(
      label,
      style: TextStyles.font14DarkBlueMedium.copyWith(
        fontFamily: 'Cairo',
        fontSize: baseFontSize * 0.875,
        color: isDark ? Colors.white : null,
      ),
    );
  }

  InputDecoration _buildDecoration({
    required String hint,
    required IconData icon,
    required bool isDark,
    required double width,
    required double baseFontSize,
  }) {
    return InputDecoration(
      isDense: true,
      contentPadding:
          EdgeInsets.symmetric(horizontal: width * 0.04, vertical: 16),
      hintText: hint,
      hintStyle: TextStyle(
        fontFamily: 'Cairo',
        fontSize: baseFontSize * 0.875,
        color: isDark ? Colors.grey[500] : Colors.grey[400],
      ),
      prefixIcon: Icon(icon,
          color: isDark ? Colors.grey[400] : ColorsManager.mainBlue, size: 22),
      fillColor:
          isDark ? const Color(0xFF2D2D2D) : ColorsManager.moreLighterGray,
      filled: true,
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(
            color: isDark ? Colors.grey.shade700 : ColorsManager.lighterGray,
            width: 1.3),
        borderRadius: BorderRadius.circular(16),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: ColorsManager.mainBlue, width: 1.3),
        borderRadius: BorderRadius.circular(16),
      ),
      errorBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.red, width: 1.3),
        borderRadius: BorderRadius.circular(16),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.red, width: 1.3),
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}
