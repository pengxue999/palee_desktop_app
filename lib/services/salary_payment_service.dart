import 'dart:typed_data';

import '../models/salary_payment_model.dart';
import '../core/utils/http_helper.dart';

class SalaryPaymentService {
  final HttpHelper _http = HttpHelper();

  Future<SalaryPaymentResponse> getAll({
    String? teacherId,
    int? year,
    int? month,
  }) async {
    final params = <String, String>{};
    if (teacherId != null) params['teacher_id'] = teacherId;
    if (year != null) params['year'] = year.toString();
    if (month != null) params['month'] = month.toString();
    final query = params.isNotEmpty
        ? '?${params.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&')}'
        : '';
    final response = await _http.get('/salary-payments$query');
    return SalaryPaymentResponse.fromJson(_http.handleJson(response));
  }

  Future<SalaryPaymentSingleResponse> getById(String paymentId) async {
    final response = await _http.get('/salary-payments/$paymentId');
    return SalaryPaymentSingleResponse.fromJson(_http.handleJson(response));
  }

  Future<SalaryPaymentResponse> getByTeacher(String teacherId) async {
    final response = await _http.get(
      '/salary-payments/teacher/$teacherId/payments',
    );
    return SalaryPaymentResponse.fromJson(_http.handleJson(response));
  }

  Future<List<TeachingMonth>> getTeachingMonths({String? teacherId}) async {
    final query = teacherId != null
        ? '?teacher_id=${Uri.encodeComponent(teacherId)}'
        : '';
    final response = await _http.get(
      '/salary-payments/options/teaching-months$query',
    );
    final json = _http.handleJson(response);
    final data = json['data'] as List<dynamic>;
    return data
        .map((e) => TeachingMonth.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<TeacherMonthlySummary>> getTeachersMonthly(
    int month,
    int year,
  ) async {
    final response = await _http.get(
      '/salary-payments/teachers/monthly?month=$month&year=$year',
    );
    final json = _http.handleJson(response);
    final data = json['data'] as List<dynamic>;
    return data
        .map((e) => TeacherMonthlySummary.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<TeacherSalaryCalculation> calculateSalary(
    String teacherId,
    int month,
    int year,
  ) async {
    final response = await _http.get(
      '/salary-payments/calculate/$teacherId?month=$month&year=$year',
    );
    final json = _http.handleJson(response);
    return TeacherSalaryCalculation.fromJson(
      json['data'] as Map<String, dynamic>,
    );
  }

  Future<TeacherPaymentSummary> getTeacherSummary(
    String teacherId,
    int month,
    int year,
  ) async {
    final response = await _http.get(
      '/salary-payments/teacher/$teacherId/summary?month=$month&year=$year',
    );
    final json = _http.handleJson(response);
    return TeacherPaymentSummary.fromJson(json['data'] as Map<String, dynamic>);
  }

  Future<SalaryPaymentSingleResponse> createPayment(
    SalaryPaymentRequest request,
  ) async {
    final response = await _http.post(
      '/salary-payments',
      body: request.toJson(),
    );
    return SalaryPaymentSingleResponse.fromJson(_http.handleJson(response));
  }

  Future<Uint8List> createSalaryPaymentReceiptPdf(String paymentId) async {
    final response = await _http.get(
      '/salary-payments/$paymentId/receipt-pdf',
      headers: {'Accept': 'application/pdf'},
      timeout: const Duration(seconds: 90),
    );

    if (response.statusCode != 200) {
      _http.handleJson(response);
      throw Exception('ບໍ່ສາມາດສ້າງ PDF ໄດ້');
    }

    return response.bodyBytes;
  }

  Future<SalaryPaymentSingleResponse> updatePayment(
    String paymentId,
    Map<String, dynamic> data,
  ) async {
    final response = await _http.put('/salary-payments/$paymentId', body: data);
    return SalaryPaymentSingleResponse.fromJson(_http.handleJson(response));
  }

  Future<void> deletePayment(String paymentId) async {
    final response = await _http.delete('/salary-payments/$paymentId');
    _http.handleJson(response);
  }
}
