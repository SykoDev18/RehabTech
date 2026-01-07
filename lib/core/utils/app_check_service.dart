import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';
import 'logger.dart';

/// Servicio de Firebase App Check para proteger las APIs
class AppCheckService {
  static final AppCheckService _instance = AppCheckService._internal();
  factory AppCheckService() => _instance;
  AppCheckService._internal();

  bool _initialized = false;

  /// Inicializar App Check
  /// 
  /// En debug usa Debug Provider
  /// En release usa Play Integrity (Android) / Device Check (iOS)
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      await FirebaseAppCheck.instance.activate(
        // Debug provider para desarrollo
        androidProvider: kDebugMode 
            ? AndroidProvider.debug 
            : AndroidProvider.playIntegrity,
        appleProvider: kDebugMode 
            ? AppleProvider.debug 
            : AppleProvider.deviceCheck,
      );

      _initialized = true;
      AppLogger.info(
        'Firebase App Check activado',
        data: {
          'mode': kDebugMode ? 'debug' : 'release',
          'androidProvider': kDebugMode ? 'debug' : 'playIntegrity',
          'appleProvider': kDebugMode ? 'debug' : 'deviceCheck',
        },
        tag: 'AppCheck',
      );

      // Escuchar cambios en el token (opcional)
      FirebaseAppCheck.instance.onTokenChange.listen((token) {
        AppLogger.debug(
          'App Check token actualizado',
          data: {'tokenLength': token?.length ?? 0},
          tag: 'AppCheck',
        );
      });
    } catch (e, st) {
      AppLogger.error(
        'Error al inicializar App Check',
        error: e,
        stackTrace: st,
        tag: 'AppCheck',
      );
      // No lanzamos el error para que la app siga funcionando
      // pero las APIs de Firebase estarán menos protegidas
    }
  }

  /// Obtener el token actual de App Check
  Future<String?> getToken({bool forceRefresh = false}) async {
    try {
      final token = await FirebaseAppCheck.instance.getToken(forceRefresh);
      return token;
    } catch (e) {
      AppLogger.warning(
        'No se pudo obtener token de App Check',
        data: {'error': e.toString()},
        tag: 'AppCheck',
      );
      return null;
    }
  }

  /// Verificar si App Check está activo
  bool get isInitialized => _initialized;
}
