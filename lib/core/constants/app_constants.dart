/// Các hằng số kích thước dùng trong toàn ứng dụng
class AppDimensions {
  AppDimensions._();

  // Padding/Margin
  static const double paddingXS = 4.0;
  static const double paddingS = 8.0;
  static const double paddingM = 16.0;
  static const double paddingL = 24.0;
  static const double paddingXL = 32.0;
  static const double paddingXXL = 48.0;

  // Border radius
  static const double radiusS = 8.0;
  static const double radiusM = 12.0;
  static const double radiusL = 16.0;
  static const double radiusXL = 24.0;
  static const double radiusFull = 100.0;

  // Icon sizes
  static const double iconS = 16.0;
  static const double iconM = 24.0;
  static const double iconL = 32.0;
  static const double iconXL = 48.0;

  // Button heights
  static const double buttonHeight = 52.0;
  static const double buttonHeightS = 40.0;
}

/// Các chuỗi ký tự dùng trong toàn ứng dụng
class AppStrings {
  AppStrings._();

  // App
  static const String appName = 'Origami';
  static const String appTagline = 'Fold your creativity';

  // Auth
  static const String welcomeBack = 'Welcome back!';
  static const String login = 'Login';
  static const String register = 'Register';
  static const String email = 'Email';
  static const String password = 'Password';
  static const String forgotPassword = 'Forgot Password?';
  static const String noAccount = "Don't have an account? ";
  static const String signUp = 'Sign up';

  // Navigation
  static const String home = 'Home';
  static const String explore = 'Explore';
  static const String create = 'Create';
  static const String messages = 'Messages';
  static const String profile = 'Profile';

  // Newsfeed
  static const String newsfeedTitle = 'Origami Feed';

  // Explore
  static const String exploreTitle = 'Explore';
  static const String searchHint = 'Search origami patterns...';
}
