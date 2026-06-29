import 'package:flutter/widgets.dart';
import 'package:origami/core/auth/auth_api.dart';
import 'package:origami/core/auth/auth_tokens.dart';
import 'package:origami/core/auth/registration.dart';
import 'package:origami/core/auth/token_storage.dart';
import 'package:origami/core/network/api_client.dart';

class AuthSession extends ChangeNotifier {
  AuthSession({
    TokenStorage? tokenStorage,
    AuthGateway? authGateway,
    ApiClient? apiClient,
  }) {
    _tokenStorage = tokenStorage ?? SecureTokenStorage();
    _authGateway = authGateway ?? AuthApi();
    _apiClient =
        apiClient ??
        ApiClient(tokenStorage: _tokenStorage, authGateway: _authGateway);
    _apiClient.onTokensRefreshed = _handleTokensRefreshed;
    _apiClient.onSessionExpired = _handleSessionExpired;
  }

  late final TokenStorage _tokenStorage;
  late final AuthGateway _authGateway;
  late final ApiClient _apiClient;

  Future<void>? _initialization;
  bool _isAuthenticated = false;
  bool _isBusy = false;
  bool _requiresLogin = false;
  String? _errorMessage;

  bool get isAuthenticated => _isAuthenticated;
  bool get isBusy => _isBusy;
  bool get requiresLogin => _requiresLogin;
  String? get errorMessage => _errorMessage;
  ApiClient get apiClient => _apiClient;

  Future<void> initialize() => _initialization ??= _restoreSession();

  Future<bool> login({required String email, required String password}) async {
    if (_isBusy) return false;
    _setBusy(true);
    _errorMessage = null;
    _requiresLogin = false;

    try {
      final tokens = await _authGateway.login(email: email, password: password);
      await _tokenStorage.write(tokens);
      _applyTokens(tokens);
      return true;
    } on AuthFailure catch (error) {
      _errorMessage = error.message;
      return false;
    } on Object {
      _errorMessage = 'Could not securely save your session. Please try again.';
      await _safeClear();
      return false;
    } finally {
      _setBusy(false);
    }
  }

  Future<OtpChallenge?> requestRegistrationOtp(String email) async {
    if (_isBusy) return null;
    _setBusy(true);
    _errorMessage = null;
    try {
      return await _authGateway.requestRegistrationOtp(email);
    } on AuthFailure catch (error) {
      _errorMessage = error.message;
      return null;
    } on Object {
      _errorMessage = 'Could not send the verification code. Please try again.';
      return null;
    } finally {
      _setBusy(false);
    }
  }

  Future<bool> verifyRegistration({
    required RegistrationDraft registration,
    required String otp,
  }) async {
    if (_isBusy) return false;
    _setBusy(true);
    _errorMessage = null;
    try {
      await _authGateway.verifyRegistration(
        registration: registration,
        otp: otp,
      );
      final tokens = await _authGateway.login(
        email: registration.email,
        password: registration.password,
      );
      await _tokenStorage.write(tokens);
      _applyTokens(tokens);
      return true;
    } on AuthFailure catch (error) {
      _errorMessage = error.message;
      return false;
    } on Object {
      _errorMessage = 'Could not complete registration. Please try again.';
      return false;
    } finally {
      _setBusy(false);
    }
  }

  Future<void> logout() async {
    if (_isBusy) return;
    _setBusy(true);
    try {
      final tokens = await _tokenStorage.read();
      if (tokens != null) {
        try {
          await _authGateway.logout(refreshToken: tokens.refreshToken);
        } on Object {
          // Local logout must remain available when the API is unreachable.
        }
      }
    } on Object {
      // Continue clearing the in-memory session if secure storage cannot read.
    } finally {
      await _safeClear();
      _isAuthenticated = false;
      _requiresLogin = false;
      _apiClient.setAccessToken(null);
      _setBusy(false);
    }
  }

  Future<void> _restoreSession() async {
    try {
      final stored = await _tokenStorage.read();
      if (stored == null) return;

      if (!stored.isAccessTokenExpired) {
        _applyTokens(stored);
        return;
      }

      final refreshed = await _authGateway.refresh(stored.refreshToken);
      await _tokenStorage.write(refreshed);
      _applyTokens(refreshed);
    } on Object {
      await _safeClear();
      _isAuthenticated = false;
      _apiClient.setAccessToken(null);
    } finally {
      notifyListeners();
    }
  }

  void _applyTokens(AuthTokens tokens) {
    _apiClient.setAccessToken(tokens.accessToken);
    _isAuthenticated = true;
    _requiresLogin = false;
    _errorMessage = null;
    notifyListeners();
  }

  void _handleTokensRefreshed(AuthTokens tokens) {
    _isAuthenticated = true;
    _requiresLogin = false;
    _errorMessage = null;
    notifyListeners();
  }

  void _handleSessionExpired() {
    _isAuthenticated = false;
    _requiresLogin = true;
    _errorMessage = 'Your session has expired. Please log in again.';
    notifyListeners();
  }

  void consumeLoginRequirement() {
    _requiresLogin = false;
  }

  void _setBusy(bool value) {
    _isBusy = value;
    notifyListeners();
  }

  Future<void> _safeClear() async {
    try {
      await _tokenStorage.clear();
    } on Object {
      // Nothing else can be done if the platform keystore is unavailable.
    }
  }
}

class AuthScope extends InheritedNotifier<AuthSession> {
  const AuthScope({
    required AuthSession session,
    required super.child,
    super.key,
  }) : super(notifier: session);

  static AuthSession of(BuildContext context, {bool listen = true}) {
    final AuthScope? scope;
    if (listen) {
      scope = context.dependOnInheritedWidgetOfExactType<AuthScope>();
    } else {
      final element = context
          .getElementForInheritedWidgetOfExactType<AuthScope>();
      scope = element?.widget as AuthScope?;
    }
    assert(scope != null, 'AuthScope not found in widget tree');
    return scope!.notifier!;
  }

  static AuthSession? maybeOf(BuildContext context, {bool listen = true}) {
    if (listen) {
      return context.dependOnInheritedWidgetOfExactType<AuthScope>()?.notifier;
    }
    final element = context
        .getElementForInheritedWidgetOfExactType<AuthScope>();
    return (element?.widget as AuthScope?)?.notifier;
  }
}
