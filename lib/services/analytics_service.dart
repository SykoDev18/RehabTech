import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import '../core/utils/logger.dart';

/// Servicio de Analytics para tracking de eventos de usuario
class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  late FirebaseAnalytics _analytics;
  late FirebaseAnalyticsObserver _observer;
  bool _initialized = false;

  FirebaseAnalyticsObserver get observer => _observer;

  /// Inicializar el servicio de analytics
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      _analytics = FirebaseAnalytics.instance;
      _observer = FirebaseAnalyticsObserver(analytics: _analytics);
      
      // Configurar propiedades de usuario por defecto
      await _analytics.setAnalyticsCollectionEnabled(!kDebugMode || true); // Habilitar en debug para testing
      
      _initialized = true;
      AppLogger.info('Firebase Analytics inicializado', tag: 'Analytics');
    } catch (e) {
      AppLogger.error('Error inicializando Analytics: $e', tag: 'Analytics');
    }
  }

  // ==================== EVENTOS DE AUTENTICACIÓN ====================

  /// Usuario inició sesión
  Future<void> logLogin({required String method}) async {
    await _analytics.logLogin(loginMethod: method);
    AppLogger.debug('Analytics: login ($method)', tag: 'Analytics');
  }

  /// Usuario se registró
  Future<void> logSignUp({required String method}) async {
    await _analytics.logSignUp(signUpMethod: method);
    AppLogger.debug('Analytics: signup ($method)', tag: 'Analytics');
  }

  /// Usuario cerró sesión
  Future<void> logLogout() async {
    await _analytics.logEvent(name: 'logout');
    AppLogger.debug('Analytics: logout', tag: 'Analytics');
  }

  // ==================== EVENTOS DE EJERCICIOS ====================

  /// Usuario inició una sesión de ejercicio
  Future<void> logExerciseStarted({
    required String exerciseId,
    required String exerciseName,
    required String category,
  }) async {
    await _analytics.logEvent(
      name: 'exercise_started',
      parameters: {
        'exercise_id': exerciseId,
        'exercise_name': exerciseName,
        'category': category,
      },
    );
    AppLogger.debug('Analytics: exercise_started ($exerciseName)', tag: 'Analytics');
  }

  /// Usuario completó una sesión de ejercicio
  Future<void> logExerciseCompleted({
    required String exerciseId,
    required String exerciseName,
    required int completedReps,
    required int totalReps,
    required int durationSeconds,
    required double completionPercentage,
  }) async {
    await _analytics.logEvent(
      name: 'exercise_completed',
      parameters: {
        'exercise_id': exerciseId,
        'exercise_name': exerciseName,
        'completed_reps': completedReps,
        'total_reps': totalReps,
        'duration_seconds': durationSeconds,
        'completion_percentage': completionPercentage,
      },
    );
    AppLogger.debug('Analytics: exercise_completed ($exerciseName, $completionPercentage%)', tag: 'Analytics');
  }

  /// Usuario abandonó un ejercicio antes de terminar
  Future<void> logExerciseAbandoned({
    required String exerciseId,
    required String exerciseName,
    required int completedReps,
    required int totalReps,
    required int durationSeconds,
  }) async {
    await _analytics.logEvent(
      name: 'exercise_abandoned',
      parameters: {
        'exercise_id': exerciseId,
        'exercise_name': exerciseName,
        'completed_reps': completedReps,
        'total_reps': totalReps,
        'duration_seconds': durationSeconds,
      },
    );
    AppLogger.debug('Analytics: exercise_abandoned ($exerciseName)', tag: 'Analytics');
  }

  // ==================== EVENTOS DE CHAT/IA ====================

  /// Usuario envió mensaje al asistente Nora
  Future<void> logChatMessage({required bool isUser}) async {
    await _analytics.logEvent(
      name: 'chat_message',
      parameters: {
        'is_user': isUser,
      },
    );
  }

  /// Usuario inició conversación con IA
  Future<void> logAIChatStarted() async {
    await _analytics.logEvent(name: 'ai_chat_started');
    AppLogger.debug('Analytics: ai_chat_started', tag: 'Analytics');
  }

  // ==================== EVENTOS DE NAVEGACIÓN ====================

  /// Usuario visitó una pantalla
  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    await _analytics.logScreenView(
      screenName: screenName,
      screenClass: screenClass,
    );
  }

  // ==================== EVENTOS DE TERAPEUTA ====================

  /// Terapeuta agregó un paciente
  Future<void> logPatientAdded() async {
    await _analytics.logEvent(name: 'patient_added');
    AppLogger.debug('Analytics: patient_added', tag: 'Analytics');
  }

  /// Terapeuta creó una rutina
  Future<void> logRoutineCreated({required int exerciseCount}) async {
    await _analytics.logEvent(
      name: 'routine_created',
      parameters: {'exercise_count': exerciseCount},
    );
    AppLogger.debug('Analytics: routine_created ($exerciseCount exercises)', tag: 'Analytics');
  }

  // ==================== EVENTOS DE PROGRESO ====================

  /// Usuario vio su reporte de progreso
  Future<void> logProgressViewed({required String period}) async {
    await _analytics.logEvent(
      name: 'progress_viewed',
      parameters: {'period': period},
    );
    AppLogger.debug('Analytics: progress_viewed ($period)', tag: 'Analytics');
  }

  /// Usuario compartió su progreso
  Future<void> logProgressShared({required String method}) async {
    await _analytics.logShare(
      contentType: 'progress_report',
      itemId: 'progress',
      method: method,
    );
    AppLogger.debug('Analytics: progress_shared ($method)', tag: 'Analytics');
  }

  // ==================== PROPIEDADES DE USUARIO ====================

  /// Establecer ID de usuario
  Future<void> setUserId(String? userId) async {
    await _analytics.setUserId(id: userId);
  }

  /// Establecer tipo de usuario (paciente/terapeuta)
  Future<void> setUserType(String userType) async {
    await _analytics.setUserProperty(name: 'user_type', value: userType);
  }

  /// Establecer si el usuario tiene terapeuta asignado
  Future<void> setHasTherapist(bool hasTherapist) async {
    await _analytics.setUserProperty(
      name: 'has_therapist',
      value: hasTherapist.toString(),
    );
  }
}
