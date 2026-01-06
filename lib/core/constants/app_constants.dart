/// Application constants
class AppConstants {
  AppConstants._();

  // App info
  static const String appName = 'RehabTech';
  static const String appVersion = '1.0.0';
  
  // Animation durations
  static const Duration animationFast = Duration(milliseconds: 200);
  static const Duration animationNormal = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);
  
  // Padding & Spacing
  static const double paddingXS = 4.0;
  static const double paddingS = 8.0;
  static const double paddingM = 16.0;
  static const double paddingL = 24.0;
  static const double paddingXL = 32.0;
  
  // Border radius
  static const double radiusS = 8.0;
  static const double radiusM = 12.0;
  static const double radiusL = 16.0;
  static const double radiusXL = 24.0;
  static const double radiusRound = 28.0;
  
  // Icon sizes
  static const double iconS = 16.0;
  static const double iconM = 24.0;
  static const double iconL = 32.0;
  
  // Avatar sizes
  static const double avatarS = 32.0;
  static const double avatarM = 48.0;
  static const double avatarL = 72.0;
  
  // Countdown
  static const int countdownSeconds = 5;
  
  // Chat
  static const int maxMessageLength = 1000;
  
  // Exercise
  static const int defaultSets = 3;
  static const int defaultReps = 10;
  static const int defaultRestSeconds = 60;
}
