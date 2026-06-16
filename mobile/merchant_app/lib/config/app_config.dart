class AppConfig {
  // API Base URL - adjust for your environment
  static String get baseUrl {
    // Always talk to the hosted backend by default - this matters for debug
    // builds on a real device too: 'dart.vm.product' is only true in
    // release/profile mode, so a plain `flutter run` on a physical phone
    // would otherwise fall through to the emulator-only 10.0.2.2 address,
    // which a real device can never reach.
    //
    // To point at a backend running on your own machine instead, pass it
    // explicitly, e.g.:
    //   flutter run --dart-define=PRODUCTION_API_URL=http://10.0.2.2:5000   (Android emulator)
    //   flutter run --dart-define=PRODUCTION_API_URL=http://localhost:5000  (iOS sim/desktop/web)
    const String productionUrl = String.fromEnvironment('PRODUCTION_API_URL',
        defaultValue: 'https://tumai-backend.onrender.com');
    return '$productionUrl/api';
  }

  // Auth Endpoints
  static String get loginEndpoint => '/auth/login';
  static String get registerEndpoint => '/auth/register';
  static String get profileEndpoint => '/auth/profile';
  static String get passwordEndpoint => '/auth/password';

  // Merchant Product Endpoints
  // Backend routes: GET /api/products/my-products, POST /api/products, PUT/DELETE /api/products/:id
  static String get productsEndpoint => '/products/my-products';
  static String get createProductEndpoint => '/products';
  static String productEndpoint(String id) => '/products/$id';

  // Category Endpoints
  static String get categoriesEndpoint => '/categories';

  // Order Endpoints (merchant orders)
  static String get ordersEndpoint => '/orders/merchant/orders';
  static String orderEndpoint(String id) => '/orders/$id';
  static String orderStatusEndpoint(String id) => '/orders/$id/status';

  // App Info
  static const String appName = 'Tumai Market - Vendeur';
  static const String appVersion = '1.0.0';
  static const String currency = 'FCFA';
  static const String countryCode = 'TD'; // Chad

  // Support
  static const String supportEmail = 'support@tumaimarket.com';
  static const String supportPhone = '+235 00 00 00 00';
}
