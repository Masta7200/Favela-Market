String getHost() {
  // Always talk to the hosted backend by default (see host_io.dart for the
  // rationale). Override with --dart-define=PRODUCTION_API_URL=... for local dev.
  return const String.fromEnvironment('PRODUCTION_API_URL',
      defaultValue: 'https://tumai-backend.onrender.com');
}
