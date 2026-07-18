import 'package:palee_elite_training_center/core/utils/http_helper.dart';
import '../models/fee_model.dart';

class FeeService {
  final HttpHelper _http = HttpHelper();

  Future<FeeListResponse> getFees() async {
    final response = await _http.get('/fees');
    return FeeListResponse.fromJson(_http.handleJson(response));
  }

  Future<FeeSingleResponse> getFeeById(String feeId) async {
    final response = await _http.get('/fees/$feeId');
    return FeeSingleResponse.fromJson(_http.handleJson(response));
  }

  Future<FeeSingleResponse> createFee(FeeRequest request) async {
    final response = await _http.post('/fees', body: request.toJson());
    return FeeSingleResponse.fromJson(_http.handleJson(response));
  }

  Future<FeeSingleResponse> updateFee(String feeId, FeeRequest request) async {
    final response = await _http.put('/fees/$feeId', body: request.toJson());
    return FeeSingleResponse.fromJson(_http.handleJson(response));
  }

  Future<void> deleteFee(String feeId) async {
    final response = await _http.delete('/fees/$feeId');
    _http.handleJson(response);
  }
}
