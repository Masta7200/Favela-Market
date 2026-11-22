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

  // Notifications (order on its way, delivered, cancelled...) shown at the top of the app
  static String get notificationsEndpoint => '$apiUrl/notifications';
  static String notificationReadEndpoint(String id) =>
      '$apiUrl/notifications/$id/read';
  static String get notificationsReadAllEndpoint =>
      '$apiUrl/notifications/read-all';
  static const Duration notificationPollInterval = Duration(seconds: 30);

  // Timeouts
  // Note: the hosted backend is on Render's free tier, which "sleeps" after
  // inactivity. The first request after a sleep can take 30-60s to wake it
  // up, so the timeout needs enough headroom or every cold start looks like
  // a generic connection error.
  static const Duration connectTimeout = Duration(seconds: 60);
  static const Duration receiveTimeout = Duration(seconds: 60);

  // Storage Keys
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';
  static const String cartKey = 'cart_data';
  static const String languageKey = 'language';

  // Pagination
  static const int pageSize = 20;

  // App Info
  static const String appName = 'Tumai Market';
  static const String appVersion = '1.0.0';
  static const String currency = 'FCFA';
  static const String phonePrefix = '+235';

  // Support
  static const String supportPhone = '+235 60 64 60 72';
  static const String supportEmail = 'support@tumaimarket.com';
}
