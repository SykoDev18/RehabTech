import 'dart:async';

import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';
import 'logger.dart';

/// Servicio de Firebase App Check para proteger las APIs
class AppCheckService {
  static final AppCheckService _instance = AppCheckService._internal();
  factory AppCheckService() => _instance;
  AppCheckService._internal();

  bool _initialized = false;
  StreamSubscription<String?>? _tokenChangeSub;

  /// Inicializar App Check
  /// 
  /// En debug usa Debug Provider
  /// En release usa Play Integrity (Android) / Device Check (iOS)
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      await FirebaseAppCheck.instance.activate(
        // Debug provider para desarrollo
        // ignore: deprecated_member_use
        androidProvider: kDebugMode 
            ? AndroidProvider.debug 
            : AndroidProvider.playIntegrity,
        // ignore: deprecated_member_use
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

      // En debug mode, el SDK nativo de Firebase imprime el debug-token
      // (UUID) UNA SOLA VEZ con tag `FirebaseAppCheck` ("Enter this debug
      // secret into the allow list..."). Si no lo registras en
      // Firebase Console → App Check → Apps → [Android] → Manage debug
      // tokens, *cualquier* request a Storage/Firestore protegido con
      // App Check devolverá 403 ("App attestation failed").
      //
      // Imprimimos un recordatorio visible para que sea fácil de ubicar
      // entre el ruido de logcat al diagnosticar 403 en Storage.
      if (kDebugMode) {
        AppLogger.warning(
          '⚠️  App Check debug-token: busca "FirebaseAppCheck" en logcat '
          'y registra el UUID en Firebase Console → App Check → '
          'Manage debug tokens. Sin esto, Storage/Firestore devolverán 403.',
          tag: 'AppCheck',
        );
      }

      // Escuchar cambios en el token (opcional)
      _tokenChangeSub = FirebaseAppCheck.instance.onTokenChange.listen((token) {
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

  /// Cancela la suscripción al token y libera recursos.
  /// Singleton de toda la vida de la app; expuesto para tests/cierre forzoso.
  Future<void> dispose() async {
    await _tokenChangeSub?.cancel();
    _tokenChangeSub = null;
    _initialized = false;
  }
}
