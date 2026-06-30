import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:origami/core/auth/auth_api.dart';
import 'package:origami/core/auth/auth_session.dart';
import 'package:origami/core/auth/auth_tokens.dart';
import 'package:origami/core/auth/registration.dart';
import 'package:origami/core/auth/token_storage.dart';

void main() {
  group('AuthSession', () {
    test('logs in and stores tokens', () async {
      final storage = MemoryTokenStorage();
      final gateway = _FakeAuthGateway();
      final session = AuthSession(tokenStorage: storage, authGateway: gateway);

      final result = await session.login(
        email: 'paper@example.com',
        password: 'password123',
      );

      expect(result, isTrue);
      expect(session.isAuthenticated, isTrue);
      expect(storage.tokens?.refreshToken, 'login-refresh');
      expect(gateway.loginEmail, 'paper@example.com');
    });

    test(
      'marks session as admin when the access token has ADMIN authority',
      () async {
        final storage = MemoryTokenStorage();
        final gateway = _FakeAuthGateway(
          loginAuthorities: const ['ADMIN', 'USER_READ'],
        );
        final session = AuthSession(
          tokenStorage: storage,
          authGateway: gateway,
        );

        final result = await session.login(
          email: 'admin@example.com',
          password: 'password123',
        );

        expect(result, isTrue);
        expect(session.isAuthenticated, isTrue);
        expect(session.isAdmin, isTrue);
      },
    );

    test('refreshes an expired access token during startup', () async {
      final storage = MemoryTokenStorage()
        ..tokens = AuthTokens(
          accessToken: _jwt(expirationOffset: const Duration(minutes: -1)),
          refreshToken: 'old-refresh',
        );
      final gateway = _FakeAuthGateway();
      final session = AuthSession(tokenStorage: storage, authGateway: gateway);

      await session.initialize();

      expect(gateway.refreshCalls, 1);
      expect(gateway.lastRefreshToken, 'old-refresh');
      expect(storage.tokens?.refreshToken, 'rotated-refresh');
      expect(session.isAuthenticated, isTrue);
    });

    test('logout revokes the refresh token and clears local session', () async {
      final storage = MemoryTokenStorage()
        ..tokens = AuthTokens(
          accessToken: _jwt(expirationOffset: const Duration(minutes: 10)),
          refreshToken: 'refresh-to-revoke',
        );
      final gateway = _FakeAuthGateway();
      final session = AuthSession(tokenStorage: storage, authGateway: gateway);
      await session.initialize();

      await session.logout();

      expect(gateway.logoutRefreshToken, 'refresh-to-revoke');
      expect(storage.tokens, isNull);
      expect(session.isAuthenticated, isFalse);
    });

    test('verifies registration and signs the new user in', () async {
      final storage = MemoryTokenStorage();
      final gateway = _FakeAuthGateway();
      final session = AuthSession(tokenStorage: storage, authGateway: gateway);
      const registration = RegistrationDraft(
        displayName: 'Paper Artist',
        handle: 'paperartist',
        email: 'new@example.com',
        password: 'password123',
      );

      final challenge = await session.requestRegistrationOtp(
        registration.email,
      );
      final result = await session.verifyRegistration(
        registration: registration,
        otp: '123456',
      );

      expect(challenge?.resendIn, 60);
      expect(gateway.registrationOtp, '123456');
      expect(gateway.loginEmail, registration.email);
      expect(result, isTrue);
      expect(session.isAuthenticated, isTrue);
      expect(storage.tokens?.refreshToken, 'login-refresh');
    });
  });
}

class _FakeAuthGateway implements AuthGateway {
  _FakeAuthGateway({this.loginAuthorities = const []});

  final List<String> loginAuthorities;
  String? loginEmail;
  String? lastRefreshToken;
  String? logoutRefreshToken;
  String? registrationOtp;
  int refreshCalls = 0;

  @override
  Future<AuthTokens> login({
    required String email,
    required String password,
  }) async {
    loginEmail = email;
    return AuthTokens(
      accessToken: _jwt(
        expirationOffset: const Duration(minutes: 15),
        authorities: loginAuthorities,
      ),
      refreshToken: 'login-refresh',
    );
  }

  @override
  Future<AuthTokens> refresh(String refreshToken) async {
    refreshCalls++;
    lastRefreshToken = refreshToken;
    return AuthTokens(
      accessToken: _jwt(expirationOffset: const Duration(minutes: 15)),
      refreshToken: 'rotated-refresh',
    );
  }

  @override
  Future<void> logout({required String refreshToken}) async {
    logoutRefreshToken = refreshToken;
  }

  @override
  Future<OtpChallenge> requestRegistrationOtp(String email) async {
    return OtpChallenge(email: email, expiresIn: 300, resendIn: 60);
  }

  @override
  Future<void> verifyRegistration({
    required RegistrationDraft registration,
    required String otp,
  }) async {
    registrationOtp = otp;
  }
}

String _jwt({
  required Duration expirationOffset,
  List<String> authorities = const [],
}) {
  String encode(Object value) =>
      base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
  final expiresAt = DateTime.now().add(expirationOffset);
  return '${encode({'alg': 'HS256'})}.${encode({'exp': expiresAt.millisecondsSinceEpoch ~/ 1000, if (authorities.isNotEmpty) 'authorities': authorities})}.signature';
}
