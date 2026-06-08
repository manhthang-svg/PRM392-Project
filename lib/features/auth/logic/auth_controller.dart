import 'package:flutter/foundation.dart';
import 'package:origami/features/auth/data/models/user_model.dart';
import 'package:origami/features/auth/data/repositories/auth_repository.dart';

/// Trạng thái của quá trình xác thực
enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

/// Controller quản lý toàn bộ state của Auth flow
class AuthController extends ChangeNotifier {
  final AuthRepository _repo = AuthRepository.instance;

  // ─── State ───
  AuthStatus _status = AuthStatus.initial;
  UserModel? _currentUser;
  String? _errorMessage;

  // ─── Getters ───
  AuthStatus get status => _status;
  UserModel? get currentUser => _currentUser;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == AuthStatus.loading;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  // ───────────────────────────────────────────
  // Kiểm tra session khi khởi động app
  // ───────────────────────────────────────────
  Future<void> checkAuthStatus() async {
    _setStatus(AuthStatus.loading);
    final loggedIn = await _repo.isLoggedIn;
    if (loggedIn) {
      _currentUser = await _repo.getCurrentUser();
      if (_currentUser != null) {
        _setStatus(AuthStatus.authenticated);
        return;
      }
    }
    _setStatus(AuthStatus.unauthenticated);
  }

  // ───────────────────────────────────────────
  // Đăng nhập
  // ───────────────────────────────────────────
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _clearError();
    _setStatus(AuthStatus.loading);

    final result = await _repo.login(email: email, password: password);

    if (result.success && result.user != null) {
      _currentUser = result.user;
      _setStatus(AuthStatus.authenticated);
      return true;
    } else {
      _errorMessage = result.message;
      _setStatus(AuthStatus.error);
      return false;
    }
  }

  // ───────────────────────────────────────────
  // Đăng ký
  // ───────────────────────────────────────────
  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    _clearError();
    _setStatus(AuthStatus.loading);

    final result = await _repo.register(
      name: name,
      email: email,
      password: password,
      confirmPassword: confirmPassword,
    );

    if (result.success && result.user != null) {
      _currentUser = result.user;
      _setStatus(AuthStatus.authenticated);
      return true;
    } else {
      _errorMessage = result.message;
      _setStatus(AuthStatus.error);
      return false;
    }
  }

  // ───────────────────────────────────────────
  // Đăng xuất
  // ───────────────────────────────────────────
  Future<void> logout() async {
    await _repo.logout();
    _currentUser = null;
    _setStatus(AuthStatus.unauthenticated);
  }

  // ───────────────────────────────────────────
  // Xóa lỗi (gọi khi user bắt đầu nhập lại)
  // ───────────────────────────────────────────
  void clearError() => _clearError();

  // ─── Private helpers ───
  void _setStatus(AuthStatus status) {
    _status = status;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    if (_status == AuthStatus.error) {
      _status = AuthStatus.unauthenticated;
    }
  }
}
