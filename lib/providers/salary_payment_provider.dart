import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/salary_payment_model.dart';
import '../models/teacher_model.dart';
import '../services/salary_payment_service.dart';

final salaryPaymentServiceProvider = Provider<SalaryPaymentService>(
  (_) => SalaryPaymentService(),
);

class SalaryPaymentState {
  final List<SalaryPaymentModel> payments;
  final List<SalaryPaymentModel>
  teacherPayments;
  final List<TeachingMonth> availableMonths;
  final List<TeacherMonthlySummary>
  monthlyTeachers;
  final List<TeacherModel> teachers;
  final TeacherSalaryCalculation? calculation;
  final TeacherPaymentSummary? summary;
  final TeachingMonth? selectedMonth;
  final String? selectedTeacherId;
  final bool isLoading;
  final bool isCalculating;
  final bool isLoadingTeachers;
  final String? error;

  const SalaryPaymentState({
    this.payments = const [],
    this.teacherPayments = const [],
    this.availableMonths = const [],
    this.monthlyTeachers = const [],
    this.teachers = const [],
    this.calculation,
    this.summary,
    this.selectedMonth,
    this.selectedTeacherId,
    this.isLoading = false,
    this.isCalculating = false,
    this.isLoadingTeachers = false,
    this.error,
  });

  SalaryPaymentState copyWith({
    List<SalaryPaymentModel>? payments,
    List<SalaryPaymentModel>? teacherPayments,
    List<TeachingMonth>? availableMonths,
    List<TeacherMonthlySummary>? monthlyTeachers,
    List<TeacherModel>? teachers,
    TeacherSalaryCalculation? calculation,
    TeacherPaymentSummary? summary,
    TeachingMonth? selectedMonth,
    String? selectedTeacherId,
    bool? isLoading,
    bool? isCalculating,
    bool? isLoadingTeachers,
    String? error,
    bool clearCalculation = false,
    bool clearSelectedTeacher = false,
    bool clearSelectedMonth = false,
  }) {
    return SalaryPaymentState(
      payments: payments ?? this.payments,
      teacherPayments: teacherPayments ?? this.teacherPayments,
      availableMonths: availableMonths ?? this.availableMonths,
      monthlyTeachers: monthlyTeachers ?? this.monthlyTeachers,
      teachers: teachers ?? this.teachers,
      calculation: clearCalculation ? null : (calculation ?? this.calculation),
      summary: clearCalculation ? null : (summary ?? this.summary),
      selectedMonth: clearSelectedMonth
          ? null
          : (selectedMonth ?? this.selectedMonth),
      selectedTeacherId: clearSelectedTeacher
          ? null
          : (selectedTeacherId ?? this.selectedTeacherId),
      isLoading: isLoading ?? this.isLoading,
      isCalculating: isCalculating ?? this.isCalculating,
      isLoadingTeachers: isLoadingTeachers ?? this.isLoadingTeachers,
      error: error,
    );
  }
}

class SalaryPaymentNotifier extends StateNotifier<SalaryPaymentState> {
  final SalaryPaymentService _service;

  SalaryPaymentNotifier(this._service) : super(const SalaryPaymentState());

  Future<void> loadPayments({
    String? teacherId,
    String? fromDate,
    String? toDate,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _service.getAll(
        teacherId: teacherId,
      );
      state = state.copyWith(payments: response.data, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> loadTeacherPayments(String teacherId) async {
    final hasExistingData = state.teacherPayments.isNotEmpty;
    if (!hasExistingData) {
      state = state.copyWith(isLoading: true, error: null);
    }
    try {
      final response = await _service.getByTeacher(teacherId);
      state = state.copyWith(
        teacherPayments: response.data,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
    }
  }

  Future<void> loadTeachingMonths() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final months = await _service.getTeachingMonths();
      state = state.copyWith(availableMonths: months, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> loadMonthlyTeachers(int month, int year) async {
    state = state.copyWith(
      isLoadingTeachers: true,
      error: null,
      clearSelectedTeacher: false,
    );
    try {
      final teachers = await _service.getTeachersMonthly(month, year);
      state = state.copyWith(
        monthlyTeachers: teachers,
        isLoadingTeachers: false,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoadingTeachers: false);
    }
  }

  Future<void> selectMonth(TeachingMonth month) async {
    state = state.copyWith(
      selectedMonth: month,
      clearCalculation: true,
      clearSelectedTeacher: true,
      teacherPayments: [],
    );
    await loadMonthlyTeachers(month.month, month.year);
  }

  Future<void> selectTeacher(String teacherId) async {
    final month = state.selectedMonth;
    if (month == null) return;

    if (state.selectedTeacherId == teacherId) return;

    state = state.copyWith(
      selectedTeacherId: teacherId,
    );

    await Future.wait([
      loadTeacherPayments(teacherId),
      calculateTeacherSalary(teacherId, month.month, month.year),
    ]);
  }

  Future<void> calculateTeacherSalary(
    String teacherId,
    int month,
    int year,
  ) async {
    final hasExistingCalc = state.calculation != null;
    if (!hasExistingCalc) {
      state = state.copyWith(isCalculating: true, error: null);
    }
    try {
      final calculation = await _service.calculateSalary(
        teacherId,
        month,
        year,
      );
      state = state.copyWith(
        calculation: calculation,
        isCalculating: false,
      );
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isCalculating: false,
      );
    }
  }

  Future<void> getTeacherSummary(String teacherId, int month, int year) async {
    state = state.copyWith(isCalculating: true, error: null);
    try {
      final summary = await _service.getTeacherSummary(teacherId, month, year);
      state = state.copyWith(summary: summary, isCalculating: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isCalculating: false);
    }
  }

  Future<String?> createPayment(SalaryPaymentRequest request) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _service.createPayment(request);
      final paymentId = response.data.salaryPaymentId;

      final month = state.selectedMonth;
      await loadPayments();
      if (state.selectedTeacherId != null) {
        await loadTeacherPayments(state.selectedTeacherId!);
      }
      if (month != null) {
        await loadMonthlyTeachers(month.month, month.year);
        if (state.selectedTeacherId != null) {
          await calculateTeacherSalary(
            state.selectedTeacherId!,
            month.month,
            month.year,
          );
        }
      }
      return paymentId;
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      return null;
    }
  }

  Future<bool> updatePayment(
    String paymentId,
    Map<String, dynamic> data,
  ) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _service.updatePayment(paymentId, data);
      await loadPayments();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      return false;
    }
  }

  Future<bool> deletePayment(String paymentId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _service.deletePayment(paymentId);
      state = state.copyWith(
        payments: state.payments
            .where((p) => p.salaryPaymentId != paymentId)
            .toList(),
        teacherPayments: state.teacherPayments
            .where((p) => p.salaryPaymentId != paymentId)
            .toList(),
        isLoading: false,
      );
      final month = state.selectedMonth;
      if (month != null) {
        await loadMonthlyTeachers(month.month, month.year);
      }
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      return false;
    }
  }

  void clearCalculation() {
    state = state.copyWith(clearCalculation: true);
  }

  void clearError() => state = state.copyWith(error: null);
}

final salaryPaymentProvider =
    StateNotifierProvider<SalaryPaymentNotifier, SalaryPaymentState>(
      (ref) => SalaryPaymentNotifier(ref.read(salaryPaymentServiceProvider)),
    );
