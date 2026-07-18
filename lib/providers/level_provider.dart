import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:palee_elite_training_center/models/level_model.dart';
import '../services/level_service.dart';

final levelServiceProvider = Provider<LevelService>((_) => LevelService());

class LevelState {
  final List<Level> levels;
  final Level? selectedLevel;
  final bool isLoading;
  final String? error;

  const LevelState({
    this.levels = const [],
    this.selectedLevel,
    this.isLoading = false,
    this.error,
  });

  LevelState copyWith({
    List<Level>? levels,
    Level? selectedLevel,
    bool? isLoading,
    String? error,
  }) {
    return LevelState(
      levels: levels ?? this.levels,
      selectedLevel: selectedLevel ?? this.selectedLevel,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class LevelNotifier extends StateNotifier<LevelState> {
  final LevelService _service;

  LevelNotifier(this._service) : super(const LevelState());

  Future<void> getLevels() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _service.getLevels();
      state = state.copyWith(levels: response.data, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        levels: [
          Level(levelId: 'L001', levelName: 'ມ3'),
          Level(levelId: 'L002', levelName: 'ມ4'),
          Level(levelId: 'L003', levelName: 'ມ5'),
          Level(levelId: 'L004', levelName: 'ມ6'),
          Level(levelId: 'L005', levelName: 'ມ7'),
          Level(levelId: 'L006', levelName: 'ເລີ່ມຕົ້ນ'),
          Level(levelId: 'L007', levelName: 'ກາງ'),
          Level(levelId: 'L008', levelName: 'ສູງ'),
          Level(levelId: 'L009', levelName: 'HSK 1'),
          Level(levelId: 'L010', levelName: 'HSK 2'),
          Level(levelId: 'L011', levelName: 'HSK 3'),
          Level(levelId: 'L012', levelName: 'HSK 4'),
          Level(levelId: 'L013', levelName: 'HSK 5'),
          Level(levelId: 'L014', levelName: 'HSK 6'),
        ],
        error: 'ບໍ່ສາມາດໂຫຼດຂໍ້ມູນຈາກ API, ສະແດງຂໍ້ມູນຈຳລອງ: ${e.toString()}',
        isLoading: false,
      );
    }
  }

  Future<void> getLevelById(String levelId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _service.getLevelById(levelId);
      state = state.copyWith(selectedLevel: response.data, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<bool> createLevel(LevelRequest request) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _service.createLevel(request);
      state = state.copyWith(
        levels: [...state.levels, response.data],
        isLoading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      return false;
    }
  }

  Future<bool> updateLevel(String levelId, LevelRequest request) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _service.updateLevel(levelId, request);
      state = state.copyWith(
        levels: state.levels
            .map((level) => level.levelId == levelId ? response.data : level)
            .toList(),
        isLoading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      return false;
    }
  }

  Future<bool> deleteLevel(String levelId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _service.deleteLevel(levelId);
      state = state.copyWith(
        levels: state.levels.where((level) => level.levelId != levelId).toList(),
        isLoading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      return false;
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

final levelProvider = StateNotifierProvider<LevelNotifier, LevelState>(
  (ref) => LevelNotifier(ref.read(levelServiceProvider)),
);
