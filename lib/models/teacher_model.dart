import '../core/utils/enum_localization.dart';

class TeacherModel {
  final String teacherId;
  final String teacherName;
  final String teacherLastname;
  final String gender;
  final String teacherContact;
  final String districtName;
  final String provinceName;

  const TeacherModel({
    required this.teacherId,
    required this.teacherName,
    required this.teacherLastname,
    required this.gender,
    required this.teacherContact,
    required this.districtName,
    required this.provinceName,
  });

  String get fullName => '$teacherName $teacherLastname';

  dynamic operator [](String key) {
    switch (key) {
      case 'teacherId':
        return teacherId;
      case 'fullName':
        return fullName;
      case 'gender':
        return gender;
      case 'teacherContact':
        return teacherContact;
      case 'districtName':
        return districtName;
      case 'provinceName':
        return provinceName;
      default:
        return null;
    }
  }

  factory TeacherModel.fromJson(Map<String, dynamic> json) {
    return TeacherModel(
      teacherId: json['teacher_id'] as String,
      teacherName: json['teacher_name'] as String,
      teacherLastname: json['teacher_lastname'] as String,
      gender: localizeGender(json['gender'] as String?),
      teacherContact: json['teacher_contact'] as String,
      districtName: json['district_name'] as String,
      provinceName: json['province_name'] as String,
    );
  }
}

class TeacherRequest {
  final String teacherName;
  final String teacherLastname;
  final String gender;
  final String teacherContact;
  final int districtId;

  const TeacherRequest({
    required this.teacherName,
    required this.teacherLastname,
    required this.gender,
    required this.teacherContact,
    required this.districtId,
  });

  Map<String, dynamic> toJson() => {
    'teacher_name': teacherName,
    'teacher_lastname': teacherLastname,
    'gender': apiGender(gender),
    'teacher_contact': teacherContact,
    'district_id': districtId,
  };
}

class TeacherResponse {
  final String code;
  final String messages;
  final List<TeacherModel> data;

  const TeacherResponse({
    required this.code,
    required this.messages,
    required this.data,
  });

  factory TeacherResponse.fromJson(Map<String, dynamic> json) {
    return TeacherResponse(
      code: json['code'] as String,
      messages: json['messages'] as String,
      data: (json['data'] as List)
          .map((e) => TeacherModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class TeacherSingleResponse {
  final String code;
  final String messages;
  final TeacherModel data;

  const TeacherSingleResponse({
    required this.code,
    required this.messages,
    required this.data,
  });

  factory TeacherSingleResponse.fromJson(Map<String, dynamic> json) {
    return TeacherSingleResponse(
      code: json['code'] as String,
      messages: json['messages'] as String,
      data: TeacherModel.fromJson(json['data'] as Map<String, dynamic>),
    );
  }
}
