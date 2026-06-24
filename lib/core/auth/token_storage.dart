import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:origami/core/auth/auth_tokens.dart';

abstract interface class TokenStorage {
  Future<AuthTokens?> read();

  Future<void> write(AuthTokens tokens);

  Future<void> clear();
}

class SecureTokenStorage implements TokenStorage {
  SecureTokenStorage({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const _accessTokenKey = 'auth.access_token';
  static const _refreshTokenKey = 'auth.refresh_token';
  static const _tokenTypeKey = 'auth.token_type';

  final FlutterSecureStorage _storage;

  @override
  Future<AuthTokens?> read() async {
    final values = await _storage.readAll();
    final accessToken = values[_accessTokenKey];
    final refreshToken = values[_refreshTokenKey];
    if (accessToken == null || refreshToken == null) return null;

    return AuthTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
      tokenType: values[_tokenTypeKey] ?? 'Bearer',
    );
  }

  @override
  Future<void> write(AuthTokens tokens) async {
    await _storage.write(key: _accessTokenKey, value: tokens.accessToken);
    await _storage.write(key: _refreshTokenKey, value: tokens.refreshToken);
    await _storage.write(key: _tokenTypeKey, value: tokens.tokenType);
  }

  @override
  Future<void> clear() async {
    await Future.wait([
      _storage.delete(key: _accessTokenKey),
      _storage.delete(key: _refreshTokenKey),
      _storage.delete(key: _tokenTypeKey),
    ]);
  }
}

class MemoryTokenStorage implements TokenStorage {
  AuthTokens? tokens;

  @override
  Future<AuthTokens?> read() async => tokens;

  @override
  Future<void> write(AuthTokens value) async => tokens = value;

  @override
  Future<void> clear() async => tokens = null;
}
