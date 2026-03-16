class AppointmentModel {
  final int? id;
  final int? doctorId;
  final String? doctorFirstName;
  final String? doctorLastName;
  final int? patientId;
  final String? patientFirstName;
  final String? patientLastName;
  final String? patientPhoneNumber;
  final String? status;
  final String? createdAt;
  final String? updatedAt;

  AppointmentModel({
    this.id,
    this.doctorId,
    this.doctorFirstName,
    this.doctorLastName,
    this.patientId,
    this.patientFirstName,
    this.patientLastName,
    this.patientPhoneNumber,
    this.status,
    this.createdAt,
    this.updatedAt,
  });

  /// Full doctor name helper
  String get doctorFullName {
    final first = doctorFirstName ?? '';
    final last = doctorLastName ?? '';
    return '$first $last'.trim();
  }

  /// Full patient name helper
  String get patientFullName {
    final first = patientFirstName ?? '';
    final last = patientLastName ?? '';
    return '$first $last'.trim();
  }

  /// Status color helper
  String get displayStatus {
    final s = status?.toLowerCase() ?? 'confirmed';
    if (s == 'confirmed' || s == 'مؤكد') return 'مؤكد';
    if (s == 'pending' || s == 'قيد الانتظار') return 'قيد الانتظار';
    return status ?? 'مؤكد';
  }

  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    return AppointmentModel(
      id: json['id'] as int?,
      doctorId: json['doctorId'] as int?,
      doctorFirstName: json['doctorFirstName'] as String?,
      doctorLastName: json['doctorLastName'] as String?,
      patientId: json['patientId'] as int?,
      patientFirstName: json['patientFirstName'] as String?,
      patientLastName: json['patientLastName'] as String?,
      patientPhoneNumber: json['patientPhoneNumber'] as String?,
      status: json['status'] as String?,
      createdAt: json['createdAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'doctorId': doctorId,
      'doctorFirstName': doctorFirstName,
      'doctorLastName': doctorLastName,
      'patientId': patientId,
      'patientFirstName': patientFirstName,
      'patientLastName': patientLastName,
      'patientPhoneNumber': patientPhoneNumber,
      'status': status,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  AppointmentModel copyWith({
    int? id,
    int? doctorId,
    String? doctorFirstName,
    String? doctorLastName,
    int? patientId,
    String? patientFirstName,
    String? patientLastName,
    String? patientPhoneNumber,
    String? status,
    String? createdAt,
    String? updatedAt,
  }) {
    return AppointmentModel(
      id: id ?? this.id,
      doctorId: doctorId ?? this.doctorId,
      doctorFirstName: doctorFirstName ?? this.doctorFirstName,
      doctorLastName: doctorLastName ?? this.doctorLastName,
      patientId: patientId ?? this.patientId,
      patientFirstName: patientFirstName ?? this.patientFirstName,
      patientLastName: patientLastName ?? this.patientLastName,
      patientPhoneNumber: patientPhoneNumber ?? this.patientPhoneNumber,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
