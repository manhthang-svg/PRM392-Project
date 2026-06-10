import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:origami/core/state/app_state.dart';

void main() {
  group('AppState', () {
    test('legacy user objects default a missing follower flag to false', () {
      const user = UserProfileData(
        id: 'legacy',
        name: 'Legacy User',
        handle: '@legacy',
        bio: '',
        followers: 0,
        following: 0,
        isFollower: null,
      );

      expect(user.isFollower, isFalse);
    });

    test('adds a Newsfeed post and updates profile author snapshots', () {
      final state = AppState();

      state.addPost(
        caption: 'My first community post',
        images: [XFile('sample.jpg')],
      );

      expect(state.posts.first.caption, 'My first community post');
      expect(state.posts.first.localImages, hasLength(1));

      state.updateProfile(
        name: 'Paper Artist',
        handle: '@paperartist',
        bio: 'A new bio',
      );

      expect(state.posts.first.authorName, 'Paper Artist');
      expect(state.currentUser.handle, '@paperartist');
    });

    test('only approved instructions accept reactions and comments', () {
      final state = AppState();
      final processingInstruction = InstructionSubmissionData(
        id: 'processing-instruction',
        title: 'Paper Boat',
        resources: 'One square sheet',
        estimatedMinutes: 10,
        difficulty: 'Easy',
        description: 'A simple paper boat.',
        steps: const [],
        status: SubmissionStatus.processing,
        updatedLabel: 'Sent now',
      );

      state.addInstruction(processingInstruction);
      state.reactToInstruction(processingInstruction.id);
      state.addInstructionComment(
        processingInstruction.id,
        'Clear instructions',
      );

      expect(state.submissions.first.status, SubmissionStatus.processing);
      expect(state.submissions.first.reactions, 0);
      expect(state.submissions.first.comments, isEmpty);

      final approvedInstruction = state.submissions.firstWhere(
        (item) => item.status == SubmissionStatus.approved,
      );
      final initialReactions = approvedInstruction.reactions;
      state.reactToInstruction(approvedInstruction.id);
      state.addInstructionComment(approvedInstruction.id, 'Clear instructions');

      expect(approvedInstruction.reactions, initialReactions + 1);
      expect(approvedInstruction.comments, contains('Clear instructions'));
    });

    test('adds comments to Newsfeed posts and updates the count', () {
      final state = AppState();
      final post = state.posts.first;
      final initialCount = post.comments;

      state.addPostComment(post.id, 'Beautiful folds');

      expect(post.comments, initialCount + 1);
      expect(post.commentItems.last.message, 'Beautiful folds');
      expect(post.commentItems.last.authorId, state.currentUser.id);
      expect(post.commentItems.last.createdLabel, 'Just now');

      state.addPostComment(post.id, '   ');

      expect(post.comments, initialCount + 1);
    });

    test('follows users, saves tutorials, and sends chat messages', () {
      final state = AppState();
      final yuki = state.userById('yuki');

      state.toggleFollow(yuki.id);
      expect(state.userById('yuki').isFollowing, isTrue);

      state.toggleSavedTutorial('geometric-star');
      expect(state.savedTutorialIds, contains('geometric-star'));

      state.sendMessage('sarah', 'Let us fold together');
      final conversation = state.conversationByUserId('sarah');
      expect(conversation.lastMessage, 'Let us fold together');
      expect(conversation.messages.last.sentByMe, isTrue);
    });

    test('adds completed folds to achievement history', () {
      final state = AppState();
      final initialCount = state.foldHistory.length;

      state.addCompletedFold(
        title: 'Paper Boat',
        image: artworkOne,
        difficulty: 'Easy',
        duration: '10 min',
      );

      expect(state.foldHistory, hasLength(initialCount + 1));
      expect(state.foldHistory.first.title, 'Paper Boat');
    });
  });
}
