import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:thoutha_mobile_app/features/requests/data/repos/case_request_repo.dart';
import 'package:thoutha_mobile_app/features/requests/data/logic/add_edit_case_request_state.dart';

import 'package:thoutha_mobile_app/features/requests/data/models/case_request_body.dart';

class AddEditCaseRequestCubit extends Cubit<AddEditCaseRequestState> {
  final CaseRequestRepo _repo;

  AddEditCaseRequestCubit(this._repo)
      : super(const AddEditCaseRequestState.initial());

  Future<void> emitPublishRequest({
    required String description,
    required String dateTime,
    int? requestId,
  }) async {
    emit(const AddEditCaseRequestState.loading());

    // Validate inputs
    if (description.trim().isEmpty && dateTime.trim().isEmpty) {
      emit(AddEditCaseRequestState.error(
          message: 'يرجى ملء الوصف والتاريخ والوقت'));
      return;
    }

    final body = CaseRequestBody(
      description: description.trim().isEmpty
          ? 'لا توجد تفاصيل إضافية'
          : description.trim(),
      dateTime: dateTime.trim(),
    );

    // Call update if requestId is provided, otherwise create new
    final result = requestId != null
        ? await _repo.updateCaseRequest(requestId, body)
        : await _repo.createCaseRequest(body);

    if (result['success'] == true) {
      emit(const AddEditCaseRequestState.success());
    } else {
      emit(AddEditCaseRequestState.error(
          message: result['error']?.toString() ?? 'فشل في معالجة الطلب'));
    }
  }
}
