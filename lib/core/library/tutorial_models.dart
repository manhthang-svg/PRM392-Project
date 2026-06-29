class LibraryTutorial {
  const LibraryTutorial({
    required this.id,
    required this.slug,
    required this.title,
    required this.description,
    required this.thumbnailUrl,
    required this.difficulty,
    required this.estimatedMinutes,
    required this.category,
    required this.creatorName,
    required this.rating,
    required this.stepCount,
  });

  factory LibraryTutorial.fromJson(Map<String, dynamic> json) {
    return LibraryTutorial(
      id: '${json['id']}',
      slug: json['slug'] as String? ?? '',
      title: json['title'] as String? ?? 'Untitled tutorial',
      description: json['description'] as String? ?? '',
      thumbnailUrl: json['thumbnailUrl'] as String? ?? '',
      difficulty: _displayDifficulty(json['difficulty'] as String?),
      estimatedMinutes: (json['estimatedMinutes'] as num?)?.toInt() ?? 0,
      category: json['category'] as String? ?? 'Uncategorized',
      creatorName: json['creatorName'] as String? ?? 'Origami creator',
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      stepCount: (json['stepCount'] as num?)?.toInt() ?? 0,
    );
  }

  final String id;
  final String slug;
  final String title;
  final String description;
  final String thumbnailUrl;
  final String difficulty;
  final int estimatedMinutes;
  final String category;
  final String creatorName;
  final double rating;
  final int stepCount;

  String get duration => '$estimatedMinutes min';
}

class TutorialStepModel {
  const TutorialStepModel({
    required this.stepNumber,
    required this.title,
    required this.description,
    required this.mediaUrl,
  });

  factory TutorialStepModel.fromJson(Map<String, dynamic> json) {
    return TutorialStepModel(
      stepNumber: (json['stepNumber'] as num?)?.toInt() ?? 0,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      mediaUrl: json['mediaUrl'] as String? ?? '',
    );
  }

  final int stepNumber;
  final String title;
  final String description;
  final String mediaUrl;
}

class TutorialDetailModel {
  const TutorialDetailModel({
    required this.summary,
    required this.status,
    required this.materials,
    required this.steps,
  });

  factory TutorialDetailModel.fromJson(Map<String, dynamic> json) {
    final materials = json['materials'];
    final steps = json['steps'];
    return TutorialDetailModel(
      summary: LibraryTutorial.fromJson({
        ...json,
        'stepCount': steps is List ? steps.length : 0,
      }),
      status: json['status'] as String? ?? '',
      materials: materials is List
          ? materials.whereType<String>().toList(growable: false)
          : const [],
      steps: steps is List
          ? steps
                .whereType<Map>()
                .map(
                  (value) => TutorialStepModel.fromJson(
                    Map<String, dynamic>.from(value),
                  ),
                )
                .toList(growable: false)
          : const [],
    );
  }

  final LibraryTutorial summary;
  final String status;
  final List<String> materials;
  final List<TutorialStepModel> steps;
}

class UploadedImage {
  const UploadedImage({required this.secureUrl, required this.publicId});

  factory UploadedImage.fromJson(Map<String, dynamic> json) {
    final secureUrl = json['secureUrl'];
    if (secureUrl is! String || secureUrl.isEmpty) {
      throw const FormatException('Invalid image upload response');
    }
    return UploadedImage(
      secureUrl: secureUrl,
      publicId: json['publicId'] as String? ?? '',
    );
  }

  final String secureUrl;
  final String publicId;
}

class CreateTutorialPayload {
  const CreateTutorialPayload({
    required this.title,
    required this.description,
    required this.categorySlug,
    required this.difficulty,
    required this.estimatedMinutes,
    required this.thumbnailUrl,
    required this.draft,
    required this.materials,
    required this.steps,
  });

  final String title;
  final String description;
  final String categorySlug;
  final String difficulty;
  final int estimatedMinutes;
  final String thumbnailUrl;
  final bool draft;
  final List<String> materials;
  final List<CreateTutorialStepPayload> steps;

  Map<String, dynamic> toJson() => {
    'title': title,
    'description': description,
    'categorySlug': categorySlug,
    'difficulty': difficulty.toUpperCase(),
    'estimatedMinutes': estimatedMinutes > 0 ? estimatedMinutes : null,
    'thumbnailUrl': thumbnailUrl,
    'draft': draft,
    'materials': materials,
    'steps': steps.map((step) => step.toJson()).toList(growable: false),
  };
}

class CreateTutorialStepPayload {
  const CreateTutorialStepPayload({
    required this.description,
    required this.mediaUrl,
  });

  final String description;
  final String mediaUrl;

  Map<String, dynamic> toJson() => {
    'description': description,
    'mediaUrl': mediaUrl,
  };
}

String tutorialCategorySlug(String category) {
  return category.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-');
}

String _displayDifficulty(String? value) {
  if (value == null || value.isEmpty) return 'Unknown';
  final normalized = value.toLowerCase();
  return '${normalized[0].toUpperCase()}${normalized.substring(1)}';
}
