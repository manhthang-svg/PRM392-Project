import 'package:dio/dio.dart';
import 'package:origami/core/network/api_client.dart';

abstract interface class PostReviewGateway {
  Future<List<AdminPostReviewItem>> findPosts({String status = 'PROCESSING'});

  Future<AdminPostReviewItem> reviewPost({
    required String id,
    required String status,
    String? note,
  });
}

class PostReviewApi implements PostReviewGateway {
  PostReviewApi(this._client);

  final ApiClient _client;

  @override
  Future<List<AdminPostReviewItem>> findPosts({
    String status = 'PROCESSING',
  }) async {
    try {
      final response = await _client.dio.get<Map<String, dynamic>>(
        '/api/admin/posts',
        queryParameters: {'status': status},
      );
      final data = response.data?['data'];
      if (data is! List) {
        throw const FormatException('Invalid post review response');
      }
      return data
          .whereType<Map>()
          .map(
            (value) =>
                AdminPostReviewItem.fromJson(Map<String, dynamic>.from(value)),
          )
          .toList(growable: false);
    } on DioException catch (error) {
      throw PostReviewFailure.fromDio(error);
    } on FormatException catch (error) {
      throw PostReviewFailure(error.message);
    }
  }

  @override
  Future<AdminPostReviewItem> reviewPost({
    required String id,
    required String status,
    String? note,
  }) async {
    try {
      final response = await _client.dio.patch<Map<String, dynamic>>(
        '/api/admin/posts/$id/review',
        data: {
          'status': status,
          if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
        },
      );
      final data = response.data?['data'];
      if (data is! Map) {
        throw const FormatException('Invalid post review response');
      }
      return AdminPostReviewItem.fromJson(Map<String, dynamic>.from(data));
    } on DioException catch (error) {
      throw PostReviewFailure.fromDio(error);
    } on FormatException catch (error) {
      throw PostReviewFailure(error.message);
    }
  }
}

class AdminPostReviewItem {
  const AdminPostReviewItem({
    required this.id,
    required this.caption,
    required this.status,
    required this.authorName,
    required this.mediaUrls,
    this.tutorialTitle,
    this.rejectionReason,
    this.submittedAt,
    this.reviewedAt,
    this.reviewerName,
  });

  factory AdminPostReviewItem.fromJson(Map<String, dynamic> json) {
    final media = json['mediaUrls'];
    return AdminPostReviewItem(
      id: '${json['id'] ?? ''}',
      caption: json['caption'] as String? ?? '',
      status: json['status'] as String? ?? '',
      authorName: json['authorName'] as String? ?? 'Unknown creator',
      tutorialTitle: json['tutorialTitle'] as String?,
      mediaUrls: media is List
          ? media.whereType<String>().toList(growable: false)
          : const [],
      rejectionReason: json['rejectionReason'] as String?,
      submittedAt: DateTime.tryParse(json['submittedAt'] as String? ?? ''),
      reviewedAt: DateTime.tryParse(json['reviewedAt'] as String? ?? ''),
      reviewerName: json['reviewerName'] as String?,
    );
  }

  final String id;
  final String caption;
  final String status;
  final String authorName;
  final String? tutorialTitle;
  final List<String> mediaUrls;
  final String? rejectionReason;
  final DateTime? submittedAt;
  final DateTime? reviewedAt;
  final String? reviewerName;
}

class PostReviewFailure implements Exception {
  const PostReviewFailure(this.message);

  factory PostReviewFailure.fromDio(DioException error) {
    final data = error.response?.data;
    if (data is Map && data['message'] is String) {
      return PostReviewFailure(data['message'] as String);
    }
    if (error.response?.statusCode == 403) {
      return const PostReviewFailure(
        'Only admin or manager accounts can review posts.',
      );
    }
    if (error.type == DioExceptionType.connectionError) {
      return const PostReviewFailure('Cannot connect to the admin API.');
    }
    return const PostReviewFailure(
      'Could not complete the post review action.',
    );
  }

  final String message;

  @override
  String toString() => message;
}
