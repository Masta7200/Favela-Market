class AppConfig {
  static String get baseUrl {
    const String productionUrl = String.fromEnvironment('PRODUCTION_API_URL',
        defaultValue: 'https://tumai-backend.onrender.com');
    return '$productionUrl/api';
  }

  // Auth Endpoints
  static String get loginEndpoint => '/auth/login';
  static String get registerEndpoint => '/auth/register';
  static String get meEndpoint => '/auth/me';
  static String get profileEndpoint => '/auth/profile';
  static String get passwordEndpoint => '/auth/password';
  static String get availabilityEndpoint => '/auth/availability';
  static String get forgotPasswordEndpoint => '/auth/forgot-password';
  static String get resetPasswordEndpoint => '/auth/reset-password';

  // Product Endpoints (delivery persons can sell items, like merchants)
  static String get productsEndpoint => '/products/my-products';
  static String get createProductEndpoint => '/products';
  static String productEndpoint(String id) => '/products/$id';

  // Category Endpoints
  static String get categoriesEndpoint => '/categories';

  // Delivery Order Endpoints (orders assigned to the logged-in delivery person)
  static String get ordersEndpoint => '/orders/delivery/orders';
  static String orderEndpoint(String id) => '/orders/$id';
  static String acceptOrderEndpoint(String id) => '/orders/$id/delivery/accept';
  static String declineOrderEndpoint(String id) =>
      '/orders/$id/delivery/decline';
  static String deliveryStatusEndpoint(String id) =>
      '/orders/$id/delivery/status';

  // Notification Endpoints
  static String get notificationsEndpoint => '/notifications';
  static String notificationReadEndpoint(String id) =>
      '/notifications/$id/read';
  static String get notificationsReadAllEndpoint => '/notifications/read-all';

  // How often the app checks for new notifications while it is open
  static const Duration notificationPollInterval = Duration(seconds: 30);

  // Cloudinary (unsigned upload — safe to put in client code)
  static const String cloudinaryCloudName = 'dwysrvwpw';
  static const String cloudinaryUploadPreset = 'jrz5sl0f';

  // App Info
  static const String appName = 'Tumai Market - Livreur';
  static const String appVersion = '1.0.0';
  static const String currency = 'FCFA';
  static const String countryCode = 'TD';

  // Support
  static const String supportEmail = 'support@tumaimarket.com';
  static const String supportPhone = '+235 60 64 60 72';

  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 60);
  static const Duration receiveTimeout = Duration(seconds: 60);
}
