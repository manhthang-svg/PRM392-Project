import 'dart:convert';

class AuthTokens {
  const AuthTokens({
    required this.accessToken,
    required this.refreshToken,
    this.tokenType = 'Bearer',
    this.expiresIn,
  });

  factory AuthTokens.fromApiData(Map<String, dynamic> data) {
    final accessToken = data['accessToken'];
    final refreshToken = data['refreshToken'];
    if (accessToken is! String || accessToken.isEmpty) {
      throw const FormatException('The server did not return an access token');
    }
    if (refreshToken is! String || refreshToken.isEmpty) {
      throw const FormatException('The server did not return a refresh token');
    }

    return AuthTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
      tokenType: data['tokenType'] as String? ?? 'Bearer',
      expiresIn: (data['expiresIn'] as num?)?.toInt(),
    );
  }

  final String accessToken;
  final String refreshToken;
  final String tokenType;
  final int? expiresIn;

  bool get isAccessTokenExpired {
    try {
      final parts = accessToken.split('.');
      if (parts.length != 3) return true;
      final payload = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      );
      final expiration = (payload as Map<String, dynamic>)['exp'];
      if (expiration is! num) return true;

      // Refresh slightly early so a token cannot expire in flight.
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      return expiration.toInt() <= now + 30;
    } on Object {
      return true;
    }
  }

  List<String> get authorities {
    try {
      final payload = _payload;
      final value = payload['authorities'];
      if (value is List) {
        return value.whereType<String>().toList(growable: false);
      }
      return const [];
    } on Object {
      return const [];
    }
  }

  bool get isAdmin => authorities.contains('ADMIN');

  Map<String, dynamic> get _payload {
    final parts = accessToken.split('.');
    if (parts.length != 3) return const {};
    final decoded = jsonDecode(
      utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
    );
    return decoded is Map<String, dynamic> ? decoded : const {};
  }
}
