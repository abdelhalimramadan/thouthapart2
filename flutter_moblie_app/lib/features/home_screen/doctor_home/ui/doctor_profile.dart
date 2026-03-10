import 'package:flutter/material.dart';
import 'package:thotha_mobile_app/core/helpers/shared_pref_helper.dart';
import 'package:thotha_mobile_app/core/routing/routes.dart';
import 'package:thotha_mobile_app/features/home_screen/doctor_home/ui/account_deletion_screen.dart';
import 'package:thotha_mobile_app/features/home_screen/doctor_home/ui/doctor_home_screen.dart';

class DoctorProfile extends StatefulWidget {
  const DoctorProfile({super.key});

  @override
  State<DoctorProfile> createState() => _DoctorProfileState();
}

class _DoctorProfileState extends State<DoctorProfile> {
  // Data from SharedPreferences
  String _firstName = '';
  String _lastName = '';
  String _email = '';
  String _phone = '';
  String _university = '';
  String _studyYear = '';
  String _city = '';
  String _category = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    setState(() => _isLoading = true);

    try {
      final firstName = await SharedPrefHelper.getString('first_name') ?? '';
      final lastName = await SharedPrefHelper.getString('last_name') ?? '';
      final email = await SharedPrefHelper.getString('email') ?? '';
      final phone = await SharedPrefHelper.getString('phone') ?? '';
      final faculty = await SharedPrefHelper.getString('faculty') ?? '';
      final year = await SharedPrefHelper.getString('year') ?? '';
      final governorate = await SharedPrefHelper.getString('governorate') ?? '';
      final category = await SharedPrefHelper.getString('category') ?? '';

      if (mounted) {
        setState(() {
          _firstName = firstName;
          _lastName = lastName;
          _email = email;
          _phone = phone;
          _university = faculty;
          _studyYear = year;
          _city = governorate;
          _category = category;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF2D2D2D) : Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'الملف الشخصي',
          style: TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
            color: isDark ? Colors.white : Colors.black),
          onPressed: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                settings: const RouteSettings(name: 'doctor-home'),
                builder: (context) => const DoctorHomeScreen(),
              ),
            );
          },
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildField('الاسم الأول', _firstName),
                  const SizedBox(height: 16),
                  _buildField('اسم العائلة', _lastName),
                  const SizedBox(height: 16),
                  _buildField('البريد الإلكتروني', _email),
                  const SizedBox(height: 16),
                  _buildField('رقم الهاتف', _phone),
                  const SizedBox(height: 16),
                  _buildField('الجامعة', _university),
                  const SizedBox(height: 16),
                  _buildField('السنة الدراسية', _studyYear),
                  const SizedBox(height: 16),
                  _buildField('المحافظة', _city),
                  const SizedBox(height: 16),
                  _buildField('التخصص', _category),

                  const SizedBox(height: 32),

                  // Change Password Button
                  _buildActionButton(
                    label: 'تغيير كلمة المرور',
                    icon: Icons.lock_outline,
                    gradientColors: const [Color(0xFF667EEA), Color(0xFF764BA2)],
                    onTap: () {
                      Navigator.of(context).pushNamed(Routes.changePasswordScreen);
                    },
                  ),

                  const SizedBox(height: 16),

                  // Delete Account Button
                  _buildActionButton(
                    label: 'حذف الحساب',
                    icon: Icons.delete_outline,
                    gradientColors: const [Color(0xFFE53935), Color(0xFFD32F2F)],
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const AccountDeletionScreen(),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _buildField(String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label above the rectangle
        Padding(
          padding: const EdgeInsets.only(right: 4, bottom: 8),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
            textAlign: TextAlign.right,
          ),
        ),
        // Rectangle with value
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2D2D2D) : Colors.white,
            border: Border.all(
              color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
              width: 1.5
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: isDark
                  ? Colors.black.withValues(alpha: 0.3)
                  : Colors.grey.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            value.isNotEmpty ? value : 'غير محدد',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: value.isNotEmpty
                ? (isDark ? Colors.white : Colors.black)
                : Colors.grey,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required List<Color> gradientColors,
    required VoidCallback onTap,
  }) {
    return Container(
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: gradientColors,
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: gradientColors[0].withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 20, color: Colors.white),
        label: Text(
          label,
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 16,
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
      ),
    );
  }
}

