import 'package:flutter/material.dart';
import '../models/usermodel.dart';
import '../services/apiservices.dart';
import '../services/storageservices.dart';
import '../config/app_config.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  UserModel? _user;
  bool _isLoading = false;
  String? _error;
  bool _isAuthenticated = false;

  // Getters
  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _isAuthenticated;

  // Check if user is logged in
  Future<bool> checkAuth() async {
    try {
      final token = await StorageService.getToken();
      final savedUser = StorageService.getUser();

      if (token != null && savedUser != null) {
        _user = savedUser;
        _isAuthenticated = true;
        notifyListeners();

        // Fetch latest user data
        await fetchUserProfile();
        return true;
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  // Register
  Future<bool> register({
    required String phone,
    required String password,
    required String name,
    String? email,
  }) async {
    try {
      _setLoading(true);
      _error = null;

      final response = await _apiService.post(
        '${AppConfig.authEndpoint}/register',
        {
          'phone': phone,
          'password': password,
          'name': name,
          if (email != null && email.isNotEmpty) 'email': email,
          'role': 'client',
        },
        includeAuth: false,
      );

      if (response['success'] == true) {
        final token = response['data']['token'];
        final userData = response['data']['user'];

        await StorageService.saveToken(token);

        _user = UserModel.fromJson(userData);
        await StorageService.saveUser(_user!);

        _isAuthenticated = true;
        _setLoading(false);
        return true;
      }

      _error = response['message'] ?? 'Erreur lors de l\'inscription';
      _setLoading(false);
      return false;
    } on ApiException catch (e) {
      _error = e.message;
      _setLoading(false);
      return false;
    } catch (e) {
      _error = 'Une erreur est survenue. Veuillez réessayer.';
      _setLoading(false);
      return false;
    }
  }

  // Login
  Future<bool> login({
    required String phone,
    required String password,
  }) async {
    try {
      _setLoading(true);
      _error = null;

      final response = await _apiService.post(
        '${AppConfig.authEndpoint}/login',
        {
          'phone': phone,
          'password': password,
        },
        includeAuth: false,
      );

      if (response['success'] == true) {
        final token = response['data']['token'];
        final userData = response['data']['user'];

        await StorageService.saveToken(token);

        _user = UserModel.fromJson(userData);
        await StorageService.saveUser(_user!);

        _isAuthenticated = true;
        _setLoading(false);
        return true;
      }

      _error = response['message'] ?? 'Erreur lors de la connexion';
      _setLoading(false);
      return false;
    } on ApiException catch (e) {
      _error = e.message;
      _setLoading(false);
      return false;
    } catch (e) {
      _error = 'Une erreur est survenue. Veuillez réessayer.';
      _setLoading(false);
      return false;
    }
  }

  // Fetch user profile
  Future<void> fetchUserProfile() async {
    try {
      final response = await _apiService.get(
        '${AppConfig.authEndpoint}/me',
      );

      if (response['success'] == true) {
        _user = UserModel.fromJson(response['data']['user']);
        await StorageService.saveUser(_user!);
        notifyListeners();
      }
    } catch (e) {
      // Silently fail, keep using cached user data
    }
  }

  // Update profile
  Future<bool> updateProfile({
    String? name,
    String? email,
  }) async {
    try {
      _setLoading(true);
      _error = null;

      final body = <String, dynamic>{};
      if (name != null && name.isNotEmpty) body['name'] = name;
      if (email != null && email.isNotEmpty) body['email'] = email;

      final response = await _apiService.put(
        '${AppConfig.authEndpoint}/profile',
        body,
      );

      if (response['success'] == true) {
        _user = UserModel.fromJson(response['data']['user']);
        await StorageService.saveUser(_user!);
        _setLoading(false);
        return true;
      }

      _error = response['message'] ?? 'Erreur lors de la mise à jour';
      _setLoading(false);
      return false;
    } on ApiException catch (e) {
      _error = e.message;
      _setLoading(false);
      return false;
    } catch (e) {
      _error = 'Une erreur est survenue. Veuillez réessayer.';
      _setLoading(false);
      return false;
    }
  }

  // Update password
  Future<bool> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      _setLoading(true);
      _error = null;

      final response = await _apiService.put(
        '${AppConfig.authEndpoint}/password',
        {
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        },
      );

      if (response['success'] == true) {
        final token = response['data']['token'];
        await StorageService.saveToken(token);
        _setLoading(false);
        return true;
      }

      _error = response['message'] ?? 'Erreur lors de la mise à jour';
      _setLoading(false);
      return false;
    } on ApiException catch (e) {
      _error = e.message;
      _setLoading(false);
      return false;
    } catch (e) {
      _error = 'Une erreur est survenue. Veuillez réessayer.';
      _setLoading(false);
      return false;
    }
  }

  // Request password reset (send OTP)
  Future<bool> requestPasswordReset({
    required String phone,
  }) async {
    try {
      _setLoading(true);
      _error = null;

      final response = await _apiService.post(
        '${AppConfig.authEndpoint}/forgot-password',
        {
          'phone': phone,
        },
        includeAuth: false,
      );

      _setLoading(false);
      if (response['success'] == true) {
        return true;
      }

      _error = response['message'] ?? 'Erreur lors de la requête';
      return false;
    } on ApiException catch (e) {
      _error = e.message;
      _setLoading(false);
      return false;
    } catch (e) {
      _error = 'Une erreur est survenue. Veuillez réessayer.';
      _setLoading(false);
      return false;
    }
  }

  // Reset password using OTP
  Future<bool> resetPassword({
    required String phone,
    required String otp,
    required String newPassword,
  }) async {
    try {
      _setLoading(true);
      _error = null;

      final response = await _apiService.post(
        '${AppConfig.authEndpoint}/reset-password',
        {
          'phone': phone,
          'otp': otp,
          'newPassword': newPassword,
        },
        includeAuth: false,
      );

      _setLoading(false);

      if (response['success'] == true) {
        return true;
      }

      _error = response['message'] ?? 'Erreur lors de la réinitialisation';
      return false;
    } on ApiException catch (e) {
      _error = e.message;
      _setLoading(false);
      return false;
    } catch (e) {
      _error = 'Une erreur est survenue. Veuillez réessayer.';
      _setLoading(false);
      return false;
    }
  }

  // Add address
  Future<bool> addAddress(AddressModel address) async {
    try {
      _setLoading(true);
      _error = null;

      final response = await _apiService.post(
        AppConfig.addressesEndpoint,
        address.toJson(),
      );

      if (response['success'] == true) {
        // Update local user with new addresses
        final addresses = (response['data']['addresses'] as List)
            .map((addr) => AddressModel.fromJson(addr))
            .toList();

        _user = _user?.copyWith(addresses: addresses);
        if (_user != null) {
          await StorageService.saveUser(_user!);
        }

        _setLoading(false);
        return true;
      }

      _error = response['message'] ?? 'Erreur lors de l\'ajout de l\'adresse';
      _setLoading(false);
      return false;
    } on ApiException catch (e) {
      _error = e.message;
      _setLoading(false);
      return false;
    } catch (e) {
      _error = 'Une erreur est survenue. Veuillez réessayer.';
      _setLoading(false);
      return false;
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      _setLoading(true);

      await StorageService.clearAll();

      _user = null;
      _isAuthenticated = false;
      _error = null;

      _setLoading(false);
    } catch (e) {
      _setLoading(false);
    }
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Private helper methods
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
