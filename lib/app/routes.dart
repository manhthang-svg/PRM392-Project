import 'package:flutter/material.dart';
import 'package:origami/features/auth/screens/splash_screen.dart';
import 'package:origami/features/auth/screens/login_screen.dart';
import 'package:origami/features/newsfeed/screens/newsfeed_screen.dart';
import 'package:origami/features/explore/screens/explore_screen.dart';
import 'package:origami/features/contribution/screens/contribution_screen.dart';
import 'package:origami/features/chat/screens/chat_screen.dart';
import 'package:origami/features/profile/screens/profile_screen.dart';

/// Định nghĩa tất cả các route trong ứng dụng
class AppRoutes {
  AppRoutes._();

  // Route names
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String newsfeed = '/newsfeed';
  static const String explore = '/explore';
  static const String contribution = '/contribution';
  static const String chat = '/chat';
  static const String profile = '/profile';

  /// Map các route name với widget tương ứng
  static Map<String, WidgetBuilder> get routes => {
    splash: (_) => const SplashScreen(),
    login: (_) => const LoginScreen(),
    newsfeed: (_) => const NewsfeedScreen(),
    explore: (_) => const ExploreScreen(),
    contribution: (_) => const ContributionScreen(),
    chat: (_) => const ChatScreen(),
    profile: (_) => const ProfileScreen(),
  };
}
