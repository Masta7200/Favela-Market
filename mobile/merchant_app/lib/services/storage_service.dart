import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

class StorageService {
  static late SharedPreferences _prefs;
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Token Management (Secure)
  static Future<void> saveToken(String token) async {
    await _secureStorage.write(key: 'auth_token', value: token);
  }

  static Future<String?> getToken() async {
    return await _secureStorage.read(key: 'auth_token');
  }

  static Future<void> deleteToken() async {
    await _secureStorage.delete(key: 'auth_token');
  }

  // User Data
  static Future<void> saveUser(Map<String, dynamic> user) async {
    await _prefs.setString('user', jsonEncode(user));
  }

  static Map<String, dynamic>? getUser() {
    final userString = _prefs.getString('user');
    if (userString != null) {
      return jsonDecode(userString);
    }
    return null;
  }

  static Future<void> deleteUser() async {
    await _prefs.remove('user');
  }

  // Shop Data
  static Future<void> saveShop(Map<String, dynamic> shop) async {
    await _prefs.setString('shop', jsonEncode(shop));
  }

  static Map<String, dynamic>? getShop() {
    final shopString = _prefs.getString('shop');
    if (shopString != null) {
      return jsonDecode(shopString);
    }
    return null;
  }

  static Future<void> deleteShop() async {
    await _prefs.remove('shop');
  }

  // Clear All
  static Future<void> clearAll() async {
    await deleteToken();
    await deleteUser();
    await deleteShop();
  }
}
