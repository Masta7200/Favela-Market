import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/app_config.dart';
import '../models/usermodel.dart';

class StorageService {
  static late SharedPreferences _prefs;
  static const _secureStorage = FlutterSecureStorage();

  // Initialize storage
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Token Management (Secure)
  static Future<void> saveToken(String token) async {
    await _secureStorage.write(key: AppConfig.tokenKey, value: token);
  }

  static Future<String?> getToken() async {
    return await _secureStorage.read(key: AppConfig.tokenKey);
  }

  static Future<void> deleteToken() async {
    await _secureStorage.delete(key: AppConfig.tokenKey);
  }

  // User Data
  static Future<void> saveUser(UserModel user) async {
    final userJson = jsonEncode(user.toJson());
    await _prefs.setString(AppConfig.userKey, userJson);
  }

  static UserModel? getUser() {
    final userJson = _prefs.getString(AppConfig.userKey);
    if (userJson == null) return null;

    try {
      return UserModel.fromJson(jsonDecode(userJson));
    } catch (e) {
      return null;
    }
  }

  static Future<void> deleteUser() async {
    await _prefs.remove(AppConfig.userKey);
  }

  // Cart Data
  static Future<void> saveCart(List<Map<String, dynamic>> cartItems) async {
    final cartJson = jsonEncode(cartItems);
    await _prefs.setString(AppConfig.cartKey, cartJson);
  }

  static List<Map<String, dynamic>> getCart() {
    final cartJson = _prefs.getString(AppConfig.cartKey);
    if (cartJson == null) return [];

    try {
      final List<dynamic> decoded = jsonDecode(cartJson);
      return decoded.cast<Map<String, dynamic>>();
    } catch (e) {
      return [];
    }
  }

  static Future<void> clearCart() async {
    await _prefs.remove(AppConfig.cartKey);
  }

  // Language
  static Future<void> saveLanguage(String languageCode) async {
    await _prefs.setString(AppConfig.languageKey, languageCode);
  }

  static String getLanguage() {
    return _prefs.getString(AppConfig.languageKey) ?? 'fr';
  }

  // Clear all data (Logout)
  static Future<void> clearAll() async {
    await deleteToken();
    await deleteUser();
    await clearCart();
  }

  // Generic methods
  static Future<void> setString(String key, String value) async {
    await _prefs.setString(key, value);
  }

  static String? getString(String key) {
    return _prefs.getString(key);
  }

  static Future<void> setBool(String key, bool value) async {
    await _prefs.setBool(key, value);
  }

  static bool? getBool(String key) {
    return _prefs.getBool(key);
  }

  static Future<void> setInt(String key, int value) async {
    await _prefs.setInt(key, value);
  }

  static int? getInt(String key) {
    return _prefs.getInt(key);
  }

  static Future<void> remove(String key) async {
    await _prefs.remove(key);
  }
}
