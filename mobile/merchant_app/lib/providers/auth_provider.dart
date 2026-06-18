import 'package:flutter/material.dart';
import '../models/merchant_model.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../config/app_config.dart';

class AuthProvider extends ChangeNotifier {
  MerchantModel? _merchant;
  bool _isLoading = false;
  String? _error;

  MerchantModel? get merchant => _merchant;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _merchant != null;

  AuthProvider() {
    _loadMerchant();
  }

  Future<void> _loadMerchant() async {
    final merchantData = StorageService.getUser();
    if (merchantData != null) {
      _merchant = MerchantModel.fromJson(merchantData);
      notifyListeners();
    }
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

        if (userData['role'] != 'merchant') {
          _error = 'Accès refusé. Compte vendeur requis.';
          _isLoading = false;
          notifyListeners();
          return false;
        }

        _merchant = MerchantModel.fromJson(userData);
        await StorageService.saveToken(response['data']['token']);
        await StorageService.saveUser(userData);

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
    required String password,
    required String shopName,
    String? email,
    String? shopDescription,
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
          'password': password,
          'email': email,
          'role': 'merchant',
          'shopName': shopName,
          'shopDescription': shopDescription,
        },
        includeAuth: false,
      );

      if (response['success'] == true) {
        _merchant = MerchantModel.fromJson(response['data']['user']);
        _isLoading = false;
        notifyListeners();
        return true;
      }

      _error = response['message'] ?? 'Erreur d\'inscription';
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
    String? shopName,
    String? shopDescription,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final body = <String, dynamic>{'name': name};
      if (email != null && email.isNotEmpty) body['email'] = email;
      if (shopName != null && shopName.isNotEmpty) body['shopName'] = shopName;
      if (shopDescription != null) body['shopDescription'] = shopDescription;

      final response = await ApiService.put(AppConfig.profileEndpoint, body);

      if (response['success'] == true) {
        final userData = response['data']['user'];
        _merchant = MerchantModel.fromJson(userData);
        await StorageService.saveUser(userData);
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

      await ApiService.put(
        AppConfig.passwordEndpoint,
        {'currentPassword': currentPassword, 'newPassword': newPassword},
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

  Future<void> logout() async {
    _merchant = null;
    await StorageService.clearAll();
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
