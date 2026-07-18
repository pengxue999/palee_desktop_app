import '../core/utils/enum_localization.dart';

class EvaluationScoreEntryStudent {
  final int regisDetailId;
  final String registrationId;
  final String studentId;
  final String studentName;
  final String studentLastname;
  final String fullName;
  final String? gender;
  final String? studentContact;
  final String? parentsContact;
  final String? school;
  final String? districtName;
  final String? provinceName;
  final String subjectDetailId;
  final String subjectId;
  final String subjectName;
  final double feeAmount;
  final double? score;
  final int? ranking;
  final double? prize;

  const EvaluationScoreEntryStudent({
    required this.regisDetailId,
    required this.registrationId,
    required this.studentId,
    required this.studentName,
    required this.studentLastname,
    required this.fullName,
    this.gender,
    this.studentContact,
    this.parentsContact,
    this.school,
    this.districtName,
    this.provinceName,
    required this.subjectDetailId,
    required this.subjectId,
    required this.subjectName,
    required this.feeAmount,
    this.score,
    this.ranking,
    this.prize,
  });

  factory EvaluationScoreEntryStudent.fromJson(Map<String, dynamic> json) {
    return EvaluationScoreEntryStudent(
      regisDetailId: json['regis_detail_id'] as int? ?? 0,
      registrationId: json['registration_id'] as String? ?? '',
      studentId: json['student_id'] as String? ?? '',
      studentName: json['student_name'] as String? ?? '',
      studentLastname: json['student_lastname'] as String? ?? '',
      fullName: json['full_name'] as String? ?? '',
      gender: json['gender'] == null
          ? null
          : localizeGender(json['gender'] as String?),
      studentContact: json['student_contact'] as String?,
      parentsContact: json['parents_contact'] as String?,
      school: json['school'] as String?,
      districtName: json['district_name'] as String?,
      provinceName: json['province_name'] as String?,
      subjectDetailId: json['subject_detail_id'] as String? ?? '',
      subjectId: json['subject_id'] as String? ?? '',
      subjectName: json['subject_name'] as String? ?? '',
      feeAmount: _toDouble(json['fee_amount']) ?? 0,
      score: _toDouble(json['score']),
      ranking: _toInt(json['ranking']),
      prize: _toDouble(json['prize']),
    );
  }

  dynamic operator [](String key) {
    switch (key) {
      case 'studentId':
      case 'student_id':
        return studentId;
      case 'studentName':
      case 'student_name':
        return studentName;
      case 'studentLastname':
      case 'student_lastname':
        return studentLastname;
      case 'fullName':
      case 'full_name':
        return fullName;
      case 'gender':
        return gender;
      case 'studentContact':
      case 'student_contact':
        return studentContact;
      case 'parentsContact':
      case 'parents_contact':
        return parentsContact;
      case 'school':
        return school;
      case 'districtName':
      case 'district_name':
        return districtName;
      case 'provinceName':
      case 'province_name':
        return provinceName;
      case 'subjectName':
      case 'subject_name':
        return subjectName;
      default:
        return null;
    }
  }
}

int? _toInt(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  if (value is String) {
    return int.tryParse(value);
  }
  return null;
}

double? _toDouble(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is num) {
    return value.toDouble();
  }
  if (value is String) {
    return double.tryParse(value);
  }
  return null;
}

class EvaluationScoreEntrySummary {
  final int totalStudents;
  final int enteredStudents;
  final int missingStudents;
  final double? highestScore;
  final double? lowestScore;
  final double? averageScore;

  const EvaluationScoreEntrySummary({
    required this.totalStudents,
    required this.enteredStudents,
    required this.missingStudents,
    this.highestScore,
    this.lowestScore,
    this.averageScore,
  });

  factory EvaluationScoreEntrySummary.fromJson(Map<String, dynamic> json) {
    return EvaluationScoreEntrySummary(
      totalStudents: json['total_students'] as int? ?? 0,
      enteredStudents: json['entered_students'] as int? ?? 0,
      missingStudents: json['missing_students'] as int? ?? 0,
      highestScore: _toDouble(json['highest_score']),
      lowestScore: _toDouble(json['lowest_score']),
      averageScore: _toDouble(json['average_score']),
    );
  }
}

class EvaluationScoreSheet {
  final String? academicId;
  final String? academicYear;
  final String semester;
  final String levelId;
  final String levelName;
  final String subjectDetailId;
  final String subjectId;
  final String subjectName;
  final String? evaluationId;
  final String? evaluationDate;
  final EvaluationScoreEntrySummary summary;
  final List<EvaluationScoreEntryStudent> students;

  const EvaluationScoreSheet({
    required this.academicId,
    required this.academicYear,
    required this.semester,
    required this.levelId,
    required this.levelName,
    required this.subjectDetailId,
    required this.subjectId,
    required this.subjectName,
    required this.evaluationId,
    required this.evaluationDate,
    required this.summary,
    required this.students,
  });

  factory EvaluationScoreSheet.fromJson(Map<String, dynamic> json) {
    return EvaluationScoreSheet(
      academicId: json['academic_id'] as String?,
      academicYear: json['academic_year'] as String?,
      semester: localizeSemester(json['semester'] as String?),
      levelId: json['level_id'] as String? ?? '',
      levelName: json['level_name'] as String? ?? '',
      subjectDetailId: json['subject_detail_id'] as String? ?? '',
      subjectId: json['subject_id'] as String? ?? '',
      subjectName: json['subject_name'] as String? ?? '',
      evaluationId: json['evaluation_id'] as String?,
      evaluationDate: json['evaluation_date'] as String?,
      summary: EvaluationScoreEntrySummary.fromJson(
        json['summary'] as Map<String, dynamic>? ?? const {},
      ),
      students: (json['students'] as List<dynamic>? ?? const [])
          .map(
            (item) => EvaluationScoreEntryStudent.fromJson(
              item as Map<String, dynamic>,
            ),
          )
          .toList(),
    );
  }
}

class EvaluationScoreUpdateItem {
  final int regisDetailId;
  final double? score;
  final double? prize;

  const EvaluationScoreUpdateItem({
    required this.regisDetailId,
    this.score,
    this.prize,
  });

  Map<String, dynamic> toJson() => {
    'regis_detail_id': regisDetailId,
    'score': score,
    'prize': prize,
  };
}

class EvaluationScoreSheetRequest {
  final String semester;
  final String levelId;
  final String subjectDetailId;
  final List<EvaluationScoreUpdateItem> scores;

  const EvaluationScoreSheetRequest({
    required this.semester,
    required this.levelId,
    required this.subjectDetailId,
    required this.scores,
  });

  Map<String, dynamic> toJson() => {
    'semester': apiSemester(semester),
    'level_id': levelId,
    'subject_detail_id': subjectDetailId,
    'scores': scores.map((item) => item.toJson()).toList(),
  };
}

class EvaluationScoreSubjectOption {
  final String subjectId;
  final String subjectName;

  const EvaluationScoreSubjectOption({
    required this.subjectId,
    required this.subjectName,
  });

  factory EvaluationScoreSubjectOption.fromJson(Map<String, dynamic> json) {
    return EvaluationScoreSubjectOption(
      subjectId: json['subject_id'] as String? ?? '',
      subjectName: json['subject_name'] as String? ?? '',
    );
  }
}

/// ວິຊາ/ລະດັບ ທີ່ອາຈານສອນ ພ້ອມຈຳນວນນັກຮຽນທີ່ລົງທະບຽນແລ້ວ (ສົກຮຽນ ACTIVE).
class TeacherSubjectRegistration {
  final String assignmentId;
  final String subjectDetailId;
  final String subjectId;
  final String subjectName;
  final String levelId;
  final String levelName;
  final int registeredStudents;

  const TeacherSubjectRegistration({
    required this.assignmentId,
    required this.subjectDetailId,
    required this.subjectId,
    required this.subjectName,
    required this.levelId,
    required this.levelName,
    required this.registeredStudents,
  });

  factory TeacherSubjectRegistration.fromJson(Map<String, dynamic> json) {
    return TeacherSubjectRegistration(
      assignmentId: json['assignment_id'] as String? ?? '',
      subjectDetailId: json['subject_detail_id'] as String? ?? '',
      subjectId: json['subject_id'] as String? ?? '',
      subjectName: json['subject_name'] as String? ?? '',
      levelId: json['level_id'] as String? ?? '',
      levelName: json['level_name'] as String? ?? '',
      registeredStudents: _toInt(json['registered_students']) ?? 0,
    );
  }
}

class TeacherSubjectRegistrationListResponse {
  final String code;
  final String messages;
  final List<TeacherSubjectRegistration> data;

  const TeacherSubjectRegistrationListResponse({
    required this.code,
    required this.messages,
    required this.data,
  });

  factory TeacherSubjectRegistrationListResponse.fromJson(
    Map<String, dynamic> json,
  ) {
    return TeacherSubjectRegistrationListResponse(
      code: json['code'] as String? ?? '',
      messages: json['messages'] as String? ?? '',
      data: (json['data'] as List<dynamic>? ?? const [])
          .map(
            (item) => TeacherSubjectRegistration.fromJson(
              item as Map<String, dynamic>,
            ),
          )
          .toList(),
    );
  }
}

class EvaluationScoreLevelOption {
  final String subjectDetailId;
  final String levelId;
  final String levelName;
  final double feeAmount;

  const EvaluationScoreLevelOption({
    required this.subjectDetailId,
    required this.levelId,
    required this.levelName,
    required this.feeAmount,
  });

  factory EvaluationScoreLevelOption.fromJson(Map<String, dynamic> json) {
    return EvaluationScoreLevelOption(
      subjectDetailId: json['subject_detail_id'] as String? ?? '',
      levelId: json['level_id'] as String? ?? '',
      levelName: json['level_name'] as String? ?? '',
      feeAmount: _toDouble(json['fee_amount']) ?? 0,
    );
  }
}

class EvaluationScoreSubjectListResponse {
  final String code;
  final String messages;
  final List<EvaluationScoreSubjectOption> data;

  const EvaluationScoreSubjectListResponse({
    required this.code,
    required this.messages,
    required this.data,
  });

  factory EvaluationScoreSubjectListResponse.fromJson(
    Map<String, dynamic> json,
  ) {
    return EvaluationScoreSubjectListResponse(
      code: json['code'] as String? ?? '',
      messages: json['messages'] as String? ?? '',
      data: (json['data'] as List<dynamic>? ?? const [])
          .map(
            (item) => EvaluationScoreSubjectOption.fromJson(
              item as Map<String, dynamic>,
            ),
          )
          .toList(),
    );
  }
}

class EvaluationScoreLevelListResponse {
  final String code;
  final String messages;
  final List<EvaluationScoreLevelOption> data;

  const EvaluationScoreLevelListResponse({
    required this.code,
    required this.messages,
    required this.data,
  });

  factory EvaluationScoreLevelListResponse.fromJson(Map<String, dynamic> json) {
    return EvaluationScoreLevelListResponse(
      code: json['code'] as String? ?? '',
      messages: json['messages'] as String? ?? '',
      data: (json['data'] as List<dynamic>? ?? const [])
          .map(
            (item) => EvaluationScoreLevelOption.fromJson(
              item as Map<String, dynamic>,
            ),
          )
          .toList(),
    );
  }
}

class EvaluationScoreSheetResponse {
  final String code;
  final String messages;
  final EvaluationScoreSheet data;

  const EvaluationScoreSheetResponse({
    required this.code,
    required this.messages,
    required this.data,
  });

  factory EvaluationScoreSheetResponse.fromJson(Map<String, dynamic> json) {
    return EvaluationScoreSheetResponse(
      code: json['code'] as String? ?? '',
      messages: json['messages'] as String? ?? '',
      data: EvaluationScoreSheet.fromJson(
        json['data'] as Map<String, dynamic>? ?? const {},
      ),
    );
  }
}

class AssessmentReportItem {
  final String evaluationId;
  final int regisDetailId;
  final String academicId;
  final String? academicYear;
  final String semester;
  final String evaluationType;
  final String subjectId;
  final String subjectDetailId;
  final String levelId;
  final String? evaluationDate;
  final String studentId;
  final String studentName;
  final String studentLastname;
  final String fullName;
  final String? provinceName;
  final String? districtName;
  final String subjectName;
  final String levelName;
  final double score;
  final int ranking;
  final double? prize;

  const AssessmentReportItem({
    required this.evaluationId,
    required this.regisDetailId,
    required this.academicId,
    required this.academicYear,
    required this.semester,
    required this.evaluationType,
    required this.subjectId,
    required this.subjectDetailId,
    required this.levelId,
    required this.evaluationDate,
    required this.studentId,
    required this.studentName,
    required this.studentLastname,
    required this.fullName,
    this.provinceName,
    this.districtName,
    required this.subjectName,
    required this.levelName,
    required this.score,
    required this.ranking,
    this.prize,
  });

  factory AssessmentReportItem.fromJson(Map<String, dynamic> json) {
    return AssessmentReportItem(
      evaluationId: json['evaluation_id'] as String? ?? '',
      regisDetailId: _toInt(json['regis_detail_id']) ?? 0,
      academicId: json['academic_id'] as String? ?? '',
      academicYear: json['academic_year'] as String?,
      semester: localizeSemester(json['semester'] as String?),
      evaluationType: localizeSemester(json['evaluation_type'] as String?),
      subjectId: json['subject_id'] as String? ?? '',
      subjectDetailId: json['subject_detail_id'] as String? ?? '',
      levelId: json['level_id'] as String? ?? '',
      evaluationDate: json['evaluation_date'] as String?,
      studentId: json['student_id'] as String? ?? '',
      studentName: json['student_name'] as String? ?? '',
      studentLastname: json['student_lastname'] as String? ?? '',
      fullName: json['full_name'] as String? ?? '',
      provinceName: json['province_name'] as String?,
      districtName: json['district_name'] as String?,
      subjectName: json['subject_name'] as String? ?? '',
      levelName: json['level_name'] as String? ?? '',
      score: _toDouble(json['score']) ?? 0,
      ranking: _toInt(json['ranking']) ?? 0,
      prize: _toDouble(json['prize']),
    );
  }

  dynamic operator [](String key) {
    switch (key) {
      case 'evaluationId':
      case 'evaluation_id':
        return evaluationId;
      case 'academicId':
      case 'academic_id':
        return academicId;
      case 'regisDetailId':
      case 'regis_detail_id':
        return regisDetailId;
      case 'academicYear':
      case 'academic_year':
        return academicYear;
      case 'semester':
        return semester;
      case 'evaluationType':
      case 'evaluation_type':
        return evaluationType;
      case 'studentId':
      case 'student_id':
        return studentId;
      case 'subjectId':
      case 'subject_id':
        return subjectId;
      case 'subjectDetailId':
      case 'subject_detail_id':
        return subjectDetailId;
      case 'levelId':
      case 'level_id':
        return levelId;
      case 'evaluationDate':
      case 'evaluation_date':
        return evaluationDate;
      case 'studentName':
      case 'student_name':
        return studentName;
      case 'studentLastname':
      case 'student_lastname':
        return studentLastname;
      case 'fullName':
      case 'full_name':
        return fullName;
      case 'provinceName':
      case 'province_name':
        return provinceName;
      case 'districtName':
      case 'district_name':
        return districtName;
      case 'subjectName':
      case 'subject_name':
        return subjectName;
      case 'levelName':
      case 'level_name':
        return levelName;
      case 'score':
        return score;
      case 'ranking':
        return ranking;
      case 'prize':
        return prize;
      default:
        return null;
    }
  }
}

class AssessmentReportListResponse {
  final String code;
  final String messages;
  final List<AssessmentReportItem> data;

  const AssessmentReportListResponse({
    required this.code,
    required this.messages,
    required this.data,
  });

  factory AssessmentReportListResponse.fromJson(Map<String, dynamic> json) {
    return AssessmentReportListResponse(
      code: json['code'] as String? ?? '',
      messages: json['messages'] as String? ?? '',
      data: (json['data'] as List<dynamic>? ?? const [])
          .map(
            (item) =>
                AssessmentReportItem.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
    );
  }
}
