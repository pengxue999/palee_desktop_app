import '../core/utils/http_helper.dart';
import '../models/income_model.dart';

class IncomeService {
  final HttpHelper _http = HttpHelper();

  Future<List<IncomeModel>> getIncomes() async {
    final response = await _http.get('/incomes');
    final json = _http.handleJson(response);
    final list = json['data'] as List<dynamic>;
    return list
        .map((e) => IncomeModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<IncomeModel> createIncome(IncomeRequest request) async {
    final response = await _http.post('/incomes', body: request.toJson());
    final json = _http.handleJson(response);
    return IncomeModel.fromJson(json['data'] as Map<String, dynamic>);
  }

  Future<IncomeModel> updateIncome(
    int incomeId,
    IncomeUpdateRequest request,
  ) async {
    final response = await _http.put(
      '/incomes/$incomeId',
      body: request.toJson(),
    );
    final json = _http.handleJson(response);
    return IncomeModel.fromJson(json['data'] as Map<String, dynamic>);
  }

  Future<void> deleteIncome(int incomeId) async {
    final response = await _http.delete('/incomes/$incomeId');
    _http.handleJson(response);
  }
}
