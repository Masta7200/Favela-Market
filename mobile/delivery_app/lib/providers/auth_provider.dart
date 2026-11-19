import 'package:flutter/material.dart';
import '../models/delivery_user_model.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../config/app_config.dart';

class AuthProvider extends ChangeNotifier {
  DeliveryUserModel? _user;
  bool _isLoading = false;
  String? _error;

  DeliveryUserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;
  bool get isApproved => _user?.canDeliver ?? false;

  AuthProvider() {
    _loadUser();
  }

  void _loadUser() {
    final userData = StorageService.getUser();
    if (userData != null) {
      _user = DeliveryUserModel.fromJson(userData);
      notifyListeners();
    }
  }

  Future<void> _saveUser(Map<String, dynamic> userData) async {
    _user = DeliveryUserModel.fromJson(userData);
    await StorageService.saveUser(_user!.toJson());
  }

  Future<bool> login(String phone, String password) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await ApiService.post(
        AppConfig.loginEndpoint,
        {'phone': phone, 'password': password},
        includeAuth: false,
      );

      if (response['success'] == true) {
        final userData = response['data']['user'];

        if (userData['role'] != 'delivery') {
          _error = 'Accès refusé. Compte livreur requis.';
          _isLoading = false;
          notifyListeners();
          return false;
        }

        await StorageService.saveToken(response['data']['token']);
        await _saveUser(userData);

        _isLoading = false;
        notifyListeners();
        return true;
      }

      _error = response['message'] ?? 'Erreur de connexion';
      _isLoading = false;
      notifyListeners();
      return false;
    } on ApiException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String name,
    required String phone,
    required String email,
    required String password,
    required String vehicleType,
    String? vehicleNumber,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await ApiService.post(
        AppConfig.registerEndpoint,
        {
          'name': name,
          'phone': phone,
          'email': email,
          'password': password,
          'role': 'delivery',
          'vehicleType': vehicleType,
          if (vehicleNumber != null) 'vehicleNumber': vehicleNumber,
        },
        includeAuth: false,
      );

      _isLoading = false;
      if (response['success'] == true) {
        notifyListeners();
        return true;
      }

      _error = response['message'] ?? 'Erreur d\'inscription';
      notifyListeners();
      return false;
    } on ApiException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Reloads the account from the server, e.g. to pick up admin approval.
  /// Returns false if the session is no longer valid (user was logged out).
  Future<bool> refreshProfile() async {
    try {
      final response = await ApiService.get(AppConfig.meEndpoint);
      if (response['success'] == true) {
        await _saveUser(response['data']['user']);
        notifyListeners();
      }
      return true;
    } on ApiException catch (e) {
      // Token expired or account deactivated by the admin
      if (e.isUnauthorized) {
        await logout();
        return false;
      }
      return true;
    }
  }

  Future<bool> setAvailability(bool isAvailable) async {
    final previous = _user;
    if (previous == null) return false;

    // Optimistic update so the switch responds immediately
    _user = previous.copyWith(isAvailable: isAvailable);
    _error = null;
    notifyListeners();

    try {
      await ApiService.put(
        AppConfig.availabilityEndpoint,
        {'isAvailable': isAvailable},
      );
      await StorageService.saveUser(_user!.toJson());
      return true;
    } on ApiException catch (e) {
      _user = previous;
      _error = e.message;
      notifyListeners();
      return false;
    }
  }

  Future<bool> requestPasswordReset({required String email}) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await ApiService.post(
        AppConfig.forgotPasswordEndpoint,
        {'email': email},
        includeAuth: false,
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await ApiService.post(
        AppConfig.resetPasswordEndpoint,
        {'email': email, 'otp': otp, 'newPassword': newPassword},
        includeAuth: false,
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateProfile({
    required String name,
    String? email,
    String? vehicleType,
    String? vehicleNumber,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final body = <String, dynamic>{'name': name};
      if (email != null && email.isNotEmpty) body['email'] = email;
      if (vehicleType != null) body['vehicleType'] = vehicleType;
      if (vehicleNumber != null) body['vehicleNumber'] = vehicleNumber;

      final response = await ApiService.put(AppConfig.profileEndpoint, body);

      if (response['success'] == true) {
        await _saveUser(response['data']['user']);
        _isLoading = false;
        notifyListeners();
        return true;
      }

      _error = response['message'] ?? 'Erreur de mise à jour';
      _isLoading = false;
      notifyListeners();
      return false;
    } on ApiException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await ApiService.put(
        AppConfig.passwordEndpoint,
        {'currentPassword': currentPassword, 'newPassword': newPassword},
      );

      // The backend issues a fresh token after a password change
      final token = response['data']?['token'];
      if (token is String) await StorageService.saveToken(token);

      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _user = null;
    await StorageService.clearAll();
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
