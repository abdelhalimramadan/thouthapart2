import 'package:freezed_annotation/freezed_annotation.dart';

part 'add_edit_case_request_state.freezed.dart';

@freezed
class AddEditCaseRequestState with _$AddEditCaseRequestState {
  const factory AddEditCaseRequestState.initial() = _Initial;
  const factory AddEditCaseRequestState.loading() = Loading;
  const factory AddEditCaseRequestState.success() = Success;
  const factory AddEditCaseRequestState.error({required String message}) =
      Error;
}
