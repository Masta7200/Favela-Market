import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../services/storageservices.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // Get headers with auth token
  Future<Map<String, String>> _getHeaders({bool includeAuth = true}) async {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (includeAuth) {
      final token = await StorageService.getToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  // Handle API Response
  Map<String, dynamic> _handleResponse(http.Response response) {
    try {
      final Map<String, dynamic> data = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return data;
      } else {
        throw ApiException(
          message: data['message'] ?? 'Une erreur est survenue',
          statusCode: response.statusCode,
        );
      }
    } on FormatException {
      throw ApiException(
        message: 'Erreur de format de réponse',
        statusCode: response.statusCode,
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        message: 'Une erreur est survenue: ${e.toString()}',
        statusCode: response.statusCode,
      );
    }
  }

  // GET Request
  Future<Map<String, dynamic>> get(
    String endpoint, {
    bool includeAuth = true,
  }) async {
    try {
      final headers = await _getHeaders(includeAuth: includeAuth);
      final response = await http
          .get(
            Uri.parse(endpoint),
            headers: headers,
          )
          .timeout(AppConfig.receiveTimeout);

      return _handleResponse(response);
    } on SocketException {
      throw ApiException(
        message: 'Pas de connexion internet',
        statusCode: 0,
      );
    } on HttpException {
      throw ApiException(
        message: 'Erreur de connexion au serveur',
        statusCode: 0,
      );
    } on FormatException {
      throw ApiException(
        message: 'Format de réponse invalide',
        statusCode: 0,
      );
    }
  }

  // POST Request
  Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> body, {
    bool includeAuth = true,
  }) async {
    try {
      final headers = await _getHeaders(includeAuth: includeAuth);
      final response = await http
          .post(
            Uri.parse(endpoint),
            headers: headers,
            body: jsonEncode(body),
          )
          .timeout(AppConfig.receiveTimeout);

      return _handleResponse(response);
    } on SocketException {
      throw ApiException(
        message: 'Pas de connexion internet',
        statusCode: 0,
      );
    } on HttpException {
      throw ApiException(
        message: 'Erreur de connexion au serveur',
        statusCode: 0,
      );
    } on FormatException {
      throw ApiException(
        message: 'Format de réponse invalide',
        statusCode: 0,
      );
    }
  }

  // PUT Request
  Future<Map<String, dynamic>> put(
    String endpoint,
    Map<String, dynamic> body, {
    bool includeAuth = true,
  }) async {
    try {
      final headers = await _getHeaders(includeAuth: includeAuth);
      final response = await http
          .put(
            Uri.parse(endpoint),
            headers: headers,
            body: jsonEncode(body),
          )
          .timeout(AppConfig.receiveTimeout);

      return _handleResponse(response);
    } on SocketException {
      throw ApiException(
        message: 'Pas de connexion internet',
        statusCode: 0,
      );
    } on HttpException {
      throw ApiException(
        message: 'Erreur de connexion au serveur',
        statusCode: 0,
      );
    } on FormatException {
      throw ApiException(
        message: 'Format de réponse invalide',
        statusCode: 0,
      );
    }
  }

  // DELETE Request
  Future<Map<String, dynamic>> delete(
    String endpoint, {
    bool includeAuth = true,
  }) async {
    try {
      final headers = await _getHeaders(includeAuth: includeAuth);
      final response = await http
          .delete(
            Uri.parse(endpoint),
            headers: headers,
          )
          .timeout(AppConfig.receiveTimeout);

      return _handleResponse(response);
    } on SocketException {
      throw ApiException(
        message: 'Pas de connexion internet',
        statusCode: 0,
      );
    } on HttpException {
      throw ApiException(
        message: 'Erreur de connexion au serveur',
        statusCode: 0,
      );
    } on FormatException {
      throw ApiException(
        message: 'Format de réponse invalide',
        statusCode: 0,
      );
    }
  }
}

// Custom Exception Class
class ApiException implements Exception {
  final String message;
  final int statusCode;

  ApiException({
    required this.message,
    required this.statusCode,
  });

  @override
  String toString() => message;
}
