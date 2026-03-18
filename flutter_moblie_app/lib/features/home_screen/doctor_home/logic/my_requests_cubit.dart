import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:thotha_mobile_app/core/helpers/constants.dart';
import 'package:thotha_mobile_app/core/helpers/shared_pref_helper.dart';
import 'package:thotha_mobile_app/features/home_screen/data/models/case_request_model.dart';
import 'package:thotha_mobile_app/features/home_screen/data/repositories/case_request_repo.dart';
import 'my_requests_state.dart';

/// Manages fetching and deleting the authenticated doctor's requests.
///
/// Call [loadRequests] on creation (cubit..loadRequests() inside BlocProvider).
/// Call [deleteRequest] when the user confirms deletion.
class MyRequestsCubit extends Cubit<MyRequestsState> {
  final CaseRequestRepo _repo;

  MyRequestsCubit(this._repo) : super(MyRequestsInitial());

  // ── Public API ────────────────────────────────────────────────────────────

  /// Fetches all requests for the currently logged-in doctor.
  ///
  /// Flow:
  ///  1. Emit [MyRequestsLoading].
  ///  2. Guard: abort with [MyRequestsError] if JWT token is absent.
  ///  3. Resolve doctorId from SharedPreferences or JWT payload.
  ///  4. Call GET /api/request/getRequestsByDoctorId?doctorId=&lt;id&gt;.
  ///  5. Emit [MyRequestsSuccess], [MyRequestsEmpty], or [MyRequestsError].
  Future<void> loadRequests() async {
    emit(MyRequestsLoading());

    // ── 1. Token guard ────────────────────────────────────────────────────
    final token =
        await SharedPrefHelper.getSecuredString(SharedPrefKeys.userToken);
    if (token == null || token.isEmpty) {
      emit(MyRequestsError(
        'يرجى تسجيل الدخول أولاً للاستمرار',
        isAuthError: true,
      ));
      return;
    }

    // ── 3. GET /api/request/getRequestsByDoctorId ──────────
    final result = await _repo.getRequestsByDoctorId();

    if (result['success'] == true) {
      final requests = List<CaseRequestModel>.from(result['data'] as List);
      emit(requests.isEmpty ? MyRequestsEmpty() : MyRequestsSuccess(requests));
    } else {
      final code = result['statusCode'] as int?;
      if (code == 404) {
        // 404 = no requests found: treat as empty, not an error
        emit(MyRequestsEmpty());
      } else if (code != null && code >= 500) {
        emit(MyRequestsError(
          'خطأ في الخادم، يرجى المحاولة لاحقاً',
          isServerError: true,
        ));
      } else {
        emit(MyRequestsError(
          result['error']?.toString() ?? 'فشل في تحميل الطلبات',
        ));
      }
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Returns the request list from whichever state currently holds one.
  List<CaseRequestModel> get _visibleRequests {
    final s = state;
    if (s is MyRequestsSuccess) return s.requests;
    if (s is MyRequestsDeleteSuccess) return s.requests;
    if (s is MyRequestsDeleteError) return s.requests;
    return [];
  }

  /// Deletes [request] and emits the updated list.
  ///
  /// On success → [MyRequestsDeleteSuccess] (or [MyRequestsEmpty] if last item).
  /// On failure → [MyRequestsDeleteError] (keeps the unchanged list).
  Future<void> deleteRequest(CaseRequestModel request) async {
    final currentList = List<CaseRequestModel>.from(_visibleRequests);

    print('=== deleteRequest Cubit Debug ===');
    print('Total requests before delete: ${currentList.length}');
    print('Deleting request ID: ${request.id}');
    print('Request description: ${request.description}');
    print('All request IDs: ${currentList.map((r) => r.id).toList()}');

    // Read cached doctorId so the backend can verify ownership
    int doctorId = await SharedPrefHelper.getInt('doctor_id');
    if (doctorId == 0) {
      final s = await SharedPrefHelper.getString('doctor_id');
      doctorId = int.tryParse(s) ?? 0;
    }

    print('Doctor ID for deletion: $doctorId');

    final result = await _repo.deleteRequest(request.id ?? 0,
        doctorId: doctorId == 0 ? null : doctorId);

    print('Delete API Result: ${result['success']}');
    print('Delete Error (if any): ${result['error']}');

    if (result['success'] == true) {
      final beforeCount = currentList.length;
      currentList.removeWhere((r) => r.id == request.id);
      final afterCount = currentList.length;
      
      print('Requests removed: ${beforeCount - afterCount}');
      print('Total requests after delete: ${afterCount}');
      
      if (currentList.isEmpty) {
        emit(MyRequestsEmpty());
      } else {
        emit(MyRequestsDeleteSuccess(currentList));
      }
    } else {
      emit(MyRequestsDeleteError(
        result['error']?.toString() ?? 'فشل في حذف الطلب',
        currentList,
      ));
    }
  }
}
