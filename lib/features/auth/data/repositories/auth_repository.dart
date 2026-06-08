import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:origami/features/auth/data/models/user_model.dart';

/// Kết quả trả về từ các thao tác auth
class AuthResult {
  final bool success;
  final String? message;
  final UserModel? user;

  const AuthResult({
    required this.success,
    this.message,
    this.user,
  });

  factory AuthResult.ok(UserModel user) =>
      AuthResult(success: true, user: user);

  factory AuthResult.fail(String message) =>
      AuthResult(success: false, message: message);
}

/// Mock Auth Repository — Xử lý toàn bộ logic xác thực với dữ liệu cục bộ
class AuthRepository {
  AuthRepository._();
  static final AuthRepository instance = AuthRepository._();

  // SharedPreferences keys
  static const _keyCurrentUser = 'current_user';
  static const _keyIsLoggedIn = 'is_logged_in';

  // ───────────────────────────────────────────
  // Mock user database (in-memory)
  // ───────────────────────────────────────────
  final List<_MockUser> _mockUsers = [
    _MockUser(
      user: UserModel(
        id: 'user_001',
        name: 'Origami Demo',
        email: 'demo@origami.com',
        avatarUrl: null,
        bio: 'Origami enthusiast & paper art lover 🦢',
        createdAt: DateTime(2024, 1, 15),
      ),
      passwordHash: 'password123',
    ),
    _MockUser(
      user: UserModel(
        id: 'user_002',
        name: 'Paper Artist',
        email: 'artist@origami.com',
        avatarUrl: null,
        bio: 'Creating beautiful origami since 2018 ✨',
        createdAt: DateTime(2024, 3, 20),
      ),
      passwordHash: 'password123',
    ),
  ];

  // ───────────────────────────────────────────
  // Auth Operations
  // ───────────────────────────────────────────

  /// Đăng nhập với email và password
  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    // Giả lập network delay
    await Future.delayed(const Duration(milliseconds: 1500));

    // Validate input
    if (email.trim().isEmpty) {
      return AuthResult.fail('Vui lòng nhập email.');
    }
    if (password.isEmpty) {
      return AuthResult.fail('Vui lòng nhập mật khẩu.');
    }

    // Tìm user theo email (không phân biệt hoa thường)
    final normalizedEmail = email.trim().toLowerCase();
    final found = _mockUsers.where(
      (u) => u.user.email.toLowerCase() == normalizedEmail,
    );

    if (found.isEmpty) {
      return AuthResult.fail('Email không tồn tại trong hệ thống.');
    }

    final mockUser = found.first;

    // Kiểm tra password
    if (mockUser.passwordHash != password) {
      return AuthResult.fail('Mật khẩu không chính xác.');
    }

    // Lưu session
    await _saveSession(mockUser.user);
    return AuthResult.ok(mockUser.user);
  }

  /// Đăng ký tài khoản mới
  Future<AuthResult> register({
    required String name,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    // Giả lập network delay
    await Future.delayed(const Duration(milliseconds: 1800));

    // Validate input
    if (name.trim().isEmpty) {
      return AuthResult.fail('Vui lòng nhập tên của bạn.');
    }
    if (name.trim().length < 2) {
      return AuthResult.fail('Tên phải có ít nhất 2 ký tự.');
    }
    if (email.trim().isEmpty) {
      return AuthResult.fail('Vui lòng nhập email.');
    }
    if (!_isValidEmail(email.trim())) {
      return AuthResult.fail('Định dạng email không hợp lệ.');
    }
    if (password.isEmpty) {
      return AuthResult.fail('Vui lòng nhập mật khẩu.');
    }
    if (password.length < 6) {
      return AuthResult.fail('Mật khẩu phải có ít nhất 6 ký tự.');
    }
    if (password != confirmPassword) {
      return AuthResult.fail('Mật khẩu xác nhận không khớp.');
    }

    // Kiểm tra email đã tồn tại chưa
    final normalizedEmail = email.trim().toLowerCase();
    final emailExists = _mockUsers.any(
      (u) => u.user.email.toLowerCase() == normalizedEmail,
    );
    if (emailExists) {
      return AuthResult.fail('Email này đã được đăng ký. Vui lòng dùng email khác.');
    }

    // Tạo user mới
    final newUser = UserModel(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      name: name.trim(),
      email: normalizedEmail,
      bio: 'Origami beginner 🌸',
      createdAt: DateTime.now(),
    );

    // Thêm vào mock database
    _mockUsers.add(_MockUser(user: newUser, passwordHash: password));

    // Tự động đăng nhập sau khi đăng ký
    await _saveSession(newUser);
    return AuthResult.ok(newUser);
  }

  /// Đăng xuất
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyCurrentUser);
    await prefs.setBool(_keyIsLoggedIn, false);
  }

  /// Kiểm tra trạng thái đăng nhập
  Future<bool> get isLoggedIn async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsLoggedIn) ?? false;
  }

  /// Lấy user hiện tại từ SharedPreferences
  Future<UserModel?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_keyCurrentUser);
    if (userJson == null) return null;
    try {
      return UserModel.fromJson(jsonDecode(userJson) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  // ───────────────────────────────────────────
  // Private Helpers
  // ───────────────────────────────────────────

  Future<void> _saveSession(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyCurrentUser, jsonEncode(user.toJson()));
    await prefs.setBool(_keyIsLoggedIn, true);
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w\.\-]+@([\w\-]+\.)+[\w\-]{2,4}$').hasMatch(email);
  }
}

/// Internal class gộp User + password mock
class _MockUser {
  final UserModel user;
  final String passwordHash;

  const _MockUser({required this.user, required this.passwordHash});
}
