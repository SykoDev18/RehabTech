/// API and service constants
class ApiConstants {
  ApiConstants._();
  
  // Firebase collections
  static const String usersCollection = 'users';
  static const String exercisesCollection = 'exercises';
  static const String noraChatsCollection = 'nora_chats';
  static const String messagesCollection = 'messages';
  static const String patientContextCollection = 'patient_context';
  static const String progressCollection = 'progress';
  
  // Gemini AI
  static const String geminiModel = 'gemini-2.0-flash';
  
  // SharedPreferences keys
  static const String themeModeKey = 'themeMode';
  static const String userProfileKey = 'userProfile';
  static const String onboardingCompleteKey = 'onboardingComplete';
  static const String fcmTokenKey = 'fcmToken';
}
