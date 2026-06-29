import 'package:dio/dio.dart';
import 'package:origami/core/auth/auth_tokens.dart';
import 'package:origami/core/auth/registration.dart';
import 'package:origami/core/constants/api_constants.dart';

abstract interface class AuthGateway {
  Future<AuthTokens> login({required String email, required String password});

  Future<AuthTokens> refresh(String refreshToken);

  Future<void> logout({required String refreshToken});

  Future<OtpChallenge> requestRegistrationOtp(String email);

  Future<void> verifyRegistration({
    required RegistrationDraft registration,
    required String otp,
  });
}

class AuthApi implements AuthGateway {
  AuthApi({Dio? dio}) : _dio = dio ?? Dio(ApiConstants.baseOptions);

  final Dio _dio;

  @override
  Future<AuthTokens> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/auth/login',
        data: {'username': email.trim(), 'password': password},
      );
      return _tokensFrom(response.data);
    } on DioException catch (error) {
      throw AuthFailure.fromDio(error);
    } on FormatException catch (error) {
      throw AuthFailure(error.message);
    }
  }

  @override
  Future<AuthTokens> refresh(String refreshToken) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/auth/refresh-token',
        data: {'refreshToken': refreshToken},
      );
      return _tokensFrom(response.data);
    } on DioException catch (error) {
      throw AuthFailure.fromDio(error);
    } on FormatException catch (error) {
      throw AuthFailure(error.message);
    }
  }

  @override
  Future<void> logout({required String refreshToken}) async {
    try {
      await _dio.post<void>(
        '/api/auth/logout',
        data: {'refreshToken': refreshToken},
      );
    } on DioException catch (error) {
      throw AuthFailure.fromDio(error);
    }
  }

  @override
  Future<OtpChallenge> requestRegistrationOtp(String email) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/auth/register/request-otp',
        data: {'email': email.trim()},
      );
      final data = response.data?['data'];
      if (data is! Map) {
        throw const FormatException('Invalid OTP response');
      }
      return OtpChallenge.fromApiData(Map<String, dynamic>.from(data));
    } on DioException catch (error) {
      throw AuthFailure.fromDio(error);
    } on FormatException catch (error) {
      throw AuthFailure(error.message);
    }
  }

  @override
  Future<void> verifyRegistration({
    required RegistrationDraft registration,
    required String otp,
  }) async {
    try {
      await _dio.post<Map<String, dynamic>>(
        '/api/auth/register/verify',
        data: {
          'email': registration.email.trim(),
          'otp': otp,
          'displayName': registration.displayName.trim(),
          'handle': registration.handle.trim(),
          'password': registration.password,
        },
      );
    } on DioException catch (error) {
      throw AuthFailure.fromDio(error);
    }
  }

  AuthTokens _tokensFrom(Map<String, dynamic>? envelope) {
    final data = envelope?['data'];
    if (data is! Map) {
      throw const FormatException('Invalid authentication response');
    }
    return AuthTokens.fromApiData(Map<String, dynamic>.from(data));
  }
}

class AuthFailure implements Exception {
  const AuthFailure(this.message);

  factory AuthFailure.fromDio(DioException error) {
    final responseData = error.response?.data;
    if (responseData is Map && responseData['message'] is String) {
      return AuthFailure(responseData['message'] as String);
    }
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return const AuthFailure('The server took too long to respond');
    }
    if (error.type == DioExceptionType.connectionError) {
      return const AuthFailure(
        'Cannot connect to the server. Check the API address and network.',
      );
    }
    return const AuthFailure('Authentication failed. Please try again.');
  }

  final String message;

  @override
  String toString() => message;
}
