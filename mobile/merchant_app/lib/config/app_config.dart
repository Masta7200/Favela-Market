class AppConfig {
  static String get baseUrl {
    const String productionUrl = String.fromEnvironment('PRODUCTION_API_URL',
        defaultValue: 'https://tumai-backend.onrender.com');
    return '$productionUrl/api';
  }

  // Auth Endpoints
  static String get loginEndpoint => '/auth/login';
  static String get registerEndpoint => '/auth/register';
  static String get profileEndpoint => '/auth/profile';
  static String get passwordEndpoint => '/auth/password';
  static String get forgotPasswordEndpoint => '/auth/forgot-password';
  static String get resetPasswordEndpoint => '/auth/reset-password';

  // Merchant Product Endpoints
  static String get productsEndpoint => '/products/my-products';
  static String get createProductEndpoint => '/products';
  static String productEndpoint(String id) => '/products/$id';

  // Category Endpoints
  static String get categoriesEndpoint => '/categories';

  // Order Endpoints (merchant orders)
  static String get ordersEndpoint => '/orders/merchant/orders';
  static String orderEndpoint(String id) => '/orders/$id';
  static String orderStatusEndpoint(String id) => '/orders/$id/status';

  // Cloudinary (unsigned upload — safe to put in client code)
  // 1. Create a free account at https://cloudinary.com
  // 2. Copy your Cloud Name from the dashboard
  // 3. Go to Settings → Upload → Upload presets → Add preset → Mode: Unsigned → Save
  // 4. Paste the cloud name and preset name below
  static const String cloudinaryCloudName = ''; // TODO: e.g. 'abc123xyz'
  static const String cloudinaryUploadPreset = ''; // TODO: e.g. 'tumai_unsigned'

  // App Info
  static const String appName = 'Tumai Market - Vendeur';
  static const String appVersion = '1.0.0';
  static const String currency = 'FCFA';
  static const String countryCode = 'TD';

  // Support
  static const String supportEmail = 'support@tumaimarket.com';
  static const String supportPhone = '+235 00 00 00 00';

  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 60);
  static const Duration receiveTimeout = Duration(seconds: 60);
}
