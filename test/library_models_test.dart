import 'package:flutter_test/flutter_test.dart';
import 'package:origami/core/library/tutorial_models.dart';

void main() {
  test('parses Library tutorial and detail responses', () {
    final detail = TutorialDetailModel.fromJson({
      'id': 12,
      'slug': 'paper-crane-a1b2c3d4',
      'title': 'Paper Crane',
      'description': 'A traditional crane',
      'thumbnailUrl': 'https://res.cloudinary.com/demo/image/upload/crane.jpg',
      'difficulty': 'EASY',
      'estimatedMinutes': 15,
      'category': 'Birds',
      'creatorName': 'Paper Artist',
      'status': 'APPROVED',
      'rating': 4.5,
      'materials': ['15cm square paper'],
      'steps': [
        {
          'stepNumber': 1,
          'description': 'Fold the paper diagonally',
          'mediaUrl':
              'https://res.cloudinary.com/demo/image/upload/step-one.jpg',
        },
      ],
    });

    expect(detail.summary.id, '12');
    expect(detail.summary.difficulty, 'Easy');
    expect(detail.summary.duration, '15 min');
    expect(detail.steps.single.stepNumber, 1);
    expect(detail.materials.single, '15cm square paper');
  });

  test('serializes a submitted tutorial payload', () {
    const payload = CreateTutorialPayload(
      title: 'Paper Crane',
      description: 'A traditional crane',
      categorySlug: 'birds',
      difficulty: 'Easy',
      estimatedMinutes: 15,
      thumbnailUrl: 'https://res.cloudinary.com/demo/image/upload/crane.jpg',
      draft: false,
      materials: ['Square paper'],
      steps: [
        CreateTutorialStepPayload(
          description: 'First fold',
          mediaUrl: 'https://res.cloudinary.com/demo/image/upload/step-one.jpg',
        ),
      ],
    );

    expect(payload.toJson()['difficulty'], 'EASY');
    expect(payload.toJson()['draft'], isFalse);
    expect(payload.toJson()['steps'], hasLength(1));
  });
}
