import 'dart:async';

import 'package:dio/dio.dart';
import 'package:origami/core/auth/auth_api.dart';
import 'package:origami/core/auth/auth_tokens.dart';
import 'package:origami/core/auth/token_storage.dart';
import 'package:origami/core/constants/api_constants.dart';

class ApiClient {
  ApiClient({Dio? dio, TokenStorage? tokenStorage, AuthGateway? authGateway})
    : dio = dio ?? Dio(ApiConstants.baseOptions),
      _tokenStorage = tokenStorage ?? SecureTokenStorage(),
      _authGateway = authGateway ?? AuthApi() {
    this.dio.interceptors.add(
      QueuedInterceptorsWrapper(onRequest: _onRequest, onError: _onError),
    );
  }

  static const _retriedKey = 'auth.retried';

  final Dio dio;
  final TokenStorage _tokenStorage;
  final AuthGateway _authGateway;

  String? _accessToken;
  Future<AuthTokens>? _refreshing;

  void Function(AuthTokens tokens)? onTokensRefreshed;
  void Function()? onSessionExpired;

  void setAccessToken(String? token) => _accessToken = token;

  void _onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = _accessToken;
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  Future<void> _onError(
    DioException error,
    ErrorInterceptorHandler handler,
  ) async {
    final request = error.requestOptions;
    final isAuthRequest = request.path.startsWith('/api/auth/');
    final wasRetried = request.extra[_retriedKey] == true;
    if (error.response?.statusCode != 401 || isAuthRequest || wasRetried) {
      handler.next(error);
      return;
    }

    try {
      final currentToken = _accessToken;
      final failedAuthorization = request.headers['Authorization'];
      if (currentToken != null &&
          failedAuthorization != 'Bearer $currentToken') {
        request.extra[_retriedKey] = true;
        request.headers['Authorization'] = 'Bearer $currentToken';
        handler.resolve(await dio.fetch<dynamic>(request));
        return;
      }

      final tokens = await _refreshOnce();
      request.extra[_retriedKey] = true;
      request.headers['Authorization'] = 'Bearer ${tokens.accessToken}';
      handler.resolve(await dio.fetch<dynamic>(request));
    } on Object {
      await _clearExpiredSession();
      handler.next(error);
    }
  }

  Future<AuthTokens> _refreshOnce() {
    final currentRefresh = _refreshing;
    if (currentRefresh != null) return currentRefresh;

    final refresh = _performRefresh();
    _refreshing = refresh;
    return refresh.whenComplete(() => _refreshing = null);
  }

  Future<AuthTokens> _performRefresh() async {
    final stored = await _tokenStorage.read();
    if (stored == null || stored.refreshToken.isEmpty) {
      throw const AuthFailure('Your session has expired');
    }

    final tokens = await _authGateway.refresh(stored.refreshToken);
    await _tokenStorage.write(tokens);
    setAccessToken(tokens.accessToken);
    onTokensRefreshed?.call(tokens);
    return tokens;
  }

  Future<void> _clearExpiredSession() async {
    setAccessToken(null);
    try {
      await _tokenStorage.clear();
    } on Object {
      // The in-memory session must still expire if secure storage is unavailable.
    }
    onSessionExpired?.call();
  }
}
