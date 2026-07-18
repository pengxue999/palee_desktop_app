class DashboardStatsModel {
  final AcademicYearInfo academicYear;
  final StudentStats students;
  final TeacherStats teachers;
  final IncomeStats income;
  final ExpenseStats expenses;
  final double balance;

  const DashboardStatsModel({
    required this.academicYear,
    required this.students,
    required this.teachers,
    required this.income,
    required this.expenses,
    required this.balance,
  });

  factory DashboardStatsModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;
    return DashboardStatsModel(
      academicYear: AcademicYearInfo.fromJson(data['academic_year'] as Map<String, dynamic>),
      students: StudentStats.fromJson(data['students'] as Map<String, dynamic>),
      teachers: TeacherStats.fromJson(data['teachers'] as Map<String, dynamic>),
      income: IncomeStats.fromJson(data['income'] as Map<String, dynamic>),
      expenses: ExpenseStats.fromJson(data['expenses'] as Map<String, dynamic>),
      balance: (data['balance'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class AcademicYearInfo {
  final String? academicId;
  final String academicYear;
  final String? status;

  const AcademicYearInfo({
    this.academicId,
    required this.academicYear,
    this.status,
  });

  factory AcademicYearInfo.fromJson(Map<String, dynamic> json) {
    return AcademicYearInfo(
      academicId: json['academic_id'] as String?,
      academicYear: json['academic_year'] as String? ?? 'ບໍ່ມີຂໍ້ມູນ',
      status: json['status'] as String?,
    );
  }
}

class StudentStats {
  final int total;
  final int active;

  const StudentStats({
    required this.total,
    required this.active,
  });

  factory StudentStats.fromJson(Map<String, dynamic> json) {
    return StudentStats(
      total: (json['total'] as num?)?.toInt() ?? 0,
      active: (json['active'] as num?)?.toInt() ?? 0,
    );
  }
}

class TeacherStats {
  final int total;
  final int active;

  const TeacherStats({
    required this.total,
    required this.active,
  });

  factory TeacherStats.fromJson(Map<String, dynamic> json) {
    return TeacherStats(
      total: (json['total'] as num?)?.toInt() ?? 0,
      active: (json['active'] as num?)?.toInt() ?? 0,
    );
  }
}

class IncomeStats {
  final double total;
  final double tuition;
  final double donation;
  final double other;

  const IncomeStats({
    required this.total,
    required this.tuition,
    required this.donation,
    required this.other,
  });

  factory IncomeStats.fromJson(Map<String, dynamic> json) {
    return IncomeStats(
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
      tuition: (json['tuition'] as num?)?.toDouble() ?? 0.0,
      donation: (json['donation'] as num?)?.toDouble() ?? 0.0,
      other: (json['other'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class ExpenseStats {
  final double total;
  final double salary;
  final double other;

  const ExpenseStats({
    required this.total,
    required this.salary,
    required this.other,
  });

  factory ExpenseStats.fromJson(Map<String, dynamic> json) {
    return ExpenseStats(
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
      salary: (json['salary'] as num?)?.toDouble() ?? 0.0,
      other: (json['other'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class DashboardStatsResponse {
  final String code;
  final String messages;
  final DashboardStatsModel data;

  const DashboardStatsResponse({
    required this.code,
    required this.messages,
    required this.data,
  });

  factory DashboardStatsResponse.fromJson(Map<String, dynamic> json) {
    return DashboardStatsResponse(
      code: json['code'] as String? ?? 'SUCCESSFULLY',
      messages: json['messages'] as String? ?? '',
      data: DashboardStatsModel.fromJson(json),
    );
  }
}
