String getHost() {
  // For production, use the deployed Render URL
  // For development, use localhost
  const bool isProduction = const bool.fromEnvironment('dart.vm.product');
  const String productionUrl = String.fromEnvironment('PRODUCTION_API_URL',
      defaultValue: 'https://tumai-backend.onrender.com');

  return isProduction ? productionUrl : 'http://localhost:5000';
}
