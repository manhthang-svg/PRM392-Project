import 'package:dio/dio.dart';
import 'package:origami/core/constants/api_constants.dart';
import 'package:origami/core/library/tutorial_models.dart';
import 'package:origami/core/network/api_client.dart';

class AdminApi {
  AdminApi(this._client);

  final ApiClient _client;

  Future<List<AdminUserItem>> findUsers() async {
    try {
      final response = await _client.dio.get<Map<String, dynamic>>(
        '/api/admin/users',
      );
      final data = response.data?['data'];
      if (data is! List) throw const FormatException('Invalid users response');
      return data
          .whereType<Map>()
          .map(
            (value) => AdminUserItem.fromJson(Map<String, dynamic>.from(value)),
          )
          .toList(growable: false);
    } on DioException catch (error) {
      throw AdminFailure.fromDio(error);
    } on FormatException catch (error) {
      throw AdminFailure(error.message);
    }
  }

  Future<List<LibraryTutorial>> findTutorials({
    String status = 'PROCESSING',
  }) async {
    try {
      final response = await _client.dio.get<Map<String, dynamic>>(
        '/api/admin/tutorials',
        queryParameters: {'status': status},
      );
      final data = response.data?['data'];
      if (data is! List) {
        throw const FormatException('Invalid tutorials response');
      }
      return data
          .whereType<Map>()
          .map(
            (value) =>
                LibraryTutorial.fromJson(Map<String, dynamic>.from(value)),
          )
          .toList(growable: false);
    } on DioException catch (error) {
      throw AdminFailure.fromDio(error);
    } on FormatException catch (error) {
      throw AdminFailure(error.message);
    }
  }

  Future<TutorialDetailModel> findTutorial(String id) async {
    try {
      final response = await _client.dio.get<Map<String, dynamic>>(
        '/api/admin/tutorials/$id',
      );
      final data = response.data?['data'];
      if (data is! Map) {
        throw const FormatException('Invalid tutorial detail response');
      }
      return TutorialDetailModel.fromJson(Map<String, dynamic>.from(data));
    } on DioException catch (error) {
      throw AdminFailure.fromDio(error);
    } on FormatException catch (error) {
      throw AdminFailure(error.message);
    }
  }

  Future<void> reviewTutorial({
    required String id,
    required String status,
    String? note,
  }) async {
    try {
      await _client.dio.patch<Map<String, dynamic>>(
        '/api/admin/tutorials/$id/review',
        data: {
          'status': status,
          if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
        },
      );
    } on DioException catch (error) {
      throw AdminFailure.fromDio(error);
    }
  }
}

class AdminUserItem {
  const AdminUserItem({
    required this.id,
    required this.username,
    required this.displayName,
    required this.handle,
    required this.roles,
  });

  factory AdminUserItem.fromJson(Map<String, dynamic> json) {
    final roles = json['roles'];
    return AdminUserItem(
      id: '${json['id'] ?? ''}',
      username: json['username'] as String? ?? '',
      displayName: json['displayName'] as String? ?? '',
      handle: json['handle'] as String? ?? '',
      roles: roles is List
          ? roles
                .whereType<Map>()
                .map((role) => role['name'])
                .whereType<String>()
                .toList(growable: false)
          : const [],
    );
  }

  final String id;
  final String username;
  final String displayName;
  final String handle;
  final List<String> roles;
}

class AdminFailure implements Exception {
  const AdminFailure(this.message);

  factory AdminFailure.fromDio(DioException error) {
    final data = error.response?.data;
    if (data is Map && data['message'] is String) {
      return AdminFailure(data['message'] as String);
    }
    if (data is String && data.trim().isNotEmpty) {
      return AdminFailure(data.trim());
    }
    if (error.response?.statusCode == 401) {
      return const AdminFailure(
        'Your admin session has expired. Please log in again.',
      );
    }
    if (error.response?.statusCode == 403) {
      return const AdminFailure(
        'Only admin or manager accounts can access this page.',
      );
    }
    final statusCode = error.response?.statusCode;
    if (statusCode != null) {
      return AdminFailure('Could not load admin data. HTTP $statusCode.');
    }
    if (error.type == DioExceptionType.connectionError) {
      return AdminFailure(
        'Cannot connect to the admin server at ${ApiConstants.baseUrl}.',
      );
    }
    return const AdminFailure('Could not load admin data.');
  }

  final String message;
}
