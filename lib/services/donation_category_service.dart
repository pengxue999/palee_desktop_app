import '../core/utils/http_helper.dart';
import '../models/donation_category_model.dart';

class DonationCategoryService {
  final HttpHelper _http = HttpHelper();

  Future<DonationCategoryListResponse> getDonationCategories() async {
    final response = await _http.get('/donation-categories');
    return DonationCategoryListResponse.fromJson(_http.handleJson(response));
  }

  Future<DonationCategorySingleResponse> getDonationCategoryById(
    int donationCategoryId,
  ) async {
    final response = await _http.get(
      '/donation-categories/$donationCategoryId',
    );
    return DonationCategorySingleResponse.fromJson(_http.handleJson(response));
  }

  Future<DonationCategorySingleResponse> createDonationCategory(
    DonationCategoryRequest request,
  ) async {
    final response = await _http.post(
      '/donation-categories',
      body: request.toJson(),
    );
    return DonationCategorySingleResponse.fromJson(_http.handleJson(response));
  }

  Future<DonationCategorySingleResponse> updateDonationCategory(
    int donationCategoryId,
    DonationCategoryRequest request,
  ) async {
    final response = await _http.put(
      '/donation-categories/$donationCategoryId',
      body: request.toJson(),
    );
    return DonationCategorySingleResponse.fromJson(_http.handleJson(response));
  }

  Future<void> deleteDonationCategory(int donationCategoryId) async {
    final response = await _http.delete(
      '/donation-categories/$donationCategoryId',
    );
    _http.handleJson(response);
  }
}
