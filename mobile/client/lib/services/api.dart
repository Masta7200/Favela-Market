import 'dart:io';
import 'package:flutter/foundation.dart';

final String apiBaseUrl = kIsWeb
    ? 'http://localhost:5000'
    : Platform.isAndroid
        ? 'http://10.0.2.2:5000'
        : 'http://localhost:5000';
