import '../core/utils/enum_localization.dart';

class StudentModel {
  final String? studentId;
  final String studentName;
  final String studentLastname;
  final String gender;
  final String studentContact;
  final String parentsContact;
  final String school;
  final String districtName;
  final String provinceName;

  const StudentModel({
    this.studentId,
    required this.studentName,
    required this.studentLastname,
    required this.gender,
    required this.studentContact,
    required this.parentsContact,
    required this.school,
    required this.districtName,
    required this.provinceName,
  });

  factory StudentModel.fromJson(Map<String, dynamic> json) {
    return StudentModel(
      studentId: json['student_id'] as String?,
      studentName: json['student_name'] as String,
      studentLastname: json['student_lastname'] as String,
      gender: localizeGender(json['gender'] as String?),
      studentContact: json['student_contact'] as String,
      parentsContact: json['parents_contact'] as String,
      school: json['school'] as String,
      districtName: json['district_name'] as String,
      provinceName: json['province_name'] as String,
    );
  }

  dynamic operator [](String key) {
    switch (key) {
      case 'studentId':
        return studentId ?? '';
      case 'studentName':
        return studentName;
      case 'studentLastname':
        return studentLastname;
      case 'fullName':
        return '$studentName $studentLastname';
      case 'gender':
        return gender;
      case 'studentContact':
        return studentContact;
      case 'parentsContact':
        return parentsContact;
      case 'school':
        return school;
      case 'districtName':
        return districtName;
      case 'provinceName':
        return provinceName;
      default:
        return null;
    }
  }
}

class StudentRequest {
  final String studentName;
  final String studentLastname;
  final String gender;
  final String studentContact;
  final String parentsContact;
  final String school;
  final int districtId;

  const StudentRequest({
    required this.studentName,
    required this.studentLastname,
    required this.gender,
    required this.studentContact,
    required this.parentsContact,
    required this.school,
    required this.districtId,
  });

  Map<String, dynamic> toJson() => {
    'student_name': studentName,
    'student_lastname': studentLastname,
    'gender': apiGender(gender),
    'student_contact': studentContact,
    'parents_contact': parentsContact,
    'school': school,
    'district_id': districtId,
  };
}

class StudentListResponse {
  final String code;
  final String messages;
  final List<StudentModel> data;

  const StudentListResponse({
    required this.code,
    required this.messages,
    required this.data,
  });

  factory StudentListResponse.fromJson(Map<String, dynamic> json) {
    return StudentListResponse(
      code: json['code'] as String,
      messages: json['messages'] as String,
      data: (json['data'] as List)
          .map((e) => StudentModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class StudentSingleResponse {
  final String code;
  final String messages;
  final StudentModel data;

  const StudentSingleResponse({
    required this.code,
    required this.messages,
    required this.data,
  });

  factory StudentSingleResponse.fromJson(Map<String, dynamic> json) {
    return StudentSingleResponse(
      code: json['code'] as String,
      messages: json['messages'] as String,
      data: StudentModel.fromJson(json['data'] as Map<String, dynamic>),
    );
  }
}
