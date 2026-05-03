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
  final String universityName;
  final String cityName;
  final String? doctorPhoto;
  final int? requestId;
  final int? doctorId;

  BookingConfirmationScreen({
    super.key,
    required this.doctorName,
    required this.date,
    required this.time,
    required this.universityName,
    required this.cityName,
    this.doctorPhoto,
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
        await SharedPrefHelper.setData(
            'first_name', _firstNameController.text.trim());
        await SharedPrefHelper.setData(
            'last_name', _lastNameController.text.trim());
        await SharedPrefHelper.setData(
            'phone_number', _phoneController.text.trim());

        if (!mounted) return;
        _showSuccessDialog();
      } else {
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

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final isAr = context.locale.languageCode == 'ar';
        
        return Directionality(
          textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
          child: AlertDialog(
            backgroundColor: isDark ? Color(0xFF1A1A1A) : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
            contentPadding: EdgeInsets.zero,
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                _buildGradientHeader(),
                
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                  child: Column(
                    children: [
                      // Success Icon
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: Color(0xFFE0F2F5),
                          shape: BoxShape.circle,
                          border: Border.all(color: Color(0xFF53CAF7).withOpacity(0.3), width: 2),
                        ),
                        child: Center(
                          child: Icon(Icons.check_rounded, color: ColorsManager.mainBlue, size: 40),
                        ),
                      ),
                      
                      SizedBox(height: 16),
                      
                      Text(
                        'booking.your_reservation_has_been'.tr(),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      
                      SizedBox(height: 20),
                      
                      // Info Box
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Color(0xFFF4FAFB),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Color(0xFFE0F2F5)),
                        ),
                        child: Text(
                          isAr 
                            ? 'تم حجز موعدك بنجاح مع د. ${widget.doctorName} يوم ${widget.date} الساعة ${widget.time} في ${widget.universityName}.'
                            : 'Your appointment has been successfully booked with Dr. ${widget.doctorName} on ${widget.date} at ${widget.time} in ${widget.universityName}.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 13,
                            color: isDark ? Colors.white70 : Colors.black87,
                            height: 1.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      
                      SizedBox(height: 20),
                      
                      // Chips
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        alignment: WrapAlignment.center,
                        children: [
                          _buildSuccessChip(widget.date, Icons.calendar_today_rounded),
                          _buildSuccessChip(widget.time, Icons.access_time_rounded),
                          _buildSuccessChip(widget.universityName, Icons.school_rounded),
                        ],
                      ),
                      
                      SizedBox(height: 32),
                      
                      // "Done" Button
                      Container(
                        width: 160,
                        height: 52,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF247CFF), Color(0xFF4CB8FF)],
                            begin: Alignment.centerRight,
                            end: Alignment.centerLeft,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: ColorsManager.mainBlue.withOpacity(0.2),
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context); // close dialog
                            Navigator.pop(context); // go back
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: Text(
                            'booking.good'.tr(),
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSuccessChip(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Color(0xFFF0F7FF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ColorsManager.mainBlue.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: ColorsManager.mainBlue, size: 14),
          SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 12,
                color: ColorsManager.mainBlue,
                fontWeight: FontWeight.w700,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
    final isAr = context.locale.languageCode == 'ar';

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: isDark ? Color(0xFF121212) : Color(0xFFF8FBFF),
        body: SafeArea(
          child: Stack(
            children: [
              SingleChildScrollView(
                physics: BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  child: Column(
                    children: [
                      // Space for the back button and top padding
                      SizedBox(height: 50),
                      
                      // Main Card
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: isDark ? theme.cardColor : Colors.white,
                          borderRadius: BorderRadius.circular(32),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 24,
                              offset: Offset(0, 12),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // Gradient Header
                            _buildGradientHeader(),
                            
                            Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                children: [
                                  // Doctor Info Section
                                  _buildDoctorInfoCard(isDark),
                                  
                                  SizedBox(height: 32),
                                  
                                  // Divider with Text "بياناتك"
                                  _buildSectionDivider('booking.your_data'.tr()),
                                  
                                  SizedBox(height: 24),
                                  
                                  // Patient Form
                                  _buildPatientForm(isDark),
                                  
                                  SizedBox(height: 40),
                                  
                                  // Confirmation Button
                                  _buildConfirmButton(),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
              
              // Refined Back Button
              PositionedDirectional(
                top: 10,
                start: 16,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[900] : Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      isAr ? Icons.arrow_forward_ios_rounded : Icons.arrow_back_ios_rounded,
                      color: ColorsManager.mainBlue,
                      size: 20,
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

  Widget _buildGradientHeader() {
    final isAr = context.locale.languageCode == 'ar';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF247CFF),
            Color(0xFF4CB8FF),
            Color(0xFF53CAF7),
          ],
          begin: isAr ? Alignment.topRight : Alignment.topLeft,
          end: isAr ? Alignment.bottomLeft : Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Doctor Info (Primary - appears at 'start')
          Column(
            crossAxisAlignment: isAr ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Text(
                widget.doctorName,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : Colors.black,
                  height: 1.2,
                ),
              ),
              Text(
                widget.specialty,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 13,
                  color: isDark ? Colors.white.withOpacity(0.85) : Colors.black.withOpacity(0.7),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          
          // Booking Badge (Secondary - appears at 'end')
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.15) : Colors.black.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: isDark ? Colors.white.withOpacity(0.2) : Colors.black.withOpacity(0.1)),
            ),
            child: Text(
              'home_screen.book_an_appointment'.tr(),
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 11,
                color: isDark ? Colors.white : Colors.black,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorInfoCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Color(0xFFF4FAFB),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isDark ? Colors.white10 : Color(0xFFE0F2F5),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          // Date & Time Row
          Row(
            children: [
              _buildInfoIcon(Icons.calendar_today_rounded),
              SizedBox(width: 10),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: TextStyle(fontFamily: 'Cairo', fontSize: 13, color: Colors.grey[600]),
                    children: [
                      TextSpan(text: '${'home_screen.today'.tr()} '),
                      TextSpan(
                        text: widget.date,
                        style: TextStyle(fontWeight: FontWeight.bold, color: ColorsManager.mainBlue),
                      ),
                    ],
                  ),
                ),
              ),
              Container(width: 1, height: 20, color: Colors.grey.withOpacity(0.2), margin: EdgeInsets.symmetric(horizontal: 8)),
              _buildInfoIcon(Icons.access_time_rounded),
              SizedBox(width: 10),
              Text(
                widget.time,
                style: TextStyle(fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.bold, color: ColorsManager.mainBlue),
              ),
            ],
          ),
          
          Divider(height: 40, thickness: 1, color: isDark ? Colors.white10 : Color(0xFFE0F2F5)),
          
          // University Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoIcon(Icons.school_rounded),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'doctor.the_university'.tr(),
                      style: TextStyle(fontFamily: 'Cairo', fontSize: 12, color: Colors.grey[500], fontWeight: FontWeight.w600),
                    ),
                    Text(
                      widget.universityName,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          SizedBox(height: 20),
          
          // Governorate Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildInfoIcon(Icons.location_on_rounded),
              SizedBox(width: 12),
              Text(
                'home_screen.governorate'.tr(),
                style: TextStyle(fontFamily: 'Cairo', fontSize: 12, color: Colors.grey[500], fontWeight: FontWeight.w600),
              ),
              SizedBox(width: 8),
              Text(
                widget.cityName,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoIcon(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: ColorsManager.mainBlue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: ColorsManager.mainBlue, size: 18),
    );
  }

  Widget _buildSectionDivider(String label) {
    return Row(
      children: [
        Expanded(child: Container(height: 1, color: Colors.grey.withOpacity(0.1))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 13,
              color: Colors.grey[400],
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Expanded(child: Container(height: 1, color: Colors.grey.withOpacity(0.1))),
      ],
    );
  }

  Widget _buildPatientForm(bool isDark) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _firstNameController,
                  label: 'booking.first_name'.tr(),
                  hint: 'booking.first_name'.tr(),
                  icon: Icons.person_outline_rounded,
                  isDark: isDark,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'booking.please_enter_first_name'.tr();
                    }
                    return null;
                  },
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildTextField(
                  controller: _lastNameController,
                  label: 'booking.last_name'.tr(),
                  hint: 'booking.last_name'.tr(),
                  icon: Icons.person_outline_rounded,
                  isDark: isDark,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'booking.please_enter_your_last'.tr();
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          SizedBox(height: 24),
          _buildTextField(
            controller: _phoneController,
            label: 'booking.mobile_number'.tr(),
            hint: '01X XXXX XXXX',
            icon: Icons.phone_iphone_rounded,
            keyboardType: TextInputType.phone,
            isDark: isDark,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9\u0660-\u0669]')),
            ],
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'booking.please_enter_mobile_number'.tr();
              }
              String cleanPhone = value.replaceAll(RegExp(r'[\s\-\(\)]'), '');
              if (cleanPhone.startsWith('01')) {
                if (cleanPhone.length != 11) return 'booking.the_egyptian_mobile_number'.tr();
                if (!RegExp(r'^01[0-5]\d{8}$').hasMatch(cleanPhone)) return 'booking.the_egyptian_mobile_number_1'.tr();
              } else {
                return 'booking.please_enter_a_valid'.tr();
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required bool isDark,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10, right: 4),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            validator: validator,
            textAlign: TextAlign.right,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(fontFamily: 'Cairo', color: Colors.grey.withOpacity(0.4), fontSize: 13),
              prefixIcon: Icon(icon, color: ColorsManager.mainBlue.withOpacity(0.5), size: 22),
              filled: true,
              fillColor: isDark ? Colors.grey[850] : Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide(color: Colors.grey.withOpacity(0.1)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide(color: Colors.grey.withOpacity(0.1)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide(color: ColorsManager.mainBlue, width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide(color: Colors.red.withOpacity(0.5)),
              ),
            ),
            style: TextStyle(fontFamily: 'Cairo', fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmButton() {
    return Container(
      width: double.infinity,
      height: 64,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF247CFF),
            Color(0xFF1B62D6),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: ColorsManager.mainBlue.withOpacity(0.4),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submitForm,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        ),
        child: _isLoading
            ? CircularProgressIndicator(color: Colors.white)
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'booking.booking_confirmation'.tr(),
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 12),
                  Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 26),
                ],
              ),
      ),
    );
  }
}
