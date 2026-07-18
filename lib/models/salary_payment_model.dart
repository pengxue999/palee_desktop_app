import '../core/utils/enum_localization.dart';

class SalaryPaymentModel {
  final String salaryPaymentId;
  final String teacherId;
  final String teacherName;
  final String teacherLastname;
  final String userName;
  final int year;
  final int month;
  final double totalAmount;
  final String paymentDate;
  final String status;

  const SalaryPaymentModel({
    required this.salaryPaymentId,
    required this.teacherId,
    required this.teacherName,
    required this.teacherLastname,
    required this.userName,
    required this.year,
    required this.month,
    required this.totalAmount,
    required this.paymentDate,
    required this.status,
  });

  String get teacherFullName => '$teacherName $teacherLastname';

  factory SalaryPaymentModel.fromJson(Map<String, dynamic> json) {
    return SalaryPaymentModel(
      salaryPaymentId: json['salary_payment_id'] as String,
      teacherId: json['teacher_id'] as String,
      teacherName: json['teacher_name'] as String,
      teacherLastname: json['teacher_lastname'] as String,
      userName: json['user_name'] as String,
      year: json['year'] as int,
      month: json['month'] as int,
      totalAmount:
          double.tryParse(json['total_amount']?.toString() ?? '0') ?? 0,
      paymentDate: json['payment_date'] as String,
      status: localizeRegistrationStatus(json['status'] as String?),
    );
  }

  dynamic operator [](String key) {
    switch (key) {
      case 'salaryPaymentId':
        return salaryPaymentId;
      case 'teacherId':
        return teacherId;
      case 'teacherName':
        return teacherName;
      case 'teacherLastname':
        return teacherLastname;
      case 'teacherFullName':
        return teacherFullName;
      case 'userName':
        return userName;
      case 'year':
        return year;
      case 'month':
        return month;
      case 'totalAmount':
        return totalAmount;
      case 'paymentDate':
        return paymentDate;
      case 'status':
        return status;
      default:
        return null;
    }
  }
}

class SalaryPaymentRequest {
  final String? salaryPaymentId;
  final String teacherId;
  final int userId;
  final int month;
  final double totalAmount;
  final String paymentDate;
  final String status;

  const SalaryPaymentRequest({
    this.salaryPaymentId,
    required this.teacherId,
    required this.userId,
    required this.month,
    required this.totalAmount,
    required this.paymentDate,
    required this.status,
  });

  Map<String, dynamic> toJson() => {
    if (salaryPaymentId != null) 'salary_payment_id': salaryPaymentId,
    'teacher_id': teacherId,
    'user_id': userId,
    'month': month,
    'total_amount': totalAmount,
    'payment_date': paymentDate,
    'status': apiRegistrationStatus(status),
  };
}

class SalaryPaymentResponse {
  final String code;
  final String messages;
  final List<SalaryPaymentModel> data;

  const SalaryPaymentResponse({
    required this.code,
    required this.messages,
    required this.data,
  });

  factory SalaryPaymentResponse.fromJson(Map<String, dynamic> json) {
    return SalaryPaymentResponse(
      code: json['code'] as String,
      messages: json['messages'] as String,
      data: (json['data'] as List)
          .map((e) => SalaryPaymentModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class SalaryPaymentSingleResponse {
  final String code;
  final String messages;
  final SalaryPaymentModel data;

  const SalaryPaymentSingleResponse({
    required this.code,
    required this.messages,
    required this.data,
  });

  factory SalaryPaymentSingleResponse.fromJson(Map<String, dynamic> json) {
    return SalaryPaymentSingleResponse(
      code: json['code'] as String,
      messages: json['messages'] as String,
      data: SalaryPaymentModel.fromJson(json['data'] as Map<String, dynamic>),
    );
  }
}

class TeachingMonth {
  final int year;
  final int month;
  final String label;
  final int count;

  const TeachingMonth({
    required this.year,
    required this.month,
    required this.label,
    required this.count,
  });

  factory TeachingMonth.fromJson(Map<String, dynamic> json) {
    return TeachingMonth(
      year: json['year'] as int,
      month: json['month'] as int,
      label: json['label'] as String,
      count: json['count'] as int,
    );
  }
}

class TeacherSalaryCalculation {
  final String teacherId;
  final String teacherName;
  final String teacherLastname;
  final String? provinceName;
  final String? districtName;
  final int year;
  final int month;
  final double totalHours;
  final double totalAmount;
  final double plannedHours;
  final double plannedAmount;
  final double hourlyRate;
  final int totalSessions;
  final double totalPaid;
  final double priorDebt;
  final double remainingBalance;

  const TeacherSalaryCalculation({
    required this.teacherId,
    required this.teacherName,
    required this.teacherLastname,
    this.provinceName,
    this.districtName,
    required this.year,
    required this.month,
    required this.totalHours,
    required this.totalAmount,
    this.plannedHours = 0,
    this.plannedAmount = 0,
    required this.hourlyRate,
    required this.totalSessions,
    this.totalPaid = 0,
    this.priorDebt = 0,
    this.remainingBalance = 0,
  });

  String get teacherFullName => '$teacherName $teacherLastname';

  factory TeacherSalaryCalculation.fromJson(Map<String, dynamic> json) {
    return TeacherSalaryCalculation(
      teacherId: json['teacher_id'] as String,
      teacherName: json['teacher_name'] as String,
      teacherLastname: json['teacher_lastname'] as String,
      provinceName: json['province_name'] as String?,
      districtName: json['district_name'] as String?,
      year: json['year'] as int,
      month: json['month'] as int,
      totalHours: double.tryParse(json['total_hours']?.toString() ?? '0') ?? 0,
      totalAmount:
          double.tryParse(json['total_amount']?.toString() ?? '0') ?? 0,
      plannedHours:
          double.tryParse(json['planned_hours']?.toString() ?? '0') ?? 0,
      plannedAmount:
          double.tryParse(json['planned_amount']?.toString() ?? '0') ?? 0,
      hourlyRate: double.tryParse(json['hourly_rate']?.toString() ?? '0') ?? 0,
      totalSessions: json['total_sessions'] as int? ?? 0,
      totalPaid: double.tryParse(json['total_paid']?.toString() ?? '0') ?? 0,
      priorDebt: double.tryParse(json['prior_debt']?.toString() ?? '0') ?? 0,
      remainingBalance:
          double.tryParse(json['remaining_balance']?.toString() ?? '0') ?? 0,
    );
  }
}

class TeacherPaymentSummary {
  final String teacherId;
  final int year;
  final int month;
  final double expectedAmount;
  final double plannedAmount;
  final double totalHours;
  final double hourlyRate;
  final double totalPaid;
  final double priorDebt;
  final double remainingBalance;
  final bool isFullyPaid;

  const TeacherPaymentSummary({
    required this.teacherId,
    required this.year,
    required this.month,
    required this.expectedAmount,
    required this.plannedAmount,
    required this.totalHours,
    required this.hourlyRate,
    required this.totalPaid,
    this.priorDebt = 0,
    required this.remainingBalance,
    required this.isFullyPaid,
  });

  factory TeacherPaymentSummary.fromJson(Map<String, dynamic> json) {
    return TeacherPaymentSummary(
      teacherId: json['teacher_id'] as String,
      year: json['year'] as int,
      month: json['month'] as int,
      expectedAmount:
          double.tryParse(json['expected_amount']?.toString() ?? '0') ?? 0,
      plannedAmount:
          double.tryParse(json['planned_amount']?.toString() ?? '0') ?? 0,
      totalHours: double.tryParse(json['total_hours']?.toString() ?? '0') ?? 0,
      hourlyRate: double.tryParse(json['hourly_rate']?.toString() ?? '0') ?? 0,
      totalPaid: double.tryParse(json['total_paid']?.toString() ?? '0') ?? 0,
      priorDebt: double.tryParse(json['prior_debt']?.toString() ?? '0') ?? 0,
      remainingBalance:
          double.tryParse(json['remaining_balance']?.toString() ?? '0') ?? 0,
      isFullyPaid: json['is_fully_paid'] as bool? ?? false,
    );
  }
}

class TeacherMonthlySummary {
  final String teacherId;
  final String teacherName;
  final String teacherLastname;
  final int year;
  final int month;
  final double totalHours;
  final double totalAmount;
  final double plannedAmount;
  final double hourlyRate;
  final int totalSessions;
  final double totalPaid;
  final double priorDebt;
  final double remainingBalance;

  const TeacherMonthlySummary({
    required this.teacherId,
    required this.teacherName,
    required this.teacherLastname,
    required this.year,
    required this.month,
    required this.totalHours,
    required this.totalAmount,
    required this.plannedAmount,
    required this.hourlyRate,
    required this.totalSessions,
    required this.totalPaid,
    this.priorDebt = 0,
    required this.remainingBalance,
  });

  String get teacherFullName => '$teacherName $teacherLastname';

  String get paymentStatus {
    if (totalPaid <= 0) return 'ຍັງບໍ່ທັນຈ່າຍ';
    if (remainingBalance <= 0) return 'ຈ່າຍແລ້ວ';
    return 'ຈ່າຍບາງສ່ວນ';
  }

  factory TeacherMonthlySummary.fromJson(Map<String, dynamic> json) {
    return TeacherMonthlySummary(
      teacherId: json['teacher_id'] as String,
      teacherName: json['teacher_name'] as String,
      teacherLastname: json['teacher_lastname'] as String,
      year: json['year'] as int,
      month: json['month'] as int,
      totalHours: double.tryParse(json['total_hours']?.toString() ?? '0') ?? 0,
      totalAmount:
          double.tryParse(json['total_amount']?.toString() ?? '0') ?? 0,
      plannedAmount:
          double.tryParse(json['planned_amount']?.toString() ?? '0') ?? 0,
      hourlyRate: double.tryParse(json['hourly_rate']?.toString() ?? '0') ?? 0,
      totalSessions: json['total_sessions'] as int? ?? 0,
      totalPaid: double.tryParse(json['total_paid']?.toString() ?? '0') ?? 0,
      priorDebt: double.tryParse(json['prior_debt']?.toString() ?? '0') ?? 0,
      remainingBalance:
          double.tryParse(json['remaining_balance']?.toString() ?? '0') ?? 0,
    );
  }
}
