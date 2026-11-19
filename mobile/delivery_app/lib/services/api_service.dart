import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import 'storage_service.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, {this.statusCode});

  bool get isUnauthorized => statusCode == 401;
  bool get isNotFound => statusCode == 404;

  @override
  String toString() => message;
}

class ApiService {
  static Future<Map<String, String>> _getHeaders(
      {bool includeAuth = true}) async {
    final headers = {
      'Content-Type': 'application/json',
    };

    if (includeAuth) {
      final token = await StorageService.getToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  static Future<Map<String, dynamic>> get(
    String endpoint, {
    bool includeAuth = true,
  }) {
    return _send(() async => http.get(
          Uri.parse('${AppConfig.baseUrl}$endpoint'),
          headers: await _getHeaders(includeAuth: includeAuth),
        ));
  }

  static Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> body, {
    bool includeAuth = true,
  }) {
    return _send(() async => http.post(
          Uri.parse('${AppConfig.baseUrl}$endpoint'),
          headers: await _getHeaders(includeAuth: includeAuth),
          body: jsonEncode(body),
        ));
  }

  static Future<Map<String, dynamic>> put(
    String endpoint,
    Map<String, dynamic> body, {
    bool includeAuth = true,
  }) {
    return _send(() async => http.put(
          Uri.parse('${AppConfig.baseUrl}$endpoint'),
          headers: await _getHeaders(includeAuth: includeAuth),
          body: jsonEncode(body),
        ));
  }

  static Future<Map<String, dynamic>> delete(
    String endpoint, {
    bool includeAuth = true,
  }) {
    return _send(() async => http.delete(
          Uri.parse('${AppConfig.baseUrl}$endpoint'),
          headers: await _getHeaders(includeAuth: includeAuth),
        ));
  }

  static Future<Map<String, dynamic>> _send(
      Future<http.Response> Function() request) async {
    http.Response response;
    try {
      response = await request().timeout(AppConfig.receiveTimeout);
    } catch (e) {
      throw ApiException('Erreur de connexion: ${e.toString()}');
    }
    return _handleResponse(response);
  }

  static Map<String, dynamic> _handleResponse(http.Response response) {
    dynamic data;
    try {
      data = jsonDecode(response.body);
    } catch (_) {
      throw ApiException(
        'Réponse invalide du serveur (${response.statusCode})',
        statusCode: response.statusCode,
      );
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data is Map<String, dynamic> ? data : {'success': true, 'data': data};
    }

    final message = data is Map ? data['message'] : null;
    throw ApiException(
      message?.toString() ?? 'Une erreur est survenue',
      statusCode: response.statusCode,
    );
  }
}
