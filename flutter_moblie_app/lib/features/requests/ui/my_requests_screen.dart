import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:thotha_mobile_app/core/di/dependency_injection.dart';
import 'package:thotha_mobile_app/core/theming/colors.dart';
import 'package:thotha_mobile_app/features/requests/data/models/case_request_model.dart';
import 'package:thotha_mobile_app/features/requests/logic/my_requests_cubit.dart';
import 'package:thotha_mobile_app/features/requests/logic/my_requests_state.dart';
import 'package:thotha_mobile_app/features/doctor/ui/doctor_home_screen.dart';

// ── Entry point ──────────────────────────────────────────────────────────────

/// Injects [MyRequestsCubit] and kicks off the initial fetch immediately.
class MyRequestsScreen extends StatelessWidget {
  const MyRequestsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<MyRequestsCubit>()..loadRequests(),
      child: const _MyRequestsView(),
    );
  }
}

// ── View ─────────────────────────────────────────────────────────────────────

class _MyRequestsView extends StatelessWidget {
  const _MyRequestsView();

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final baseFontSize = width * 0.04;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocConsumer<MyRequestsCubit, MyRequestsState>(
      // ── Listener: side-effects only (snackbars) ──────────────────────────
      listenWhen: (_, current) =>
          current is MyRequestsDeleteSuccess ||
          current is MyRequestsDeleteError,
      listener: (context, state) {
        if (state is MyRequestsDeleteSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'تم حذف الطلب بنجاح',
                style: TextStyle(fontFamily: 'Cairo'),
              ),
              backgroundColor: Colors.green,
            ),
          );
        } else if (state is MyRequestsDeleteError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                state.message,
                style: const TextStyle(fontFamily: 'Cairo'),
              ),
              backgroundColor: Colors.red[700],
            ),
          );
        }
      },
      // ── Builder: rebuild the Scaffold on every state change ──────────────
      builder: (context, state) {
        return Scaffold(
          appBar: _buildAppBar(context, baseFontSize),
          body: Directionality(
            textDirection: TextDirection.rtl,
            child: _buildBody(
              context,
              state,
              baseFontSize,
              width,
              isDark,
            ),
          ),
        );
      },
    );
  }

  // ── AppBar ─────────────────────────────────────────────────────────────────

  AppBar _buildAppBar(BuildContext context, double baseFontSize) {
    return AppBar(
      title: Text(
        'طلباتي',
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
        onPressed: () {
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                settings: const RouteSettings(name: 'doctor-home'),
                builder: (_) => const DoctorHomeScreen(),
              ),
            );
          }
        },
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.home_rounded),
          tooltip: 'الرئيسية',
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                settings: const RouteSettings(name: 'doctor-home'),
                builder: (_) => const DoctorHomeScreen(),
              ),
              (route) => false,
            );
          },
        ),
      ],
    );
  }

  // ── Body dispatcher ────────────────────────────────────────────────────────

  Widget _buildBody(
    BuildContext context,
    MyRequestsState state,
    double baseFontSize,
    double width,
    bool isDark,
  ) {
    // Loading / initial
    if (state is MyRequestsInitial || state is MyRequestsLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Error
    if (state is MyRequestsError) {
      return _buildError(context, state, baseFontSize);
    }

    // Empty list (404 or all items deleted)
    if (state is MyRequestsEmpty) {
      return _buildEmpty(context, baseFontSize, width);
    }

    // Success / delete result — extract whichever list is present
    final requests = _requestsFromState(state);
    if (requests == null || requests.isEmpty) {
      return _buildEmpty(context, baseFontSize, width);
    }

    return RefreshIndicator(
      onRefresh: () => context.read<MyRequestsCubit>().loadRequests(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: requests.length,
        itemBuilder: (_, index) => _buildRequestCard(
          context,
          requests[index],
          width,
          baseFontSize,
          isDark,
        ),
      ),
    );
  }

  /// Extracts the request list from any list-bearing state, or returns null.
  List<CaseRequestModel>? _requestsFromState(MyRequestsState state) {
    if (state is MyRequestsSuccess) return state.requests;
    if (state is MyRequestsDeleteSuccess) return state.requests;
    if (state is MyRequestsDeleteError) return state.requests;
    return null;
  }

  // ── Empty state ────────────────────────────────────────────────────────────

  Widget _buildEmpty(
    BuildContext context,
    double baseFontSize,
    double width,
  ) {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.inbox_outlined,
                size: 72 * (width / 390),
                color: Colors.grey[300],
              ),
              const SizedBox(height: 20),
              Text(
                'لا توجد طلبات حالياً',
                style: TextStyle(
                  fontSize: baseFontSize * 1.2,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600],
                  fontFamily: 'Cairo',
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'لم يتم العثور على أي طلبات مسجلة لحسابك',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: baseFontSize * 0.9,
                  color: Colors.grey[400],
                  fontFamily: 'Cairo',
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorsManager.mainBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                onPressed: () =>
                    context.read<MyRequestsCubit>().loadRequests(),
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text(
                  'تحديث',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Error state ────────────────────────────────────────────────────────────

  Widget _buildError(
    BuildContext context,
    MyRequestsError state,
    double baseFontSize,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                state.isServerError
                    ? Icons.cloud_off_rounded
                    : state.isAuthError
                        ? Icons.lock_outline_rounded
                        : Icons.error_outline_rounded,
                size: 40,
                color: Colors.redAccent,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              state.isServerError
                  ? 'خطأ في الخادم'
                  : state.isAuthError
                      ? 'تسجيل الدخول مطلوب'
                      : 'حدث خطأ',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: baseFontSize * 1.2,
                fontWeight: FontWeight.bold,
                color: Colors.redAccent,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              state.message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: baseFontSize * 0.9,
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            if (!state.isAuthError)
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorsManager.mainBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                onPressed: () =>
                    context.read<MyRequestsCubit>().loadRequests(),
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text(
                  'إعادة المحاولة',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Request card ──────────────────────────────────────────────────────────

  Widget _buildRequestCard(
    BuildContext context,
    CaseRequestModel req,
    double width,
    double baseFontSize,
    bool isDark,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header row: category + id badge + delete ──────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    req.categoryName,
                    style: TextStyle(
                      fontSize: baseFontSize * 1.125,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ),
                Row(
                  children: [
                    if (req.id != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color:
                              ColorsManager.mainBlue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '#${req.id}',
                          style: TextStyle(
                            color: ColorsManager.mainBlue,
                            fontSize: baseFontSize * 0.75,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Cairo',
                          ),
                        ),
                      ),
                    const SizedBox(width: 8),
                    Material(
                      color: Colors.red.withValues(alpha: 0.08),
                      shape: const CircleBorder(),
                      child: IconButton(
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          color: Colors.red,
                          size: 20,
                        ),
                        tooltip: 'حذف الطلب',
                        onPressed: () =>
                            _confirmAndDelete(context, req),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),

            // ── Doctor name ───────────────────────────────────────────────
            Row(children: [
              Icon(Icons.person_outline, size: 14, color: Colors.grey[500]),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  req.doctorFullName,
                  style: TextStyle(
                    fontSize: baseFontSize * 0.875,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    fontFamily: 'Cairo',
                  ),
                ),
              ),
            ]),

            // ── City ──────────────────────────────────────────────────────
            if (req.doctorCityName.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(children: [
                Icon(Icons.location_on_outlined,
                    size: 14, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    req.doctorCityName,
                    style: TextStyle(
                      fontSize: baseFontSize * 0.875,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                      fontFamily: 'Cairo',
                    ),
                  ),
                ),
              ]),
            ],

            const SizedBox(height: 16),

            // ── Date / time chips ─────────────────────────────────────────
            Row(children: [
              _buildInfoChip(
                icon: Icons.calendar_today,
                text: req.formattedDate,
                baseFontSize: baseFontSize,
                isDark: isDark,
              ),
              const SizedBox(width: 12),
              _buildInfoChip(
                icon: Icons.access_time,
                text: req.formattedTime,
                baseFontSize: baseFontSize,
                isDark: isDark,
              ),
            ]),

            // ── Description ───────────────────────────────────────────────
            if (req.description.isNotEmpty &&
                req.description != 'No details') ...[
              const SizedBox(height: 12),
              Text(
                req.description,
                style: TextStyle(
                  fontSize: baseFontSize * 0.875,
                  color: isDark ? Colors.grey[200] : Colors.grey[800],
                  fontFamily: 'Cairo',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Info chip ─────────────────────────────────────────────────────────────

  Widget _buildInfoChip({
    required IconData icon,
    required String text,
    required double baseFontSize,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: ColorsManager.mainBlue),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: baseFontSize * 0.75,
              color: isDark ? Colors.grey[200] : Colors.grey[800],
              fontFamily: 'Cairo',
            ),
          ),
        ],
      ),
    );
  }

  // ── Delete flow ───────────────────────────────────────────────────────────

  /// Shows a confirmation dialog then delegates deletion to [MyRequestsCubit].
  /// A loading overlay is shown while the request is in-flight.
  Future<void> _confirmAndDelete(
    BuildContext context,
    CaseRequestModel req,
  ) async {
    final cubit = context.read<MyRequestsCubit>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'حذف الطلب',
            style:
                TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700),
          ),
          content: const Text(
            'هل أنت متأكد من حذف هذا الطلب؟',
            style: TextStyle(fontFamily: 'Cairo'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text(
                'إلغاء',
                style: TextStyle(fontFamily: 'Cairo', color: Colors.grey),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text(
                'حذف',
                style: TextStyle(fontFamily: 'Cairo', color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true || !context.mounted) return;

    // Show blocking loading overlay during the DELETE request
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    await cubit.deleteRequest(req);

    if (context.mounted) Navigator.pop(context); // dismiss the overlay
  }
}
