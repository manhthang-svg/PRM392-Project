import 'package:dio/dio.dart';
import 'package:origami/core/network/api_client.dart';

class UserSearchApi {
  UserSearchApi(this._client);

  final ApiClient _client;

  Future<List<UserSearchDto>> search({
    required String query,
    int size = 30,
  }) async {
    try {
      final response = await _client.dio.get<Map<String, dynamic>>(
        '/api/users/search',
        queryParameters: {'q': query.trim(), 'size': size.clamp(1, 50)},
      );
      final data = response.data?['data'];
      if (data is! List) {
        throw const FormatException('Invalid user search response');
      }
      return data
          .whereType<Map>()
          .map(
            (item) => UserSearchDto.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(growable: false);
    } on DioException catch (error) {
      throw UserSearchFailure.fromDio(error);
    } on FormatException catch (error) {
      throw UserSearchFailure(error.message);
    }
  }
}

class UserSearchDto {
  const UserSearchDto({
    required this.id,
    required this.username,
    required this.displayName,
    required this.handle,
    required this.bio,
    required this.avatarUrl,
    required this.followers,
    required this.following,
    required this.isFollowing,
  });

  factory UserSearchDto.fromJson(Map<String, dynamic> json) {
    final handle = json['handle'] as String? ?? '';
    return UserSearchDto(
      id: '${json['id'] ?? ''}',
      username: json['username'] as String? ?? '',
      displayName: json['displayName'] as String? ?? '',
      handle: handle.isEmpty
          ? ''
          : handle.startsWith('@')
          ? handle
          : '@$handle',
      bio: json['bio'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String? ?? '',
      followers: _readInt(json['followerCount']),
      following: _readInt(json['followingCount']),
      isFollowing: json['followedByCurrentUser'] == true,
    );
  }

  final String id;
  final String username;
  final String displayName;
  final String handle;
  final String bio;
  final String avatarUrl;
  final int followers;
  final int following;
  final bool isFollowing;

  String get name {
    if (displayName.trim().isNotEmpty) return displayName.trim();
    if (handle.trim().isNotEmpty) return handle.trim();
    return username.trim().isEmpty ? 'Origami User' : username.trim();
  }

  static int _readInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('${value ?? ''}') ?? 0;
  }
}

class UserSearchFailure implements Exception {
  const UserSearchFailure(this.message);

  factory UserSearchFailure.fromDio(DioException error) {
    final data = error.response?.data;
    if (data is Map && data['message'] is String) {
      return UserSearchFailure(data['message'] as String);
    }
    if (error.type == DioExceptionType.connectionError) {
      return const UserSearchFailure('Cannot connect to the user server.');
    }
    return const UserSearchFailure('Could not search users.');
  }

  final String message;
}
