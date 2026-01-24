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

        // Check if user is a merchant
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
        await StorageService.saveToken(response['data']['token']);
        await StorageService.saveUser(response['data']['user']);

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
