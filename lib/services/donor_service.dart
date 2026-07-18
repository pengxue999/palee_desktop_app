import '../core/utils/http_helper.dart';
import '../models/donor_model.dart';

class DonorService {
  final HttpHelper _http = HttpHelper();

  Future<DonorListResponse> getDonors() async {
    final response = await _http.get('/donors');
    return DonorListResponse.fromJson(_http.handleJson(response));
  }

  Future<DonorSingleResponse> getDonorById(String donorId) async {
    final response = await _http.get('/donors/$donorId');
    return DonorSingleResponse.fromJson(_http.handleJson(response));
  }

  Future<DonorSingleResponse> createDonor(DonorRequest request) async {
    final response = await _http.post('/donors', body: request.toJson());
    return DonorSingleResponse.fromJson(_http.handleJson(response));
  }

  Future<DonorSingleResponse> updateDonor(
    String donorId,
    DonorRequest request,
  ) async {
    final response = await _http.put(
      '/donors/$donorId',
      body: request.toJson(),
    );
    return DonorSingleResponse.fromJson(_http.handleJson(response));
  }

  Future<void> deleteDonor(String donorId) async {
    final response = await _http.delete('/donors/$donorId');
    _http.handleJson(response);
  }
}
