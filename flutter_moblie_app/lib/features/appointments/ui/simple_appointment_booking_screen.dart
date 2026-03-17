import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:thotha_mobile_app/core/theming/colors.dart';
import 'package:thotha_mobile_app/features/appointments/data/appointments_service.dart';
import 'package:thotha_mobile_app/core/networking/api_service.dart';

/// Simple Appointment Booking Screen
/// 
/// Ultra-simple patient booking with only 3 fields:
/// ✅ First Name
/// ✅ Last Name  
/// ✅ Phone Number
/// 
/// PatientId: Auto-created if not exists (based on phone number)
/// NO appointment date (inherited from Request.dateTime)
/// NO duration
/// NO notes
class SimpleAppointmentBookingScreen extends StatefulWidget {
  final String requestId;
  final String requestDescription;
  final String doctorName;
  final String categoryName;
  final String requestDateTime;

  const SimpleAppointmentBookingScreen({
    super.key,
    required this.requestId,
    required this.requestDescription,
    required this.doctorName,
    required this.categoryName,
    required this.requestDateTime,
  });

  @override
  State<SimpleAppointmentBookingScreen> createState() => _SimpleAppointmentBookingScreenState();
}

class _SimpleAppointmentBookingScreenState extends State<SimpleAppointmentBookingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  
  bool _isLoading = false;
  final _appointmentsService = AppointmentsService(ApiService());

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('حجز موعد'),
        backgroundColor: ColorsManager.mainBlue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Request Info Card
            _buildRequestInfoCard(),
            SizedBox(height: 24.h),
            
            // Booking Form
            _buildBookingForm(),
            SizedBox(height: 24.h),
            
            // Submit Button
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestInfoCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: ColorsManager.mainBlue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: ColorsManager.mainBlue.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            'معلومات الطلب',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: ColorsManager.mainBlue,
            ),
          ),
          SizedBox(height: 8.h),
          _buildInfoRow('الدكتور:', widget.doctorName),
          _buildInfoRow('التخصص:', widget.categoryName),
          _buildInfoRow('الوصف:', widget.requestDescription),
          _buildInfoRow('التاريخ والوقت:', _formatDateTime(widget.requestDateTime)),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        children: [
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 14.sp),
              textAlign: TextAlign.right,
            ),
          ),
          SizedBox(width: 8.w),
          Text(
            label,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            'معلومات المريض',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16.h),
          
          // First Name
          TextFormField(
            controller: _firstNameController,
            textAlign: TextAlign.right,
            decoration: InputDecoration(
              labelText: 'الاسم الأول',
              hintText: 'أدخل الاسم الأول',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'الرجاء إدخال الاسم الأول';
              }
              return null;
            },
          ),
          SizedBox(height: 16.h),
          
          // Last Name
          TextFormField(
            controller: _lastNameController,
            textAlign: TextAlign.right,
            decoration: InputDecoration(
              labelText: 'اسم العائلة',
              hintText: 'أدخل اسم العائلة',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'الرجاء إدخال اسم العائلة';
              }
              return null;
            },
          ),
          SizedBox(height: 16.h),
          
          // Phone Number
          TextFormField(
            controller: _phoneController,
            textAlign: TextAlign.right,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: 'رقم الجوال',
              hintText: '01xxxxxxxxx',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
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
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 50.h,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submitBooking,
        style: ElevatedButton.styleFrom(
          backgroundColor: ColorsManager.mainBlue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.r),
          ),
        ),
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(
                'احجز الآن',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Future<void> _submitBooking() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _appointmentsService.createAppointment(
        requestId: widget.requestId,
        patientFirstName: _firstNameController.text.trim(),
        patientLastName: _lastNameController.text.trim(),
        patientPhoneNumber: _phoneController.text.trim(),
      );

      if (mounted) {
        if (result['success'] == true) {
          _showSuccessDialog(result['data']);
        } else {
          _showErrorDialog(result['error'] ?? 'فشل في إنشاء الحجز');
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('حدث خطأ غير متوقع: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSuccessDialog(dynamic appointmentData) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'تم الحجز بنجاح!',
          textAlign: TextAlign.right,
        ),
        content: const Text(
          'تم حجز الموعد بنجاح. سيتم التواصل معك قريباً.',
          textAlign: TextAlign.right,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Go back to previous screen
            },
            child: const Text('حسناً'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'خطأ في الحجز',
          textAlign: TextAlign.right,
        ),
        content: Text(
          error,
          textAlign: TextAlign.right,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('حسناً'),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(String dateTimeString) {
    try {
      final dateTime = DateTime.parse(dateTimeString);
      return '${dateTime.day.toString().padLeft(2, '0')}/'
          '${dateTime.month.toString().padLeft(2, '0')}/'
          '${dateTime.year} '
          '${dateTime.hour.toString().padLeft(2, '0')}:'
          '${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateTimeString;
    }
  }
}
