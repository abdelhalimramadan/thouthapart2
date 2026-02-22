import 'package:thotha_mobile_app/features/booking/ui/otp_verification_dialog.dart';
import 'package:thotha_mobile_app/features/appointments/data/appointments_service.dart';
import 'package:thotha_mobile_app/core/networking/otp_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class BookingConfirmationScreen extends StatefulWidget {
  final String doctorName;
  final String date;
  final String time;
  final String specialty;

  const BookingConfirmationScreen({
    Key? key,
    required this.doctorName,
    required this.date,
    required this.time,
    this.specialty = 'طب الأسنان',
  }) : super(key: key);

  @override
  State<BookingConfirmationScreen> createState() => _BookingConfirmationScreenState();
}

class _BookingConfirmationScreenState extends State<BookingConfirmationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final OtpService _otpService = OtpService();
  bool _isLoading = false;
  bool _isSendingOtp = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _submitForm(double width, double baseFontSize) async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSendingOtp = true;
      });

      final otpResult = await _otpService.sendOtp(_phoneController.text);
      
      setState(() {
        _isSendingOtp = false;
      });

      if (otpResult['success']) {
        if (!mounted) return;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => OtpVerificationDialog(
            contactInfo: _phoneController.text,
            onVerified: (code) {
              _completeBooking(width, baseFontSize);
            },
            onResend: (phoneNumber) {
              // ignore
            },
          ),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(otpResult['error'] ?? 'فشل إرسال رمز التحقق', style: const TextStyle(fontFamily: 'Cairo')),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _completeBooking(double width, double baseFontSize) {
      setState(() {
        _isLoading = true;
      });

      Future.delayed(const Duration(seconds: 2), () async {
        final appointment = {
          'doctorName': widget.doctorName,
          'specialty': widget.specialty,
          'date': widget.date,
          'time': widget.time,
          'status': 'مؤكد',
        };

        await AppointmentsService().addAppointment(appointment);

        if (!mounted) return;

        setState(() {
          _isLoading = false;
        });
        
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            titlePadding: const EdgeInsets.only(top: 20, left: 20, right: 20),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            actionsPadding: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
            title: Text(
              'تم الحجز بنجاح',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: baseFontSize * 1.125, // 18
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0B8FAC),
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72 * (width / 390),
                  height: 72 * (width / 390),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0B8FAC).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.check_rounded, color: const Color(0xFF0B8FAC), size: 42 * (width / 390)),
                ),
                const SizedBox(height: 16),
                Text(
                  'تم حجز موعدك بنجاح مع ${widget.doctorName}\nفي يوم ${widget.date} الساعة ${widget.time}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: baseFontSize * 0.875, // 14
                    color: const Color(0xFF1F2937),
                    height: 1.6,
                  ),
                ),
              ],
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              SizedBox(
                width: 140 * (width / 390),
                height: 40,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); 
                    Navigator.pop(context); 
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0B8FAC),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'حسناً',
                    style: TextStyle(fontFamily: 'Cairo', fontSize: baseFontSize * 0.875, color: Colors.white, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        );
      });
    }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final baseFontSize = width * 0.04;
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
                    center: const Alignment(-0.7, -0.7),
                    radius: 1.5,
                    colors: [
                      const Color(0xFF84E5F3).withValues(alpha: 0.4),
                      const Color(0xFF84E5F3).withValues(alpha: 0.1),
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
                    center: const Alignment(0.7, 0.7),
                    radius: 1.5,
                    colors: [
                      const Color(0xFF8DECB4).withValues(alpha: 0.4),
                      const Color(0xFF8DECB4).withValues(alpha: 0.1),
                      Colors.transparent,
                    ],
                    stops: const [0.1, 0.3, 0.8],
                  ),
                ),
              ),
              Center(
                child: Padding(
                  padding: EdgeInsets.all(width * 0.06),
                  child: Container(
                    width: double.infinity,
                    constraints: BoxConstraints(
                      maxWidth: width >= 600 ? 500 : double.infinity,
                    ),
                    padding: EdgeInsets.all(width * 0.06),
                    decoration: BoxDecoration(
                      color: theme.cardTheme.color ?? colorScheme.surface,
                      borderRadius: BorderRadius.circular(16.0),
                      boxShadow: [
                        BoxShadow(
                          color: isDark ? Colors.black.withValues(alpha: 0.3) : Colors.grey.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
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
                                'تأكيد الحجز',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontFamily: 'Cairo',
                                  fontSize: baseFontSize * 1.5, // 24
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.primary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(height: 16),
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
                                      'معلومات الطبيب',
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        fontFamily: 'Cairo',
                                        fontSize: baseFontSize, // 16
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    _buildInfoRow('الطبيب:', widget.doctorName, baseFontSize),
                                    const SizedBox(height: 8),
                                    _buildInfoRow('التخصص:', widget.specialty, baseFontSize),
                                    const SizedBox(height: 8),
                                    _buildInfoRow('التاريخ:', widget.date, baseFontSize),
                                    const SizedBox(height: 8),
                                    _buildInfoRow('الوقت:', widget.time, baseFontSize),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'معلومات المريض',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontFamily: 'Cairo',
                                fontSize: baseFontSize * 1.125, // 18
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _firstNameController,
                              style: const TextStyle(fontFamily: 'Cairo'),
                              decoration: InputDecoration(
                                labelText: 'الاسم الأول',
                                labelStyle: const TextStyle(fontFamily: 'Cairo'),
                                prefixIcon: Icon(Icons.person_outline, color: theme.iconTheme.color),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                              ),
                              textInputAction: TextInputAction.next,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'الرجاء إدخال الاسم الأول';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _lastNameController,
                              style: const TextStyle(fontFamily: 'Cairo'),
                              decoration: InputDecoration(
                                labelText: 'اسم العائلة',
                                labelStyle: const TextStyle(fontFamily: 'Cairo'),
                                prefixIcon: Icon(Icons.person_outline, color: theme.iconTheme.color),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                              ),
                              textInputAction: TextInputAction.next,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'الرجاء إدخال اسم العائلة';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _phoneController,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(fontFamily: 'Cairo'),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(RegExp(r'[0-9\u0660-\u0669]')),
                              ],
                              decoration: InputDecoration(
                                labelText: 'رقم الجوال',
                                labelStyle: const TextStyle(fontFamily: 'Cairo'),
                                hintText: '01X XXX XXXXX',
                                hintStyle: const TextStyle(fontFamily: 'Cairo'),
                                prefixIcon: Icon(Icons.phone_android, color: theme.iconTheme.color),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'الرجاء إدخال رقم الجوال';
                                }
                                
                                String cleanPhone = value.replaceAll(RegExp(r'[\s\-\(\)]'), '');
                                
                                if (cleanPhone.startsWith('01')) {
                                  if (cleanPhone.length != 11) {
                                    return 'رقم الجوال المصري يجب أن يكون 11 رقم';
                                  }
                                  if (!RegExp(r'^01[0-2]\d{8}$').hasMatch(cleanPhone)) {
                                    return 'رقم الجوال المصري غير صحيح';
                                  }
                                } else if (cleanPhone.startsWith('+20')) {
                                  if (cleanPhone.length != 13) {
                                    return 'رقم الجوال المصري يجب أن يكون 13 رقم مع +20';
                                  }
                                  if (!RegExp(r'^\+201[0-2]\d{8}$').hasMatch(cleanPhone)) {
                                    return 'رقم الجوال المصري غير صحيح';
                                  }
                                } else {
                                  return 'الرجاء إدخال رقم جوال مصري صحيح';
                                }
                                
                                return null;
                              },
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              height: 48,
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: (_isLoading || _isSendingOtp) ? null : () => _submitForm(width, baseFontSize),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: colorScheme.primary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                ),
                                child: _isSendingOtp
                                    ? Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            'جاري إرسال رمز التحقق...',
                                            style: theme.textTheme.titleMedium?.copyWith(
                                              fontFamily: 'Cairo',
                                              fontSize: baseFontSize,
                                              color: colorScheme.onPrimary,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      )
                                    : _isLoading
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : Text(
                                            'تأكيد الحجز',
                                            style: theme.textTheme.titleMedium?.copyWith(
                                              fontFamily: 'Cairo',
                                              fontSize: baseFontSize,
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

  Widget _buildInfoRow(String label, String value, double baseFontSize) {
    return Row(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontFamily: 'Cairo',
            fontSize: baseFontSize * 0.875, // 14
            color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontFamily: 'Cairo',
            fontSize: baseFontSize * 0.875, // 14
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
