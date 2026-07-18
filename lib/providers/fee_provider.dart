import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/fee_model.dart';
import '../services/fee_service.dart';

final feeServiceProvider = Provider<FeeService>((_) => FeeService());

class FeeState {
  final List<FeeModel> fees;
  final FeeModel? selectedFee;
  final bool isLoading;
  final String? error;

  const FeeState({
    this.fees = const [],
    this.selectedFee,
    this.isLoading = false,
    this.error,
  });

  FeeState copyWith({
    List<FeeModel>? fees,
    FeeModel? selectedFee,
    bool? isLoading,
    String? error,
  }) {
    return FeeState(
      fees: fees ?? this.fees,
      selectedFee: selectedFee ?? this.selectedFee,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class FeeNotifier extends StateNotifier<FeeState> {
  final FeeService _service;

  FeeNotifier(this._service) : super(const FeeState());

  Future<void> getFees() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _service.getFees();
      state = state.copyWith(fees: response.data, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> getFeeById(String feeId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _service.getFeeById(feeId);
      state = state.copyWith(selectedFee: response.data, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<bool> createFee(FeeRequest request) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _service.createFee(request);
      await getFees();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      return false;
    }
  }

  Future<bool> updateFee(String feeId, FeeRequest request) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _service.updateFee(feeId, request);
      await getFees();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      return false;
    }
  }

  Future<bool> deleteFee(String feeId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _service.deleteFee(feeId);
      state = state.copyWith(
        fees: state.fees.where((f) => f.feeId != feeId).toList(),
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

final feeProvider = StateNotifierProvider<FeeNotifier, FeeState>(
  (ref) => FeeNotifier(ref.read(feeServiceProvider)),
);
