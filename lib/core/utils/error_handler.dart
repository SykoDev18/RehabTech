import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'logger.dart';

/// Tipos de errores de la aplicación
enum AppErrorType {
  network,
  authentication,
  permission,
  validation,
  server,
  unknown,
}

/// Modelo de error personalizado de la app
class AppError implements Exception {
  final String message;
  final String? userMessage;
  final AppErrorType type;
  final Object? originalError;
  final StackTrace? stackTrace;
  final Map<String, dynamic>? context;

  AppError({
    required this.message,
    this.userMessage,
    this.type = AppErrorType.unknown,
    this.originalError,
    this.stackTrace,
    this.context,
  });

  /// Mensaje amigable para mostrar al usuario
  String get displayMessage {
    return userMessage ?? _getDefaultMessage();
  }

  String _getDefaultMessage() {
    switch (type) {
      case AppErrorType.network:
        return 'Error de conexión. Verifica tu internet.';
      case AppErrorType.authentication:
        return 'Error de autenticación. Inicia sesión nuevamente.';
      case AppErrorType.permission:
        return 'No tienes permisos para realizar esta acción.';
      case AppErrorType.validation:
        return 'Los datos ingresados no son válidos.';
      case AppErrorType.server:
        return 'Error del servidor. Intenta más tarde.';
      case AppErrorType.unknown:
        return 'Ha ocurrido un error inesperado.';
    }
  }

  @override
  String toString() => 'AppError($type): $message';
}

/// Manejador de errores centralizado
class ErrorHandler {
  static final ErrorHandler _instance = ErrorHandler._internal();
  factory ErrorHandler() => _instance;
  ErrorHandler._internal();

  /// Stream de errores para escuchar globalmente
  final _errorController = StreamController<AppError>.broadcast();
  Stream<AppError> get errorStream => _errorController.stream;

  /// Callback opcional para mostrar errores en UI
  void Function(AppError error)? onError;

  /// Inicializar el handler de errores de Flutter
  void initialize() {
    // Capturar errores de Flutter
    FlutterError.onError = (FlutterErrorDetails details) {
      AppLogger.error(
        'Flutter Error',
        error: details.exception,
        stackTrace: details.stack,
        tag: 'FlutterError',
      );
      
      if (kDebugMode) {
        FlutterError.dumpErrorToConsole(details);
      }
    };

    // Capturar errores de zona (async)
    PlatformDispatcher.instance.onError = (error, stack) {
      AppLogger.error(
        'Platform Error',
        error: error,
        stackTrace: stack,
        tag: 'PlatformError',
      );
      return true;
    };

    AppLogger.info('ErrorHandler inicializado', tag: 'ErrorHandler');
  }

  /// Manejar un error y convertirlo a AppError
  AppError handle(
    Object error, {
    StackTrace? stackTrace,
    String? context,
    bool notify = true,
  }) {
    final appError = _convertToAppError(error, stackTrace, context);
    
    // Loguear el error
    AppLogger.error(
      appError.message,
      error: appError.originalError,
      stackTrace: appError.stackTrace,
      data: appError.context,
      tag: 'ErrorHandler',
    );

    // Emitir al stream
    _errorController.add(appError);

    // Notificar si hay callback
    if (notify && onError != null) {
      onError!(appError);
    }

    return appError;
  }

  /// Ejecutar una función con manejo de errores
  Future<T?> runGuarded<T>(
    Future<T> Function() action, {
    String? context,
    T? fallback,
    void Function(AppError)? onError,
  }) async {
    try {
      return await action();
    } catch (e, st) {
      final error = handle(e, stackTrace: st, context: context, notify: false);
      if (onError != null) {
        onError(error);
      }
      return fallback;
    }
  }

  /// Convertir cualquier error a AppError
  AppError _convertToAppError(Object error, StackTrace? stackTrace, String? context) {
    // Firebase Auth errors
    if (error is FirebaseAuthException) {
      return AppError(
        message: 'Firebase Auth: ${error.code}',
        userMessage: _getFirebaseAuthMessage(error.code),
        type: AppErrorType.authentication,
        originalError: error,
        stackTrace: stackTrace,
        context: context != null ? {'context': context} : null,
      );
    }

    // Firestore errors
    if (error is FirebaseException) {
      return AppError(
        message: 'Firebase: ${error.code} - ${error.message}',
        userMessage: _getFirebaseMessage(error.code),
        type: _getFirebaseErrorType(error.code),
        originalError: error,
        stackTrace: stackTrace,
        context: context != null ? {'context': context} : null,
      );
    }

    // Network errors
    if (error.toString().contains('SocketException') ||
        error.toString().contains('NetworkException') ||
        error.toString().contains('Connection')) {
      return AppError(
        message: 'Network error: $error',
        type: AppErrorType.network,
        originalError: error,
        stackTrace: stackTrace,
        context: context != null ? {'context': context} : null,
      );
    }

    // AppError ya manejado
    if (error is AppError) {
      return error;
    }

    // Error genérico
    return AppError(
      message: error.toString(),
      type: AppErrorType.unknown,
      originalError: error,
      stackTrace: stackTrace,
      context: context != null ? {'context': context} : null,
    );
  }

  String _getFirebaseAuthMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No existe una cuenta con este correo.';
      case 'wrong-password':
        return 'Contraseña incorrecta.';
      case 'invalid-email':
        return 'El correo electrónico no es válido.';
      case 'user-disabled':
        return 'Esta cuenta ha sido deshabilitada.';
      case 'email-already-in-use':
        return 'Ya existe una cuenta con este correo.';
      case 'weak-password':
        return 'La contraseña es muy débil.';
      case 'invalid-credential':
        return 'Credenciales inválidas.';
      case 'too-many-requests':
        return 'Demasiados intentos. Intenta más tarde.';
      case 'operation-not-allowed':
        return 'Operación no permitida.';
      default:
        return 'Error de autenticación.';
    }
  }

  String _getFirebaseMessage(String code) {
    switch (code) {
      case 'permission-denied':
        return 'No tienes permisos para esta acción.';
      case 'unavailable':
        return 'Servicio no disponible. Intenta más tarde.';
      case 'not-found':
        return 'El recurso no fue encontrado.';
      case 'already-exists':
        return 'El recurso ya existe.';
      case 'resource-exhausted':
        return 'Se ha excedido el límite. Intenta más tarde.';
      default:
        return 'Error del servidor.';
    }
  }

  AppErrorType _getFirebaseErrorType(String code) {
    switch (code) {
      case 'permission-denied':
        return AppErrorType.permission;
      case 'unavailable':
      case 'resource-exhausted':
        return AppErrorType.server;
      default:
        return AppErrorType.unknown;
    }
  }

  /// Mostrar error en un SnackBar
  static void showErrorSnackBar(BuildContext context, AppError error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              _getIconForType(error.type),
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                error.displayMessage,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: _getColorForType(error.type),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  static IconData _getIconForType(AppErrorType type) {
    switch (type) {
      case AppErrorType.network:
        return Icons.wifi_off_rounded;
      case AppErrorType.authentication:
        return Icons.lock_outline_rounded;
      case AppErrorType.permission:
        return Icons.block_rounded;
      case AppErrorType.validation:
        return Icons.warning_amber_rounded;
      case AppErrorType.server:
        return Icons.cloud_off_rounded;
      case AppErrorType.unknown:
        return Icons.error_outline_rounded;
    }
  }

  static Color _getColorForType(AppErrorType type) {
    switch (type) {
      case AppErrorType.network:
        return const Color(0xFF6366F1); // Indigo
      case AppErrorType.authentication:
        return const Color(0xFFF59E0B); // Amber
      case AppErrorType.permission:
        return const Color(0xFFEF4444); // Red
      case AppErrorType.validation:
        return const Color(0xFFF97316); // Orange
      case AppErrorType.server:
        return const Color(0xFF8B5CF6); // Purple
      case AppErrorType.unknown:
        return const Color(0xFF64748B); // Slate
    }
  }

  void dispose() {
    _errorController.close();
  }
}

/// Widget para mostrar errores de forma global
class ErrorListener extends StatefulWidget {
  final Widget child;

  const ErrorListener({super.key, required this.child});

  @override
  State<ErrorListener> createState() => _ErrorListenerState();
}

class _ErrorListenerState extends State<ErrorListener> {
  late StreamSubscription<AppError> _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = ErrorHandler().errorStream.listen((error) {
      if (mounted) {
        ErrorHandler.showErrorSnackBar(context, error);
      }
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
