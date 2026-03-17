import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:thotha_mobile_app/core/helpers/shared_pref_helper.dart';
import 'package:thotha_mobile_app/core/theming/colors.dart';
import 'package:thotha_mobile_app/core/theming/styles.dart';
import 'package:thotha_mobile_app/core/di/dependency_injection.dart';
import 'package:thotha_mobile_app/features/requests/data/models/case_request_body.dart';
import 'package:thotha_mobile_app/features/requests/data/models/case_request_model.dart';
import 'package:thotha_mobile_app/features/requests/data/repos/case_request_repo.dart';

class EditCaseRequestScreen extends StatefulWidget {
  final CaseRequestModel request;

  const EditCaseRequestScreen({
    super.key,
    required this.request,
  });

  @override
  State<EditCaseRequestScreen> createState() => _EditCaseRequestScreenState();
}

class _EditCaseRequestScreenState extends State<EditCaseRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _descriptionController;

  // Doctor info (display only)
  String _firstName = '';
  String _lastName = '';
  String _category = '';
  bool _isLoadingInfo = true;

  // Selected date & time
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController(
      text: widget.request.description.isEmpty ||
              widget.request.description == 'No details'
          ? ''
          : widget.request.description,
    );
    _loadDoctorInfo();
    _loadDateTime();
    _descriptionController.addListener(_onFieldChanged);
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  void _onFieldChanged() {
    // Placeholder for potential future use
  }

  Future<void> _loadDoctorInfo() async {
    final firstName = await SharedPrefHelper.getString('first_name') ?? '';
    final lastName = await SharedPrefHelper.getString('last_name') ?? '';
    final category = await SharedPrefHelper.getString('category') ?? '';

    if (mounted) {
      setState(() {
        _firstName = firstName;
        _lastName = lastName;
        _category = category;
        _isLoadingInfo = false;
      });
    }
  }

  void _loadDateTime() {
    try {
      final dt = DateTime.parse(widget.request.dateTime);
      setState(() {
        _selectedDate = dt;
        _selectedTime = TimeOfDay.fromDateTime(dt);
      });
    } catch (_) {
      // If parsing fails, use defaults
    }
  }

  Future<void> _selectDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2099),
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  Future<void> _selectTime() async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child!,
        );
      },
    );

    if (pickedTime != null) {
      setState(() {
        _selectedTime = pickedTime;
      });
    }
  }

  String get _dateTimeIso {
    if (_selectedDate == null || _selectedTime == null) {
      return widget.request.dateTime;
    }
    final combined = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );
    return combined.toIso8601String();
  }

  Future<void> _submitForm() async {
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
      final result = await repo.editRequest(widget.request.id ?? 0, body);

      if (mounted) Navigator.pop(context);

      if (result['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'تم تحديث الطلب بنجاح',
                style: TextStyle(fontFamily: 'Cairo'),
              ),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true); // Return true to indicate success
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                result['error']?.toString() ?? 'فشل في تحديث الطلب',
                style: const TextStyle(fontFamily: 'Cairo'),
              ),
              backgroundColor: Colors.red[700],
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'حدث خطأ: ${e.toString()}',
              style: const TextStyle(fontFamily: 'Cairo'),
            ),
            backgroundColor: Colors.red[700],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final baseFontSize = width * 0.04;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'تعديل الطلب',
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
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: _isLoadingInfo
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'تعديل تفاصيل الطلب',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: baseFontSize * 1.125,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'قم بتحديث البيانات التالية لتعديل طلبك',
                        style: TextStyles.font14GrayRegular.copyWith(
                          fontFamily: 'Cairo',
                          fontSize: baseFontSize * 0.875,
                          color: isDark ? Colors.grey[400] : null,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ── Doctor Info Card (display only) ────────────────
                      _buildInfoCard(isDark, baseFontSize),
                      const SizedBox(height: 24),

                      // ── DateTime picker ───────────────────────────────
                      _buildLabel('التاريخ والوقت', baseFontSize, isDark),
                      const SizedBox(height: 8),
                      _buildDateTimePicker(isDark, baseFontSize, width),
                      const SizedBox(height: 20),

                      // ── Description ───────────────────────────────────
                      _buildLabel('الوصف والتفاصيل', baseFontSize, isDark),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 4,
                        minLines: 3,
                        textDirection: TextDirection.rtl,
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: baseFontSize * 0.95,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        decoration: InputDecoration(
                          hintText: 'صف حالتك أو احتياجاتك...',
                          hintStyle: TextStyle(
                            fontFamily: 'Cairo',
                            color: Colors.grey[400],
                          ),
                          contentPadding: const EdgeInsets.all(14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: Colors.grey[300]!,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: Colors.grey[300]!,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: Colors.blue,
                            ),
                          ),
                          filled: true,
                          fillColor: isDark
                              ? Colors.grey[800]
                              : Colors.grey[50],
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'الوصف مطلوب';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 32),

                      // ── Submit Button ─────────────────────────────────
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ColorsManager.mainBlue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: _submitForm,
                          child: Text(
                            'حفظ التعديلات',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: baseFontSize * 1.125,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ── Cancel Button ─────────────────────────────────
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            side: BorderSide(
                              color: Colors.grey[400]!,
                            ),
                          ),
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            'إلغاء',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: baseFontSize * 1.125,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildInfoCard(bool isDark, double baseFontSize) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.grey[50],
        border: Border.all(
          color: Colors.grey[300]!,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'بيانات الطبيب',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: baseFontSize * 0.95,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.grey[200] : Colors.grey[700],
            ),
          ),
          const SizedBox(height: 12),
          _buildInfoRow('الاسم', '$_firstName $_lastName', isDark, baseFontSize),
          const SizedBox(height: 8),
          _buildInfoRow('التخصص', _category, isDark, baseFontSize),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
      String label, String value, bool isDark, double baseFontSize) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label: ',
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: baseFontSize * 0.875,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.grey[300] : Colors.grey[600],
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: baseFontSize * 0.875,
              color: isDark ? Colors.grey[100] : Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateTimePicker(
      bool isDark, double baseFontSize, double width) {
    final dateStr = _selectedDate != null
        ? DateFormat('dd/MM/yyyy', 'ar_SA').format(_selectedDate!)
        : 'اختر التاريخ';
    final timeStr = _selectedTime != null
        ? '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}'
        : 'اختر الوقت';

    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: _selectDate,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(10),
                color: isDark ? Colors.grey[800] : Colors.white,
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today,
                      size: 18, color: ColorsManager.mainBlue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      dateStr,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: baseFontSize * 0.875,
                        color: isDark ? Colors.grey[200] : Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: _selectTime,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(10),
                color: isDark ? Colors.grey[800] : Colors.white,
              ),
              child: Row(
                children: [
                  Icon(Icons.access_time,
                      size: 18, color: ColorsManager.mainBlue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      timeStr,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: baseFontSize * 0.875,
                        color: isDark ? Colors.grey[200] : Colors.black87,
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

  Widget _buildLabel(String label, double baseFontSize, bool isDark) {
    return Text(
      label,
      style: TextStyle(
        fontFamily: 'Cairo',
        fontSize: baseFontSize * 0.95,
        fontWeight: FontWeight.w600,
        color: isDark ? Colors.grey[200] : Colors.grey[700],
      ),
    );
  }
}

