import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:intl/intl.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:thoutha_mobile_app/core/di/dependency_injection.dart';

import 'package:thoutha_mobile_app/core/networking/api_service.dart';
import 'package:thoutha_mobile_app/core/theming/colors.dart';
import 'package:thoutha_mobile_app/core/theming/styles.dart';
import 'package:thoutha_mobile_app/core/widgets/app_text_button.dart';
import 'package:thoutha_mobile_app/features/requests/data/models/case_request_model.dart';

class EditRequestScreen extends StatefulWidget {
  final CaseRequestModel request;

  const EditRequestScreen({
    super.key,
    required this.request,
  });

  @override
  State<EditRequestScreen> createState() => _EditRequestScreenState();
}

class _EditRequestScreenState extends State<EditRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _descriptionController = TextEditingController();

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadRequestData();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  /// Load request data into form
  void _loadRequestData() {
    _descriptionController.text = widget.request.description;
    try {
      final dt = DateTime.parse(widget.request.dateTime);
      _selectedDate = DateTime(dt.year, dt.month, dt.day);
      _selectedTime = TimeOfDay(hour: dt.hour, minute: dt.minute);
    } catch (_) {
      // If parsing fails, keep dates as null
    }
  }

  // ── Getters ───────────────────────────────────────────────────────────────

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

  // ── Date & Time Pickers ───────────────────────────────────────────────────

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: now,
      lastDate: DateTime(2101),
      locale: const Locale('ar', 'EG'),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
      builder: (ctx, child) => Localizations.override(
        context: ctx,
        locale: const Locale('ar', 'EG'),
        child: child,
      ),
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  // ── Save Request ──────────────────────────────────────────────────────────

  Future<void> _saveRequest() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedDate == null || _selectedTime == null) {
      _showSnackBar(
        'يرجى اختيار التاريخ والوقت',
        Colors.orange,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final apiService = getIt<ApiService>();

      final description = _descriptionController.text.trim().isEmpty
          ? 'لا توجد تفاصيل إضافية'
          : _descriptionController.text.trim();

      final result = await apiService.editRequest(
        widget.request.id ?? 0,
        description,
        _dateTimeIso,
      );

      if (mounted) {
        if (result['success'] == true) {
          _showSnackBar(
            'تم تحديث الطلب بنجاح!',
            Colors.green,
          );

          // Wait a moment and then pop back
          await Future.delayed(const Duration(milliseconds: 500));
          if (mounted) {
            Navigator.pop(context, true); // Return true to indicate success
          }
        } else {
          _showSnackBar(
            result['error'] ?? 'فشل في تحديث الطلب',
            Colors.red,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar(
          'حدث خطأ غير متوقع: $e',
          Colors.red,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontFamily: 'Cairo'),
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, false);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'تعديل الطلب',
            style: TextStyles.font18DarkBlueBold.copyWith(
              fontFamily: 'Cairo',
              fontSize: 18.sp,
              color: isDark ? Colors.white : null,
            ),
          ),
          centerTitle: true,
          backgroundColor: isDark ? const Color(0xFF2D2D2D) : Colors.white,
          elevation: 0,
          iconTheme: IconThemeData(
            color: isDark ? Colors.white : ColorsManager.darkBlue,
            size: 24.r,
          ),
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded, size: 24.r),
            onPressed: () => Navigator.pop(context, false),
          ),
        ),
        backgroundColor:
            isDark ? const Color(0xFF1E1E1E) : ColorsManager.offWhite,
        body: SafeArea(
          child: Directionality(
            textDirection: ui.TextDirection.rtl,
            child: SingleChildScrollView(
              padding: EdgeInsets.all(24.r),
              child: Form(
                key: _formKey,
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: 500.w,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Header ───────────────────────────────────────
                        Text(
                          'تعديل بيانات الحالة',
                          style: TextStyles.font18DarkBlueBold.copyWith(
                            fontFamily: 'Cairo',
                            fontSize: 18.sp,
                            color: isDark ? Colors.white : null,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          'قم بتعديل البيانات التالية للطلب',
                          style: TextStyles.font14GrayRegular.copyWith(
                            fontFamily: 'Cairo',
                            color: isDark ? Colors.grey[400] : null,
                          ),
                        ),
                        SizedBox(height: 24.h),

                        // ── Request Info Card ────────────────────────────
                        _buildRequestInfoCard(isDark),
                        SizedBox(height: 24.h),

                        // ── DateTime Picker ──────────────────────────────
                        _buildLabel('التاريخ والوقت', isDark),
                        SizedBox(height: 8.h),
                        _buildDateTimePicker(isDark),
                        SizedBox(height: 20.h),

                        // ── Description ──────────────────────────────────
                        _buildLabel('وصف الحالة (اختياري)', isDark),
                        SizedBox(height: 8.h),
                        TextFormField(
                          controller: _descriptionController,
                          maxLines: 4,
                          maxLength: 500,
                          textDirection: ui.TextDirection.rtl,
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            color: isDark ? Colors.white : Colors.black,
                            fontSize: 14.sp,
                          ),
                          decoration: _buildDecoration(
                            hint: 'أضف وصفاً تفصيلياً للحالة...',
                            icon: Icons.description_outlined,
                            isDark: isDark,
                          ),
                        ),
                        SizedBox(height: 32.h),

                        // ── Save Button ──────────────────────────────────
                        _isLoading
                            ? Center(
                                child: CircularProgressIndicator(
                                  color: ColorsManager.mainBlue,
                                ),
                              )
                            : Column(
                                children: [
                                  AppTextButton(
                                    buttonText: 'حفظ التعديلات',
                                    textStyle:
                                        TextStyles.font16WhiteSemiBold.copyWith(
                                      fontFamily: 'Cairo',
                                      fontSize: 16.sp,
                                    ),
                                    backgroundColor: ColorsManager.mainBlue,
                                    onPressed: _saveRequest,
                                  ),
                                  SizedBox(height: 16.h),
                                  // ── Cancel Button ────────────────────────────────
                                  AppTextButton(
                                    buttonText: 'إلغاء',
                                    textStyle:
                                        TextStyles.font16WhiteSemiBold.copyWith(
                                      fontFamily: 'Cairo',
                                      fontSize: 16.sp,
                                      color: ColorsManager.mainBlue,
                                    ),
                                    backgroundColor: Colors.transparent,
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                  ),
                                ],
                              ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── UI Helpers ────────────────────────────────────────────────────────────

  Widget _buildRequestInfoCard(bool isDark) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2D2D2D) : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isDark ? Colors.grey.shade700 : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category
          _buildInfoRow(
            icon: Icons.medical_services_outlined,
            label: 'التخصص',
            value: widget.request.categoryName,
            isDark: isDark,
          ),
          SizedBox(height: 12.h),
          // Doctor Name
          _buildInfoRow(
            icon: Icons.person_outline,
            label: 'الطبيب',
            value: widget.request.doctorFullName,
            isDark: isDark,
          ),
          SizedBox(height: 12.h),
          // Request ID
          _buildInfoRow(
            icon: Icons.tag_outlined,
            label: 'رقم الطلب',
            value: '#${widget.request.id}',
            isDark: isDark,
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
  }) {
    return Row(
      children: [
        Icon(
          icon,
          color: isDark ? Colors.grey[400] : ColorsManager.mainBlue,
          size: 20.r,
        ),
        SizedBox(width: 10.w),
        Text(
          '$label: ',
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 14.sp,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 14.sp,
              color: isDark ? Colors.white : Colors.black87,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildDateTimePicker(bool isDark) {
    final hasDate = _selectedDate != null;
    final hasTime = _selectedTime != null;

    return Row(
      children: [
        // Date
        Expanded(
          child: GestureDetector(
            onTap: _pickDate,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 14.h),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF2D2D2D)
                    : ColorsManager.moreLighterGray,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color:
                      isDark ? Colors.grey.shade700 : ColorsManager.lighterGray,
                  width: 1.3,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 18.r,
                    color: isDark ? Colors.grey[400] : ColorsManager.mainBlue,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      hasDate ? _formattedDate : 'التاريخ',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 13.sp,
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
        SizedBox(width: 12.w),
        // Time
        Expanded(
          child: GestureDetector(
            onTap: _pickTime,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 14.h),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF2D2D2D)
                    : ColorsManager.moreLighterGray,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color:
                      isDark ? Colors.grey.shade700 : ColorsManager.lighterGray,
                  width: 1.3,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.access_time_filled_rounded,
                    size: 18.r,
                    color: isDark ? Colors.grey[400] : ColorsManager.mainBlue,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      hasTime ? _formattedTime : 'الوقت',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 13.sp,
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

  Widget _buildLabel(String text, bool isDark) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: 'Cairo',
        fontSize: 14.sp,
        fontWeight: FontWeight.w600,
        color: isDark ? Colors.white : Colors.black87,
      ),
    );
  }

  InputDecoration _buildDecoration({
    required String hint,
    required IconData icon,
    required bool isDark,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        fontFamily: 'Cairo',
        color: isDark ? Colors.grey[600] : Colors.grey[400],
        fontSize: 14.sp,
      ),
      prefixIcon: Icon(
        icon,
        color: isDark ? Colors.grey[500] : ColorsManager.mainBlue,
        size: 20.r,
      ),
      filled: true,
      fillColor:
          isDark ? const Color(0xFF2D2D2D) : ColorsManager.moreLighterGray,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16.r),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16.r),
        borderSide: BorderSide(
          color: ColorsManager.mainBlue,
          width: 2,
        ),
      ),
      contentPadding: EdgeInsets.symmetric(
        horizontal: 16.w,
        vertical: 16.h,
      ),
    );
  }
}
