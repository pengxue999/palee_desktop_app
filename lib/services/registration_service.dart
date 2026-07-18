import 'dart:typed_data';

import '../core/utils/http_helper.dart';
import '../models/registration_model.dart';

class RegistrationService {
  final HttpHelper _http = HttpHelper();

  /// ດຶງລາຍການລົງທະບຽນ.
  /// - [academicId] ລະບຸສະເພາະສົກຮຽນທີ່ຕ້ອງການ.
  /// - [allYears] = true ດຶງທຸກສົກຮຽນ (ບໍ່ filter).
  /// - ຖ້າບໍ່ລະບຸທັງສອງ: backend ຈະສົ່ງສະເພາະສົກຮຽນທີ່ ACTIVE ມາໃຫ້.
  Future<RegistrationListResponse> getRegistrations({
    String? academicId,
    bool allYears = false,
  }) async {
    final query = <String, String>{
      if (academicId != null) 'academic_id': academicId,
      if (allYears) 'all_years': 'true',
    };
    final endpoint = query.isEmpty
        ? '/registrations'
        : '/registrations?${Uri(queryParameters: query).query}';
    final response = await _http.get(endpoint);
    return RegistrationListResponse.fromJson(_http.handleJson(response));
  }

  Future<RegistrationSingleResponse> getRegistrationById(
    String registrationId,
  ) async {
    final response = await _http.get('/registrations/$registrationId');
    return RegistrationSingleResponse.fromJson(_http.handleJson(response));
  }

  Future<RegistrationSingleResponse> createRegistration(
    RegistrationRequest request,
  ) async {
    final response = await _http.post('/registrations', body: request.toJson());
    return RegistrationSingleResponse.fromJson(_http.handleJson(response));
  }

  Future<RegistrationSingleResponse> createRegistrationBulk(
    RegistrationRequest request,
    List<Map<String, dynamic>> details,
  ) async {
    final body = {...request.toJson(), 'details': details};
    final response = await _http.post('/registrations/bulk', body: body);
    return RegistrationSingleResponse.fromJson(_http.handleJson(response));
  }

  /// ຖາມ backend ໃຫ້ຄຳນວນ ສ່ວນຫຼຸດ/ຈຳນວນເງິນ ກ່ອນບັນທຶກ.
  /// backend ເປັນຜູ້ຕັດສິນ — frontend ພຽງສະແດງຜົນ.
  Future<RegistrationPreview> previewRegistration({
    required String studentId,
    required List<Map<String, dynamic>> details,
    DateTime? registrationDate,
  }) async {
    final body = {
      'student_id': studentId,
      'details': details,
      if (registrationDate != null)
        'registration_date': registrationDate.toIso8601String(),
    };
    final response = await _http.post('/registrations/preview', body: body);
    final json = _http.handleJson(response);
    final data = json['data'] ?? json;
    return RegistrationPreview.fromJson(data as Map<String, dynamic>);
  }

  /// ດຶງການລົງທະບຽນທີ່ມີຢູ່ແລ້ວຂອງນັກຮຽນ (ສົກປັດຈຸບັນ) ພ້ອມລາຍວິຊາ.
  /// ສົ່ງຄືນ null ຖ້ານັກຮຽນຍັງບໍ່ມີການລົງທະບຽນ.
  Future<StudentRegistration?> getRegistrationByStudent(
    String studentId,
  ) async {
    final response = await _http.get('/registrations/by-student/$studentId');
    final json = _http.handleJson(response);
    final data = json['data'];
    if (data == null) return null;
    return StudentRegistration.fromJson(data as Map<String, dynamic>);
  }

  /// ແກ້ໄຂ 1 ວິຊາ (ປ່ຽນວິຊາ ຫຼື ສະຖານະທຶນ). backend ຈະຄຳນວນສ່ວນຫຼຸດຄືນ.
  Future<void> updateRegistrationDetail(
    int regisDetailId, {
    String? feeId,
    String? scholarship,
  }) async {
    final body = <String, dynamic>{
      if (feeId != null) 'fee_id': feeId,
      if (scholarship != null) 'scholarship': scholarship,
    };
    final response = await _http.put(
      '/registration-details/$regisDetailId',
      body: body,
    );
    _http.handleJson(response);
  }

  /// ລຶບ 1 ວິຊາ. backend ຈະຄຳນວນຄືນ (ແລະ ລຶບການລົງທະບຽນ ຖ້າບໍ່ເຫຼືອວິຊາ).
  Future<void> deleteRegistrationDetail(int regisDetailId) async {
    final response = await _http.delete(
      '/registration-details/$regisDetailId',
    );
    _http.handleJson(response);
  }

  Future<RegistrationSingleResponse> updateRegistration(
    String registrationId,
    RegistrationRequest request,
  ) async {
    final response = await _http.put(
      '/registrations/$registrationId',
      body: request.toJson(),
    );
    return RegistrationSingleResponse.fromJson(_http.handleJson(response));
  }

  Future<void> deleteRegistration(String registrationId) async {
    final response = await _http.delete('/registrations/$registrationId');
    _http.handleJson(response);
  }

  Future<Uint8List> getRegistrationReceiptPdf(String registrationId) async {
    final response = await _http.get(
      '/registrations/$registrationId/receipt-pdf',
      headers: {'Accept': 'application/pdf'},
      timeout: const Duration(seconds: 90),
    );

    if (response.statusCode != 200) {
      _http.handleJson(response);
      throw Exception('ບໍ່ສາມາດສ້າງ PDF ໄດ້');
    }

    return response.bodyBytes;
  }

  Future<Uint8List> createRegistrationReceiptPdf({
    required String registrationId,
    required String registrationDate,
    required String studentName,
    required List<Map<String, Object?>> selectedFees,
    required int tuitionFee,
    required int totalFee,
    required int discountAmount,
    required int netFee,
  }) async {
    final response = await _http.post(
      '/registrations/receipt-pdf',
      body: {
        'registration_id': registrationId,
        'registration_date': registrationDate,
        'student_name': studentName,
        'selected_fees': selectedFees,
        'tuition_fee': tuitionFee,
        'total_fee': totalFee,
        'discount_amount': discountAmount,
        'net_fee': netFee,
      },
      headers: {'Accept': 'application/pdf'},
      timeout: const Duration(seconds: 90),
    );

    if (response.statusCode != 200) {
      _http.handleJson(response);
      throw Exception('ບໍ່ສາມາດສ້າງ PDF ໄດ້');
    }

    return response.bodyBytes;
  }
}
