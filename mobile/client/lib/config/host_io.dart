String getHost() {
  // Always talk to the hosted backend by default - this matters for debug
  // builds on a real device too, not just release builds: 'dart.vm.product'
  // is only true in release/profile mode, so a plain `flutter run` on a
  // physical phone used to fall through to the emulator-only 10.0.2.2
  // address below, which a real device can never reach.
  //
  // To point at a backend running on your own machine instead, pass it
  // explicitly, e.g.:
  //   flutter run --dart-define=PRODUCTION_API_URL=http://10.0.2.2:5000   (Android emulator)
  //   flutter run --dart-define=PRODUCTION_API_URL=http://localhost:5000  (iOS sim/desktop)
  return const String.fromEnvironment('PRODUCTION_API_URL',
      defaultValue: 'https://tumai-backend.onrender.com');
}
