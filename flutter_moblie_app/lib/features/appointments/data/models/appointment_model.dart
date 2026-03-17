import 'package:equatable/equatable.dart';

class AppointmentModel extends Equatable {
  final String? patientId;
  final String? firstName;
  final String? lastName;
  final String? phone;
  final String? requestId;
  final String? id;
  final String? createdAt;
  final String? updatedAt;
  final String? status;

  const AppointmentModel({
    this.patientId,
    this.firstName,
    this.lastName,
    this.phone,
    this.requestId,
    this.id,
    this.createdAt,
    this.updatedAt,
    this.status,
  });

  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    return AppointmentModel(
      patientId: json['PatientId']?.toString() ?? json['patientId']?.toString(),
      firstName: json['FirstName']?.toString() ?? json['firstName']?.toString(),
      lastName: json['LastName']?.toString() ?? json['lastName']?.toString(),
      phone: json['Phone']?.toString() ?? json['phone']?.toString(),
      requestId: json['RequestId']?.toString() ?? json['requestId']?.toString(),
      id: json['id']?.toString() ?? json['AppointmentId']?.toString() ?? json['appointmentId']?.toString() ?? json['Id']?.toString(),
      createdAt: json['CreatedAt']?.toString() ?? json['createdAt']?.toString() ?? json['created_at']?.toString(),
      updatedAt: json['UpdatedAt']?.toString() ?? json['updatedAt']?.toString() ?? json['updated_at']?.toString(),
      status: json['Status']?.toString() ?? json['status']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'PatientId': patientId,
      'FirstName': firstName,
      'LastName': lastName,
      'Phone': phone,
      'RequestId': requestId,
      'id': id,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'status': status,
    };
  }

  String get patientFullName => '${firstName ?? ''} ${lastName ?? ''}'.trim();
  String get patientPhoneNumber => phone ?? '';

  String get displayStatus {
    switch (status?.toLowerCase()) {
      case 'confirmed':
      case 'مؤكد':
        return 'مؤكد';
      case 'pending':
      case 'قيد الانتظار':
        return 'قيد الانتظار';
      case 'cancelled':
      case 'ملغي':
        return 'ملغي';
      default:
        return status ?? 'قيد الانتظار';
    }
  }

  AppointmentModel copyWith({
    String? patientId,
    String? firstName,
    String? lastName,
    String? phone,
    String? requestId,
    String? id,
    String? createdAt,
    String? updatedAt,
    String? status,
  }) {
    return AppointmentModel(
      patientId: patientId ?? this.patientId,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phone: phone ?? this.phone,
      requestId: requestId ?? this.requestId,
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      status: status ?? this.status,
    );
  }

  @override
  List<Object?> get props => [
        patientId,
        firstName,
        lastName,
        phone,
        requestId,
        id,
        createdAt,
        updatedAt,
        status,
      ];
}
