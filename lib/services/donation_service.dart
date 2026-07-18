import '../core/utils/http_helper.dart';
import 'dart:typed_data';
import '../models/donation_model.dart';

class DonationService {
  final HttpHelper _http = HttpHelper();

  Future<DonationListResponse> getDonations() async {
    final response = await _http.get('/donations');
    return DonationListResponse.fromJson(_http.handleJson(response));
  }

  Future<DonationSingleResponse> getDonationById(int donationId) async {
    final response = await _http.get('/donations/$donationId');
    return DonationSingleResponse.fromJson(_http.handleJson(response));
  }

  Future<DonationListResponse> getDonationsByDonor(String donorId) async {
    final response = await _http.get('/donations/by-donor/$donorId');
    return DonationListResponse.fromJson(_http.handleJson(response));
  }

  Future<DonationSingleResponse> createDonation(DonationRequest request) async {
    final response = await _http.post('/donations', body: request.toJson());
    return DonationSingleResponse.fromJson(_http.handleJson(response));
  }

  Future<DonationSingleResponse> updateDonation(
    int donationId,
    DonationUpdateRequest request,
  ) async {
    final response = await _http.put(
      '/donations/$donationId',
      body: request.toJson(),
    );
    return DonationSingleResponse.fromJson(_http.handleJson(response));
  }

  Future<void> deleteDonation(int donationId) async {
    final response = await _http.delete('/donations/$donationId');
    _http.handleJson(response);
  }

  Future<Uint8List> getDonationCertificatePdf(int donationId) async {
    final response = await _http.get(
      '/donations/$donationId/certificate-pdf',
      headers: {'Accept': 'application/pdf'},
      timeout: const Duration(seconds: 90),
    );

    if (response.statusCode != 200) {
      _http.handleJson(response);
      throw Exception('ບໍ່ສາມາດສ້າງ PDF ໄດ້');
    }

    return response.bodyBytes;
  }

  Future<Uint8List> getDonationCertificateDocx(int donationId) async {
    final response = await _http.get(
      '/donations/$donationId/certificate-docx',
      headers: {
        'Accept':
            'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      },
      timeout: const Duration(seconds: 90),
    );

    if (response.statusCode != 200) {
      _http.handleJson(response);
      throw Exception('ບໍ່ສາມາດສ້າງ Word ໄດ້');
    }

    return response.bodyBytes;
  }
}
