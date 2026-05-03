import 'package:thoutha_mobile_app/core/networking/api_service.dart';
import 'package:thoutha_mobile_app/core/di/dependency_injection.dart';
import 'package:thoutha_mobile_app/core/theming/colors.dart';
import 'package:thoutha_mobile_app/core/helpers/shared_pref_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;

class BookingConfirmationScreen extends StatefulWidget {
  final String doctorName;
  final String date;
  final String time;
  final String specialty;
  final int? requestId;
  final int? doctorId;

  BookingConfirmationScreen({
    super.key,
    required this.doctorName,
    required this.date,
    required this.time,
    String? specialty,
    this.requestId,
    this.doctorId,
  }) : specialty = specialty ?? 'booking.dentistry'.tr();

  @override
  State<BookingConfirmationScreen> createState() =>
      _BookingConfirmationScreenState();
}

class _BookingConfirmationScreenState extends State<BookingConfirmationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();

  // Appointment-related variables
  late ApiService _apiService;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _apiService = getIt<ApiService>();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      _completeBooking();
    }
  }

  void _completeBooking() async {
    if (widget.requestId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'booking.sorry_your_reservation_cannot'.tr(),
              style: TextStyle(fontFamily: 'Cairo')),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Call the API to create appointment
      final result = await _apiService.createAppointment(
        widget.requestId!,
        _firstNameController.text,
        _lastNameController.text,
        _phoneController.text,
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      if (result['success'] == true) {
        // حفظ البيانات للمرة القادمة
        await SharedPrefHelper.setData(
            'first_name', _firstNameController.text.trim());
        await SharedPrefHelper.setData(
            'last_name', _lastNameController.text.trim());
        await SharedPrefHelper.setData(
            'phone_number', _phoneController.text.trim());

        // Success - show confirmation dialog
        if (!mounted) return;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            return Directionality(
              textDirection: TextDirection.rtl,
              child: AlertDialog(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                titlePadding: const EdgeInsets.only(top: 20, left: 20, right: 20),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                actionsPadding:
                    const EdgeInsets.only(bottom: 16, left: 16, right: 16),
                actionsAlignment: MainAxisAlignment.center,
                title: Text(
                  'booking.your_reservation_has_been'.tr(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: ColorsManager.mainBlue,
                  ),
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: ColorsManager.mainBlue.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.check_rounded,
                          color: ColorsManager.mainBlue, size: 42),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'تم حجز موعدك بنجاح مع ${widget.doctorName}\nفي يوم ${widget.date} الساعة ${widget.time}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 14,
                        color: isDark ? Colors.white : Color(0xFF1F2937),
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
                actions: [
                  Builder(
                    builder: (context) {
                      final screenWidth = MediaQuery.of(context).size.width;
                      final isTablet = screenWidth >= 600;

                      return Center(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ColorsManager.mainBlue,
                            minimumSize: Size(isTablet ? 220 : screenWidth * 0.6, isTablet ? 56 : 50),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'booking.good'.tr(),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: isTablet ? 19 : 17,
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              height: 1.1, // Improved line height for Cairo
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        );
      } else {
        // Error
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result['error'] ?? 'booking.failed_to_create_appointment'.tr(),
              style: TextStyle(fontFamily: 'Cairo'),
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'حدث خطأ: ${e.toString()}',
            style: TextStyle(fontFamily: 'Cairo'),
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: Stack(
            children: [
              Container(
                width: double.infinity,
                height: double.infinity,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(-0.7, -0.7),
                    radius: 1.5,
                    colors: [
                      Color(0xFF84E5F3).withOpacity(0.4),
                      Color(0xFF84E5F3).withOpacity(0.1),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.3, 0.8],
                  ),
                ),
              ),
              Container(
                width: double.infinity,
                height: double.infinity,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(0.7, 0.7),
                    radius: 1.5,
                    colors: [
                      ColorsManager.layerBlur2,
                      Colors.transparent,
                    ],
                    stops: [0.1, 0.8],
                  ),
                ),
              ),
              // Top Back Button
              Positioned(
                top: MediaQuery.of(context).padding.top + 10,
                right: 20,
                child: IconButton(
                  icon: Icon(
                    Icons.arrow_forward_ios,
                    color: ColorsManager.mainBlue,
                    size: 24,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Container(
                    width: double.infinity,
                    constraints: BoxConstraints(
                      maxWidth: 500,
                    ),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: theme.cardTheme.color ?? colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: isDark
                              ? Colors.black.withOpacity(0.3)
                              : Colors.grey.withOpacity(0.1),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: SingleChildScrollView(
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(
                              child: Text(
                                'booking.booking_confirmation'.tr(),
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontFamily: 'Cairo',
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.primary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            SizedBox(height: 16),
                            Card(
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'booking.doctor_information'.tr(),
                                      style:
                                          theme.textTheme.titleMedium?.copyWith(
                                        fontFamily: 'Cairo',
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 12),
                                    _buildInfoRow(
                                        'booking.doctor'.tr(), widget.doctorName, 14),
                                    SizedBox(height: 8),
                                    _buildInfoRow(
                                        'booking.specialization'.tr(), widget.specialty, 14),
                                    SizedBox(height: 8),
                                    _buildInfoRow(
                                        'booking.the_date'.tr(), widget.date, 14),
                                    SizedBox(height: 8),
                                    _buildInfoRow('booking.the_time'.tr(), widget.time, 14),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(height: 24),
                            Text(
                              'booking.patient_information'.tr(),
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontFamily: 'Cairo',
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 16),
                            SizedBox(height: 16),
                            TextFormField(
                              controller: _firstNameController,
                              style: TextStyle(fontFamily: 'Cairo'),
                              decoration: InputDecoration(
                                labelText: 'booking.first_name'.tr(),
                                labelStyle:
                                    TextStyle(fontFamily: 'Cairo'),
                                prefixIcon: Icon(Icons.person_outline,
                                    color: theme.iconTheme.color),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                              ),
                              textInputAction: TextInputAction.next,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'booking.please_enter_first_name'.tr();
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: 16),
                            TextFormField(
                              controller: _lastNameController,
                              style: TextStyle(fontFamily: 'Cairo'),
                              decoration: InputDecoration(
                                labelText: 'booking.last_name'.tr(),
                                labelStyle:
                                    TextStyle(fontFamily: 'Cairo'),
                                prefixIcon: Icon(Icons.person_outline,
                                    color: theme.iconTheme.color),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                              ),
                              textInputAction: TextInputAction.next,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'booking.please_enter_your_last'.tr();
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: 16),
                            TextFormField(
                              controller: _phoneController,
                              keyboardType: TextInputType.number,
                              style: TextStyle(fontFamily: 'Cairo'),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                    RegExp(r'[0-9\u0660-\u0669]')),
                              ],
                              decoration: InputDecoration(
                                labelText: 'booking.mobile_number'.tr(),
                                labelStyle:
                                    TextStyle(fontFamily: 'Cairo'),
                                hintText: '01X XXX XXXXX',
                                hintStyle: TextStyle(fontFamily: 'Cairo'),
                                prefixIcon: Icon(Icons.phone_android,
                                    color: theme.iconTheme.color),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'booking.please_enter_mobile_number'.tr();
                                }

                                String cleanPhone =
                                    value.replaceAll(RegExp(r'[\s\-\(\)]'), '');

                                if (cleanPhone.startsWith('01')) {
                                  if (cleanPhone.length != 11) {
                                    return 'booking.the_egyptian_mobile_number'.tr();
                                  }
                                  if (!RegExp(r'^01[0-5]\d{8}$')
                                      .hasMatch(cleanPhone)) {
                                    return 'booking.the_egyptian_mobile_number_1'.tr();
                                  }
                                } else if (cleanPhone.startsWith('+20')) {
                                  if (cleanPhone.length != 13) {
                                    return 'booking.the_egyptian_mobile_number_2'.tr();
                                  }
                                  if (!RegExp(r'^\+201[0-25]\d{8}$')
                                      .hasMatch(cleanPhone)) {
                                    return 'booking.the_egyptian_mobile_number_1'.tr();
                                  }
                                } else {
                                  return 'booking.please_enter_a_valid'.tr();
                                }

                                return null;
                              },
                            ),
                            SizedBox(height: 24),
                            SizedBox(
                              height: 48,
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed:
                                    _isLoading ? null : () => _submitForm(),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: colorScheme.primary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: _isLoading
                                    ? SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Text(
                                        'booking.booking_confirmation'.tr(),
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                          fontFamily: 'Cairo',
                                          fontSize: 16,
                                          color: colorScheme.onPrimary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, double fontSize) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontFamily: 'Cairo',
            fontSize: fontSize,
            color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
          ),
        ),
        SizedBox(width: 8),
        Text(
          value,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontFamily: 'Cairo',
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
