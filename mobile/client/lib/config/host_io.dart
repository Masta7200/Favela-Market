import 'dart:io';

String getHost() {
  // For production, use the deployed Render URL
  // For development, use localhost/emulator addresses
  const bool isProduction = const bool.fromEnvironment('dart.vm.product');
  const String productionUrl = String.fromEnvironment('PRODUCTION_API_URL',
      defaultValue: 'https://favela-market-backend.onrender.com');

  if (isProduction) {
    return productionUrl;
  }

  if (Platform.isAndroid) {
    // Android emulator uses 10.0.2.2 to reach host machine
    return 'http://10.0.2.2:5000';
  }

  // For iOS simulator, Windows, macOS, Linux and others use localhost
  return 'http://localhost:5000';
}
