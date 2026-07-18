import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/subject_model.dart';
import '../services/subject_service.dart';

final subjectServiceProvider =
    Provider<SubjectService>((_) => SubjectService());

class SubjectState {
  final List<SubjectModel> subjects;
  final SubjectModel? selectedSubject;
  final bool isLoading;
  final String? error;

  const SubjectState({
    this.subjects = const [
      SubjectModel(
        subjectId: 'S001',
        subjectName: 'ຄະນິດສາດ',
        subjectCategoryId: 'SC001',
        subjectCategoryName: 'ສາຍຄິດໄລ່',
      ),
      SubjectModel(
        subjectId: 'S002',
        subjectName: 'ເຄີມີສາດ',
        subjectCategoryId: 'SC002',
        subjectCategoryName: 'ສາຍພາສາ',
      ),
      SubjectModel(
        subjectId: 'S003',
        subjectName: 'ຟີຊິກສາດ',
        subjectCategoryId: 'SC001',
        subjectCategoryName: 'ສາຍຄິດໄລ່',
      ),
      SubjectModel(
        subjectId: 'S004',
        subjectName: 'ພາສາອັງກິດ',
        subjectCategoryId: 'SC002',
        subjectCategoryName: 'ສາຍພາສາ',
      ),
      SubjectModel(
        subjectId: 'S005',
        subjectName: 'ພາສາຈີນ',
        subjectCategoryId: 'SC002',
        subjectCategoryName: 'ສາຍພາສາ',
      ),
    ],
    this.selectedSubject,
    this.isLoading = false,
    this.error,
  });

  SubjectState copyWith({
    List<SubjectModel>? subjects,
    SubjectModel? selectedSubject,
    bool? isLoading,
    String? error,
  }) {
    return SubjectState(
      subjects: subjects ?? this.subjects,
      selectedSubject: selectedSubject ?? this.selectedSubject,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class SubjectNotifier extends StateNotifier<SubjectState> {
  final SubjectService _service;

  SubjectNotifier(this._service) : super(const SubjectState());

  Future<void> getSubjects() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _service.getSubjects();
      state = state.copyWith(subjects: response.data, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        subjects: [
          SubjectModel(
            subjectId: 'S001',
            subjectName: 'ຄະນິດສາດ',
            subjectCategoryId: 'SC001',
            subjectCategoryName: 'ສາຍຄິດໄລ່',
          ),
          SubjectModel(
            subjectId: 'S002',
            subjectName: 'ເຄີມີສາດ',
            subjectCategoryId: 'SC002',
            subjectCategoryName: 'ສາຍພາສາ',
          ),
          SubjectModel(
            subjectId: 'S003',
            subjectName: 'ຟີຊິກສາດ',
            subjectCategoryId: 'SC001',
            subjectCategoryName: 'ສາຍຄິດໄລ່',
          ),
          SubjectModel(
            subjectId: 'S004',
            subjectName: 'ພາສາອັງກິດ',
            subjectCategoryId: 'SC002',
            subjectCategoryName: 'ສາຍພາສາ',
          ),
          SubjectModel(
            subjectId: 'S005',
            subjectName: 'ພາສາຈີນ',
            subjectCategoryId: 'SC002',
            subjectCategoryName: 'ສາຍພາສາ',
          ),
        ],
        error: 'ບໍ່ສາມາດໂຫຼດຂໍ້ມູນຈາກ API, ສະແດງຂໍ້ມູນຈຳລອງ: ${e.toString()}',
        isLoading: false,
      );
    }
  }

  Future<void> getSubjectById(String subjectId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _service.getSubjectById(subjectId);
      state = state.copyWith(selectedSubject: response.data, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<bool> createSubject(SubjectRequest request) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _service.createSubject(request);
      state = state.copyWith(
        subjects: [...state.subjects, response.data],
        isLoading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      return false;
    }
  }

  Future<bool> updateSubject(String subjectId, SubjectRequest request) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _service.updateSubject(subjectId, request);
      state = state.copyWith(
        subjects: state.subjects
            .map((s) => s.subjectId == subjectId ? response.data : s)
            .toList(),
        isLoading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      return false;
    }
  }

  Future<bool> deleteSubject(String subjectId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _service.deleteSubject(subjectId);
      state = state.copyWith(
        subjects: state.subjects
            .where((s) => s.subjectId != subjectId)
            .toList(),
        isLoading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      return false;
    }
  }
}

final subjectProvider =
    StateNotifierProvider<SubjectNotifier, SubjectState>(
  (ref) => SubjectNotifier(ref.read(subjectServiceProvider)),
);
