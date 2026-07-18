import '../core/utils/enum_localization.dart';

class AcademicYearModel {
  final String? academicId;
  final String academicYear;
  final String startDate;
  final String endDate;
  final String academicStatus;

  const AcademicYearModel({
    this.academicId,
    required this.academicYear,
    required this.startDate,
    required this.endDate,
    this.academicStatus = 'ດໍາເນີນການ',
  });

  factory AcademicYearModel.fromJson(Map<String, dynamic> json) {
    return AcademicYearModel(
      academicId: json['academic_id'] as String?,
      academicYear: json['academic_year'] as String? ?? '',
      startDate: json['start_date_at'] as String? ?? '',
      endDate: json['end_date_at'] as String? ?? '',
      academicStatus: localizeAcademicStatus(
        json['status'] as String? ?? 'ACTIVE',
      ),
    );
  }

  dynamic operator [](String key) {
    switch (key) {
      case 'id':
      case 'academicId':
        return academicId ?? '';
      case 'academicYear':
        return academicYear;
      case 'startDate':
        return startDate;
      case 'endDate':
        return endDate;
      case 'academicStatus':
        return academicStatus;
      case 'status':
        return apiAcademicStatus(academicStatus);
      default:
        return null;
    }
  }
}

class AcademicYearRequest {
  final String academicYear;
  final String startDate;
  final String endDate;
  final String academicStatus;

  const AcademicYearRequest({
    required this.academicYear,
    required this.startDate,
    required this.endDate,
    required this.academicStatus,
  });

  Map<String, dynamic> toJson() => {
    'academic_year': academicYear,
    'start_date_at': startDate,
    'end_date_at': endDate,
    'status': apiAcademicStatus(academicStatus),
  };
}

class AcademicYearListResponse {
  final String code;
  final String messages;
  final List<AcademicYearModel> data;

  const AcademicYearListResponse({
    required this.code,
    required this.messages,
    required this.data,
  });

  factory AcademicYearListResponse.fromJson(Map<String, dynamic> json) {
    return AcademicYearListResponse(
      code: json['code'] as String,
      messages: json['messages'] as String,
      data: (json['data'] as List)
          .map((e) => AcademicYearModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class AcademicYearSingleResponse {
  final String code;
  final String messages;
  final AcademicYearModel data;

  const AcademicYearSingleResponse({
    required this.code,
    required this.messages,
    required this.data,
  });

  factory AcademicYearSingleResponse.fromJson(Map<String, dynamic> json) {
    return AcademicYearSingleResponse(
      code: json['code'] as String,
      messages: json['messages'] as String,
      data: AcademicYearModel.fromJson(json['data'] as Map<String, dynamic>),
    );
  }
}
