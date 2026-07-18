import 'package:palee_elite_training_center/core/utils/http_helper.dart';
import 'package:palee_elite_training_center/models/level_model.dart';

class LevelService {
  final HttpHelper _http = HttpHelper();

  Future<LevelListResponse> getLevels() async {
    final response = await _http.get('/levels');
    return LevelListResponse.fromJson(_http.handleJson(response));
  }

  Future<LevelSingleResponse> getLevelById(String levelId) async {
    final response = await _http.get('/levels/$levelId');
    return LevelSingleResponse.fromJson(_http.handleJson(response));
  }

  Future<LevelSingleResponse> createLevel(LevelRequest request) async {
    final response = await _http.post('/levels', body: request.toJson());
    return LevelSingleResponse.fromJson(_http.handleJson(response));
  }

  Future<LevelSingleResponse> updateLevel(
    String levelId,
    LevelRequest request,
  ) async {
    final response = await _http.put(
      '/levels/$levelId',
      body: request.toJson(),
    );
    return LevelSingleResponse.fromJson(_http.handleJson(response));
  }

  Future<void> deleteLevel(String levelId) async {
    final response = await _http.delete('/levels/$levelId');
    _http.handleJson(response);
  }
}

class LevelRequest {
  final String levelName;

  LevelRequest({required this.levelName});

  Map<String, dynamic> toJson() {
    return {'level_name': levelName};
  }
}

class LevelListResponse {
  final String code;
  final String messages;
  final List<Level> data;

  LevelListResponse({
    required this.code,
    required this.messages,
    required this.data,
  });

  factory LevelListResponse.fromJson(Map<String, dynamic> json) {
    return LevelListResponse(
      code: json['code'] ?? '',
      messages: json['messages'] ?? '',
      data:
          (json['data'] as List?)
              ?.map((item) => Level.fromJson(item))
              .toList() ??
          [],
    );
  }
}

class LevelSingleResponse {
  final String code;
  final String messages;
  final Level data;

  LevelSingleResponse({
    required this.code,
    required this.messages,
    required this.data,
  });

  factory LevelSingleResponse.fromJson(Map<String, dynamic> json) {
    return LevelSingleResponse(
      code: json['code'] ?? '',
      messages: json['messages'] ?? '',
      data: Level.fromJson(json['data']),
    );
  }
}
