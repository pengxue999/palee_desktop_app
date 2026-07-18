import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/income_model.dart';
import '../services/income_service.dart';

final incomeServiceProvider = Provider<IncomeService>((_) => IncomeService());

class IncomeState {
  final List<IncomeModel> incomes;
  final bool isLoading;
  final String? error;

  const IncomeState({
    this.incomes = const [],
    this.isLoading = false,
    this.error,
  });

  IncomeState copyWith({
    List<IncomeModel>? incomes,
    bool? isLoading,
    String? error,
  }) {
    return IncomeState(
      incomes: incomes ?? this.incomes,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  double get totalIncome {
    return incomes.fold(0.0, (sum, income) => sum + income.amount);
  }

  List<IncomeModel> get manualIncomes {
    return incomes.where((i) => i.tuitionPaymentId == null && i.donationId == null).toList();
  }

  List<IncomeModel> get tuitionIncomes {
    return incomes.where((i) => i.tuitionPaymentId != null).toList();
  }

  List<IncomeModel> get donationIncomes {
    return incomes.where((i) => i.donationId != null).toList();
  }
}

class IncomeNotifier extends StateNotifier<IncomeState> {
  final IncomeService _service;

  IncomeNotifier(this._service) : super(const IncomeState());

  Future<void> loadIncomes() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final incomes = await _service.getIncomes();
      state = state.copyWith(incomes: incomes, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<bool> createManualIncome({
    required double amount,
    String? description,
    DateTime? incomeDate,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final request = IncomeRequest(
        tuitionPaymentId: null,
        donationId: null,
        amount: amount,
        description: description,
      );
      await _service.createIncome(request);
      await loadIncomes();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      return false;
    }
  }

  Future<bool> updateIncome({
    required int incomeId,
    required double amount,
    String? description,
    DateTime? incomeDate,
  }) async {
    final income = state.incomes.firstWhere((i) => i.incomeId == incomeId);
    if (income.tuitionPaymentId != null || income.donationId != null) {
      state = state.copyWith(
        error: 'ບໍ່ສາມາດແກ້ໄຂລາຍຮັບນີ້ໄດ້ (ເປັນລາຍຮັບຈາກລະບົບ)',
        isLoading: false,
      );
      return false;
    }

    state = state.copyWith(isLoading: true, error: null);
    try {
      final request = IncomeUpdateRequest(
        amount: amount,
        description: description,
      );
      await _service.updateIncome(incomeId, request);
      await loadIncomes();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      return false;
    }
  }

  Future<bool> deleteIncome(int incomeId) async {
    final income = state.incomes.firstWhere((i) => i.incomeId == incomeId);
    if (income.tuitionPaymentId != null || income.donationId != null) {
      state = state.copyWith(
        error: 'ບໍ່ສາມາດລຶບລາຍຮັບນີ້ໄດ້ (ເປັນລາຍຮັບຈາກລະບົບ)',
        isLoading: false,
      );
      return false;
    }

    state = state.copyWith(isLoading: true, error: null);
    try {
      await _service.deleteIncome(incomeId);
      state = state.copyWith(
        incomes: state.incomes.where((i) => i.incomeId != incomeId).toList(),
        isLoading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      return false;
    }
  }

  bool canEditOrDelete(int incomeId) {
    final income = state.incomes.firstWhere((i) => i.incomeId == incomeId);
    return income.tuitionPaymentId == null && income.donationId == null;
  }

  void clearError() => state = state.copyWith(error: null);
}

final incomeProvider = StateNotifierProvider<IncomeNotifier, IncomeState>(
  (ref) => IncomeNotifier(ref.read(incomeServiceProvider)),
);
