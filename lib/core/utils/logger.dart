import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

/// Niveles de log disponibles
enum LogLevel {
  debug,
  info,
  warning,
  error,
}

/// Servicio de logging estructurado usando dart:developer
/// 
/// Uso:
/// ```dart
/// AppLogger.debug('Mensaje de debug');
/// AppLogger.info('Usuario logueado', data: {'userId': '123'});
/// AppLogger.warning('Token por expirar');
/// AppLogger.error('Error en API', error: e, stackTrace: st);
/// ```
class AppLogger {
  static const String _name = 'RehabTech';
  
  // Colores para la consola (solo en debug)
  static const String _reset = '\x1B[0m';
  static const String _red = '\x1B[31m';
  static const String _green = '\x1B[32m';
  static const String _yellow = '\x1B[33m';
  static const String _blue = '\x1B[34m';
  static const String _cyan = '\x1B[36m';

  /// Log de nivel DEBUG - para información detallada de desarrollo
  static void debug(String message, {Map<String, dynamic>? data, String? tag}) {
    _log(LogLevel.debug, message, data: data, tag: tag);
  }

  /// Log de nivel INFO - para eventos importantes de la app
  static void info(String message, {Map<String, dynamic>? data, String? tag}) {
    _log(LogLevel.info, message, data: data, tag: tag);
  }

  /// Log de nivel WARNING - para situaciones potencialmente problemáticas
  static void warning(String message, {Map<String, dynamic>? data, String? tag}) {
    _log(LogLevel.warning, message, data: data, tag: tag);
  }

  /// Log de nivel ERROR - para errores y excepciones
  static void error(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? data,
    String? tag,
  }) {
    _log(
      LogLevel.error,
      message,
      error: error,
      stackTrace: stackTrace,
      data: data,
      tag: tag,
    );
  }

  /// Log interno que usa dart:developer
  static void _log(
    LogLevel level,
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? data,
    String? tag,
  }) {
    // Solo loguear en modo debug
    if (!kDebugMode && level == LogLevel.debug) return;

    final timestamp = DateTime.now().toIso8601String();
    final levelStr = level.name.toUpperCase();
    final tagStr = tag != null ? '[$tag]' : '';
    
    // Construir mensaje formateado
    final buffer = StringBuffer();
    buffer.writeln('$_getColorForLevel(level)[$levelStr]$_reset $tagStr $message');
    
    if (data != null && data.isNotEmpty) {
      buffer.writeln('  📦 Data: $data');
    }
    
    if (error != null) {
      buffer.writeln('  ❌ Error: $error');
    }

    final logMessage = buffer.toString();

    // Usar dart:developer para logging estructurado
    developer.log(
      logMessage,
      time: DateTime.now(),
      level: _getLevelValue(level),
      name: '$_name${tag != null ? '.$tag' : ''}',
      error: error,
      stackTrace: stackTrace,
    );

    // También imprimir en consola con colores en debug
    if (kDebugMode) {
      final color = _getColorForLevel(level);
      final icon = _getIconForLevel(level);
      
      // ignore: avoid_print
      print('$color$icon [$levelStr] $timestamp$_reset');
      // ignore: avoid_print
      print('$color   $tagStr $message$_reset');
      
      if (data != null && data.isNotEmpty) {
        // ignore: avoid_print
        print('$_cyan   📦 $data$_reset');
      }
      
      if (error != null) {
        // ignore: avoid_print
        print('$_red   ❌ $error$_reset');
      }
      
      if (stackTrace != null) {
        // ignore: avoid_print
        print('$_red   📍 ${stackTrace.toString().split('\n').take(5).join('\n   ')}$_reset');
      }
    }
  }

  static String _getColorForLevel(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return _blue;
      case LogLevel.info:
        return _green;
      case LogLevel.warning:
        return _yellow;
      case LogLevel.error:
        return _red;
    }
  }

  static String _getIconForLevel(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return '🔍';
      case LogLevel.info:
        return '✅';
      case LogLevel.warning:
        return '⚠️';
      case LogLevel.error:
        return '🚨';
    }
  }

  static int _getLevelValue(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return 500;
      case LogLevel.info:
        return 800;
      case LogLevel.warning:
        return 900;
      case LogLevel.error:
        return 1000;
    }
  }
}

/// Extension para facilitar el logging en cualquier clase
extension LoggerExtension on Object {
  void logDebug(String message, {Map<String, dynamic>? data}) {
    AppLogger.debug(message, data: data, tag: runtimeType.toString());
  }

  void logInfo(String message, {Map<String, dynamic>? data}) {
    AppLogger.info(message, data: data, tag: runtimeType.toString());
  }

  void logWarning(String message, {Map<String, dynamic>? data}) {
    AppLogger.warning(message, data: data, tag: runtimeType.toString());
  }

  void logError(String message, {Object? error, StackTrace? stackTrace, Map<String, dynamic>? data}) {
    AppLogger.error(message, error: error, stackTrace: stackTrace, data: data, tag: runtimeType.toString());
  }
}
