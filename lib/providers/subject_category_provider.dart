import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/subject_category_model.dart';
import '../services/subject_category_service.dart';

final subjectCategoryServiceProvider =
    Provider<SubjectCategoryService>((_) => SubjectCategoryService());

class SubjectCategoryState {
  final List<SubjectCategoryModel> subjectCategories;
  final SubjectCategoryModel? selectedSubjectCategory;
  final bool isLoading;
  final String? error;

  const SubjectCategoryState({
    this.subjectCategories = const [
      SubjectCategoryModel(
        subjectCategoryId: 'SC001',
        subjectCategoryName: 'ສາຍຄິດໄລ່',
      ),
      SubjectCategoryModel(
        subjectCategoryId: 'SC002',
        subjectCategoryName: 'ສາຍພາສາ',
      ),
    ],
    this.selectedSubjectCategory,
    this.isLoading = false,
    this.error,
  });

  SubjectCategoryState copyWith({
    List<SubjectCategoryModel>? subjectCategories,
    SubjectCategoryModel? selectedSubjectCategory,
    bool? isLoading,
    String? error,
  }) {
    return SubjectCategoryState(
      subjectCategories: subjectCategories ?? this.subjectCategories,
      selectedSubjectCategory: selectedSubjectCategory ?? this.selectedSubjectCategory,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class SubjectCategoryNotifier extends StateNotifier<SubjectCategoryState> {
  final SubjectCategoryService _service;

  SubjectCategoryNotifier(this._service) : super(const SubjectCategoryState());

  Future<void> getSubjectCategories() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _service.getSubjectCategories();
      state = state.copyWith(subjectCategories: response.data, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        subjectCategories: [
          SubjectCategoryModel(
            subjectCategoryId: 'SC001',
            subjectCategoryName: 'ສາຍຄິດໄລ່',
          ),
          SubjectCategoryModel(
            subjectCategoryId: 'SC002',
            subjectCategoryName: 'ສາຍພາສາ',
          ),
        ],
        error: 'ບໍ່ສາມາດໂຫຼດຂໍ້ມູນຈາກ API, ສະແດງຂໍ້ມູນຈຳລອງ: ${e.toString()}',
        isLoading: false,
      );
    }
  }

  Future<void> getSubjectCategoryById(String subjectCategoryId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _service.getSubjectCategoryById(subjectCategoryId);
      state = state.copyWith(selectedSubjectCategory: response.data, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<bool> createSubjectCategory(SubjectCategoryRequest request) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _service.createSubjectCategory(request);
      state = state.copyWith(
        subjectCategories: [...state.subjectCategories, response.data],
        isLoading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      return false;
    }
  }

  Future<bool> updateSubjectCategory(String subjectCategoryId, SubjectCategoryRequest request) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _service.updateSubjectCategory(subjectCategoryId, request);
      state = state.copyWith(
        subjectCategories: state.subjectCategories
            .map((sc) => sc.subjectCategoryId == subjectCategoryId ? response.data : sc)
            .toList(),
        isLoading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      return false;
    }
  }

  Future<bool> deleteSubjectCategory(String subjectCategoryId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _service.deleteSubjectCategory(subjectCategoryId);
      state = state.copyWith(
        subjectCategories: state.subjectCategories
            .where((sc) => sc.subjectCategoryId != subjectCategoryId)
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

final subjectCategoryProvider =
    StateNotifierProvider<SubjectCategoryNotifier, SubjectCategoryState>(
  (ref) => SubjectCategoryNotifier(ref.read(subjectCategoryServiceProvider)),
);
