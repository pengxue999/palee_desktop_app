import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/academic_year_model.dart';
import '../services/academic_year_service.dart';

final academicYearServiceProvider = Provider<AcademicYearService>(
  (_) => AcademicYearService(),
);

class AcademicYearState {
  final List<AcademicYearModel> academicYears;
  final AcademicYearModel? selectedAcademicYear;
  final bool isLoading;
  final String? error;

  const AcademicYearState({
    this.academicYears = const [],
    this.selectedAcademicYear,
    this.isLoading = false,
    this.error,
  });

  AcademicYearState copyWith({
    List<AcademicYearModel>? academicYears,
    AcademicYearModel? selectedAcademicYear,
    bool? isLoading,
    String? error,
  }) {
    return AcademicYearState(
      academicYears: academicYears ?? this.academicYears,
      selectedAcademicYear: selectedAcademicYear ?? this.selectedAcademicYear,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class AcademicYearNotifier extends StateNotifier<AcademicYearState> {
  final AcademicYearService _service;

  AcademicYearNotifier(this._service) : super(const AcademicYearState());

  Future<void> getAcademicYears() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _service.getAcademicYears();
      state = state.copyWith(academicYears: response.data, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> getAcademicYearById(String academicId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _service.getAcademicYearById(academicId);
      state = state.copyWith(
        selectedAcademicYear: response.data,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<bool> createAcademicYear(AcademicYearRequest request) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _service.createAcademicYear(request);
      final refreshed = await _service.getAcademicYears();
      state = state.copyWith(academicYears: refreshed.data, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      return false;
    }
  }

  Future<bool> updateAcademicYear(
    String academicId,
    AcademicYearRequest request,
  ) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _service.updateAcademicYear(academicId, request);
      state = state.copyWith(
        academicYears: state.academicYears
            .map((ay) => ay.academicId == academicId ? response.data : ay)
            .toList(),
        isLoading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      return false;
    }
  }

  Future<bool> deleteAcademicYear(String academicId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _service.deleteAcademicYear(academicId);
      state = state.copyWith(
        academicYears: state.academicYears
            .where((ay) => ay.academicId != academicId)
            .toList(),
        isLoading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      return false;
    }
  }

  void selectAcademicYear(AcademicYearModel academicYear) {
    state = state.copyWith(selectedAcademicYear: academicYear);
  }
}

final academicYearProvider =
    StateNotifierProvider<AcademicYearNotifier, AcademicYearState>(
      (ref) => AcademicYearNotifier(ref.read(academicYearServiceProvider)),
    );
