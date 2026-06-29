import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:origami/core/library/tutorial_models.dart';
import 'package:origami/core/network/api_client.dart';

abstract interface class LibraryGateway {
  Future<List<LibraryTutorial>> findTutorials({
    String? query,
    String? category,
    String? difficulty,
    int? minMinutes,
    int? maxMinutes,
  });

  Future<TutorialDetailModel> findTutorial(String id);

  Future<UploadedImage> uploadImage(XFile image);

  Future<TutorialDetailModel> createTutorial(CreateTutorialPayload payload);
}

class LibraryApi implements LibraryGateway {
  LibraryApi(this._client);

  final ApiClient _client;

  @override
  Future<List<LibraryTutorial>> findTutorials({
    String? query,
    String? category,
    String? difficulty,
    int? minMinutes,
    int? maxMinutes,
  }) async {
    try {
      final response = await _client.dio.get<Map<String, dynamic>>(
        '/api/tutorials',
        queryParameters: {
          if (query != null && query.trim().isNotEmpty) 'query': query.trim(),
          if (category != null && category.isNotEmpty)
            'category': tutorialCategorySlug(category),
          if (difficulty != null && difficulty.isNotEmpty)
            'difficulty': difficulty.toUpperCase(),
          'minMinutes': ?minMinutes,
          'maxMinutes': ?maxMinutes,
        },
      );
      final data = _envelopeData(response.data);
      if (data is! List) {
        throw const FormatException('Invalid Library response');
      }
      return data
          .whereType<Map>()
          .map(
            (value) =>
                LibraryTutorial.fromJson(Map<String, dynamic>.from(value)),
          )
          .toList(growable: false);
    } on DioException catch (error) {
      throw LibraryFailure.fromDio(error);
    } on FormatException catch (error) {
      throw LibraryFailure(error.message);
    }
  }

  @override
  Future<TutorialDetailModel> findTutorial(String id) async {
    try {
      final response = await _client.dio.get<Map<String, dynamic>>(
        '/api/tutorials/$id',
      );
      final data = _envelopeData(response.data);
      if (data is! Map) {
        throw const FormatException('Invalid tutorial response');
      }
      return TutorialDetailModel.fromJson(Map<String, dynamic>.from(data));
    } on DioException catch (error) {
      throw LibraryFailure.fromDio(error);
    } on FormatException catch (error) {
      throw LibraryFailure(error.message);
    }
  }

  @override
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
      final data = _envelopeData(response.data);
      if (data is! Map) {
        throw const FormatException('Invalid upload response');
      }
      return UploadedImage.fromJson(Map<String, dynamic>.from(data));
    } on DioException catch (error) {
      throw LibraryFailure.fromDio(error);
    } on FormatException catch (error) {
      throw LibraryFailure(error.message);
    }
  }

  @override
  Future<TutorialDetailModel> createTutorial(
    CreateTutorialPayload payload,
  ) async {
    try {
      final response = await _client.dio.post<Map<String, dynamic>>(
        '/api/tutorials',
        data: payload.toJson(),
      );
      final data = _envelopeData(response.data);
      if (data is! Map) {
        throw const FormatException('Invalid tutorial response');
      }
      return TutorialDetailModel.fromJson(Map<String, dynamic>.from(data));
    } on DioException catch (error) {
      throw LibraryFailure.fromDio(error);
    } on FormatException catch (error) {
      throw LibraryFailure(error.message);
    }
  }

  Object? _envelopeData(Map<String, dynamic>? envelope) => envelope?['data'];
}

class LibraryFailure implements Exception {
  const LibraryFailure(this.message);

  factory LibraryFailure.fromDio(DioException error) {
    final data = error.response?.data;
    if (data is Map && data['message'] is String) {
      return LibraryFailure(data['message'] as String);
    }
    if (error.type == DioExceptionType.connectionError) {
      return const LibraryFailure('Cannot connect to the Library server.');
    }
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return const LibraryFailure(
        'The Library server took too long to respond.',
      );
    }
    return const LibraryFailure('Could not complete the Library request.');
  }

  final String message;

  @override
  String toString() => message;
}
