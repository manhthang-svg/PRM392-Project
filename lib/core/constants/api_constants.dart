import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

abstract final class ApiConstants {
  static const _configuredBaseUrl = String.fromEnvironment('API_BASE_URL');

  static String get baseUrl {
    if (_configuredBaseUrl.isNotEmpty) return _configuredBaseUrl;
    if (kIsWeb) return 'http://localhost:8080';
    return defaultTargetPlatform == TargetPlatform.android
        ? 'http://10.0.2.2:8080'
        : 'http://localhost:8080';
  }

  static const connectTimeout = Duration(seconds: 15);
  static const receiveTimeout = Duration(seconds: 15);

  static BaseOptions get baseOptions => BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: connectTimeout,
    receiveTimeout: receiveTimeout,
    headers: const {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    },
  );
}
