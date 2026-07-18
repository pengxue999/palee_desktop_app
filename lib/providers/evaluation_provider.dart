import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:palee_elite_training_center/models/evaluation_model.dart';
import 'package:palee_elite_training_center/services/evaluation_service.dart';

final evaluationServiceProvider = Provider<EvaluationService>(
  (_) => EvaluationService(),
);

class EvaluationState {
  static const _unset = Object();

  final EvaluationScoreSheet? sheet;
  final List<EvaluationScoreSubjectOption> availableSubjects;
  final List<EvaluationScoreLevelOption> availableLevels;
  final bool isLoading;
  final bool isLoadingSubjects;
  final bool isLoadingLevels;
  final bool isPreviewing;
  final bool isSaving;
  final String? error;

  const EvaluationState({
    this.sheet,
    this.availableSubjects = const [],
    this.availableLevels = const [],
    this.isLoading = false,
    this.isLoadingSubjects = false,
    this.isLoadingLevels = false,
    this.isPreviewing = false,
    this.isSaving = false,
    this.error,
  });

  EvaluationState copyWith({
    Object? sheet = _unset,
    Object? availableSubjects = _unset,
    Object? availableLevels = _unset,
    bool? isLoading,
    bool? isLoadingSubjects,
    bool? isLoadingLevels,
    bool? isPreviewing,
    bool? isSaving,
    Object? error = _unset,
  }) {
    return EvaluationState(
      sheet: identical(sheet, _unset)
          ? this.sheet
          : sheet as EvaluationScoreSheet?,
      availableSubjects: identical(availableSubjects, _unset)
          ? this.availableSubjects
          : availableSubjects as List<EvaluationScoreSubjectOption>,
      availableLevels: identical(availableLevels, _unset)
          ? this.availableLevels
          : availableLevels as List<EvaluationScoreLevelOption>,
      isLoading: isLoading ?? this.isLoading,
      isLoadingSubjects: isLoadingSubjects ?? this.isLoadingSubjects,
      isLoadingLevels: isLoadingLevels ?? this.isLoadingLevels,
      isPreviewing: isPreviewing ?? this.isPreviewing,
      isSaving: isSaving ?? this.isSaving,
      error: identical(error, _unset) ? this.error : error as String?,
    );
  }
}

class EvaluationNotifier extends StateNotifier<EvaluationState> {
  EvaluationNotifier(this._service) : super(const EvaluationState());

  final EvaluationService _service;
  int _subjectsRequestId = 0;
  int _levelsRequestId = 0;
  int _sheetRequestId = 0;

  Future<void> loadScoreSubjects({String? teacherId}) async {
    final requestId = ++_subjectsRequestId;
    state = state.copyWith(isLoadingSubjects: true, error: null);
    try {
      final response = await _service.getScoreSubjects(teacherId: teacherId);
      if (requestId != _subjectsRequestId) {
        return;
      }
      state = state.copyWith(
        availableSubjects: response.data,
        isLoadingSubjects: false,
      );
    } catch (e) {
      if (requestId != _subjectsRequestId) {
        return;
      }
      state = state.copyWith(
        availableSubjects: <EvaluationScoreSubjectOption>[],
        isLoadingSubjects: false,
        error: e.toString(),
      );
    }
  }

  Future<void> loadScoreLevels({
    required String subjectId,
    String? teacherId,
  }) async {
    final requestId = ++_levelsRequestId;
    state = state.copyWith(isLoadingLevels: true, error: null);
    try {
      final response = await _service.getScoreLevels(
        subjectId: subjectId,
        teacherId: teacherId,
      );
      if (requestId != _levelsRequestId) {
        return;
      }
      state = state.copyWith(
        availableLevels: response.data,
        isLoadingLevels: false,
      );
    } catch (e) {
      if (requestId != _levelsRequestId) {
        return;
      }
      state = state.copyWith(
        availableLevels: <EvaluationScoreLevelOption>[],
        isLoadingLevels: false,
        error: e.toString(),
      );
    }
  }

  Future<void> loadScoreSheet({
    required String semester,
    required String levelId,
    required String subjectDetailId,
  }) async {
    final requestId = ++_sheetRequestId;
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _service.getScoreSheet(
        semester: semester,
        levelId: levelId,
        subjectDetailId: subjectDetailId,
      );
      if (requestId != _sheetRequestId) {
        return;
      }
      state = state.copyWith(sheet: response.data, isLoading: false);
    } catch (e) {
      if (requestId != _sheetRequestId) {
        return;
      }
      state = state.copyWith(
        sheet: null,
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<bool> previewScoreSheet(EvaluationScoreSheetRequest request) async {
    state = state.copyWith(isPreviewing: true, error: null);
    try {
      final response = await _service.previewScoreSheet(request);
      state = state.copyWith(sheet: response.data, isPreviewing: false);
      return true;
    } catch (e) {
      state = state.copyWith(isPreviewing: false, error: e.toString());
      return false;
    }
  }

  Future<bool> saveScoreSheet(EvaluationScoreSheetRequest request) async {
    state = state.copyWith(isSaving: true, error: null);
    try {
      final response = await _service.saveScoreSheet(request);
      state = state.copyWith(sheet: response.data, isSaving: false);
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: e.toString());
      return false;
    }
  }

  void clearSheet({bool clearSubjects = false, bool clearLevels = true}) {
    state = state.copyWith(
      sheet: null,
      error: null,
      availableSubjects: clearSubjects
          ? <EvaluationScoreSubjectOption>[]
          : state.availableSubjects,
      availableLevels: clearLevels
          ? <EvaluationScoreLevelOption>[]
          : state.availableLevels,
    );
  }

  void resetScoreEntryForm() {
    state = state.copyWith(
      sheet: null,
      error: null,
      availableLevels: <EvaluationScoreLevelOption>[],
    );
  }
}

final evaluationProvider =
    StateNotifierProvider<EvaluationNotifier, EvaluationState>(
      (ref) => EvaluationNotifier(ref.read(evaluationServiceProvider)),
    );
