<<<<<<< Updated upstream
/// API endpoints và network configuration
class ApiConstants {
  ApiConstants._();

  static const String baseUrl = 'https://api.origami-app.com';
  static const String apiVersion = '/v1';

  // Auth endpoints
  static const String login = '$baseUrl$apiVersion/auth/login';
  static const String register = '$baseUrl$apiVersion/auth/register';
  static const String logout = '$baseUrl$apiVersion/auth/logout';
  static const String refreshToken = '$baseUrl$apiVersion/auth/refresh';

  // User endpoints
  static const String userProfile = '$baseUrl$apiVersion/users/me';
  static const String updateProfile = '$baseUrl$apiVersion/users/me';

  // Newsfeed endpoints
  static const String newsfeed = '$baseUrl$apiVersion/posts';
  static const String createPost = '$baseUrl$apiVersion/posts';

  // Explore endpoints
  static const String patterns = '$baseUrl$apiVersion/patterns';
  static const String categories = '$baseUrl$apiVersion/categories';

  // Chat endpoints
  static const String conversations = '$baseUrl$apiVersion/conversations';
  static const String messages = '$baseUrl$apiVersion/messages';
  static const String wsUrl = 'wss://ws.origami-app.com';

  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
=======
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
>>>>>>> Stashed changes
}
