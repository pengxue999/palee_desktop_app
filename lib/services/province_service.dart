import 'package:palee_elite_training_center/core/utils/http_helper.dart';
import '../models/province_model.dart';

class ProvinceService {
  final HttpHelper _http = HttpHelper();

  Future<ProvinceResponse> getProvinces() async {
    final response = await _http.get('/provinces');
    return ProvinceResponse.fromJson(_http.handleJson(response));
  }

  Future<ProvinceSingleResponse> getProvinceById(int provinceId) async {
    final response = await _http.get('/provinces/$provinceId');
    return ProvinceSingleResponse.fromJson(_http.handleJson(response));
  }

  Future<ProvinceSingleResponse> createProvince(ProvinceRequest request) async {
    final response = await _http.post('/provinces', body: request.toJson());
    return ProvinceSingleResponse.fromJson(_http.handleJson(response));
  }

  Future<ProvinceSingleResponse> updateProvince(
    int provinceId,
    ProvinceRequest request,
  ) async {
    final response = await _http.put(
      '/provinces/$provinceId',
      body: request.toJson(),
    );
    return ProvinceSingleResponse.fromJson(_http.handleJson(response));
  }

  Future<void> deleteProvince(int provinceId) async {
    final response = await _http.delete('/provinces/$provinceId');
    _http.handleJson(response);
  }
}
