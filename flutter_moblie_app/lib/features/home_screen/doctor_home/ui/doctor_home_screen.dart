import 'package:flutter/material.dart';
import '../../../../core/helpers/shared_pref_helper.dart';
import '../../../../core/networking/dio_factory.dart';
import '../../../../core/utils/notification_helper.dart';
import '../drawer/doctor_drawer_screen.dart';
import '../../../notifications/ui/notifications_screen.dart';
import '../../../home_screen/data/models/case_request_model.dart';
import '../../../../core/di/dependency_injection.dart';
import '../../../home_screen/data/repositories/case_request_repo.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DoctorHomeScreen
// ─────────────────────────────────────────────────────────────────────────────
class DoctorHomeScreen extends StatefulWidget {
  const DoctorHomeScreen({super.key});

  @override
  State<DoctorHomeScreen> createState() => _DoctorHomeScreenState();
}

class _DoctorHomeScreenState extends State<DoctorHomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final CaseRequestRepo _caseRepo = getIt<CaseRequestRepo>();

  // ── State ──────────────────────────────────────────────────────
  String? _firstName;
  bool _isLoadingName = true;

  List<CaseRequestModel> _caseRequests = [];
  bool _isLoadingCases = true;
  String? _casesError;

  // ── Lifecycle ──────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    // Run both fetches in parallel — faster startup
    Future.wait([_fetchDoctorName(), _fetchCaseRequests()]);
  }

  // ── Data Fetching ──────────────────────────────────────────────

  /// Fetches the doctor's first name from cache or API, then saves the
  /// doctor's ID if found in the response (useful for the cases screen).
  Future<void> _fetchDoctorName() async {
    try {
      // Try cache first — avoids unnecessary network call
      final cached = await SharedPrefHelper.getString('first_name');
      if (cached.isNotEmpty) {
        if (mounted) setState(() { _firstName = cached; _isLoadingName = false; });
        return;
      }

      final dio = DioFactory.getDio();
      dynamic response;

      // Try /me then /profile as fallback
      for (final path in ['/me', '/profile']) {
        try {
          response = await dio.get(path);
          if ((response?.statusCode ?? 0) == 200) break;
        } catch (_) {}
      }

      if (response != null && response.statusCode == 200) {
        final data = response.data;
        if (data is Map) {
          // Extract first name (supports top-level or nested under 'user')
          final nested = data['user'];
          String? fn = (data['firstName'] ?? data['first_name'])?.toString();
          if ((fn == null || fn.isEmpty) && nested is Map) {
            fn = (nested['firstName'] ?? nested['first_name'])?.toString();
          }

          // Persist first name
          if (fn != null && fn.isNotEmpty) {
            await SharedPrefHelper.setData('first_name', fn);
            if (mounted) setState(() => _firstName = fn);
          }

          // Persist doctor ID for subsequent screens
          final rawId = data['id'] ?? (nested is Map ? nested['id'] : null);
          final did = int.tryParse(rawId?.toString() ?? '');
          if (did != null) await SharedPrefHelper.setData('doctor_id', did);
        }
      }
    } catch (_) {
      // Silently fail — UI shows fallback "دكتور"
    } finally {
      if (mounted) setState(() => _isLoadingName = false);
    }
  }

  Future<void> _fetchCaseRequests() async {
    if (!mounted) return;
    setState(() { _isLoadingCases = true; _casesError = null; });

    try {
      int doctorId = await SharedPrefHelper.getInt('doctor_id');
      if (doctorId == 0) {
        final s = await SharedPrefHelper.getString('doctor_id');
        doctorId = int.tryParse(s) ?? 0;
      }

      if (doctorId == 0) {
        if (mounted) setState(() { _isLoadingCases = false; _casesError = 'تعذر تحديد هوية الطبيب'; });
        return;
      }

      final result = await _caseRepo.getRequestsByDoctorId(doctorId);
      if (!mounted) return;

      if (result['success'] == true) {
        setState(() {
          _caseRequests = List<CaseRequestModel>.from(result['data'] as List);
          _isLoadingCases = false;
        });
      } else {
        setState(() {
          _casesError = result['error']?.toString() ?? 'فشل في تحميل الحالات';
          _isLoadingCases = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() { _isLoadingCases = false; _casesError = 'حدث خطأ غير متوقع'; });
    }
  }

  // ── Actions ────────────────────────────────────────────────────

  void _openCaseDetails(CaseRequestModel req) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CaseDetailsSheet(req: req),
    );
  }

  void _openNotifications() {
    NotificationHelper.hasUnreadNotifications = false;
    Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()))
        .then((_) { if (mounted) setState(() {}); });
  }

  // ── Build ──────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final width        = MediaQuery.of(context).size.width;
    final theme        = Theme.of(context);
    final cs           = theme.colorScheme;
    final tt           = theme.textTheme;
    final baseFontSize = width * 0.04;
    final unreadCount  = NotificationHelper.getUnreadCount();

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      drawer: const DoctorDrawer(),
      appBar: _buildAppBar(width, cs, tt, baseFontSize, unreadCount),
      body: RefreshIndicator(
        onRefresh: _fetchCaseRequests,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildGreeting(width, baseFontSize),
              _buildSectionTitle('حالاتي القادمة', width, baseFontSize),
              _buildCasesSection(width, baseFontSize),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // ── AppBar ─────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar(
    double width,
    ColorScheme cs,
    TextTheme tt,
    double baseFontSize,
    int unreadCount,
  ) {
    return AppBar(
      toolbarHeight: 70,
      elevation: 0,
      backgroundColor: Colors.white,
      foregroundColor: cs.onSurface,
      automaticallyImplyLeading: false,
      leading: Builder(
        builder: (ctx) => IconButton(
          icon: const Icon(Icons.menu, size: 24),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
      ),
      titleSpacing: 0,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/splash-logo.png',
            width: 36 * (width / 390),
            height: 36 * (width / 390),
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 8),
          Text(
            'لوحة التحكم',
            style: tt.titleLarge?.copyWith(
              fontFamily: 'Cairo',
              fontSize: baseFontSize * 1.125,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
      actions: [
        Stack(children: [
          IconButton(
            icon: const Icon(Icons.notifications_none, size: 24),
            onPressed: _openNotifications,
          ),
          if (unreadCount > 0)
            Positioned(
              right: 8, top: 10,
              child: Container(
                width: 16, height: 16,
                decoration: BoxDecoration(color: Theme.of(context).colorScheme.error, shape: BoxShape.circle),
                child: Center(
                  child: Text(
                    unreadCount > 9 ? '9+' : '$unreadCount',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onError,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ]),
        const SizedBox(width: 8),
      ],
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(height: 1, color: Color(0xFFE5E7EB)),
      ),
    );
  }

  // ── Greeting ───────────────────────────────────────────────────
  Widget _buildGreeting(double width, double baseFontSize) {
    return Padding(
      padding: EdgeInsets.fromLTRB(width * 0.05, 20, width * 0.05, 10),
      child: _isLoadingName
          ? const SizedBox(height: 30, child: CircularProgressIndicator(strokeWidth: 2))
          : Text(
              _firstName != null ? 'مرحباً، د/ $_firstName 👋' : 'مرحباً، دكتور 👋',
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: baseFontSize * 1.4,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF111827),
              ),
            ),
    );
  }

  // ── Section title ──────────────────────────────────────────────
  Widget _buildSectionTitle(String title, double width, double baseFontSize) {
    return Padding(
      padding: EdgeInsets.fromLTRB(width * 0.05, 18, width * 0.05, 6),
      child: Align(
        alignment: Alignment.centerRight,
        child: Text(
          title,
          style: TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.w700,
            fontSize: baseFontSize * 1.1,
            color: const Color(0xFF111827),
          ),
        ),
      ),
    );
  }

  // ── Cases section ──────────────────────────────────────────────
  Widget _buildCasesSection(double width, double baseFontSize) {
    if (_isLoadingCases) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_casesError != null) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: width * 0.05, vertical: 16),
        child: Column(
          children: [
            Text(_casesError!, textAlign: TextAlign.center,
                style: const TextStyle(fontFamily: 'Cairo', color: Colors.redAccent)),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _fetchCaseRequests,
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المحاولة', style: TextStyle(fontFamily: 'Cairo')),
            ),
          ],
        ),
      );
    }

    if (_caseRequests.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: width * 0.05, vertical: 40),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.calendar_today_outlined, size: 48, color: Colors.grey[300]),
              const SizedBox(height: 12),
              const Text(
                'لا توجد حالات مسجلة حالياً',
                style: TextStyle(fontFamily: 'Cairo', color: Colors.grey, fontSize: 15),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.only(top: 10, bottom: 8),
      itemCount: _caseRequests.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (_, i) => _CaseCard(
        req: _caseRequests[i],
        width: width,
        baseFontSize: baseFontSize,
        onTap: () => _openCaseDetails(_caseRequests[i]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _CaseCard — stateless, const-safe
// ─────────────────────────────────────────────────────────────────────────────
class _CaseCard extends StatelessWidget {
  final CaseRequestModel req;
  final double width;
  final double baseFontSize;
  final VoidCallback onTap;

  const _CaseCard({
    required this.req,
    required this.width,
    required this.baseFontSize,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: width * 0.04),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 3)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Header: id badge + category
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (req.id != null) _IdBadge(id: req.id!, baseFontSize: baseFontSize),
                Text(
                  req.categoryName,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: baseFontSize,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1D61E7),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            // Doctor name
            Row(children: [
              Icon(Icons.person_outline, size: 14, color: Colors.grey[500]),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  req.doctorFullName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontFamily: 'Cairo', fontSize: baseFontSize * 0.8, color: Colors.grey[600]),
                ),
              ),
            ]),
            // City · University
            if (req.doctorCityName.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(children: [
                Icon(Icons.location_on_outlined, size: 14, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    req.doctorCityName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontFamily: 'Cairo', fontSize: baseFontSize * 0.8, color: Colors.grey[600]),
                  ),
                ),
              ]),
            ],
            // Description (optional)
            if (req.description.isNotEmpty && req.description != 'No details') ...[
              const SizedBox(height: 6),
              Text(
                req.description,
                textAlign: TextAlign.right,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontFamily: 'Cairo', fontSize: baseFontSize * 0.82, color: Colors.grey[700]),
              ),
            ],
            const SizedBox(height: 10),
            // Time + Date chips
            Row(children: [
              _InfoChip(icon: Icons.access_time_outlined,    text: req.formattedTime, baseFontSize: baseFontSize),
              const SizedBox(width: 8),
              _InfoChip(icon: Icons.calendar_today_outlined, text: req.formattedDate, baseFontSize: baseFontSize),
            ]),
          ],
        ),
      ),
    );
  }
}

class _IdBadge extends StatelessWidget {
  final int? id;
  final double baseFontSize;
  const _IdBadge({required this.id, required this.baseFontSize});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFF1D61E7).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '#${id ?? ""}', 
        style: TextStyle(
          fontFamily: 'Cairo',
          fontSize: baseFontSize * 0.68,
          color: const Color(0xFF1D61E7),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String text;
  final double baseFontSize;
  const _InfoChip({required this.icon, required this.text, required this.baseFontSize});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 13, color: const Color(0xFF1D61E7)),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(fontFamily: 'Cairo', fontSize: baseFontSize * 0.72, color: Colors.grey[800])),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _CaseDetailsSheet — bottom sheet as separate widget (no setState bleed)
// ─────────────────────────────────────────────────────────────────────────────
class _CaseDetailsSheet extends StatelessWidget {
  final CaseRequestModel req;
  const _CaseDetailsSheet({required this.req});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(4)),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'تفاصيل الحالة',
            style: TextStyle(fontFamily: 'Cairo', fontSize: 18, fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87),
          ),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 10),
          _DetailRow(icon: Icons.medical_services_outlined, label: 'التخصص',    value: req.categoryName),
          _DetailRow(icon: Icons.person_outline,             label: 'الطبيب',    value: req.doctorFullName),
          _DetailRow(icon: Icons.phone_outlined,             label: 'الهاتف',    value: req.doctorPhoneNumber),
          _DetailRow(icon: Icons.location_on_outlined,       label: 'المدينة',   value: req.doctorCityName),
          _DetailRow(icon: Icons.school_outlined,            label: 'الجامعة',   value: req.doctorUniversityName),
          _DetailRow(icon: Icons.calendar_today_outlined,    label: 'التاريخ',   value: req.formattedDate),
          _DetailRow(icon: Icons.access_time_outlined,       label: 'الوقت',     value: req.formattedTime),
          if (req.description.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[850] : const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                req.description,
                textAlign: TextAlign.right,
                style: TextStyle(fontFamily: 'Cairo', fontSize: 14, color: isDark ? Colors.grey[200] : Colors.grey[800]),
              ),
            ),
          ],
          const SizedBox(height: 20),
          Row(children: [
            Expanded(child: _SheetButton(label: 'رفض الحالة',  color: Colors.red.shade600,   onTap: () => Navigator.pop(context))),
            const SizedBox(width: 12),
            Expanded(child: _SheetButton(label: 'قبول الحالة', color: Colors.green.shade600, onTap: () => Navigator.pop(context))),
          ]),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _DetailRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Flexible(child: Text(value, textAlign: TextAlign.right,
              style: const TextStyle(fontFamily: 'Cairo', fontSize: 14))),
          const SizedBox(width: 8),
          Text('$label:', style: const TextStyle(fontFamily: 'Cairo', fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Icon(icon, size: 18, color: const Color(0xFF1D61E7)),
        ],
      ),
    );
  }
}

class _SheetButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _SheetButton({required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(label, style: const TextStyle(fontFamily: 'Cairo', fontSize: 15, fontWeight: FontWeight.bold)),
    );
  }
}
