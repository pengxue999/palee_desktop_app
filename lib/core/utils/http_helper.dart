import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../constants/constant.dart';

class HttpHelper {
  static final HttpHelper _instance = HttpHelper._internal();
  factory HttpHelper() => _instance;
  HttpHelper._internal();

  Map<String, String> _defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  void Function()? onUnauthorized;

  void setDefaultHeaders(Map<String, String> headers) {
    _defaultHeaders = {..._defaultHeaders, ...headers};
  }

  void removeDefaultHeader(String key) {
    _defaultHeaders = {..._defaultHeaders}..remove(key);
  }

  Map<String, String> getHeaders({Map<String, String>? customHeaders}) {
    return {..._defaultHeaders, ...?customHeaders};
  }

  Map<String, dynamic> handleJson(http.Response response) {
    if (response.statusCode == 204) {
      return {
        'code': 'DELETE_SUCCESSFULLY',
        'messages': 'ລຶບຂໍ້ມູນສຳເລັດ',
        'data': null,
      };
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final message = json['messages'] as String? ?? 'ເກີດຂໍ້ຜິດພາດ';

    switch (response.statusCode) {
      case 200:
      case 201:
        return json;

      case 400:
        throw Exception(message);

      case 401:
        onUnauthorized?.call();
        throw UnauthorizedException(message);

      case 403:
        throw ForbiddenException(message);

      case 404:
        throw NotFoundException(message);

      case 409:
        throw ConflictException(message);

      case 422:
        throw ValidationException(message, errors: json['data']);

      case 500:
        throw ServerException(message);

      default:
        throw Exception('[${response.statusCode}] $message');
    }
  }

  Future<http.Response> get(
    String endpoint, {
    Map<String, String>? headers,
    Duration? timeout,
  }) async {
    try {
      final response = await http
          .get(_buildUri(endpoint), headers: getHeaders(customHeaders: headers))
          .timeout(timeout ?? const Duration(seconds: 30));
      return _handleResponse(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<http.Response> post(
    String endpoint, {
    Object? body,
    Map<String, String>? headers,
    Duration? timeout,
  }) async {
    try {
      final response = await http
          .post(
            _buildUri(endpoint),
            headers: getHeaders(customHeaders: headers),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(timeout ?? const Duration(seconds: 30));
      return _handleResponse(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<http.Response> put(
    String endpoint, {
    Object? body,
    Map<String, String>? headers,
    Duration? timeout,
  }) async {
    try {
      final response = await http
          .put(
            _buildUri(endpoint),
            headers: getHeaders(customHeaders: headers),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(timeout ?? const Duration(seconds: 30));
      return _handleResponse(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<http.Response> patch(
    String endpoint, {
    Object? body,
    Map<String, String>? headers,
    Duration? timeout,
  }) async {
    try {
      final response = await http
          .patch(
            _buildUri(endpoint),
            headers: getHeaders(customHeaders: headers),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(timeout ?? const Duration(seconds: 30));
      return _handleResponse(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<http.Response> delete(
    String endpoint, {
    Map<String, String>? headers,
    Duration? timeout,
  }) async {
    try {
      final response = await http
          .delete(
            _buildUri(endpoint),
            headers: getHeaders(customHeaders: headers),
          )
          .timeout(timeout ?? const Duration(seconds: 30));
      return _handleResponse(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<http.Response> postMultipart(
    String endpoint, {
    Map<String, String>? fields,
    Map<String, File>? files,
    Map<String, String>? headers,
    Duration? timeout,
  }) async {
    try {
      final request = http.MultipartRequest('POST', _buildUri(endpoint));

      final mergedHeaders = getHeaders(customHeaders: headers);
      mergedHeaders.remove('Content-Type');
      request.headers.addAll(mergedHeaders);

      if (fields != null) request.fields.addAll(fields);

      if (files != null) {
        for (final entry in files.entries) {
          request.files.add(
            http.MultipartFile(
              entry.key,
              entry.value.openRead(),
              await entry.value.length(),
              filename: entry.value.path.split('/').last,
            ),
          );
        }
      }

      final response = await http.Response.fromStream(
        await request.send().timeout(timeout ?? const Duration(seconds: 30)),
      );
      return _handleResponse(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  http.Response _handleResponse(http.Response response) {
    return response;
  }

  Uri _buildUri(String endpoint) {
    if (endpoint.startsWith('http')) return Uri.parse(endpoint);
    return Uri.parse('${AppConstants.baseUrl}$endpoint');
  }

  Exception _handleError(dynamic error) {
    if (error is SocketException) {
      return Exception('ບໍ່ສາມາດເຊື່ອມຕໍ່ກັບເຊີບເວີໄດ້: ${error.message}');
    } else if (error is HttpException) {
      return Exception('HTTP Error: ${error.message}');
    } else if (error is FormatException) {
      return Exception('ຮູບແບບຂໍ້ມູນບໍ່ຖືກຕ້ອງ: ${error.message}');
    } else {
      return Exception('ເກີດຂໍ້ຜິດພາດ: $error');
    }
  }
}

class NotFoundException implements Exception {
  final String message;
  NotFoundException(this.message);
  @override
  String toString() => message;
}

class ConflictException implements Exception {
  final String message;
  ConflictException(this.message);
  @override
  String toString() => message;
}

class ValidationException implements Exception {
  final String message;
  final List<dynamic>? errors;
  ValidationException(this.message, {this.errors});
  @override
  String toString() => message;
}

class UnauthorizedException implements Exception {
  final String message;
  UnauthorizedException(this.message);
  @override
  String toString() => message;
}

class ForbiddenException implements Exception {
  final String message;
  ForbiddenException(this.message);
  @override
  String toString() => message;
}

class ServerException implements Exception {
  final String message;
  ServerException(this.message);
  @override
  String toString() => message;
}
