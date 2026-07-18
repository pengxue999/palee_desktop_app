import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/report_models.dart';
import '../services/report_service.dart';

final reportServiceProvider = Provider<ReportService>((_) => ReportService());

class ReportState {
  final List<StudentReportItem> students;
  final ReportFilters? filters;
  final int totalCount;
  final StudentSummaryData? summary;
  final bool isLoading;
  final bool isExporting;
  final String? error;

  final List<TeacherAttendanceReportItem> teacherAttendanceRecords;
  final TeacherAttendanceFilters? teacherAttendanceFilters;
  final int teacherAttendanceTotalCount;
  final TeacherAttendanceSummary? teacherAttendanceSummary;
  final bool isTeacherAttendanceLoading;
  final bool isTeacherAttendanceExporting;
  final String? teacherAttendanceError;

  final FinanceReportData? financeData;
  final bool isFinanceLoading;
  final bool isFinanceExporting;
  final String? financeError;

  final PopularSubjectsReportData? popularSubjectsData;
  final bool isPopularSubjectsLoading;
  final String? popularSubjectsError;

  final RegistrationReportData? registrationData;
  final bool isRegistrationLoading;
  final bool isRegistrationExporting;
  final String? registrationError;

  const ReportState({
    this.students = const [],
    this.filters,
    this.totalCount = 0,
    this.summary,
    this.isLoading = false,
    this.isExporting = false,
    this.error,
    this.teacherAttendanceRecords = const [],
    this.teacherAttendanceFilters,
    this.teacherAttendanceTotalCount = 0,
    this.teacherAttendanceSummary,
    this.isTeacherAttendanceLoading = false,
    this.isTeacherAttendanceExporting = false,
    this.teacherAttendanceError,
    this.financeData,
    this.isFinanceLoading = false,
    this.isFinanceExporting = false,
    this.financeError,
    this.popularSubjectsData,
    this.isPopularSubjectsLoading = false,
    this.popularSubjectsError,
    this.registrationData,
    this.isRegistrationLoading = false,
    this.isRegistrationExporting = false,
    this.registrationError,
  });

  ReportState copyWith({
    List<StudentReportItem>? students,
    ReportFilters? filters,
    int? totalCount,
    StudentSummaryData? summary,
    bool? isLoading,
    bool? isExporting,
    String? error,
    List<TeacherAttendanceReportItem>? teacherAttendanceRecords,
    TeacherAttendanceFilters? teacherAttendanceFilters,
    int? teacherAttendanceTotalCount,
    TeacherAttendanceSummary? teacherAttendanceSummary,
    bool? isTeacherAttendanceLoading,
    bool? isTeacherAttendanceExporting,
    String? teacherAttendanceError,
    FinanceReportData? financeData,
    bool? isFinanceLoading,
    bool? isFinanceExporting,
    String? financeError,
    PopularSubjectsReportData? popularSubjectsData,
    bool? isPopularSubjectsLoading,
    String? popularSubjectsError,
    RegistrationReportData? registrationData,
    bool? isRegistrationLoading,
    bool? isRegistrationExporting,
    String? registrationError,
  }) {
    return ReportState(
      students: students ?? this.students,
      filters: filters ?? this.filters,
      totalCount: totalCount ?? this.totalCount,
      summary: summary ?? this.summary,
      isLoading: isLoading ?? this.isLoading,
      isExporting: isExporting ?? this.isExporting,
      error: error,
      teacherAttendanceRecords:
          teacherAttendanceRecords ?? this.teacherAttendanceRecords,
      teacherAttendanceFilters:
          teacherAttendanceFilters ?? this.teacherAttendanceFilters,
      teacherAttendanceTotalCount:
          teacherAttendanceTotalCount ?? this.teacherAttendanceTotalCount,
      teacherAttendanceSummary:
          teacherAttendanceSummary ?? this.teacherAttendanceSummary,
      isTeacherAttendanceLoading:
          isTeacherAttendanceLoading ?? this.isTeacherAttendanceLoading,
      isTeacherAttendanceExporting:
          isTeacherAttendanceExporting ?? this.isTeacherAttendanceExporting,
      teacherAttendanceError: teacherAttendanceError,
      financeData: financeData ?? this.financeData,
      isFinanceLoading: isFinanceLoading ?? this.isFinanceLoading,
      isFinanceExporting: isFinanceExporting ?? this.isFinanceExporting,
      financeError: financeError,
      popularSubjectsData: popularSubjectsData ?? this.popularSubjectsData,
      isPopularSubjectsLoading:
          isPopularSubjectsLoading ?? this.isPopularSubjectsLoading,
      popularSubjectsError: popularSubjectsError,
      registrationData: registrationData ?? this.registrationData,
      isRegistrationLoading:
          isRegistrationLoading ?? this.isRegistrationLoading,
      isRegistrationExporting:
          isRegistrationExporting ?? this.isRegistrationExporting,
      registrationError: registrationError,
    );
  }
}

class ReportNotifier extends StateNotifier<ReportState> {
  final ReportService _service;

  ReportNotifier(this._service) : super(const ReportState());

  Future<void> getStudentReport({
    String? academicId,
    int? provinceId,
    int? districtId,
    String? scholarship,
    String? gender,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _service.getStudentReport(
        academicId: academicId,
        provinceId: provinceId,
        districtId: districtId,
        scholarship: scholarship,
        gender: gender,
      );
      state = state.copyWith(
        students: response.data.students,
        filters: response.data.filters,
        totalCount: response.data.totalCount,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<ExportReportData?> exportStudentReport({
    String? academicId,
    int? provinceId,
    int? districtId,
    String? scholarship,
    String? gender,
    String format = 'excel',
  }) async {
    state = state.copyWith(isExporting: true, error: null);
    try {
      final response = await _service.exportStudentReport(
        academicId: academicId,
        provinceId: provinceId,
        districtId: districtId,
        scholarship: scholarship,
        gender: gender,
        format: format,
      );
      state = state.copyWith(isExporting: false);
      return response.data;
    } catch (e) {
      state = state.copyWith(error: e.toString(), isExporting: false);
      return null;
    }
  }

  Future<void> getStudentSummary({String? academicId}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _service.getStudentSummary(academicId: academicId);
      state = state.copyWith(summary: response.data, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  Future<void> getTeacherAttendanceReport({
    String? academicId,
    String? month,
    String? status,
    String? teacherId,
  }) async {
    state = state.copyWith(
      isTeacherAttendanceLoading: true,
      teacherAttendanceError: null,
    );
    try {
      final response = await _service.getTeacherAttendanceReport(
        academicId: academicId,
        month: month,
        status: status,
        teacherId: teacherId,
      );
      state = state.copyWith(
        teacherAttendanceRecords: response.data.records,
        teacherAttendanceFilters: response.data.filters,
        teacherAttendanceTotalCount: response.data.totalCount,
        teacherAttendanceSummary: response.data.summary,
        isTeacherAttendanceLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        teacherAttendanceError: e.toString(),
        isTeacherAttendanceLoading: false,
      );
    }
  }

  Future<ExportReportData?> exportTeacherAttendanceReport({
    String? academicId,
    String? month,
    String? status,
    String? teacherId,
    String format = 'excel',
  }) async {
    state = state.copyWith(
      isTeacherAttendanceExporting: true,
      teacherAttendanceError: null,
    );
    try {
      final response = await _service.exportTeacherAttendanceReport(
        academicId: academicId,
        month: month,
        status: status,
        teacherId: teacherId,
        format: format,
      );
      state = state.copyWith(isTeacherAttendanceExporting: false);
      return response.data;
    } catch (e) {
      state = state.copyWith(
        teacherAttendanceError: e.toString(),
        isTeacherAttendanceExporting: false,
      );
      return null;
    }
  }

  void clearTeacherAttendanceError() {
    state = state.copyWith(teacherAttendanceError: null);
  }

  Future<void> getFinanceReport({String? academicId, int? year}) async {
    state = state.copyWith(isFinanceLoading: true, financeError: null);
    try {
      final response = await _service.getFinanceReport(
        academicId: academicId,
        year: year,
      );
      state = state.copyWith(
        financeData: response.data,
        isFinanceLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        financeError: e.toString(),
        isFinanceLoading: false,
      );
    }
  }

  Future<ExportReportData?> exportFinanceReport({
    String? academicId,
    int? year,
    String tab = 'overview',
    String format = 'excel',
  }) async {
    state = state.copyWith(isFinanceExporting: true, financeError: null);
    try {
      final response = await _service.exportFinanceReport(
        academicId: academicId,
        year: year,
        tab: tab,
        format: format,
      );
      state = state.copyWith(isFinanceExporting: false);
      return response.data;
    } catch (e) {
      state = state.copyWith(
        financeError: e.toString(),
        isFinanceExporting: false,
      );
      return null;
    }
  }

  Future<void> getPopularSubjectsReport({String? academicId}) async {
    state = state.copyWith(
      isPopularSubjectsLoading: true,
      popularSubjectsError: null,
    );
    try {
      final response = await _service.getPopularSubjectsReport(
        academicId: academicId,
      );
      state = state.copyWith(
        popularSubjectsData: response.data,
        isPopularSubjectsLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        popularSubjectsError: e.toString(),
        isPopularSubjectsLoading: false,
      );
    }
  }

  void clearPopularSubjectsError() {
    state = state.copyWith(popularSubjectsError: null);
  }

  Future<void> getRegistrationReport({
    String? academicId,
    String? subjectId,
    String? levelId,
    String? status,
    String? scholarship,
  }) async {
    state = state.copyWith(
      isRegistrationLoading: true,
      registrationError: null,
    );
    try {
      final response = await _service.getRegistrationReport(
        academicId: academicId,
        subjectId: subjectId,
        levelId: levelId,
        status: status,
        scholarship: scholarship,
      );
      state = state.copyWith(
        registrationData: response.data,
        isRegistrationLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        registrationError: e.toString(),
        isRegistrationLoading: false,
      );
    }
  }

  Future<ExportReportData?> exportRegistrationReport({
    String? academicId,
    String? subjectId,
    String? levelId,
    String? status,
    String? scholarship,
    String format = 'excel',
  }) async {
    state = state.copyWith(
      isRegistrationExporting: true,
      registrationError: null,
    );
    try {
      final response = await _service.exportRegistrationReport(
        academicId: academicId,
        subjectId: subjectId,
        levelId: levelId,
        status: status,
        scholarship: scholarship,
        format: format,
      );
      state = state.copyWith(isRegistrationExporting: false);
      return response.data;
    } catch (e) {
      state = state.copyWith(
        registrationError: e.toString(),
        isRegistrationExporting: false,
      );
      return null;
    }
  }

  void clearRegistrationError() {
    state = state.copyWith(registrationError: null);
  }

  void clearFinanceError() {
    state = state.copyWith(financeError: null);
  }
}

final reportProvider = StateNotifierProvider<ReportNotifier, ReportState>(
  (ref) => ReportNotifier(ref.read(reportServiceProvider)),
);
