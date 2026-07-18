import '../core/utils/enum_localization.dart';

class TeachingLogModel {
  final int teachingLogId;
  final String assignmentId;
  final String teacherId;
  final String teacherName;
  final String teacherLastname;
  final String subjectName;
  final String levelName;
  final String academicYear;
  final String? teachingDate;
  final double hourly;
  final double hourlyRate;
  final String? remark;
  final String? status;
  final String? substituteForAssignmentId;
  final String? substituteForTeacherId;
  final String? substituteForTeacherName;
  final String? substituteForTeacherLastname;
  final String? substituteForSubjectName;
  final String? substituteForLevelName;

  const TeachingLogModel({
    required this.teachingLogId,
    required this.assignmentId,
    required this.teacherId,
    required this.teacherName,
    required this.teacherLastname,
    required this.subjectName,
    required this.levelName,
    required this.academicYear,
    this.teachingDate,
    required this.hourly,
    required this.hourlyRate,
    this.remark,
    this.status,
    this.substituteForAssignmentId,
    this.substituteForTeacherId,
    this.substituteForTeacherName,
    this.substituteForTeacherLastname,
    this.substituteForSubjectName,
    this.substituteForLevelName,
  });

  bool get isSubstitute => substituteForAssignmentId != null;
  String get substituteForFullName =>
      '${substituteForTeacherName ?? ''} ${substituteForTeacherLastname ?? ''}'
          .trim();

  String get teacherFullName => '$teacherName $teacherLastname';
  double get totalAmount => hourly * hourlyRate;

  dynamic operator [](String key) {
    switch (key) {
      case 'teachingLogId':
        return teachingLogId;
      case 'assignmentId':
        return assignmentId;
      case 'teacherId':
        return teacherId;
      case 'teacherName':
        return teacherName;
      case 'teacherLastname':
        return teacherLastname;
      case 'subjectName':
        return subjectName;
      case 'levelName':
        return levelName;
      case 'academicYear':
        return academicYear;
      case 'teachingDate':
        return teachingDate;
      case 'hourly':
        return hourly;
      case 'hourlyRate':
        return hourlyRate;
      case 'remark':
        return remark;
      case 'status':
        return status;
      case 'totalAmount':
        return totalAmount;
      case 'teacherFullName':
        return teacherFullName;
      case 'substituteForAssignmentId':
        return substituteForAssignmentId;
      case 'substituteForTeacherName':
        return substituteForTeacherName;
      case 'substituteForSubjectName':
        return substituteForSubjectName;
      case 'isSubstitute':
        return isSubstitute;
      default:
        return null;
    }
  }

  factory TeachingLogModel.fromJson(Map<String, dynamic> json) {
    return TeachingLogModel(
      teachingLogId: json['teaching_log_id'] as int,
      assignmentId: json['assignment_id'] as String,
      teacherId: json['teacher_id'] as String,
      teacherName: json['teacher_name'] as String,
      teacherLastname: json['teacher_lastname'] as String,
      subjectName: json['subject_name'] as String,
      levelName: json['level_name'] as String,
      academicYear: json['academic_year'] as String,
      teachingDate: json['teaching_date'] as String?,
      hourly: double.tryParse(json['hourly']?.toString() ?? '0') ?? 0,
      hourlyRate: double.tryParse(json['hourly_rate']?.toString() ?? '0') ?? 0,
      remark: json['remark'] as String?,
      status: localizeTeachingStatus(json['status'] as String?),
      substituteForAssignmentId:
          json['substitute_for_assignment_id'] as String?,
      substituteForTeacherId: json['substitute_for_teacher_id'] as String?,
      substituteForTeacherName: json['substitute_for_teacher_name'] as String?,
      substituteForTeacherLastname:
          json['substitute_for_teacher_lastname'] as String?,
      substituteForSubjectName: json['substitute_for_subject_name'] as String?,
      substituteForLevelName: json['substitute_for_level_name'] as String?,
    );
  }
}

class TeachingLogRequest {
  final String assignmentId;
  final String? substituteForAssignmentId;
  final double hourly;
  final String? remark;
  final String? status;

  const TeachingLogRequest({
    required this.assignmentId,
    this.substituteForAssignmentId,
    required this.hourly,
    this.remark,
    this.status,
  });

  Map<String, dynamic> toJson() => {
    'assignment_id': assignmentId,
    if (substituteForAssignmentId != null)
      'substitute_for_assignment_id': substituteForAssignmentId,
    'hourly': hourly,
    if (remark != null) 'remark': remark,
    if (status != null) 'status': apiTeachingStatus(status),
  };
}

class TeachingLogResponse {
  final String code;
  final String messages;
  final List<TeachingLogModel> data;

  const TeachingLogResponse({
    required this.code,
    required this.messages,
    required this.data,
  });

  factory TeachingLogResponse.fromJson(Map<String, dynamic> json) {
    return TeachingLogResponse(
      code: json['code'] as String,
      messages: json['messages'] as String,
      data: (json['data'] as List<dynamic>)
          .map((e) => TeachingLogModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class TeachingLogSingleResponse {
  final String code;
  final String messages;
  final TeachingLogModel data;

  const TeachingLogSingleResponse({
    required this.code,
    required this.messages,
    required this.data,
  });

  factory TeachingLogSingleResponse.fromJson(Map<String, dynamic> json) {
    return TeachingLogSingleResponse(
      code: json['code'] as String,
      messages: json['messages'] as String,
      data: TeachingLogModel.fromJson(json['data'] as Map<String, dynamic>),
    );
  }
}
