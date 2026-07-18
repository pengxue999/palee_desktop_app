import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/discount_model.dart';
import '../services/discount_service.dart';

final discountServiceProvider =
    Provider<DiscountService>((_) => DiscountService());

class DiscountState {
  final List<DiscountModel> discounts;
  final bool isLoading;
  final String? error;

  const DiscountState({
    this.discounts = const [],
    this.isLoading = false,
    this.error,
  });

  DiscountState copyWith({
    List<DiscountModel>? discounts,
    bool? isLoading,
    String? error,
  }) {
    return DiscountState(
      discounts: discounts ?? this.discounts,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class DiscountNotifier extends StateNotifier<DiscountState> {
  final DiscountService _service;

  DiscountNotifier(this._service) : super(const DiscountState());

  Future<void> getDiscounts() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _service.getDiscounts();
      state = state.copyWith(discounts: response.data, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<bool> createDiscount(DiscountRequest request) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _service.createDiscount(request);
      await getDiscounts();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      return false;
    }
  }

  Future<bool> updateDiscount(
      String discountId, DiscountRequest request) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _service.updateDiscount(discountId, request);
      await getDiscounts();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      return false;
    }
  }

  Future<bool> deleteDiscount(String discountId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _service.deleteDiscount(discountId);
      state = state.copyWith(
        discounts: state.discounts
            .where((d) => d.discountId != discountId)
            .toList(),
        isLoading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      return false;
    }
  }

  void clearError() => state = state.copyWith(error: null);
}

final discountProvider =
    StateNotifierProvider<DiscountNotifier, DiscountState>(
  (ref) => DiscountNotifier(ref.read(discountServiceProvider)),
);
