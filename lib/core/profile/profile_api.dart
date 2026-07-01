import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:origami/core/library/tutorial_models.dart';
import 'package:origami/core/network/api_client.dart';

class ProfileApi {
  ProfileApi(this._client);

  final ApiClient _client;

  Future<UserProfileDto> me() async {
    try {
      final response = await _client.dio.get<Map<String, dynamic>>(
        '/api/users/me',
      );
      return _profileFromEnvelope(response.data);
    } on DioException catch (error) {
      throw ProfileFailure.fromDio(error);
    } on FormatException catch (error) {
      throw ProfileFailure(error.message);
    }
  }

  Future<UserProfileDto> update({
    required String displayName,
    required String handle,
    required String bio,
    String? avatarUrl,
  }) async {
    try {
      final response = await _client.dio.put<Map<String, dynamic>>(
        '/api/users/me',
        data: {
          'displayName': displayName.trim(),
          'handle': handle.trim(),
          'bio': bio.trim(),
          'avatarUrl': avatarUrl,
        },
      );
      return _profileFromEnvelope(response.data);
    } on DioException catch (error) {
      throw ProfileFailure.fromDio(error);
    } on FormatException catch (error) {
      throw ProfileFailure(error.message);
    }
  }

  Future<List<UserProfileDto>> followers(String userId) async {
    try {
      final response = await _client.dio.get<Map<String, dynamic>>(
        '/api/users/$userId/followers',
      );
      return _profilesFromEnvelope(response.data);
    } on DioException catch (error) {
      throw ProfileFailure.fromDio(error);
    } on FormatException catch (error) {
      throw ProfileFailure(error.message);
    }
  }

  Future<List<UserProfileDto>> following(String userId) async {
    try {
      final response = await _client.dio.get<Map<String, dynamic>>(
        '/api/users/$userId/following',
      );
      return _profilesFromEnvelope(response.data);
    } on DioException catch (error) {
      throw ProfileFailure.fromDio(error);
    } on FormatException catch (error) {
      throw ProfileFailure(error.message);
    }
  }

  Future<UserProfileDto> follow(String userId) async {
    try {
      final response = await _client.dio.post<Map<String, dynamic>>(
        '/api/users/$userId/follow',
      );
      return _profileFromEnvelope(response.data);
    } on DioException catch (error) {
      throw ProfileFailure.fromDio(error);
    } on FormatException catch (error) {
      throw ProfileFailure(error.message);
    }
  }

  Future<UserProfileDto> unfollow(String userId) async {
    try {
      final response = await _client.dio.delete<Map<String, dynamic>>(
        '/api/users/$userId/follow',
      );
      return _profileFromEnvelope(response.data);
    } on DioException catch (error) {
      throw ProfileFailure.fromDio(error);
    } on FormatException catch (error) {
      throw ProfileFailure(error.message);
    }
  }

  Future<UploadedImage> uploadAvatar(XFile image) async {
    try {
      final bytes = await image.readAsBytes();
      final response = await _client.dio.post<Map<String, dynamic>>(
        '/api/media/images',
        data: FormData.fromMap({
          'file': MultipartFile.fromBytes(
            bytes,
            filename: image.name,
            contentType:
                MultipartFile.lookupMediaType(image.name) ??
                DioMediaType('image', 'jpeg'),
          ),
        }),
      );
      final data = response.data?['data'];
      if (data is! Map) {
        throw const FormatException('Invalid avatar upload response');
      }
      return UploadedImage.fromJson(Map<String, dynamic>.from(data));
    } on DioException catch (error) {
      throw ProfileFailure.fromDio(error);
    } on FormatException catch (error) {
      throw ProfileFailure(error.message);
    }
  }

  UserProfileDto _profileFromEnvelope(Map<String, dynamic>? envelope) {
    final data = envelope?['data'];
    if (data is! Map) {
      throw const FormatException('Invalid profile response');
    }
    return UserProfileDto.fromJson(Map<String, dynamic>.from(data));
  }

  List<UserProfileDto> _profilesFromEnvelope(Map<String, dynamic>? envelope) {
    final data = envelope?['data'];
    if (data is! List) {
      throw const FormatException('Invalid profile list response');
    }
    return data
        .whereType<Map>()
        .map((item) => UserProfileDto.fromJson(Map<String, dynamic>.from(item)))
        .toList(growable: false);
  }
}

class UserProfileDto {
  const UserProfileDto({
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

  factory UserProfileDto.fromJson(Map<String, dynamic> json) {
    final handle = json['handle'] as String? ?? '';
    return UserProfileDto(
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

  static int _readInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('${value ?? ''}') ?? 0;
  }
}

class ProfileFailure implements Exception {
  const ProfileFailure(this.message);

  factory ProfileFailure.fromDio(DioException error) {
    final data = error.response?.data;
    if (data is Map && data['message'] is String) {
      return ProfileFailure(data['message'] as String);
    }
    if (error.type == DioExceptionType.connectionError) {
      return const ProfileFailure('Cannot connect to the profile server.');
    }
    return const ProfileFailure('Could not load profile data.');
  }

  final String message;
}
