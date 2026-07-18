import 'dart:typed_data';

import 'package:palee_elite_training_center/core/utils/http_helper.dart';

import '../core/utils/enum_localization.dart';
import '../models/report_models.dart';

class ReportService {
  final HttpHelper _http = HttpHelper();

  Future<ExportReportResponse> exportSalaryPaymentReport({
    int? month,
    String? teacherId,
    String? status,
    String format = 'excel',
  }) async {
    final queryParams = <String, String>{'format': format};
    if (month != null) queryParams['month'] = month.toString();
    if (teacherId != null) queryParams['teacher_id'] = teacherId;
    if (status != null) queryParams['status'] = status;

    final queryString = queryParams.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');

    final response = await _http.get(
      '/reports/salary-payments/export?$queryString',
    );
    return ExportReportResponse.fromJson(_http.handleJson(response));
  }

  Future<Uint8List> createSalaryPaymentReportPdf({
    int? month,
    String? teacherId,
    String? status,
  }) async {
    final queryParams = <String, String>{};
    if (month != null) queryParams['month'] = month.toString();
    if (teacherId != null) queryParams['teacher_id'] = teacherId;
    if (status != null) queryParams['status'] = status;

    final queryString = queryParams.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');

    final response = await _http.get(
      '/reports/salary-payments/report-pdf${queryString.isEmpty ? '' : '?$queryString'}',
      headers: {'Accept': 'application/pdf'},
      timeout: const Duration(seconds: 90),
    );

    if (response.statusCode != 200) {
      _http.handleJson(response);
      throw Exception('ບໍ່ສາມາດສ້າງ PDF ໄດ້');
    }

    return response.bodyBytes;
  }

  Future<FinanceReportResponse> getFinanceReport({
    String? academicId,
    int? year,
  }) async {
    final queryParams = <String, String>{};
    if (academicId != null) queryParams['academic_id'] = academicId;
    if (year != null) queryParams['year'] = year.toString();

    final queryString = queryParams.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');

    final response = await _http.get('/reports/finance?$queryString');
    return FinanceReportResponse.fromJson(_http.handleJson(response));
  }

  Future<ExportReportResponse> exportFinanceReport({
    String? academicId,
    int? year,
    String tab = 'overview',
    String format = 'excel',
  }) async {
    final queryParams = <String, String>{'format': format, 'tab': tab};
    if (academicId != null) queryParams['academic_id'] = academicId;
    if (year != null) queryParams['year'] = year.toString();

    final queryString = queryParams.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');

    final response = await _http.get('/reports/finance/export?$queryString');
    return ExportReportResponse.fromJson(_http.handleJson(response));
  }

  Future<Uint8List> createFinanceReportPdf({
    String? academicId,
    int? year,
    String tab = 'overview',
  }) async {
    final queryParams = <String, String>{'tab': tab};
    if (academicId != null) queryParams['academic_id'] = academicId;
    if (year != null) queryParams['year'] = year.toString();

    final queryString = queryParams.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');

    final response = await _http.get(
      '/reports/finance/report-pdf${queryString.isEmpty ? '' : '?$queryString'}',
      headers: {'Accept': 'application/pdf'},
      timeout: const Duration(seconds: 90),
    );

    if (response.statusCode != 200) {
      _http.handleJson(response);
      throw Exception('ບໍ່ສາມາດສ້າງ PDF ໄດ້');
    }

    return response.bodyBytes;
  }

  Future<StudentReportResponse> getStudentReport({
    String? academicId,
    int? provinceId,
    int? districtId,
    String? scholarship,
    String? gender,
  }) async {
    final queryParams = <String, String>{};
    if (academicId != null) queryParams['academic_id'] = academicId;
    if (provinceId != null) queryParams['province_id'] = provinceId.toString();
    if (districtId != null) queryParams['district_id'] = districtId.toString();
    if (scholarship != null) queryParams['scholarship'] = scholarship;
    if (gender != null) queryParams['gender'] = gender;

    final queryString = queryParams.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');

    final response = await _http.get('/reports/students?$queryString');
    return StudentReportResponse.fromJson(_http.handleJson(response));
  }

  Future<ExportReportResponse> exportStudentReport({
    String? academicId,
    int? provinceId,
    int? districtId,
    String? scholarship,
    String? gender,
    String format = 'excel',
  }) async {
    final queryParams = <String, String>{'format': format};
    if (academicId != null) queryParams['academic_id'] = academicId;
    if (provinceId != null) queryParams['province_id'] = provinceId.toString();
    if (districtId != null) queryParams['district_id'] = districtId.toString();
    if (scholarship != null) queryParams['scholarship'] = scholarship;
    if (gender != null) queryParams['gender'] = gender;

    final queryString = queryParams.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');

    final response = await _http.get('/reports/students/export?$queryString');
    return ExportReportResponse.fromJson(_http.handleJson(response));
  }

  Future<Uint8List> createStudentReportPdf({
    String? academicId,
    int? provinceId,
    int? districtId,
    String? scholarship,
    String? gender,
  }) async {
    final queryParams = <String, String>{};
    if (academicId != null) queryParams['academic_id'] = academicId;
    if (provinceId != null) queryParams['province_id'] = provinceId.toString();
    if (districtId != null) queryParams['district_id'] = districtId.toString();
    if (scholarship != null) queryParams['scholarship'] = scholarship;
    if (gender != null) queryParams['gender'] = gender;

    final queryString = queryParams.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');

    final response = await _http.get(
      '/reports/students/report-pdf${queryString.isEmpty ? '' : '?$queryString'}',
      headers: {'Accept': 'application/pdf'},
      timeout: const Duration(seconds: 90),
    );

    if (response.statusCode != 200) {
      _http.handleJson(response);
      throw Exception('ບໍ່ສາມາດສ້າງ PDF ໄດ້');
    }

    return response.bodyBytes;
  }

  Future<ExportReportResponse> exportAssessmentReport({
    String? academicId,
    required String semester,
    String? subjectId,
    String? levelId,
    String? ranking,
    String format = 'excel',
  }) async {
    final queryParams = <String, String>{
      'semester': semester,
      'format': format,
    };
    if (academicId != null && academicId.isNotEmpty) {
      queryParams['academic_id'] = academicId;
    }
    if (subjectId != null && subjectId.isNotEmpty) {
      queryParams['subject_id'] = subjectId;
    }
    if (levelId != null && levelId.isNotEmpty) {
      queryParams['level_id'] = levelId;
    }
    if (ranking != null && ranking.isNotEmpty) {
      queryParams['ranking'] = ranking;
    }

    final queryString = queryParams.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');

    final response = await _http.get(
      '/reports/assessment-results/export?$queryString',
    );
    return ExportReportResponse.fromJson(_http.handleJson(response));
  }

  Future<Uint8List> createAssessmentReportPdf({
    String? academicId,
    required String semester,
    String? subjectId,
    String? levelId,
    String? ranking,
  }) async {
    final queryParams = <String, String>{'semester': semester};
    if (academicId != null && academicId.isNotEmpty) {
      queryParams['academic_id'] = academicId;
    }
    if (subjectId != null && subjectId.isNotEmpty) {
      queryParams['subject_id'] = subjectId;
    }
    if (levelId != null && levelId.isNotEmpty) {
      queryParams['level_id'] = levelId;
    }
    if (ranking != null && ranking.isNotEmpty) {
      queryParams['ranking'] = ranking;
    }

    final queryString = queryParams.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');

    final response = await _http.get(
      '/reports/assessment-results/report-pdf?$queryString',
      headers: {'Accept': 'application/pdf'},
      timeout: const Duration(seconds: 90),
    );

    if (response.statusCode != 200) {
      _http.handleJson(response);
      throw Exception('ບໍ່ສາມາດສ້າງ PDF ໄດ້');
    }

    return response.bodyBytes;
  }

  Future<StudentSummaryResponse> getStudentSummary({String? academicId}) async {
    final queryString = academicId != null
        ? '?academic_id=${Uri.encodeComponent(academicId)}'
        : '';

    final response = await _http.get('/reports/students/summary$queryString');
    return StudentSummaryResponse.fromJson(_http.handleJson(response));
  }

  Future<TeacherAttendanceReportResponse> getTeacherAttendanceReport({
    String? academicId,
    String? month,
    String? status,
    String? teacherId,
  }) async {
    final queryParams = <String, String>{};
    if (academicId != null) queryParams['academic_id'] = academicId;
    if (month != null) queryParams['month'] = month;
    if (status != null) queryParams['status'] = apiTeachingStatus(status);
    if (teacherId != null) queryParams['teacher_id'] = teacherId;

    final queryString = queryParams.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');

    final response = await _http.get(
      '/reports/teacher-attendance?$queryString',
    );
    return TeacherAttendanceReportResponse.fromJson(_http.handleJson(response));
  }

  Future<ExportReportResponse> exportTeacherAttendanceReport({
    String? academicId,
    String? month,
    String? status,
    String? teacherId,
    String format = 'excel',
  }) async {
    final queryParams = <String, String>{'format': format};
    if (academicId != null) queryParams['academic_id'] = academicId;
    if (month != null) queryParams['month'] = month;
    if (status != null) queryParams['status'] = apiTeachingStatus(status);
    if (teacherId != null) queryParams['teacher_id'] = teacherId;

    final queryString = queryParams.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');

    final response = await _http.get(
      '/reports/teacher-attendance/export?$queryString',
    );
    return ExportReportResponse.fromJson(_http.handleJson(response));
  }

  Future<Uint8List> createTeacherAttendanceReportPdf({
    String? academicId,
    String? month,
    String? status,
    String? teacherId,
  }) async {
    final queryParams = <String, String>{};
    if (academicId != null) queryParams['academic_id'] = academicId;
    if (month != null) queryParams['month'] = month;
    if (status != null) queryParams['status'] = apiTeachingStatus(status);
    if (teacherId != null) queryParams['teacher_id'] = teacherId;

    final queryString = queryParams.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');

    final response = await _http.get(
      '/reports/teacher-attendance/report-pdf${queryString.isEmpty ? '' : '?$queryString'}',
      headers: {'Accept': 'application/pdf'},
      timeout: const Duration(seconds: 90),
    );

    if (response.statusCode != 200) {
      _http.handleJson(response);
      throw Exception('ບໍ່ສາມາດສ້າງ PDF ໄດ້');
    }

    return response.bodyBytes;
  }

  Future<PopularSubjectsReportResponse> getPopularSubjectsReport({
    String? academicId,
  }) async {
    final queryParams = <String, String>{};
    if (academicId != null) queryParams['academic_id'] = academicId;

    final queryString = queryParams.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');

    final response = await _http.get('/reports/popular-subjects?$queryString');
    return PopularSubjectsReportResponse.fromJson(_http.handleJson(response));
  }

  Future<ExportReportResponse> exportPopularSubjectsReport({
    String? academicId,
    String format = 'excel',
  }) async {
    final queryParams = <String, String>{'format': format};
    if (academicId != null) queryParams['academic_id'] = academicId;

    final queryString = queryParams.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');

    final response = await _http.get(
      '/reports/popular-subjects/export?$queryString',
    );
    return ExportReportResponse.fromJson(_http.handleJson(response));
  }

  Future<ExportReportResponse> exportPopularSubjectLevelDetailReport({
    String? academicId,
    required String subjectName,
    required String subjectCategory,
    required String levelName,
    String format = 'excel',
  }) async {
    final queryParams = <String, String>{
      'format': format,
      'subject_name': subjectName,
      'subject_category': subjectCategory,
      'level_name': levelName,
    };
    if (academicId != null) queryParams['academic_id'] = academicId;

    final queryString = queryParams.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');

    final response = await _http.get(
      '/reports/popular-subjects/level-detail/export?$queryString',
    );
    return ExportReportResponse.fromJson(_http.handleJson(response));
  }

  Future<Uint8List> createPopularSubjectsReportPdf({String? academicId}) async {
    final queryParams = <String, String>{};
    if (academicId != null) queryParams['academic_id'] = academicId;

    final queryString = queryParams.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');

    final response = await _http.get(
      '/reports/popular-subjects/report-pdf${queryString.isEmpty ? '' : '?$queryString'}',
      headers: {'Accept': 'application/pdf'},
      timeout: const Duration(seconds: 90),
    );

    if (response.statusCode != 200) {
      _http.handleJson(response);
      throw Exception('ບໍ່ສາມາດສ້າງ PDF ໄດ້');
    }

    return response.bodyBytes;
  }

  Future<Uint8List> createPopularSubjectLevelDetailPdf({
    String? academicId,
    required String subjectName,
    required String subjectCategory,
    required String levelName,
  }) async {
    final queryParams = <String, String>{
      'subject_name': subjectName,
      'subject_category': subjectCategory,
      'level_name': levelName,
    };
    if (academicId != null) queryParams['academic_id'] = academicId;

    final queryString = queryParams.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');

    final response = await _http.get(
      '/reports/popular-subjects/level-detail/report-pdf?$queryString',
      headers: {'Accept': 'application/pdf'},
      timeout: const Duration(seconds: 90),
    );

    if (response.statusCode != 200) {
      _http.handleJson(response);
      throw Exception('ບໍ່ສາມາດສ້າງ PDF ໄດ້');
    }

    return response.bodyBytes;
  }

  Future<RegistrationReportResponse> getRegistrationReport({
    String? academicId,
    String? subjectId,
    String? levelId,
    String? status,
    String? scholarship,
  }) async {
    final queryParams = <String, String>{};
    if (academicId != null) queryParams['academic_id'] = academicId;
    if (subjectId != null) queryParams['subject_id'] = subjectId;
    if (levelId != null) queryParams['level_id'] = levelId;
    if (status != null) queryParams['status'] = status;
    if (scholarship != null) queryParams['scholarship'] = scholarship;

    final queryString = queryParams.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');

    final response = await _http.get('/reports/registrations?$queryString');
    return RegistrationReportResponse.fromJson(_http.handleJson(response));
  }

  Future<ExportReportResponse> exportRegistrationReport({
    String? academicId,
    String? subjectId,
    String? levelId,
    String? status,
    String? scholarship,
    String format = 'excel',
  }) async {
    final queryParams = <String, String>{'format': format};
    if (academicId != null) queryParams['academic_id'] = academicId;
    if (subjectId != null) queryParams['subject_id'] = subjectId;
    if (levelId != null) queryParams['level_id'] = levelId;
    if (status != null) queryParams['status'] = status;
    if (scholarship != null) queryParams['scholarship'] = scholarship;

    final queryString = queryParams.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');

    final response = await _http.get(
      '/reports/registrations/export?$queryString',
    );
    return ExportReportResponse.fromJson(_http.handleJson(response));
  }

  Future<Uint8List> createRegistrationReportPdf({
    String? academicId,
    String? subjectId,
    String? levelId,
    String? status,
    String? scholarship,
  }) async {
    final queryParams = <String, String>{};
    if (academicId != null) queryParams['academic_id'] = academicId;
    if (subjectId != null) queryParams['subject_id'] = subjectId;
    if (levelId != null) queryParams['level_id'] = levelId;
    if (status != null) queryParams['status'] = status;
    if (scholarship != null) queryParams['scholarship'] = scholarship;

    final queryString = queryParams.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');

    final response = await _http.get(
      '/reports/registrations/report-pdf${queryString.isEmpty ? '' : '?$queryString'}',
      headers: {'Accept': 'application/pdf'},
      timeout: const Duration(seconds: 90),
    );

    if (response.statusCode != 200) {
      _http.handleJson(response);
      throw Exception('ບໍ່ສາມາດສ້າງ PDF ໄດ້');
    }

    return response.bodyBytes;
  }

  Future<ExportReportResponse> exportDonationReport({
    String? donorId,
    String? donationCategory,
    int? year,
    String format = 'excel',
  }) async {
    final queryParams = <String, String>{'format': format};
    if (donorId != null) queryParams['donor_id'] = donorId;
    if (donationCategory != null) {
      queryParams['donation_category'] = donationCategory;
    }
    if (year != null) queryParams['year'] = year.toString();

    final queryString = queryParams.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');

    final response = await _http.get('/reports/donations/export?$queryString');
    return ExportReportResponse.fromJson(_http.handleJson(response));
  }

  Future<Uint8List> createDonationReportPdf({
    String? donorId,
    String? donationCategory,
    int? year,
  }) async {
    final queryParams = <String, String>{};
    if (donorId != null) queryParams['donor_id'] = donorId;
    if (donationCategory != null) {
      queryParams['donation_category'] = donationCategory;
    }
    if (year != null) queryParams['year'] = year.toString();

    final queryString = queryParams.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');

    final response = await _http.get(
      '/reports/donations/report-pdf${queryString.isEmpty ? '' : '?$queryString'}',
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
