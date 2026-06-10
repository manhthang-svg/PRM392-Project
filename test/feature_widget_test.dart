import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:origami/app/app_shell.dart';
import 'package:origami/app/routes.dart';
import 'package:origami/core/state/app_state.dart';
import 'package:origami/features/contribution/screens/contribution_screens.dart';
import 'package:origami/features/newsfeed/screens/newsfeed_screen.dart';
import 'package:origami/features/profile/screens/profile_screens.dart';

Widget _testApp(Widget home) {
  return AppStateScope(
    state: AppState(),
    child: MaterialApp(
      onGenerateRoute: AppRouter.onGenerateRoute,
      home: Scaffold(body: home),
    ),
  );
}

void main() {
  testWidgets('Create hub exposes both creator workflows', (tester) async {
    await tester.pumpWidget(_testApp(const CreatorHubTab()));

    expect(find.text('Post to Newsfeed'), findsOneWidget);
    expect(find.text('Create Origami Instruction'), findsOneWidget);
    expect(find.text('Recent Activity'), findsOneWidget);
    expect(find.text('Processing'), findsOneWidget);
    expect(find.text('Approved'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Rejected'), 250);
    expect(find.text('Rejected'), findsOneWidget);
  });

  testWidgets('Profile keeps follower stats and removes model gallery', (
    tester,
  ) async {
    await tester.pumpWidget(_testApp(const ProfileHomeTab()));

    expect(find.text('Followers'), findsOneWidget);
    expect(find.text('Following'), findsOneWidget);
    expect(find.text('Edit Profile'), findsOneWidget);
    expect(find.text('Achievements'), findsOneWidget);
    expect(find.text('Saved Tutorials'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Log Out'), 200);
    expect(find.text('Log Out'), findsOneWidget);
    expect(find.text('Models'), findsNothing);
    expect(find.text('Completed Models'), findsNothing);
  });

  testWidgets('Library filter opens category difficulty and duration popup', (
    tester,
  ) async {
    await tester.pumpWidget(_testApp(const AppShell(initialIndex: 1)));

    await tester.tap(find.text('Filters'));
    await tester.pumpAndSettle();

    expect(find.text('Category'), findsOneWidget);
    expect(find.text('Difficulty'), findsOneWidget);
    expect(find.text('Duration'), findsOneWidget);
    expect(find.text('Box'), findsOneWidget);
    expect(find.text('Over 60 min'), findsOneWidget);
    expect(find.text('Apply Filters'), findsOneWidget);
  });

  testWidgets('Instruction community actions only appear after approval', (
    tester,
  ) async {
    await tester.pumpWidget(
      _testApp(
        const InstructionSubmissionDetailScreen(submissionId: 'instruction-2'),
      ),
    );

    expect(
      find.text(
        'Reactions and comments will be available after this instruction is approved.',
      ),
      findsOneWidget,
    );
    expect(find.text('Write a comment...'), findsNothing);
    expect(find.text('24 reacts'), findsNothing);

    await tester.pumpWidget(
      _testApp(
        const InstructionSubmissionDetailScreen(submissionId: 'instruction-1'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('128 reacts'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Write a comment...'), 250);
    expect(find.text('Write a comment...'), findsOneWidget);
  });

  testWidgets('Newsfeed comments can be opened and submitted', (tester) async {
    await tester.pumpWidget(_testApp(const NewsfeedHomeTab()));

    final commentButton = find.byKey(const Key('postComments-post-1'));
    await tester.ensureVisible(commentButton);
    await tester.pumpAndSettle();
    await tester.tap(commentButton);
    await tester.pumpAndSettle();

    expect(find.text('89 comments'), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('postCommentField')),
      'Wonderful work',
    );
    await tester.tap(find.byKey(const Key('sendPostComment-post-1')));
    await tester.pumpAndSettle();

    expect(find.text('Wonderful work'), findsOneWidget);
    expect(find.text('90 comments'), findsOneWidget);
  });

  testWidgets('Profile logout clears navigation and returns to login', (
    tester,
  ) async {
    await tester.pumpWidget(_testApp(const ProfileHomeTab()));

    await tester.scrollUntilVisible(find.text('Log Out'), 200);
    await tester.tap(find.text('Log Out'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Log Out'));
    await tester.pumpAndSettle();

    expect(find.text('Welcome Back'), findsOneWidget);
    expect(find.text('Log In'), findsOneWidget);
  });

  testWidgets('Followers and following screens show relationship lists', (
    tester,
  ) async {
    await tester.pumpWidget(
      _testApp(
        const SocialConnectionsScreen(mode: SocialConnectionMode.followers),
      ),
    );

    expect(find.text('Followers'), findsOneWidget);
    expect(find.text('Sarah Chen'), findsOneWidget);
    expect(find.text('Search followers...'), findsOneWidget);

    await tester.pumpWidget(
      _testApp(
        const SocialConnectionsScreen(mode: SocialConnectionMode.following),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Following'), findsWidgets);
    expect(find.text('Alex Park'), findsOneWidget);
    expect(find.text('Search following...'), findsOneWidget);
  });
}
