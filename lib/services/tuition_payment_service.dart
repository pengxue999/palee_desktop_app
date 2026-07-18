import 'dart:typed_data';

import '../core/utils/http_helper.dart';
import '../models/tuition_payment_model.dart';

class TuitionPaymentService {
  final HttpHelper _http = HttpHelper();

  Future<TuitionPaymentListResponse> getTuitionPayments() async {
    final response = await _http.get('/tuition-payments');
    return TuitionPaymentListResponse.fromJson(_http.handleJson(response));
  }

  Future<TuitionPaymentListResponse> getPaymentsByRegistration(
    String registrationId,
  ) async {
    final response = await _http.get(
      '/tuition-payments/by-registration/$registrationId',
    );
    return TuitionPaymentListResponse.fromJson(_http.handleJson(response));
  }

  Future<TuitionPaymentSingleResponse> getTuitionPaymentById(String id) async {
    final response = await _http.get('/tuition-payments/$id');
    return TuitionPaymentSingleResponse.fromJson(_http.handleJson(response));
  }

  Future<TuitionPaymentSingleResponse> createTuitionPayment(
    TuitionPaymentRequest request,
  ) async {
    final response = await _http.post(
      '/tuition-payments',
      body: request.toJson(),
    );
    return TuitionPaymentSingleResponse.fromJson(_http.handleJson(response));
  }

  Future<Uint8List> createTuitionPaymentReceiptPdf(String paymentId) async {
    final response = await _http.get(
      '/tuition-payments/$paymentId/receipt-pdf',
      headers: {'Accept': 'application/pdf'},
      timeout: const Duration(seconds: 90),
    );

    if (response.statusCode != 200) {
      _http.handleJson(response);
      throw Exception('ບໍ່ສາມາດສ້າງ PDF ໄດ້');
    }

    return response.bodyBytes;
  }

  Future<Uint8List> createTuitionPaymentHistoryPdf(
    String registrationId,
  ) async {
    final response = await _http.get(
      '/tuition-payments/by-registration/$registrationId/history-pdf',
      headers: {'Accept': 'application/pdf'},
      timeout: const Duration(seconds: 90),
    );

    if (response.statusCode != 200) {
      _http.handleJson(response);
      throw Exception('ບໍ່ສາມາດສ້າງ PDF ສະຫຼຸບການຈ່າຍໄດ້');
    }

    return response.bodyBytes;
  }

  Future<void> deleteTuitionPayment(String id) async {
    final response = await _http.delete('/tuition-payments/$id');
    _http.handleJson(response);
  }
}
