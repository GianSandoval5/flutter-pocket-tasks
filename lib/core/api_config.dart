import 'package:flutter/foundation.dart';

class ApiConfig {
  static const configuredUrl = String.fromEnvironment('MOBILELAB_URL');

  static Uri get baseUri {
    if (configuredUrl.isNotEmpty) return Uri.parse(configuredUrl);
    final host = !kIsWeb && defaultTargetPlatform == TargetPlatform.android
        ? '10.0.2.2'
        : '127.0.0.1';
    return Uri.parse('http://$host:4566');
  }
}
