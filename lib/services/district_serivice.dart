import 'package:palee_elite_training_center/core/utils/http_helper.dart';

import '../models/district_model.dart';

class DistrictService {
  final HttpHelper _http = HttpHelper();

  Future<DistrictResponse> getDistricts() async {
    final response = await _http.get('/districts');
    return DistrictResponse.fromJson(_http.handleJson(response));
  }

  Future<DistrictSingleResponse> getDistrictById(int districtId) async {
    final response = await _http.get('/districts/$districtId');
    return DistrictSingleResponse.fromJson(_http.handleJson(response));
  }

  Future<DistrictResponse> getDistrictsByProvince(int provinceId) async {
    final response = await _http.get('/districts/province/$provinceId');
    return DistrictResponse.fromJson(_http.handleJson(response));
  }

  Future<DistrictSingleResponse> createDistrict(DistrictRequest request) async {
    final response = await _http.post('/districts', body: request.toJson());
    return DistrictSingleResponse.fromJson(_http.handleJson(response));
  }

  Future<DistrictSingleResponse> updateDistrict(
    int districtId,
    DistrictRequest request,
  ) async {
    final response = await _http.put(
      '/districts/$districtId',
      body: request.toJson(),
    );
    return DistrictSingleResponse.fromJson(_http.handleJson(response));
  }

  Future<void> deleteDistrict(int districtId) async {
    final response = await _http.delete('/districts/$districtId');
    _http.handleJson(response);
  }
}
