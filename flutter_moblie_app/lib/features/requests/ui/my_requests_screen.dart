import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:thoutha_mobile_app/core/di/dependency_injection.dart';
import 'package:thoutha_mobile_app/core/theming/colors.dart';
import 'package:thoutha_mobile_app/features/requests/data/logic/my_requests_cubit.dart';
import 'package:thoutha_mobile_app/features/requests/data/models/case_request_model.dart';
import 'package:thoutha_mobile_app/features/requests/data/logic/my_requests_state.dart';
import 'package:thoutha_mobile_app/features/doctor/ui/doctor_home_screen.dart';

import 'package:thoutha_mobile_app/features/requests/ui/edit_request_screen.dart';

class MyRequestsScreen extends StatelessWidget {
  const MyRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<MyRequestsCubit>()..loadRequests(),
      child: const MyRequestsView(),
    );
  }
}

class MyRequestsView extends StatelessWidget {
  const MyRequestsView({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF121212) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'طلباتي',
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: ColorsManager.mainBlue,
        elevation: 0,
        leading: IconButton(
          icon:
              Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 24.r),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const DoctorHomeScreen()),
            );
          },
        ),
      ),
      body: BlocConsumer<MyRequestsCubit, MyRequestsState>(
        listenWhen: (previous, current) =>
            current is MyRequestsDeleteSuccess ||
            current is MyRequestsDeleteError,
        listener: (context, state) {
          if (state is MyRequestsDeleteSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('تم حذف الطلب بنجاح',
                    style: TextStyle(fontFamily: 'Cairo')),
                backgroundColor: Colors.green.shade600,
                behavior: SnackBarBehavior.floating,
              ),
            );
          } else if (state is MyRequestsDeleteError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message,
                    style: const TextStyle(fontFamily: 'Cairo')),
                backgroundColor: Colors.red.shade600,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        builder: (context, state) {
          return Directionality(
            textDirection: TextDirection.rtl,
            child: _buildBody(context, state),
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, MyRequestsState state) {
    if (state is MyRequestsLoading) {
      return const Center(
          child: CircularProgressIndicator(color: ColorsManager.mainBlue));
    }

    if (state is MyRequestsError) {
      return _buildErrorState(context, state.message);
    }

    if (state is MyRequestsEmpty) {
      return _buildEmptyState(context);
    }

    List<CaseRequestModel>? requests;
    if (state is MyRequestsSuccess) requests = state.requests;
    if (state is MyRequestsDeleteSuccess) requests = state.requests;
    if (state is MyRequestsDeleteError) requests = state.requests;

    if (requests == null || requests.isEmpty) {
      return _buildEmptyState(context);
    }

    return RefreshIndicator(
      onRefresh: () => context.read<MyRequestsCubit>().loadRequests(),
      color: ColorsManager.mainBlue,
      child: ListView.builder(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
        itemCount: requests.length,
        itemBuilder: (context, index) =>
            _RequestCard(request: requests![index]),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_late_outlined,
              size: 80.r, color: Colors.grey.withOpacity(0.5)),
          SizedBox(height: 16.h),
          Text(
            'لا توجد طلبات حالياً',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'ابدأ بإضافة طلباتك لتظهر هنا',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 14.sp,
              color: Colors.grey.shade500,
            ),
          ),
          SizedBox(height: 24.h),
          ElevatedButton(
            onPressed: () => context.read<MyRequestsCubit>().loadRequests(),
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorsManager.mainBlue,
              padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 12.h),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.r)),
            ),
            child: Text(
              'تحديث الصفحة',
              style: TextStyle(
                  fontFamily: 'Cairo', fontSize: 14.sp, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String message) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded,
                size: 60.r, color: Colors.red.shade400),
            SizedBox(height: 16.h),
            Text(
              'حدث خطأ ما',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: Colors.red.shade700,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 14.sp,
                  color: Colors.grey.shade600),
            ),
            SizedBox(height: 24.h),
            ElevatedButton(
              onPressed: () => context.read<MyRequestsCubit>().loadRequests(),
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorsManager.mainBlue,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.r)),
              ),
              child: const Text('إعادة المحاولة',
                  style: TextStyle(fontFamily: 'Cairo', color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  final CaseRequestModel request;
  const _RequestCard({required this.request});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10.r,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Colored Header
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    ColorsManager.mainBlue,
                    ColorsManager.mainBlue.withOpacity(0.8),
                  ],
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.medical_services_outlined,
                      color: Colors.white, size: 20.r),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      request.categoryName,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 15.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Text(
                      '#${request.id}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // City and Doctor
                  Row(
                    children: [
                      _buildInfoIcon(Icons.location_on_rounded,
                          request.doctorCityName, isDark),
                      const Spacer(),
                      _buildInfoIcon(
                          Icons.person, request.doctorFullName, isDark),
                    ],
                  ),

                  SizedBox(height: 16.h),
                  const Divider(height: 1, color: Colors.grey, thickness: 0.1),
                  SizedBox(height: 16.h),

                  // Date and Time
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildDateTimeItem(Icons.calendar_month_rounded,
                          'التاريخ', request.formattedDate, isDark),
                      _buildDateTimeItem(Icons.access_time_filled_rounded,
                          'الوقت', request.formattedTime, isDark),
                    ],
                  ),

                  if (request.description.isNotEmpty &&
                      request.description != 'No details') ...[
                    SizedBox(height: 16.h),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withOpacity(0.05)
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Text(
                        request.description,
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 13.sp,
                          color: isDark
                              ? Colors.grey.shade300
                              : Colors.grey.shade800,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],

                  SizedBox(height: 20.h),

                  // Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _navigateToEdit(context, request),
                          icon: Icon(Icons.edit_note_rounded, size: 20.r),
                          label: const Text('تعديل الطلب',
                              style: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontWeight: FontWeight.bold)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.blue.shade700,
                            side: BorderSide(color: Colors.blue.shade200),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.r)),
                            padding: EdgeInsets.symmetric(vertical: 10.h),
                          ),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _showDeleteDialog(context, request),
                          icon: Icon(Icons.delete_sweep_rounded,
                              size: 20.r, color: Colors.white),
                          label: const Text('حذف الطلب',
                              style: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade400,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.r)),
                            padding: EdgeInsets.symmetric(vertical: 10.h),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoIcon(IconData icon, String text, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16.r, color: ColorsManager.mainBlue),
        SizedBox(width: 4.w),
        Text(
          text,
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 13.sp,
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildDateTimeItem(
      IconData icon, String label, String value, bool isDark) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon,
                size: 14.r, color: ColorsManager.mainBlue.withOpacity(0.7)),
            SizedBox(width: 4.w),
            Text(label,
                style: TextStyle(
                    fontFamily: 'Cairo', fontSize: 11.sp, color: Colors.grey)),
          ],
        ),
        SizedBox(height: 4.h),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 13.sp,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
      ],
    );
  }

  void _navigateToEdit(BuildContext context, CaseRequestModel request) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditRequestScreen(request: request),
      ),
    ).then((result) {
      // Refresh requests list if changes were saved
      if (result == true && context.mounted) {
        context.read<MyRequestsCubit>().loadRequests();
      }
    });
  }

  void _showDeleteDialog(BuildContext context, CaseRequestModel request) {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red.shade600),
              SizedBox(width: 10.w),
              const Text('تأكيد الحذف',
                  style: TextStyle(
                      fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
            ],
          ),
          content: const Text(
            'هل أنت متأكد من رغبتك في حذف هذا الطلب نهائياً؟ لا يمكن التراجع عن هذا الإجراء.',
            style: TextStyle(fontFamily: 'Cairo'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('إلغاء',
                  style: TextStyle(
                      fontFamily: 'Cairo', color: Colors.grey.shade600)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) => const Center(
                      child: CircularProgressIndicator(
                          color: ColorsManager.mainBlue)),
                );
                await context.read<MyRequestsCubit>().deleteRequest(request);
                if (context.mounted) Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r)),
              ),
              child: const Text('حذف الآن',
                  style: TextStyle(fontFamily: 'Cairo', color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}

