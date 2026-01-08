import 'package:flutter/foundation.dart';
import '../core/utils/logger.dart';
import '../models/exercise.dart';

/// Servicio para manejar Deep Links
class DeepLinkService {
  static final DeepLinkService _instance = DeepLinkService._internal();
  factory DeepLinkService() => _instance;
  DeepLinkService._internal();

  /// Parsea una URI de deep link y retorna la ruta de GoRouter
  /// 
  /// Soporta los siguientes formatos:
  /// - rehabtech://exercise/1
  /// - rehabtech://chat/nora
  /// - rehabtech://profile
  /// - rehabtech://progress
  /// - https://rehabtech.app/exercise/1
  String? parseDeepLink(Uri uri) {
    AppLogger.info('Deep link recibido: $uri', tag: 'DeepLink');
    
    final path = uri.path.isEmpty ? uri.host : uri.path;
    final segments = path.split('/').where((s) => s.isNotEmpty).toList();
    
    if (segments.isEmpty) {
      return '/main';
    }

    switch (segments[0]) {
      case 'exercise':
        if (segments.length > 1) {
          final exerciseId = segments[1];
          return '/main/exercise/$exerciseId';
        }
        return '/main';
        
      case 'chat':
        if (segments.length > 1 && segments[1] == 'nora') {
          final conversationId = uri.queryParameters['id'];
          if (conversationId != null) {
            return '/main/chat/nora?conversationId=$conversationId';
          }
          return '/main/chat/nora';
        }
        if (segments.length > 1 && segments[1] == 'therapist') {
          return '/main/chat/therapist';
        }
        return '/main';
        
      case 'profile':
        if (segments.length > 1) {
          return '/profile/${segments[1]}';
        }
        return '/main'; // Tab de perfil
        
      case 'progress':
        return '/main'; // Tab de progreso
        
      case 'routine':
        if (segments.length > 1) {
          final routineId = segments[1];
          return '/main/routine/$routineId';
        }
        return '/main';
        
      case 'notification':
        // Manejar clicks en notificaciones
        final type = uri.queryParameters['type'];
        return _handleNotificationDeepLink(type, uri.queryParameters);
        
      default:
        AppLogger.warning('Deep link no reconocido: $uri', tag: 'DeepLink');
        return '/main';
    }
  }

  /// Maneja deep links provenientes de notificaciones
  String _handleNotificationDeepLink(String? type, Map<String, String> params) {
    switch (type) {
      case 'daily_reminder':
        return '/main'; // Ir a ejercicios
        
      case 'therapist_message':
        return '/main/chat/therapist';
        
      case 'new_routine':
        final routineId = params['routineId'];
        if (routineId != null) {
          return '/main/routine/$routineId';
        }
        return '/main';
        
      case 'progress_update':
        return '/main'; // Tab de progreso
        
      default:
        return '/main';
    }
  }

  /// Genera un deep link para compartir un ejercicio
  Uri generateExerciseLink(String exerciseId) {
    return Uri.parse('https://rehabtech.app/exercise/$exerciseId');
  }

  /// Genera un deep link para compartir progreso
  Uri generateProgressLink(String date) {
    return Uri.parse('https://rehabtech.app/progress?date=$date');
  }

  /// Genera un deep link interno (scheme personalizado)
  Uri generateInternalLink(String path, {Map<String, String>? queryParams}) {
    return Uri(
      scheme: 'rehabtech',
      host: path.split('/').first,
      path: path.contains('/') ? '/${path.split('/').skip(1).join('/')}' : '',
      queryParameters: queryParams,
    );
  }

  /// Obtiene el ejercicio por ID para navegación por deep link
  Exercise? getExerciseById(String id) {
    try {
      return allExercises.firstWhere((e) => e.id == id);
    } catch (e) {
      AppLogger.warning('Ejercicio no encontrado: $id', tag: 'DeepLink');
      return null;
    }
  }

  /// Debug: imprime información del deep link
  void debugDeepLink(Uri uri) {
    if (kDebugMode) {
      AppLogger.debug('''
Deep Link Debug:
  URI: $uri
  Scheme: ${uri.scheme}
  Host: ${uri.host}
  Path: ${uri.path}
  Segments: ${uri.pathSegments}
  Query: ${uri.queryParameters}
''', tag: 'DeepLink');
    }
  }
}
