import 'package:freezed_annotation/freezed_annotation.dart';

part 'doctor_profile_model.freezed.dart';
part 'doctor_profile_model.g.dart';

Object? readFirstName(Map json, String key) => json['first_name'] ?? json['firstName'];
Object? readLastName(Map json, String key) => json['last_name'] ?? json['lastName'];
Object? readPhone(Map json, String key) {
  final keys = ['phone', 'tel', 'telephone', 'phone_number', 'mobile', 'phoneNumber'];
  for (var k in keys) {
    if (json[k] != null && json[k].toString().isNotEmpty && !json[k].toString().contains('@')) return json[k];
  }
  return null;
}
Object? readGov(Map json, String key) => json['governorate'] ?? json['governorate_id'];
Object? readCat(Map json, String key) => json['category'] ?? json['specialty'] ?? json['specialization'];

@freezed
abstract class DoctorProfileModel with _$DoctorProfileModel {
  const factory DoctorProfileModel({
    int? id,
    String? firstName,
    @JsonKey(readValue: readLastName) String? lastName,
    String? email,
    @JsonKey(readValue: readPhone) String? phone,
    String? faculty,
    String? year,
    @JsonKey(readValue: readGov) String? governorate,
    @JsonKey(readValue: readCat) String? category,
  }) = _DoctorProfileModel;

  factory DoctorProfileModel.fromJson(Map<String, dynamic> json) => _$DoctorProfileModelFromJson(json);
}
