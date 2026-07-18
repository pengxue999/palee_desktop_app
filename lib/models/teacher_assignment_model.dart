class TeacherAssignmentModel {
  final String assignmentId;
  final String teacherId;
  final String subjectDetailId;
  final String academicId;
  final String teacherName;
  final String teacherLastname;
  final String subjectName;
  final String levelName;
  final String academicYear;
  final double hourlyRate;

  const TeacherAssignmentModel({
    required this.assignmentId,
    required this.teacherId,
    required this.subjectDetailId,
    required this.academicId,
    required this.teacherName,
    required this.teacherLastname,
    required this.subjectName,
    required this.levelName,
    required this.academicYear,
    required this.hourlyRate,
  });

  String get teacherFullName => '$teacherName $teacherLastname';
  String get subjectLabel => '$subjectName - $levelName';

  dynamic operator [](String key) {
    switch (key) {
      case 'assignmentId':
        return assignmentId;
      case 'teacherId':
        return teacherId;
      case 'subjectDetailId':
        return subjectDetailId;
      case 'academicId':
        return academicId;
      case 'teacherFullName':
        return teacherFullName;
      case 'subjectLabel':
        return subjectLabel;
      case 'academicYear':
        return academicYear;
      case 'hourlyRate':
        return hourlyRate;
      default:
        return null;
    }
  }

  factory TeacherAssignmentModel.fromJson(Map<String, dynamic> json) {
    return TeacherAssignmentModel(
      assignmentId: json['assignment_id'] as String,
      teacherId: json['teacher_id'] as String,
      subjectDetailId: json['subject_detail_id'] as String? ?? '',
      academicId: json['academic_id'] as String? ?? '',
      teacherName: json['teacher_name'] as String,
      teacherLastname: json['teacher_lastname'] as String,
      subjectName: json['subject_name'] as String,
      levelName: json['level_name'] as String,
      academicYear: json['academic_year'] as String,
      hourlyRate: double.tryParse(json['hourly_rate']?.toString() ?? '0') ?? 0,
    );
  }
}

class TeacherAssignmentRequest {
  final String teacherId;
  final String subjectDetailId;
  final String academicId;
  final double hourlyRate;

  const TeacherAssignmentRequest({
    required this.teacherId,
    required this.subjectDetailId,
    required this.academicId,
    required this.hourlyRate,
  });

  Map<String, dynamic> toJson() => {
    'teacher_id': teacherId,
    'subject_detail_id': subjectDetailId,
    'academic_id': academicId,
    'hourly_rate': hourlyRate,
  };
}

class TeacherAssignmentBatchItemRequest {
  final String subjectDetailId;
  final double hourlyRate;

  const TeacherAssignmentBatchItemRequest({
    required this.subjectDetailId,
    required this.hourlyRate,
  });

  Map<String, dynamic> toJson() => {
    'subject_detail_id': subjectDetailId,
    'hourly_rate': hourlyRate,
  };
}

class TeacherAssignmentBatchRequest {
  final String teacherId;
  final String academicId;
  final List<TeacherAssignmentBatchItemRequest> assignments;

  const TeacherAssignmentBatchRequest({
    required this.teacherId,
    required this.academicId,
    required this.assignments,
  });

  Map<String, dynamic> toJson() => {
    'teacher_id': teacherId,
    'academic_id': academicId,
    'assignments': assignments.map((item) => item.toJson()).toList(),
  };
}

class TeacherAssignmentResponse {
  final String code;
  final String messages;
  final List<TeacherAssignmentModel> data;

  const TeacherAssignmentResponse({
    required this.code,
    required this.messages,
    required this.data,
  });

  factory TeacherAssignmentResponse.fromJson(Map<String, dynamic> json) {
    return TeacherAssignmentResponse(
      code: json['code'] as String,
      messages: json['messages'] as String,
      data: (json['data'] as List)
          .map(
            (e) => TeacherAssignmentModel.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
    );
  }
}

class TeacherAssignmentSingleResponse {
  final String code;
  final String messages;
  final TeacherAssignmentModel data;

  const TeacherAssignmentSingleResponse({
    required this.code,
    required this.messages,
    required this.data,
  });

  factory TeacherAssignmentSingleResponse.fromJson(Map<String, dynamic> json) {
    return TeacherAssignmentSingleResponse(
      code: json['code'] as String,
      messages: json['messages'] as String,
      data: TeacherAssignmentModel.fromJson(
        json['data'] as Map<String, dynamic>,
      ),
    );
  }
}
