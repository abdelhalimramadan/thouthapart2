import 'package:flutter/material.dart';
import 'package:thotha_mobile_app/core/helpers/shared_pref_helper.dart';
import 'package:thotha_mobile_app/core/networking/api_service.dart';
import 'package:thotha_mobile_app/core/networking/models/category_model.dart';
import 'package:thotha_mobile_app/core/networking/models/city_model.dart';
import 'package:thotha_mobile_app/core/networking/models/university_model.dart';
import 'package:thotha_mobile_app/core/theming/colors.dart';

class EditDoctorProfileScreen extends StatefulWidget {
  // القيم الحالية بتتبعت من صفحة الملف الشخصي
  final String firstName;
  final String lastName;
  final String phone;
  final String? faculty;
  final String? year;
  final String? governorate;
  final String? category;

  const EditDoctorProfileScreen({
    Key? key,
    required this.firstName,
    required this.lastName,
    required this.phone,
    this.faculty,
    this.year,
    this.governorate,
    this.category,
  }) : super(key: key);

  @override
  State<EditDoctorProfileScreen> createState() => _EditDoctorProfileScreenState();
}

class _EditDoctorProfileScreenState extends State<EditDoctorProfileScreen> {
  final ApiService _apiService = ApiService();

  // Controllers
  late final TextEditingController _firstNameCtrl;
  late final TextEditingController _lastNameCtrl;
  late final TextEditingController _phoneCtrl;

  // Dropdown values
  String? _faculty;
  String? _year;
  String? _governorate;
  String? _category;

  // Reference data from API
  List<String> _governorates = [];
  List<String> _categories  = [];
  List<String> _colleges    = [];
  final List<String> _studyYears = [
    'الفرقة الأولى', 'الفرقة الثانية', 'الفرقة الثالثة',
    'الفرقة الرابعة', 'الفرقة الخامسة', 'امتياز',
  ];

  bool _loadingRef  = false;
  bool _isSaving    = false;

  @override
  void initState() {
    super.initState();
    _firstNameCtrl = TextEditingController(text: widget.firstName);
    _lastNameCtrl  = TextEditingController(text: widget.lastName);
    _phoneCtrl     = TextEditingController(text: widget.phone);
    _faculty    = widget.faculty;
    _year       = widget.year;
    _governorate = widget.governorate;
    _category   = widget.category;
    _fetchReferenceData();
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  // ── جلب بيانات القوائم من API ─────────────────────────────────
  Future<void> _fetchReferenceData() async {
    setState(() => _loadingRef = true);
    try {
      final results = await Future.wait([
        _apiService.getCities(),
        _apiService.getUniversities(),
        _apiService.getCategories(),
      ]);

      final citiesRes  = results[0];
      final universRes = results[1];
      final catsRes    = results[2];

      if (mounted) {
        setState(() {
          if (citiesRes['success']  == true) _governorates = (citiesRes['data']  as List<CityModel>).map((c) => c.name).toList();
          if (universRes['success'] == true) _colleges     = (universRes['data'] as List<UniversityModel>).map((u) => u.name).toList();
          if (catsRes['success']    == true) _categories   = (catsRes['data']    as List<CategoryModel>).map((c) => c.name).toList();

          // التحقق من أن القيم المختارة موجودة في القوائم المجلوبة
          if (_faculty    != null && _colleges.isNotEmpty    && !_colleges.contains(_faculty))       _faculty    = null;
          if (_year       != null && !_studyYears.contains(_year))                                    _year       = null;
          if (_governorate != null && _governorates.isNotEmpty && !_governorates.contains(_governorate)) _governorate = null;
          if (_category   != null && _categories.isNotEmpty   && !_categories.contains(_category))   _category   = null;
        });
      }
    } catch (_) {} finally {
      if (mounted) setState(() => _loadingRef = false);
    }
  }

  // ── حفظ البيانات ──────────────────────────────────────────────
  Future<void> _save() async {
    final firstName = _firstNameCtrl.text.trim();
    final lastName  = _lastNameCtrl.text.trim();
    final phone     = _phoneCtrl.text.trim();

    if (firstName.isEmpty) {
      _showError('الاسم الأول مطلوب');
      return;
    }

    setState(() => _isSaving = true);

    final data = <String, dynamic>{
      'firstName': firstName,
      'lastName': lastName,
      if (phone.isNotEmpty) 'phoneNumber': phone,
      if (_faculty     != null) 'universityName': _faculty,
      if (_year        != null) 'studyYear':      _year,
      if (_governorate != null) 'cityName':       _governorate,
      if (_category    != null) 'categoryName':   _category,
    };

    try {
      final result = await _apiService.updateDoctor(data);

      if (!mounted) return;

      if (result['success'] == true) {
        // ── تحديث SharedPreferences ──────────────────────────
        await SharedPrefHelper.setData('first_name',  firstName);
        await SharedPrefHelper.setData('last_name',   lastName);
        if (phone.isNotEmpty)        await SharedPrefHelper.setData('phone',       phone);
        if (_faculty    != null)     await SharedPrefHelper.setData('faculty',     _faculty!);
        if (_year       != null)     await SharedPrefHelper.setData('year',        _year!);
        if (_governorate != null)    await SharedPrefHelper.setData('governorate', _governorate!);
        if (_category   != null)     await SharedPrefHelper.setData('category',    _category!);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ تم تحديث البيانات بنجاح', style: TextStyle(fontFamily: 'Cairo')),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
          // إرجاع true للصفحة السابقة لتعرف إن فيه تحديث
          Navigator.of(context).pop(true);
        }
      } else {
        _showError(result['error']?.toString() ?? 'فشل في التحديث');
      }
    } on Exception catch (e) {
      _showError('خطأ في الاتصال: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('❌ $msg', style: const TextStyle(fontFamily: 'Cairo')),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ── UI Helpers ────────────────────────────────────────────────
  Widget _buildField(String label, TextEditingController ctrl, {TextInputType keyboardType = TextInputType.text, bool isRtl = true}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: ctrl,
        keyboardType: keyboardType,
        textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
        style: const TextStyle(fontFamily: 'Cairo'),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontFamily: 'Cairo'),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFD1D5DB))),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: ColorsManager.mainBlue, width: 2)),
          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          filled: true,
          fillColor: const Color(0xFFF9FAFB),
        ),
      ),
    );
  }

  Widget _buildDropdown(String label, String? value, List<String> items, ValueChanged<String?> onChanged) {
    // فلترة القيمة لو مش موجودة في القائمة
    final safeValue = (value != null && items.contains(value)) ? value : null;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontFamily: 'Cairo'),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFD1D5DB))),
          contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
          filled: true,
          fillColor: const Color(0xFFF9FAFB),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: safeValue,
            hint: items.isEmpty
                ? const Text('جاري التحميل...', style: TextStyle(fontFamily: 'Cairo', color: Colors.grey))
                : Text('اختر $label', style: const TextStyle(fontFamily: 'Cairo', color: Colors.grey)),
            isExpanded: true,
            icon: const Icon(Icons.arrow_drop_down),
            style: const TextStyle(fontFamily: 'Cairo', color: Colors.black87, fontSize: 14),
            onChanged: items.isEmpty ? null : onChanged,
            items: items.map((v) => DropdownMenuItem(value: v, child: Text(v, style: const TextStyle(fontFamily: 'Cairo')))).toList(),
          ),
        ),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        centerTitle: true,
        title: const Text('تعديل الملف الشخصي', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 18)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(false),
        ),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(14),
              child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else
            TextButton(
              onPressed: _save,
              child: Text('حفظ', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 16, color: ColorsManager.mainBlue)),
            ),
        ],
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(height: 1, color: const Color(0xFFE5E7EB))),
      ),
      body: _loadingRef
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: width * 0.05, vertical: 20),
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Avatar placeholder
                    Center(
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 46,
                            backgroundColor: Colors.grey[200],
                            child: const Icon(Icons.person, size: 56, color: Colors.grey),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(color: ColorsManager.mainBlue, shape: BoxShape.circle),
                              child: const Icon(Icons.camera_alt_outlined, size: 16, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── Section: البيانات الشخصية ──────────────────
                    _sectionLabel('البيانات الشخصية'),
                    _buildField('الاسم الأول',  _firstNameCtrl),
                    _buildField('اسم العائلة',   _lastNameCtrl),
                    _buildField('رقم الهاتف',    _phoneCtrl, keyboardType: TextInputType.phone),

                    const SizedBox(height: 8),

                    // ── Section: البيانات الأكاديمية ───────────────
                    _sectionLabel('البيانات الأكاديمية'),
                    _buildDropdown('الكلية',          _faculty,     _colleges,    (v) => setState(() => _faculty    = v)),
                    _buildDropdown('الفرقة الدراسية', _year,        _studyYears,  (v) => setState(() => _year       = v)),

                    const SizedBox(height: 8),

                    // ── Section: التخصص والموقع ────────────────────
                    _sectionLabel('التخصص والموقع'),
                    _buildDropdown('المحافظة', _governorate, _governorates, (v) => setState(() => _governorate = v)),
                    _buildDropdown('التخصص',   _category,    _categories,   (v) => setState(() => _category    = v)),

                    const SizedBox(height: 32),

                    // ── Save button ────────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ColorsManager.mainBlue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        child: _isSaving
                            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text('حفظ التغييرات', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _sectionLabel(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4, top: 8),
      child: Text(title, style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF6B7280))),
    );
  }
}
