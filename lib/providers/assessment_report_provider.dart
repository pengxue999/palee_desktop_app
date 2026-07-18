import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:palee_elite_training_center/models/evaluation_model.dart';
import 'package:palee_elite_training_center/providers/evaluation_provider.dart';

class AssessmentReportState {
  final List<AssessmentReportItem> items;
  final bool isLoading;
  final String? error;

  const AssessmentReportState({
    this.items = const [],
    this.isLoading = false,
    this.error,
  });

  AssessmentReportState copyWith({
    List<AssessmentReportItem>? items,
    bool? isLoading,
    String? error,
  }) {
    return AssessmentReportState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class AssessmentReportNotifier extends StateNotifier<AssessmentReportState> {
  AssessmentReportNotifier(this._ref) : super(const AssessmentReportState());

  final Ref _ref;

  Future<void> loadReport({
    String? academicId,
    required String semester,
    String? subjectId,
    String? levelId,
    String? ranking,
    String? teacherId,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _ref
          .read(evaluationServiceProvider)
          .getAssessmentResults(
            academicId: academicId,
            semester: semester,
            subjectId: subjectId,
            levelId: levelId,
            ranking: ranking,
            teacherId: teacherId,
          );
      state = state.copyWith(items: response.data, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void clear() {
    state = const AssessmentReportState();
  }
}

final assessmentReportProvider =
    StateNotifierProvider<AssessmentReportNotifier, AssessmentReportState>(
      (ref) => AssessmentReportNotifier(ref),
    );
