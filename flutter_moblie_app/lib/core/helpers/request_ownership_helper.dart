import 'package:flutter/material.dart';
import 'package:thotha_mobile_app/core/helpers/shared_pref_helper.dart';
import 'package:thotha_mobile_app/features/home_screen/data/models/case_request_model.dart';

class RequestOwnershipHelper {
  /// Fetches the current doctor's ID from secure storage
  static Future<int> getCurrentDoctorId() async {
    // Try multiple common keys for doctor_id
    int doctorId = await SharedPrefHelper.getInt('doctor_id');
    if (doctorId == 0) {
      final sId = await SharedPrefHelper.getString('doctor_id');
      doctorId = int.tryParse(sId ?? '') ?? 0;
    }
    return doctorId;
  }

  /// Sync check if the current doctor is the owner of the request
  static bool isRequestOwnerSync(CaseRequestModel request, int currentDoctorId) {
    if (currentDoctorId == 0 || request.doctorId == null) return false;
    return request.doctorId == currentDoctorId;
  }

  /// Async check if the current doctor is the owner of the request
  static Future<bool> isRequestOwner(CaseRequestModel request) async {
    final currentDoctorId = await getCurrentDoctorId();
    return isRequestOwnerSync(request, currentDoctorId);
  }

  /// Builds a widget only if the current doctor is the owner
  static Widget buildOwnerOnlyWidget({
    required CaseRequestModel request,
    required int currentDoctorId,
    required Widget child,
  }) {
    if (isRequestOwnerSync(request, currentDoctorId)) {
      return child;
    }
    return const SizedBox.shrink();
  }

  /// Builds different widgets based on ownership
  static Widget buildConditionalWidget({
    required CaseRequestModel request,
    required int currentDoctorId,
    required Widget ownerWidget,
    Widget nonOwnerWidget = const SizedBox.shrink(),
  }) {
    if (isRequestOwnerSync(request, currentDoctorId)) {
      return ownerWidget;
    }
    return nonOwnerWidget;
  }
}
