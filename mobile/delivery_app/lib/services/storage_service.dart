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

  // Notifications already shown as system alerts (avoid showing twice)
  static Set<String> getShownNotificationIds() {
    return (_prefs.getStringList('shown_notifications') ?? []).toSet();
  }

  static Future<void> saveShownNotificationIds(Set<String> ids) async {
    // Keep the list bounded
    final list = ids.toList();
    final trimmed = list.length > 200 ? list.sublist(list.length - 200) : list;
    await _prefs.setStringList('shown_notifications', trimmed);
  }

  // Clear All
  static Future<void> clearAll() async {
    await deleteToken();
    await deleteUser();
    await _prefs.remove('shown_notifications');
  }
}
