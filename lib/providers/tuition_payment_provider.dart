import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/tuition_payment_model.dart';
import '../services/tuition_payment_service.dart';

final tuitionPaymentServiceProvider = Provider<TuitionPaymentService>(
  (_) => TuitionPaymentService(),
);

class TuitionPaymentState {
  final List<TuitionPaymentModel> payments;
  final List<TuitionPaymentModel> registrationPayments;
  final bool isLoading;
  final bool isLoadingRegistrationPayments;
  final bool isCreating;
  final String? error;

  TuitionPaymentState({
    this.payments = const [],
    this.registrationPayments = const [],
    this.isLoading = false,
    this.isLoadingRegistrationPayments = false,
    this.isCreating = false,
    this.error,
  });

  TuitionPaymentState copyWith({
    List<TuitionPaymentModel>? payments,
    List<TuitionPaymentModel>? registrationPayments,
    bool? isLoading,
    bool? isLoadingRegistrationPayments,
    bool? isCreating,
    String? error,
  }) {
    return TuitionPaymentState(
      payments: payments ?? this.payments,
      registrationPayments: registrationPayments ?? this.registrationPayments,
      isLoading: isLoading ?? this.isLoading,
      isLoadingRegistrationPayments:
          isLoadingRegistrationPayments ?? this.isLoadingRegistrationPayments,
      isCreating: isCreating ?? this.isCreating,
      error: error,
    );
  }
}

class TuitionPaymentNotifier extends StateNotifier<TuitionPaymentState> {
  final TuitionPaymentService _service;

  TuitionPaymentNotifier(this._service) : super(TuitionPaymentState());

  Future<void> getPayments() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _service.getTuitionPayments();
      state = state.copyWith(payments: response.data, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> getPaymentsByRegistration(String registrationId) async {
    state = state.copyWith(isLoadingRegistrationPayments: true, error: null);
    try {
      final response = await _service.getPaymentsByRegistration(registrationId);
      state = state.copyWith(
        registrationPayments: response.data,
        isLoadingRegistrationPayments: false,
      );
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoadingRegistrationPayments: false,
      );
    }
  }

  void clearRegistrationPayments() {
    state = state.copyWith(registrationPayments: []);
  }

  Future<TuitionPaymentModel?> createPayment(
    TuitionPaymentRequest request,
  ) async {
    state = state.copyWith(isCreating: true, error: null);
    try {
      final response = await _service.createTuitionPayment(request);
      state = state.copyWith(
        payments: [...state.payments, response.data],
        registrationPayments: [...state.registrationPayments, response.data],
        isCreating: false,
      );
      return response.data;
    } catch (e) {
      state = state.copyWith(error: e.toString(), isCreating: false);
      return null;
    }
  }

  Future<bool> deletePayment(String id) async {
    try {
      await _service.deleteTuitionPayment(id);
      state = state.copyWith(
        payments: state.payments
            .where((p) => p.tuitionPaymentId != id)
            .toList(),
        registrationPayments: state.registrationPayments
            .where((p) => p.tuitionPaymentId != id)
            .toList(),
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }
}

final tuitionPaymentProvider =
    StateNotifierProvider<TuitionPaymentNotifier, TuitionPaymentState>(
      (ref) => TuitionPaymentNotifier(ref.watch(tuitionPaymentServiceProvider)),
    );
