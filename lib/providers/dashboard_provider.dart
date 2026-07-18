import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/utils/enum_localization.dart';
import '../models/academic_year_model.dart';
import '../models/dashboard_model.dart';
import '../services/dashboard_service.dart';

final dashboardServiceProvider = Provider<DashboardService>(
  (_) => DashboardService(),
);

class DashboardState {
  final DashboardStatsModel? stats;
  final AcademicYearModel? selectedAcademicYear;
  final List<AcademicYearModel> availableAcademicYears;
  final bool isLoading;
  final String? error;

  const DashboardState({
    this.stats,
    this.selectedAcademicYear,
    this.availableAcademicYears = const [],
    this.isLoading = false,
    this.error,
  });

  DashboardState copyWith({
    DashboardStatsModel? stats,
    AcademicYearModel? selectedAcademicYear,
    List<AcademicYearModel>? availableAcademicYears,
    bool? isLoading,
    String? error,
  }) {
    return DashboardState(
      stats: stats ?? this.stats,
      selectedAcademicYear: selectedAcademicYear ?? this.selectedAcademicYear,
      availableAcademicYears:
          availableAcademicYears ?? this.availableAcademicYears,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  int get totalStudents => stats?.students.total ?? 0;
  int get activeStudents => stats?.students.active ?? 0;
  int get totalTeachers => stats?.teachers.total ?? 0;
  int get activeTeachers => stats?.teachers.active ?? 0;
  double get totalIncome => stats?.income.total ?? 0.0;
  double get totalExpenses => stats?.expenses.total ?? 0.0;
  double get balance => stats?.balance ?? 0.0;
  String get currentAcademicYear =>
      stats?.academicYear.academicYear ?? 'ບໍ່ມີຂໍ້ມູນ';
}

class DashboardNotifier extends StateNotifier<DashboardState> {
  final DashboardService _service;

  DashboardNotifier(this._service) : super(const DashboardState());

  Future<void> loadDashboardStats({String? academicId}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _service.getDashboardStats(academicId: academicId);
      state = state.copyWith(stats: response.data, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        error: 'ບໍ່ສາມາດດຶງຂໍ້ມູນ Dashboard ໄດ້: $e',
        isLoading: false,
      );
    }
  }

  Future<void> refreshStats() async {
    final academicId = state.selectedAcademicYear?.academicId;
    await loadDashboardStats(academicId: academicId);
  }

  void selectAcademicYear(AcademicYearModel academicYear) {
    state = state.copyWith(selectedAcademicYear: academicYear);
    loadDashboardStats(academicId: academicYear.academicId);
  }

  void setAvailableAcademicYears(List<AcademicYearModel> academicYears) {
    state = state.copyWith(availableAcademicYears: academicYears);

    if (state.selectedAcademicYear == null) {
      final activeYear = academicYears
          .where((ay) => isActiveAcademicStatus(ay.academicStatus))
          .firstOrNull;

      if (activeYear != null) {
        state = state.copyWith(selectedAcademicYear: activeYear);
      } else if (academicYears.isNotEmpty) {
        state = state.copyWith(selectedAcademicYear: academicYears.last);
      }
    }
  }

  void clearError() => state = state.copyWith(error: null);
}

final dashboardProvider =
    StateNotifierProvider<DashboardNotifier, DashboardState>(
      (ref) => DashboardNotifier(ref.read(dashboardServiceProvider)),
    );
