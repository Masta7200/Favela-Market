import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import 'storage_service.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, {this.statusCode});

  bool get isUnauthorized => statusCode == 401;

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

  static Uri _uri(String endpoint) => Uri.parse('${AppConfig.baseUrl}$endpoint');

  /// Runs the request. Only network problems become "Erreur de connexion";
  /// error messages sent by the server are shown as they are.
  static Future<Map<String, dynamic>> _send(
      Future<http.Response> Function() request) async {
    http.Response response;
    try {
      response = await request().timeout(AppConfig.receiveTimeout);
    } on TimeoutException {
      throw ApiException('Le serveur met trop de temps à répondre. Réessayez.');
    } on SocketException {
      throw ApiException('Pas de connexion internet');
    } on http.ClientException catch (e) {
      throw ApiException('Erreur de connexion: ${e.message}');
    }
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> get(
    String endpoint, {
    bool includeAuth = true,
  }) async {
    final headers = await _getHeaders(includeAuth: includeAuth);
    return _send(() => http.get(_uri(endpoint), headers: headers));
  }

  static Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> body, {
    bool includeAuth = true,
  }) async {
    final headers = await _getHeaders(includeAuth: includeAuth);
    return _send(() =>
        http.post(_uri(endpoint), headers: headers, body: jsonEncode(body)));
  }

  static Future<Map<String, dynamic>> put(
    String endpoint,
    Map<String, dynamic> body, {
    bool includeAuth = true,
  }) async {
    final headers = await _getHeaders(includeAuth: includeAuth);
    return _send(() =>
        http.put(_uri(endpoint), headers: headers, body: jsonEncode(body)));
  }

  static Future<Map<String, dynamic>> delete(
    String endpoint, {
    bool includeAuth = true,
  }) async {
    final headers = await _getHeaders(includeAuth: includeAuth);
    return _send(() => http.delete(_uri(endpoint), headers: headers));
  }

  static Map<String, dynamic> _handleResponse(http.Response response) {
    dynamic data;
    try {
      data = jsonDecode(response.body);
    } on FormatException {
      // e.g. an HTML error page from the hosting provider
      throw ApiException('Réponse inattendue du serveur (${response.statusCode})',
          statusCode: response.statusCode);
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data is Map<String, dynamic> ? data : {'success': true, 'data': data};
    }

    final message = data is Map ? data['message']?.toString() : null;
    throw ApiException(message ?? 'Une erreur est survenue',
        statusCode: response.statusCode);
  }
}
