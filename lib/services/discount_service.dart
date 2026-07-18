import '../core/utils/http_helper.dart';
import '../models/discount_model.dart';

class DiscountService {
  final HttpHelper _http = HttpHelper();

  Future<DiscountListResponse> getDiscounts() async {
    final response = await _http.get('/discounts');
    return DiscountListResponse.fromJson(_http.handleJson(response));
  }

  Future<DiscountSingleResponse> getDiscountById(String discountId) async {
    final response = await _http.get('/discounts/$discountId');
    return DiscountSingleResponse.fromJson(_http.handleJson(response));
  }

  Future<DiscountSingleResponse> createDiscount(DiscountRequest request) async {
    final response = await _http.post('/discounts', body: request.toJson());
    return DiscountSingleResponse.fromJson(_http.handleJson(response));
  }

  Future<DiscountSingleResponse> updateDiscount(
    String discountId,
    DiscountRequest request,
  ) async {
    final response = await _http.put(
      '/discounts/$discountId',
      body: request.toJson(),
    );
    return DiscountSingleResponse.fromJson(_http.handleJson(response));
  }

  Future<void> deleteDiscount(String discountId) async {
    final response = await _http.delete('/discounts/$discountId');
    _http.handleJson(response);
  }
}
