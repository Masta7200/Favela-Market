import 'host_io.dart' if (dart.library.html) 'host_web.dart';

class AppConfig {
  // API Configuration (selected at runtime depending on platform)
  static String get baseUrl => getHost();

  static String get apiUrl => '$baseUrl/api';

  // API Endpoints
  static String get authEndpoint => '$apiUrl/auth';
  static String get productsEndpoint => '$apiUrl/products';
  static String get categoriesEndpoint => '$apiUrl/categories';
  static String get ordersEndpoint => '$apiUrl/orders';
  static String get addressesEndpoint => '$authEndpoint/addresses';

  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // Storage Keys
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';
  static const String cartKey = 'cart_data';
  static const String languageKey = 'language';

  // Pagination
  static const int pageSize = 20;

  // App Info
  static const String appName = 'Favela Market';
  static const String appVersion = '1.0.0';
  static const String currency = 'FCFA';
  static const String phonePrefix = '+235';

  // Support
  static const String supportPhone = '+235600000000';
  static const String supportEmail = 'support@favelamarket.cm';
}
