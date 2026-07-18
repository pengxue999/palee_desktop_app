import '../core/utils/enum_localization.dart';

class StudentReportItem {
  final String studentId;
  final String studentName;
  final String studentLastname;
  final String fullName;
  final String gender;
  final String studentContact;
  final String parentsContact;
  final String school;
  final String? districtName;
  final String? provinceName;
  final String? scholarshipStatus;

  const StudentReportItem({
    required this.studentId,
    required this.studentName,
    required this.studentLastname,
    required this.fullName,
    required this.gender,
    required this.studentContact,
    required this.parentsContact,
    required this.school,
    this.districtName,
    this.provinceName,
    this.scholarshipStatus,
  });

  factory StudentReportItem.fromJson(Map<String, dynamic> json) {
    return StudentReportItem(
      studentId: json['student_id'] as String,
      studentName: json['student_name'] as String,
      studentLastname: json['student_lastname'] as String,
      fullName: json['full_name'] as String,
      gender: localizeGender(json['gender'] as String?),
      studentContact: json['student_contact'] as String,
      parentsContact: json['parents_contact'] as String,
      school: json['school'] as String,
      districtName: json['district_name'] as String?,
      provinceName: json['province_name'] as String?,
      scholarshipStatus: localizeScholarship(
        json['scholarship_status'] as String?,
      ),
    );
  }

  dynamic operator [](String key) {
    switch (key) {
      case 'studentId':
        return studentId;
      case 'studentName':
        return studentName;
      case 'studentLastname':
        return studentLastname;
      case 'fullName':
        return fullName;
      case 'gender':
        return gender;
      case 'studentContact':
        return studentContact;
      case 'parentsContact':
        return parentsContact;
      case 'school':
        return school;
      case 'districtName':
        return districtName ?? '-';
      case 'provinceName':
        return provinceName ?? '-';
      case 'scholarshipStatus':
        return scholarshipStatus ?? '-';
      default:
        return null;
    }
  }
}

class ReportFilters {
  final String? academicId;
  final String? academicYearName;
  final int? provinceId;
  final String? provinceName;
  final int? districtId;
  final String? districtName;
  final String? scholarship;
  final String? gender;

  const ReportFilters({
    this.academicId,
    this.academicYearName,
    this.provinceId,
    this.provinceName,
    this.districtId,
    this.districtName,
    this.scholarship,
    this.gender,
  });

  factory ReportFilters.fromJson(Map<String, dynamic> json) {
    return ReportFilters(
      academicId: json['academic_id'] as String?,
      academicYearName: json['academic_year_name'] as String?,
      provinceId: json['province_id'] as int?,
      provinceName: json['province_name'] as String?,
      districtId: json['district_id'] as int?,
      districtName: json['district_name'] as String?,
      scholarship: localizeScholarship(json['scholarship'] as String?),
      gender: localizeGender(json['gender'] as String?),
    );
  }
}

class StudentReportResponse {
  final String code;
  final String messages;
  final StudentReportData data;

  const StudentReportResponse({
    required this.code,
    required this.messages,
    required this.data,
  });

  factory StudentReportResponse.fromJson(Map<String, dynamic> json) {
    return StudentReportResponse(
      code: json['code'] as String,
      messages: json['messages'] as String,
      data: StudentReportData.fromJson(json['data'] as Map<String, dynamic>),
    );
  }
}

class StudentReportData {
  final ReportFilters filters;
  final int totalCount;
  final List<StudentReportItem> students;

  const StudentReportData({
    required this.filters,
    required this.totalCount,
    required this.students,
  });

  factory StudentReportData.fromJson(Map<String, dynamic> json) {
    return StudentReportData(
      filters: ReportFilters.fromJson(json['filters'] as Map<String, dynamic>),
      totalCount: json['total_count'] as int,
      students: (json['students'] as List)
          .map((e) => StudentReportItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class ExportReportResponse {
  final String code;
  final String messages;
  final ExportReportData data;

  const ExportReportResponse({
    required this.code,
    required this.messages,
    required this.data,
  });

  factory ExportReportResponse.fromJson(Map<String, dynamic> json) {
    return ExportReportResponse(
      code: json['code'] as String,
      messages: json['messages'] as String,
      data: ExportReportData.fromJson(json['data'] as Map<String, dynamic>),
    );
  }
}

class ExportReportData {
  final String filename;
  final String contentType;
  final String data;
  final int totalRecords;

  const ExportReportData({
    required this.filename,
    required this.contentType,
    required this.data,
    required this.totalRecords,
  });

  factory ExportReportData.fromJson(Map<String, dynamic> json) {
    return ExportReportData(
      filename: json['filename'] as String,
      contentType: json['content_type'] as String,
      data: json['data'] as String,
      totalRecords: json['total_records'] as int,
    );
  }
}

class StudentSummaryResponse {
  final String code;
  final String messages;
  final StudentSummaryData data;

  const StudentSummaryResponse({
    required this.code,
    required this.messages,
    required this.data,
  });

  factory StudentSummaryResponse.fromJson(Map<String, dynamic> json) {
    return StudentSummaryResponse(
      code: json['code'] as String,
      messages: json['messages'] as String,
      data: StudentSummaryData.fromJson(json['data'] as Map<String, dynamic>),
    );
  }
}

class StudentSummaryData {
  final int totalStudents;
  final Map<String, int> byGender;
  final Map<String, int> byScholarship;
  final Map<String, int> byProvince;
  final Map<String, int> byDistrict;

  const StudentSummaryData({
    required this.totalStudents,
    required this.byGender,
    required this.byScholarship,
    required this.byProvince,
    required this.byDistrict,
  });

  factory StudentSummaryData.fromJson(Map<String, dynamic> json) {
    return StudentSummaryData(
      totalStudents: json['total_students'] as int,
      byGender: localizeGenderStats(
        Map<String, int>.from(json['by_gender'] as Map),
      ),
      byScholarship: localizeScholarshipStats(
        Map<String, int>.from(json['by_scholarship'] as Map),
      ),
      byProvince: Map<String, int>.from(json['by_province'] as Map),
      byDistrict: Map<String, int>.from(json['by_district'] as Map),
    );
  }
}

class TeacherAttendanceReportItem {
  final String teacherId;
  final String teacherName;
  final String teacherLastname;
  final String fullName;
  final String subjectName;
  final String levelName;
  final String academicYear;
  final String? teachingDate;
  final String? status;
  final double hourly;
  final double hourlyRate;
  final double totalAmount;
  final String? remark;
  final bool isSubstitute;
  final String? substituteForTeacherName;
  final String? substituteForTeacherLastname;
  final String? substituteForSubjectName;

  const TeacherAttendanceReportItem({
    required this.teacherId,
    required this.teacherName,
    required this.teacherLastname,
    required this.fullName,
    required this.subjectName,
    required this.levelName,
    required this.academicYear,
    this.teachingDate,
    this.status,
    required this.hourly,
    required this.hourlyRate,
    required this.totalAmount,
    this.remark,
    required this.isSubstitute,
    this.substituteForTeacherName,
    this.substituteForTeacherLastname,
    this.substituteForSubjectName,
  });

  factory TeacherAttendanceReportItem.fromJson(Map<String, dynamic> json) {
    return TeacherAttendanceReportItem(
      teacherId: json['teacher_id'] as String,
      teacherName: json['teacher_name'] as String,
      teacherLastname: json['teacher_lastname'] as String,
      fullName: json['full_name'] as String,
      subjectName: json['subject_name'] as String,
      levelName: json['level_name'] as String,
      academicYear: json['academic_year'] as String,
      teachingDate: json['teaching_date'] as String?,
      status: localizeTeachingStatus(json['status'] as String?),
      hourly: double.tryParse(json['hourly']?.toString() ?? '0') ?? 0,
      hourlyRate: double.tryParse(json['hourly_rate']?.toString() ?? '0') ?? 0,
      totalAmount:
          double.tryParse(json['total_amount']?.toString() ?? '0') ?? 0,
      remark: json['remark'] as String?,
      isSubstitute: json['is_substitute'] == true || json['is_substitute'] == 1,
      substituteForTeacherName: json['substitute_for_teacher_name'] as String?,
      substituteForTeacherLastname:
          json['substitute_for_teacher_lastname'] as String?,
      substituteForSubjectName: json['substitute_for_subject_name'] as String?,
    );
  }

  dynamic operator [](String key) {
    switch (key) {
      case 'teacherId':
        return teacherId;
      case 'teacherName':
        return teacherName;
      case 'teacherLastname':
        return teacherLastname;
      case 'fullName':
        return fullName;
      case 'subjectName':
        return subjectName;
      case 'levelName':
        return levelName;
      case 'academicYear':
        return academicYear;
      case 'teachingDate':
        return teachingDate ?? '-';
      case 'status':
        return status ?? 'ຂື້ນສອນ';
      case 'hourly':
        return hourly;
      case 'hourlyRate':
        return hourlyRate;
      case 'totalAmount':
        return totalAmount;
      case 'remark':
        return remark ?? '-';
      case 'isSubstitute':
        return isSubstitute ? 'ໃຊ່' : 'ບໍ່ໃຊ່';
      case 'substituteForTeacherName':
        return substituteForTeacherName ?? '-';
      case 'substituteForSubjectName':
        return substituteForSubjectName ?? '-';
      default:
        return null;
    }
  }
}

class TeacherAttendanceFilters {
  final String? academicId;
  final String? academicYearName;
  final String? month;
  final String? status;
  final String? teacherId;

  const TeacherAttendanceFilters({
    this.academicId,
    this.academicYearName,
    this.month,
    this.status,
    this.teacherId,
  });

  factory TeacherAttendanceFilters.fromJson(Map<String, dynamic> json) {
    return TeacherAttendanceFilters(
      academicId: json['academic_id'] as String?,
      academicYearName: json['academic_year_name'] as String?,
      month: json['month'] as String?,
      status: localizeTeachingStatus(json['status'] as String?),
      teacherId: json['teacher_id'] as String?,
    );
  }
}

class TeacherAttendanceSummary {
  final int totalRecords;
  final int presentCount;
  final int absentCount;
  final double totalHours;
  final double totalAmount;
  final Map<String, int> byTeacher;
  final Map<String, int> bySubject;
  final Map<String, int> byStatus;

  const TeacherAttendanceSummary({
    required this.totalRecords,
    required this.presentCount,
    required this.absentCount,
    required this.totalHours,
    required this.totalAmount,
    required this.byTeacher,
    required this.bySubject,
    required this.byStatus,
  });

  factory TeacherAttendanceSummary.fromJson(Map<String, dynamic> json) {
    return TeacherAttendanceSummary(
      totalRecords: json['total_records'] as int,
      presentCount: json['present_count'] as int,
      absentCount: json['absent_count'] as int,
      totalHours: double.tryParse(json['total_hours']?.toString() ?? '0') ?? 0,
      totalAmount:
          double.tryParse(json['total_amount']?.toString() ?? '0') ?? 0,
      byTeacher: Map<String, int>.from(json['by_teacher'] as Map),
      bySubject: Map<String, int>.from(json['by_subject'] as Map),
      byStatus: localizeTeachingStatusStats(
        Map<String, int>.from(json['by_status'] as Map),
      ),
    );
  }
}

class TeacherAttendanceReportResponse {
  final String code;
  final String messages;
  final TeacherAttendanceReportData data;

  const TeacherAttendanceReportResponse({
    required this.code,
    required this.messages,
    required this.data,
  });

  factory TeacherAttendanceReportResponse.fromJson(Map<String, dynamic> json) {
    return TeacherAttendanceReportResponse(
      code: json['code'] as String,
      messages: json['messages'] as String,
      data: TeacherAttendanceReportData.fromJson(
        json['data'] as Map<String, dynamic>,
      ),
    );
  }
}

class TeacherAttendanceReportData {
  final TeacherAttendanceFilters filters;
  final int totalCount;
  final List<TeacherAttendanceReportItem> records;
  final TeacherAttendanceSummary? summary;

  const TeacherAttendanceReportData({
    required this.filters,
    required this.totalCount,
    required this.records,
    this.summary,
  });

  factory TeacherAttendanceReportData.fromJson(Map<String, dynamic> json) {
    return TeacherAttendanceReportData(
      filters: TeacherAttendanceFilters.fromJson(
        json['filters'] as Map<String, dynamic>,
      ),
      totalCount: json['total_count'] as int,
      records: (json['records'] as List)
          .map(
            (e) =>
                TeacherAttendanceReportItem.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
      summary: json['summary'] != null
          ? TeacherAttendanceSummary.fromJson(
              json['summary'] as Map<String, dynamic>,
            )
          : null,
    );
  }
}

class FinanceSummary {
  final double totalIncome;
  final double totalExpense;
  final double balance;

  const FinanceSummary({
    required this.totalIncome,
    required this.totalExpense,
    required this.balance,
  });

  factory FinanceSummary.fromJson(Map<String, dynamic> json) {
    return FinanceSummary(
      totalIncome:
          double.tryParse(json['total_income']?.toString() ?? '0') ?? 0,
      totalExpense:
          double.tryParse(json['total_expense']?.toString() ?? '0') ?? 0,
      balance: double.tryParse(json['balance']?.toString() ?? '0') ?? 0,
    );
  }
}

class FinanceBreakdownItem {
  final String category;
  final double amount;
  final double percentage;

  const FinanceBreakdownItem({
    required this.category,
    required this.amount,
    required this.percentage,
  });

  factory FinanceBreakdownItem.fromJson(Map<String, dynamic> json) {
    return FinanceBreakdownItem(
      category: json['category'] as String,
      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0,
      percentage: double.tryParse(json['percentage']?.toString() ?? '0') ?? 0,
    );
  }
}

class YearlyFinanceData {
  final int year;
  final double income;
  final double expense;
  final double balance;

  const YearlyFinanceData({
    required this.year,
    required this.income,
    required this.expense,
    required this.balance,
  });

  factory YearlyFinanceData.fromJson(Map<String, dynamic> json) {
    return YearlyFinanceData(
      year: json['year'] as int,
      income: double.tryParse(json['income']?.toString() ?? '0') ?? 0,
      expense: double.tryParse(json['expense']?.toString() ?? '0') ?? 0,
      balance: double.tryParse(json['balance']?.toString() ?? '0') ?? 0,
    );
  }
}

class FinanceFilters {
  final String? academicId;
  final String? academicYearName;
  final int? year;

  const FinanceFilters({this.academicId, this.academicYearName, this.year});

  factory FinanceFilters.fromJson(Map<String, dynamic> json) {
    return FinanceFilters(
      academicId: json['academic_id'] as String?,
      academicYearName: json['academic_year_name'] as String?,
      year: json['year'] as int?,
    );
  }
}

class FinanceReportData {
  final FinanceFilters filters;
  final FinanceSummary summary;
  final List<FinanceBreakdownItem> incomeBreakdown;
  final List<FinanceBreakdownItem> expenseBreakdown;
  final List<YearlyFinanceData> yearlyComparison;
  final List<FinanceIncomeItem> incomes;
  final List<FinanceExpenseItem> expenses;
  final int totalIncomeCount;
  final int totalExpenseCount;

  const FinanceReportData({
    required this.filters,
    required this.summary,
    required this.incomeBreakdown,
    required this.expenseBreakdown,
    required this.yearlyComparison,
    required this.incomes,
    required this.expenses,
    required this.totalIncomeCount,
    required this.totalExpenseCount,
  });

  factory FinanceReportData.fromJson(Map<String, dynamic> json) {
    return FinanceReportData(
      filters: FinanceFilters.fromJson(json['filters'] as Map<String, dynamic>),
      summary: FinanceSummary.fromJson(json['summary'] as Map<String, dynamic>),
      incomeBreakdown: (json['income_breakdown'] as List)
          .map((e) => FinanceBreakdownItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      expenseBreakdown: (json['expense_breakdown'] as List)
          .map((e) => FinanceBreakdownItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      yearlyComparison: (json['yearly_comparison'] as List)
          .map((e) => YearlyFinanceData.fromJson(e as Map<String, dynamic>))
          .toList(),
      incomes: (json['incomes'] as List)
          .map((e) => FinanceIncomeItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      expenses: (json['expenses'] as List)
          .map((e) => FinanceExpenseItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalIncomeCount: json['total_income_count'] as int,
      totalExpenseCount: json['total_expense_count'] as int,
    );
  }
}

class FinanceIncomeItem {
  final int incomeId;
  final double amount;
  final String? description;
  final String? incomeDate;
  final String source;

  const FinanceIncomeItem({
    required this.incomeId,
    required this.amount,
    this.description,
    this.incomeDate,
    required this.source,
  });

  factory FinanceIncomeItem.fromJson(Map<String, dynamic> json) {
    return FinanceIncomeItem(
      incomeId: json['income_id'] as int,
      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0,
      description: json['description'] as String?,
      incomeDate: json['income_date'] as String?,
      source: json['source'] as String,
    );
  }

  dynamic operator [](String key) {
    switch (key) {
      case 'incomeId':
        return incomeId;
      case 'amount':
        return amount;
      case 'description':
        return description ?? '-';
      case 'incomeDate':
        return incomeDate ?? '-';
      case 'source':
        return source;
      default:
        return null;
    }
  }
}

class FinanceExpenseItem {
  final int expenseId;
  final double amount;
  final String? description;
  final String? expenseDate;
  final String category;

  const FinanceExpenseItem({
    required this.expenseId,
    required this.amount,
    this.description,
    this.expenseDate,
    required this.category,
  });

  factory FinanceExpenseItem.fromJson(Map<String, dynamic> json) {
    return FinanceExpenseItem(
      expenseId: json['expense_id'] as int,
      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0,
      description: json['description'] as String?,
      expenseDate: json['expense_date'] as String?,
      category: json['category'] as String,
    );
  }

  dynamic operator [](String key) {
    switch (key) {
      case 'expenseId':
        return expenseId;
      case 'amount':
        return amount;
      case 'description':
        return description ?? '-';
      case 'expenseDate':
        return expenseDate ?? '-';
      case 'category':
        return category;
      default:
        return null;
    }
  }
}

class FinanceReportResponse {
  final String code;
  final String messages;
  final FinanceReportData data;

  const FinanceReportResponse({
    required this.code,
    required this.messages,
    required this.data,
  });

  factory FinanceReportResponse.fromJson(Map<String, dynamic> json) {
    return FinanceReportResponse(
      code: json['code'] as String,
      messages: json['messages'] as String,
      data: FinanceReportData.fromJson(json['data'] as Map<String, dynamic>),
    );
  }
}

class PopularSubjectItem {
  final String subjectName;
  final String subjectCategory;
  final int studentCount;
  final int levelCount;
  final double avgFee;
  final double percentage;

  const PopularSubjectItem({
    required this.subjectName,
    required this.subjectCategory,
    required this.studentCount,
    required this.levelCount,
    required this.avgFee,
    required this.percentage,
  });

  factory PopularSubjectItem.fromJson(Map<String, dynamic> json) {
    return PopularSubjectItem(
      subjectName: json['subject_name'] as String,
      subjectCategory: json['subject_category'] as String,
      studentCount: json['student_count'] as int,
      levelCount: json['level_count'] as int,
      avgFee: double.tryParse(json['avg_fee']?.toString() ?? '0') ?? 0,
      percentage: double.tryParse(json['percentage']?.toString() ?? '0') ?? 0,
    );
  }

  dynamic operator [](String key) {
    switch (key) {
      case 'subjectName':
        return subjectName;
      case 'subjectCategory':
        return subjectCategory;
      case 'studentCount':
        return studentCount;
      case 'levelCount':
        return levelCount;
      case 'avgFee':
        return avgFee;
      case 'percentage':
        return percentage;
      default:
        return null;
    }
  }
}

class LevelStatsItem {
  final String subjectName;
  final String subjectCategory;
  final String levelName;
  final int studentCount;
  final double feeAmount;

  const LevelStatsItem({
    required this.subjectName,
    required this.subjectCategory,
    required this.levelName,
    required this.studentCount,
    required this.feeAmount,
  });

  factory LevelStatsItem.fromJson(Map<String, dynamic> json) {
    return LevelStatsItem(
      subjectName: json['subject_name'] as String,
      subjectCategory: json['subject_category'] as String,
      levelName: json['level_name'] as String,
      studentCount: json['student_count'] as int,
      feeAmount: double.tryParse(json['fee_amount']?.toString() ?? '0') ?? 0,
    );
  }

  dynamic operator [](String key) {
    switch (key) {
      case 'subjectName':
        return subjectName;
      case 'subjectCategory':
        return subjectCategory;
      case 'levelName':
        return levelName;
      case 'studentCount':
        return studentCount;
      case 'feeAmount':
        return feeAmount;
      default:
        return null;
    }
  }
}

class PopularSubjectsSummary {
  final int totalStudents;
  final int totalSubjects;
  final int totalCategories;

  const PopularSubjectsSummary({
    required this.totalStudents,
    required this.totalSubjects,
    required this.totalCategories,
  });

  factory PopularSubjectsSummary.fromJson(Map<String, dynamic> json) {
    return PopularSubjectsSummary(
      totalStudents: json['total_students'] as int,
      totalSubjects: json['total_subjects'] as int,
      totalCategories: json['total_categories'] as int,
    );
  }
}

class PopularSubjectsFilters {
  final String? academicId;
  final String? academicYearName;

  const PopularSubjectsFilters({this.academicId, this.academicYearName});

  factory PopularSubjectsFilters.fromJson(Map<String, dynamic> json) {
    return PopularSubjectsFilters(
      academicId: json['academic_id'] as String?,
      academicYearName: json['academic_year_name'] as String?,
    );
  }
}

class PopularSubjectsReportData {
  final PopularSubjectsFilters filters;
  final PopularSubjectsSummary summary;
  final List<PopularSubjectItem> subjects;
  final List<LevelStatsItem> levels;
  final Map<String, int> categories;

  const PopularSubjectsReportData({
    required this.filters,
    required this.summary,
    required this.subjects,
    required this.levels,
    required this.categories,
  });

  factory PopularSubjectsReportData.fromJson(Map<String, dynamic> json) {
    return PopularSubjectsReportData(
      filters: PopularSubjectsFilters.fromJson(
        json['filters'] as Map<String, dynamic>,
      ),
      summary: PopularSubjectsSummary.fromJson(
        json['summary'] as Map<String, dynamic>,
      ),
      subjects: (json['subjects'] as List)
          .map((e) => PopularSubjectItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      levels: (json['levels'] as List)
          .map((e) => LevelStatsItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      categories: Map<String, int>.from(json['categories'] as Map),
    );
  }
}

class PopularSubjectsReportResponse {
  final String code;
  final String messages;
  final PopularSubjectsReportData data;

  const PopularSubjectsReportResponse({
    required this.code,
    required this.messages,
    required this.data,
  });

  factory PopularSubjectsReportResponse.fromJson(Map<String, dynamic> json) {
    return PopularSubjectsReportResponse(
      code: json['code'] as String,
      messages: json['messages'] as String,
      data: PopularSubjectsReportData.fromJson(
        json['data'] as Map<String, dynamic>,
      ),
    );
  }
}

class RegistrationReportItem {
  final String registrationId;
  final String? studentId;
  final String? fullName;
  final String gender;
  final String? school;
  final String? districtName;
  final String? provinceName;
  final String? status;
  final String statusLabel;
  final String? scholarship;
  final String scholarshipLabel;

  const RegistrationReportItem({
    required this.registrationId,
    this.studentId,
    this.fullName,
    required this.gender,
    this.school,
    this.districtName,
    this.provinceName,
    this.status,
    required this.statusLabel,
    this.scholarship,
    required this.scholarshipLabel,
  });

  factory RegistrationReportItem.fromJson(Map<String, dynamic> json) {
    return RegistrationReportItem(
      registrationId: json['registration_id'] as String,
      studentId: json['student_id'] as String?,
      fullName: json['full_name'] as String?,
      gender: localizeGender(json['gender'] as String?),
      school: json['school'] as String?,
      districtName: json['district_name'] as String?,
      provinceName: json['province_name'] as String?,
      status: json['status'] as String?,
      statusLabel: localizeRegistrationStatus(json['status'] as String?),
      scholarship: json['scholarship'] as String?,
      scholarshipLabel: localizeScholarship(json['scholarship'] as String?),
    );
  }

  dynamic operator [](String key) {
    switch (key) {
      case 'registrationId':
        return registrationId;
      case 'studentId':
        return studentId ?? '-';
      case 'fullName':
        return fullName ?? '-';
      case 'gender':
        return gender;
      case 'school':
        return school ?? '-';
      case 'districtName':
        return districtName ?? '-';
      case 'provinceName':
        return provinceName ?? '-';
      case 'status':
        return status ?? 'UNPAID';
      case 'statusLabel':
        return statusLabel;
      case 'scholarship':
        return scholarship ?? 'NO_SCHOLARSHIP';
      case 'scholarshipLabel':
        return scholarshipLabel;
      default:
        return null;
    }
  }
}

class RegistrationReportFilters {
  final String? academicId;
  final String? academicYearName;
  final String? subjectId;
  final String? subjectName;
  final String? levelId;
  final String? levelName;
  final String? status;
  final String? statusLabel;
  final String? scholarship;
  final String? scholarshipLabel;

  const RegistrationReportFilters({
    this.academicId,
    this.academicYearName,
    this.subjectId,
    this.subjectName,
    this.levelId,
    this.levelName,
    this.status,
    this.statusLabel,
    this.scholarship,
    this.scholarshipLabel,
  });

  factory RegistrationReportFilters.fromJson(Map<String, dynamic> json) {
    return RegistrationReportFilters(
      academicId: json['academic_id'] as String?,
      academicYearName: json['academic_year_name'] as String?,
      subjectId: json['subject_id'] as String?,
      subjectName: json['subject_name'] as String?,
      levelId: json['level_id'] as String?,
      levelName: json['level_name'] as String?,
      status: json['status'] as String?,
      statusLabel: json['status_label'] as String?,
      scholarship: json['scholarship'] as String?,
      scholarshipLabel: json['scholarship_label'] as String?,
    );
  }
}

class RegistrationReportSummary {
  final int total;
  final int paid;
  final int unpaid;
  final int partial;

  const RegistrationReportSummary({
    required this.total,
    required this.paid,
    required this.unpaid,
    required this.partial,
  });

  factory RegistrationReportSummary.fromJson(Map<String, dynamic> json) {
    return RegistrationReportSummary(
      total: json['total'] as int? ?? 0,
      paid: json['paid'] as int? ?? 0,
      unpaid: json['unpaid'] as int? ?? 0,
      partial: json['partial'] as int? ?? 0,
    );
  }
}

class RegistrationReportData {
  final RegistrationReportFilters filters;
  final int totalCount;
  final RegistrationReportSummary summary;
  final List<RegistrationReportItem> registrations;

  const RegistrationReportData({
    required this.filters,
    required this.totalCount,
    required this.summary,
    required this.registrations,
  });

  factory RegistrationReportData.fromJson(Map<String, dynamic> json) {
    return RegistrationReportData(
      filters: RegistrationReportFilters.fromJson(
        json['filters'] as Map<String, dynamic>,
      ),
      totalCount: json['total_count'] as int,
      summary: RegistrationReportSummary.fromJson(
        json['summary'] as Map<String, dynamic>,
      ),
      registrations: (json['registrations'] as List)
          .map((e) => RegistrationReportItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class RegistrationReportResponse {
  final String code;
  final String messages;
  final RegistrationReportData data;

  const RegistrationReportResponse({
    required this.code,
    required this.messages,
    required this.data,
  });

  factory RegistrationReportResponse.fromJson(Map<String, dynamic> json) {
    return RegistrationReportResponse(
      code: json['code'] as String,
      messages: json['messages'] as String,
      data: RegistrationReportData.fromJson(
        json['data'] as Map<String, dynamic>,
      ),
    );
  }
}
