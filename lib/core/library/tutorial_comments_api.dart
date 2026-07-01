import 'package:dio/dio.dart';

import 'package:origami/core/network/api_client.dart';

class TutorialCommentsApi {
  TutorialCommentsApi(this._client);

  final ApiClient _client;

  Future<List<TutorialCommentDto>> findStepComments({
    required String tutorialId,
    required String stepId,
    int page = 0,
    int size = 10,
    String sort = 'newest',
  }) async {
    try {
      final response = await _client.dio.get<Map<String, dynamic>>(
        '/api/tutorials/$tutorialId/steps/$stepId/comments',
        queryParameters: {'page': page, 'size': size, 'sort': sort},
      );
      final data = response.data?['data'];
      if (data is! List) {
        throw const FormatException('Invalid tutorial comments response');
      }
      return data
          .whereType<Map>()
          .map(
            (value) =>
                TutorialCommentDto.fromJson(Map<String, dynamic>.from(value)),
          )
          .toList(growable: false);
    } on DioException catch (error) {
      throw TutorialCommentsFailure.fromDio(error);
    } on FormatException catch (error) {
      throw TutorialCommentsFailure(error.message);
    }
  }

  Future<TutorialCommentDto> addStepComment({
    required String tutorialId,
    required String stepId,
    required String content,
  }) async {
    try {
      final response = await _client.dio.post<Map<String, dynamic>>(
        '/api/tutorials/$tutorialId/steps/$stepId/comments',
        data: {'content': content.trim()},
      );
      return _commentFromEnvelope(response.data);
    } on DioException catch (error) {
      throw TutorialCommentsFailure.fromDio(error);
    } on FormatException catch (error) {
      throw TutorialCommentsFailure(error.message);
    }
  }

  Future<List<TutorialCommentDto>> findReplies(
    String commentId, {
    int page = 0,
    int size = 10,
  }) async {
    try {
      final response = await _client.dio.get<Map<String, dynamic>>(
        '/api/tutorial-comments/$commentId/replies',
        queryParameters: {'page': page, 'size': size},
      );
      final data = response.data?['data'];
      if (data is! List) {
        throw const FormatException('Invalid tutorial replies response');
      }
      return data
          .whereType<Map>()
          .map(
            (value) =>
                TutorialCommentDto.fromJson(Map<String, dynamic>.from(value)),
          )
          .toList(growable: false);
    } on DioException catch (error) {
      throw TutorialCommentsFailure.fromDio(error);
    } on FormatException catch (error) {
      throw TutorialCommentsFailure(error.message);
    }
  }

  Future<TutorialCommentDto> addReply({
    required String commentId,
    required String content,
  }) async {
    try {
      final response = await _client.dio.post<Map<String, dynamic>>(
        '/api/tutorial-comments/$commentId/replies',
        data: {'content': content.trim()},
      );
      return _commentFromEnvelope(response.data);
    } on DioException catch (error) {
      throw TutorialCommentsFailure.fromDio(error);
    } on FormatException catch (error) {
      throw TutorialCommentsFailure(error.message);
    }
  }

  Future<TutorialCommentDto> updateComment({
    required String commentId,
    required String content,
  }) async {
    try {
      final response = await _client.dio.put<Map<String, dynamic>>(
        '/api/tutorial-comments/$commentId',
        data: {'content': content.trim()},
      );
      return _commentFromEnvelope(response.data);
    } on DioException catch (error) {
      throw TutorialCommentsFailure.fromDio(error);
    } on FormatException catch (error) {
      throw TutorialCommentsFailure(error.message);
    }
  }

  Future<TutorialCommentDto> deleteComment(String commentId) async {
    try {
      final response = await _client.dio.delete<Map<String, dynamic>>(
        '/api/tutorial-comments/$commentId',
      );
      return _commentFromEnvelope(response.data);
    } on DioException catch (error) {
      throw TutorialCommentsFailure.fromDio(error);
    } on FormatException catch (error) {
      throw TutorialCommentsFailure(error.message);
    }
  }

  Future<TutorialCommentDto> toggleCommentLike(String commentId) async {
    try {
      final response = await _client.dio.patch<Map<String, dynamic>>(
        '/api/tutorial-comments/$commentId/like',
      );
      return _commentFromEnvelope(response.data);
    } on DioException catch (error) {
      throw TutorialCommentsFailure.fromDio(error);
    } on FormatException catch (error) {
      throw TutorialCommentsFailure(error.message);
    }
  }

  TutorialCommentDto _commentFromEnvelope(Map<String, dynamic>? envelope) {
    final data = envelope?['data'];
    if (data is! Map) {
      throw const FormatException('Invalid tutorial comment response');
    }
    return TutorialCommentDto.fromJson(Map<String, dynamic>.from(data));
  }
}

class TutorialCommentDto {
  const TutorialCommentDto({
    required this.id,
    required this.tutorialId,
    required this.stepId,
    this.parentId,
    this.replyToUserId,
    required this.content,
    required this.authorId,
    required this.authorName,
    required this.authorAvatarUrl,
    required this.likeCount,
    required this.likedByCurrentUser,
    required this.replyCount,
    required this.deleted,
    required this.edited,
    required this.canEdit,
    required this.canDelete,
    this.createdAt,
    this.updatedAt,
  });

  factory TutorialCommentDto.fromJson(Map<String, dynamic> json) {
    return TutorialCommentDto(
      id: '${json['id'] ?? ''}',
      tutorialId: '${json['tutorialId'] ?? ''}',
      stepId: '${json['stepId'] ?? ''}',
      parentId: json['parentId'] == null ? null : '${json['parentId']}',
      replyToUserId: json['replyToUserId'] == null
          ? null
          : '${json['replyToUserId']}',
      content: json['content'] as String? ?? '',
      authorId: '${json['authorId'] ?? json['userId'] ?? ''}',
      authorName:
          json['authorName'] as String? ??
          json['userName'] as String? ??
          'Origami creator',
      authorAvatarUrl:
          json['authorAvatarUrl'] as String? ??
          json['userAvatar'] as String? ??
          '',
      likeCount: (json['likeCount'] as num?)?.toInt() ?? 0,
      likedByCurrentUser: json['likedByCurrentUser'] == true,
      replyCount: (json['replyCount'] as num?)?.toInt() ?? 0,
      deleted: json['deleted'] == true,
      edited: json['edited'] == true,
      canEdit: json['canEdit'] == true,
      canDelete: json['canDelete'] == true,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? ''),
    );
  }

  final String id;
  final String tutorialId;
  final String stepId;
  final String? parentId;
  final String? replyToUserId;
  final String content;
  final String authorId;
  final String authorName;
  final String authorAvatarUrl;
  final int likeCount;
  final bool likedByCurrentUser;
  final int replyCount;
  final bool deleted;
  final bool edited;
  final bool canEdit;
  final bool canDelete;
  final DateTime? createdAt;
  final DateTime? updatedAt;
}

class TutorialCommentsFailure implements Exception {
  const TutorialCommentsFailure(this.message);

  factory TutorialCommentsFailure.fromDio(DioException error) {
    final data = error.response?.data;
    if (data is Map && data['message'] is String) {
      return TutorialCommentsFailure(data['message'] as String);
    }
    if (error.type == DioExceptionType.connectionError) {
      return const TutorialCommentsFailure(
        'Cannot connect to the tutorial comments server.',
      );
    }
    return const TutorialCommentsFailure('Could not load tutorial comments.');
  }

  final String message;
}
