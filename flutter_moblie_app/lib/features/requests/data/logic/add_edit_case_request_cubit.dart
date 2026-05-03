import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:thoutha_mobile_app/features/requests/data/repos/case_request_repo.dart';
import 'package:thoutha_mobile_app/features/requests/data/logic/add_edit_case_request_state.dart';

import 'package:thoutha_mobile_app/features/requests/data/models/case_request_body.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;

class AddEditCaseRequestCubit extends Cubit<AddEditCaseRequestState> {
  final CaseRequestRepo _repo;

  AddEditCaseRequestCubit(this._repo)
      : super(AddEditCaseRequestState.initial());

  Future<void> emitPublishRequest({
    required String description,
    required String dateTime,
    int? requestId,
  }) async {
    emit(AddEditCaseRequestState.loading());

    // Validate inputs
    if (description.trim().isEmpty && dateTime.trim().isEmpty) {
      emit(AddEditCaseRequestState.error(
          message: 'requests.please_fill_in_the'.tr()));
      return;
    }

    final body = CaseRequestBody(
      description: description.trim().isEmpty
          ? 'requests.there_are_no_additional'.tr()
          : description.trim(),
      dateTime: dateTime.trim(),
    );

    // Call update if requestId is provided, otherwise create new
    final result = requestId != null
        ? await _repo.updateCaseRequest(requestId, body)
        : await _repo.createCaseRequest(body);

    if (result['success'] == true) {
      emit(AddEditCaseRequestState.success());
    } else {
      emit(AddEditCaseRequestState.error(
          message: result['error']?.toString() ?? 'requests.failed_to_process_the'.tr()));
    }
  }
}
