import '../core/utils/http_helper.dart';
import '../models/registration_detail_model.dart';

class RegistrationDetailService {
  final HttpHelper _http = HttpHelper();

  Future<RegistrationDetailResponse> createRegistrationDetail(
    RegistrationDetailCreateRequest request,
  ) async {
    final response = await _http.post(
      '/registration-details',
      body: request.toJson(),
    );
    return RegistrationDetailResponse.fromJson(_http.handleJson(response));
  }

  Future<List<RegistrationDetailModel>> getRegistrationDetails() async {
    final response = await _http.get('/registration-details');
    final json = _http.handleJson(response);
    final data = json['data'] as List? ?? [];
    return data
        .map((e) => RegistrationDetailModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<RegistrationDetailModel> getRegistrationDetailById(int id) async {
    final response = await _http.get('/registration-details/$id');
    final json = _http.handleJson(response);
    return RegistrationDetailModel.fromJson(
      json['data'] as Map<String, dynamic>,
    );
  }
}
