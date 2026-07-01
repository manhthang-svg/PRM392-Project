import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:origami/core/library/tutorial_models.dart';
import 'package:origami/core/network/api_client.dart';

class NewsfeedApi {
  NewsfeedApi(this._client);

  final ApiClient _client;

  Future<List<NewsfeedPostDto>> findFeed() async {
    try {
      final response = await _client.dio.get<Map<String, dynamic>>(
        '/api/posts',
      );
      return _postsFromEnvelope(response.data);
    } on DioException catch (error) {
      throw NewsfeedFailure.fromDio(error);
    } on FormatException catch (error) {
      throw NewsfeedFailure(error.message);
    }
  }

  Future<List<NewsfeedPostDto>> findMine() async {
    try {
      final response = await _client.dio.get<Map<String, dynamic>>(
        '/api/posts/mine',
      );
      return _postsFromEnvelope(response.data);
    } on DioException catch (error) {
      throw NewsfeedFailure.fromDio(error);
    } on FormatException catch (error) {
      throw NewsfeedFailure(error.message);
    }
  }

  Future<NewsfeedPostDto> createPost({
    required String caption,
    required List<String> mediaUrls,
  }) async {
    try {
      final response = await _client.dio.post<Map<String, dynamic>>(
        '/api/posts',
        data: {'caption': caption.trim(), 'mediaUrls': mediaUrls},
      );
      return _postFromEnvelope(response.data);
    } on DioException catch (error) {
      throw NewsfeedFailure.fromDio(error);
    } on FormatException catch (error) {
      throw NewsfeedFailure(error.message);
    }
  }

  Future<UploadedImage> uploadImage(XFile image) async {
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
        throw const FormatException('Invalid upload response');
      }
      return UploadedImage.fromJson(Map<String, dynamic>.from(data));
    } on DioException catch (error) {
      throw NewsfeedFailure.fromDio(error);
    } on FormatException catch (error) {
      throw NewsfeedFailure(error.message);
    }
  }

  Future<NewsfeedPostDto> toggleLike(String postId) async {
    try {
      final response = await _client.dio.patch<Map<String, dynamic>>(
        '/api/posts/$postId/like',
      );
      return _postFromEnvelope(response.data);
    } on DioException catch (error) {
      throw NewsfeedFailure.fromDio(error);
    } on FormatException catch (error) {
      throw NewsfeedFailure(error.message);
    }
  }

  Future<List<NewsfeedCommentDto>> findComments(
    String postId, {
    int page = 0,
    int size = 10,
    String sort = 'newest',
  }) async {
    try {
      final response = await _client.dio.get<Map<String, dynamic>>(
        '/api/posts/$postId/comments',
        queryParameters: {'page': page, 'size': size, 'sort': sort},
      );
      final data = response.data?['data'];
      if (data is! List) {
        throw const FormatException('Invalid comments response');
      }
      return data
          .whereType<Map>()
          .map(
            (value) =>
                NewsfeedCommentDto.fromJson(Map<String, dynamic>.from(value)),
          )
          .toList(growable: false);
    } on DioException catch (error) {
      throw NewsfeedFailure.fromDio(error);
    } on FormatException catch (error) {
      throw NewsfeedFailure(error.message);
    }
  }

  Future<NewsfeedCommentDto> addComment({
    required String postId,
    required String content,
  }) async {
    try {
      final response = await _client.dio.post<Map<String, dynamic>>(
        '/api/posts/$postId/comments',
        data: {'content': content.trim()},
      );
      final data = response.data?['data'];
      if (data is! Map) {
        throw const FormatException('Invalid comment response');
      }
      return NewsfeedCommentDto.fromJson(Map<String, dynamic>.from(data));
    } on DioException catch (error) {
      throw NewsfeedFailure.fromDio(error);
    } on FormatException catch (error) {
      throw NewsfeedFailure(error.message);
    }
  }

  Future<List<NewsfeedCommentDto>> findReplies(
    String commentId, {
    int page = 0,
    int size = 10,
  }) async {
    try {
      final response = await _client.dio.get<Map<String, dynamic>>(
        '/api/comments/$commentId/replies',
        queryParameters: {'page': page, 'size': size},
      );
      final data = response.data?['data'];
      if (data is! List) {
        throw const FormatException('Invalid replies response');
      }
      return data
          .whereType<Map>()
          .map(
            (value) =>
                NewsfeedCommentDto.fromJson(Map<String, dynamic>.from(value)),
          )
          .toList(growable: false);
    } on DioException catch (error) {
      throw NewsfeedFailure.fromDio(error);
    } on FormatException catch (error) {
      throw NewsfeedFailure(error.message);
    }
  }

  Future<NewsfeedCommentDto> addReply({
    required String commentId,
    required String content,
  }) async {
    try {
      final response = await _client.dio.post<Map<String, dynamic>>(
        '/api/comments/$commentId/replies',
        data: {'content': content.trim()},
      );
      final data = response.data?['data'];
      if (data is! Map) {
        throw const FormatException('Invalid reply response');
      }
      return NewsfeedCommentDto.fromJson(Map<String, dynamic>.from(data));
    } on DioException catch (error) {
      throw NewsfeedFailure.fromDio(error);
    } on FormatException catch (error) {
      throw NewsfeedFailure(error.message);
    }
  }

  Future<NewsfeedCommentDto> updateComment({
    required String commentId,
    required String content,
  }) async {
    try {
      final response = await _client.dio.put<Map<String, dynamic>>(
        '/api/comments/$commentId',
        data: {'content': content.trim()},
      );
      final data = response.data?['data'];
      if (data is! Map) {
        throw const FormatException('Invalid comment response');
      }
      return NewsfeedCommentDto.fromJson(Map<String, dynamic>.from(data));
    } on DioException catch (error) {
      throw NewsfeedFailure.fromDio(error);
    } on FormatException catch (error) {
      throw NewsfeedFailure(error.message);
    }
  }

  Future<NewsfeedCommentDto> deleteComment(String commentId) async {
    try {
      final response = await _client.dio.delete<Map<String, dynamic>>(
        '/api/comments/$commentId',
      );
      final data = response.data?['data'];
      if (data is! Map) {
        throw const FormatException('Invalid comment response');
      }
      return NewsfeedCommentDto.fromJson(Map<String, dynamic>.from(data));
    } on DioException catch (error) {
      throw NewsfeedFailure.fromDio(error);
    } on FormatException catch (error) {
      throw NewsfeedFailure(error.message);
    }
  }

  Future<NewsfeedCommentDto> toggleCommentLike(String commentId) async {
    try {
      final response = await _client.dio.patch<Map<String, dynamic>>(
        '/api/comments/$commentId/like',
      );
      final data = response.data?['data'];
      if (data is! Map) {
        throw const FormatException('Invalid comment response');
      }
      return NewsfeedCommentDto.fromJson(Map<String, dynamic>.from(data));
    } on DioException catch (error) {
      throw NewsfeedFailure.fromDio(error);
    } on FormatException catch (error) {
      throw NewsfeedFailure(error.message);
    }
  }

  NewsfeedPostDto _postFromEnvelope(Map<String, dynamic>? envelope) {
    final data = envelope?['data'];
    if (data is! Map) {
      throw const FormatException('Invalid post response');
    }
    return NewsfeedPostDto.fromJson(Map<String, dynamic>.from(data));
  }

  List<NewsfeedPostDto> _postsFromEnvelope(Map<String, dynamic>? envelope) {
    final data = envelope?['data'];
    if (data is! List) {
      throw const FormatException('Invalid posts response');
    }
    return data
        .whereType<Map>()
        .map(
          (value) => NewsfeedPostDto.fromJson(Map<String, dynamic>.from(value)),
        )
        .toList(growable: false);
  }
}

class NewsfeedPostDto {
  const NewsfeedPostDto({
    required this.id,
    required this.caption,
    required this.status,
    required this.authorId,
    required this.authorName,
    required this.authorAvatarUrl,
    required this.mediaUrls,
    required this.likes,
    required this.comments,
    required this.likedByMe,
    this.rejectionReason,
    this.tutorialId,
    this.tutorialTitle,
    this.createdAt,
  });

  factory NewsfeedPostDto.fromJson(Map<String, dynamic> json) {
    final media = json['mediaUrls'];
    return NewsfeedPostDto(
      id: '${json['id'] ?? ''}',
      caption: json['caption'] as String? ?? '',
      status: json['status'] as String? ?? '',
      rejectionReason: json['rejectionReason'] as String?,
      authorId: '${json['authorId'] ?? ''}',
      authorName: json['authorName'] as String? ?? 'Origami creator',
      authorAvatarUrl: json['authorAvatarUrl'] as String? ?? '',
      tutorialId: json['tutorialId'] == null ? null : '${json['tutorialId']}',
      tutorialTitle: json['tutorialTitle'] as String?,
      mediaUrls: media is List
          ? media.whereType<String>().toList(growable: false)
          : const [],
      likes: (json['likes'] as num?)?.toInt() ?? 0,
      comments: (json['comments'] as num?)?.toInt() ?? 0,
      likedByMe: json['likedByMe'] == true,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
    );
  }

  final String id;
  final String caption;
  final String status;
  final String? rejectionReason;
  final String authorId;
  final String authorName;
  final String authorAvatarUrl;
  final String? tutorialId;
  final String? tutorialTitle;
  final List<String> mediaUrls;
  final int likes;
  final int comments;
  final bool likedByMe;
  final DateTime? createdAt;
}

class NewsfeedCommentDto {
  const NewsfeedCommentDto({
    required this.id,
    required this.postId,
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

  factory NewsfeedCommentDto.fromJson(Map<String, dynamic> json) {
    return NewsfeedCommentDto(
      id: '${json['id'] ?? ''}',
      postId: '${json['postId'] ?? ''}',
      parentId: json['parentId'] == null ? null : '${json['parentId']}',
      replyToUserId: json['replyToUserId'] == null
          ? null
          : '${json['replyToUserId']}',
      content: json['content'] as String? ?? '',
      authorId: '${json['authorId'] ?? ''}',
      authorName: json['authorName'] as String? ?? 'Origami creator',
      authorAvatarUrl: json['authorAvatarUrl'] as String? ?? '',
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
  final String postId;
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

class NewsfeedFailure implements Exception {
  const NewsfeedFailure(this.message);

  factory NewsfeedFailure.fromDio(DioException error) {
    final data = error.response?.data;
    if (data is Map && data['message'] is String) {
      return NewsfeedFailure(data['message'] as String);
    }
    if (error.type == DioExceptionType.connectionError) {
      return const NewsfeedFailure('Cannot connect to the newsfeed server.');
    }
    return const NewsfeedFailure('Could not load newsfeed data.');
  }

  final String message;
}
