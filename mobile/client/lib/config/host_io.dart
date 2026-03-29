import 'dart:io';

String getHost() {
  if (Platform.isAndroid) {
    // Android emulator uses 10.0.2.2 to reach host machine
    return 'http://10.0.2.2:5000';
  }

  // For iOS simulator, Windows, macOS, Linux and others use localhost
  return 'http://localhost:5000';
}
