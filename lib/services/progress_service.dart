import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ProgressData {
  final DateTime date;
  final String exerciseId;
  final String exerciseName;
  final int completedReps;
  final int totalReps;
  final int durationSeconds;
  final int painLevel; // 0-10
  final double completionPercentage;

  ProgressData({
    required this.date,
    required this.exerciseId,
    required this.exerciseName,
    required this.completedReps,
    required this.totalReps,
    required this.durationSeconds,
    required this.painLevel,
    required this.completionPercentage,
  });

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'exerciseId': exerciseId,
    'exerciseName': exerciseName,
    'completedReps': completedReps,
    'totalReps': totalReps,
    'durationSeconds': durationSeconds,
    'painLevel': painLevel,
    'completionPercentage': completionPercentage,
  };

  factory ProgressData.fromJson(Map<String, dynamic> json) => ProgressData(
    date: DateTime.parse(json['date']),
    exerciseId: json['exerciseId'],
    exerciseName: json['exerciseName'],
    completedReps: json['completedReps'],
    totalReps: json['totalReps'],
    durationSeconds: json['durationSeconds'],
    painLevel: json['painLevel'],
    completionPercentage: json['completionPercentage'],
  );
}

class UserProfile {
  String name;
  String lastName;
  String email;
  String phone;
  String birthDate;
  String condition;
  String therapistName;
  String photoUrl;

  UserProfile({
    this.name = '',
    this.lastName = '',
    this.email = '',
    this.phone = '',
    this.birthDate = '',
    this.condition = '',
    this.therapistName = '',
    this.photoUrl = '',
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'lastName': lastName,
    'email': email,
    'phone': phone,
    'birthDate': birthDate,
    'condition': condition,
    'therapistName': therapistName,
    'photoUrl': photoUrl,
  };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    name: json['name'] ?? '',
    lastName: json['lastName'] ?? '',
    email: json['email'] ?? '',
    phone: json['phone'] ?? '',
    birthDate: json['birthDate'] ?? '',
    condition: json['condition'] ?? '',
    therapistName: json['therapistName'] ?? '',
    photoUrl: json['photoUrl'] ?? '',
  );
}

class ProgressService {
  static const String _progressKey = 'progress_data';
  static const String _profileKey = 'user_profile';
  static const String _settingsKey = 'app_settings';

  // Singleton
  static final ProgressService _instance = ProgressService._internal();
  factory ProgressService() => _instance;
  ProgressService._internal();

  List<ProgressData> _progressList = [];
  UserProfile _userProfile = UserProfile();
  Map<String, dynamic> _settings = {
    'useFaceId': true,
    'dailyReminder': true,
    'reminderTime': '09:00',
    'weeklyProgress': true,
    'achievementNotifications': true,
    'therapistMessages': true,
    'textSize': 1.0,
    'highContrast': false,
  };

  List<ProgressData> get progressList => _progressList;
  UserProfile get userProfile => _userProfile;
  Map<String, dynamic> get settings => _settings;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Cargar progreso
    final progressJson = prefs.getString(_progressKey);
    if (progressJson != null) {
      final List<dynamic> decoded = jsonDecode(progressJson);
      _progressList = decoded.map((e) => ProgressData.fromJson(e)).toList();
    }

    // Cargar perfil
    final profileJson = prefs.getString(_profileKey);
    if (profileJson != null) {
      _userProfile = UserProfile.fromJson(jsonDecode(profileJson));
    }

    // Cargar configuraciones
    final settingsJson = prefs.getString(_settingsKey);
    if (settingsJson != null) {
      _settings = jsonDecode(settingsJson);
    }
  }

  Future<void> saveProgress(ProgressData data) async {
    _progressList.add(data);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _progressKey,
      jsonEncode(_progressList.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> saveProfile(UserProfile profile) async {
    _userProfile = profile;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_profileKey, jsonEncode(profile.toJson()));
  }

  Future<void> saveSetting(String key, dynamic value) async {
    _settings[key] = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_settingsKey, jsonEncode(_settings));
  }

  dynamic getSetting(String key) {
    return _settings[key];
  }

  // Estadísticas semanales
  Map<String, dynamic> getWeeklyStats() {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    
    final weekData = _progressList.where((p) => 
      p.date.isAfter(weekStart.subtract(const Duration(days: 1)))).toList();
    
    int totalExercises = weekData.length;
    int totalSeconds = weekData.fold(0, (sum, p) => sum + p.durationSeconds);
    double avgPain = weekData.isEmpty ? 0 : 
      weekData.fold(0.0, (sum, p) => sum + p.painLevel) / weekData.length;
    double avgCompletion = weekData.isEmpty ? 0 :
      weekData.fold(0.0, (sum, p) => sum + p.completionPercentage) / weekData.length;
    
    // Datos por día de la semana
    List<double> dailyExercises = List.filled(7, 0);
    List<double> dailyMovement = List.filled(7, 0);
    
    for (var p in weekData) {
      int dayIndex = p.date.weekday - 1;
      if (dayIndex >= 0 && dayIndex < 7) {
        dailyExercises[dayIndex]++;
        dailyMovement[dayIndex] = p.completionPercentage;
      }
    }
    
    return {
      'totalExercises': totalExercises,
      'totalSeconds': totalSeconds,
      'avgPain': avgPain,
      'avgCompletion': avgCompletion,
      'dailyExercises': dailyExercises,
      'dailyMovement': dailyMovement,
      'streak': _calculateStreak(),
    };
  }

  // Estadísticas mensuales
  Map<String, dynamic> getMonthlyStats() {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    
    final monthData = _progressList.where((p) => 
      p.date.isAfter(monthStart.subtract(const Duration(days: 1)))).toList();
    
    int totalExercises = monthData.length;
    int totalSeconds = monthData.fold(0, (sum, p) => sum + p.durationSeconds);
    double avgPain = monthData.isEmpty ? 0 : 
      monthData.fold(0.0, (sum, p) => sum + p.painLevel) / monthData.length;
    double avgCompletion = monthData.isEmpty ? 0 :
      monthData.fold(0.0, (sum, p) => sum + p.completionPercentage) / monthData.length;
    
    // Datos por semana del mes
    List<double> weeklyExercises = List.filled(4, 0);
    List<double> weeklyMovement = List.filled(4, 0);
    
    for (var p in monthData) {
      int weekIndex = ((p.date.day - 1) / 7).floor();
      if (weekIndex >= 0 && weekIndex < 4) {
        weeklyExercises[weekIndex]++;
        weeklyMovement[weekIndex] = p.completionPercentage;
      }
    }
    
    return {
      'totalExercises': totalExercises,
      'totalSeconds': totalSeconds,
      'avgPain': avgPain,
      'avgCompletion': avgCompletion,
      'weeklyExercises': weeklyExercises,
      'weeklyMovement': weeklyMovement,
    };
  }

  // Estadísticas totales
  Map<String, dynamic> getTotalStats() {
    int totalExercises = _progressList.length;
    int totalSeconds = _progressList.fold(0, (sum, p) => sum + p.durationSeconds);
    double avgPain = _progressList.isEmpty ? 0 : 
      _progressList.fold(0.0, (sum, p) => sum + p.painLevel) / _progressList.length;
    double avgCompletion = _progressList.isEmpty ? 0 :
      _progressList.fold(0.0, (sum, p) => sum + p.completionPercentage) / _progressList.length;
    
    return {
      'totalExercises': totalExercises,
      'totalSeconds': totalSeconds,
      'avgPain': avgPain,
      'avgCompletion': avgCompletion,
      'firstSession': _progressList.isNotEmpty ? _progressList.first.date : null,
      'totalDays': _progressList.isNotEmpty 
        ? DateTime.now().difference(_progressList.first.date).inDays + 1
        : 0,
    };
  }

  int _calculateStreak() {
    if (_progressList.isEmpty) return 0;
    
    int streak = 0;
    DateTime checkDate = DateTime.now();
    
    while (true) {
      final hasExercise = _progressList.any((p) =>
        p.date.year == checkDate.year &&
        p.date.month == checkDate.month &&
        p.date.day == checkDate.day
      );
      
      if (hasExercise) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    
    return streak;
  }

  Future<void> clearAllData() async {
    _progressList.clear();
    _userProfile = UserProfile();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_progressKey);
    await prefs.remove(_profileKey);
    await prefs.remove(_settingsKey);
  }
}
