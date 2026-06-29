import 'package:flutter/material.dart';
import 'package:origami/app/app_shell.dart';
import 'package:origami/core/library/tutorial_models.dart';
import 'package:origami/features/auth/screens/login_screen.dart';
import 'package:origami/features/auth/screens/signup_screen.dart';
import 'package:origami/features/auth/screens/splash_screen.dart';
import 'package:origami/features/contribution/screens/contribution_screens.dart';
import 'package:origami/features/explore/screens/completion_screen.dart';
import 'package:origami/features/explore/screens/step_by_step_screen.dart';
import 'package:origami/features/explore/screens/tutorial_detail_screen.dart';
import 'package:origami/features/newsfeed/screens/search_users_screen.dart';
import 'package:origami/features/profile/screens/achievements_screen.dart';
import 'package:origami/features/profile/screens/profile_screens.dart';

abstract final class AppRoutes {
  static const splash = '/';
  static const login = '/login';
  static const signup = '/signup';
  static const newsfeed = '/newsfeed';
  static const library = '/library';
  static const create = '/create';
  static const profile = '/profile';
  static const tutorialDetail = '/tutorial/detail';
  static const tutorialSteps = '/tutorial/steps';
  static const tutorialComplete = '/tutorial/complete';
  static const searchUsers = '/search/users';
  static const achievements = '/achievements';
  static const achievementDetail = '/achievements/detail';
  static const savedTutorials = '/saved-tutorials';
  static const editProfile = '/profile/edit';
  static const publicProfile = '/profile/public';
  static const followers = '/profile/followers';
  static const following = '/profile/following';
  static const createPost = '/create/post';
  static const createInstruction = '/create/instruction';
  static const instructionSubmissionDetail = '/create/instruction/detail';
  static const postActivityDetail = '/create/post/detail';
}

abstract final class AppRouter {
  static Route<void> onGenerateRoute(RouteSettings settings) {
    final argument = settings.arguments;
    final stringArgument = argument is String ? argument : null;
    final Widget page = switch (settings.name) {
      AppRoutes.splash => const SplashScreen(),
      AppRoutes.login => const LoginScreen(),
      AppRoutes.signup => const SignupScreen(),
      AppRoutes.newsfeed => const AppShell(initialIndex: 0),
      AppRoutes.library => const AppShell(initialIndex: 1),
      AppRoutes.create => const AppShell(initialIndex: 2),
      AppRoutes.profile => const AppShell(initialIndex: 3),
      AppRoutes.tutorialDetail => TutorialDetailScreen(
        tutorialId: stringArgument ?? '0',
      ),
      AppRoutes.tutorialSteps => StepByStepScreen(
        tutorial: argument is TutorialDetailModel ? argument : null,
      ),
      AppRoutes.tutorialComplete => const CompletionScreen(),
      AppRoutes.searchUsers => const SearchUsersScreen(),
      AppRoutes.achievements => const AchievementsScreen(),
      AppRoutes.achievementDetail => AchievementDetailScreen(
        historyId: stringArgument ?? 'fold-1',
      ),
      AppRoutes.savedTutorials => const SavedTutorialsScreen(),
      AppRoutes.editProfile => const EditProfileScreen(),
      AppRoutes.publicProfile => PublicProfileScreen(
        userId: stringArgument ?? 'sarah',
      ),
      AppRoutes.followers => const SocialConnectionsScreen(
        mode: SocialConnectionMode.followers,
      ),
      AppRoutes.following => const SocialConnectionsScreen(
        mode: SocialConnectionMode.following,
      ),
      AppRoutes.createPost => const CreatePostScreen(),
      AppRoutes.createInstruction => const CreateInstructionScreen(),
      AppRoutes.instructionSubmissionDetail =>
        InstructionSubmissionDetailScreen(
          submissionId: stringArgument ?? 'instruction-1',
        ),
      AppRoutes.postActivityDetail => PostActivityDetailScreen(
        postId: stringArgument ?? 'post-1',
      ),
      _ => const SplashScreen(),
    };

    return MaterialPageRoute<void>(builder: (_) => page, settings: settings);
  }
}
