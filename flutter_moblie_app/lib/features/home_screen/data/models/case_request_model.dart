class CaseRequestModel {
  final int? id;
  final int? doctorId;
  final String doctorFirstName;
  final String doctorLastName;
  final String doctorPhoneNumber;
  final String doctorCityName;
  final String doctorUniversityName;
  final String categoryName;
  final String description;
  final String dateTime; // raw ISO string e.g. "2026-03-10T21:12:00"

  CaseRequestModel({
    this.id,
    this.doctorId,
    required this.doctorFirstName,
    required this.doctorLastName,
    required this.doctorPhoneNumber,
    required this.doctorCityName,
    required this.doctorUniversityName,
    required this.categoryName,
    required this.description,
    required this.dateTime,
  });

  /// Full doctor name helper
  String get doctorFullName => '$doctorFirstName $doctorLastName'.trim();

  /// Returns the date part formatted as "10/03/2026"
  String get formattedDate {
    try {
      final dt = DateTime.parse(dateTime);
      return '${dt.day.toString().padLeft(2, '0')}/'
          '${dt.month.toString().padLeft(2, '0')}/'
          '${dt.year}';
    } catch (_) {
      return dateTime;
    }
  }

  /// Returns the time part as "HH:mm"
  String get formattedTime {
    try {
      final dt = DateTime.parse(dateTime);
      return '${dt.hour.toString().padLeft(2, '0')}:'
          '${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }

  factory CaseRequestModel.fromJson(Map<String, dynamic> json) {
    final did = json['doctorId'] ?? json['doctor_id'];
    return CaseRequestModel(
      id: json['id'] as int?,
      doctorId: did is int ? did : (int.tryParse(did?.toString() ?? '')),
      doctorFirstName: json['doctorFirstName'] as String? ?? '',
      doctorLastName: json['doctorLastName'] as String? ?? '',
      doctorPhoneNumber: json['doctorPhoneNumber'] as String? ?? '',
      doctorCityName: json['doctorCityName'] as String? ?? '',
      doctorUniversityName: json['doctorUniversityName'] as String? ?? '',
      categoryName: json['categoryName'] as String? ?? '',
      description: json['description'] as String? ?? '',
      dateTime: json['dateTime'] as String? ?? '',
    );
  }
}
