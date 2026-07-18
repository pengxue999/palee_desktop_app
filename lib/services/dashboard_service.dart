import 'package:palee_elite_training_center/core/utils/http_helper.dart';
import '../models/dashboard_model.dart';

class DashboardService {
  final HttpHelper _http = HttpHelper();

  Future<DashboardStatsResponse> getDashboardStats({String? academicId}) async {
    String endpoint = '/dashboard/stats';
    if (academicId != null) {
      endpoint = '$endpoint?academic_id=$academicId';
    }
    final response = await _http.get(endpoint);
    return DashboardStatsResponse.fromJson(_http.handleJson(response));
  }
}
