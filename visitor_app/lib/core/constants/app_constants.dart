import 'package:flutter/foundation.dart';

class AppConstants {
  static String get baseUrl {
    if (kIsWeb) return 'http://localhost:3000/api';
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:3000/api';
    }
    // Windows, macOS, Linux, iOS simulator
    return 'http://localhost:3000/api';
  }
}
