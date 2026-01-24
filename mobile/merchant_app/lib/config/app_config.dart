import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class AppConfig {
  // API Base URL - adjust for your environment
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:5000/api';
    }
    // For Android emulator, use 10.0.2.2 to access host machine
    // For iOS simulator, use localhost
    // For physical devices, use your machine's IP address
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:5000/api';
    }
    return 'http://localhost:5000/api';
  }

  // Auth Endpoints
  static String get loginEndpoint => '/auth/login';
  static String get registerEndpoint => '/auth/register';
  static String get profileEndpoint => '/auth/profile';
  static String get passwordEndpoint => '/auth/password';

  // Merchant Product Endpoints (uses merchant-specific routes)
  static String get productsEndpoint => '/products/merchant/my-products';
  static String get createProductEndpoint => '/products/merchant';
  static String productEndpoint(String id) => '/products/merchant/$id';

  // Category Endpoints
  static String get categoriesEndpoint => '/categories';

  // Order Endpoints (merchant orders)
  static String get ordersEndpoint => '/orders/merchant';
  static String orderEndpoint(String id) => '/orders/$id';
  static String orderStatusEndpoint(String id) => '/orders/$id/status';

  // App Info
  static const String appName = 'Favela Market - Vendeur';
  static const String appVersion = '1.0.0';
  static const String currency = 'FCFA';
  static const String countryCode = 'TD'; // Chad

  // Support
  static const String supportEmail = 'support@favelamarket.com';
  static const String supportPhone = '+235 00 00 00 00';
}
