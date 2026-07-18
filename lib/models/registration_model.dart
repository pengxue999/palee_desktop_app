import '../core/utils/enum_localization.dart';

class RegistrationModel {
  final String registrationId;
  final String? studentId;
  final String studentName;
  final String studentLastname;
  final String? provinceName;
  final String? districtName;
  final String? academicId;
  final String academicYear;
  final String? discountDescription;
  final double totalAmount;
  final double finalAmount;
  final double paidAmount;
  final String status;
  final String registrationDate;

  RegistrationModel({
    required this.registrationId,
    this.studentId,
    required this.studentName,
    required this.studentLastname,
    this.provinceName,
    this.districtName,
    this.academicId,
    this.academicYear = '',
    this.discountDescription,
    required this.totalAmount,
    required this.finalAmount,
    this.paidAmount = 0.0,
    required this.status,
    required this.registrationDate,
  });

  factory RegistrationModel.fromJson(Map<String, dynamic> json) {
    double parseAmount(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    return RegistrationModel(
      registrationId: json['registration_id'] as String? ?? '',
      studentId: json['student_id'] as String?,
      studentName: json['student_name'] as String? ?? '',
      studentLastname: json['student_lastname'] as String? ?? '',
      provinceName: json['province_name'] as String?,
      districtName: json['district_name'] as String?,
      academicId: json['academic_id'] as String?,
      academicYear: json['academic_year'] as String? ?? '',
      discountDescription: localizeDiscountDescription(
        json['discount_description'] as String?,
      ),
      totalAmount: parseAmount(json['total_amount']),
      finalAmount: parseAmount(json['final_amount']),
      paidAmount: parseAmount(json['paid_amount']),
      status: localizeRegistrationStatus(json['status'] as String?),
      registrationDate: json['registration_date'] as String? ?? '',
    );
  }

  double get remainingAmount =>
      (finalAmount - paidAmount).clamp(0.0, double.infinity);

  String get studentFullName => '$studentName $studentLastname';

  dynamic operator [](String key) {
    switch (key) {
      case 'registrationId':
        return registrationId;
      case 'studentId':
        return studentId ?? '';
      case 'studentName':
        return studentFullName;
      case 'studentFirstName':
        return studentName;
      case 'studentLastname':
        return studentLastname;
      case 'provinceName':
        return provinceName ?? '-';
      case 'districtName':
        return districtName ?? '-';
      case 'academicId':
        return academicId ?? '';
      case 'academicYear':
        return academicYear;
      case 'discountDescription':
        return discountDescription ?? '-';
      case 'totalAmount':
        return totalAmount;
      case 'finalAmount':
        return finalAmount;
      case 'paidAmount':
        return paidAmount;
      case 'remainingAmount':
        return remainingAmount;
      case 'status':
        return status;
      case 'registrationDate':
        return registrationDate;
      default:
        return null;
    }
  }
}

class RegistrationRequest {
  final String? registrationId;
  final String studentId;
  final String? discountId;
  final double totalAmount;
  final double finalAmount;
  final String status;
  final DateTime registrationDate;

  RegistrationRequest({
    this.registrationId,
    required this.studentId,
    this.discountId,
    required this.totalAmount,
    required this.finalAmount,
    required this.status,
    required this.registrationDate,
  });

  Map<String, dynamic> toJson() => {
    if (registrationId != null) 'registration_id': registrationId,
    'student_id': studentId,
    'discount_id': discountId,
    'total_amount': totalAmount,
    'final_amount': finalAmount,
    'status': apiRegistrationStatus(status),
    'registration_date': registrationDate.toIso8601String(),
  };
}

/// ຜົນຄຳນວນ ສ່ວນຫຼຸດ/ຈຳນວນເງິນ ຈາກ backend (ແຫຼ່ງຄວາມຈິງ).
class RegistrationPreview {
  final double totalAmount;
  final double discountAmount;
  final double finalAmount;
  final String? discountId;
  final String? discountDescription;

  RegistrationPreview({
    required this.totalAmount,
    required this.discountAmount,
    required this.finalAmount,
    this.discountId,
    this.discountDescription,
  });

  factory RegistrationPreview.fromJson(Map<String, dynamic> json) {
    double parseAmount(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    return RegistrationPreview(
      totalAmount: parseAmount(json['total_amount']),
      discountAmount: parseAmount(json['discount_amount']),
      finalAmount: parseAmount(json['final_amount']),
      discountId: json['discount_id'] as String?,
      discountDescription: json['discount_description'] as String?,
    );
  }
}

/// 1 ວິຊາ ໃນການລົງທະບຽນທີ່ມີຢູ່ແລ້ວ (ໃຊ້ສຳລັບ UI ແກ້ໄຂ).
class StudentRegistrationDetail {
  final int regisDetailId;
  final String feeId;
  final String subjectName;
  final String levelName;
  final String scholarship; // API value: SCHOLARSHIP / NO_SCHOLARSHIP
  final double fee;

  StudentRegistrationDetail({
    required this.regisDetailId,
    required this.feeId,
    required this.subjectName,
    required this.levelName,
    required this.scholarship,
    required this.fee,
  });

  factory StudentRegistrationDetail.fromJson(Map<String, dynamic> json) {
    double parseAmount(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    return StudentRegistrationDetail(
      regisDetailId: (json['regis_detail_id'] as num).toInt(),
      feeId: json['fee_id'] as String? ?? '',
      subjectName: json['subject_name'] as String? ?? '-',
      levelName: json['level_name'] as String? ?? '-',
      scholarship: json['scholarship'] as String? ?? 'NO_SCHOLARSHIP',
      fee: parseAmount(json['fee']),
    );
  }
}

/// ການລົງທະບຽນທີ່ມີຢູ່ແລ້ວຂອງນັກຮຽນ ໃນສົກຮຽນ ພ້ອມລາຍວິຊາ.
class StudentRegistration {
  final String registrationId;
  final String studentId;
  final String? academicId;
  final String? academicYear;
  final String? discountId;
  final String? discountDescription;
  final double totalAmount;
  final double finalAmount;
  final double paidAmount;
  final String status;
  final String registrationDate;
  final bool isLocked; // ຈ່າຍແລ້ວ → ແກ້/ລຶບວິຊາເກົ່າບໍ່ໄດ້
  final List<StudentRegistrationDetail> details;

  StudentRegistration({
    required this.registrationId,
    required this.studentId,
    this.academicId,
    this.academicYear,
    this.discountId,
    this.discountDescription,
    required this.totalAmount,
    required this.finalAmount,
    required this.paidAmount,
    required this.status,
    required this.registrationDate,
    required this.isLocked,
    required this.details,
  });

  factory StudentRegistration.fromJson(Map<String, dynamic> json) {
    double parseAmount(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    return StudentRegistration(
      registrationId: json['registration_id'] as String? ?? '',
      studentId: json['student_id'] as String? ?? '',
      academicId: json['academic_id'] as String?,
      academicYear: json['academic_year'] as String?,
      discountId: json['discount_id'] as String?,
      discountDescription: json['discount_description'] as String?,
      totalAmount: parseAmount(json['total_amount']),
      finalAmount: parseAmount(json['final_amount']),
      paidAmount: parseAmount(json['paid_amount']),
      status: json['status'] as String? ?? 'UNPAID',
      registrationDate: json['registration_date'] as String? ?? '',
      isLocked: json['is_locked'] as bool? ?? false,
      details:
          (json['details'] as List?)
              ?.map(
                (e) => StudentRegistrationDetail.fromJson(
                  e as Map<String, dynamic>,
                ),
              )
              .toList() ??
          [],
    );
  }
}

class RegistrationListResponse {
  final String code;
  final String messages;
  final List<RegistrationModel> data;

  RegistrationListResponse({
    required this.code,
    required this.messages,
    required this.data,
  });

  factory RegistrationListResponse.fromJson(Map<String, dynamic> json) {
    return RegistrationListResponse(
      code: json['code'] as String? ?? '',
      messages: json['messages'] as String? ?? '',
      data:
          (json['data'] as List?)
              ?.map(
                (e) => RegistrationModel.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
    );
  }
}

class RegistrationSingleResponse {
  final String code;
  final String messages;
  final RegistrationModel data;

  RegistrationSingleResponse({
    required this.code,
    required this.messages,
    required this.data,
  });

  factory RegistrationSingleResponse.fromJson(Map<String, dynamic> json) {
    return RegistrationSingleResponse(
      code: json['code'] as String? ?? '',
      messages: json['messages'] as String? ?? '',
      data: RegistrationModel.fromJson(json['data'] as Map<String, dynamic>),
    );
  }
}
