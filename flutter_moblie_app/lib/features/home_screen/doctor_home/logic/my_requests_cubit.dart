import 'dart:convert';

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
  ///  4. Call GET /api/request/getRequestsByDoctorId?doctorId=<id>.
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

    // ── 2. Resolve doctorId ───────────────────────────────────────────────
    final doctorId = await _resolveDoctorId(token);
    if (doctorId == 0) {
      emit(MyRequestsError(
        'تعذر تحديد هوية الطبيب، يرجى تسجيل الدخول مرة أخرى',
        isAuthError: true,
      ));
      return;
    }

    // ── 3. GET /api/request/getRequestsByDoctorId?doctorId=<id> ──────────
    final result = await _repo.getRequestsByDoctorId(doctorId);

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

  /// Deletes [request] and emits the updated list.
  ///
  /// On success → [MyRequestsDeleteSuccess] (or [MyRequestsEmpty] if last item).
  /// On failure → [MyRequestsDeleteError] (keeps the unchanged list).
  Future<void> deleteRequest(CaseRequestModel request) async {
    final currentList = List<CaseRequestModel>.from(_visibleRequests);

    // Read cached doctorId so the backend can verify ownership
    int doctorId = await SharedPrefHelper.getInt('doctor_id');
    if (doctorId == 0) {
      final s = await SharedPrefHelper.getString('doctor_id');
      doctorId = int.tryParse(s) ?? 0;
    }

    final result = await _repo.deleteRequest(request.id ?? 0, doctorId: doctorId == 0 ? null : doctorId);

    if (result['success'] == true) {
      currentList.removeWhere((r) => r.id == request.id);
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

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Returns the request list from whichever state currently holds one.
  List<CaseRequestModel> get _visibleRequests {
    final s = state;
    if (s is MyRequestsSuccess) return s.requests;
    if (s is MyRequestsDeleteSuccess) return s.requests;
    if (s is MyRequestsDeleteError) return s.requests;
    return [];
  }

  /// Resolves the doctor's numeric ID using three strategies:
  ///  1. SharedPreferences integer (fastest — cached from previous login)
  ///  2. SharedPreferences string
  ///  3. Base64-decoded JWT payload (authoritative — no extra HTTP call)
  Future<int> _resolveDoctorId(String token) async {
    // Strategy 1 – stored as int
    int id = await SharedPrefHelper.getInt('doctor_id');
    if (id != 0) return id;

    // Strategy 2 – stored as string
    final idStr = await SharedPrefHelper.getString('doctor_id');
    id = int.tryParse(idStr) ?? 0;
    if (id != 0) return id;

    // Strategy 3 – decode JWT payload directly (no HTTP call)
    try {
      final parts = token.split('.');
      if (parts.length == 3) {
        String payload = parts[1];
        while (payload.length % 4 != 0) {
          payload += '=';
        }
        final decoded =
            json.decode(utf8.decode(base64Url.decode(payload))) as Map?;
        if (decoded != null) {
          final raw = decoded['id'] ??
              decoded['doctorId'] ??
              decoded['doctor_id'] ??
              decoded['sub'];
          final fromToken = int.tryParse(raw?.toString() ?? '');
          if (fromToken != null && fromToken != 0) {
            await SharedPrefHelper.setData('doctor_id', fromToken);
            return fromToken;
          }
        }
      }
    } catch (_) {}

    return 0;
  }
}
